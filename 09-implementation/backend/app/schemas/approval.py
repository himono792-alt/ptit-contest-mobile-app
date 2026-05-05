"""Pydantic schemas cho workflow approval (BCN_QĐ1, BCN_QĐ2)."""

from datetime import datetime
from enum import Enum
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import ApprovalStatus, ApprovalStep, ApprovalTarget


class DecideAction(str, Enum):
    """3 hành động BCN có thể chọn khi review."""

    APPROVE = "approve"
    REJECT = "reject"
    REQUEST_REVISION = "request_revision"


class DecisionIn(BaseModel):
    """BCN-02 / BCN-04 POST /api/approvals/{id}/decide."""

    action: DecideAction
    comment: str | None = Field(None, description="Bắt buộc nếu reject/request_revision")


class SubmitForApprovalOut(BaseModel):
    """BTC GV-02 POST /api/contests/{id}/submit-for-approval — return mới."""

    approval_id: int
    revision_round: int
    target_type: ApprovalTarget
    step: ApprovalStep
    status: ApprovalStatus


class ApprovalSummary(BaseModel):
    """Lightweight cho list pending."""

    model_config = ConfigDict(from_attributes=True)

    approval_id: int
    target_type: ApprovalTarget
    contest_id: int
    contest_title: str | None = None  # populated từ join
    contest_slug: str | None = None
    step: ApprovalStep
    status: ApprovalStatus
    revision_round: int
    submitted_by: int
    submitted_at: datetime
    submission_note: str | None = None


class ApprovalDetail(ApprovalSummary):
    """Full detail (BCN xem để decide)."""

    reviewed_by: int | None = None
    reviewed_at: datetime | None = None
    bcn_comment: str | None = None
    snapshot_json: dict[str, Any] | None = None
    created_at: datetime
    updated_at: datetime
