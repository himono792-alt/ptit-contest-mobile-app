"""Entry router — SV-06 đăng ký, GV-03 phê duyệt, SV-10 hủy."""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.models.enums import RegistrationStatus
from app.schemas.entry import (
    EntryListItem,
    MyEntryItem,
    RegisterIndividualIn,
    RegisterTeamIn,
    ReviewEntryIn,
)
from app.services import entry_service

# 3 router: 1 cho /contests/{id}/*, 1 cho /entries/{id}, 1 cho /me/entries
contest_entries_router = APIRouter(prefix="/contests", tags=["entries"])
entries_router = APIRouter(prefix="/entries", tags=["entries"])
me_entries_router = APIRouter(prefix="/me", tags=["entries"])


@me_entries_router.get("/entries", response_model=list[MyEntryItem])
async def list_my_entries(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[MyEntryItem]:
    """SV-10 — Danh sách entries của SV hiện tại + contest info kèm theo."""
    rows = await entry_service.list_my_entries(db, user)
    return [
        MyEntryItem(
            entry_id=e.entry_id,
            contest_id=e.contest_id,
            contest_slug=c.slug,
            contest_title=c.title,
            contest_status=c.status.value,
            entry_type=e.entry_type.value if hasattr(e.entry_type, 'value') else str(e.entry_type),
            team_id=e.team_id,
            registration_status=e.registration_status,
            participant_status=e.participant_status,
            registration_note=e.registration_note,
            created_at=e.created_at,
            contest_start_at=c.start_at,
            contest_end_at=c.end_at,
        )
        for e, c in rows
    ]


# ---------- SV-06 register ----------

@contest_entries_router.post(
    "/{contest_id}/register/individual",
    response_model=EntryListItem,
    status_code=status.HTTP_201_CREATED,
)
async def register_individual(
    contest_id: int,
    data: RegisterIndividualIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> EntryListItem:
    """SV-06 — Đăng ký cá nhân vào contest (status PENDING chờ BTC duyệt)."""
    entry = await entry_service.register_individual(db, user, contest_id, data.note)
    return EntryListItem.model_validate(entry)


@contest_entries_router.post(
    "/{contest_id}/register/team",
    response_model=EntryListItem,
    status_code=status.HTTP_201_CREATED,
)
async def register_team(
    contest_id: int,
    data: RegisterTeamIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> EntryListItem:
    """SV-06 — Đăng ký team (chỉ leader gọi)."""
    entry = await entry_service.register_team(db, user, contest_id, data.team_id, data.note)
    return EntryListItem.model_validate(entry)


# ---------- SV-10 cancel ----------

@contest_entries_router.delete(
    "/{contest_id}/registration",
    status_code=status.HTTP_204_NO_CONTENT,
)
async def cancel_my_registration(
    contest_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> None:
    """SV-10 — Hủy đăng ký của chính mình."""
    await entry_service.cancel_my_registration(db, user, contest_id)


# ---------- GV-03 list + review ----------

@contest_entries_router.get(
    "/{contest_id}/entries",
    response_model=list[EntryListItem],
)
async def list_contest_entries(
    contest_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    status_filter: RegistrationStatus | None = Query(None, alias="status"),
) -> list[EntryListItem]:
    """GV-03 — Danh sách entries (filter theo status PENDING/APPROVED/...)."""
    entries = await entry_service.list_entries(db, user, contest_id, status_filter)
    return [EntryListItem.model_validate(e) for e in entries]


@entries_router.patch("/{entry_id}", response_model=EntryListItem)
async def review_entry(
    entry_id: int,
    data: ReviewEntryIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> EntryListItem:
    """GV-03 — Approve/reject entry."""
    entry = await entry_service.review_entry(db, user, entry_id, data.action, data.note)
    return EntryListItem.model_validate(entry)
