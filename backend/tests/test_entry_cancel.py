"""Test rule hủy đăng ký theo thời gian — QĐ-03 (2026-06-16).

Đóng TODO entry_service: chỉ cho hủy đăng ký khi còn cách ngày thi bắt đầu
tối thiểu `cancel.min_days_before` ngày (seed = 7). Quá hạn → 409.
"""
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException
from sqlalchemy import select

from app.models.contest import Contest
from app.models.entry import ContestEntry
from app.models.enums import ContestStatus, DeliveryMode, EntryType, RegistrationStatus
from app.models.identity import AppUser
from app.models.master_data import Student
from app.services import entry_service

pytestmark = pytest.mark.asyncio
NOW = datetime.now(timezone.utc)


async def _student_user(db, email):
    user = (await db.execute(select(AppUser).where(AppUser.email == email))).scalar_one()
    st = (await db.execute(select(Student).where(Student.user_id == user.user_id))).scalar_one()
    return user, st


async def _make_contest_with_entry(db, student, *, slug, start_in_days):
    contest = Contest(
        slug=slug,
        title=f"Contest cancel {slug}",
        delivery_mode=DeliveryMode.ONLINE,
        participation_mode=EntryType.INDIVIDUAL,
        start_at=NOW + timedelta(days=start_in_days),
        end_at=NOW + timedelta(days=start_in_days + 5),
        status=ContestStatus.PUBLISHED if hasattr(ContestStatus, "PUBLISHED") else ContestStatus.ONGOING,
        created_by=student.user_id,
    )
    db.add(contest)
    await db.flush()
    db.add(ContestEntry(
        contest_id=contest.contest_id,
        entry_type=EntryType.INDIVIDUAL,
        student_id=student.student_id,
        registration_status=RegistrationStatus.APPROVED,
    ))
    await db.commit()
    return contest


async def test_cancel_allowed_when_far_from_start(db):
    """Còn 30 ngày tới ngày thi (> 7) → hủy được."""
    user, st = await _student_user(db, "b22dccn001@ptit.edu.vn")
    contest = await _make_contest_with_entry(db, st, slug="cancel-far", start_in_days=30)

    await entry_service.cancel_my_registration(db, user, contest.contest_id)

    entry = (await db.execute(
        select(ContestEntry).where(
            ContestEntry.contest_id == contest.contest_id,
            ContestEntry.student_id == st.student_id,
        )
    )).scalar_one()
    assert entry.registration_status == RegistrationStatus.CANCELLED


async def test_cancel_blocked_within_window(db):
    """Chỉ còn 2 ngày tới ngày thi (< 7) → chặn 409."""
    user, st = await _student_user(db, "b22dccn002@ptit.edu.vn")
    contest = await _make_contest_with_entry(db, st, slug="cancel-near", start_in_days=2)

    with pytest.raises(HTTPException) as exc:
        await entry_service.cancel_my_registration(db, user, contest.contest_id)
    assert exc.value.status_code == 409

    entry = (await db.execute(
        select(ContestEntry).where(
            ContestEntry.contest_id == contest.contest_id,
            ContestEntry.student_id == st.student_id,
        )
    )).scalar_one()
    assert entry.registration_status == RegistrationStatus.APPROVED  # không bị hủy
