"""Pydantic schemas cho contest reviews (SV-11)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class ReviewCreateIn(BaseModel):
    """SV-11 POST /api/contests/{id}/reviews."""

    rating: int = Field(..., ge=1, le=5, description="1-5 sao")
    comment_text: str | None = Field(None, max_length=2000)


class ReviewUpdateIn(BaseModel):
    """SV-11 PATCH /api/contests/{id}/reviews/me — sửa review của mình."""

    rating: int | None = Field(None, ge=1, le=5)
    comment_text: str | None = Field(None, max_length=2000)


class ReviewModerateIn(BaseModel):
    """AD-06 PATCH /api/admin/reviews/{id}/moderate — admin ẩn/hiện review."""

    is_visible: bool
    moderation_note: str | None = Field(None, max_length=500)


class ReviewOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    review_id: int
    contest_id: int
    student_id: int
    rating: int
    comment_text: str | None = None
    is_visible: bool
    created_at: datetime
    updated_at: datetime


class ReviewSummaryOut(BaseModel):
    """Aggregate stats cho list reviews + GET /contests/{id}/reviews/summary."""

    total: int
    average_rating: float
    distribution: dict[int, int] = Field(
        default_factory=dict,
        description="Số review theo rating, vd: {1:0, 2:1, 3:5, 4:10, 5:8}",
    )
