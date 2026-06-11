"""Certificate business logic (BCN-06 + SV-09).

Lưu ý: PDF generation defer cho Phase 6+ (cần install reportlab/weasyprint).
Hiện chỉ store rendered HTML + URL placeholder. SV mở URL → backend render HTML on-demand.
"""

import secrets
from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.certificate import CertificateTemplate, IssuedCertificate
from app.models.contest import Contest
from app.models.entry import ContestEntry, TeamMember
from app.models.enums import ApprovalStatus, EntryType
from app.models.identity import AppUser
from app.models.judging import ContestResult
from app.models.master_data import DepartmentHead, Student, StudentDirectory


# ---------- Helpers ----------

async def _ensure_btc_or_hod(db: AsyncSession, user: AppUser, contest: Contest) -> None:
    if "ADMIN" in user.role_codes:
        return
    if "ORGANIZER" in user.role_codes and contest.created_by == user.user_id:
        return
    if "HOD" in user.role_codes:
        dh_stmt = select(DepartmentHead).where(DepartmentHead.user_id == user.user_id)
        dh = (await db.execute(dh_stmt)).scalar_one_or_none()
        if dh and dh.faculty_id == contest.host_faculty_id:
            return
    raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần BTC contest hoặc BCN khoa host")


async def _ensure_hod_for_contest(db: AsyncSession, user: AppUser, contest: Contest) -> None:
    if "ADMIN" in user.role_codes:
        return
    if "HOD" not in user.role_codes:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần role HOD")
    dh = (await db.execute(
        select(DepartmentHead).where(DepartmentHead.user_id == user.user_id)
    )).scalar_one_or_none()
    if dh is None or dh.faculty_id != contest.host_faculty_id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Không phải BCN khoa host")


# ---------- Template ----------

async def create_template(
    db: AsyncSession, user: AppUser, contest_id: int,
    template_name: str, html_template: str, background_image_url: str | None,
) -> CertificateTemplate:
    """BTC tạo template (chưa active, chờ BCN duyệt)."""
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    await _ensure_btc_or_hod(db, user, contest)

    template = CertificateTemplate(
        contest_id=contest_id,
        template_name=template_name,
        html_template=html_template,
        background_image_url=background_image_url,
        created_by=user.user_id,
    )
    db.add(template)
    await db.commit()
    await db.refresh(template)
    return template


async def list_templates(db: AsyncSession, contest_id: int) -> list[CertificateTemplate]:
    stmt = (
        select(CertificateTemplate)
        .where(CertificateTemplate.contest_id == contest_id)
        .order_by(CertificateTemplate.created_at.desc())
    )
    return list((await db.execute(stmt)).scalars().all())


async def approve_template(
    db: AsyncSession, user: AppUser, template_id: int
) -> CertificateTemplate:
    """BCN approve template (BCN_QĐ3)."""
    template = await db.get(CertificateTemplate, template_id)
    if template is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Template not found")
    contest = await db.get(Contest, template.contest_id)
    assert contest is not None
    await _ensure_hod_for_contest(db, user, contest)

    template.approved_by = user.user_id
    template.approved_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(template)
    return template


async def activate_template(
    db: AsyncSession, user: AppUser, template_id: int
) -> CertificateTemplate:
    """Set is_active=True (chỉ 1 template/contest active vì partial unique index)."""
    template = await db.get(CertificateTemplate, template_id)
    if template is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Template not found")
    if template.approved_at is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Template chưa được BCN duyệt, không activate được",
        )
    contest = await db.get(Contest, template.contest_id)
    assert contest is not None
    await _ensure_btc_or_hod(db, user, contest)

    # Deactivate other templates của contest (workaround partial unique)
    other_stmt = select(CertificateTemplate).where(
        CertificateTemplate.contest_id == template.contest_id,
        CertificateTemplate.template_id != template_id,
        CertificateTemplate.is_active.is_(True),
    )
    for other in (await db.execute(other_stmt)).scalars().all():
        other.is_active = False

    template.is_active = True
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, "Active template conflict") from e
    await db.refresh(template)
    return template


# ---------- Issue ----------

async def issue_certificates(
    db: AsyncSession, user: AppUser, contest_id: int, only_with_award: bool
) -> dict:
    """BCN-06 — Issue certs hàng loạt cho tất cả contest_results có bcn_approval_status=APPROVED."""
    contest = await db.get(Contest, contest_id)
    if contest is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Contest not found")
    await _ensure_btc_or_hod(db, user, contest)

    # Get active template
    tpl_stmt = select(CertificateTemplate).where(
        CertificateTemplate.contest_id == contest_id,
        CertificateTemplate.is_active.is_(True),
    )
    template = (await db.execute(tpl_stmt)).scalar_one_or_none()
    if template is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Chưa có active template. Tạo + approve + activate template trước.",
        )

    # Get APPROVED contest_results
    cr_stmt = select(ContestResult).where(
        ContestResult.contest_id == contest_id,
        ContestResult.bcn_approval_status == ApprovalStatus.APPROVED,
        ContestResult.published_at.is_not(None),
    )
    if only_with_award:
        cr_stmt = cr_stmt.where(ContestResult.award_title.is_not(None))
    contest_results = list((await db.execute(cr_stmt)).scalars().all())
    if not contest_results:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Không có contest_results đủ điều kiện (cần APPROVED + published_at)",
        )

    issued = []
    skipped = 0
    for cr in contest_results:
        # Skip if already issued
        existing = (await db.execute(
            select(IssuedCertificate).where(IssuedCertificate.contest_result_id == cr.contest_result_id)
        )).scalar_one_or_none()
        if existing is not None:
            skipped += 1
            continue

        qr_code = secrets.token_urlsafe(32)
        cert = IssuedCertificate(
            contest_result_id=cr.contest_result_id,
            template_id=template.template_id,
            qr_code=qr_code,
            pdf_url=f"/api/certificates/{qr_code}/render",  # render HTML on-demand
            issued_by=user.user_id,
        )
        db.add(cert)
        issued.append({
            "contest_result_id": cr.contest_result_id,
            "qr_code": qr_code,
            "rank_no": cr.rank_no,
            "award_title": cr.award_title,
        })

    await db.commit()
    return {"issued_count": len(issued), "skipped_count": skipped, "items": issued}


# ---------- Verify (public) ----------

async def verify_qr(db: AsyncSession, qr_code: str) -> dict:
    """Public verify — anyone có QR đều xem được info cert."""
    cert_stmt = select(IssuedCertificate).where(IssuedCertificate.qr_code == qr_code)
    cert = (await db.execute(cert_stmt)).scalar_one_or_none()
    if cert is None:
        return {"valid": False}

    cr = await db.get(ContestResult, cert.contest_result_id)
    contest = await db.get(Contest, cr.contest_id) if cr else None

    # Get student name (handle both INDIVIDUAL + TEAM)
    student_name = None
    student_code = None
    if cr:
        entry = await db.get(ContestEntry, cr.entry_id)
        if entry:
            if entry.entry_type == EntryType.INDIVIDUAL and entry.student_id:
                stmt = (
                    select(StudentDirectory)
                    .join(Student, Student.directory_id == StudentDirectory.directory_id)
                    .where(Student.student_id == entry.student_id)
                )
                sd = (await db.execute(stmt)).scalar_one_or_none()
                if sd:
                    student_name = sd.full_name
                    student_code = sd.student_code
            elif entry.team_id:
                # Team — show team representative (leader)
                from app.models.entry import Team
                team = await db.get(Team, entry.team_id)
                if team:
                    stmt = (
                        select(StudentDirectory)
                        .join(Student, Student.directory_id == StudentDirectory.directory_id)
                        .where(Student.student_id == team.leader_student_id)
                    )
                    sd = (await db.execute(stmt)).scalar_one_or_none()
                    if sd:
                        student_name = f"Đội: {team.team_name} (leader: {sd.full_name})"
                        student_code = sd.student_code

    return {
        "valid": cert.revoked_at is None,
        "cert_id": cert.cert_id,
        "contest_title": contest.title if contest else None,
        "award_title": cr.award_title if cr else None,
        "student_name": student_name,
        "student_code": student_code,
        "issued_at": cert.issued_at,
        "revoked": cert.revoked_at is not None,
        "revoke_reason": cert.revoke_reason,
    }
