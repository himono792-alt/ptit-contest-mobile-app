"""Check-in / QR token."""

from datetime import datetime

from sqlalchemy import (
    BigInteger, Boolean, DateTime, Enum as SAEnum, ForeignKey, String, func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base
from app.models.enums import CheckinMethod, CheckinStatus


class CheckinQrToken(Base):
    __tablename__ = "checkin_qr_tokens"

    qr_token_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    session_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_sessions.session_id", ondelete="CASCADE"), nullable=False,
    )
    token_value: Mapped[str] = mapped_column(String(255), nullable=False, unique=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )


class Checkin(Base):
    __tablename__ = "checkins"

    checkin_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    session_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_sessions.session_id", ondelete="CASCADE"), nullable=False,
    )
    student_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("students.student_id", ondelete="CASCADE"), nullable=False,
    )
    entry_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("contest_entries.entry_id", ondelete="SET NULL"),
    )
    qr_token_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("checkin_qr_tokens.qr_token_id", ondelete="SET NULL"),
    )
    method: Mapped[CheckinMethod] = mapped_column(
        SAEnum(CheckinMethod, name="checkin_method_enum", schema="ptit_contest", create_type=False),
        nullable=False,
    )
    status: Mapped[CheckinStatus] = mapped_column(
        SAEnum(CheckinStatus, name="checkin_status_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=CheckinStatus.SUCCESS,
    )
    checked_in_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    device_info: Mapped[str | None] = mapped_column(String(255))
