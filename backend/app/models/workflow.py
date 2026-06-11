"""Workflow approvals BTC↔BCN (BCN_QD1, BCN_QD2)."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    BigInteger, DateTime, Enum as SAEnum, ForeignKey, Integer, Text, func,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base
from app.models.enums import ApprovalStatus, ApprovalStep, ApprovalTarget

if TYPE_CHECKING:
    from app.models.contest import Contest


class WorkflowApproval(Base):
    __tablename__ = "workflow_approvals"

    approval_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    target_type: Mapped[ApprovalTarget] = mapped_column(
        SAEnum(ApprovalTarget, name="approval_target_enum", schema="ptit_contest", create_type=False),
        nullable=False,
    )
    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), nullable=False,
    )
    step: Mapped[ApprovalStep] = mapped_column(
        SAEnum(ApprovalStep, name="approval_step_enum", schema="ptit_contest", create_type=False),
        nullable=False,
    )
    status: Mapped[ApprovalStatus] = mapped_column(
        SAEnum(ApprovalStatus, name="approval_status_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=ApprovalStatus.PENDING,
    )
    revision_round: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    submitted_by: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="RESTRICT"), nullable=False,
    )
    submitted_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    submission_note: Mapped[str | None] = mapped_column(Text)
    reviewed_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    reviewed_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    bcn_comment: Mapped[str | None] = mapped_column(Text)
    snapshot_json: Mapped[dict | None] = mapped_column(JSONB)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    contest: Mapped["Contest"] = relationship(back_populates="approvals")
