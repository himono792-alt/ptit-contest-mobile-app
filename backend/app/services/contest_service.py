"""Contest CRUD business logic (GV-02).

Rules:
  - DRAFT / REVISION_REQUESTED: BTC tự sửa được
  - PROPOSED / PUBLISHED+: locked với general fields
  - Rounds/Sessions: editable cho đến trước ONGOING
  - DELETE: chỉ DRAFT + không có entries
"""

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.contest import Contest, ContestRound, ContestSession
from app.models.entry import ContestEntry
from app.models.enums import ContestStatus
from app.models.identity import AppUser
from app.models.master_data import Organizer
from app.schemas.contest import (
    ContestCreateIn,
    ContestRoundCreateIn,
    ContestSessionCreateIn,
    ContestUpdateIn,
)

_EDITABLE_STATUSES = (ContestStatus.DRAFT, ContestStatus.REVISION_REQUESTED)

# Structural changes (rounds/sessions) — cho phép xuyên suốt trừ FINISHED/CANCELLED
# (thực tế BTC có thể cần thêm round phụ giữa contest ONGOING)
_STRUCTURE_EDITABLE_STATUSES = (
    ContestStatus.DRAFT,
    ContestStatus.REVISION_REQUESTED,
    ContestStatus.PUBLISHED,
    ContestStatus.REG_OPEN,
    ContestStatus.REG_CLOSED,
    ContestStatus.ONGOING,
)


# Authorization helpers

async def _ensure_organizer(db: AsyncSession, user: AppUser) -> int:
    if "ORGANIZER" not in user.role_codes and "ADMIN" not in user.role_codes:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần role ORGANIZER hoặc ADMIN")
    stmt = select(Organizer).where(Organizer.user_id == user.user_id)
    org = (await db.execute(stmt)).scalar_one_or_none()
    if org is None and "ADMIN" not in user.role_codes:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "User chưa có profile organizer")
    return org.organizer_id if org else 0


async def _get_contest_or_404(db: AsyncSession, contest_id: int) -> Contest:
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    return contest


def _ensure_owner(contest: Contest, user: AppUser) -> None:
    if "ADMIN" in user.role_codes:
        return
    if contest.created_by != user.user_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Chỉ owner mới sửa được")


def _ensure_editable(contest: Contest) -> None:
    if contest.status not in _EDITABLE_STATUSES:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Chỉ sửa được khi status DRAFT hoặc REVISION_REQUESTED. Hiện tại: {contest.status.value}",
        )


def _ensure_structure_editable(contest: Contest) -> None:
    if contest.status not in _STRUCTURE_EDITABLE_STATUSES:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Không sửa cấu trúc khi contest đang {contest.status.value}",
        )


# Contest CRUD

async def create_contest(db: AsyncSession, user: AppUser, data: ContestCreateIn) -> Contest:
    await _ensure_organizer(db, user)

    if data.participation_mode.value == "TEAM":
        if not data.team_min_members or not data.team_max_members:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "TEAM cần team_min/max_members")
        if data.team_max_members < data.team_min_members:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "team_max < team_min")

    # Sprint 21+ fix (2026-05-09): nếu form không gửi host_faculty_id (field
    # optional), auto inject faculty_id từ profile Organizer của GV. Lý do
    # phát hiện: BCN approval queue filter `Contest.host_faculty_id == bcn_faculty_id`
    # → contest có host_faculty_id NULL không vào queue → BCN không thấy duyệt.
    payload = data.model_dump()
    if payload.get("host_faculty_id") is None:
        org_stmt = select(Organizer).where(Organizer.user_id == user.user_id)
        org = (await db.execute(org_stmt)).scalar_one_or_none()
        if org is not None and org.faculty_id is not None:
            payload["host_faculty_id"] = org.faculty_id

    contest = Contest(
        **payload,
        status=ContestStatus.DRAFT,
        created_by=user.user_id,
        proposed_by=user.user_id,
    )
    db.add(contest)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, f"Slug '{data.slug}' đã được dùng") from e
    await db.refresh(contest)
    return contest


async def update_contest(db, user, contest_id, data):
    contest = await _get_contest_or_404(db, contest_id)
    _ensure_owner(contest, user)
    _ensure_editable(contest)

    update_data = data.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(contest, field, value)
    await db.commit()
    await db.refresh(contest)
    return contest


async def delete_contest(db, user, contest_id):
    contest = await _get_contest_or_404(db, contest_id)
    _ensure_owner(contest, user)
    if contest.status != ContestStatus.DRAFT:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"Chỉ DELETE khi status=DRAFT. Hiện: {contest.status.value}",
        )
    entry_count_stmt = (
        select(func.count())
        .select_from(ContestEntry)
        .where(ContestEntry.contest_id == contest_id)
    )
    if (await db.execute(entry_count_stmt)).scalar_one() > 0:
        raise HTTPException(status.HTTP_409_CONFLICT, "Đã có entries, không xóa được")

    await db.delete(contest)
    await db.commit()


# Rounds

async def add_round(db, user, contest_id, data):
    contest = await _get_contest_or_404(db, contest_id)
    _ensure_owner(contest, user)
    _ensure_structure_editable(contest)

    round_obj = ContestRound(contest_id=contest_id, **data.model_dump())
    db.add(round_obj)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            f"round_no={data.round_no} đã tồn tại trong contest",
        ) from e
    await db.refresh(round_obj)
    return round_obj


async def list_rounds(db, contest_id):
    stmt = (
        select(ContestRound)
        .where(ContestRound.contest_id == contest_id)
        .order_by(ContestRound.round_no)
    )
    return list((await db.execute(stmt)).scalars().all())


# Sessions

async def add_session(db, user, contest_id, data):
    contest = await _get_contest_or_404(db, contest_id)
    _ensure_owner(contest, user)
    _ensure_structure_editable(contest)

    session = ContestSession(contest_id=contest_id, **data.model_dump())
    db.add(session)
    await db.commit()
    await db.refresh(session)
    return session


async def list_sessions(db, contest_id):
    stmt = (
        select(ContestSession)
        .where(ContestSession.contest_id == contest_id)
        .order_by(ContestSession.start_at)
    )
    return list((await db.execute(stmt)).scalars().all())
