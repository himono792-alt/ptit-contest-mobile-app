"""Test fix B: publish kết quả phải bulk-notify mọi SV đã đăng ký APPROVED.

Trước fix: publish_results trả notified_count = số dòng kết quả và KHÔNG tạo
notification nào → SV không được báo khi kết quả công bố.
Sau fix: tạo Notification + NotificationRecipient cho từng SV (entry APPROVED),
trả notified_count = số SV thực sự được notify, có deep-link /contests/{id}.
"""
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.models.contest import Contest
from app.models.entry import ContestEntry
from app.models.enums import (
    ApprovalStatus,
    ApprovalStep,
    ApprovalTarget,
    ContestStatus,
    DeliveryMode,
    EntryType,
    NotificationScope,
    RegistrationStatus,
)
from app.models.identity import AppUser, UserRole
from app.models.judging import ContestResult
from app.models.master_data import Student
from app.models.notification import Notification, NotificationRecipient
from app.models.workflow import WorkflowApproval
from app.services import result_service

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


async def _make_contest(db, gv, *, slug):
    contest = Contest(
        slug=slug,
        title="Cuộc thi test publish notify",
        delivery_mode=DeliveryMode.ONLINE,
        participation_mode=EntryType.INDIVIDUAL,
        start_at=NOW - timedelta(days=2),
        end_at=NOW + timedelta(days=2),
        status=ContestStatus.ONGOING,
        created_by=gv.user_id,
        proposed_by=gv.user_id,
    )
    db.add(contest)
    await db.flush()
    return contest


async def _add_entry(db, contest, student, reg_status):
    e = ContestEntry(
        contest_id=contest.contest_id,
        entry_type=EntryType.INDIVIDUAL,
        student_id=student.student_id,
        registration_status=reg_status,
    )
    db.add(e)
    await db.flush()
    return e


async def _approve_result_workflow(db, contest, gv):
    db.add(WorkflowApproval(
        target_type=ApprovalTarget.CONTEST_RESULT,
        contest_id=contest.contest_id,
        step=ApprovalStep.BCN_QD2,
        status=ApprovalStatus.APPROVED,
        revision_round=1,
        submitted_by=gv.user_id,
    ))
    await db.flush()


async def test_resolve_participants_only_approved(db):
    """_resolve_contest_participant_user_ids: chỉ lấy entry APPROVED."""
    gv = await _get_user(db, "gv@ptit.edu.vn")
    _, s1 = await _student_of(db, "b22dccn001@ptit.edu.vn")
    _, s2 = await _student_of(db, "b22dccn002@ptit.edu.vn")
    _, s3 = await _student_of(db, "b22dccn003@ptit.edu.vn")
    contest = await _make_contest(db, gv, slug="test-resolve-participants")
    await _add_entry(db, contest, s1, RegistrationStatus.APPROVED)
    await _add_entry(db, contest, s2, RegistrationStatus.APPROVED)
    await _add_entry(db, contest, s3, RegistrationStatus.PENDING)  # phải bị loại
    await db.commit()

    uids = await result_service._resolve_contest_participant_user_ids(db, contest.contest_id)
    assert set(uids) == {s1.user_id, s2.user_id}
    assert s3.user_id not in uids


async def test_publish_creates_notifications(db):
    """publish_results: tạo notification thật + notified_count đúng + deep-link."""
    gv = await _get_user(db, "gv@ptit.edu.vn")
    u1, s1 = await _student_of(db, "b22dccn001@ptit.edu.vn")
    u2, s2 = await _student_of(db, "b22dccn002@ptit.edu.vn")
    u3, s3 = await _student_of(db, "b22dccn003@ptit.edu.vn")
    contest = await _make_contest(db, gv, slug="test-publish-notify")
    e1 = await _add_entry(db, contest, s1, RegistrationStatus.APPROVED)
    e2 = await _add_entry(db, contest, s2, RegistrationStatus.APPROVED)
    await _add_entry(db, contest, s3, RegistrationStatus.CANCELLED)  # bị loại
    db.add(ContestResult(contest_id=contest.contest_id, entry_id=e1.entry_id,
                         rank_no=1, bcn_approval_status=ApprovalStatus.APPROVED))
    db.add(ContestResult(contest_id=contest.contest_id, entry_id=e2.entry_id,
                         rank_no=2, bcn_approval_status=ApprovalStatus.APPROVED))
    await _approve_result_workflow(db, contest, gv)
    await db.commit()

    out_contest, published_at, notified = await result_service.publish_results(
        db, gv, contest.contest_id
    )

    # notified_count = số SV APPROVED (2), KHÔNG phải số dòng kết quả
    assert notified == 2
    assert out_contest.status == ContestStatus.FINISHED
    assert published_at is not None

    # Notification thật được tạo, scope CONTEST + deep-link
    notif = (await db.execute(
        select(Notification).where(Notification.contest_id == contest.contest_id)
    )).scalars().all()
    assert len(notif) == 1
    assert notif[0].scope == NotificationScope.CONTEST
    assert notif[0].target_route == f"/contests/{contest.contest_id}"

    # Đúng 2 recipient: u1, u2 — KHÔNG có u3 (entry cancelled)
    recips = (await db.execute(
        select(NotificationRecipient.user_id)
        .where(NotificationRecipient.notification_id == notif[0].notification_id)
    )).scalars().all()
    assert set(recips) == {u1.user_id, u2.user_id}
    assert u3.user_id not in recips


async def test_publish_without_approval_blocked(db):
    """publish khi chưa có BCN_QĐ2 APPROVED → bị chặn (không 200)."""
    from fastapi import HTTPException

    gv = await _get_user(db, "gv@ptit.edu.vn")
    _, s1 = await _student_of(db, "b22dccn001@ptit.edu.vn")
    contest = await _make_contest(db, gv, slug="test-publish-no-approval")
    await _add_entry(db, contest, s1, RegistrationStatus.APPROVED)
    await db.commit()

    with pytest.raises(HTTPException) as exc:
        await result_service.publish_results(db, gv, contest.contest_id)
    assert exc.value.status_code in (400, 403)
