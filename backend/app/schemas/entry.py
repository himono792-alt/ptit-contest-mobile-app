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
    schedule_conflict_ack: bool = False
    created_at: datetime


class EntryReviewAction(str, Enum):
    APPROVE = "approve"
    REJECT = "reject"


class ReviewEntryIn(BaseModel):
    """GV-03 PATCH /api/entries/{id} — duyệt/từ chối đăng ký."""

    action: EntryReviewAction
    note: str | None = Field(None, description="Bắt buộc nếu reject")


# ---------- Phase 2 sprint 1 step 2 (2026-05-06): Bulk review ----------

class BulkReviewIn(BaseModel):
    """GV-03 POST /api/contests/{cid}/entries/bulk-review — duyệt/từ chối nhiều entries 1 lần.

    Productivity feature: thay vì 50 click × 3s = 2.5p, chỉ 1 request = 5s.
    Max 100 entries/request để chống timeout và làm dễ retry partial fail.
    """

    entry_ids: list[int] = Field(..., min_length=1, max_length=100,
                                  description="Danh sách entry_id cần review (1-100)")
    action: EntryReviewAction
    note: str | None = Field(None, description="Bắt buộc nếu reject (áp dụng chung cho tất cả)")


class BulkReviewFailedItem(BaseModel):
    entry_id: int
    reason: str


class BulkReviewOut(BaseModel):
    """Response bulk review.

    Partial commit pattern: success entries đã commit, failed list để FE show user
    biết entry nào còn pending. Không rollback toàn bộ vì có thể chỉ 1-2 entry bị
    lỗi (vd đã approved trước đó) — không nên fail luôn 98 entries còn lại.
    """

    success_count: int
    failed: list[BulkReviewFailedItem]
    total_requested: int


class MyEntryItem(BaseModel):
    """SV-10 GET /me/entries — entry của SV + contest info kèm theo."""

    model_config = ConfigDict(from_attributes=True)

    entry_id: int
    contest_id: int
    contest_slug: str
    contest_title: str
    contest_status: str
    entry_type: str
    team_id: int | None = None
    registration_status: RegistrationStatus
    participant_status: ParticipantStatus
    registration_note: str | None = None
    created_at: datetime
    contest_start_at: datetime
    contest_end_at: datetime
