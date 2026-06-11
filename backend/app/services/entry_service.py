"""Contest entry business logic (SV-06 register, GV-03 approve, SV-10 cancel)."""

from datetime import datetime, timezone
from typing import Annotated

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.contest import Contest, ContestOrganizer
from app.models.entry import ContestEntry, EntryStatusLog, Team, TeamMember
from app.models.enums import (
    ContestStatus,
    EntryType,
    NotificationScope,
    ParticipantStatus,
    RegistrationStatus,
)
from app.models.identity import AppUser
from app.models.master_data import Organizer, Student
from app.schemas.entry import EntryReviewAction
from app.services import notification_service


async def _get_my_student(db: AsyncSession, user: AppUser) -> Student:
    stmt = select(Student).where(Student.user_id == user.user_id)
    student = (await db.execute(stmt)).scalar_one_or_none()
    if student is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "User không phải sinh viên (không có student profile)",
        )
    return student


def _ensure_registration_open(contest: Contest) -> None:
    if contest.status != ContestStatus.REG_OPEN:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Cuộc thi chưa mở đăng ký (status={contest.status.value})",
        )


# ---------- SV-06 register ----------

async def register_individual(
    db: AsyncSession, user: AppUser, contest_id: int, note: str | None
) -> ContestEntry:
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    if contest.participation_mode != EntryType.INDIVIDUAL:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Cuộc thi này theo team. Dùng /register/team thay vì /register/individual",
        )
    _ensure_registration_open(contest)

    student = await _get_my_student(db, user)

    entry = ContestEntry(
        contest_id=contest_id,
        entry_type=EntryType.INDIVIDUAL,
        student_id=student.student_id,
        registration_status=RegistrationStatus.PENDING,
        participant_status=ParticipantStatus.REGISTERED,
        registration_note=note,
    )
    db.add(entry)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Bạn đã đăng ký contest này rồi",
        ) from e
    await db.refresh(entry)
    return entry


async def register_team(
    db: AsyncSession, user: AppUser, contest_id: int, team_id: int, note: str | None
) -> ContestEntry:
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    if contest.participation_mode != EntryType.TEAM:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Cuộc thi này cá nhân. Dùng /register/individual thay vì /register/team",
        )
    _ensure_registration_open(contest)

    student = await _get_my_student(db, user)

    team = await db.get(Team, team_id)
    if team is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Team not found")
    if team.contest_id != contest_id:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Team không thuộc contest này",
        )
    if team.leader_student_id != student.student_id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Chỉ leader của team mới đăng ký được",
        )

    entry = ContestEntry(
        contest_id=contest_id,
        entry_type=EntryType.TEAM,
        team_id=team_id,
        registration_status=RegistrationStatus.PENDING,
        participant_status=ParticipantStatus.REGISTERED,
        registration_note=note,
    )
    db.add(entry)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Team đã đăng ký contest này rồi",
        ) from e
    await db.refresh(entry)
    return entry


# ---------- SV-10 cancel ----------

async def cancel_my_registration(
    db: AsyncSession, user: AppUser, contest_id: int
) -> None:
    student = await _get_my_student(db, user)
    stmt = (
        select(ContestEntry)
        .where(
            ContestEntry.contest_id == contest_id,
            ContestEntry.student_id == student.student_id,
        )
    )
    entry = (await db.execute(stmt)).scalar_one_or_none()
    if entry is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Bạn chưa đăng ký contest này")

    if entry.registration_status == RegistrationStatus.CANCELLED:
        raise HTTPException(status.HTTP_409_CONFLICT, "Đã hủy trước đó")

    # TODO (team): check thời gian — system_configs.cancel.min_days_before
    entry.registration_status = RegistrationStatus.CANCELLED
    db.add(EntryStatusLog(
        entry_id=entry.entry_id,
        old_status=entry.participant_status,
        new_status=ParticipantStatus.ELIMINATED,
        changed_by=user.user_id,
        note="SV self-cancel",
    ))
    await db.commit()


# ---------- GV-03 list + approve ----------

async def _ensure_organizer_of_contest(
    db: AsyncSession, user: AppUser, contest: Contest
) -> None:
    """GV chỉ duyệt được entries của contest mình tổ chức."""
    if "ADMIN" in user.role_codes:
        return
    if "ORGANIZER" not in user.role_codes:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần role ORGANIZER")
    if contest.created_by == user.user_id:
        return
    # Hoặc trong contest_organizers
    org_stmt = select(Organizer).where(Organizer.user_id == user.user_id)
    organizer = (await db.execute(org_stmt)).scalar_one_or_none()
    if organizer is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "User chưa có profile organizer")
    co_stmt = select(ContestOrganizer).where(
        ContestOrganizer.contest_id == contest.contest_id,
        ContestOrganizer.organizer_id == organizer.organizer_id,
    )
    if (await db.execute(co_stmt)).scalar_one_or_none() is None:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Bạn không phải BTC của contest này",
        )


async def list_entries(
    db: AsyncSession,
    user: AppUser,
    contest_id: int,
    status_filter: RegistrationStatus | None,
) -> list[ContestEntry]:
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    await _ensure_organizer_of_contest(db, user, contest)

    stmt = select(ContestEntry).where(ContestEntry.contest_id == contest_id)
    if status_filter is not None:
        stmt = stmt.where(ContestEntry.registration_status == status_filter)
    stmt = stmt.order_by(ContestEntry.created_at.desc())
    return list((await db.execute(stmt)).scalars().all())


async def list_my_entries(
    db: AsyncSession,
    user: AppUser,
) -> list[tuple[ContestEntry, Contest]]:
    """SV-10 — List entries của SV hiện tại + contest info kèm theo.

    Bao gồm:
    - Individual entries: student_id == student.student_id
    - Team entries: SV là member của team (team_members JOIN)
    """
    student = await _get_my_student(db, user)

    # 1. Individual entries
    indiv_stmt = (
        select(ContestEntry, Contest)
        .join(Contest, ContestEntry.contest_id == Contest.contest_id)
        .where(ContestEntry.student_id == student.student_id)
    )
    indiv_rows = (await db.execute(indiv_stmt)).all()

    # 2. Team entries — SV là member của team đã đăng ký contest
    team_stmt = (
        select(ContestEntry, Contest)
        .join(Contest, ContestEntry.contest_id == Contest.contest_id)
        .join(TeamMember, TeamMember.team_id == ContestEntry.team_id)
        .where(
            ContestEntry.team_id.is_not(None),
            TeamMember.student_id == student.student_id,
        )
    )
    team_rows = (await db.execute(team_stmt)).all()

    # Merge + dedup theo entry_id (phòng trường hợp lạ)
    seen_ids = set()
    result: list[tuple[ContestEntry, Contest]] = []
    for e, c in [*indiv_rows, *team_rows]:
        if e.entry_id in seen_ids:
            continue
        seen_ids.add(e.entry_id)
        result.append((e, c))

    # Sort theo created_at DESC
    result.sort(key=lambda r: r[0].created_at, reverse=True)
    return result


async def _resolve_recipient_user_ids(
    db: AsyncSession, entry: ContestEntry
) -> list[int]:
    """Phase 2 sprint 1 step 2.5 (2026-05-06): trả list user_id cần notify cho 1 entry.

    - INDIVIDUAL: 1 SV (entry.student_id → Student.user_id)
    - TEAM: tất cả members (TeamMember → Student.user_id list)
    """
    user_ids: list[int] = []
    if entry.entry_type == EntryType.INDIVIDUAL and entry.student_id is not None:
        stmt = select(Student.user_id).where(Student.student_id == entry.student_id)
        uid = (await db.execute(stmt)).scalar_one_or_none()
        if uid is not None:
            user_ids.append(uid)
    elif entry.entry_type == EntryType.TEAM and entry.team_id is not None:
        # JOIN team_members → students để lấy user_id list
        stmt = (
            select(Student.user_id)
            .join(TeamMember, TeamMember.student_id == Student.student_id)
            .where(TeamMember.team_id == entry.team_id)
        )
        rows = (await db.execute(stmt)).scalars().all()
        user_ids.extend(rows)
    return user_ids


async def review_entry(
    db: AsyncSession,
    user: AppUser,
    entry_id: int,
    action: EntryReviewAction,
    note: str | None,
) -> ContestEntry:
    entry = await db.get(ContestEntry, entry_id)
    if entry is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Entry not found")

    contest = await db.get(Contest, entry.contest_id)
    assert contest is not None
    await _ensure_organizer_of_contest(db, user, contest)

    if entry.registration_status != RegistrationStatus.PENDING:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Entry không ở trạng thái PENDING (hiện: {entry.registration_status.value})",
        )

    if action == EntryReviewAction.REJECT and not (note and note.strip()):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Reject phải có lý do (note)")

    entry.registration_status = (
        RegistrationStatus.APPROVED if action == EntryReviewAction.APPROVE
        else RegistrationStatus.REJECTED
    )
    entry.approved_by = user.user_id
    entry.approved_at = datetime.now(timezone.utc)
    if note:
        entry.registration_note = note
    await db.commit()
    await db.refresh(entry)

    # Phase 2 sprint 1 step 2.5 (2026-05-06): notify SV về kết quả review.
    # Wire vào để demo end-to-end Step 1 deep-link (notification target_route).
    recipient_user_ids = await _resolve_recipient_user_ids(db, entry)
    if recipient_user_ids:
        action_label = "đã được duyệt" if action == EntryReviewAction.APPROVE else "đã bị từ chối"
        await notification_service.notify_users(
            db,
            title=f"Đơn đăng ký {action_label}",
            message=(
                f"Đơn đăng ký cuộc thi #{entry.contest_id} của bạn {action_label}."
                + (f" Lý do: {note}" if note else "")
            ),
            user_ids=recipient_user_ids,
            scope=NotificationScope.CONTEST,
            contest_id=entry.contest_id,
            created_by=user.user_id,
            target_route="/me/entries",  # SV click → tab "Của tôi" - Đơn đăng ký
        )

    return entry


async def bulk_review_entries(
    db: AsyncSession,
    user: AppUser,
    contest_id: int,
    entry_ids: list[int],
    action: EntryReviewAction,
    note: str | None,
) -> tuple[int, list[tuple[int, str]]]:
    """Phase 2 sprint 1 step 2 (2026-05-06): bulk approve/reject nhiều entries.

    Partial commit pattern:
    - Verify GV là organizer của contest 1 lần (không lặp 100 lần)
    - Loop từng entry_id → process, append vào success/failed
    - Commit 1 lần ở cuối (success entries đã modify, failed entries không touch)
    - Trả tuple (success_count, failed list)

    Tradeoff vs all-or-nothing: nếu 1 entry đã approved trước, all-or-nothing sẽ
    fail toàn bộ. Partial commit cho user biết "98/100 done, 2 đã approved rồi".
    """
    if action == EntryReviewAction.REJECT and not (note and note.strip()):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Reject phải có lý do (note)")

    # Verify quyền GV cho contest này 1 lần
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    await _ensure_organizer_of_contest(db, user, contest)

    new_status = (
        RegistrationStatus.APPROVED if action == EntryReviewAction.APPROVE
        else RegistrationStatus.REJECTED
    )
    now = datetime.now(timezone.utc)

    success_count = 0
    failed: list[tuple[int, str]] = []
    success_entries: list[ContestEntry] = []  # giữ ref để notify sau commit

    # Dedup entry_ids (phòng FE gửi trùng)
    for entry_id in dict.fromkeys(entry_ids):
        entry = await db.get(ContestEntry, entry_id)
        if entry is None:
            failed.append((entry_id, "Entry không tồn tại"))
            continue
        if entry.contest_id != contest_id:
            # Bảo mật: entry phải thuộc contest đang review (chống bypass quyền GV)
            failed.append((entry_id, "Entry không thuộc contest này"))
            continue
        if entry.registration_status != RegistrationStatus.PENDING:
            failed.append((
                entry_id,
                f"Đã ở trạng thái {entry.registration_status.value}, bỏ qua",
            ))
            continue

        # Modify (chưa commit)
        entry.registration_status = new_status
        entry.approved_by = user.user_id
        entry.approved_at = now
        if note:
            entry.registration_note = note
        success_count += 1
        success_entries.append(entry)

    # Commit 1 lần cho tất cả entries success
    if success_count > 0:
        await db.commit()

        # Phase 2 sprint 1 step 2.5 (2026-05-06): notify SV cho từng entry success.
        # 1 notification per entry — nếu SV có nhiều entries trong batch sẽ nhận
        # nhiều notification (acceptable, mỗi cái có context entry riêng).
        action_label = "đã được duyệt" if action == EntryReviewAction.APPROVE else "đã bị từ chối"
        for entry in success_entries:
            recipient_user_ids = await _resolve_recipient_user_ids(db, entry)
            if not recipient_user_ids:
                continue
            await notification_service.notify_users(
                db,
                title=f"Đơn đăng ký {action_label}",
                message=(
                    f"Đơn đăng ký cuộc thi #{entry.contest_id} của bạn {action_label}."
                    + (f" Lý do: {note}" if note else "")
                ),
                user_ids=recipient_user_ids,
                scope=NotificationScope.CONTEST,
                contest_id=entry.contest_id,
                created_by=user.user_id,
                target_route="/me/entries",
            )

    return success_count, failed
