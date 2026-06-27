"""Contest core: contests, organizers M-N, rounds, sessions, judges M-N."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    BigInteger, Boolean, DateTime, Enum as SAEnum, ForeignKey, Integer, String, Text, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base
from app.models.enums import ContestStatus, DeliveryMode, EntryType, RoundType, SessionType

if TYPE_CHECKING:
    from app.models.entry import ContestEntry
    from app.models.judging import ContestResult
    from app.models.workflow import WorkflowApproval


class Contest(Base):
    __tablename__ = "contests"

    contest_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    slug: Mapped[str] = mapped_column(String(120), nullable=False, unique=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    rules_text: Mapped[str | None] = mapped_column(Text)
    award_text: Mapped[str | None] = mapped_column(Text)
    banner_url: Mapped[str | None] = mapped_column(Text)
    delivery_mode: Mapped[DeliveryMode] = mapped_column(
        SAEnum(DeliveryMode, name="delivery_mode_enum", schema="ptit_contest", create_type=False),
        nullable=False,
    )
    participation_mode: Mapped[EntryType] = mapped_column(
        SAEnum(EntryType, name="entry_type_enum", schema="ptit_contest", create_type=False),
        nullable=False,
    )
    team_min_members: Mapped[int | None] = mapped_column(Integer)
    team_max_members: Mapped[int | None] = mapped_column(Integer)
    max_entries: Mapped[int | None] = mapped_column(Integer)
    requires_submission: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    is_public: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    registration_open_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    registration_close_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    start_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    location_text: Mapped[str | None] = mapped_column(String(255))
    appeal_deadline: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    status: Mapped[ContestStatus] = mapped_column(
        SAEnum(ContestStatus, name="contest_status_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=ContestStatus.DRAFT,
    )
    proposed_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    host_faculty_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("faculties.faculty_id", ondelete="SET NULL"),
    )
    created_by: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="RESTRICT"), nullable=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    rounds: Mapped[list["ContestRound"]] = relationship(
        back_populates="contest", cascade="all, delete-orphan",
    )
    sessions: Mapped[list["ContestSession"]] = relationship(
        back_populates="contest", cascade="all, delete-orphan",
    )
    organizers: Mapped[list["ContestOrganizer"]] = relationship(
        back_populates="contest", cascade="all, delete-orphan",
    )
    entries: Mapped[list["ContestEntry"]] = relationship(
        back_populates="contest", cascade="all, delete-orphan",
    )
    results: Mapped[list["ContestResult"]] = relationship(
        back_populates="contest", cascade="all, delete-orphan",
    )
    approvals: Mapped[list["WorkflowApproval"]] = relationship(
        back_populates="contest", cascade="all, delete-orphan",
    )


class ContestOrganizer(Base):
    __tablename__ = "contest_organizers"

    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), primary_key=True,
    )
    organizer_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("organizers.organizer_id", ondelete="CASCADE"), primary_key=True,
    )
    assigned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    contest: Mapped["Contest"] = relationship(back_populates="organizers")


class ContestRound(Base):
    __tablename__ = "contest_rounds"

    round_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), nullable=False,
    )
    round_no: Mapped[int] = mapped_column(Integer, nullable=False)
    round_name: Mapped[str] = mapped_column(String(150), nullable=False)
    round_type: Mapped[RoundType] = mapped_column(
        SAEnum(RoundType, name="round_type_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=RoundType.OTHER,
    )
    description: Mapped[str | None] = mapped_column(Text)
    start_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    submission_open_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    submission_close_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    judging_open_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    judging_close_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    is_elimination_round: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    contest: Mapped["Contest"] = relationship(back_populates="rounds")


class ContestSession(Base):
    __tablename__ = "contest_sessions"

    session_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), nullable=False,
    )
    round_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("contest_rounds.round_id", ondelete="SET NULL"),
    )
    session_name: Mapped[str] = mapped_column(String(150), nullable=False)
    session_type: Mapped[SessionType] = mapped_column(
        SAEnum(SessionType, name="session_type_enum", schema="ptit_contest", create_type=False),
        nullable=False,
    )
    start_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    end_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    location_text: Mapped[str | None] = mapped_column(String(255))
    room_text: Mapped[str | None] = mapped_column(String(100))
    online_meeting_url: Mapped[str | None] = mapped_column(Text)
    checkin_open_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    checkin_close_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    contest: Mapped["Contest"] = relationship(back_populates="sessions")


class ContestJudge(Base):
    __tablename__ = "contest_judges"

    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), primary_key=True,
    )
    judge_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("judges.judge_id", ondelete="CASCADE"), primary_key=True,
    )
    assigned_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    assigned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
