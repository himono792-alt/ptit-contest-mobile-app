"""Certificate router (BCN-06 + SV-09 + public verify)."""

from typing import Annotated

from fastapi import APIRouter, Depends, status
from fastapi.responses import HTMLResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import CurrentUser
from app.models.certificate import IssuedCertificate
from app.schemas.certificate import (
    CertificateTemplateCreateIn,
    CertificateTemplateOut,
    CertVerifyOut,
    IssueCertificatesIn,
    IssueCertificatesOut,
)
from app.services import certificate_service

contests_certs_router = APIRouter(prefix="/contests", tags=["certificates"])
templates_router = APIRouter(prefix="/certificate-templates", tags=["certificates"])
certs_router = APIRouter(prefix="/certificates", tags=["certificates"])
verify_router = APIRouter(prefix="/verify", tags=["certificates"])


# ---------- Templates (BCN-06 phần 1) ----------

@contests_certs_router.post(
    "/{contest_id}/certificate-templates",
    response_model=CertificateTemplateOut,
    status_code=status.HTTP_201_CREATED,
)
async def create_template(
    contest_id: int,
    data: CertificateTemplateCreateIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CertificateTemplateOut:
    """BCN-06 — BTC tạo template HTML."""
    tpl = await certificate_service.create_template(
        db, user, contest_id, data.template_name, data.html_template, data.background_image_url
    )
    return CertificateTemplateOut.model_validate(tpl)


@contests_certs_router.get(
    "/{contest_id}/certificate-templates",
    response_model=list[CertificateTemplateOut],
)
async def list_templates(
    contest_id: int,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> list[CertificateTemplateOut]:
    items = await certificate_service.list_templates(db, contest_id)
    return [CertificateTemplateOut.model_validate(t) for t in items]


@templates_router.patch("/{template_id}/approve", response_model=CertificateTemplateOut)
async def approve_template(
    template_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CertificateTemplateOut:
    """BCN-06 — BCN duyệt template (BCN_QĐ3)."""
    tpl = await certificate_service.approve_template(db, user, template_id)
    return CertificateTemplateOut.model_validate(tpl)


@templates_router.patch("/{template_id}/activate", response_model=CertificateTemplateOut)
async def activate_template(
    template_id: int,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CertificateTemplateOut:
    """BTC activate template đã được BCN duyệt (chỉ 1 active/contest)."""
    tpl = await certificate_service.activate_template(db, user, template_id)
    return CertificateTemplateOut.model_validate(tpl)


# ---------- Issue (BCN-06 phần 2) ----------

@contests_certs_router.post(
    "/{contest_id}/certificates/issue",
    response_model=IssueCertificatesOut,
)
async def issue_certificates(
    contest_id: int,
    data: IssueCertificatesIn,
    user: CurrentUser,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> IssueCertificatesOut:
    """BCN-06 — Issue certs hàng loạt cho results đã APPROVED."""
    result = await certificate_service.issue_certificates(
        db, user, contest_id, data.only_with_award
    )
    return IssueCertificatesOut(**result)


# ---------- Verify (public, no auth) ----------

@verify_router.get("/{qr_code}", response_model=CertVerifyOut)
async def verify_certificate(
    qr_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> CertVerifyOut:
    """Public — anyone scan QR sẽ ra info cert (verify thật/giả)."""
    return CertVerifyOut(**await certificate_service.verify_qr(db, qr_code))


# ---------- Render HTML on-demand (SV-09) ----------

@certs_router.get("/{qr_code}/render", response_class=HTMLResponse)
async def render_certificate(
    qr_code: str,
    db: Annotated[AsyncSession, Depends(get_db)],
) -> HTMLResponse:
    """Render HTML cert (SV-09 download). Browser có thể print → save PDF."""
    info = await certificate_service.verify_qr(db, qr_code)
    if not info["valid"]:
        return HTMLResponse(
            "<h1>Chứng nhận không hợp lệ hoặc đã bị thu hồi</h1>",
            status_code=404,
        )

    # Get template HTML
    cert_stmt = select(IssuedCertificate).where(IssuedCertificate.qr_code == qr_code)
    cert = (await db.execute(cert_stmt)).scalar_one_or_none()
    if cert is None or cert.template_id is None:
        return HTMLResponse("<h1>Template không có</h1>", status_code=404)

    from app.models.certificate import CertificateTemplate

    tpl = await db.get(CertificateTemplate, cert.template_id)
    html = tpl.html_template if tpl else ""

    # Simple {{var}} replace
    replacements = {
        "{{full_name}}": info.get("student_name") or "",
        "{{student_code}}": info.get("student_code") or "",
        "{{award_title}}": info.get("award_title") or "",
        "{{contest_title}}": info.get("contest_title") or "",
        "{{issued_date}}": info["issued_at"].strftime("%d/%m/%Y") if info.get("issued_at") else "",
        "{{qr_code}}": qr_code,
    }
    for k, v in replacements.items():
        html = html.replace(k, str(v))

    return HTMLResponse(html)
