"""FastAPI app entry point."""

from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.database import engine
from app.middleware.audit import AuditASGIMiddleware
from app.routers import (
    admin,
    approvals,
    auth,
    certificates,
    contests,
    entries,
    judging,
    notifications,
    reports,
    results,
    reviews,
    submissions,
    teams,
    users,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"PTIT Contest API starting in {settings.app_env} mode")
    print(f"   DB: {settings.database_url.split('@')[-1]}")
    yield
    await engine.dispose()
    print("Shutdown complete")


app = FastAPI(
    title=settings.app_name,
    version="1.0.0",
    description="Backend cho he thong quan ly cuoc thi sinh vien PTIT — full coverage 30/30 functions",
    lifespan=lifespan,
    docs_url=f"{settings.api_prefix}/docs",
    redoc_url=f"{settings.api_prefix}/redoc",
    openapi_url=f"{settings.api_prefix}/openapi.json",
)

app.add_middleware(AuditASGIMiddleware)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    # Cho phép truy cập từ LAN (vd iPhone Safari trên cùng WiFi).
    # Pattern khớp: localhost / 127.0.0.1 / 10.x.x.x / 172.16-31.x.x / 192.168.x.x
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1|10\.\d+\.\d+\.\d+|172\.(1[6-9]|2\d|3[01])\.\d+\.\d+|192\.168\.\d+\.\d+)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["meta"])
async def health() -> dict[str, str]:
    return {"status": "ok", "app": settings.app_name, "env": settings.app_env}


P = settings.api_prefix

# Auth + profile
app.include_router(auth.router, prefix=P)
app.include_router(users.me_router, prefix=P)
app.include_router(users.auth_router, prefix=P)

# Contests
app.include_router(contests.router, prefix=P)
app.include_router(approvals.contests_submit_router, prefix=P)

# Entries
app.include_router(entries.contest_entries_router, prefix=P)
app.include_router(entries.entries_router, prefix=P)

# Teams
app.include_router(teams.contest_teams_router, prefix=P)
app.include_router(teams.teams_router, prefix=P)

# Approvals
app.include_router(approvals.me_pending_router, prefix=P)
app.include_router(approvals.approvals_router, prefix=P)

# Submissions
app.include_router(submissions.rounds_router, prefix=P)
app.include_router(submissions.submissions_router, prefix=P)

# Judging
app.include_router(judging.rounds_router, prefix=P)
app.include_router(judging.me_assignments_router, prefix=P)
app.include_router(judging.assignments_router, prefix=P)

# Results
app.include_router(results.contests_results_router, prefix=P)
app.include_router(results.contest_result_router, prefix=P)
app.include_router(results.me_results_router, prefix=P)

# Reviews
app.include_router(reviews.contests_reviews_router, prefix=P)

# Notifications
app.include_router(notifications.me_notifications_router, prefix=P)

# Certificates
app.include_router(certificates.contests_certs_router, prefix=P)
app.include_router(certificates.templates_router, prefix=P)
app.include_router(certificates.certs_router, prefix=P)
app.include_router(certificates.verify_router)

# Admin
app.include_router(admin.router, prefix=P)

# Reports (GV-07, BCN-03, BCN-05, AD-05)
app.include_router(reports.contests_stats_router, prefix=P)
app.include_router(reports.admin_reports_router, prefix=P)
app.include_router(reports.reports_router, prefix=P)
