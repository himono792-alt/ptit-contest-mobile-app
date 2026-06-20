"""Test tải PDF chứng nhận thật (2026-06-16).

GET /api/certificates/{qr}/pdf → PDF reportlab (public, ai có QR đều tải được).
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

pytestmark = pytest.mark.asyncio
NOW = datetime.now(timezone.utc)


async def _issue_cert(db, *, slug, qr):
    u = (await db.execute(
        select(AppUser).where(AppUser.email == "b22dccn001@ptit.edu.vn"))).scalar_one()
    st = (await db.execute(select(Student).where(Student.user_id == u.user_id))).scalar_one()
    contest = Contest(
        slug=slug, title="Contest PDF", delivery_mode=DeliveryMode.ONLINE,
        participation_mode=EntryType.INDIVIDUAL, start_at=NOW - timedelta(days=10),
        end_at=NOW - timedelta(days=1), status=ContestStatus.FINISHED, created_by=u.user_id,
    )
    db.add(contest)
    await db.flush()
    entry = ContestEntry(contest_id=contest.contest_id, entry_type=EntryType.INDIVIDUAL,
                         student_id=st.student_id, registration_status=RegistrationStatus.APPROVED)
    db.add(entry)
    await db.flush()
    cr = ContestResult(contest_id=contest.contest_id, entry_id=entry.entry_id, rank_no=1,
                       award_title="Giải Nhất", bcn_approval_status=ApprovalStatus.APPROVED,
                       published_at=NOW)
    db.add(cr)
    await db.flush()
    db.add(IssuedCertificate(contest_result_id=cr.contest_result_id, qr_code=qr,
                             pdf_url=f"/api/certificates/{qr}/pdf"))
    await db.commit()


async def test_download_cert_pdf(client, db):
    await _issue_cert(db, slug="cert-pdf-ok", qr="QR-PDF-TEST-001")
    r = await client.get("/api/certificates/QR-PDF-TEST-001/pdf")
    assert r.status_code == 200, r.text
    assert r.headers["content-type"] == "application/pdf"
    assert r.content[:4] == b"%PDF"
    assert len(r.content) > 2000  # PDF có nội dung thật
    assert "attachment" in r.headers.get("content-disposition", "")


async def test_download_cert_pdf_invalid_qr_404(client):
    r = await client.get("/api/certificates/khong-ton-tai-qr/pdf")
    assert r.status_code == 404


async def test_verify_returns_qr_code(client, db):
    """Fix: /verify/{qr} phải trả lại qr_code để FE dựng link tải PDF/HTML."""
    await _issue_cert(db, slug="cert-verify-qr", qr="QR-VERIFY-RET-9")
    r = await client.get("/api/verify/QR-VERIFY-RET-9")
    assert r.status_code == 200, r.text
    body = r.json()
    assert body["valid"] is True
    assert body["qr_code"] == "QR-VERIFY-RET-9"


async def test_render_html_uses_template(client, db):
    """/render trả HTML Mẫu C đã đổ dữ liệu (không còn placeholder)."""
    await _issue_cert(db, slug="cert-render-html", qr="QR-RENDER-HTML-1")
    r = await client.get("/api/certificates/QR-RENDER-HTML-1/render")
    assert r.status_code == 200
    body = r.text
    assert "{{" not in body  # đã thay hết placeholder
    assert "GIẤY CHỨNG NHẬN" in body
    assert "Nguyễn Văn An" in body  # student_name seed
    assert "QR-RENDER-HTML-1" in body
