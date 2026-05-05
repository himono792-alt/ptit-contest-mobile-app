"""FastAPI app entry point."""

import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.config import settings
from app.database import engine
from app.middleware.audit import (
    AuditASGIMiddleware,
    start_audit_worker,
    stop_audit_worker,
)


# ----- Phase 1 step 1 (2026-05-06): Sentry error tracking -----
# Init NGAY trước khi tạo FastAPI() để Sentry catch cả lỗi import / startup config.
# Skip init nếu SENTRY_DSN rỗng (dev mode hoặc local).
if settings.sentry_dsn:
    try:
        import sentry_sdk
        from sentry_sdk.integrations.asyncio import AsyncioIntegration
        from sentry_sdk.integrations.fastapi import FastApiIntegration
        from sentry_sdk.integrations.sqlalchemy import SqlalchemyIntegration
        from sentry_sdk.integrations.starlette import StarletteIntegration

        # Release tag: ưu tiên config, fallback Railway env, cuối cùng "unknown"
        release = (
            settings.sentry_release
            or os.environ.get("RAILWAY_GIT_COMMIT_SHA", "")
            or "unknown"
        )

        sentry_sdk.init(
            dsn=settings.sentry_dsn,
            environment=settings.app_env,
            release=release,
            traces_sample_rate=settings.sentry_traces_sample_rate,
            # GDPR-safer default: không gửi PII (email, IP, headers) trừ khi explicit
            send_default_pii=False,
            integrations=[
                StarletteIntegration(transaction_style="endpoint"),
                FastApiIntegration(transaction_style="endpoint"),
                SqlalchemyIntegration(),
                AsyncioIntegration(),
            ],
            # Tự động attach stack trace cho mọi message log level WARNING+
            attach_stacktrace=True,
        )
        logging.getLogger("sentry").info(
            "Sentry initialized — env=%s release=%s traces=%.2f",
            settings.app_env, release, settings.sentry_traces_sample_rate,
        )
    except Exception as e:
        # Không bao giờ để Sentry init crash app — fail open
        logging.getLogger("sentry").warning("Sentry init failed: %s", e)
else:
    logging.getLogger("sentry").info("Sentry skipped — SENTRY_DSN rỗng")
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


# Sprint 0 / P0-1 (audit 2026-05-06): idempotent block đã được inline vào schema v04.
# Giữ block này LÀM SAFETY NET cho:
#   - DB production cũ (đã chạy v03) — block sẽ no-op vì cột đã có
#   - Trường hợp Alembic chưa kịp upgrade (race condition cold-start)
# Sau khi Alembic baseline ổn định 1-2 tháng → có thể xóa hẳn.
_PROFILE_MIGRATION_SQL = """
ALTER TABLE ptit_contest.app_users
  ADD COLUMN IF NOT EXISTS dob DATE,
  ADD COLUMN IF NOT EXISTS gender VARCHAR(10),
  ADD COLUMN IF NOT EXISTS citizen_id VARCHAR(20),
  ADD COLUMN IF NOT EXISTS place_of_birth VARCHAR(150),
  ADD COLUMN IF NOT EXISTS address VARCHAR(500),
  ADD COLUMN IF NOT EXISTS ethnicity VARCHAR(50),
  ADD COLUMN IF NOT EXISTS religion VARCHAR(50),
  ADD COLUMN IF NOT EXISTS nationality VARCHAR(50),
  ADD COLUMN IF NOT EXISTS secondary_email VARCHAR(255);

ALTER TABLE ptit_contest.submission_files
  ADD COLUMN IF NOT EXISTS file_data BYTEA;
"""


@asynccontextmanager
async def lifespan(app: FastAPI):
    print(f"PTIT Contest API starting in {settings.app_env} mode")
    print(f"   DB: {settings.database_url.split('@')[-1]}")
    # Idempotent migration cho profile fields mở rộng (2026-05-05)
    # Note: Sau khi chuyển sang Alembic baseline (Sprint 0 P0-4), block này sẽ là
    # safety net cho các DB cũ chưa migrate. DB mới đã có cột trong init-schema v04.
    try:
        async with engine.begin() as conn:
            await conn.execute(text(_PROFILE_MIGRATION_SQL))
        print("Profile fields migration: ok (idempotent safety net)")
    except Exception as e:
        print(f"Profile fields migration WARN: {e}")

    # Fix P0-3 (audit 2026-05-06): start audit worker fire-and-forget
    await start_audit_worker()

    yield

    await stop_audit_worker()
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
    allow_origin_regex=r"^https?://(localhost|127\.0\.0\.1|10\.\d+\.\d+\.\d+|172\.(1[6-9]|2\d|3[01])\.\d+\.\d+|192\.168\.\d+\.\d+|[a-z0-9-]+\.netlify\.app|[a-z0-9-]+\.vercel\.app|[a-z0-9-]+\.up\.railway\.app)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["meta"])
async def health() -> dict[str, str]:
    return {"status": "ok", "app": settings.app_name, "env": settings.app_env}


# Phase 1 step 1 (2026-05-06): Sentry test endpoint — gọi 1 lần để verify Sentry
# nhận được event, sau đó SẼ XÓA. Yêu cầu query token để tránh trigger nhầm.
# Token = first 8 chars của SENTRY_DSN, hoặc "verify-2026-05-06" nếu DSN rỗng.
@app.get("/debug-sentry", tags=["meta"], include_in_schema=False)
async def debug_sentry(token: str = "") -> dict:
    expected = (
        settings.sentry_dsn[:8] if settings.sentry_dsn
        else "verify-2026-05-06"
    )
    if token != expected:
        return {
            "msg": "Sentry test endpoint. Cần query ?token=<8 char đầu của SENTRY_DSN>",
            "hint_dev": "verify-2026-05-06" if not settings.sentry_dsn else None,
        }
    # Trigger artificial exception → Sentry phải capture
    1 / 0
    return {"unreachable": True}


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
app.include_router(entries.me_entries_router, prefix=P)

# Teams
app.include_router(teams.contest_teams_router, prefix=P)
app.include_router(teams.teams_router, prefix=P)
app.include_router(teams.me_teams_router, prefix=P)

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
app.include_router(certificates.verify_router, prefix=P)  # /api/verify/{qr_code} — fix 2026-05-06 (P0-2 audit)

# Admin
app.include_router(admin.router, prefix=P)

# Reports (GV-07, BCN-03, BCN-05, AD-05)
app.include_router(reports.contests_stats_router, prefix=P)
app.include_router(reports.admin_reports_router, prefix=P)
app.include_router(reports.reports_router, prefix=P)
