"""Test AD-02 bulk user status — khóa/mở/xóa hàng loạt (2026-06-16)."""
import pytest
from sqlalchemy import select

from app.models.enums import UserStatus
from app.models.identity import AppUser
from tests.conftest import auth_header, login_token

pytestmark = pytest.mark.asyncio
ADMIN = "admin@ptit.edu.vn"


async def _throwaway_users(db, prefix, n=2):
    """Tạo user dùng-1-lần (KHÔNG dùng seed account để khỏi ảnh hưởng test khác)."""
    ids = []
    for i in range(n):
        u = AppUser(email=f"{prefix}{i}@throwaway.test", password_hash="x", full_name=f"TW {prefix}{i}")
        db.add(u)
        await db.flush()
        ids.append(u.user_id)
    await db.commit()
    return ids


async def test_bulk_lock_users(client, db):
    ids = await _throwaway_users(db, "lock")
    fake = 888888
    token = await login_token(client, ADMIN)
    r = await client.post(
        "/api/admin/users/bulk-status",
        headers=auth_header(token),
        json={"user_ids": ids + [fake], "action": "LOCK"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["affected_count"] == 2
    assert fake in body["skipped"]
    for uid in ids:
        u = await db.get(AppUser, uid)
        await db.refresh(u)
        assert u.status == UserStatus.LOCKED


async def test_bulk_delete_skips_self(client, db):
    """Admin không tự xóa mình — id của chính admin nằm trong skipped."""
    token = await login_token(client, ADMIN)
    me = await client.get("/api/auth/me", headers=auth_header(token))
    admin_id = me.json()["user_id"]
    ids = await _throwaway_users(db, "del")

    r = await client.post(
        "/api/admin/users/bulk-status",
        headers=auth_header(token),
        json={"user_ids": ids + [admin_id], "action": "DELETE"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["affected_count"] == 2
    assert admin_id in body["skipped"]
    admin_user = await db.get(AppUser, admin_id)
    await db.refresh(admin_user)
    assert admin_user.status == UserStatus.ACTIVE  # vẫn còn nguyên


async def test_bulk_status_requires_admin(client, db):
    ids = await _throwaway_users(db, "perm")
    token = await login_token(client, "b22dccn001@ptit.edu.vn")
    r = await client.post(
        "/api/admin/users/bulk-status",
        headers=auth_header(token),
        json={"user_ids": ids, "action": "LOCK"},
    )
    assert r.status_code == 403
