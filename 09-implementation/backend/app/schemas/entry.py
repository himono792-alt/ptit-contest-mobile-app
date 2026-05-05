"""Pydantic schemas cho contest entries (SV-06 đăng ký, GV-03 phê duyệt, SV-10 hủy)."""

from datetime import datetime
from enum import Enum

from pydantic import BaseModel, ConfigDict, Field

from app.models.enums import ParticipantStatus, RegistrationStatus


class RegisterIndividualIn(BaseModel):
    """SV-06 — đăng ký cá nhân (contest có participation_mode=INDIVIDUAL)."""

    note: str | None = Field(None, description="Ghi chú đăng ký")


class RegisterTeamIn(BaseModel):
    """SV-06 — đăng ký theo team (contest có participation_mode=TEAM)."""

    team_id: int = Field(..., description="Team đã tạo trước, leader = SV hiện tại")
    note: str | None = None


class EntryListItem(BaseModel):
    """Item trong list entries (GV-03 view)."""

    model_config = ConfigDict(from_attributes=True)

    entry_id: int
    contest_id: int
    entry_type: str
    student_id: int | None = None
    team_id: int | None = None
    anonymous_code: str | None = None
    registration_status: RegistrationStatus
    participant_status: ParticipantStatus
    approved_by: int | None = None
    approved_at: datetime | None = None
    registration_note: str | None = None
    created_at: datetime


class EntryReviewAction(str, Enum):
    APPROVE = "approve"
    REJECT = "reject"


class ReviewEntryIn(BaseModel):
    """GV-03 PATCH /api/entries/{id} — duyệt/từ chối đăng ký."""

    action: EntryReviewAction
    note: str | None = Field(None, description="Bắt buộc nếu reject")
