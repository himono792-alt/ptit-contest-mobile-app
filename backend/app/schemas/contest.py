"""Pydantic schemas cho contest endpoints."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.enums import (
    ContestStatus,
    DeliveryMode,
    EntryType,
    RoundType,
    SessionType,
)


# ---------- READ ----------

class ContestSummary(BaseModel):
    """Lightweight schema cho list (SV-04, BCN-03, GV-02 list)."""

    model_config = ConfigDict(from_attributes=True)

    contest_id: int
    slug: str
    title: str
    delivery_mode: DeliveryMode
    participation_mode: EntryType
    status: ContestStatus
    start_at: datetime
    end_at: datetime
    registration_open_at: datetime | None = None
    registration_close_at: datetime | None = None
    max_entries: int | None = None
    host_faculty_id: int | None = None
    is_public: bool
    # Sprint 4 fix M10 (2026-05-07): count entries APPROVED + PENDING để admin
    # thấy "12/100" thay vì chỉ "max 100" (mix max setting với actual count).
    # Default 0 nếu schema cũ không inject (backward-compat).
    entries_count: int = 0


class ContestDetail(ContestSummary):
    """Full detail (SV-05 GET /api/contests/{slug})."""

    description: str | None = None
    rules_text: str | None = None
    award_text: str | None = None
    banner_url: str | None = None
    location_text: str | None = None
    team_min_members: int | None = None
    team_max_members: int | None = None
    requires_submission: bool
    appeal_deadline: datetime | None = None
    proposed_by: int | None = None
    created_by: int
    created_at: datetime
    updated_at: datetime


class ContestListOut(BaseModel):
    items: list[ContestSummary]
    total: int
    page: int
    size: int


# ---------- WRITE (GV-02) ----------

class ContestCreateIn(BaseModel):
    """GV-02 POST /api/contests — tạo contest mới ở status DRAFT."""

    slug: str = Field(..., min_length=3, max_length=120, pattern=r"^[a-z0-9-]+$")
    title: str = Field(..., min_length=3, max_length=255)
    description: str | None = None
    rules_text: str | None = None
    award_text: str | None = None
    banner_url: str | None = None
    delivery_mode: DeliveryMode
    participation_mode: EntryType
    team_min_members: int | None = Field(None, ge=1)
    team_max_members: int | None = Field(None, ge=1)
    max_entries: int | None = Field(None, ge=1)
    requires_submission: bool = False
    is_public: bool = True
    registration_open_at: datetime | None = None
    registration_close_at: datetime | None = None
    start_at: datetime
    end_at: datetime
    location_text: str | None = Field(None, max_length=255)
    host_faculty_id: int | None = None

    @field_validator("end_at")
    @classmethod
    def _end_after_start(cls, v: datetime, info) -> datetime:
        start = info.data.get("start_at")
        if start and v <= start:
            raise ValueError("end_at phải sau start_at")
        return v


class ContestUpdateIn(BaseModel):
    """GV-02 PATCH /api/contests/{id} — partial update.

    Chỉ allow update khi status IN (DRAFT, REVISION_REQUESTED).
    Không cho đổi slug sau khi tạo (immutable identifier).
    """

    title: str | None = Field(None, min_length=3, max_length=255)
    description: str | None = None
    rules_text: str | None = None
    award_text: str | None = None
    banner_url: str | None = None
    delivery_mode: DeliveryMode | None = None
    participation_mode: EntryType | None = None
    team_min_members: int | None = Field(None, ge=1)
    team_max_members: int | None = Field(None, ge=1)
    max_entries: int | None = Field(None, ge=1)
    requires_submission: bool | None = None
    is_public: bool | None = None
    registration_open_at: datetime | None = None
    registration_close_at: datetime | None = None
    start_at: datetime | None = None
    end_at: datetime | None = None
    location_text: str | None = Field(None, max_length=255)
    host_faculty_id: int | None = None


# ---------- ROUND ----------

class ContestRoundOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    round_id: int
    contest_id: int
    round_no: int
    round_name: str
    round_type: RoundType
    description: str | None = None
    start_at: datetime
    end_at: datetime
    submission_open_at: datetime | None = None
    submission_close_at: datetime | None = None
    judging_open_at: datetime | None = None
    judging_close_at: datetime | None = None
    is_elimination_round: bool


class ContestRoundCreateIn(BaseModel):
    round_no: int = Field(..., ge=1)
    round_name: str = Field(..., min_length=2, max_length=150)
    round_type: RoundType = RoundType.OTHER
    description: str | None = None
    start_at: datetime
    end_at: datetime
    submission_open_at: datetime | None = None
    submission_close_at: datetime | None = None
    judging_open_at: datetime | None = None
    judging_close_at: datetime | None = None
    is_elimination_round: bool = False


# ---------- SESSION ----------

class ContestSessionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    session_id: int
    contest_id: int
    round_id: int | None = None
    session_name: str
    session_type: SessionType
    start_at: datetime
    end_at: datetime
    location_text: str | None = None
    room_text: str | None = None
    online_meeting_url: str | None = None
    checkin_open_at: datetime | None = None
    checkin_close_at: datetime | None = None


class ContestSessionCreateIn(BaseModel):
    session_name: str = Field(..., min_length=2, max_length=150)
    session_type: SessionType
    round_id: int | None = None
    start_at: datetime
    end_at: datetime
    location_text: str | None = Field(None, max_length=255)
    room_text: str | None = Field(None, max_length=100)
    online_meeting_url: str | None = None
    checkin_open_at: datetime | None = None
    checkin_close_at: datetime | None = None
