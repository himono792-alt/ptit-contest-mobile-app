# Contributing — PTIT Contest Backend

Cảm ơn bạn quan tâm đóng góp cho project! Đây là hướng dẫn để contributor mới onboard nhanh.

---

## Quick start

```bash
# 1. Fork repo + clone về máy
git clone https://github.com/YOUR_USERNAME/ptit-contest-mobile-app.git
cd ptit-contest-mobile-app

# 2. Setup environment
python -m venv .venv
source .venv/bin/activate    # Windows: .venv\Scripts\activate
pip install -e ".[dev]"

# 3. Cấu hình env
cp .env.example .env
# Sửa DATABASE_URL + JWT_SECRET_KEY (>= 32 ký tự random)

# 4. Tạo DB + apply schema
psql -U postgres -c "CREATE DATABASE ptit_contest_db;"
psql -U postgres -d ptit_contest_db -f ../../08-database/2026-05-04_sqlapp_v03.sql
alembic stamp head
python scripts/seed-test-users.py

# 5. Run dev
uvicorn app.main:app --reload --port 8000
```

→ http://localhost:8000/api/docs

---

## Workflow

1. **Tạo issue** mô tả bug/feature trước khi code (xem `.github/ISSUE_TEMPLATE/`).
2. **Branch naming**: `feature/<short-desc>` · `fix/<short-desc>` · `docs/<short-desc>`
3. **Code change** — tuân thủ rules dưới.
4. **Local test** — chạy `uvicorn app.main:app --reload` + smoke test endpoint qua Swagger UI.
5. **Commit message** theo Conventional Commits (xem dưới).
6. **Pull request** — mô tả rõ "Why" + "What changed" + screenshot/video nếu UI-affecting.

---

## Commit convention (Conventional Commits)

```
<type>(<scope>): <subject>

<body — tuỳ chọn>

<footer — vd "BREAKING CHANGE:" hoặc "Closes #123">
```

**Types:**
- `feat` — Tính năng mới (vd endpoint mới)
- `fix` — Bug fix
- `refactor` — Refactor không thay đổi behavior
- `perf` — Tối ưu performance
- `docs` — Chỉ docs (README/CHANGELOG/comment)
- `test` — Chỉ test
- `chore` — Dependency bump / build config / infra

**Scopes** (optional):
- `auth` · `contests` · `judging` · `admin` · `migrations` · `r2` · `email` · ...

**Examples:**
```
feat(contests): add GET /api/contests/{id}/leaderboard with enriched display_name
fix(submissions): handle NULL submission_close_at trong round detail
refactor(judging): extract bulk count criteria/scores logic
docs(readme): update Sprint 16 endpoints
chore(deps): bump fastapi 0.115 → 0.118
```

---

## Code style

- **Python 3.11+** với type hints.
- **Async** mọi DB operation (SQLAlchemy 2.0 async, asyncpg).
- **Pydantic v2** schemas — `model_config = ConfigDict(from_attributes=True)` cho ORM model.
- **Ruff** linter — chạy trước commit:
  ```bash
  ruff check app/
  ruff format app/
  ```
- **Naming**: snake_case file/function, PascalCase class, UPPER_CASE constant.
- **Docstring** chỉ cho complex business logic; endpoint dùng FastAPI auto-doc qua summary parameter.

---

## Patterns project

### RBAC
```python
from app.deps import CurrentUser, require_roles

@router.post("/contests")
async def create_contest(
    user: AppUser = Depends(require_roles("ORGANIZER", "ADMIN")),
    ...
):
    ...
```

### DB query
```python
from sqlalchemy import select
from app.database import get_db

stmt = select(Contest).where(Contest.contest_id == contest_id)
result = (await db.execute(stmt)).scalar_one_or_none()
```

### Response model với enrichment
Khi cần join data, prefer `list[dict]` thay model — flexibility cao hơn cho FE consumer (xem `result_service.list_leaderboard` Sprint 16):
```python
async def list_leaderboard(db, contest_id) -> list[dict]:
    rows = await db.execute(...)
    student_names = ...  # bulk lookup
    return [{"rank_no": r.rank, "display_name": ..., ...} for r in rows]
```

---

## Testing

⚠️ Test suite hiện tại empty (defer post-graduation). Smoke test bằng Swagger UI hoặc curl.

```bash
# Test login + endpoint
TOKEN=$(curl -s -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"gv@ptit.edu.vn","password":"abc123"}' | jq -r .access_token)

curl http://localhost:8000/api/contests \
  -H "Authorization: Bearer $TOKEN"
```

---

## Deployment

Railway auto-deploy via git push:

```bash
git add app/
git commit -m "feat(contests): ..."
git push origin main
```

Railway tự build từ Dockerfile + restart container. Logs: https://railway.app/

---

## Reference

- README: `README.md`
- CHANGELOG: `CHANGELOG.md`
- Báo cáo CNPM: `../../11-docs/2026-05-07_bao-cao-cnpm_v02.md`
