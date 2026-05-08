"""Pydantic schemas cho reports/stats (GV-07, BCN-03, BCN-05, AD-05)."""

from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, Field


# ---------- GV-07 contest stats ----------

class ContestStatsOut(BaseModel):
    """GV-07 GET /api/contests/{id}/stats — stats cho 1 contest."""

    contest_id: int
    contest_title: str
    contest_status: str

    total_entries: int = Field(0, description="Tất cả entries (mọi status)")
    approved_entries: int = 0
    pending_entries: int = 0
    rejected_entries: int = 0
    cancelled_entries: int = 0

    total_submissions: int = 0
    submitted_count: int = 0
    late_count: int = 0

    rounds_count: int = 0
    rounds_with_results: int = 0

    average_final_score: Decimal | None = None
    pass_rate_percent: Decimal | None = Field(None, description="Tỷ lệ entry có rank trong top 50%")
    avg_review_rating: Decimal | None = None
    review_count: int = 0


# ---------- BCN-03 monitor ----------

class ContestProgressItem(BaseModel):
    """1 item trong monitor list."""

    contest_id: int
    title: str
    slug: str
    status: str
    start_at: str | None = None
    end_at: str | None = None

    registration_pct: float | None = Field(None, description="entries / max_entries")
    submission_pct: float | None = Field(None, description="submissions / approved entries")
    judging_pct: float | None = Field(None, description="rounds_with_results / total_rounds")

    total_entries: int = 0
    total_submissions: int = 0


class MonitorOut(BaseModel):
    items: list[ContestProgressItem]
    total: int


# ---------- BCN-05 faculty summary ----------

class FacultySummaryOut(BaseModel):
    """BCN-05 GET /api/reports/faculty-summary — stats theo khoa."""

    faculty_id: int
    faculty_code: str
    faculty_name: str
    year: int

    total_contests: int = 0
    contests_finished: int = 0
    contests_ongoing: int = 0
    contests_draft_or_pending: int = 0

    total_unique_students: int = 0
    total_entries: int = 0
    total_awards: int = 0
    avg_completion_rate: Decimal | None = None
    avg_rating: Decimal | None = None


# ---------- AD-05 system summary ----------

class SystemSummaryOut(BaseModel):
    """AD-05 GET /api/admin/reports/system-summary — toàn hệ thống."""

    year: int
    total_users: int = 0
    students_active: int = 0
    organizers: int = 0
    judges: int = 0
    department_heads: int = 0
    admins: int = 0

    total_contests: int = 0
    contests_published_or_after: int = 0
    contests_finished: int = 0
    total_entries: int = 0
    total_submissions: int = 0
    total_certificates_issued: int = 0
    total_reviews: int = 0
    avg_review_rating: Decimal | None = None


# ---------- Sprint 23 (2026-05-09): BCN/BTC dashboard real-data ----------

class ApprovalStatsOut(BaseModel):
    """BCN dashboard donut chart — count by approval status trong N ngày."""

    days: int
    approved: int = 0
    revision_requested: int = 0
    rejected: int = 0
    total: int = 0
    avg_processing_hours: float | None = None


class BcnDeltasOut(BaseModel):
    """BCN dashboard 4 stat cards với trend deltas."""

    queue_pending: int = 0
    queue_pending_delta_24h: int = 0  # so với 24h trước (- = giảm)
    urgent_count: int = 0  # SLA ≤24h sắp hết hạn
    contests_ongoing: int = 0
    contests_ongoing_delta_7d: int = 0
    students_total: int = 0
    students_delta_30d: int = 0


class BtcDeltasOut(BaseModel):
    """BTC dashboard 4 stat cards với trend deltas."""

    contests_ongoing: int = 0
    contests_ongoing_delta_7d: int = 0
    submissions_pending_judge: int = 0
    submissions_judged_24h: int = 0
    registrations_pending: int = 0
    registrations_pending_delta_24h: int = 0
    students_total: int = 0


class ActivityFeedItemOut(BaseModel):
    """1 entry trong activity feed."""

    timestamp: datetime
    action: str  # vd "approve_q1", "submit_proposal", "register"
    actor_name: str | None = None
    contest_title: str | None = None
    contest_id: int | None = None
    note: str | None = None


class ActivityFeedOut(BaseModel):
    items: list[ActivityFeedItemOut] = []
    total: int = 0
