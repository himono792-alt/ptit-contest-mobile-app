"""Seed dữ liệu DEMO đầy đủ cho bản chạy offline / clone-and-run (Docker).

Mục tiêu: sau `docker compose up`, thầy/người chấm clone repo về là có ngay một
hệ thống ĐẦY DỮ LIỆU để xem trọn workflow — không phải tự tạo gì.

Script idempotent: chạy lại nhiều lần không nhân đôi dữ liệu (docker-entrypoint.sh
gọi mỗi lần boot). Muốn reset sạch: `docker compose down -v` rồi `up` lại.

Tạo:
  - 2 khoa: CNTT, ATTT
  - 3 sinh viên (login được ngay): b22dccn001..003@ptit.edu.vn
      → app_user + role STUDENT + student_directory + students profile
  - 3 nhân sự (gộp logic seed-test-users.py):
      GV/BTC  gv@ptit.edu.vn   [ORGANIZER + JUDGE]  + organizer/judge profile
      BCN/HOD bcn@ptit.edu.vn  [HOD]                + department_head (primary approver)
      ADMIN   admin@ptit.edu.vn [ADMIN]
  - Cuộc thi A (INDIVIDUAL, ONGOING): 1 vòng chung kết + 2 lượt đăng ký (APPROVED)
      + 1 bài nộp đã khoá → GV có bài để chấm, SV thấy cuộc thi đang diễn ra.
  - Cuộc thi B (TEAM, PROPOSED): 1 vòng + 1 đề nghị phê duyệt QĐ1 (PENDING)
      → BCN có 1 mục trong hàng đợi duyệt → demo workflow 2 cấp BTC↔BCN.
  - Thông báo cho SV (mở đăng ký) và BCN (chờ duyệt).

Mật khẩu mọi tài khoản = env DEMO_PASSWORD (compose set 'abc123'); fallback 'abc123'
nếu chưa set để demo không bao giờ kẹt.

Chạy thủ công (ngoài Docker):
    cd backend
    DEMO_PASSWORD=abc123 python scripts/seed-demo.py
"""
import asyncio
import os
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Cho phép import app.* khi chạy script trực tiếp
sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select

from app.database import AsyncSessionLocal, engine
from app.models.contest import Contest, ContestOrganizer, ContestRound
from app.models.entry import ContestEntry
from app.models.enums import (
    ApprovalStatus,
    ApprovalStep,
    ApprovalTarget,
    ContestStatus,
    DeliveryMode,
    EntryType,
    NotificationScope,
    ParticipantStatus,
    RegistrationStatus,
    RoleCode,
    RoundType,
    SubmissionStatus,
)
from app.models.identity import AppUser, Role, UserRole
from app.models.master_data import (
    DepartmentHead,
    Faculty,
    Judge,
    Organizer,
    Student,
    StudentDirectory,
)
from app.models.notification import Notification, NotificationRecipient
from app.models.submission import Submission, SubmissionVersion
from app.models.workflow import WorkflowApproval
from app.security import hash_password

# Fallback 'abc123' để demo offline không bao giờ kẹt vì thiếu env.
DEMO_PASSWORD = os.environ.get("DEMO_PASSWORD") or "abc123"

NOW = datetime.now(timezone.utc)


def days(n: int) -> datetime:
    return NOW + timedelta(days=n)


def hours(n: int) -> datetime:
    return NOW + timedelta(hours=n)


# ----------------------------------------------------------------------------
# Helpers (get_or_create) — idempotent
# ----------------------------------------------------------------------------
async def get_or_create_user(db, email, full_name, password):
    existing = (
        await db.execute(select(AppUser).where(AppUser.email == email))
    ).scalar_one_or_none()
    if existing:
        return existing, False
    user = AppUser(
        email=email,
        password_hash=hash_password(password),
        full_name=full_name,
    )
    db.add(user)
    await db.flush()
    print(f"  + user {email} (id={user.user_id})")
    return user, True


async def assign_role(db, user_id, role_code):
    role = (
        await db.execute(select(Role).where(Role.role_code == role_code))
    ).scalar_one()
    existing = (
        await db.execute(
            select(UserRole).where(
                UserRole.user_id == user_id, UserRole.role_id == role.role_id
            )
        )
    ).scalar_one_or_none()
    if not existing:
        db.add(UserRole(user_id=user_id, role_id=role.role_id))
        print(f"    → role {role_code.value}")


async def get_or_create_faculty(db, code, name):
    fac = (
        await db.execute(select(Faculty).where(Faculty.faculty_code == code))
    ).scalar_one_or_none()
    if fac:
        return fac
    fac = Faculty(faculty_code=code, faculty_name=name)
    db.add(fac)
    await db.flush()
    print(f"  + faculty {code} (id={fac.faculty_id})")
    return fac


async def get_or_create_student(db, code, email, full_name, faculty, password):
    """Tạo app_user + STUDENT role + student_directory + students profile."""
    user, _ = await get_or_create_user(db, email, full_name, password)
    await assign_role(db, user.user_id, RoleCode.STUDENT)

    directory = (
        await db.execute(
            select(StudentDirectory).where(StudentDirectory.student_code == code)
        )
    ).scalar_one_or_none()
    if directory is None:
        directory = StudentDirectory(
            student_code=code,
            ptit_email=email,
            full_name=full_name,
            faculty_id=faculty.faculty_id,
            is_active=True,
        )
        db.add(directory)
        await db.flush()

    student = (
        await db.execute(select(Student).where(Student.user_id == user.user_id))
    ).scalar_one_or_none()
    if student is None:
        student = Student(user_id=user.user_id, directory_id=directory.directory_id)
        db.add(student)
        await db.flush()
        print(f"    → student profile {code} (student_id={student.student_id})")
    return student, user


# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
async def main():
    async with AsyncSessionLocal() as db:
        print("=== Seed demo data ===")

        # --- Khoa ---
        cntt = await get_or_create_faculty(db, "CNTT", "Công nghệ thông tin")
        await get_or_create_faculty(db, "ATTT", "An toàn thông tin")

        # --- Sinh viên ---
        print("\n[Sinh viên]")
        st1, _ = await get_or_create_student(
            db, "B22DCCN001", "b22dccn001@ptit.edu.vn", "Nguyễn Văn An", cntt, DEMO_PASSWORD
        )
        st2, _ = await get_or_create_student(
            db, "B22DCCN002", "b22dccn002@ptit.edu.vn", "Trần Thị Bình", cntt, DEMO_PASSWORD
        )
        await get_or_create_student(
            db, "B22DCCN003", "b22dccn003@ptit.edu.vn", "Lê Văn Cường", cntt, DEMO_PASSWORD
        )

        # --- GV/BTC ---
        print("\n[GV/BTC]")
        gv, gv_created = await get_or_create_user(
            db, "gv@ptit.edu.vn", "GV. Nguyễn Văn A", DEMO_PASSWORD
        )
        await assign_role(db, gv.user_id, RoleCode.ORGANIZER)
        await assign_role(db, gv.user_id, RoleCode.JUDGE)
        organizer = (
            await db.execute(select(Organizer).where(Organizer.user_id == gv.user_id))
        ).scalar_one_or_none()
        if organizer is None:
            organizer = Organizer(
                user_id=gv.user_id,
                organization_name="Khoa CNTT",
                faculty_id=cntt.faculty_id,
            )
            db.add(organizer)
            await db.flush()
            print("    → organizer profile")
        judge = (
            await db.execute(select(Judge).where(Judge.user_id == gv.user_id))
        ).scalar_one_or_none()
        if judge is None:
            db.add(Judge(user_id=gv.user_id, expertise="Lập trình, Thuật toán"))
            print("    → judge profile")

        # --- BCN/HOD ---
        print("\n[BCN/HOD]")
        bcn, _ = await get_or_create_user(
            db, "bcn@ptit.edu.vn", "BCN. Trần Văn B", DEMO_PASSWORD
        )
        await assign_role(db, bcn.user_id, RoleCode.HOD)
        dept_head = (
            await db.execute(
                select(DepartmentHead).where(DepartmentHead.user_id == bcn.user_id)
            )
        ).scalar_one_or_none()
        if dept_head is None:
            db.add(
                DepartmentHead(
                    user_id=bcn.user_id,
                    faculty_id=cntt.faculty_id,
                    title="Trưởng khoa",
                    is_primary_approver=True,
                )
            )
            print("    → department_head (Trưởng khoa CNTT)")

        # --- ADMIN ---
        print("\n[ADMIN]")
        admin, _ = await get_or_create_user(
            db, "admin@ptit.edu.vn", "Quản trị hệ thống", DEMO_PASSWORD
        )
        await assign_role(db, admin.user_id, RoleCode.ADMIN)

        # --- Dữ liệu cuộc thi (guard idempotent theo slug A) ---
        slug_a = "lap-trinh-thuat-toan-2026"
        existed = (
            await db.execute(select(Contest).where(Contest.slug == slug_a))
        ).scalar_one_or_none()
        if existed:
            print("\n[Cuộc thi] đã có — bỏ qua tạo demo data.")
        else:
            print("\n[Cuộc thi]")
            # ===== Contest A: INDIVIDUAL, ONGOING =====
            contest_a = Contest(
                slug=slug_a,
                title="Cuộc thi Lập trình thuật toán 2026",
                description="Sân chơi học thuật cho sinh viên đam mê thuật toán và lập trình thi đấu.",
                rules_text="Mỗi thí sinh nộp 1 bài. Chấm theo số test pass và thời gian chạy.",
                award_text="Giải Nhất 5.000.000đ, Nhì 3.000.000đ, Ba 2.000.000đ.",
                delivery_mode=DeliveryMode.ONLINE,
                participation_mode=EntryType.INDIVIDUAL,
                requires_submission=True,
                is_public=True,
                registration_open_at=days(-10),
                registration_close_at=days(-2),
                start_at=days(-1),
                end_at=days(7),
                location_text="Trực tuyến",
                status=ContestStatus.ONGOING,
                proposed_by=gv.user_id,
                host_faculty_id=cntt.faculty_id,
                created_by=gv.user_id,
            )
            db.add(contest_a)
            await db.flush()
            db.add(
                ContestOrganizer(
                    contest_id=contest_a.contest_id, organizer_id=organizer.organizer_id
                )
            )
            round_a = ContestRound(
                contest_id=contest_a.contest_id,
                round_no=1,
                round_name="Vòng Chung kết",
                round_type=RoundType.FINAL,
                description="Vòng thi duy nhất, nộp bài trực tuyến.",
                start_at=days(-1),
                end_at=days(7),
                submission_open_at=days(-1),
                submission_close_at=days(3),
                judging_open_at=days(3),
                judging_close_at=days(6),
                is_elimination_round=False,
            )
            db.add(round_a)
            await db.flush()

            # 2 lượt đăng ký cá nhân, đã duyệt
            entry1 = ContestEntry(
                contest_id=contest_a.contest_id,
                entry_type=EntryType.INDIVIDUAL,
                student_id=st1.student_id,
                anonymous_code="TS-001",
                registration_status=RegistrationStatus.APPROVED,
                participant_status=ParticipantStatus.SUBMITTED,
                approved_by=gv.user_id,
                approved_at=days(-2),
            )
            entry2 = ContestEntry(
                contest_id=contest_a.contest_id,
                entry_type=EntryType.INDIVIDUAL,
                student_id=st2.student_id,
                anonymous_code="TS-002",
                registration_status=RegistrationStatus.APPROVED,
                participant_status=ParticipantStatus.REGISTERED,
                approved_by=gv.user_id,
                approved_at=days(-2),
            )
            db.add_all([entry1, entry2])
            await db.flush()

            # 1 bài nộp đã khoá cho entry1 → GV có bài để chấm
            sub = Submission(
                round_id=round_a.round_id,
                entry_id=entry1.entry_id,
                current_version_no=1,
                status=SubmissionStatus.LOCKED,
                is_locked=True,
                submitted_at=hours(-12),
                created_by=st1.user_id,
                updated_by=st1.user_id,
            )
            db.add(sub)
            await db.flush()
            db.add(
                SubmissionVersion(
                    submission_id=sub.submission_id,
                    version_no=1,
                    title="Lời giải bài thuật toán — Nguyễn Văn An",
                    description="Giải bằng quy hoạch động, độ phức tạp O(n log n).",
                    external_link="https://github.com/demo/ptit-contest-solution",
                    text_answer="Trình bày ý tưởng, độ phức tạp và mã nguồn kèm theo.",
                    submitted_by=st1.user_id,
                    submitted_at=hours(-12),
                    note="Bài nộp demo.",
                )
            )

            # ===== Contest B: TEAM, PROPOSED → hàng đợi duyệt BCN =====
            contest_b = Contest(
                slug="hackathon-sang-tao-2026",
                title="Hackathon Sáng tạo 2026",
                description="Cuộc thi lập trình theo đội, xây dựng sản phẩm trong 48 giờ.",
                rules_text="Đội 2–4 thành viên. Nộp sản phẩm + slide thuyết trình.",
                award_text="Giải Nhất 10.000.000đ và suất thực tập.",
                delivery_mode=DeliveryMode.OFFLINE,
                participation_mode=EntryType.TEAM,
                team_min_members=2,
                team_max_members=4,
                requires_submission=True,
                is_public=False,
                registration_open_at=days(1),
                registration_close_at=days(10),
                start_at=days(14),
                end_at=days(20),
                location_text="Hội trường A1, PTIT",
                status=ContestStatus.PROPOSED,
                proposed_by=gv.user_id,
                host_faculty_id=cntt.faculty_id,
                created_by=gv.user_id,
            )
            db.add(contest_b)
            await db.flush()
            db.add(
                ContestOrganizer(
                    contest_id=contest_b.contest_id, organizer_id=organizer.organizer_id
                )
            )
            db.add(
                ContestRound(
                    contest_id=contest_b.contest_id,
                    round_no=1,
                    round_name="Vòng Chung kết",
                    round_type=RoundType.FINAL,
                    start_at=days(14),
                    end_at=days(20),
                    is_elimination_round=False,
                )
            )
            # Đề nghị phê duyệt QĐ1 (PENDING) → BCN thấy trong hàng đợi
            db.add(
                WorkflowApproval(
                    target_type=ApprovalTarget.CONTEST_PROPOSAL,
                    contest_id=contest_b.contest_id,
                    step=ApprovalStep.BCN_QD1,
                    status=ApprovalStatus.PENDING,
                    revision_round=1,
                    submitted_by=gv.user_id,
                    submitted_at=hours(-6),
                    submission_note="Kính đề nghị Ban Chủ nhiệm khoa phê duyệt đề xuất tổ chức cuộc thi.",
                )
            )

            # --- Thông báo ---
            print("[Thông báo]")
            notif_sv = Notification(
                scope=NotificationScope.CONTEST,
                contest_id=contest_a.contest_id,
                title="Mở đăng ký: Cuộc thi Lập trình thuật toán 2026",
                message="Cuộc thi đã bắt đầu. Xem chi tiết và theo dõi kết quả của bạn.",
                target_route=f"/contests/{contest_a.slug}",
                created_by=gv.user_id,
                published_at=days(-2),
            )
            db.add(notif_sv)
            await db.flush()
            for st_user_id in (st1.user_id, st2.user_id):
                db.add(
                    NotificationRecipient(
                        notification_id=notif_sv.notification_id, user_id=st_user_id
                    )
                )

            notif_bcn = Notification(
                scope=NotificationScope.CONTEST,
                contest_id=contest_b.contest_id,
                title="Đề xuất cuộc thi chờ phê duyệt (QĐ1)",
                message="Hackathon Sáng tạo 2026 đang chờ Ban Chủ nhiệm khoa phê duyệt.",
                target_route="/bcn/approvals",
                created_by=gv.user_id,
                published_at=hours(-6),
            )
            db.add(notif_bcn)
            await db.flush()
            db.add(
                NotificationRecipient(
                    notification_id=notif_bcn.notification_id, user_id=bcn.user_id
                )
            )

            print("    → 2 cuộc thi + vòng + đăng ký + bài nộp + đề nghị QĐ1 + thông báo")

        await db.commit()

    await engine.dispose()

    print("\n✅ Seed demo OK")
    print("\nĐăng nhập (mật khẩu = '%s'):" % DEMO_PASSWORD)
    print("  SV     → b22dccn001@ptit.edu.vn  (và 002, 003)")
    print("  GV/BTC → gv@ptit.edu.vn          [ORGANIZER + JUDGE]")
    print("  BCN    → bcn@ptit.edu.vn         [HOD] — có 1 mục chờ duyệt QĐ1")
    print("  ADMIN  → admin@ptit.edu.vn       [ADMIN]")


if __name__ == "__main__":
    asyncio.run(main())
