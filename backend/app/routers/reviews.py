"""Reviews router (SV-11)."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.schemas.review import (
    ReviewCreateIn,
    ReviewOut,
    ReviewSummaryOut,
    ReviewUpdateIn,
)
from app.services import review_service

contests_reviews_router = APIRouter(prefix="/contests", tags=["reviews"])


@contests_reviews_router.post(
    "/{contest_id}/reviews",
    response_model=ReviewOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_review(
    contest_id: int,
    data: ReviewCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReviewOut:
    """SV-11 — Đánh giá cuộc thi (rating 1-5 sao + comment).

    Yêu cầu: contest đang FINISHED + SV có result published.
    """
    review = await review_service.create_review(
        db, user, contest_id, data.rating, data.comment_text
    )
    return ReviewOut.model_validate(review)


@contests_reviews_router.patch("/{contest_id}/reviews/me", response_model=ReviewOut)
async def update_my_review(
    contest_id: int,
    data: ReviewUpdateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReviewOut:
    """SV-11 — Sửa review của mình."""
    review = await review_service.update_my_review(
        db, user, contest_id, data.rating, data.comment_text
    )
    return ReviewOut.model_validate(review)


@contests_reviews_router.get("/{contest_id}/reviews", response_model=list[ReviewOut])
async def list_reviews(
    contest_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[ReviewOut]:
    """Public — list reviews visible của contest (cho SV-05 detail page)."""
    items = await review_service.list_visible_reviews(db, contest_id)
    return [ReviewOut.model_validate(r) for r in items]


@contests_reviews_router.get("/{contest_id}/reviews/summary", response_model=ReviewSummaryOut)
async def get_review_summary(
    contest_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ReviewSummaryOut:
    """Public — aggregate stats (avg rating, distribution)."""
    return ReviewSummaryOut(**await review_service.get_summary(db, contest_id))
