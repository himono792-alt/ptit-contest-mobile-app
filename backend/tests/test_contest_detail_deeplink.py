"""Test fix deep-link notification 404 (2026-06-16).

Notification cũ build target_route = /contests/{contest_id} (số). Route FE là
/contests/:slug → gọi GET /api/contests/{slug}. Khi slug là số → trước đây 404.
Fix: endpoint detail fallback tra theo contest_id nếu slug toàn chữ số.
"""
import pytest

pytestmark = pytest.mark.asyncio
SLUG_A = "lap-trinh-thuat-toan-2026"


async def test_detail_by_slug_works(client):
    r = await client.get(f"/api/contests/{SLUG_A}")
    assert r.status_code == 200
    assert r.json()["slug"] == SLUG_A


async def test_detail_by_numeric_id_fallback(client):
    """Deep-link cũ /contests/{id} (số) phải resolve được qua fallback."""
    # Lấy contest_id thật của contest A
    detail = await client.get(f"/api/contests/{SLUG_A}")
    contest_id = detail.json()["contest_id"]

    r = await client.get(f"/api/contests/{contest_id}")
    assert r.status_code == 200, r.text
    assert r.json()["contest_id"] == contest_id
    assert r.json()["slug"] == SLUG_A


async def test_detail_unknown_numeric_404(client):
    r = await client.get("/api/contests/99999999")
    assert r.status_code == 404
