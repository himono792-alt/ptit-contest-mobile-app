"""Test contest read + workflow phê duyệt 2 cấp (A — 2026-06-16).

Dữ liệu seed (scripts/seed-demo.py):
  - Contest A "lap-trinh-thuat-toan-2026" (INDIVIDUAL, ONGOING, public).
  - Contest B (TEAM, PROPOSED) + 1 đề nghị QĐ1 PENDING cho BCN khoa CNTT.
"""
import pytest

from tests.conftest import auth_header, login_token

pytestmark = pytest.mark.asyncio

SLUG_A = "lap-trinh-thuat-toan-2026"
BCN = "bcn@ptit.edu.vn"
SV = "b22dccn001@ptit.edu.vn"


async def test_list_contests_public(client):
    r = await client.get("/api/contests")
    assert r.status_code == 200
    body = r.json()
    items = body["items"] if isinstance(body, dict) else body
    slugs = [c["slug"] for c in items]
    assert SLUG_A in slugs  # Contest A ONGOING là public


async def test_get_contest_detail_by_slug(client):
    r = await client.get(f"/api/contests/{SLUG_A}")
    assert r.status_code == 200
    assert r.json()["slug"] == SLUG_A


async def test_get_contest_unknown_slug_404(client):
    r = await client.get("/api/contests/khong-co-cuoc-thi-nay")
    assert r.status_code == 404


async def test_filter_contests_by_status(client):
    r = await client.get("/api/contests", params={"status": "ONGOING"})
    assert r.status_code == 200
    body = r.json()
    items = body["items"] if isinstance(body, dict) else body
    assert all(c["status"] == "ONGOING" for c in items)


async def test_bcn_sees_pending_approval_queue(client):
    """BCN khoa CNTT thấy đề nghị QĐ1 PENDING (workflow 2 cấp BTC↔BCN)."""
    token = await login_token(client, BCN)
    r = await client.get("/api/me/pending-approvals", headers=auth_header(token))
    assert r.status_code == 200
    queue = r.json()
    assert len(queue) >= 1
    assert any(item["status"] == "PENDING" for item in queue)


async def test_student_cannot_see_approval_queue(client):
    """SV không có quyền BCN → không xem được queue duyệt."""
    token = await login_token(client, SV)
    r = await client.get("/api/me/pending-approvals", headers=auth_header(token))
    assert r.status_code == 403
