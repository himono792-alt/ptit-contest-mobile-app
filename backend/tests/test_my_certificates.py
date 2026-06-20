"""Test SV lấy được mã QR chứng nhận của mình qua /me/results (2026-06-16).

Trước: MyResult không có qr_code → màn 'Chứng nhận' không tải/xác thực được.
Sau: list_my_results LEFT JOIN issued_certificates → trả cert_qr_code.
"""
from datetime import datetime, timedelta, timezone

import pytest
from sqlalchemy import select

from app.models.certificate import IssuedCertificate
from app.models.contest import Contest
from app.models.entry import ContestEntry
from app.models.enums import (
    ApprovalStatus,
    ContestStatus,
    DeliveryMode,
    EntryType,
    RegistrationStatus,
)
from app.models.identity import AppUser
from app.models.judging import ContestResult
from app.models.master_data import Student
from app.services import result_service

pytestmark = pytest.mark.asyncio
NOW = datetime.now(timezone.utc)


async def _student(db, email):
    u = (await db.execute(select(AppUser).where(AppUser.email == email))).scalar_one()
    st = (await db.execute(select(Student).where(Student.user_id == u.user_id))).scalar_one()
    return u, st


async def _result_with_cert(db, student, *, slug, qr):
    contest = Contest(
        slug=slug, title="Contest cert", delivery_mode=DeliveryMode.ONLINE,
        participation_mode=EntryType.INDIVIDUAL, start_at=NOW - timedelta(days=10),
        end_at=NOW - timedelta(days=1), status=ContestStatus.FINISHED, created_by=student.user_id,
    )
    db.add(contest)
    await db.flush()
    entry = ContestEntry(contest_id=contest.contest_id, entry_type=EntryType.INDIVIDUAL,
                         student_id=student.student_id, registration_status=RegistrationStatus.APPROVED)
    db.add(entry)
    await db.flush()
    cr = ContestResult(contest_id=contest.contest_id, entry_id=entry.entry_id, rank_no=1,
                       award_title="Giải Nhất", bcn_approval_status=ApprovalStatus.APPROVED,
                       published_at=NOW)
    db.add(cr)
    await db.flush()
    if qr is not None:
        db.add(IssuedCertificate(contest_result_id=cr.contest_result_id, qr_code=qr,
                                 pdf_url=f"/certs/{qr}.pdf"))
    await db.commit()
    return contest.contest_id


async def test_my_results_includes_cert_qr(db):
    user, st = await _student(db, "b22dccn001@ptit.edu.vn")
    cid = await _result_with_cert(db, st, slug="cert-qr-yes", qr="QR-VERIFY-ABC123")

    results = await result_service.list_my_results(db, user)
    target = next(r for r in results if r["contest_id"] == cid)
    assert target["cert_qr_code"] == "QR-VERIFY-ABC123"
    assert target["award_title"] == "Giải Nhất"


async def test_my_results_cert_qr_null_when_not_issued(db):
    """Có giải nhưng chưa cấp chứng nhận → cert_qr_code = None (FE ẩn nút tải)."""
    user, st = await _student(db, "b22dccn002@ptit.edu.vn")
    cid = await _result_with_cert(db, st, slug="cert-qr-no", qr=None)

    results = await result_service.list_my_results(db, user)
    target = next(r for r in results if r["contest_id"] == cid)
    assert target["cert_qr_code"] is None
