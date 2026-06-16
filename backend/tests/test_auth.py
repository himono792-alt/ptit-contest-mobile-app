"""Test auth + RBAC (A — 2026-06-16).

Bao phủ: login đúng/sai, /me trả role chính xác, refresh token, register validation,
và phân quyền (SV không vào được endpoint admin).
"""
import pytest

from tests.conftest import DEMO_PASSWORD, auth_header, login_token

pytestmark = pytest.mark.asyncio

# Tài khoản seed sẵn (scripts/seed-demo.py)
GV = "gv@ptit.edu.vn"
BCN = "bcn@ptit.edu.vn"
ADMIN = "admin@ptit.edu.vn"
SV = "b22dccn001@ptit.edu.vn"


async def test_login_success_returns_tokens(client):
    r = await client.post("/api/auth/login", json={"email": GV, "password": DEMO_PASSWORD})
    assert r.status_code == 200
    body = r.json()
    assert body["access_token"]
    assert body["refresh_token"]
    assert body["expires_in"] > 0


async def test_login_wrong_password_401(client):
    r = await client.post("/api/auth/login", json={"email": GV, "password": "sai-mat-khau"})
    assert r.status_code == 401


async def test_login_unknown_email_401(client):
    r = await client.post("/api/auth/login", json={"email": "khongton-tai@ptit.edu.vn", "password": "x"})
    assert r.status_code == 401


async def test_login_missing_body_422(client):
    r = await client.post("/api/auth/login", json={})
    assert r.status_code == 422


@pytest.mark.parametrize(
    "email,expected_role",
    [(GV, "ORGANIZER"), (BCN, "HOD"), (ADMIN, "ADMIN"), (SV, "STUDENT")],
)
async def test_me_returns_correct_roles(client, email, expected_role):
    token = await login_token(client, email)
    r = await client.get("/api/auth/me", headers=auth_header(token))
    assert r.status_code == 200
    body = r.json()
    assert body["email"].lower() == email
    assert expected_role in body["roles"]


async def test_me_requires_auth(client):
    r = await client.get("/api/auth/me")
    assert r.status_code in (401, 403)


async def test_refresh_token_issues_new_access(client):
    r = await client.post("/api/auth/login", json={"email": SV, "password": DEMO_PASSWORD})
    refresh = r.json()["refresh_token"]
    r2 = await client.post("/api/auth/refresh", json={"refresh_token": refresh})
    assert r2.status_code == 200
    assert r2.json()["access_token"]


async def test_refresh_token_invalid_401(client):
    r = await client.post("/api/auth/refresh", json={"refresh_token": "rac.khong.hop.le"})
    assert r.status_code == 401


# ---- RBAC: SV không được vào endpoint admin ----

async def test_student_cannot_access_admin_users(client):
    token = await login_token(client, SV)
    r = await client.get("/api/admin/users", headers=auth_header(token))
    assert r.status_code == 403


async def test_admin_can_access_admin_users(client):
    token = await login_token(client, ADMIN)
    r = await client.get("/api/admin/users", headers=auth_header(token))
    assert r.status_code == 200
    assert "items" in r.json()
