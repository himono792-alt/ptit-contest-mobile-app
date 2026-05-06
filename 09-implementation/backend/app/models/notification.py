"""Notifications, articles, Q&A."""

from datetime import datetime

from sqlalchemy import (
    BigInteger, Boolean, DateTime, Enum as SAEnum, ForeignKey, String, Text, func,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base
from app.models.enums import NotificationScope, QuestionStatus


class Notification(Base):
    __tablename__ = "notifications"

    notification_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    scope: Mapped[NotificationScope] = mapped_column(
        SAEnum(NotificationScope, name="notification_scope_enum", schema="ptit_contest", create_type=False),
        nullable=False,
    )
    contest_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"),
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    # Phase 2 sprint 1 step 1 (2026-05-06): deep-link route cho FE navigate khi click notification
    # Format: "/contests/5", "/me/entries/12", "/cert-detail/abc". Null = không nav (default).
    target_route: Mapped[str | None] = mapped_column(String(255))
    is_global: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    recipients: Mapped[list["NotificationRecipient"]] = relationship(
        back_populates="notification", cascade="all, delete-orphan",
    )


class NotificationRecipient(Base):
    __tablename__ = "notification_recipients"

    notification_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("notifications.notification_id", ondelete="CASCADE"), primary_key=True,
    )
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="CASCADE"), primary_key=True,
    )
    is_read: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    read_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    notification: Mapped["Notification"] = relationship(back_populates="recipients")


class Article(Base):
    __tablename__ = "articles"

    article_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"),
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    summary: Mapped[str | None] = mapped_column(Text)
    content_html: Mapped[str] = mapped_column(Text, nullable=False)
    is_public: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    created_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    published_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )


class Question(Base):
    __tablename__ = "questions"

    question_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"),
    )
    asked_by_student_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("students.student_id", ondelete="CASCADE"), nullable=False,
    )
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    content_text: Mapped[str] = mapped_column(Text, nullable=False)
    status: Mapped[QuestionStatus] = mapped_column(
        SAEnum(QuestionStatus, name="question_status_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=QuestionStatus.OPEN,
    )
    is_public: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    answers: Mapped[list["QuestionAnswer"]] = relationship(
        back_populates="question", cascade="all, delete-orphan",
    )


class QuestionAnswer(Base):
    __tablename__ = "question_answers"

    answer_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    question_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("questions.question_id", ondelete="CASCADE"), nullable=False,
    )
    answered_by: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="RESTRICT"), nullable=False,
    )
    content_text: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    question: Mapped["Question"] = relationship(back_populates="answers")
