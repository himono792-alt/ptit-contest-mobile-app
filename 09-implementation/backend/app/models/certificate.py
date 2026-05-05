"""Certificate templates + issued certificates (BCN-06)."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import BigInteger, Boolean, DateTime, ForeignKey, String, Text, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.judging import ContestResult


class CertificateTemplate(Base):
    __tablename__ = "certificate_templates"

    template_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), nullable=False,
    )
    template_name: Mapped[str] = mapped_column(String(150), nullable=False)
    html_template: Mapped[str] = mapped_column(Text, nullable=False)
    background_image_url: Mapped[str | None] = mapped_column(Text)
    approved_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )


class IssuedCertificate(Base):
    __tablename__ = "issued_certificates"

    cert_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_result_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("contest_results.contest_result_id", ondelete="CASCADE"),
        nullable=False, unique=True,
    )
    template_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("certificate_templates.template_id", ondelete="SET NULL"),
    )
    qr_code: Mapped[str] = mapped_column(String(64), nullable=False, unique=True)
    pdf_url: Mapped[str] = mapped_column(Text, nullable=False)
    issued_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    issued_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    revoked_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    revoked_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    revoke_reason: Mapped[str | None] = mapped_column(Text)

    contest_result: Mapped["ContestResult"] = relationship(back_populates="issued_certificate")
