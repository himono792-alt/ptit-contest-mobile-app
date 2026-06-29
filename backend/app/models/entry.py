"""Team / Entry / Session assignment."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    BigInteger, Boolean, DateTime, Enum as SAEnum, ForeignKey, String, Text, func, text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base
from app.models.enums import EntryType, ParticipantStatus, RegistrationStatus

if TYPE_CHECKING:
    from app.models.contest import Contest


class Team(Base):
    __tablename__ = "teams"

    team_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), nullable=False,
    )
    team_name: Mapped[str] = mapped_column(String(150), nullable=False)
    leader_student_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("students.student_id", ondelete="RESTRICT"), nullable=False,
    )
    status: Mapped[str] = mapped_column(String(30), nullable=False, default="ACTIVE")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    members: Mapped[list["TeamMember"]] = relationship(
        back_populates="team", cascade="all, delete-orphan",
    )


class TeamMember(Base):
    __tablename__ = "team_members"

    team_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("teams.team_id", ondelete="CASCADE"), primary_key=True,
    )
    student_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("students.student_id", ondelete="CASCADE"), primary_key=True,
    )
    is_leader: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    joined_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    team: Mapped["Team"] = relationship(back_populates="members")


class ContestEntry(Base):
    __tablename__ = "contest_entries"

    entry_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), nullable=False,
    )
    entry_type: Mapped[EntryType] = mapped_column(
        SAEnum(EntryType, name="entry_type_enum", schema="ptit_contest", create_type=False),
        nullable=False,
    )
    student_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("students.student_id", ondelete="RESTRICT"),
    )
    team_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("teams.team_id", ondelete="RESTRICT"),
    )
    anonymous_code: Mapped[str | None] = mapped_column(String(50), unique=True)
    registration_status: Mapped[RegistrationStatus] = mapped_column(
        SAEnum(RegistrationStatus, name="registration_status_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=RegistrationStatus.PENDING,
    )
    participant_status: Mapped[ParticipantStatus] = mapped_column(
        SAEnum(ParticipantStatus, name="participant_status_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=ParticipantStatus.REGISTERED,
    )
    approved_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    approved_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    registration_note: Mapped[str | None] = mapped_column(Text)
    # TRUE khi SV cố tình đăng ký dù đã được cảnh báo trùng lịch (option B).
    schedule_conflict_ack: Mapped[bool] = mapped_column(
        Boolean, nullable=False, server_default=text("false"), default=False,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    contest: Mapped["Contest"] = relationship(back_populates="entries")
    status_logs: Mapped[list["EntryStatusLog"]] = relationship(
        back_populates="entry", cascade="all, delete-orphan",
    )


class EntryStatusLog(Base):
    __tablename__ = "entry_status_logs"

    entry_status_log_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    entry_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_entries.entry_id", ondelete="CASCADE"), nullable=False,
    )
    old_status: Mapped[ParticipantStatus | None] = mapped_column(
        SAEnum(ParticipantStatus, name="participant_status_enum", schema="ptit_contest", create_type=False),
    )
    new_status: Mapped[ParticipantStatus] = mapped_column(
        SAEnum(ParticipantStatus, name="participant_status_enum", schema="ptit_contest", create_type=False),
        nullable=False,
    )
    changed_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    note: Mapped[str | None] = mapped_column(Text)
    changed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    entry: Mapped["ContestEntry"] = relationship(back_populates="status_logs")


class SessionEntry(Base):
    __tablename__ = "session_entries"

    session_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_sessions.session_id", ondelete="CASCADE"), primary_key=True,
    )
    entry_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contest_entries.entry_id", ondelete="CASCADE"), primary_key=True,
    )
    seat_no: Mapped[str | None] = mapped_column(String(30))
    assigned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
