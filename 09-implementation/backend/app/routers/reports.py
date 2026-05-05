"""Reports / stats router (GV-07, BCN-03, BCN-05, AD-05)."""

from datetime import datetime, timezone
from typing import Annotated

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.schemas.report import (
    ContestProgressItem,
    ContestStatsOut,
    FacultySummaryOut,
    MonitorOut,
    SystemSummaryOut,
)
from app.services import report_service

contests_stats_router = APIRouter(prefix="/contests", tags=["reports"])
admin_reports_router = APIRouter(prefix="/admin", tags=["reports"])
reports_router = APIRouter(prefix="/reports", tags=["reports"])


# ---------- GV-07 ----------

@contests_stats_router.get("/{contest_id}/stats", response_model=ContestStatsOut)
async def get_contest_stats(
    contest_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> ContestStatsOut:
    """GV-07 — Stats cho 1 contest (BTC contest hoặc Admin)."""
    return ContestStatsOut(**await report_service.contest_stats(db, user, contest_id))


# ---------- BCN-03 ----------

@admin_reports_router.get("/contests/monitor", response_model=MonitorOut)
async def monitor_contests(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    faculty_id: int | None = Query(None, description="Admin only — HOD bị filter theo khoa của mình"),
) -> MonitorOut:
    """BCN-03 — Giám sát tiến độ contests (% hoàn thành mỗi giai đoạn)."""
    items = await report_service.monitor_contests(db, user, faculty_id)
    return MonitorOut(
        items=[ContestProgressItem(**it) for it in items],
        total=len(items),
    )


# ---------- BCN-05 ----------

@reports_router.get("/faculty-summary", response_model=FacultySummaryOut)
async def faculty_summary(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    faculty_id: int | None = Query(None, description="HOD bị filter, Admin truyền tay"),
    year: int = Query(default_factory=lambda: datetime.now(timezone.utc).year),
) -> FacultySummaryOut:
    """BCN-05 — Báo cáo tổng hợp theo khoa (số contest/SV/giải/đánh giá)."""
    return FacultySummaryOut(**await report_service.faculty_summary(db, user, faculty_id, year))


# ---------- AD-05 ----------

@admin_reports_router.get("/reports/system-summary", response_model=SystemSummaryOut)
async def system_summary(
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
    year: int = Query(default_factory=lambda: datetime.now(timezone.utc).year),
) -> SystemSummaryOut:
    """AD-05 — Báo cáo toàn hệ thống."""
    return SystemSummaryOut(**await report_service.system_summary(db, user, year))
