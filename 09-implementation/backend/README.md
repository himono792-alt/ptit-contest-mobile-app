# PTIT Contest — Backend (FastAPI)

Backend API cho hệ thống quản lý cuộc thi sinh viên PTIT.

**Stack:** Python 3.11+ · FastAPI · SQLAlchemy 2.0 (async) · asyncpg · PostgreSQL · Alembic · Pydantic v2 · JWT (python-jose).

---

## 1. Trạng thái scaffold (v0.1.0)

| Thành phần | Trạng thái | Ghi chú |
|---|---|---|
| Project structure | ✅ | `app/` chia theo layer: models, schemas, services, routers, deps |
| Config + DB engine | ✅ | `app/config.py` (pydantic-settings), `app/database.py` (async) |
| Security | ✅ | `app/security.py` (bcrypt + JWT HS256) |
| **43 SQLAlchemy models** | ✅ | `app/models/` chia 12 file domain |
| **Auth endpoints** | ✅ | register / login / logout / me — JWT bearer |
| **Endpoint mẫu** | ✅ | `GET /api/contests` + `GET /api/contests/{slug}` |
| Alembic | ✅ | env.py async, baseline pattern (xem `alembic/README.md`) |
| Other 28 endpoints | ⏳ | Stub trong `app/main.py`, team copy template từ `routers/contests.py` |
| Tests | ⏳ | Empty `tests/` folder, team add pytest cases |

**Coverage hiện tại:** 4/30 chức năng (SV-01a, SV-01b, SV-01c, SV-04, SV-05). Còn 26 endpoint cho team implement theo traceability matrix v02.

---

## 2. Setup từ đầu

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
# Mở .env và sửa DATABASE_URL, JWT_SECRET_KEY (tối thiểu 32 ký tự random)
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Tạo DB + apply schema từ SQL v03
psql -U postgres -c "CREATE DATABASE ptit_contest_db;"
psql -U postgres -d ptit_contest_db -f ../../08-database/2026-05-04_sqlapp_v03.sql

# Stamp Alembic baseline
alembic stamp head

# Chạy server
uvicorn app.main:app --reload --port 8000
```

Mở http://localhost:8000/api/docs để xem Swagger UI.

---

## 3. Cấu trúc thư mục

```
backend/
├── pyproject.toml          # Dependencies + ruff + pytest config
├── .env.example            # Template biến env
├── alembic.ini             # Alembic config
├── alembic/
│   ├── env.py              # Async migration runner
│   ├── script.py.mako      # Template cho migration mới
│   ├── versions/           # Migration files (autogenerate)
│   └── README.md           # Hướng dẫn migration
├── app/
│   ├── main.py             # FastAPI app entry
│   ├── config.py           # Settings (pydantic-settings)
│   ├── database.py         # Async engine + get_db dependency
│   ├── security.py         # Password hash + JWT
│   ├── deps.py             # CurrentUser, require_roles, Pagination
│   ├── models/             # 43 SQLAlchemy 2.0 models
│   │   ├── base.py
│   │   ├── enums.py        # 17 Python Enum map với Postgres ENUM
│   │   ├── identity.py     # roles, app_users, user_roles
│   │   ├── master_data.py  # faculties, majors, classes, directory + 4 profiles
│   │   ├── contest.py      # contests, organizers, rounds, sessions, judges
│   │   ├── entry.py        # teams, members, contest_entries, logs, session_entries
│   │   ├── submission.py   # submissions, versions, files
│   │   ├── judging.py      # criteria, assignments, scores, results, appeals
│   │   ├── certificate.py  # templates, issued_certificates
│   │   ├── checkin.py      # qr_tokens, checkins
│   │   ├── notification.py # notifications, recipients, articles, questions, answers
│   │   ├── review.py       # contest_reviews
│   │   ├── workflow.py     # workflow_approvals
│   │   └── system.py       # system_configs, audit_logs
│   ├── schemas/            # Pydantic v2 input/output
│   │   ├── auth.py         # ✅ done
│   │   └── contest.py      # ✅ done (template)
│   ├── services/           # Business logic
│   │   └── auth_service.py # ✅ done
│   └── routers/            # API endpoints
│       ├── auth.py         # ✅ done
│       └── contests.py     # ✅ done (template)
└── tests/                  # ⏳ team add
```

---

## 4. RBAC pattern

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

Hoặc check trong code:
```python
if "HOD" not in user.role_codes:
    raise HTTPException(403, "Only BCN can do this")
```

---

## 5. Roadmap implement 26 endpoint còn lại

Theo thứ tự priority (xem `02-requirements/2026-05-04_traceability-matrix_v02.md`):

**Phase 1 — Auth + Profile (ưu tiên cao):**
- [ ] `routers/users.py` — SV-02 (PATCH /me, password, forgot-password), SV-03 (DELETE /me)

**Phase 2 — Contest lifecycle:**
- [ ] `routers/contests.py` (mở rộng) — GV-02 (POST/PATCH/DELETE, /rounds, /sessions, /submit-for-approval)
- [ ] `routers/entries.py` — SV-06 (POST register), GV-03 (GET/PATCH approve), SV-10 (DELETE register)
- [ ] `routers/teams.py` — SV-06 (POST teams, /members)

**Phase 3 — Submission + Judging:**
- [ ] `routers/submissions.py` — SV-08 (POST versions, files), GV-04 (lock)
- [ ] `routers/judging.py` — GV-05 (assignments, scores, compute-results)
- [ ] `routers/results.py` — GV-06 (compute, submit-for-approval, publish)

**Phase 4 — Approval workflow:**
- [ ] `routers/approvals.py` — BCN-02 + BCN-04 (pending-approvals, decide)
- [ ] `services/approval_service.py` — submit_for_approval, decide (xem code snippet trong `03-information-architecture/2026-05-04_workflow-approval-overview_v01.md`)

**Phase 5 — Reviews + Certificates + Notifications:**
- [ ] `routers/reviews.py` — SV-11
- [ ] `routers/certificates.py` — BCN-06 (templates, issue, verify) + SV-09 (download)
- [ ] `routers/notifications.py` — SV-07

**Phase 6 — Admin:**
- [ ] `routers/admin/users.py` — AD-02
- [ ] `routers/admin/master.py` — AD-03 (faculties/majors/classes)
- [ ] `routers/admin/configs.py` — AD-04 (system_configs)
- [ ] `routers/admin/audit.py` — AD-06

**Phase 7 — Reports + Stats:**
- [ ] `routers/reports.py` — GV-07, BCN-05, AD-05

---

## 6. Test với curl (sau khi setup xong)

```bash
# Health check
curl http://localhost:8000/health

# List contests (public, không cần token)
curl "http://localhost:8000/api/contests?size=5"

# Register sinh viên (cần seed student_directory trước trong DB)
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"student_code":"B22DCCN001","email":"b22dccn001@ptit.edu.vn","full_name":"Nguyễn Văn A","password":"secret123"}'

# Login
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"b22dccn001@ptit.edu.vn","password":"secret123"}' | jq -r .access_token)

# Get me
curl http://localhost:8000/api/auth/me -H "Authorization: Bearer $TOKEN"
```

---

## 7. Reference

- Schema SQL: `08-database/2026-05-04_sqlapp_v03.sql`
- ER diagram: `08-database/2026-05-04_er-diagram_v02.mermaid`
- Traceability matrix: `02-requirements/2026-05-04_traceability-matrix_v02.md` (mỗi dòng = 1 endpoint cần làm)
- Workflow approval: `03-information-architecture/2026-05-04_workflow-approval-overview_v01.md`
- UI mockup: `05-mockups/` (4 file HTML cho 4 actor)
