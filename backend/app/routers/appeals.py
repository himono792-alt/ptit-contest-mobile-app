"""Phúc khảo kết quả (Result Appeal) router — 2026-06-27.

SV:
  POST   /api/contests/{contest_id}/appeals       - gửi phúc khảo
  GET    /api/me/appeals                           - phúc khảo của tôi
  GET    /api/appeals/{appeal_id}                  - chi tiết (RBAC)
  POST   /api/appeals/{appeal_id}/withdraw         - SV rút (PENDING→CLOSED)

GV/BTC + BCN:
  GET    /api/contests/{contest_id}/appeals        - queue theo contest (?status=)
  POST   /api/appeals/{appeal_id}/start-review     - PENDING→IN_REVIEW
  POST   /api/appeals/{appeal_id}/resolve          - ACCEPTED|REJECTED
  PATCH  /api/contests/{contest_id}/appeal-window  - BTC đặt hạn phúc khảo
"""

from typing import Annotated

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.schemas.appeal import (
    AppealCreateIn,
    AppealOut,
    AppealResolveIn,
    AppealWindowIn,
)
from app.services import appeal_service

contests_appeals_router = APIRouter(prefix="/contests", tags=["appeals"])
me_appeals_router = APIRouter(prefix="/me", tags=["appeals"])
appeals_router = APIRouter(prefix="/appeals", tags=["appeals"])


# ---------- SV ----------

@contests_appeals_router.post(
    "/{contest_id}/appeals",
    response_model=AppealOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_appeal(
    contest_id: int,
    data: AppealCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AppealOut:
    appeal = await appeal_service.create_appeal(
        db, user, contest_id, data.entry_id, data.round_id, data.title, data.content_text
    )
    return AppealOut.model_validate(appeal)


@me_appeals_router.get("/appeals", response_model=list[AppealOut])
async def list_my_appeals(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[AppealOut]:
    items = await appeal_service.list_my_appeals(db, user)
    return [AppealOut.model_validate(a) for a in items]


@appeals_router.get("/{appeal_id}", response_model=AppealOut)
async def get_appeal(
    appeal_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AppealOut:
    appeal = await appeal_service.get_appeal(db, user, appeal_id)
    return AppealOut.model_validate(appeal)


@appeals_router.post("/{appeal_id}/withdraw", response_model=AppealOut)
async def withdraw_appeal(
    appeal_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AppealOut:
    appeal = await appeal_service.withdraw_appeal(db, user, appeal_id)
    return AppealOut.model_validate(appeal)


# ---------- GV/BTC + BCN ----------

@contests_appeals_router.get("/{contest_id}/appeals", response_model=list[AppealOut])
async def list_contest_appeals(
    contest_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    status_filter: Annotated[str | None, Query(alias="status")] = None,
) -> list[AppealOut]:
    items = await appeal_service.list_contest_appeals(db, user, contest_id, status_filter)
    return [AppealOut.model_validate(a) for a in items]


@appeals_router.post("/{appeal_id}/start-review", response_model=AppealOut)
async def start_review(
    appeal_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AppealOut:
    appeal = await appeal_service.start_review(db, user, appeal_id)
    return AppealOut.model_validate(appeal)


@appeals_router.post("/{appeal_id}/resolve", response_model=AppealOut)
async def resolve_appeal(
    appeal_id: int,
    data: AppealResolveIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> AppealOut:
    appeal = await appeal_service.resolve_appeal(
        db, user, appeal_id, data.decision, data.response_text
    )
    return AppealOut.model_validate(appeal)


@contests_appeals_router.patch("/{contest_id}/appeal-window")
async def set_appeal_window(
    contest_id: int,
    data: AppealWindowIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> dict:
    contest = await appeal_service.set_appeal_window(
        db, user, contest_id, data.appeal_deadline
    )
    return {
        "contest_id": contest.contest_id,
        "appeal_deadline": contest.appeal_deadline,
    }
