"""Master data: faculties, majors, classes, student_directory + 4 profile tables."""

from datetime import datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    BigInteger, Boolean, DateTime, ForeignKey, String, Text, func,
)
from sqlalchemy.dialects.postgresql import CITEXT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.identity import AppUser


class Faculty(Base):
    __tablename__ = "faculties"

    faculty_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    faculty_code: Mapped[str] = mapped_column(String(30), nullable=False, unique=True)
    faculty_name: Mapped[str] = mapped_column(String(150), nullable=False)


class Major(Base):
    __tablename__ = "majors"

    major_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    major_code: Mapped[str] = mapped_column(String(30), nullable=False, unique=True)
    major_name: Mapped[str] = mapped_column(String(150), nullable=False)
    faculty_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("faculties.faculty_id", ondelete="SET NULL"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )


class AcademicClass(Base):
    __tablename__ = "academic_classes"

    class_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    class_code: Mapped[str] = mapped_column(String(30), nullable=False, unique=True)
    class_name: Mapped[str] = mapped_column(String(150), nullable=False)
    faculty_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("faculties.faculty_id", ondelete="SET NULL"),
    )
    major_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("majors.major_id", ondelete="SET NULL"),
    )


class StudentDirectory(Base):
    __tablename__ = "student_directory"

    directory_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    student_code: Mapped[str] = mapped_column(String(30), nullable=False, unique=True)
    ptit_email: Mapped[str] = mapped_column(CITEXT, nullable=False, unique=True)
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    faculty_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("faculties.faculty_id", ondelete="SET NULL"),
    )
    major_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("majors.major_id", ondelete="SET NULL"),
    )
    class_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("academic_classes.class_id", ondelete="SET NULL"),
    )
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    synced_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    student: Mapped["Student | None"] = relationship(back_populates="directory_entry", uselist=False)


class Student(Base):
    __tablename__ = "students"

    student_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="CASCADE"), nullable=False, unique=True,
    )
    directory_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("student_directory.directory_id", ondelete="RESTRICT"),
        nullable=False, unique=True,
    )
    bio: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    user: Mapped["AppUser"] = relationship(back_populates="student")
    directory_entry: Mapped["StudentDirectory"] = relationship(back_populates="student")


class Organizer(Base):
    __tablename__ = "organizers"

    organizer_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="CASCADE"), nullable=False, unique=True,
    )
    organization_name: Mapped[str | None] = mapped_column(String(150))
    faculty_id: Mapped[int | None] = mapped_column(
        BigInteger, ForeignKey("faculties.faculty_id", ondelete="SET NULL"),
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    user: Mapped["AppUser"] = relationship(back_populates="organizer")


class Judge(Base):
    __tablename__ = "judges"

    judge_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="CASCADE"), nullable=False, unique=True,
    )
    expertise: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    user: Mapped["AppUser"] = relationship(back_populates="judge")


class DepartmentHead(Base):
    __tablename__ = "department_heads"

    dept_head_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="CASCADE"), nullable=False, unique=True,
    )
    faculty_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("faculties.faculty_id", ondelete="RESTRICT"), nullable=False,
    )
    title: Mapped[str | None] = mapped_column(String(100))
    is_primary_approver: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    user: Mapped["AppUser"] = relationship(back_populates="department_head")
