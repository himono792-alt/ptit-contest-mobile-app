"""Master data CRUD (AD-03 faculties / majors / classes)."""

from fastapi import HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.identity import AppUser
from app.models.master_data import (
    AcademicClass,
    Faculty,
    Major,
    StudentDirectory,
)


def _ensure_admin(user: AppUser) -> None:
    if "ADMIN" not in user.role_codes:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Cần role ADMIN")


# ---------- Faculties ----------

async def list_faculties(db: AsyncSession) -> list[Faculty]:
    stmt = select(Faculty).order_by(Faculty.faculty_code)
    return list((await db.execute(stmt)).scalars().all())


async def create_faculty(db: AsyncSession, user: AppUser, code: str, name: str) -> Faculty:
    _ensure_admin(user)
    f = Faculty(faculty_code=code, faculty_name=name)
    db.add(f)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, f"faculty_code '{code}' đã tồn tại") from e
    await db.refresh(f)
    return f


async def update_faculty(
    db: AsyncSession, user: AppUser, faculty_id: int, code: str | None, name: str | None
) -> Faculty:
    _ensure_admin(user)
    f = await db.get(Faculty, faculty_id)
    if f is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Faculty not found")
    if code is not None:
        f.faculty_code = code
    if name is not None:
        f.faculty_name = name
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, f"faculty_code conflict: {e.orig}") from e
    await db.refresh(f)
    return f


async def delete_faculty(db: AsyncSession, user: AppUser, faculty_id: int) -> None:
    _ensure_admin(user)
    f = await db.get(Faculty, faculty_id)
    if f is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Faculty not found")
    # Check no students in directory
    cnt_stmt = select(func.count()).select_from(StudentDirectory).where(
        StudentDirectory.faculty_id == faculty_id
    )
    if (await db.execute(cnt_stmt)).scalar_one() > 0:
        raise HTTPException(
            status.HTTP_409_CONFLICT,
            "Không xóa được vì còn SV thuộc khoa (xóa SV trước hoặc set faculty_id=NULL)",
        )
    await db.delete(f)
    await db.commit()


# ---------- Majors ----------

async def list_majors(db: AsyncSession, faculty_id: int | None = None) -> list[Major]:
    stmt = select(Major).order_by(Major.major_code)
    if faculty_id is not None:
        stmt = stmt.where(Major.faculty_id == faculty_id)
    return list((await db.execute(stmt)).scalars().all())


async def create_major(
    db: AsyncSession, user: AppUser, code: str, name: str, faculty_id: int | None
) -> Major:
    _ensure_admin(user)
    m = Major(major_code=code, major_name=name, faculty_id=faculty_id)
    db.add(m)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, f"major_code '{code}' đã tồn tại") from e
    await db.refresh(m)
    return m


async def update_major(
    db: AsyncSession, user: AppUser, major_id: int,
    code: str | None, name: str | None, faculty_id: int | None,
) -> Major:
    _ensure_admin(user)
    m = await db.get(Major, major_id)
    if m is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Major not found")
    if code is not None:
        m.major_code = code
    if name is not None:
        m.major_name = name
    if faculty_id is not None:
        m.faculty_id = faculty_id
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, str(e.orig)) from e
    await db.refresh(m)
    return m


async def delete_major(db: AsyncSession, user: AppUser, major_id: int) -> None:
    _ensure_admin(user)
    m = await db.get(Major, major_id)
    if m is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Major not found")
    cnt_stmt = select(func.count()).select_from(StudentDirectory).where(
        StudentDirectory.major_id == major_id
    )
    if (await db.execute(cnt_stmt)).scalar_one() > 0:
        raise HTTPException(status.HTTP_409_CONFLICT, "Còn SV thuộc ngành này")
    await db.delete(m)
    await db.commit()


# ---------- Classes ----------

async def list_classes(
    db: AsyncSession, faculty_id: int | None = None, major_id: int | None = None
) -> list[AcademicClass]:
    stmt = select(AcademicClass).order_by(AcademicClass.class_code)
    if faculty_id is not None:
        stmt = stmt.where(AcademicClass.faculty_id == faculty_id)
    if major_id is not None:
        stmt = stmt.where(AcademicClass.major_id == major_id)
    return list((await db.execute(stmt)).scalars().all())


async def create_class(
    db: AsyncSession, user: AppUser,
    code: str, name: str, faculty_id: int | None, major_id: int | None,
) -> AcademicClass:
    _ensure_admin(user)
    c = AcademicClass(class_code=code, class_name=name, faculty_id=faculty_id, major_id=major_id)
    db.add(c)
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, f"class_code '{code}' đã tồn tại") from e
    await db.refresh(c)
    return c


async def update_class(
    db: AsyncSession, user: AppUser, class_id: int,
    code: str | None, name: str | None,
    faculty_id: int | None, major_id: int | None,
) -> AcademicClass:
    _ensure_admin(user)
    c = await db.get(AcademicClass, class_id)
    if c is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Class not found")
    if code is not None:
        c.class_code = code
    if name is not None:
        c.class_name = name
    if faculty_id is not None:
        c.faculty_id = faculty_id
    if major_id is not None:
        c.major_id = major_id
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(status.HTTP_409_CONFLICT, str(e.orig)) from e
    await db.refresh(c)
    return c


async def delete_class(db: AsyncSession, user: AppUser, class_id: int) -> None:
    _ensure_admin(user)
    c = await db.get(AcademicClass, class_id)
    if c is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Class not found")
    cnt_stmt = select(func.count()).select_from(StudentDirectory).where(
        StudentDirectory.class_id == class_id
    )
    if (await db.execute(cnt_stmt)).scalar_one() > 0:
        raise HTTPException(status.HTTP_409_CONFLICT, "Còn SV thuộc lớp này")
    await db.delete(c)
    await db.commit()
