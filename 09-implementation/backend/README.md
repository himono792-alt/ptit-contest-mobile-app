# PTIT Contest — Backend (FastAPI)

Backend API cho hệ thống quản lý cuộc thi sinh viên PTIT.

**Stack:** Python 3.11+ · FastAPI · SQLAlchemy 2.0 (async) · asyncpg · PostgreSQL · Alembic · Pydantic v2 · JWT (python-jose) · openpyxl · aiobotocore (R2 S3-compat)

**Production:** https://ptit-contest-mobile-app-production.up.railway.app — Railway deploy auto qua git push
**Swagger UI:** https://ptit-contest-mobile-app-production.up.railway.app/api/docs

---

## Trạng thái v1.0 (2026-05-08)

| Thành phần | Trạng thái | Ghi chú |
|---|---|---|
| Project structure | ✅ | `app/` chia theo layer: models, schemas, services, routers, deps |
| Config + DB engine | ✅ | `app/config.py` (pydantic-settings), `app/database.py` (async, pool 4+2) |
| Security | ✅ | `app/security.py` bcrypt + JWT HS256 + refresh token rotation |
| Models | ✅ | 43 SQLAlchemy 2.0 models trong 12 file domain |
| **104 endpoints qua 16 router** | ✅ | auth · admin · contests · entries · judging · submissions · teams · reviews · results · notifications · reports · certificates · approvals · anomaly · me · auth-extra |
| Alembic | ✅ | `0001_baseline_v04.py` baseline (init-schema.sql) |
| Workflow phê duyệt 3 cấp | ✅ | QĐ1 (BCN duyệt contest) + QĐ2 (BCN duyệt kết quả) + QĐ3 (BCN duyệt cert template) |
| Sentry error tracking | ✅ | Wired qua `SENTRY_DSN` env, tag `app.platform: backend` |
| Email service | ✅ | Brevo HTTP API (Railway block SMTP TCP 25/465/587) |
| Object storage | ✅ | Cloudflare R2 bucket `ptit-contest-submissions` (S3-compat) |
| Rate limit | ✅ | slowapi 10/min cho auth endpoints |
| Strict role separation | ✅ | Sprint 15 — gv@ chỉ ORGANIZER+JUDGE, admin riêng scope |
| Tests | ⏳ | Empty `tests/` folder — defer post-graduation |

---

## Endpoint coverage (16 router)

### Auth (7) — `/api/auth/*`
- `POST /login` · `POST /logout` · `GET /me` · `POST /refresh`
- `POST /register` (self-signup SV) · `POST /forgot-password` · `POST /reset-password`
- `POST /otp/request` · `POST /otp/verify` (passwordless OTP)

### Me (5) — `/api/me/*`
- `PATCH /me` · `POST /me/change-password` · `DELETE /me`
- `GET /me/notifications` · `PATCH /me/notifications/{id}/read` · `POST /me/notifications/mark-all-read`
- `GET /me/results` · `GET /me/entries` · `GET /me/judge-assignments`

### Contests (16+) — `/api/contests/*`
- `GET /` (list with q + status filter) · `GET /{slug}` (detail by slug)
- `POST /` (create) · `PATCH /{id}` · `DELETE /{id}` (GV-02)
- `POST /{id}/submit-for-approval` (BCN_QD1)
- `GET /{id}/rounds` · `POST /{id}/rounds` (manage rounds)
- `GET /{id}/sessions` · `POST /{id}/sessions` (manage sessions)
- `GET /{id}/stats` (real-time aggregation — Sprint 12)
- `GET /{id}/results` (public published)
- `POST /{id}/results/compute` · `POST /{id}/results/submit-for-approval` · `POST /{id}/results/publish`
- **`GET /{id}/leaderboard`** (Sprint 16 — enriched với display_name từ Student/Team)

### Rounds (Sprint 16 mới)
- **`GET /api/rounds/{id}`** — round detail với `submission_close_at` + `end_at` cho FE countdown timer

### Entries (8)
- `POST /contests/{id}/register` · `DELETE /contests/{id}/registration`
- `GET /contests/{id}/entries` · `PATCH /contests/{id}/entries/{eid}/approve`
- `POST /contests/{id}/entries/bulk-approve`
- `GET /contests/{id}/entries/export.xlsx` (Excel export)

### Judging (8) — `/api/rounds/{id}/*` + `/api/assignments/{id}/*`
- `GET /rounds/{id}/criteria` · `POST /rounds/{id}/criteria` · `DELETE /rounds/{id}/criteria/{cid}`
- `POST /rounds/{id}/judge-assignments` · `GET /me/judge-assignments` (enriched is_scored + scored_count + total_criteria)
- `POST /assignments/{id}/scores` · `POST /rounds/{id}/compute-results`

### Submissions (5) — `/api/rounds/{id}/submissions/*` + `/api/submissions/*`
- `POST /rounds/{id}/submissions/me/versions` (SV submit version mới)
- `GET /rounds/{id}/submissions/me` (SV xem submission của mình)
- `POST /submissions/versions/{vid}/files` (R2 upload multipart)
- `GET /submissions/files/{fid}/download` (BYTEA stream cũ)
- `POST /submissions/{id}/lock` (GV anti-tamper)
- `GET /rounds/{id}/submissions` (GV list)

### Teams (4)
- `POST /contests/{id}/teams` · `POST /teams/{id}/members` · `DELETE /teams/{id}/members/{sid}` · `DELETE /teams/{id}`

### Reviews (4)
- `POST /contests/{id}/reviews` · `GET /contests/{id}/reviews` · `GET /contests/{id}/reviews/summary` · `DELETE /reviews/{id}`

### Notifications (3)
- `GET /me/notifications` · `PATCH /me/notifications/{id}/read` · `POST /me/notifications/mark-all-read`

### Certificates (7)
- `POST /contests/{id}/certificate-templates` · `GET /contests/{id}/certificate-templates`
- `PATCH /certificate-templates/{id}/submit-for-approval` · **`PATCH /certificate-templates/{id}/approve`** (Sprint 11 BCN_QD3)
- `PATCH /certificate-templates/{id}/activate` · `POST /contests/{id}/certificates/issue`
- `GET /certificates/{qr}` · `GET /certificates/{qr}/render` (HTML render)

### Approvals (3) — `/api/approvals/*` + `/api/me/pending-approvals`
- `GET /me/pending-approvals` (BCN inbox)
- `PATCH /approvals/{id}/decide` (approve/reject với note)

### Reports (4) — Admin only
- `GET /admin/reports/system-summary` (JSON)
- `GET /admin/reports/system-summary.xlsx` (Excel 3 sheets)
- `GET /admin/audit-logs` (filter user/action/contest/time)
- `GET /admin/anomaly-reports`

### Admin (26) — `/api/admin/*`
- Users CRUD + role assignment + lock/unlock
- Master data: faculties / majors / classes / student_directory
- System configs · Backup & Restore · Audit log · Anomaly detection · Comments moderation

---

## Setup local dev

### Yêu cầu
- Python 3.11 trở lên
- PostgreSQL 14+ đang chạy local (port 5432)

### Cài đặt

```bash
cd 09-implementation/backend

# Tạo venv
python -m venv .venv
source .venv/bin/activate    # Windows: .venv\Scripts\activate

# Cài dependencies
pip install -e ".[dev]"

# Cấu hình env
cp .env.example .env
# Sửa DATABASE_URL, JWT_SECRET_KEY (>= 32 ký tự random):
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Tạo DB + apply schema từ SQL v04
psql -U postgres -c "CREATE DATABASE ptit_contest_db;"
psql -U postgres -d ptit_contest_db -f ../../08-database/2026-05-06_sqlapp_v04.sql

# Stamp Alembic baseline (đánh dấu DB đã ở version baseline)
alembic stamp head

# Seed test users (GV + BCN + Admin)
# Password mặc định lấy từ env DEMO_PASSWORD (xem seed-test-users.py).
DEMO_PASSWORD=<your-demo-password> python scripts/seed-test-users.py

# Chạy server
uvicorn app.main:app --reload --port 8000
```

→ http://localhost:8000/api/docs (Swagger UI)

---

## Cấu trúc thư mục

```
backend/
├── pyproject.toml              # Dependencies + ruff + pytest config
├── Dockerfile                  # Cache-friendly build cho Railway
├── .env.example                # Template biến env
├── alembic.ini                 # Alembic config
├── alembic/
│   ├── env.py                  # Async migration runner
│   ├── script.py.mako          # Template migration mới
│   └── versions/
│       └── 0001_baseline_v04.py
├── scripts/
│   └── seed-test-users.py      # Tạo GV/BCN/Admin test
├── app/
│   ├── main.py                 # FastAPI app entry + Sentry init + middleware
│   ├── config.py               # Settings (pydantic-settings)
│   ├── database.py             # Async engine + get_db dependency
│   ├── security.py             # bcrypt + JWT HS256 + refresh
│   ├── deps.py                 # CurrentUser, require_roles, Pagination
│   ├── core/
│   │   └── r2_client.py        # Cloudflare R2 S3-compat client
│   ├── middleware/
│   │   ├── audit.py            # Audit log mọi mutation request
│   │   └── rate_limit.py       # slowapi 10/min auth
│   ├── models/                 # 43 SQLAlchemy 2.0 models
│   │   ├── enums.py            # 17 Python Enum map Postgres ENUM
│   │   ├── identity.py         # roles, app_users, user_roles
│   │   ├── master_data.py      # faculties, majors, classes, students
│   │   ├── contest.py          # contests, rounds, sessions
│   │   ├── entry.py            # teams, members, contest_entries
│   │   ├── submission.py       # submissions, versions, files
│   │   ├── judging.py          # criteria, assignments, scores, results
│   │   ├── certificate.py      # templates, issued_certificates
│   │   ├── checkin.py          # qr_tokens, checkins
│   │   ├── notification.py     # notifications, articles, questions
│   │   ├── review.py           # contest_reviews
│   │   ├── workflow.py         # workflow_approvals (QĐ1/QĐ2/QĐ3)
│   │   └── system.py           # system_configs, audit_logs
│   ├── schemas/                # Pydantic v2 input/output models
│   ├── services/               # Business logic layer
│   └── routers/                # API endpoints (16 router)
└── tests/                      # ⏳ Empty
```

---

## RBAC pattern

Dùng dependency `require_roles` trong `app/deps.py`:

```python
from app.deps import CurrentUser, require_roles

# Endpoint cần ORGANIZER hoặc ADMIN:
@router.post("/contests")
async def create_contest(
    data: ContestCreateIn,
    db: AsyncSession = Depends(get_db),
    user: AppUser = Depends(require_roles("ORGANIZER", "ADMIN")),
):
    ...
```

Sprint 15 strict role separation — gv@ test user chỉ có `ORGANIZER + JUDGE` (không có ADMIN cũ).

---

## Test với curl

```bash
# Health check
curl http://localhost:8000/health

# List contests (public, no token)
curl "http://localhost:8000/api/contests?size=5"

# Login GV (thay <demo-password> bằng password đã set khi seed)
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"gv@ptit.edu.vn","password":"<demo-password>"}' | jq -r .access_token)

# Get me
curl http://localhost:8000/api/auth/me -H "Authorization: Bearer $TOKEN"

# Get leaderboard (Sprint 16)
curl http://localhost:8000/api/contests/1/leaderboard

# Get round detail (Sprint 16 — countdown timer)
curl http://localhost:8000/api/rounds/1
```

---

## Deployment

Railway auto-deploy via git push:

```bash
git add app/
git commit -m "feat: ..."
git push   # Railway tự build từ Dockerfile + deploy
```

Dockerfile pattern cache-friendly:
1. COPY `pyproject.toml` + stub `app/__init__.py` → `pip install` (cached khi không thay đổi deps)
2. COPY `. .` full source

Lần build sau ~30s thay vì 5 phút.

---

## Reference

- **Frontend**: `../frontend/README.md`
- **Báo cáo CNPM v02**: `../../11-docs/deliverables/2026-05-07_bao-cao-cnpm_v02.md`
- **Schema SQL**: `../../08-database/2026-05-06_sqlapp_v04.sql`
- **ER diagram**: `../../08-database/2026-05-04_er-diagram_v02.mermaid`
- **Traceability matrix**: `../../02-requirements/2026-05-07_traceability-matrix_v03.md`
- **Workflow approval**: `../../03-information-architecture/2026-05-04_workflow-approval-overview_v01.md`
