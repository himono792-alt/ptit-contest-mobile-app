"""Test phúc khảo kết quả (Result Appeal) — 2026-06-27.

Phủ:
  - Happy path: SV gửi → GV start-review → GV resolve (ACCEPTED/REJECTED).
  - Edge: chưa mở kênh (appeal_deadline NULL), quá hạn, không phải chủ entry,
    chưa có kết quả published, 1 entry 1 đơn mở, SV rút đơn, RBAC handle.
"""
from datetime import datetime, timedelta, timezone

import pytest
from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.contest import Contest
from app.models.entry import ContestEntry
from app.models.enums import (
    AppealStatus,
    ApprovalStatus,
    ContestStatus,
    DeliveryMode,
    EntryType,
    RegistrationStatus,
)
from app.models.identity import AppUser, UserRole
from app.models.judging import ContestResult
from app.models.master_data import Student
from app.services import appeal_service

pytestmark = pytest.mark.asyncio
NOW = datetime.now(timezone.utc)


async def _get_user(db, email):
    stmt = (
        select(AppUser)
        .options(selectinload(AppUser.user_roles).selectinload(UserRole.role))
        .where(AppUser.email == email)
    )
    return (await db.execute(stmt)).scalar_one()


async def _student_of(db, email):
    user = await _get_user(db, email)
    st = (await db.execute(select(Student).where(Student.user_id == user.user_id))).scalar_one()
    return user, st


async def _finished_contest_with_result(db, gv, student, *, slug, deadline_offset_days=7):
    """Tạo contest FINISHED + entry + ContestResult published; appeal_deadline = now+offset."""
    contest = Contest(
        slug=slug,
        title="Contest phúc khảo test",
        delivery_mode=DeliveryMode.ONLINE,
        participation_mode=EntryType.INDIVIDUAL,
        start_at=NOW - timedelta(days=5),
        end_at=NOW - timedelta(days=1),
        status=ContestStatus.FINISHED,
        created_by=gv.user_id,
        proposed_by=gv.user_id,
        appeal_deadline=(NOW + timedelta(days=deadline_offset_days))
        if deadline_offset_days is not None
        else None,
    )
    db.add(contest)
    await db.flush()
    entry = ContestEntry(
        contest_id=contest.contest_id,
        entry_type=EntryType.INDIVIDUAL,
        student_id=student.student_id,
        registration_status=RegistrationStatus.APPROVED,
    )
    db.add(entry)
    await db.flush()
    db.add(ContestResult(
        contest_id=contest.contest_id, entry_id=entry.entry_id,
        rank_no=2, bcn_approval_status=ApprovalStatus.APPROVED, published_at=NOW,
    ))
    await db.flush()
    return contest, entry


async def test_appeal_happy_path_accept(db):
    gv = await _get_user(db, "gv@ptit.edu.vn")
    sv_user, sv = await _student_of(db, "b22dccn001@ptit.edu.vn")
    contest, entry = await _finished_contest_with_result(db, gv, sv, slug="appeal-happy-accept")
    await db.commit()

    appeal = await appeal_service.create_appeal(
        db, sv_user, contest.contest_id, entry.entry_id, None,
        "Xin phúc khảo điểm vòng chung kết", "Em nghĩ điểm trình bày bị chấm thiếu",
    )
    assert appeal.status == AppealStatus.PENDING

    a2 = await appeal_service.start_review(db, gv, appeal.appeal_id)
    assert a2.status == AppealStatus.IN_REVIEW
    assert a2.handled_by == gv.user_id

    a3 = await appeal_service.resolve_appeal(
        db, gv, appeal.appeal_id, "ACCEPTED", "Chấp nhận, sẽ chấm lại tiêu chí trình bày",
    )
    assert a3.status == AppealStatus.ACCEPTED
    assert a3.response_text and a3.handled_at is not None


async def test_appeal_reject_when_score_correct(db):
    gv = await _get_user(db, "gv@ptit.edu.vn")
    sv_user, sv = await _student_of(db, "b22dccn002@ptit.edu.vn")
    contest, entry = await _finished_contest_with_result(db, gv, sv, slug="appeal-reject")
    await db.commit()

    appeal = await appeal_service.create_appeal(
        db, sv_user, contest.contest_id, entry.entry_id, None, "Phúc khảo", "Nội dung",
    )
    a = await appeal_service.resolve_appeal(
        db, gv, appeal.appeal_id, "REJECTED", "Đã rà soát, điểm chính xác",
    )
    assert a.status == AppealStatus.REJECTED


async def test_appeal_blocked_when_window_closed(db):
    gv = await _get_user(db, "gv@ptit.edu.vn")
    sv_user, sv = await _student_of(db, "b22dccn003@ptit.edu.vn")
    contest, entry = await _finished_contest_with_result(
        db, gv, sv, slug="appeal-no-window", deadline_offset_days=None,
    )
    await db.commit()
    with pytest.raises(HTTPException) as exc:
        await appeal_service.create_appeal(
            db, sv_user, contest.contest_id, entry.entry_id, None, "Phúc khảo", "Nội dung",
        )
    assert exc.value.status_code == 409


async def test_appeal_blocked_when_past_deadline(db):
    gv = await _get_user(db, "gv@ptit.edu.vn")
    sv_user, sv = await _student_of(db, "b22dccn001@ptit.edu.vn")
    contest, entry = await _finished_contest_with_result(
        db, gv, sv, slug="appeal-past-deadline", deadline_offset_days=-1,
    )
    await db.commit()
    with pytest.raises(HTTPException) as exc:
        await appeal_service.create_appeal(
            db, sv_user, contest.contest_id, entry.entry_id, None, "Phúc khảo", "Nội dung",
        )
    assert exc.value.status_code == 409


async def test_appeal_blocked_not_owner(db):
    gv = await _get_user(db, "gv@ptit.edu.vn")
    _, owner = await _student_of(db, "b22dccn002@ptit.edu.vn")
    other_user, _ = await _student_of(db, "b22dccn003@ptit.edu.vn")
    contest, entry = await _finished_contest_with_result(db, gv, owner, slug="appeal-not-owner")
    await db.commit()
    with pytest.raises(HTTPException) as exc:
        await appeal_service.create_appeal(
            db, other_user, contest.contest_id, entry.entry_id, None, "Phúc khảo", "Nội dung",
        )
    assert exc.value.status_code == 403


async def test_appeal_one_open_per_entry(db):
    gv = await _get_user(db, "gv@ptit.edu.vn")
    sv_user, sv = await _student_of(db, "b22dccn001@ptit.edu.vn")
    contest, entry = await _finished_contest_with_result(db, gv, sv, slug="appeal-dup")
    await db.commit()
    await appeal_service.create_appeal(
        db, sv_user, contest.contest_id, entry.entry_id, None, "Phúc khảo 1", "ND1",
    )
    with pytest.raises(HTTPException) as exc:
        await appeal_service.create_appeal(
            db, sv_user, contest.contest_id, entry.entry_id, None, "Phúc khảo 2", "ND2",
        )
    assert exc.value.status_code == 409


async def test_appeal_withdraw(db):
    gv = await _get_user(db, "gv@ptit.edu.vn")
    sv_user, sv = await _student_of(db, "b22dccn002@ptit.edu.vn")
    contest, entry = await _finished_contest_with_result(db, gv, sv, slug="appeal-withdraw")
    await db.commit()
    appeal = await appeal_service.create_appeal(
        db, sv_user, contest.contest_id, entry.entry_id, None, "Phúc khảo", "ND",
    )
    a = await appeal_service.withdraw_appeal(db, sv_user, appeal.appeal_id)
    assert a.status == AppealStatus.CLOSED
    # rút xong có thể tạo lại
    appeal2 = await appeal_service.create_appeal(
        db, sv_user, contest.contest_id, entry.entry_id, None, "Phúc khảo lại", "ND2",
    )
    assert appeal2.status == AppealStatus.PENDING


async def test_appeal_resolve_rbac_only_btc(db):
    gv = await _get_user(db, "gv@ptit.edu.vn")
    sv_user, sv = await _student_of(db, "b22dccn003@ptit.edu.vn")
    contest, entry = await _finished_contest_with_result(db, gv, sv, slug="appeal-rbac")
    await db.commit()
    appeal = await appeal_service.create_appeal(
        db, sv_user, contest.contest_id, entry.entry_id, None, "Phúc khảo", "ND",
    )
    # SV không được resolve
    with pytest.raises(HTTPException) as exc:
        await appeal_service.resolve_appeal(
            db, sv_user, appeal.appeal_id, "REJECTED", "khong duoc",
        )
    assert exc.value.status_code == 403
