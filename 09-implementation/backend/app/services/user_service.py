"""User profile management business logic."""

from datetime import timedelta
from typing import Any

from fastapi import HTTPException, status
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.identity import AppUser, UserRole
from app.models.master_data import Student
from app.schemas.user import ChangePasswordIn, UpdateMeIn
from app.security import (
    create_access_token,
    decode_token,
    hash_password,
    verify_password,
)

# JWT scope marker cho password reset token (phân biệt với access token)
_PWD_RESET_SCOPE = "password_reset"
_PWD_RESET_EXPIRE = timedelta(minutes=15)


async def update_me(db: AsyncSession, user: AppUser, data: UpdateMeIn) -> AppUser:
    """SV-02 — Update các field tự sửa được.

    Mở rộng 2026-05-05: nhận thêm DOB, gender, address, citizen_id, ethnicity,
    religion, nationality, place_of_birth, secondary_email.
    """
    # Field cũ
    if data.full_name is not None:
        user.full_name = data.full_name
    if data.phone is not None:
        user.phone = data.phone
    if data.avatar_url is not None:
        user.avatar_url = data.avatar_url

    # Profile mở rộng — set thẳng vào AppUser (đã ALTER TABLE ở startup)
    for field in (
        "dob", "gender", "citizen_id", "place_of_birth", "address",
        "ethnicity", "religion", "nationality", "secondary_email",
    ):
        val = getattr(data, field, None)
        if val is not None:
            setattr(user, field, val)

    # Bio chỉ cho student
    if data.bio is not None:
        if user.student is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Field 'bio' chỉ áp dụng cho sinh viên",
            )
        user.student.bio = data.bio

    await db.commit()
    await db.refresh(user)
    return user


async def change_password(db: AsyncSession, user: AppUser, data: ChangePasswordIn) -> None:
    """SV-02 — Đổi mật khẩu (yêu cầu nhập password cũ để verify)."""
    if not verify_password(data.current_password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mật khẩu hiện tại không đúng",
        )
    if data.current_password == data.new_password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mật khẩu mới phải khác mật khẩu cũ",
        )
    user.password_hash = hash_password(data.new_password)
    await db.commit()


async def request_password_reset(db: AsyncSession, email: str) -> str | None:
    """SV-02 — Tạo reset token (JWT short-lived 15 phút).

    Trả token để dev stub log ra console. Production gửi qua email.
    Trả None nếu email không tồn tại (để chống enumerate emails).
    """
    stmt = select(AppUser).where(AppUser.email == email)
    user = (await db.execute(stmt)).scalar_one_or_none()
    if user is None or user.status != "ACTIVE":
        return None
    return create_access_token(
        subject=user.user_id,
        extra={"scope": _PWD_RESET_SCOPE, "email": email},
        expires_delta=_PWD_RESET_EXPIRE,
    )


async def reset_password_with_token(
    db: AsyncSession, reset_token: str, new_password: str
) -> None:
    """SV-02 — Verify reset token + set password mới."""
    try:
        payload: dict[str, Any] = decode_token(reset_token)
    except JWTError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Reset token không hợp lệ hoặc đã hết hạn",
        ) from e

    if payload.get("scope") != _PWD_RESET_SCOPE:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Token không phải dạng reset password",
        )

    user_id = int(payload["sub"])
    user = await db.get(AppUser, user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User không tồn tại",
        )
    user.password_hash = hash_password(new_password)
    await db.commit()


async def soft_delete_me(db: AsyncSession, user: AppUser) -> None:
    """SV-03 — Soft delete: set status=DELETED, không xóa data thật."""
    user.status = "DELETED"  # type: ignore[assignment]
    await db.commit()


async def reload_user_with_roles(db: AsyncSession, user_id: int) -> AppUser:
    """Helper: reload user kèm roles + student profile (để format response /me)."""
    stmt = (
        select(AppUser)
        .where(AppUser.user_id == user_id)
        .options(
            selectinload(AppUser.user_roles).selectinload(UserRole.role),
            selectinload(AppUser.student).selectinload(Student.directory_entry),
        )
    )
    return (await db.execute(stmt)).scalar_one()
