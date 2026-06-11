"""Auth business logic — tách khỏi router để dễ test + reuse."""

from datetime import datetime, timezone

from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.enums import RoleCode
from app.models.identity import AppUser, Role, UserRole
from app.models.master_data import Student, StudentDirectory
from app.schemas.auth import LoginIn, RegisterIn
from app.security import hash_password, verify_password


async def register_student(db: AsyncSession, data: RegisterIn) -> AppUser:
    """SV-01c: Tạo tài khoản sinh viên mới.

    Các bước:
    1. Validate MSSV phải tồn tại trong student_directory + is_active.
    2. Validate email khớp với student_directory.ptit_email.
    3. Tạo app_users, gán role STUDENT, tạo students profile.
    4. Update last_login_at sau khi tạo (optional).

    Raises 400 / 409 nếu validate fail.
    """
    # 1. Lookup directory by student_code
    stmt = select(StudentDirectory).where(StudentDirectory.student_code == data.student_code)
    directory = (await db.execute(stmt)).scalar_one_or_none()
    if directory is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"MSSV '{data.student_code}' không tồn tại trong danh mục SV PTIT",
        )
    if not directory.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="MSSV đã bị deactivate trong danh mục",
        )

    # 2. Email phải khớp với directory
    if str(directory.ptit_email).lower() != data.email.lower():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Email phải là '{directory.ptit_email}' (đã đăng ký trong danh mục SV)",
        )

    # 3. Check chưa có app_users với MSSV này
    existing = await db.execute(
        select(Student).where(Student.directory_id == directory.directory_id)
    )
    if existing.scalar_one_or_none() is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="MSSV này đã có tài khoản. Vui lòng login.",
        )

    # 4. Tạo user + student + role
    user = AppUser(
        email=data.email,
        password_hash=hash_password(data.password),
        full_name=data.full_name,
    )
    db.add(user)
    await db.flush()  # cần user.user_id

    # Lookup role STUDENT
    role_stmt = select(Role).where(Role.role_code == RoleCode.STUDENT)
    student_role = (await db.execute(role_stmt)).scalar_one()

    db.add(UserRole(user_id=user.user_id, role_id=student_role.role_id))
    db.add(Student(user_id=user.user_id, directory_id=directory.directory_id))

    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email đã được sử dụng",
        ) from e

    # Reload với roles để return
    return await _reload_user_with_roles(db, user.user_id)


async def authenticate(db: AsyncSession, data: LoginIn) -> AppUser:
    """SV-01a / GV-01 / BCN-01 / AD-01: Verify credentials."""
    stmt = (
        select(AppUser)
        .where(AppUser.email == data.email)
        .options(selectinload(AppUser.user_roles).selectinload(UserRole.role))
    )
    user = (await db.execute(stmt)).scalar_one_or_none()
    if user is None or not verify_password(data.password, user.password_hash):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Email hoặc mật khẩu không đúng",
        )
    if user.status != "ACTIVE":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Tài khoản đang ở trạng thái {user.status}",
        )

    # Update last_login_at
    user.last_login_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(user)
    return user


async def _reload_user_with_roles(db: AsyncSession, user_id: int) -> AppUser:
    stmt = (
        select(AppUser)
        .where(AppUser.user_id == user_id)
        .options(selectinload(AppUser.user_roles).selectinload(UserRole.role))
    )
    return (await db.execute(stmt)).scalar_one()
