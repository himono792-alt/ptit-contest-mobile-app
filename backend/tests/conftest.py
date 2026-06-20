"""Pytest fixtures cho backend test suite (A — 2026-06-16).

Môi trường test ĐỘC LẬP, không cần DB production / Docker / root:
  1. Bật 1 PostgreSQL nhúng (pgserver) chạy user-space.
  2. Tạo DB `ptit_test`, nạp `init-schema.sql` (schema thật v04: 43 bảng + enum).
     citext extension không có trong bản nhúng → shim DOMAIN text (đủ cho test).
  3. Set DATABASE_URL + thay engine bằng NullPool TRƯỚC khi import app
     (NullPool: mỗi connection mở/đóng tươi → tránh asyncpg "event loop is closed"
      khi pytest dùng loop khác nhau giữa các test).
  4. Seed dữ liệu demo (scripts/seed-demo.py) 1 lần lúc import.

Chạy:  cd backend && pytest -v
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pgserver
import pytest

BACKEND_DIR = Path(__file__).resolve().parent.parent
PGDATA = os.environ.get("PYTEST_PGDATA", "/tmp/ptit_pgtest")
DEMO_PASSWORD = "abc123"

# ---------------------------------------------------------------------------
# 1) Embedded Postgres + nạp schema
# ---------------------------------------------------------------------------
_server = pgserver.get_server(PGDATA)
_server.psql("DROP DATABASE IF EXISTS ptit_test;")
_server.psql("CREATE DATABASE ptit_test;")

_schema_sql = (BACKEND_DIR / "init-schema.sql").read_text(encoding="utf-8")
_schema_sql = _schema_sql.replace(
    "CREATE EXTENSION IF NOT EXISTS citext;",
    "CREATE DOMAIN public.citext AS text;  -- test shim (no contrib citext)",
)
_psql_bin = Path(pgserver.__file__).parent / "pginstall" / "bin" / "psql"
with tempfile.NamedTemporaryFile("w", suffix=".sql", delete=False, encoding="utf-8") as _tf:
    _tf.write(_schema_sql)
    _schema_path = _tf.name
_res = subprocess.run(
    [str(_psql_bin), f"host={PGDATA} dbname=ptit_test user=postgres",
     "-v", "ON_ERROR_STOP=1", "-f", _schema_path],
    capture_output=True, text=True,
)
if _res.returncode != 0:
    raise RuntimeError(f"Nạp init-schema.sql thất bại:\n{_res.stderr[-1500:]}")

# ---------------------------------------------------------------------------
# 2) Env cho app (set TRƯỚC khi import app.config/app.database)
# ---------------------------------------------------------------------------
os.environ["DATABASE_URL"] = f"postgresql+asyncpg://postgres@/ptit_test?host={PGDATA}"
os.environ["JWT_SECRET_KEY"] = "test_secret_key_pytest_only_0123456789"
os.environ["DEMO_PASSWORD"] = DEMO_PASSWORD
os.environ["APP_ENV"] = "development"
os.environ["MAIL_TRANSPORT"] = "console"
os.environ["RATE_LIMIT_ENABLED"] = "false"

# ---------------------------------------------------------------------------
# 3) Thay engine của app bằng NullPool (tránh chia sẻ connection giữa loop)
# ---------------------------------------------------------------------------
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine  # noqa: E402
from sqlalchemy.pool import NullPool  # noqa: E402

import app.database as _appdb  # noqa: E402

_test_engine = create_async_engine(
    os.environ["DATABASE_URL"],
    poolclass=NullPool,
    connect_args={"server_settings": {"search_path": "ptit_contest,public"}},
)
_appdb.engine = _test_engine
_appdb.AsyncSessionLocal = async_sessionmaker(
    bind=_test_engine, expire_on_commit=False, autoflush=False,
)

# ---------------------------------------------------------------------------
# 4) Seed demo data 1 lần (dùng engine NullPool đã patch ở trên)
# ---------------------------------------------------------------------------
subprocess.run(
    [sys.executable, str(BACKEND_DIR / "scripts" / "seed-demo.py")], check=True
)


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------
@pytest.fixture
async def client():
    """httpx AsyncClient gắn thẳng vào ASGI app (không cần network)."""
    from httpx import ASGITransport, AsyncClient

    from app.main import app
    from app.rate_limit import limiter

    limiter.enabled = False  # tắt rate limit để login nhiều lần không bị 429
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as c:
        yield c


@pytest.fixture
async def db():
    """AsyncSession trỏ DB test — dùng cho test ở tầng service."""
    async with _appdb.AsyncSessionLocal() as session:
        yield session


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
async def login_token(client, email: str, password: str = DEMO_PASSWORD) -> str:
    r = await client.post("/api/auth/login", json={"email": email, "password": password})
    assert r.status_code == 200, f"login {email} failed: {r.status_code} {r.text}"
    return r.json()["access_token"]


def auth_header(token: str) -> dict:
    return {"Authorization": f"Bearer {token}"}
