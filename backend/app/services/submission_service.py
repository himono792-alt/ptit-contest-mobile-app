"""Submission business logic (SV-08 nộp bài, GV-04 quản lý)."""

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.contest import Contest, ContestRound
from app.models.entry import ContestEntry, TeamMember
from app.models.enums import EntryType, RegistrationStatus, SubmissionStatus
from app.models.identity import AppUser
from app.models.judging import JudgeAssignment
from app.models.master_data import Judge, Student
from app.models.submission import Submission, SubmissionFile, SubmissionVersion
from app.schemas.submission import SubmissionVersionCreateIn


# ---------- Helpers ----------

async def _get_my_student(db: AsyncSession, user: AppUser) -> Student:
    stmt = select(Student).where(Student.user_id == user.user_id)
    s = (await db.execute(stmt)).scalar_one_or_none()
    if s is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "User không phải sinh viên")
    return s


async def _find_my_entry_in_round(
    db: AsyncSession, user: AppUser, round_obj: ContestRound
) -> ContestEntry:
    """Tìm entry của user trong contest chứa round này.
    User có thể là individual hoặc thành viên team.
    """
    student = await _get_my_student(db, user)

    # Individual entry
    indiv_stmt = (
        select(ContestEntry)
        .where(
            ContestEntry.contest_id == round_obj.contest_id,
            ContestEntry.student_id == student.student_id,
            ContestEntry.entry_type == EntryType.INDIVIDUAL,
        )
    )
    entry = (await db.execute(indiv_stmt)).scalar_one_or_none()

    # Team entry — user là member của team đăng ký
    if entry is None:
        team_stmt = (
            select(ContestEntry)
            .join(TeamMember, TeamMember.team_id == ContestEntry.team_id)
            .where(
                ContestEntry.contest_id == round_obj.contest_id,
                ContestEntry.entry_type == EntryType.TEAM,
                TeamMember.student_id == student.student_id,
            )
        )
        entry = (await db.execute(team_stmt)).scalar_one_or_none()

    if entry is None:
        raise HTTPException(
            status.HTTP_404_NOT_FOUND,
            "Bạn chưa đăng ký contest này (hoặc chưa thuộc team đăng ký)",
        )
    if entry.registration_status != RegistrationStatus.APPROVED:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            f"Đăng ký chưa được duyệt (status={entry.registration_status.value})",
        )
    return entry


async def _ensure_can_view_submission(
    db: AsyncSession, user: AppUser, submission: Submission
) -> None:
    """Allow: owner SV, ORGANIZER (created_by contest), JUDGE assigned, ADMIN."""
    if "ADMIN" in user.role_codes:
        return

    contest_stmt = (
        select(Contest)
        .join(ContestRound, ContestRound.contest_id == Contest.contest_id)
        .where(ContestRound.round_id == submission.round_id)
    )
    contest = (await db.execute(contest_stmt)).scalar_one()

    # Organizer / contest creator
    if "ORGANIZER" in user.role_codes and contest.created_by == user.user_id:
        return

    # Owner SV
    student_stmt = select(Student).where(Student.user_id == user.user_id)
    student = (await db.execute(student_stmt)).scalar_one_or_none()
    if student:
        entry = await db.get(ContestEntry, submission.entry_id)
        if entry is not None:
            if entry.student_id == student.student_id:
                return
            # Check team membership
            if entry.team_id is not None:
                tm_stmt = select(TeamMember).where(
                    TeamMember.team_id == entry.team_id,
                    TeamMember.student_id == student.student_id,
                )
                if (await db.execute(tm_stmt)).scalar_one_or_none() is not None:
                    return

    # JUDGE assigned to this submission (or entry in same round)
    if "JUDGE" in user.role_codes:
        judge_stmt = select(Judge).where(Judge.user_id == user.user_id)
        judge = (await db.execute(judge_stmt)).scalar_one_or_none()
        if judge is not None:
            assign_stmt = select(JudgeAssignment).where(
                JudgeAssignment.judge_id == judge.judge_id,
                JudgeAssignment.entry_id == submission.entry_id,
                JudgeAssignment.round_id == submission.round_id,
            )
            if (await db.execute(assign_stmt)).scalar_one_or_none() is not None:
                return

    raise HTTPException(status.HTTP_403_FORBIDDEN, "Bạn không có quyền xem submission này")


# ---------- SV-08 ----------

async def add_my_version(
    db: AsyncSession,
    user: AppUser,
    round_id: int,
    data: SubmissionVersionCreateIn,
) -> tuple[Submission, SubmissionVersion]:
    """Find-or-create submission cho (round, my_entry) + add version mới."""
    round_obj = await db.get(ContestRound, round_id)
    if round_obj is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Round not found")

    entry = await _find_my_entry_in_round(db, user, round_obj)

    # Find existing submission
    sub_stmt = select(Submission).where(
        Submission.round_id == round_id,
        Submission.entry_id == entry.entry_id,
    )
    submission = (await db.execute(sub_stmt)).scalar_one_or_none()
    if submission is None:
        submission = Submission(
            round_id=round_id,
            entry_id=entry.entry_id,
            current_version_no=0,
            status=SubmissionStatus.DRAFT,
            created_by=user.user_id,
        )
        db.add(submission)
        await db.flush()

    if submission.is_locked:
        raise HTTPException(status.HTTP_409_CONFLICT, "Submission đã bị lock, không nộp được nữa")

    # Determine LATE
    now = datetime.now(timezone.utc)
    is_late = (
        round_obj.submission_close_at is not None
        and now > round_obj.submission_close_at
    )

    # Create new version
    new_version_no = submission.current_version_no + 1
    version = SubmissionVersion(
        submission_id=submission.submission_id,
        version_no=new_version_no,
        title=data.title,
        description=data.description,
        external_link=data.external_link,
        text_answer=data.text_answer,
        note=data.note,
        submitted_by=user.user_id,
    )
    db.add(version)

    # Update submission
    submission.current_version_no = new_version_no
    submission.submitted_at = now
    submission.updated_by = user.user_id
    submission.status = SubmissionStatus.LATE if is_late else SubmissionStatus.SUBMITTED

    await db.commit()
    await db.refresh(submission)
    await db.refresh(version)
    return submission, version


async def get_my_submission_in_round(
    db: AsyncSession, user: AppUser, round_id: int
) -> Submission | None:
    round_obj = await db.get(ContestRound, round_id)
    if round_obj is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Round not found")
    entry = await _find_my_entry_in_round(db, user, round_obj)
    stmt = (
        select(Submission)
        .where(Submission.round_id == round_id, Submission.entry_id == entry.entry_id)
        .options(selectinload(Submission.versions).selectinload(SubmissionVersion.files))
    )
    return (await db.execute(stmt)).scalar_one_or_none()


# ---------- GV-04 ----------

async def list_round_submissions(
    db: AsyncSession, user: AppUser, round_id: int
) -> list[Submission]:
    """GV-04 — list submissions in round (organizer + judges only)."""
    round_obj = await db.get(ContestRound, round_id)
    if round_obj is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Round not found")
    contest = await db.get(Contest, round_obj.contest_id)
    assert contest is not None
    if "ADMIN" not in user.role_codes:
        if "ORGANIZER" not in user.role_codes and "JUDGE" not in user.role_codes:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần ORGANIZER hoặc JUDGE")
        if "ORGANIZER" in user.role_codes and contest.created_by != user.user_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Không phải BTC contest này")

    stmt = (
        select(Submission)
        .where(Submission.round_id == round_id)
        .order_by(Submission.created_at.desc())
    )
    return list((await db.execute(stmt)).scalars().all())


async def get_submission_detail(
    db: AsyncSession, user: AppUser, submission_id: int
) -> Submission:
    stmt = (
        select(Submission)
        .where(Submission.submission_id == submission_id)
        .options(selectinload(Submission.versions).selectinload(SubmissionVersion.files))
    )
    submission = (await db.execute(stmt)).scalar_one_or_none()
    if submission is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Submission not found")
    await _ensure_can_view_submission(db, user, submission)
    return submission


async def lock_submission(
    db: AsyncSession, user: AppUser, submission_id: int
) -> Submission:
    submission = await db.get(Submission, submission_id)
    if submission is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Submission not found")
    contest_stmt = (
        select(Contest)
        .join(ContestRound, ContestRound.contest_id == Contest.contest_id)
        .where(ContestRound.round_id == submission.round_id)
    )
    contest = (await db.execute(contest_stmt)).scalar_one()
    if "ADMIN" not in user.role_codes:
        if "ORGANIZER" not in user.role_codes or contest.created_by != user.user_id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Không phải BTC contest này")

    submission.is_locked = True
    submission.status = SubmissionStatus.LOCKED
    await db.commit()
    await db.refresh(submission)
    return submission
