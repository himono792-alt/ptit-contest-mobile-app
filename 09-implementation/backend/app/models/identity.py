"""Identity / RBAC: roles, app_users, user_roles."""

from datetime import date, datetime
from typing import TYPE_CHECKING

from sqlalchemy import (
    BigInteger, Date, DateTime, Enum as SAEnum, ForeignKey, String, Text, func,
)
from sqlalchemy.dialects.postgresql import CITEXT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base
from app.models.enums import RoleCode, UserStatus

if TYPE_CHECKING:
    from app.models.master_data import (
        DepartmentHead, Judge, Organizer, Student,
    )


class Role(Base):
    __tablename__ = "roles"

    role_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    role_code: Mapped[RoleCode] = mapped_column(
        SAEnum(RoleCode, name="role_code_enum", schema="ptit_contest", create_type=False),
        nullable=False, unique=True,
    )
    role_name: Mapped[str] = mapped_column(String(100), nullable=False)

    user_roles: Mapped[list["UserRole"]] = relationship(back_populates="role")


class AppUser(Base):
    __tablename__ = "app_users"

    user_id: Mapped[int] = mapped_column(BigInteger, primary_key=True)
    email: Mapped[str] = mapped_column(CITEXT, nullable=False, unique=True)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    full_name: Mapped[str] = mapped_column(String(150), nullable=False)
    phone: Mapped[str | None] = mapped_column(String(20))
    avatar_url: Mapped[str | None] = mapped_column(Text)
    status: Mapped[UserStatus] = mapped_column(
        SAEnum(UserStatus, name="user_status_enum", schema="ptit_contest", create_type=False),
        nullable=False, default=UserStatus.ACTIVE,
    )
    email_verified_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    # Profile mở rộng (theo mẫu PTIT student card) — thêm 2026-05-05
    dob: Mapped[date | None] = mapped_column(Date)
    gender: Mapped[str | None] = mapped_column(String(10), comment="Nam / Nữ / Khác")
    citizen_id: Mapped[str | None] = mapped_column(String(20), comment="Số CMND/CCCD")
    place_of_birth: Mapped[str | None] = mapped_column(String(150))
    address: Mapped[str | None] = mapped_column(String(500))
    ethnicity: Mapped[str | None] = mapped_column(String(50), comment="Dân tộc, vd: Kinh")
    religion: Mapped[str | None] = mapped_column(String(50), comment="Tôn giáo, vd: Không")
    nationality: Mapped[str | None] = mapped_column(String(50), comment="Quốc tịch, vd: Việt Nam")
    secondary_email: Mapped[str | None] = mapped_column(String(255), comment="Email phụ cá nhân")
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    user_roles: Mapped[list["UserRole"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )

    # Profile relations (1-1 hoặc 1-0)
    student: Mapped["Student | None"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan",
    )
    organizer: Mapped["Organizer | None"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan",
    )
    judge: Mapped["Judge | None"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan",
    )
    department_head: Mapped["DepartmentHead | None"] = relationship(
        back_populates="user", uselist=False, cascade="all, delete-orphan",
    )

    @property
    def role_codes(self) -> set[str]:
        return {ur.role.role_code.value for ur in self.user_roles if ur.role}


class UserRole(Base):
    __tablename__ = "user_roles"

    user_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("app_users.user_id", ondelete="CASCADE"), primary_key=True,
    )
    role_id: Mapped[int] = mapped_column(
        BigInteger, ForeignKey("roles.role_id", ondelete="RESTRICT"), primary_key=True,
    )
    assigned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(),
    )

    user: Mapped["AppUser"] = relationship(back_populates="user_roles")
    role: Mapped["Role"] = relationship(back_populates="user_roles")
