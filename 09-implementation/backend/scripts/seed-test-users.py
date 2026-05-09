"""Seed thêm test users để test E2E workflow QĐ1.

Tạo:
  - 1 GV/BTC    (GV. Nguyen Van A)  email gv@ptit.edu.vn    password abc123
                → roles ORGANIZER + JUDGE (Sprint 15: KHÔNG có ADMIN, BTC thuần)
  - 1 HOD       (BCN. Tran Van B)   email bcn@ptit.edu.vn   password abc123
                → role HOD + gắn faculty_id của khoa CNTT
  - 1 ADMIN     (Quản trị hệ thống) email admin@ptit.edu.vn password abc123
                → chỉ assign role ADMIN, không cần profile riêng (Sprint 7 2026-05-07)

Sprint 15 (2026-05-08): bỏ ADMIN role khỏi gv@ — trước đây multi-role
[ADMIN,JUDGE,ORGANIZER] làm BTC thấy toàn bộ admin sidebar (Tài khoản, Configs,
Audit log...) gây confused phân quyền. Strict separation:
- GV/BTC → Cuộc thi + Chấm bài (KHÔNG admin features)
- BCN → Phê duyệt + Giám sát
- Admin → Tài khoản + Hệ thống (KHÔNG có Cuộc thi của tôi)

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


async def remove_role(db, user_id, role_code):
    """Sprint 15 (2026-05-08): xóa role nếu user đang có.

    Dùng cho cleanup gv@ptit.edu.vn — trước đây có ADMIN role gây confused
    phân quyền (BTC thấy toàn bộ admin sidebar).
    """
    role = (await db.execute(select(Role).where(Role.role_code == role_code))).scalar_one()
    existing = (await db.execute(
        select(UserRole).where(
            UserRole.user_id == user_id, UserRole.role_id == role.role_id
        )
    )).scalar_one_or_none()
    if existing:
        await db.delete(existing)
        print(f"    − gỡ role {role_code.value} (cleanup)")


async def main():
    async with AsyncSessionLocal() as db:
        # Find faculty CNTT
        faculty = (await db.execute(select(Faculty).where(Faculty.faculty_code == "CNTT"))).scalar_one_or_none()
        if faculty is None:
            print("✗ Khoa CNTT chưa có. Chạy setup-dev.sh trước.")
            return
        print(f"Khoa CNTT id={faculty.faculty_id}")

        # 1. GV/BTC — Sprint 15: ORGANIZER + JUDGE thuần, KHÔNG có ADMIN.
        print("\n[1/3] GV/BTC (Organizer + Judge)")
        gv, created = await get_or_create_user(db, "gv@ptit.edu.vn", "GV. Nguyen Van A", "abc123")
        await assign_role(db, gv.user_id, RoleCode.ORGANIZER)
        await assign_role(db, gv.user_id, RoleCode.JUDGE)
        # Sprint 15 cleanup: nếu gv@ đang có ADMIN role (legacy seed) → gỡ.
        await remove_role(db, gv.user_id, RoleCode.ADMIN)
        if created:
            db.add(Organizer(user_id=gv.user_id, organization_name="Khoa CNTT", faculty_id=faculty.faculty_id))
            print(f"    → tạo organizer profile")

        # 2. HOD (BCN)
        print("\n[2/3] HOD (BCN)")
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

        # 3. ADMIN (Sprint 7 2026-05-07): để test toggle dark mode trên admin shell.
        # Admin không cần profile riêng — chỉ AppUser + UserRole(ADMIN).
        print("\n[3/3] ADMIN (Quản trị hệ thống)")
        admin, _ = await get_or_create_user(db, "admin@ptit.edu.vn", "Quản trị hệ thống", "abc123")
        await assign_role(db, admin.user_id, RoleCode.ADMIN)

        await db.commit()

    await engine.dispose()
    print("\n✅ Seed test users OK")
    print("\nLogin credentials (Sprint 15 strict roles):")
    print("  GV/BTC → gv@ptit.edu.vn     / abc123  [ORGANIZER + JUDGE]")
    print("  BCN    → bcn@ptit.edu.vn    / abc123  [HOD]")
    print("  ADMIN  → admin@ptit.edu.vn  / abc123  [ADMIN]")
    print("  SV     → b22dccn001@ptit.edu.vn / abc123 (cần register trước qua /api/auth/register)")


if __name__ == "__main__":
    asyncio.run(main())
