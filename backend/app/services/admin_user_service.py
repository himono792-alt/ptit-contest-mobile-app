"""Admin user management business logic (AD-02)."""

from fastapi import HTTPException, status
from sqlalchemy import desc, func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.enums import RoleCode, UserStatus
from app.models.identity import AppUser, Role, UserRole
from app.models.master_data import (
    AcademicClass,
    DepartmentHead,
    Faculty,
    Judge,
    Major,
    Organizer,
    Student,
    StudentDirectory,
)
from app.schemas.admin import (
    AdminUserCreateIn,
    AdminUserUpdateIn,
    BulkImportIn,
    StudentDirectoryImportRow,
)
from app.security import hash_password


def _ensure_admin(user: AppUser) -> None:
    if "ADMIN" not in user.role_codes:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần role ADMIN")


# ---------- Listing ----------

async def list_users(
    db: AsyncSession,
    user: AppUser,
    *,
    role: RoleCode | None,
    status_filter: UserStatus | None,
    q: str | None,
    offset: int,
    limit: int,
) -> tuple[list[AppUser], int]:
    _ensure_admin(user)

    base = select(AppUser).options(
        selectinload(AppUser.user_roles).selectinload(UserRole.role)
    )
    if status_filter is not None:
        base = base.where(AppUser.status == status_filter)
    if q:
        base = base.where(
            or_(
                AppUser.email.ilike(f"%{q}%"),
                AppUser.full_name.ilike(f"%{q}%"),
            )
        )
    if role is not None:
        # Filter qua join
        base = base.join(UserRole, UserRole.user_id == AppUser.user_id).join(
            Role, Role.role_id == UserRole.role_id
        ).where(Role.role_code == role).distinct()

    count_stmt = select(func.count()).select_from(base.subquery())
    total = (await db.execute(count_stmt)).scalar_one()

    rows = (await db.execute(
        base.order_by(desc(AppUser.created_at)).offset(offset).limit(limit)
    )).scalars().all()
    return list(rows), total


# ---------- Create ----------

async def create_user(
    db: AsyncSession, admin: AppUser, data: AdminUserCreateIn
) -> AppUser:
    _ensure_admin(admin)

    # Check email unique
    if (await db.execute(select(AppUser).where(AppUser.email == data.email))).scalar_one_or_none():
        raise HTTPException(status.HTTP_409_CONFLICT, f"Email {data.email} đã tồn tại")

    # Validate role-specific requirements
    role_set = set(data.role_codes)
    if RoleCode.STUDENT in role_set and data.directory_id is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Role STUDENT cần directory_id (link tới student_directory)",
        )
    if RoleCode.HOD in role_set and data.faculty_id is None:
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Role HOD cần faculty_id",
        )

    # Create user
    new_user = AppUser(
        email=data.email,
        password_hash=hash_password(data.password),
        full_name=data.full_name,
        phone=data.phone,
    )
    db.add(new_user)
    await db.flush()

    # Assign roles
    for rc in data.role_codes:
        role = (await db.execute(select(Role).where(Role.role_code == rc))).scalar_one()
        db.add(UserRole(user_id=new_user.user_id, role_id=role.role_id))

    # Create profiles
    if RoleCode.STUDENT in role_set:
        # Verify directory exists
        directory = await db.get(StudentDirectory, data.directory_id)
        if directory is None:
            raise HTTPException(status.HTTP_400_BAD_REQUEST, "directory_id không tồn tại")
        db.add(Student(user_id=new_user.user_id, directory_id=data.directory_id))

    if RoleCode.ORGANIZER in role_set:
        db.add(Organizer(
            user_id=new_user.user_id,
            organization_name=data.organization_name,
            faculty_id=data.faculty_id,
        ))

    if RoleCode.JUDGE in role_set:
        db.add(Judge(user_id=new_user.user_id, expertise=data.expertise))

    if RoleCode.HOD in role_set:
        db.add(DepartmentHead(
            user_id=new_user.user_id,
            faculty_id=data.faculty_id,
            title=data.title,
            is_primary_approver=data.is_primary_approver,
        ))

    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, f"DB constraint: {e.orig}") from e

    return await reload_user(db, new_user.user_id)


async def reload_user(db: AsyncSession, user_id: int) -> AppUser:
    stmt = (
        select(AppUser)
        .where(AppUser.user_id == user_id)
        .options(selectinload(AppUser.user_roles).selectinload(UserRole.role))
    )
    return (await db.execute(stmt)).scalar_one()


# ---------- Update / lock / delete ----------

async def update_user(
    db: AsyncSession, admin: AppUser, user_id: int, data: AdminUserUpdateIn
) -> AppUser:
    _ensure_admin(admin)
    target = await db.get(AppUser, user_id)
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")

    update_data = data.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(target, k, v)
    await db.commit()
    return await reload_user(db, user_id)


async def lock_user(db: AsyncSession, admin: AppUser, user_id: int) -> AppUser:
    _ensure_admin(admin)
    target = await db.get(AppUser, user_id)
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    target.status = UserStatus.LOCKED
    await db.commit()
    return await reload_user(db, user_id)


async def unlock_user(db: AsyncSession, admin: AppUser, user_id: int) -> AppUser:
    _ensure_admin(admin)
    target = await db.get(AppUser, user_id)
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    target.status = UserStatus.ACTIVE
    await db.commit()
    return await reload_user(db, user_id)


async def soft_delete_user(db: AsyncSession, admin: AppUser, user_id: int) -> None:
    _ensure_admin(admin)
    target = await db.get(AppUser, user_id)
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")
    if target.user_id == admin.user_id:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Không tự xóa mình")
    target.status = UserStatus.DELETED
    await db.commit()


# ---------- Roles ----------

async def replace_roles(
    db: AsyncSession, admin: AppUser, user_id: int, role_codes: list[RoleCode]
) -> AppUser:
    _ensure_admin(admin)
    target = await db.get(AppUser, user_id)
    if target is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "User not found")

    # Delete current roles
    cur_stmt = select(UserRole).where(UserRole.user_id == user_id)
    for ur in (await db.execute(cur_stmt)).scalars().all():
        await db.delete(ur)
    await db.flush()

    # Add new
    for rc in role_codes:
        role = (await db.execute(select(Role).where(Role.role_code == rc))).scalar_one()
        db.add(UserRole(user_id=user_id, role_id=role.role_id))

    await db.commit()
    return await reload_user(db, user_id)


# ---------- Bulk import student_directory ----------

async def import_student_directory(
    db: AsyncSession, admin: AppUser, data: BulkImportIn
) -> dict:
    _ensure_admin(admin)
    inserted = 0
    skipped = 0
    errors: list[str] = []

    # Cache faculty/major/class by code
    faculties = {f.faculty_code: f.faculty_id for f in (await db.execute(select(Faculty))).scalars().all()}
    majors = {m.major_code: m.major_id for m in (await db.execute(select(Major))).scalars().all()}
    classes = {c.class_code: c.class_id for c in (await db.execute(select(AcademicClass))).scalars().all()}

    # Dedupe within batch: nếu cùng student_code xuất hiện nhiều lần, chỉ giữ first
    seen_in_batch: set[str] = set()

    for row in data.rows:
        if row.student_code in seen_in_batch:
            errors.append(f"{row.student_code}: duplicate trong cùng batch")
            continue
        seen_in_batch.add(row.student_code)

        try:
            existing = (await db.execute(
                select(StudentDirectory).where(StudentDirectory.student_code == row.student_code)
            )).scalar_one_or_none()
            if existing is not None:
                skipped += 1
                continue

            entry = StudentDirectory(
                student_code=row.student_code,
                ptit_email=row.ptit_email,
                full_name=row.full_name,
                faculty_id=faculties.get(row.faculty_code) if row.faculty_code else None,
                major_id=majors.get(row.major_code) if row.major_code else None,
                class_id=classes.get(row.class_code) if row.class_code else None,
                is_active=True,
            )
            db.add(entry)
            # Per-row commit để 1 row lỗi không rollback tất cả
            await db.commit()
            inserted += 1
        except IntegrityError as e:
            await db.rollback()
            errors.append(f"{row.student_code}: {e.orig}")
        except Exception as e:
            await db.rollback()
            errors.append(f"{row.student_code}: {e}")

    return {"inserted": inserted, "skipped": skipped, "errors": errors}
