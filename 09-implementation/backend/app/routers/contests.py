"""Contest router — đầy đủ CRUD + sub-resources.

Endpoints:
  GET    /api/contests                          - SV-04 list public contests
  GET    /api/contests/{slug}                   - SV-05 detail
  POST   /api/contests                          - GV-02 tạo (DRAFT)
  PATCH  /api/contests/{id}                     - GV-02 sửa
  DELETE /api/contests/{id}                     - GV-02 xóa (DRAFT + no entries)
  GET    /api/contests/{id}/rounds              - list rounds
  POST   /api/contests/{id}/rounds              - GV-02 thêm round
  GET    /api/contests/{id}/sessions            - list sessions
  POST   /api/contests/{id}/sessions            - GV-02 thêm session
"""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser, Pagination
from app.models.contest import Contest
from app.models.enums import ContestStatus, DeliveryMode, EntryType
from app.schemas.contest import (
    ContestCreateIn,
    ContestDetail,
    ContestListOut,
    ContestRoundCreateIn,
    ContestRoundOut,
    ContestSessionCreateIn,
    ContestSessionOut,
    ContestSummary,
    ContestUpdateIn,
)
from app.services import contest_service

router = APIRouter(prefix="/contests", tags=["contests"])

_PUBLIC_STATUSES: tuple[ContestStatus, ...] = (
    ContestStatus.PUBLISHED,
    ContestStatus.REG_OPEN,
    ContestStatus.REG_CLOSED,
    ContestStatus.ONGOING,
    ContestStatus.FINISHED,
)


# ---------- READ ----------

@router.get("", response_model=ContestListOut)
async def list_contests(
    db: Annotated[AsyncSession, Depends(get_db)],
    pagination: Annotated[Pagination, Depends()],
    q: str | None = Query(None, description="Tìm theo title (ILIKE)"),
    status_filter: ContestStatus | None = Query(None, alias="status"),
    delivery_mode: DeliveryMode | None = None,
    participation_mode: EntryType | None = None,
    faculty_id: int | None = None,
    show_all: bool = Query(False, description="True = bao gồm DRAFT/PROPOSED (chưa enforce role)"),
) -> ContestListOut:
    """SV-04 / BCN-03 / GV-02 — Liệt kê cuộc thi."""
    base = select(Contest)

    if status_filter is not None:
        base = base.where(Contest.status == status_filter)
    elif not show_all:
        base = base.where(Contest.status.in_(_PUBLIC_STATUSES))

    if q:
        base = base.where(Contest.title.ilike(f"%{q}%"))
    if delivery_mode:
        base = base.where(Contest.delivery_mode == delivery_mode)
    if participation_mode:
        base = base.where(Contest.participation_mode == participation_mode)
    if faculty_id:
        base = base.where(Contest.host_faculty_id == faculty_id)

    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    rows_stmt = (
        base.order_by(Contest.start_at.desc())
        .offset(pagination.offset)
        .limit(pagination.limit)
    )
    rows = (await db.execute(rows_stmt)).scalars().all()

    return ContestListOut(
        items=[ContestSummary.model_validate(c) for c in rows],
        total=total,
        page=pagination.page,
        size=pagination.size,
    )


@router.get("/{slug}", response_model=ContestDetail)
async def get_contest_detail(
    slug: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ContestDetail:
    """SV-05 — Chi tiết theo slug."""
    stmt = select(Contest).where(Contest.slug == slug)
    contest = (await db.execute(stmt)).scalar_one_or_none()
    if contest is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Contest not found")
    return ContestDetail.model_validate(contest)


# ---------- WRITE (GV-02) ----------

@router.post("", response_model=ContestDetail, status_code=status.HTTP_201_CREATED)
async def create_contest(
    data: ContestCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ContestDetail:
    """GV-02 — Tạo contest mới (status DRAFT)."""
    contest = await contest_service.create_contest(db, user, data)
    return ContestDetail.model_validate(contest)


@router.patch("/{contest_id}", response_model=ContestDetail)
async def update_contest(
    contest_id: int,
    data: ContestUpdateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ContestDetail:
    """GV-02 — Update contest (chỉ DRAFT/REVISION_REQUESTED, owner only)."""
    contest = await contest_service.update_contest(db, user, contest_id, data)
    return ContestDetail.model_validate(contest)


@router.delete("/{contest_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_contest(
    contest_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """GV-02 — Xóa contest (chỉ DRAFT + no entries)."""
    await contest_service.delete_contest(db, user, contest_id)


# ---------- ROUNDS ----------

@router.get("/{contest_id}/rounds", response_model=list[ContestRoundOut])
async def list_rounds(
    contest_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ContestRoundOut]:
    rounds = await contest_service.list_rounds(db, contest_id)
    return [ContestRoundOut.model_validate(r) for r in rounds]


@router.post(
    "/{contest_id}/rounds",
    response_model=ContestRoundOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_round(
    contest_id: int,
    data: ContestRoundCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ContestRoundOut:
    """GV-02 — Thêm round vào contest."""
    round_obj = await contest_service.add_round(db, user, contest_id, data)
    return ContestRoundOut.model_validate(round_obj)


# ---------- SESSIONS ----------

@router.get("/{contest_id}/sessions", response_model=list[ContestSessionOut])
async def list_sessions(
    contest_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ContestSessionOut]:
    sessions = await contest_service.list_sessions(db, contest_id)
    return [ContestSessionOut.model_validate(s) for s in sessions]


@router.post(
    "/{contest_id}/sessions",
    response_model=ContestSessionOut,
    status_code=status.HTTP_201_CREATED,
)
async def add_session(
    contest_id: int,
    data: ContestSessionCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ContestSessionOut:
    """GV-02 — Thêm session vào contest."""
    session = await contest_service.add_session(db, user, contest_id, data)
    return ContestSessionOut.model_validate(session)
