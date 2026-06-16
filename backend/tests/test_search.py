"""Test full-text search cuộc thi (2026-06-16).

Trước: /contests?q= chỉ match `title` qua ILIKE.
Sau: full-text search trên title + description + rules_text + award_text + ranking.

Dữ liệu seed — Contest A "lap-trinh-thuat-toan-2026":
  title       = "Cuộc thi Lập trình thuật toán 2026"
  description = "Sân chơi học thuật cho sinh viên đam mê thuật toán và lập trình thi đấu."
  award_text  = "Giải Nhất 5.000.000đ, Nhì 3.000.000đ, Ba 2.000.000đ."
"""
import pytest

pytestmark = pytest.mark.asyncio

SLUG_A = "lap-trinh-thuat-toan-2026"


async def _search_slugs(client, q):
    r = await client.get("/api/contests", params={"q": q})
    assert r.status_code == 200, r.text
    body = r.json()
    items = body["items"] if isinstance(body, dict) else body
    return [c["slug"] for c in items]


async def test_search_by_title_term(client):
    assert SLUG_A in await _search_slugs(client, "thuật toán")


async def test_search_by_description_only_term(client):
    """'học thuật' chỉ có trong DESCRIPTION, không có trong title.

    Search cũ (ILIKE title-only) sẽ TRƯỢT — chứng minh giờ đã phủ description.
    """
    assert SLUG_A in await _search_slugs(client, "học thuật")


async def test_search_by_award_term(client):
    """'5.000.000' chỉ có trong award_text → chứng minh phủ award_text."""
    assert SLUG_A in await _search_slugs(client, "5.000.000")


async def test_search_gibberish_returns_empty(client):
    assert await _search_slugs(client, "zzxxqqkhongtontai123") == []


async def test_empty_query_lists_all(client):
    """Không truyền q → vẫn list bình thường (không lọc)."""
    r = await client.get("/api/contests")
    assert r.status_code == 200
    body = r.json()
    items = body["items"] if isinstance(body, dict) else body
    assert len(items) >= 1
