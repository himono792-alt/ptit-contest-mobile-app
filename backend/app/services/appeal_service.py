"""Phúc khảo kết quả (Result Appeal) business logic — 2026-06-27.

Luồng (đã chốt Q1–Q4):
  - SV (chủ entry / leader team) gửi phúc khảo khi contest FINISHED + đã publish,
    còn trong hạn `contest.appeal_deadline` (BTC tự đặt).
  - GV/BTC tiếp nhận (PENDING→IN_REVIEW) rồi kết luận:
        ACCEPTED → chấp nhận; GV chấm lại + submit BCN_QĐ2 + publish lại (endpoint sẵn có).
        REJECTED → giữ nguyên kết quả (kèm lý do).
  - 1 entry chỉ 1 phúc khảo đang mở (PENDING/IN_REVIEW).
"""

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.contest import Contest
from app.models.entry import ContestEntry, Team, TeamMember
from app.models.enums import (
    AppealStatus,
    ContestStatus,
    EntryType,
)
from app.models.identity import AppUser
from app.models.judging import ContestResult, ResultAppeal
from app.models.master_data import Student
from app.services import notification_service


# ---------- helpers ----------

async def _get_my_student(db: AsyncSession, user: AppUser) -> Student:
    s = (
        await db.execute(select(Student).where(Student.user_id == user.user_id))
    ).scalar_one_or_none()
    if s is None:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "User không phải sinh viên")
    return s


async def _student_owns_entry(
    db: AsyncSession, entry: ContestEntry, student_id: int
) -> bool:
    """INDIVIDUAL: chính chủ. TEAM: chỉ đội trưởng (is_leader) được gửi."""
    if entry.entry_type == EntryType.INDIVIDUAL:
        return entry.student_id == student_id
    if entry.team_id is None:
        return False
    leader = (
        await db.execute(
            select(TeamMember.student_id).where(
                TeamMember.team_id == entry.team_id,
                TeamMember.student_id == student_id,
                TeamMember.is_leader.is_(True),
            )
        )
    ).scalar_one_or_none()
    return leader is not None


async def _ensure_can_handle(db: AsyncSession, user: AppUser, contest: Contest) -> None:
    """Q1=A — GV/BTC (chủ contest) hoặc ADMIN xử lý phúc khảo."""
    if "ADMIN" in user.role_codes:
        return
    if "ORGANIZER" not in user.role_codes or contest.created_by != user.user_id:
        raise HTTPException(
            status.HTTP_403_FORBIDDEN, "Chỉ BTC cuộc thi (hoặc Admin) xử lý phúc khảo"
        )


def _can_view(user: AppUser, contest: Contest, appeal_student_user_id: int | None) -> bool:
    codes = user.role_codes
    if "ADMIN" in codes or "HOD" in codes:
        return True  # BCN/HOD giám sát (read)
    if "ORGANIZER" in codes and contest.created_by == user.user_id:
        return True
    if appeal_student_user_id is not None and user.user_id == appeal_student_user_id:
        return True
    return False


async def _appeal_student_user_id(db: AsyncSession, appeal: ResultAppeal) -> int | None:
    return (
        await db.execute(
            select(Student.user_id).where(
                Student.student_id == appeal.submitted_by_student_id
            )
        )
    ).scalar_one_or_none()


# ---------- SV: create / list / withdraw ----------

async def create_appeal(
    db: AsyncSession,
    user: AppUser,
    contest_id: int,
    entry_id: int,
    round_id: int | None,
    title: str,
    content_text: str,
) -> ResultAppeal:
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    if contest.status != ContestStatus.FINISHED:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Chỉ phúc khảo khi cuộc thi đã có kết quả (FINISHED). Hiện: {contest.status.value}",
        )

    # Cửa sổ phúc khảo (BTC tự đặt)
    if contest.appeal_deadline is None:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Cuộc thi này chưa mở kênh phúc khảo"
        )
    now = datetime.now(timezone.utc)
    if now > contest.appeal_deadline:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Đã quá hạn phúc khảo cho cuộc thi này",
        )

    student = await _get_my_student(db, user)

    entry = await db.get(ContestEntry, entry_id)
    if entry is None or entry.contest_id != contest_id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Entry không thuộc cuộc thi này")
    if not await _student_owns_entry(db, entry, student.student_id):
        raise HTTPException(
            status.HTTP_403_FORBIDDEN,
            "Bạn không phải chủ bài dự thi này (đội nhóm: chỉ đội trưởng gửi được)",
        )

    # Phải có kết quả published cho entry
    has_result = (
        await db.execute(
            select(func.count())
            .select_from(ContestResult)
            .where(
                ContestResult.contest_id == contest_id,
                ContestResult.entry_id == entry_id,
                ContestResult.published_at.is_not(None),
            )
        )
    ).scalar_one()
    if has_result == 0:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Bài dự thi chưa có kết quả công bố để phúc khảo"
        )

    # 1 entry — 1 phúc khảo đang mở
    open_exists = (
        await db.execute(
            select(func.count())
            .select_from(ResultAppeal)
            .where(
                ResultAppeal.entry_id == entry_id,
                ResultAppeal.status.in_(
                    [AppealStatus.PENDING, AppealStatus.IN_REVIEW]
                ),
            )
        )
    ).scalar_one()
    if open_exists > 0:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Bài dự thi này đang có một phúc khảo chưa xử lý xong",
        )

    appeal = ResultAppeal(
        contest_id=contest_id,
        round_id=round_id,
        entry_id=entry_id,
        submitted_by_student_id=student.student_id,
        title=title,
        content_text=content_text,
        status=AppealStatus.PENDING,
    )
    db.add(appeal)
    await db.commit()
    await db.refresh(appeal)

    # Notify BTC (chủ contest)
    try:
        await notification_service.notify_users(
            db,
            title="Phúc khảo mới",
            message=f"Có phúc khảo mới cho cuộc thi '{contest.title}'",
            user_ids=[contest.created_by],
            contest_id=contest_id,
            created_by=user.user_id,
            target_route=f"/contests/{contest.slug}/appeals",
        )
    except Exception:  # noqa: BLE001 — notify không được làm hỏng nghiệp vụ chính
        pass
    return appeal


async def list_my_appeals(db: AsyncSession, user: AppUser) -> list[ResultAppeal]:
    student = await _get_my_student(db, user)
    stmt = (
        select(ResultAppeal)
        .where(ResultAppeal.submitted_by_student_id == student.student_id)
        .order_by(ResultAppeal.created_at.desc())
    )
    return list((await db.execute(stmt)).scalars().all())


async def withdraw_appeal(db: AsyncSession, user: AppUser, appeal_id: int) -> ResultAppeal:
    appeal = await db.get(ResultAppeal, appeal_id)
    if appeal is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Appeal not found")
    student = await _get_my_student(db, user)
    if appeal.submitted_by_student_id != student.student_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Không phải phúc khảo của bạn")
    if appeal.status != AppealStatus.PENDING:
        raise HTTPException(
            status.HTTP_409_CONFLICT, "Chỉ rút được khi phúc khảo còn ở trạng thái chờ"
        )
    appeal.status = AppealStatus.CLOSED
    await db.commit()
    await db.refresh(appeal)
    return appeal


# ---------- detail (RBAC) ----------

async def get_appeal(db: AsyncSession, user: AppUser, appeal_id: int) -> ResultAppeal:
    appeal = await db.get(ResultAppeal, appeal_id)
    if appeal is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Appeal not found")
    contest = await db.get(Contest, appeal.contest_id)
    sv_uid = await _appeal_student_user_id(db, appeal)
    if not _can_view(user, contest, sv_uid):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Không có quyền xem phúc khảo này")
    return appeal


# ---------- GV/BTC: queue / start-review / resolve ----------

async def list_contest_appeals(
    db: AsyncSession, user: AppUser, contest_id: int, status_filter: str | None
) -> list[ResultAppeal]:
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    if not _can_view(user, contest, None):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Không có quyền xem queue phúc khảo")
    stmt = select(ResultAppeal).where(ResultAppeal.contest_id == contest_id)
    if status_filter:
        stmt = stmt.where(ResultAppeal.status == AppealStatus(status_filter))
    stmt = stmt.order_by(ResultAppeal.created_at.asc())
    return list((await db.execute(stmt)).scalars().all())


async def start_review(db: AsyncSession, user: AppUser, appeal_id: int) -> ResultAppeal:
    appeal = await db.get(ResultAppeal, appeal_id)
    if appeal is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Appeal not found")
    contest = await db.get(Contest, appeal.contest_id)
    await _ensure_can_handle(db, user, contest)
    if appeal.status != AppealStatus.PENDING:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Chỉ nhận xử lý phúc khảo đang PENDING (hiện: {appeal.status.value})",
        )
    appeal.status = AppealStatus.IN_REVIEW
    appeal.handled_by = user.user_id
    await db.commit()
    await db.refresh(appeal)

    sv_uid = await _appeal_student_user_id(db, appeal)
    if sv_uid:
        try:
            await notification_service.notify_users(
                db,
                title="Phúc khảo đang được xem xét",
                message=f"Phúc khảo '{appeal.title}' của bạn đang được BTC xem xét",
                user_ids=[sv_uid],
                contest_id=appeal.contest_id,
                created_by=user.user_id,
                target_route="/me/appeals",
            )
        except Exception:  # noqa: BLE001
            pass
    return appeal


async def resolve_appeal(
    db: AsyncSession, user: AppUser, appeal_id: int, decision: str, response_text: str
) -> ResultAppeal:
    appeal = await db.get(ResultAppeal, appeal_id)
    if appeal is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Appeal not found")
    contest = await db.get(Contest, appeal.contest_id)
    await _ensure_can_handle(db, user, contest)
    if appeal.status not in (AppealStatus.PENDING, AppealStatus.IN_REVIEW):
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Phúc khảo đã kết thúc (hiện: {appeal.status.value})",
        )
    if decision not in ("ACCEPTED", "REJECTED"):
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "decision phải ACCEPTED|REJECTED")

    appeal.status = AppealStatus(decision)
    appeal.response_text = response_text
    appeal.handled_by = user.user_id
    appeal.handled_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(appeal)

    sv_uid = await _appeal_student_user_id(db, appeal)
    if sv_uid:
        if decision == "ACCEPTED":
            msg = (
                f"Phúc khảo '{appeal.title}' được chấp nhận. "
                "BTC sẽ chấm lại và cập nhật kết quả."
            )
        else:
            msg = f"Phúc khảo '{appeal.title}' bị từ chối: {response_text}"
        try:
            await notification_service.notify_users(
                db,
                title="Kết quả phúc khảo",
                message=msg,
                user_ids=[sv_uid],
                contest_id=appeal.contest_id,
                created_by=user.user_id,
                target_route="/me/appeals",
            )
        except Exception:  # noqa: BLE001
            pass
    return appeal


# ---------- BTC: set appeal window ----------

async def set_appeal_window(
    db: AsyncSession, user: AppUser, contest_id: int, appeal_deadline: datetime | None
) -> Contest:
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    await _ensure_can_handle(db, user, contest)
    if contest.status != ContestStatus.FINISHED:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Chỉ mở phúc khảo sau khi cuộc thi đã công bố kết quả (FINISHED)",
        )
    contest.appeal_deadline = appeal_deadline
    await db.commit()
    await db.refresh(contest)
    return contest
