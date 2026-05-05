"""Rubric / Judge assignment / Score / Result / Appeal."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    BigInteger, Boolean, DateTime, Enum as SAEnum, ForeignKey, Integer, Numeric, String, Text, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base
from app.models.enums import AppealStatus, ApprovalStatus

if TYPE_CHECKING:
    from app.models.certificate import IssuedCertificate
    from app.models.contest import Contest


class RoundScoreCriterion(Base):
    __tablename__ = "round_score_criteria"

    criterion_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    round_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_rounds.round_id", ondelete="CASCADE"), nullable=False,
    )
    criterion_name: Mapped[str] = mapped_column(String(150), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    max_score: Mapped[float] = mapped_column(Numeric(8, 2), nullable=False)
    weight_percent: Mapped[float | None] = mapped_column(Numeric(5, 2))
    display_order: Mapped[int] = mapped_column(Integer, nullable=False, default=1)


class JudgeAssignment(Base):
    __tablename__ = "judge_assignments"

    assignment_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    round_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_rounds.round_id", ondelete="CASCADE"), nullable=False,
    )
    entry_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_entries.entry_id", ondelete="CASCADE"), nullable=False,
    )
    submission_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("submissions.submission_id", ondelete="SET NULL"),
    )
    judge_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("judges.judge_id", ondelete="CASCADE"), nullable=False,
    )
    assigned_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    can_view_identity: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    assigned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    scores: Mapped[list["Score"]] = relationship(
        back_populates="assignment", cascade="all, delete-orphan",
    )


class Score(Base):
    __tablename__ = "scores"

    score_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    assignment_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("judge_assignments.assignment_id", ondelete="CASCADE"), nullable=False,
    )
    criterion_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("round_score_criteria.criterion_id", ondelete="CASCADE"),
        nullable=False,
    )
    score_value: Mapped[float] = mapped_column(Numeric(8, 2), nullable=False)
    comment_text: Mapped[str | None] = mapped_column(Text)
    scored_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    assignment: Mapped["JudgeAssignment"] = relationship(back_populates="scores")


class RoundResult(Base):
    __tablename__ = "round_results"

    round_result_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    round_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_rounds.round_id", ondelete="CASCADE"), nullable=False,
    )
    entry_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_entries.entry_id", ondelete="CASCADE"), nullable=False,
    )
    total_score: Mapped[float | None] = mapped_column(Numeric(10, 2))
    average_score: Mapped[float | None] = mapped_column(Numeric(10, 2))
    rank_no: Mapped[int | None] = mapped_column(Integer)
    is_passed: Mapped[bool | None] = mapped_column(Boolean)
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    generated_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )


class ContestResult(Base):
    __tablename__ = "contest_results"

    contest_result_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), nullable=False,
    )
    entry_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_entries.entry_id", ondelete="CASCADE"), nullable=False,
    )
    final_score: Mapped[float | None] = mapped_column(Numeric(10, 2))
    rank_no: Mapped[int | None] = mapped_column(Integer)
    award_title: Mapped[str | None] = mapped_column(String(255))
    bcn_approval_status: Mapped[ApprovalStatus] = mapped_column(
        SAEnum(ApprovalStatus, name="approval_status_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=ApprovalStatus.PENDING,
    )
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    generated_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    contest: Mapped["Contest"] = relationship(back_populates="results")
    issued_certificate: Mapped["IssuedCertificate | None"] = relationship(
        back_populates="contest_result", uselist=False,
    )


class ResultAppeal(Base):
    __tablename__ = "result_appeals"

    appeal_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), nullable=False,
    )
    round_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("contest_rounds.round_id", ondelete="SET NULL"),
    )
    entry_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_entries.entry_id", ondelete="CASCADE"), nullable=False,
    )
    submitted_by_student_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("students.student_id", ondelete="RESTRICT"), nullable=False,
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    content_text: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[AppealStatus] = mapped_column(
        SAEnum(AppealStatus, name="appeal_status_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=AppealStatus.PENDING,
    )
    response_text: Mapped[str | None] = mapped_column(Text)
    handled_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    handled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
