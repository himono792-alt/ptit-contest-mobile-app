# Changelog — PTIT Contest Backend

Tất cả thay đổi notable cho backend được ghi tại đây.

Format dựa trên [Keep a Changelog](https://keepachangelog.com/), versioning [SemVer](https://semver.org/).

---

## [Unreleased]

— (chưa có thay đổi mới)

---

## [1.0.0] — 2026-05-08

Production v1.0 stable. 104 endpoints qua 16 router. Deploy Railway auto.

### Added (Sprint 19 — 2026-05-08)
— No backend changes (Sprint 19 frontend-only login redesign)

### Added (Sprint 16 — 2026-05-08)
- `GET /api/rounds/{id}` — Round detail trả `submission_close_at` + `end_at` cho FE countdown timer
- `GET /api/contests/{id}/leaderboard` — Enriched data với `display_name` (join Student/Team), `entry_type`, `rank_no`, `final_score`, `award_title`
- `result_service.list_leaderboard()` — Bulk fetch student names + team names

### Changed (Sprint 16 — 2026-05-08)
- `judging_service.list_my_judge_assignments` — Enrich response với `is_scored`, `scored_count`, `total_criteria` cho FE filter unscored vs scored
- Response type `list[dict]` thay vì `list[JudgeAssignmentOut]` model

### Added (Sprint 15 — 2026-05-08)
- `seed-test-users.py` — `remove_role()` function cho cleanup legacy seed
- gv@ test user: cleanup ADMIN role (chỉ giữ ORGANIZER + JUDGE)

### Added (Sprint 12 — 2026-05-08)
- `GET /api/contests/{id}/stats` — Real-time aggregation 6 metric (đăng ký/chờ duyệt/bài nộp/vòng/điểm TB/tỷ lệ pass)

### Fixed (Sprint 12)
- Pydantic `Decimal` serialize bug — frontend nhận string thay number, fix với `_parseNum()` helper
- Reviews summary field names — `average_rating` + `distribution` map (không phải `avg_rating` + `visible_count`)

### Added (Sprint 11 — 2026-05-08)
- `PATCH /certificate-templates/{id}/approve` — BCN duyệt cert template (QĐ3) — workflow 3 cấp QĐ1+QĐ2+QĐ3 hoàn thiện
- `POST /submissions/{id}/lock` — GV anti-tamper khi judging

### Added (Sprint 9b — 2026-05-08)
- `GET /admin/reports/system-summary.xlsx` — Excel export 3 sheets (Tổng quan / Phân loại user / Metadata)
- `report_service.export_system_summary_xlsx()` với `aiobotocore` streaming

### Added (Sprint 9 — 2026-05-08)
- `POST /api/auth/register` — Self-signup SV
- `POST /api/auth/otp/request` + `POST /api/auth/otp/verify` — OTP passwordless login
- `POST /api/contests/{id}/sessions` + `GET /api/contests/{id}/sessions` — Sessions CRUD
- `DELETE /api/rounds/{id}/criteria/{cid}` — Delete scoring criterion
- `GET /api/contests/{id}/reviews/summary` — Review aggregation

### Fixed (Sprint 8 — 2026-05-07)
- Deep-link `/admin/<tab>` 404 — slug whitelist + fallback Dashboard
- 11 bug fix verified live qua Chrome MCP smoke test 4 actor (SV/GV/BCN/Admin)
- Test User 81463 cleanup
- email.smtp_host empty config

### Added (Sprint 3 — 2026-05-07)
- Cloudflare R2 client (S3-compat) cho file submission upload
- Bucket `ptit-contest-submissions` hierarchy `contests/{cid}/rounds/{rid}/entries/{eid}/v{n}/{filename}`
- `app/core/r2_client.py` với aiobotocore async

### Added (Phase 1 — 2026-05-06)
- Sentry backend error tracking via `SENTRY_DSN`
- Rate limit slowapi 10/min cho auth endpoints
- Refresh token rotation
- Email service Brevo HTTP API (Railway block SMTP TCP)
- HSTS A+ với 6 security headers (đọc `X-Forwarded-Proto`)

### Added (Phase 0 — Initial 2026-05-04)
- 43 SQLAlchemy 2.0 async models
- Alembic baseline `0001_baseline_v04.py`
- 16 router với 104 endpoints
- Workflow approval BCN_QD1 (contest) + BCN_QD2 (results)
- JWT HS256 auth + bcrypt password hash
- pyproject.toml + ruff + pytest config

---

## Reference

- Báo cáo CNPM: `../../11-docs/deliverables/2026-05-07_bao-cao-cnpm_v02.md`
- Frontend changelog: `../frontend/CHANGELOG.md`
