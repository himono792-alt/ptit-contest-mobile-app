"""Contest reviews (SV-11)."""

from datetime import datetime

from sqlalchemy import (
    BigInteger, Boolean, DateTime, ForeignKey, SmallInteger, Text, func,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.models.base import Base


class ContestReview(Base):
    __tablename__ = "contest_reviews"

    review_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    contest_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("contests.contest_id", ondelete="CASCADE"), nullable=False,
    )
    student_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("students.student_id", ondelete="CASCADE"), nullable=False,
    )
    rating: Mapped[int] = mapped_column(SmallInteger, nullable=False)  # 1-5 (CHECK ở DB)
    comment_text: Mapped[str | None] = mapped_column(Text)
    is_visible: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    moderated_by: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="SET NULL"),
    )
    moderated_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    moderation_note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
