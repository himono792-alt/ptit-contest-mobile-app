"""Test AD-06: bulk review moderation + audit log filter (2026-06-16).

- bulk_moderate_reviews: ẩn/hiện HÀNG LOẠT review 1 lần (chống spam ồ ạt).
- audit log filter: lọc theo action_type/time (đã có sẵn — test khoá hành vi).
"""
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select

from app.models.contest import Contest
from app.models.enums import ContestStatus, DeliveryMode, EntryType
from app.models.identity import AppUser
from app.models.master_data import Student
from app.models.review import ContestReview
from app.models.system import AuditLog
from tests.conftest import auth_header, login_token

pytestmark = pytest.mark.asyncio
NOW = datetime.now(timezone.utc)
ADMIN = "admin@ptit.edu.vn"


async def _student_id(db, email):
    user = (await db.execute(select(AppUser).where(AppUser.email == email))).scalar_one()
    return (await db.execute(select(Student).where(Student.user_id == user.user_id))).scalar_one().student_id


async def _make_reviews(db, slug):
    contest = Contest(
        slug=slug,
        title="Contest cho review bulk",
        delivery_mode=DeliveryMode.ONLINE,
        participation_mode=EntryType.INDIVIDUAL,
        start_at=NOW - timedelta(days=10),
        end_at=NOW - timedelta(days=1),
        status=ContestStatus.FINISHED,
        created_by=1,
    )
    db.add(contest)
    await db.flush()
    ids = []
    for email in ("b22dccn001@ptit.edu.vn", "b22dccn002@ptit.edu.vn", "b22dccn003@ptit.edu.vn"):
        sid = await _student_id(db, email)
        rv = ContestReview(contest_id=contest.contest_id, student_id=sid, rating=5,
                           comment_text="spam spam", is_visible=True)
        db.add(rv)
        await db.flush()
        ids.append(rv.review_id)
    await db.commit()
    return ids


async def test_bulk_moderate_hides_many(client, db):
    ids = await _make_reviews(db, "reviews-bulk-1")
    fake_id = 999999
    token = await login_token(client, ADMIN)
    r = await client.patch(
        "/api/admin/reviews/bulk-moderate",
        headers=auth_header(token),
        json={"review_ids": ids[:2] + [fake_id], "is_visible": False,
              "moderation_note": "Ẩn hàng loạt spam"},
    )
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["moderated_count"] == 2
    assert fake_id in body["not_found"]

    # 2 review đầu đã bị ẩn, review thứ 3 vẫn hiện
    for rid in ids[:2]:
        rv = await db.get(ContestReview, rid)
        await db.refresh(rv)
        assert rv.is_visible is False
    rv3 = await db.get(ContestReview, ids[2])
    await db.refresh(rv3)
    assert rv3.is_visible is True


async def test_bulk_moderate_requires_admin(client, db):
    ids = await _make_reviews(db, "reviews-bulk-2")
    token = await login_token(client, "b22dccn001@ptit.edu.vn")
    r = await client.patch(
        "/api/admin/reviews/bulk-moderate",
        headers=auth_header(token),
        json={"review_ids": ids, "is_visible": False},
    )
    assert r.status_code == 403


async def test_audit_log_filter_by_action_type(client, db):
    db.add(AuditLog(user_id=None, action_type="TEST_ACTION_ALPHA", entity_name="contests"))
    db.add(AuditLog(user_id=None, action_type="TEST_ACTION_BETA", entity_name="contests"))
    await db.commit()

    token = await login_token(client, ADMIN)
    r = await client.get("/api/admin/audit-logs",
                         headers=auth_header(token), params={"action_type": "ALPHA"})
    assert r.status_code == 200, r.text
    items = r.json()["items"]
    assert len(items) >= 1
    assert all("ALPHA" in it["action_type"] for it in items)
