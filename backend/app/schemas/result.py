"""Pydantic schemas cho contest results (GV-06, SV-09, BCN-04)."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import ApprovalStatus


class ContestResultOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    contest_result_id: int
    contest_id: int
    entry_id: int
    final_score: Decimal | None = None
    rank_no: int | None = None
    award_title: str | None = None
    bcn_approval_status: ApprovalStatus
    published_at: datetime | None = None
    generated_by: int | None = None
    created_at: datetime


class AwardUpdateIn(BaseModel):
    """GV-06 PATCH /api/contest-results/{id} — chỉnh giải thưởng."""

    award_title: str | None = Field(None, max_length=255)


class PublishResultsOut(BaseModel):
    """GV-06 POST /api/contests/{id}/results/publish — kết quả publish."""

    contest_id: int
    published_at: datetime
    contest_status: str
    notified_count: int = Field(0, description="Số SV đã đăng ký APPROVED được bulk-notify")


class MyResultOut(BaseModel):
    """SV-09 GET /api/me/results — kết quả của SV cho từng contest."""

    model_config = ConfigDict(from_attributes=True)

    contest_id: int
    contest_title: str
    contest_slug: str
    entry_id: int
    final_score: Decimal | None = None
    rank_no: int | None = None
    award_title: str | None = None
    published_at: datetime
    cert_qr_code: str | None = None
