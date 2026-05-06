"""Submission / version / file."""

from datetime import datetime

from sqlalchemy import (
    BigInteger, Boolean, DateTime, Enum as SAEnum, ForeignKey, Integer, LargeBinary,
    String, Text, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base
from app.models.enums import SubmissionStatus


class Submission(Base):
    __tablename__ = "submissions"

    submission_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    round_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_rounds.round_id", ondelete="CASCADE"), nullable=False,
    )
    entry_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_entries.entry_id", ondelete="CASCADE"), nullable=False,
    )
    current_version_no: Mapped[int] = mapped_column(Integer, nullable=False, default=0)
    status: Mapped[SubmissionStatus] = mapped_column(
        SAEnum(SubmissionStatus, name="submission_status_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=SubmissionStatus.DRAFT,
    )
    is_locked: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    submitted_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    updated_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    versions: Mapped[list["SubmissionVersion"]] = relationship(
        back_populates="submission", cascade="all, delete-orphan",
    )


class SubmissionVersion(Base):
    __tablename__ = "submission_versions"

    submission_version_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    submission_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("submissions.submission_id", ondelete="CASCADE"), nullable=False,
    )
    version_no: Mapped[int] = mapped_column(Integer, nullable=False)
    title: Mapped[str | None] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(Text)
    external_link: Mapped[str | None] = mapped_column(Text)
    text_answer: Mapped[str | None] = mapped_column(Text)
    checksum_value: Mapped[str | None] = mapped_column(String(128))
    submitted_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    note: Mapped[str | None] = mapped_column(Text)

    submission: Mapped["Submission"] = relationship(back_populates="versions")
    files: Mapped[list["SubmissionFile"]] = relationship(
        back_populates="version", cascade="all, delete-orphan",
    )


class SubmissionFile(Base):
    __tablename__ = "submission_files"

    submission_file_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    submission_version_id: Mapped[int] = mapped_column(
        BigInteger,
        ForeignKey("submission_versions.submission_version_id", ondelete="CASCADE"),
        nullable=False,
    )
    file_name: Mapped[str] = mapped_column(String(255), nullable=False)
    file_url: Mapped[str] = mapped_column(Text, nullable=False)
    mime_type: Mapped[str | None] = mapped_column(String(100))
    file_size_bytes: Mapped[int | None] = mapped_column(BigInteger)
    # Demo: lưu file bytes trong DB (≤10MB). Production nên dùng S3/R2.
    file_data: Mapped[bytes | None] = mapped_column(LargeBinary)
    # Sprint 3 (2026-05-07): R2 object key path (vd: contests/123/rounds/45/...).
    # Khi NOT NULL → file ở R2, BE proxy stream khi download. Khi NULL + file_data NOT NULL → legacy.
    r2_object_key: Mapped[str | None] = mapped_column(String(500))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    version: Mapped["SubmissionVersion"] = relationship(back_populates="files")
