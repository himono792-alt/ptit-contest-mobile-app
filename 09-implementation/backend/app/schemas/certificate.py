"""Pydantic schemas cho certificates (BCN-06, SV-09)."""

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class CertificateTemplateCreateIn(BaseModel):
    """BCN-06 POST /api/contests/{id}/certificate-templates.

    BTC tạo template, BCN duyệt sau bằng /approve endpoint.
    """

    template_name: str = Field(..., min_length=2, max_length=150)
    html_template: str = Field(..., min_length=20, description="HTML với {{full_name}}, {{award_title}}, {{contest_title}}, {{issued_date}}, {{qr_code}}")
    background_image_url: str | None = None


class CertificateTemplateOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    template_id: int
    contest_id: int
    template_name: str
    html_template: str
    background_image_url: str | None = None
    approved_by: int | None = None
    approved_at: datetime | None = None
    is_active: bool
    created_by: int | None = None
    created_at: datetime


class IssueCertificatesIn(BaseModel):
    """BCN-06 POST /api/contests/{id}/certificates/issue.

    Issue cert hàng loạt cho tất cả contest_results đã APPROVED.
    """

    only_with_award: bool = Field(False, description="True = chỉ entries có award_title")


class IssueCertificatesOut(BaseModel):
    issued_count: int
    skipped_count: int
    items: list[dict] = []


class IssuedCertificateOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    cert_id: int
    contest_result_id: int
    template_id: int | None = None
    qr_code: str
    pdf_url: str
    issued_by: int | None = None
    issued_at: datetime
    revoked_at: datetime | None = None
    revoke_reason: str | None = None


class CertVerifyOut(BaseModel):
    """Public GET /verify/{qr_code} — anyone có QR đều xem được."""

    valid: bool
    cert_id: int | None = None
    contest_title: str | None = None
    award_title: str | None = None
    student_name: str | None = None
    student_code: str | None = None
    issued_at: datetime | None = None
    revoked: bool = False
    revoke_reason: str | None = None
