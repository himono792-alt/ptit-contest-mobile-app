"""Seed thêm test users để test E2E workflow QĐ1.

Tạo:
  - 1 ORGANIZER (GV. Nguyen Van A)  email gv@ptit.edu.vn  password abc123
  - 1 HOD       (BCN. Tran Van B)   email bcn@ptit.edu.vn password abc123
                → gắn faculty_id của khoa CNTT (đã seed trong setup-dev.sh)

Cách chạy:
    cd 09-implementation/backend
    source .venv/bin/activate
    python scripts/seed-test-users.py
"""
import asyncio
import sys
from pathlib import Path

# Cho phép import app.* khi chạy script
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select
from app.database import AsyncSessionLocal, engine
from app.models.enums import RoleCode
from app.models.identity import AppUser, Role, UserRole
from app.models.master_data import DepartmentHead, Faculty, Organizer
from app.security import hash_password


async def get_or_create_user(db, email, full_name, password):
    existing = (await db.execute(select(AppUser).where(AppUser.email == email))).scalar_one_or_none()
    if existing:
        print(f"  ! User {email} đã tồn tại — bỏ qua")
        return existing, False
    user = AppUser(email=email, password_hash=hash_password(password), full_name=full_name)
    db.add(user)
    await db.flush()
    print(f"  + Tạo user {email} (id={user.user_id})")
    return user, True


async def assign_role(db, user_id, role_code):
    role = (await db.execute(select(Role).where(Role.role_code == role_code))).scalar_one()
    existing = (await db.execute(
        select(UserRole).where(UserRole.user_id == user_id, UserRole.role_id == role.role_id)
    )).scalar_one_or_none()
    if not existing:
        db.add(UserRole(user_id=user_id, role_id=role.role_id))
        print(f"    → gán role {role_code.value}")


async def main():
    async with AsyncSessionLocal() as db:
        # Find faculty CNTT
        faculty = (await db.execute(select(Faculty).where(Faculty.faculty_code == "CNTT"))).scalar_one_or_none()
        if faculty is None:
            print("✗ Khoa CNTT chưa có. Chạy setup-dev.sh trước.")
            return
        print(f"Khoa CNTT id={faculty.faculty_id}")

        # 1. Organizer
        print("\n[1/2] Organizer (GV)")
        gv, created = await get_or_create_user(db, "gv@ptit.edu.vn", "GV. Nguyen Van A", "abc123")
        await assign_role(db, gv.user_id, RoleCode.ORGANIZER)
        if created:
            db.add(Organizer(user_id=gv.user_id, organization_name="Khoa CNTT", faculty_id=faculty.faculty_id))
            print(f"    → tạo organizer profile")

        # 2. HOD (BCN)
        print("\n[2/2] HOD (BCN)")
        bcn, created = await get_or_create_user(db, "bcn@ptit.edu.vn", "BCN. Tran Van B", "abc123")
        await assign_role(db, bcn.user_id, RoleCode.HOD)
        if created:
            db.add(DepartmentHead(
                user_id=bcn.user_id,
                faculty_id=faculty.faculty_id,
                title="Trưởng khoa",
                is_primary_approver=True,
            ))
            print(f"    → tạo department_head profile (Trưởng khoa CNTT)")

        await db.commit()

    await engine.dispose()
    print("\n✅ Seed test users OK")
    print("\nLogin credentials:")
    print("  GV  → gv@ptit.edu.vn  / abc123")
    print("  BCN → bcn@ptit.edu.vn / abc123")
    print("  SV  → b22dccn001@ptit.edu.vn / abc123 (cần register trước qua /api/auth/register)")


if __name__ == "__main__":
    asyncio.run(main())
