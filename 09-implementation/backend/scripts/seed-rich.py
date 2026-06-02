"""Seed DỮ LIỆU PHONG PHÚ — bổ sung trên nền seed-demo.py.

Thêm vào:
  - 3 khoa thêm (DTVT, QLKT, KTDT) + 6 ngành + 8 lớp học
  - 14 sinh viên mới (rải khắp các khoa)
  - 2 giám khảo thêm (gv2@, gv3@)
  - 3 cuộc thi FINISHED với dữ liệu đầy đủ:
      · "Lập trình Web 2025"       — INDIVIDUAL, 8 thí sinh, đã có kết quả + cert
      · "Olympic Toán Tin 2024"    — INDIVIDUAL, 6 thí sinh, đã có kết quả + cert
      · "Hackathon IoT Kết Nối"    — TEAM (4 đội × 3 SV), FINISHED, cert đội
  - 1 cuộc thi PUBLISHED/REG_OPEN sắp tới (để SV thấy danh sách phong phú)
  - round_score_criteria + judge_assignments + scores → round_results → contest_results
  - certificate_templates + issued_certificates (top 3 mỗi cuộc thi)
  - faculty_cert_templates × 3 (màn hình BCN)
  - ContestReview × 10 (đánh giá sao từ SV)
  - Questions + QuestionAnswers cho Contest A hiện tại
  - Articles × 4 (tin tức / thông báo)
  - AuditLog × 20 (lịch sử hoạt động)

Chạy: cd 09-implementation/backend && python scripts/seed-rich.py
Idempotent: guard bằng slug / email / unique key.
"""
import asyncio
import os
import secrets
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from sqlalchemy import select, text

from app.database import AsyncSessionLocal, engine
from app.models.certificate import CertificateTemplate, FacultyCertTemplate, IssuedCertificate
from app.models.contest import Contest, ContestJudge, ContestOrganizer, ContestRound
from app.models.entry import ContestEntry, Team, TeamMember
from app.models.enums import (
    ApprovalStatus,
    ContestStatus,
    DeliveryMode,
    EntryType,
    NotificationScope,
    ParticipantStatus,
    QuestionStatus,
    RegistrationStatus,
    RoundType,
    SubmissionStatus,
)
from app.models.identity import AppUser, Role, UserRole
from app.models.judging import (
    ContestResult,
    JudgeAssignment,
    RoundResult,
    RoundScoreCriterion,
    Score,
)
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
from app.models.notification import Article, Notification, NotificationRecipient, Question, QuestionAnswer
from app.models.review import ContestReview
from app.models.submission import Submission, SubmissionVersion
from app.models.system import AuditLog, SystemConfig
from app.security import hash_password

DEMO_PASSWORD = os.environ.get("DEMO_PASSWORD") or "abc123"
NOW = datetime.now(timezone.utc)


def ago(days=0, hours=0) -> datetime:
    return NOW - timedelta(days=days, hours=hours)


def later(days=0, hours=0) -> datetime:
    return NOW + timedelta(days=days, hours=hours)


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

async def goc(db, model, **kwargs):
    """get_or_create bằng toàn bộ kwargs làm filter."""
    obj = (await db.execute(select(model).filter_by(**kwargs))).scalar_one_or_none()
    if obj:
        return obj, False
    obj = model(**kwargs)
    db.add(obj)
    await db.flush()
    return obj, True


async def get_user(db, email) -> AppUser | None:
    return (await db.execute(select(AppUser).where(AppUser.email == email))).scalar_one_or_none()


async def get_or_create_user(db, email, full_name, password=DEMO_PASSWORD):
    u = await get_user(db, email)
    if u:
        return u, False
    u = AppUser(email=email, password_hash=hash_password(password), full_name=full_name)
    db.add(u)
    await db.flush()
    return u, True


async def assign_role(db, user_id, role_code):
    role = (await db.execute(select(Role).where(Role.role_code == role_code))).scalar_one()
    exists = (await db.execute(
        select(UserRole).where(UserRole.user_id == user_id, UserRole.role_id == role.role_id)
    )).scalar_one_or_none()
    if not exists:
        db.add(UserRole(user_id=user_id, role_id=role.role_id))


async def get_or_create_faculty(db, code, name):
    f = (await db.execute(select(Faculty).where(Faculty.faculty_code == code))).scalar_one_or_none()
    if f:
        return f
    f = Faculty(faculty_code=code, faculty_name=name)
    db.add(f)
    await db.flush()
    return f


async def get_or_create_student(db, code, email, full_name, faculty, major=None, cls=None):
    u, _ = await get_or_create_user(db, email, full_name)
    await assign_role(db, u.user_id, "STUDENT")

    d = (await db.execute(select(StudentDirectory).where(StudentDirectory.student_code == code))).scalar_one_or_none()
    if not d:
        d = StudentDirectory(
            student_code=code, ptit_email=email, full_name=full_name,
            faculty_id=faculty.faculty_id,
            major_id=major.major_id if major else None,
            class_id=cls.class_id if cls else None,
            is_active=True,
        )
        db.add(d)
        await db.flush()

    s = (await db.execute(select(Student).where(Student.user_id == u.user_id))).scalar_one_or_none()
    if not s:
        s = Student(user_id=u.user_id, directory_id=d.directory_id)
        db.add(s)
        await db.flush()
    return s, u


async def get_or_create_judge(db, email, full_name, expertise, faculty):
    u, _ = await get_or_create_user(db, email, full_name)
    await assign_role(db, u.user_id, "JUDGE")
    j = (await db.execute(select(Judge).where(Judge.user_id == u.user_id))).scalar_one_or_none()
    if not j:
        j = Judge(user_id=u.user_id, expertise=expertise)
        db.add(j)
        await db.flush()

    org = (await db.execute(select(Organizer).where(Organizer.user_id == u.user_id))).scalar_one_or_none()
    if not org:
        org = Organizer(user_id=u.user_id, organization_name=f"Khoa {faculty.faculty_code}", faculty_id=faculty.faculty_id)
        db.add(org)
        await db.flush()
        await assign_role(db, u.user_id, "ORGANIZER")
    return j, u


# ─────────────────────────────────────────────────────────────────────────────
# Core: tạo 1 cuộc thi FINISHED với đầy đủ dữ liệu
# ─────────────────────────────────────────────────────────────────────────────

async def create_finished_individual_contest(
    db, slug, title, description, award_text, faculty,
    organizer, judges: list,
    students: list,           # list of (student, user) tuples
    criteria: list,           # list of (name, max_score, weight)
    scores_matrix: list,      # list of list of scores [entry_idx][criterion_idx]
    start_ago_days: int,
    end_ago_days: int,
    gv_user,
):
    """Tạo 1 cuộc thi cá nhân đã kết thúc, có đầy đủ: entry, submission,
    judge_assignment, scores, round_result, contest_result, cert."""

    # Guard
    existing = (await db.execute(select(Contest).where(Contest.slug == slug))).scalar_one_or_none()
    if existing:
        print(f"  [skip] contest '{slug}' đã tồn tại")
        return existing

    print(f"\n  + Contest: {title}")
    c = Contest(
        slug=slug,
        title=title,
        description=description,
        rules_text="Mỗi thí sinh nộp 1 bài. Ban giám khảo chấm theo rubric.",
        award_text=award_text,
        delivery_mode=DeliveryMode.ONLINE,
        participation_mode=EntryType.INDIVIDUAL,
        requires_submission=True,
        is_public=True,
        registration_open_at=ago(days=start_ago_days + 20),
        registration_close_at=ago(days=start_ago_days + 5),
        start_at=ago(days=start_ago_days),
        end_at=ago(days=end_ago_days),
        location_text="Trực tuyến",
        status=ContestStatus.FINISHED,
        proposed_by=gv_user.user_id,
        host_faculty_id=faculty.faculty_id,
        created_by=gv_user.user_id,
    )
    db.add(c)
    await db.flush()

    # Organizer + Judges gán vào contest
    db.add(ContestOrganizer(contest_id=c.contest_id, organizer_id=organizer.organizer_id))
    for j in judges:
        exists_cj = (await db.execute(
            select(ContestJudge).where(ContestJudge.contest_id == c.contest_id, ContestJudge.judge_id == j.judge_id)
        )).scalar_one_or_none()
        if not exists_cj:
            db.add(ContestJudge(contest_id=c.contest_id, judge_id=j.judge_id, assigned_by=gv_user.user_id))

    # Round
    r = ContestRound(
        contest_id=c.contest_id,
        round_no=1,
        round_name="Vòng Chung kết",
        round_type=RoundType.FINAL,
        start_at=ago(days=start_ago_days),
        end_at=ago(days=end_ago_days + 2),
        submission_open_at=ago(days=start_ago_days),
        submission_close_at=ago(days=end_ago_days + 5),
        judging_open_at=ago(days=end_ago_days + 5),
        judging_close_at=ago(days=end_ago_days + 1),
        is_elimination_round=False,
    )
    db.add(r)
    await db.flush()

    # Criteria
    crit_objs = []
    for idx, (cname, cmax, cweight) in enumerate(criteria, 1):
        cr = RoundScoreCriterion(
            round_id=r.round_id,
            criterion_name=cname,
            max_score=cmax,
            weight_percent=cweight,
            display_order=idx,
        )
        db.add(cr)
        crit_objs.append(cr)
    await db.flush()

    # Cert template
    cert_tmpl = CertificateTemplate(
        contest_id=c.contest_id,
        template_name=f"Chứng nhận — {title}",
        html_template=f"""<div style="font-family:serif;text-align:center;padding:40px;border:4px double #8B0000;">
<h1 style="color:#8B0000">CHỨNG NHẬN THÀNH TÍCH</h1>
<p>Trân trọng chứng nhận</p>
<h2>{{{{full_name}}}}</h2>
<p>đã đạt <strong>{{{{award_title}}}}</strong></p>
<p>trong cuộc thi <em>{title}</em></p>
<p>Tổ chức tại Học viện Công nghệ Bưu chính Viễn thông</p>
<p style="margin-top:30px">Hà Nội, {ago(days=end_ago_days).strftime('%d/%m/%Y')}</p>
</div>""",
        is_active=True,
        created_by=gv_user.user_id,
        approved_by=gv_user.user_id,
        approved_at=ago(days=end_ago_days),
    )
    db.add(cert_tmpl)
    await db.flush()

    # Entries, submissions, scores, results
    award_titles = ["Giải Nhất", "Giải Nhì", "Giải Ba", "Giải Khuyến khích"]
    entries = []
    for i, (st, _) in enumerate(students):
        entry = ContestEntry(
            contest_id=c.contest_id,
            entry_type=EntryType.INDIVIDUAL,
            student_id=st.student_id,
            anonymous_code=f"{slug[:4].upper()}-{i+1:03d}",
            registration_status=RegistrationStatus.APPROVED,
            participant_status=ParticipantStatus.COMPLETED,
            approved_by=gv_user.user_id,
            approved_at=ago(days=start_ago_days + 4),
        )
        db.add(entry)
        entries.append(entry)
    await db.flush()

    # Submissions
    sub_objs = []
    for i, (entry, (st, st_user)) in enumerate(zip(entries, students)):
        sub = Submission(
            round_id=r.round_id,
            entry_id=entry.entry_id,
            current_version_no=1,
            status=SubmissionStatus.LOCKED,
            is_locked=True,
            submitted_at=ago(days=end_ago_days + 6, hours=i),
            created_by=st_user.user_id,
            updated_by=st_user.user_id,
        )
        db.add(sub)
        sub_objs.append(sub)
    await db.flush()

    for sub, (st, st_user) in zip(sub_objs, students):
        db.add(SubmissionVersion(
            submission_id=sub.submission_id,
            version_no=1,
            title=f"Bài nộp của {st_user.full_name}",
            description="Bài làm cuối kỳ.",
            text_answer="Nội dung bài làm đã được nộp và khoá.",
            submitted_by=st_user.user_id,
            submitted_at=sub.submitted_at,
        ))
    await db.flush()

    # Judge assignments + Scores
    j0 = judges[0]
    assign_objs = []
    for entry, sub in zip(entries, sub_objs):
        ja = JudgeAssignment(
            round_id=r.round_id,
            entry_id=entry.entry_id,
            submission_id=sub.submission_id,
            judge_id=j0.judge_id,
            assigned_by=gv_user.user_id,
            can_view_identity=False,
        )
        db.add(ja)
        assign_objs.append(ja)
    await db.flush()

    for e_idx, (ja, entry) in enumerate(zip(assign_objs, entries)):
        for c_idx, (crit, sv) in enumerate(zip(crit_objs, scores_matrix[e_idx])):
            db.add(Score(
                assignment_id=ja.assignment_id,
                criterion_id=crit.criterion_id,
                score_value=sv,
                comment_text="Đã chấm.",
                scored_at=ago(days=end_ago_days + 2, hours=e_idx),
            ))
    await db.flush()

    # Round results
    total_scores = [sum(row) for row in scores_matrix]
    ranked = sorted(enumerate(total_scores), key=lambda x: x[1], reverse=True)
    rr_map = {}
    for rank, (e_idx, total) in enumerate(ranked, 1):
        entry = entries[e_idx]
        max_total = sum(cm for _, cm, _ in criteria)
        rr = RoundResult(
            round_id=r.round_id,
            entry_id=entry.entry_id,
            total_score=round(total, 2),
            average_score=round(total / len(judges), 2),
            rank_no=rank,
            is_passed=True,
            published_at=ago(days=end_ago_days),
            generated_by=gv_user.user_id,
        )
        db.add(rr)
        rr_map[e_idx] = (rank, total)
    await db.flush()

    # Contest results + certificates
    for e_idx, (rank, total) in rr_map.items():
        award = award_titles[rank - 1] if rank <= len(award_titles) else None
        cr = ContestResult(
            contest_id=c.contest_id,
            entry_id=entries[e_idx].entry_id,
            final_score=round(total, 2),
            rank_no=rank,
            award_title=award,
            bcn_approval_status=ApprovalStatus.APPROVED,
            published_at=ago(days=end_ago_days),
            generated_by=gv_user.user_id,
        )
        db.add(cr)
        await db.flush()

        # Chỉ cấp cert cho top 3
        if rank <= 3:
            db.add(IssuedCertificate(
                contest_result_id=cr.contest_result_id,
                template_id=cert_tmpl.template_id,
                qr_code=secrets.token_hex(16),
                pdf_url=f"https://r2.ptit-contest.example/certs/{c.slug}/{secrets.token_hex(8)}.pdf",
                issued_by=gv_user.user_id,
                issued_at=ago(days=end_ago_days - 1),
            ))

    await db.flush()
    print(f"    → {len(entries)} thí sinh, {len(crit_objs)} tiêu chí, kết quả + cert top 3")
    return c


# ─────────────────────────────────────────────────────────────────────────────
# Tạo 1 cuộc thi TEAM đã kết thúc
# ─────────────────────────────────────────────────────────────────────────────

async def create_finished_team_contest(
    db, slug, title, faculty, organizer, judges, teams_data, criteria, gv_user
):
    existing = (await db.execute(select(Contest).where(Contest.slug == slug))).scalar_one_or_none()
    if existing:
        print(f"  [skip] contest '{slug}' đã tồn tại")
        return existing

    print(f"\n  + Team Contest: {title}")
    c = Contest(
        slug=slug,
        title=title,
        description="Cuộc thi lập trình theo đội, phát triển sản phẩm IoT hoàn chỉnh.",
        rules_text="Mỗi đội 2–4 thành viên. Nộp sản phẩm + slide. Chấm theo rubric kỹ thuật + thuyết trình.",
        award_text="Giải Nhất: 15.000.000đ + cúp + chứng nhận. Nhì: 8.000.000đ. Ba: 5.000.000đ.",
        delivery_mode=DeliveryMode.OFFLINE,
        participation_mode=EntryType.TEAM,
        team_min_members=2,
        team_max_members=4,
        requires_submission=True,
        is_public=True,
        registration_open_at=ago(days=120),
        registration_close_at=ago(days=95),
        start_at=ago(days=90),
        end_at=ago(days=82),
        location_text="Hội trường A1, PTIT Hà Nội",
        status=ContestStatus.FINISHED,
        proposed_by=gv_user.user_id,
        host_faculty_id=faculty.faculty_id,
        created_by=gv_user.user_id,
    )
    db.add(c)
    await db.flush()

    db.add(ContestOrganizer(contest_id=c.contest_id, organizer_id=organizer.organizer_id))
    for j in judges:
        db.add(ContestJudge(contest_id=c.contest_id, judge_id=j.judge_id, assigned_by=gv_user.user_id))

    r = ContestRound(
        contest_id=c.contest_id,
        round_no=1,
        round_name="Vòng Demo & Chấm",
        round_type=RoundType.FINAL,
        start_at=ago(days=85),
        end_at=ago(days=83),
        is_elimination_round=False,
    )
    db.add(r)
    await db.flush()

    crit_objs = []
    for idx, (cname, cmax, cweight) in enumerate(criteria, 1):
        cr = RoundScoreCriterion(round_id=r.round_id, criterion_name=cname, max_score=cmax, weight_percent=cweight, display_order=idx)
        db.add(cr)
        crit_objs.append(cr)
    await db.flush()

    cert_tmpl = CertificateTemplate(
        contest_id=c.contest_id,
        template_name=f"Chứng nhận — {title}",
        html_template=f"<div style='font-family:serif;text-align:center;padding:40px'><h1>CHỨNG NHẬN ĐỘI</h1><p>{{{{team_name}}}}</p><p>{{{{award_title}}}}</p><p>{title}</p></div>",
        is_active=True,
        created_by=gv_user.user_id,
        approved_by=gv_user.user_id,
        approved_at=ago(days=82),
    )
    db.add(cert_tmpl)
    await db.flush()

    award_titles = ["Giải Nhất", "Giải Nhì", "Giải Ba", "Giải Khuyến khích"]
    entries = []
    all_scores = []

    for team_name, leader_st, members, score_rows in teams_data:
        # Create Team
        team = Team(
            contest_id=c.contest_id,
            team_name=team_name,
            leader_student_id=leader_st.student_id,
        )
        db.add(team)
        await db.flush()

        # Team members
        all_member_students = [leader_st] + members
        for mem in all_member_students:
            is_leader = (mem.student_id == leader_st.student_id)
            exists_tm = (await db.execute(
                select(TeamMember).where(TeamMember.team_id == team.team_id, TeamMember.student_id == mem.student_id)
            )).scalar_one_or_none()
            if not exists_tm:
                db.add(TeamMember(team_id=team.team_id, student_id=mem.student_id, is_leader=is_leader))

        # Entry for team — TEAM entries: student_id MUST be NULL (chk_entry_target)
        entry = ContestEntry(
            contest_id=c.contest_id,
            entry_type=EntryType.TEAM,
            student_id=None,
            team_id=team.team_id,
            anonymous_code=f"IOT-{len(entries)+1:03d}",
            registration_status=RegistrationStatus.APPROVED,
            participant_status=ParticipantStatus.COMPLETED,
            approved_by=gv_user.user_id,
            approved_at=ago(days=94),
        )
        db.add(entry)
        entries.append(entry)
        all_scores.append(score_rows)
    await db.flush()

    # Submissions + Judge assignments + Scores
    j0 = judges[0]
    for e_idx, (entry, score_rows) in enumerate(zip(entries, all_scores)):
        sub = Submission(
            round_id=r.round_id,
            entry_id=entry.entry_id,
            current_version_no=1,
            status=SubmissionStatus.LOCKED,
            is_locked=True,
            submitted_at=ago(days=84, hours=e_idx),
            created_by=gv_user.user_id,
            updated_by=gv_user.user_id,
        )
        db.add(sub)
        await db.flush()

        db.add(SubmissionVersion(
            submission_id=sub.submission_id,
            version_no=1,
            title=f"Demo sản phẩm — {teams_data[e_idx][0]}",
            description="Slide + demo thiết bị IoT.",
            text_answer="Sản phẩm demo tại hội trường.",
            submitted_by=gv_user.user_id,
            submitted_at=sub.submitted_at,
        ))

        ja = JudgeAssignment(
            round_id=r.round_id,
            entry_id=entry.entry_id,
            submission_id=sub.submission_id,
            judge_id=j0.judge_id,
            assigned_by=gv_user.user_id,
        )
        db.add(ja)
        await db.flush()

        total = 0
        for c_idx, (crit, sv) in enumerate(zip(crit_objs, score_rows)):
            db.add(Score(assignment_id=ja.assignment_id, criterion_id=crit.criterion_id,
                         score_value=sv, scored_at=ago(days=83, hours=e_idx)))
            total += sv

        await db.flush()

    # Round results + contest results + certs
    total_scores = [sum(row) for _, _, _, row in teams_data]
    ranked = sorted(enumerate(total_scores), key=lambda x: x[1], reverse=True)

    for rank, (e_idx, total) in enumerate(ranked, 1):
        db.add(RoundResult(
            round_id=r.round_id, entry_id=entries[e_idx].entry_id,
            total_score=round(total, 2), average_score=round(total, 2),
            rank_no=rank, is_passed=True,
            published_at=ago(days=82), generated_by=gv_user.user_id,
        ))
        award = award_titles[rank - 1] if rank <= len(award_titles) else None
        cr = ContestResult(
            contest_id=c.contest_id, entry_id=entries[e_idx].entry_id,
            final_score=round(total, 2), rank_no=rank, award_title=award,
            bcn_approval_status=ApprovalStatus.APPROVED,
            published_at=ago(days=82), generated_by=gv_user.user_id,
        )
        db.add(cr)
        await db.flush()

        if rank <= 3:
            db.add(IssuedCertificate(
                contest_result_id=cr.contest_result_id,
                template_id=cert_tmpl.template_id,
                qr_code=secrets.token_hex(16),
                pdf_url=f"https://r2.ptit-contest.example/certs/{c.slug}/{secrets.token_hex(8)}.pdf",
                issued_by=gv_user.user_id,
                issued_at=ago(days=81),
            ))
    await db.flush()
    print(f"    → {len(entries)} đội, kết quả + cert top 3")
    return c


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

async def main():
    async with AsyncSessionLocal() as db:
        print("=== Seed RICH data ===\n")

        # ── 1. Lấy GV/BCN/CNTT đã có từ seed-demo ──────────────────────────
        gv_user = await get_user(db, "gv@ptit.edu.vn")
        if not gv_user:
            print("❌ Chưa chạy seed-demo.py! Chạy seed-demo trước.")
            return
        organizer = (await db.execute(select(Organizer).where(Organizer.user_id == gv_user.user_id))).scalar_one()
        judge_gv = (await db.execute(select(Judge).where(Judge.user_id == gv_user.user_id))).scalar_one()

        cntt = (await db.execute(select(Faculty).where(Faculty.faculty_code == "CNTT"))).scalar_one()

        # ── 2. Khoa, ngành, lớp thêm ────────────────────────────────────────
        print("[Khoa / Ngành / Lớp]")
        dtvt = await get_or_create_faculty(db, "DTVT", "Điện tử Viễn thông")
        qlkt = await get_or_create_faculty(db, "QLKT", "Quản lý Kinh tế")
        ktdt = await get_or_create_faculty(db, "KTDT", "Kỹ thuật Điện tử")
        await db.flush()

        # Ngành
        majors_data = [
            ("CNTT_KT", "Kỹ thuật phần mềm", cntt),
            ("CNTT_AI", "Trí tuệ nhân tạo", cntt),
            ("DTVT_TT", "Truyền thông số", dtvt),
            ("DTVT_VT", "Viễn thông", dtvt),
            ("QLKT_QT", "Quản trị kinh doanh", qlkt),
            ("KTDT_VD", "Vi điện tử", ktdt),
        ]
        major_objs = {}
        for mcode, mname, mfac in majors_data:
            m = (await db.execute(select(Major).where(Major.major_code == mcode))).scalar_one_or_none()
            if not m:
                m = Major(major_code=mcode, major_name=mname, faculty_id=mfac.faculty_id)
                db.add(m)
                await db.flush()
            major_objs[mcode] = m

        # Lớp
        classes_data = [
            ("B22DCCN", "Lớp B22DCCN", cntt, "CNTT_KT"),
            ("B22DCAI", "Lớp B22DCAI", cntt, "CNTT_AI"),
            ("B22DCVT", "Lớp B22DCVT", dtvt, "DTVT_VT"),
            ("B22DCTM", "Lớp B22DCTM", dtvt, "DTVT_TT"),
            ("B22DCQT", "Lớp B22DCQT", qlkt, "QLKT_QT"),
            ("B22DCKD", "Lớp B22DCKD", qlkt, "QLKT_QT"),
            ("B22DCKT", "Lớp B22DCKT", ktdt, "KTDT_VD"),
            ("B21DCCN", "Lớp B21DCCN", cntt, "CNTT_KT"),
        ]
        class_objs = {}
        for ccode, cname, cfac, cmajor_code in classes_data:
            cls = (await db.execute(select(AcademicClass).where(AcademicClass.class_code == ccode))).scalar_one_or_none()
            if not cls:
                cls = AcademicClass(
                    class_code=ccode, class_name=cname,
                    faculty_id=cfac.faculty_id,
                    major_id=major_objs[cmajor_code].major_id,
                )
                db.add(cls)
                await db.flush()
            class_objs[ccode] = cls
        print(f"  → {len(majors_data)} ngành, {len(classes_data)} lớp")

        # ── 3. Sinh viên mới ─────────────────────────────────────────────────
        print("\n[Sinh viên mới]")
        sv_data = [
            # CNTT
            ("B22DCCN004", "b22dccn004@ptit.edu.vn", "Phạm Thị Dung",     cntt, "CNTT_KT", "B22DCCN"),
            ("B22DCCN005", "b22dccn005@ptit.edu.vn", "Hoàng Văn Em",       cntt, "CNTT_KT", "B22DCCN"),
            ("B22DCCN006", "b22dccn006@ptit.edu.vn", "Vũ Thị Phương",      cntt, "CNTT_AI", "B22DCAI"),
            ("B22DCCN007", "b22dccn007@ptit.edu.vn", "Đặng Minh Quân",     cntt, "CNTT_AI", "B22DCAI"),
            ("B21DCCN001", "b21dccn001@ptit.edu.vn", "Ngô Thanh Hùng",     cntt, "CNTT_KT", "B21DCCN"),
            ("B21DCCN002", "b21dccn002@ptit.edu.vn", "Đinh Thị Lan",       cntt, "CNTT_KT", "B21DCCN"),
            # DTVT
            ("B22DCVT001", "b22dcvt001@ptit.edu.vn", "Trương Văn Nam",     dtvt, "DTVT_VT", "B22DCVT"),
            ("B22DCVT002", "b22dcvt002@ptit.edu.vn", "Lý Thị Oanh",        dtvt, "DTVT_VT", "B22DCVT"),
            ("B22DCTM001", "b22dctm001@ptit.edu.vn", "Bùi Quốc Phong",     dtvt, "DTVT_TT", "B22DCTM"),
            # QLKT
            ("B22DCQT001", "b22dcqt001@ptit.edu.vn", "Mai Thị Quỳnh",      qlkt, "QLKT_QT", "B22DCQT"),
            ("B22DCKD001", "b22dckd001@ptit.edu.vn", "Cao Văn Sơn",        qlkt, "QLKT_QT", "B22DCKD"),
            # KTDT
            ("B22DCKT001", "b22dckt001@ptit.edu.vn", "Tô Minh Tuấn",       ktdt, "KTDT_VD", "B22DCKT"),
            ("B22DCKT002", "b22dckt002@ptit.edu.vn", "Phan Thị Uyên",      ktdt, "KTDT_VD", "B22DCKT"),
            ("B22DCKT003", "b22dckt003@ptit.edu.vn", "Lê Công Vinh",       ktdt, "KTDT_VD", "B22DCKT"),
        ]
        students = {}
        for code, email, name, fac, mcode, ccode in sv_data:
            s, u = await get_or_create_student(db, code, email, name, fac,
                                                major_objs.get(mcode), class_objs.get(ccode))
            students[code] = (s, u)
        await db.flush()
        print(f"  → {len(sv_data)} sinh viên")

        # Lấy cả 3 SV gốc từ seed-demo
        for code, email, name in [
            ("B22DCCN001", "b22dccn001@ptit.edu.vn", "Nguyễn Văn An"),
            ("B22DCCN002", "b22dccn002@ptit.edu.vn", "Trần Thị Bình"),
            ("B22DCCN003", "b22dccn003@ptit.edu.vn", "Lê Văn Cường"),
        ]:
            s, u = await get_or_create_student(db, code, email, name, cntt)
            students[code] = (s, u)

        # ── 4. Giám khảo mới ────────────────────────────────────────────────
        print("\n[Giám khảo mới]")
        judge2, gv2_user = await get_or_create_judge(
            db, "gv2@ptit.edu.vn", "GV. Lê Thị Hoa", "Thiết kế web, UI/UX", cntt)
        judge3, gv3_user = await get_or_create_judge(
            db, "gv3@ptit.edu.vn", "GV. Phạm Văn Khánh", "IoT, Nhúng, Viễn thông", dtvt)
        await db.flush()
        print("  → gv2@, gv3@")

        # ── 5. Cuộc thi FINISHED #1 — Lập trình Web 2025 ────────────────────
        print("\n[Cuộc thi FINISHED #1 — Lập trình Web 2025]")
        web_students = [
            students["B22DCCN001"],
            students["B22DCCN002"],
            students["B22DCCN004"],
            students["B22DCCN005"],
            students["B22DCCN006"],
            students["B22DCCN007"],
            students["B21DCCN001"],
            students["B21DCCN002"],
        ]
        web_criteria = [
            ("Giao diện & UX",     40, 40.0),
            ("Chức năng hoàn chỉnh", 35, 35.0),
            ("Hiệu suất & tối ưu",  25, 25.0),
        ]
        # scores_matrix[entry_idx][criterion_idx]
        web_scores = [
            [36, 32, 22],   # 90 → Giải Nhất
            [34, 30, 20],   # 84 → Giải Nhì
            [35, 28, 19],   # 82 → Giải Ba
            [30, 29, 18],   # 77 → KK
            [28, 27, 17],   # 72
            [26, 25, 16],   # 67
            [24, 22, 14],   # 60
            [20, 20, 12],   # 52
        ]
        contest_web = await create_finished_individual_contest(
            db, slug="lap-trinh-web-2025",
            title="Cuộc thi Lập trình Web 2025",
            description="Thí sinh thiết kế và phát triển ứng dụng web hoàn chỉnh trong 72 giờ.",
            award_text="Giải Nhất 5.000.000đ, Nhì 3.000.000đ, Ba 1.500.000đ.",
            faculty=cntt, organizer=organizer, judges=[judge_gv, judge2],
            students=web_students,
            criteria=web_criteria, scores_matrix=web_scores,
            start_ago_days=60, end_ago_days=53, gv_user=gv_user,
        )

        # ── 6. Cuộc thi FINISHED #2 — Olympic Toán Tin 2024 ─────────────────
        print("\n[Cuộc thi FINISHED #2 — Olympic Toán Tin 2024]")
        math_students = [
            students["B22DCCN001"],
            students["B22DCCN003"],
            students["B22DCCN007"],
            students["B21DCCN001"],
            students["B22DCVT001"],
            students["B22DCTM001"],
        ]
        math_criteria = [
            ("Tư duy thuật toán", 50, 50.0),
            ("Độ chính xác",       30, 30.0),
            ("Tốc độ thực thi",    20, 20.0),
        ]
        math_scores = [
            [46, 28, 18],   # 92 → Nhất
            [43, 27, 17],   # 87 → Nhì
            [40, 25, 16],   # 81 → Ba
            [38, 22, 15],   # 75 → KK
            [35, 20, 13],   # 68
            [30, 18, 12],   # 60
        ]
        contest_math = await create_finished_individual_contest(
            db, slug="olympic-toan-tin-2024",
            title="Olympic Toán Tin 2024",
            description="Sân chơi học thuật về toán học rời rạc và giải thuật lập trình.",
            award_text="Giải Nhất 4.000.000đ + huy chương vàng.",
            faculty=cntt, organizer=organizer, judges=[judge_gv, judge3],
            students=math_students,
            criteria=math_criteria, scores_matrix=math_scores,
            start_ago_days=180, end_ago_days=170, gv_user=gv_user,
        )

        # ── 7. Cuộc thi TEAM FINISHED — Hackathon IoT Kết Nối ───────────────
        print("\n[Cuộc thi TEAM FINISHED — Hackathon IoT]")
        iot_criteria = [
            ("Ý tưởng & tính mới",  30, 30.0),
            ("Kỹ thuật & hoàn thiện", 40, 40.0),
            ("Trình bày & thuyết phục", 30, 30.0),
        ]
        iot_teams = [
            ("SmartHome Pro",  students["B22DCCN001"][0], [students["B22DCCN004"][0], students["B22DCKT001"][0]], [27, 36, 27]),  # 90
            ("IoT Warriors",   students["B22DCVT001"][0], [students["B22DCTM001"][0], students["B22DCKT002"][0]], [25, 35, 25]),  # 85
            ("ConnectEdge",    students["B22DCCN005"][0], [students["B22DCKT003"][0], students["B22DCCN006"][0]], [24, 32, 22]),  # 78
            ("EcoSense",       students["B21DCCN001"][0], [students["B22DCVT002"][0]],                             [20, 28, 20]),  # 68
        ]
        contest_iot = await create_finished_team_contest(
            db, slug="hackathon-iot-ket-noi-2024",
            title="Hackathon IoT Kết Nối 2024",
            faculty=dtvt, organizer=organizer,
            judges=[judge_gv, judge3],
            teams_data=iot_teams,
            criteria=iot_criteria,
            gv_user=gv_user,
        )

        # ── 8. Cuộc thi REG_OPEN — sắp tới ──────────────────────────────────
        print("\n[Cuộc thi REG_OPEN — sắp tới]")
        slug_upcoming = "cuoc-thi-ui-ux-2026"
        if not (await db.execute(select(Contest).where(Contest.slug == slug_upcoming))).scalar_one_or_none():
            c_up = Contest(
                slug=slug_upcoming,
                title="Cuộc thi Thiết kế UI/UX 2026",
                description="Thiết kế giao diện người dùng sáng tạo, lấy người dùng làm trung tâm.",
                rules_text="Nộp file Figma + prototype. Chấm theo tiêu chí thẩm mỹ và tính khả dụng.",
                award_text="Giải Nhất 6.000.000đ, Nhì 3.500.000đ, Ba 2.000.000đ.",
                delivery_mode=DeliveryMode.ONLINE,
                participation_mode=EntryType.INDIVIDUAL,
                requires_submission=True,
                is_public=True,
                registration_open_at=ago(days=3),
                registration_close_at=later(days=14),
                start_at=later(days=15),
                end_at=later(days=22),
                status=ContestStatus.REG_OPEN,
                proposed_by=gv_user.user_id,
                host_faculty_id=cntt.faculty_id,
                created_by=gv_user.user_id,
            )
            db.add(c_up)
            await db.flush()
            db.add(ContestOrganizer(contest_id=c_up.contest_id, organizer_id=organizer.organizer_id))
            db.add(ContestRound(
                contest_id=c_up.contest_id, round_no=1,
                round_name="Vòng chính", round_type=RoundType.FINAL,
                start_at=later(days=15), end_at=later(days=22),
                is_elimination_round=False,
            ))
            await db.flush()
            print("  → Thiết kế UI/UX 2026 (REG_OPEN)")

        # ── 9. Faculty Cert Templates (BCN screen) ───────────────────────────
        print("\n[Faculty Cert Templates]")
        fct_data = [
            (cntt, "Mẫu Chứng nhận Cơ bản — CNTT",
             "Khổ A4 ngang, logo PTIT trên cùng, chữ ký BCN và GV hướng dẫn.",
             "BCN. Trần Văn B, Trưởng Khoa CNTT", True),
            (cntt, "Mẫu Chứng nhận Xuất sắc — CNTT",
             "Khổ A4 ngang, nền đỏ PTIT, viền vàng, huy hiệu xuất sắc.",
             "BCN. Trần Văn B; Hiệu trưởng PTIT", True),
            (dtvt, "Mẫu Chứng nhận — DTVT",
             "Khổ A4, màu xanh dương, logo khoa DTVT.",
             "Trưởng Khoa DTVT", False),
        ]
        bcn_user = await get_user(db, "bcn@ptit.edu.vn")
        for fac, name, layout, signers, active in fct_data:
            exists = (await db.execute(
                select(FacultyCertTemplate).where(
                    FacultyCertTemplate.faculty_id == fac.faculty_id,
                    FacultyCertTemplate.name == name,
                )
            )).scalar_one_or_none()
            if not exists:
                db.add(FacultyCertTemplate(
                    faculty_id=fac.faculty_id, name=name, layout_description=layout,
                    signers=signers, is_active=active, created_by=bcn_user.user_id if bcn_user else None,
                ))
        await db.flush()
        print(f"  → {len(fct_data)} faculty cert templates")

        # ── 10. Contest Reviews ───────────────────────────────────────────────
        print("\n[Contest Reviews]")
        reviews_data = [
            # (contest, student_key, rating, comment)
            (contest_web, "B22DCCN001", 5, "Cuộc thi rất hay, học được nhiều kỹ năng thực tế. Ban tổ chức nhiệt tình!"),
            (contest_web, "B22DCCN002", 4, "Đề bài thú vị, thời gian hơi ngắn nhưng đủ để thử thách. Sẽ tham gia lần sau."),
            (contest_web, "B22DCCN004", 5, "Trải nghiệm tuyệt vời! Nhận được phản hồi chi tiết từ ban giám khảo."),
            (contest_web, "B22DCCN005", 4, "Tổ chức tốt, chỉ tiêu rõ ràng. Mong cuộc thi năm sau sẽ có thêm mảng backend."),
            (contest_math, "B22DCCN001", 5, "Đề thi chất lượng cao, thực sự thử thách tư duy thuật toán."),
            (contest_math, "B22DCCN003", 4, "Rất bổ ích. Một số bài quá khó nhưng đó là thử thách đáng giá."),
            (contest_math, "B22DCVT001", 3, "Nội dung hay nhưng hệ thống nộp bài hơi lag vào phút cuối."),
            (contest_iot, "B22DCCN001", 5, "Hackathon rất thực tế! Làm việc nhóm, triển khai sản phẩm thật — cực kỳ hữu ích."),
            (contest_iot, "B22DCVT001", 5, "Ban giám khảo rất am hiểu IoT, góp ý rất giá trị cho sản phẩm của nhóm."),
            (contest_iot, "B22DCCN005", 4, "Ý tưởng hay, áp lực cao nhưng rất đáng. Hội trường tốt, hỗ trợ kỹ thuật tốt."),
        ]
        for ct, sv_code, rating, comment in reviews_data:
            st_obj = students[sv_code][0]
            exists_rv = (await db.execute(
                select(ContestReview).where(
                    ContestReview.contest_id == ct.contest_id,
                    ContestReview.student_id == st_obj.student_id,
                )
            )).scalar_one_or_none()
            if not exists_rv:
                db.add(ContestReview(
                    contest_id=ct.contest_id, student_id=st_obj.student_id,
                    rating=rating, comment_text=comment, is_visible=True,
                ))
        await db.flush()
        print(f"  → {len(reviews_data)} reviews")

        # ── 11. Questions + Answers cho Contest A ────────────────────────────
        print("\n[Questions & Answers]")
        contest_a = (await db.execute(
            select(Contest).where(Contest.slug == "lap-trinh-thuat-toan-2026")
        )).scalar_one_or_none()
        if contest_a:
            qa_data = [
                ("B22DCCN001", "Bài nộp có được sử dụng thư viện ngoài không?",
                 "Thí sinh có thể sử dụng STL và các thư viện chuẩn của ngôn ngữ. Thư viện bên thứ ba không được phép.",
                 QuestionStatus.ANSWERED),
                ("B22DCCN002", "Giới hạn thời gian chạy cho mỗi test case là bao nhiêu?",
                 "Mỗi test case có giới hạn 2 giây với C++ và 3 giây với Python/Java.",
                 QuestionStatus.ANSWERED),
                ("B22DCCN004", "Nếu submit nhiều lần thì tính bài nộp nào?",
                 None, QuestionStatus.OPEN),
            ]
            for sv_code, q_title, answer, status in qa_data:
                st_obj = students[sv_code][0]
                exists_q = (await db.execute(
                    select(Question).where(
                        Question.contest_id == contest_a.contest_id,
                        Question.asked_by_student_id == st_obj.student_id,
                        Question.title == q_title,
                    )
                )).scalar_one_or_none()
                if not exists_q:
                    q = Question(
                        contest_id=contest_a.contest_id,
                        asked_by_student_id=st_obj.student_id,
                        title=q_title,
                        content_text=q_title,
                        status=status,
                        is_public=True,
                    )
                    db.add(q)
                    await db.flush()
                    if answer:
                        db.add(QuestionAnswer(
                            question_id=q.question_id,
                            answered_by=gv_user.user_id,
                            content_text=answer,
                        ))
            await db.flush()
            print("  → 3 câu hỏi (2 đã trả lời, 1 đang mở)")

        # ── 12. Articles ──────────────────────────────────────────────────────
        print("\n[Articles]")
        articles_data = [
            (None, "Kết quả Cuộc thi Lập trình Web 2025",
             "Cuộc thi đã kết thúc với nhiều bài nộp xuất sắc.",
             "<h2>Chúc mừng các thí sinh đoạt giải!</h2><p>Cuộc thi Lập trình Web 2025 đã kết thúc thành công với 8 thí sinh tham gia. Ban tổ chức xin chúc mừng các bạn đã giành giải thưởng và cảm ơn tất cả thí sinh đã tham dự.</p>",
             ago(days=52)),
            (None, "Thông báo lịch thi Olympic Toán Tin 2024",
             "Chi tiết lịch thi và hướng dẫn chuẩn bị cho thí sinh.",
             "<h2>Lịch thi</h2><p>Cuộc thi diễn ra trong 2 ngày. Thí sinh cần mang theo CMND/CCCD và thẻ sinh viên còn hiệu lực.</p><ul><li>Ngày 1: Thi lý thuyết</li><li>Ngày 2: Thi thực hành lập trình</li></ul>",
             ago(days=175)),
            (None, "Mở đăng ký Cuộc thi Thiết kế UI/UX 2026",
             "Cơ hội thể hiện tài năng thiết kế của bạn — giải thưởng lên đến 6 triệu đồng!",
             "<h2>Cơ hội không thể bỏ qua!</h2><p>Cuộc thi Thiết kế UI/UX 2026 chính thức mở đăng ký. Đây là sân chơi dành cho các bạn sinh viên đam mê thiết kế sản phẩm số.</p><p><strong>Giải thưởng:</strong> Nhất 6.000.000đ | Nhì 3.500.000đ | Ba 2.000.000đ</p>",
             ago(days=3)),
            (None, "PTIT tổng kết hoạt động cuộc thi sinh viên năm học 2024-2025",
             "Năm học 2024-2025 ghi nhận sự tham gia tích cực của hơn 200 sinh viên trong các sân chơi học thuật.",
             "<h2>Nhìn lại năm học 2024-2025</h2><p>Khoa CNTT và DTVT đã tổ chức thành công 5 cuộc thi cấp khoa với tổng cộng hơn 200 lượt tham gia. Đây là con số kỷ lục trong lịch sử các hoạt động ngoại khoá của nhà trường.</p>",
             ago(days=30)),
        ]
        for _, art_title, summary, content, pub_at in articles_data:
            exists_art = (await db.execute(
                select(Article).where(Article.title == art_title)
            )).scalar_one_or_none()
            if not exists_art:
                db.add(Article(
                    contest_id=None, title=art_title, summary=summary,
                    content_html=content, is_public=True,
                    created_by=gv_user.user_id, published_at=pub_at,
                ))
        await db.flush()
        print(f"  → {len(articles_data)} bài viết")

        # ── 13. Thêm notifications ────────────────────────────────────────────
        print("\n[Notifications bổ sung]")
        notif_data = [
            ("Kết quả Lập trình Web 2025 đã được công bố",
             "Xem bảng xếp hạng và nhận chứng nhận tại mục Chứng nhận của bạn.",
             students["B22DCCN001"][1].user_id),
            ("Chứng nhận của bạn đã sẵn sàng tải về",
             "Cuộc thi Olympic Toán Tin 2024 — chứng nhận Giải Nhất đã được cấp.",
             students["B22DCCN001"][1].user_id),
            ("Mở đăng ký: Cuộc thi Thiết kế UI/UX 2026",
             "Đăng ký ngay để tham gia — hạn chót còn 14 ngày.",
             students["B22DCCN002"][1].user_id),
        ]
        for ntitle, nmsg, uid in notif_data:
            exists_n = (await db.execute(select(Notification).where(Notification.title == ntitle))).scalar_one_or_none()
            if not exists_n:
                n = Notification(
                    scope=NotificationScope.SYSTEM, title=ntitle, message=nmsg,
                    created_by=gv_user.user_id, published_at=ago(hours=12),
                )
                db.add(n)
                await db.flush()
                db.add(NotificationRecipient(notification_id=n.notification_id, user_id=uid))
        await db.flush()
        print(f"  → {len(notif_data)} thông báo")

        # ── 14. System Configs ────────────────────────────────────────────────
        print("\n[System Configs]")
        configs = [
            ("app.name",                    "PTIT Contest Platform",   "STRING", "Tên hệ thống"),
            ("app.max_file_size_mb",        "50",                       "INT",    "Dung lượng file tối đa (MB)"),
            ("app.registration_grace_days", "1",                        "INT",    "Số ngày gia hạn đăng ký"),
            ("feature.cert_auto_issue",     "true",                     "BOOL",   "Tự động cấp chứng nhận sau khi BCN duyệt kết quả"),
            ("feature.enable_reviews",      "true",                     "BOOL",   "Cho phép sinh viên đánh giá cuộc thi"),
            ("feature.enable_qna",          "true",                     "BOOL",   "Bật tính năng Q&A cho cuộc thi"),
        ]
        for key, val, vtype, desc in configs:
            exists_cfg = (await db.execute(
                select(SystemConfig).where(SystemConfig.config_key == key)
            )).scalar_one_or_none()
            if not exists_cfg:
                db.add(SystemConfig(
                    config_key=key, config_value=val,
                    value_type=vtype, description=desc,
                    updated_by=None,
                ))
        await db.flush()
        print(f"  → {len(configs)} system configs")

        # ── 15. Audit Logs ────────────────────────────────────────────────────
        print("\n[Audit Logs]")
        admin_user = await get_user(db, "admin@ptit.edu.vn")
        bcn_user2  = await get_user(db, "bcn@ptit.edu.vn")
        audit_entries = [
            (gv_user.user_id,   "CREATE",  "contest",     str(contest_web.contest_id),   {"title": "Cuộc thi Lập trình Web 2025"}),
            (gv_user.user_id,   "PUBLISH", "contest",     str(contest_web.contest_id),   {"status": "FINISHED"}),
            (bcn_user2.user_id, "APPROVE", "workflow",    "1",                            {"step": "BCN_QD2", "contest": "Lập trình Web 2025"}),
            (gv_user.user_id,   "CREATE",  "contest",     str(contest_math.contest_id),  {"title": "Olympic Toán Tin 2024"}),
            (gv_user.user_id,   "ASSIGN",  "judge",       str(judge2.judge_id),          {"contest": "Olympic Toán Tin 2024"}),
            (gv_user.user_id,   "LOCK",    "submission",  "1",                            {"entry": "WEB-001"}),
            (gv_user.user_id,   "SCORE",   "round_result","1",                            {"contest": "Lập trình Web 2025", "entries": 8}),
            (bcn_user2.user_id, "APPROVE", "contest_result","1",                          {"contest": "Lập trình Web 2025"}),
            (gv_user.user_id,   "ISSUE",   "certificate", "1",                            {"rank": 1, "award": "Giải Nhất"}),
            (gv_user.user_id,   "ISSUE",   "certificate", "2",                            {"rank": 2, "award": "Giải Nhì"}),
            (gv_user.user_id,   "ISSUE",   "certificate", "3",                            {"rank": 3, "award": "Giải Ba"}),
            (admin_user.user_id if admin_user else gv_user.user_id, "UPDATE", "system_config", "feature.cert_auto_issue", {"value": "true"}),
            (admin_user.user_id if admin_user else gv_user.user_id, "CREATE", "user",      str(gv2_user.user_id), {"email": "gv2@ptit.edu.vn", "role": "JUDGE"}),
            (admin_user.user_id if admin_user else gv_user.user_id, "CREATE", "user",      str(gv3_user.user_id), {"email": "gv3@ptit.edu.vn", "role": "JUDGE"}),
            (gv_user.user_id,   "CREATE",  "contest",     str(contest_iot.contest_id),   {"title": "Hackathon IoT Kết Nối 2024"}),
            (gv_user.user_id,   "PUBLISH", "contest",     str(contest_iot.contest_id),   {"status": "FINISHED"}),
            (bcn_user2.user_id, "CREATE",  "faculty_cert_template", "1",                  {"faculty": "CNTT"}),
            (gv_user.user_id,   "PUBLISH", "article",    "1",                            {"title": "Kết quả Lập trình Web 2025"}),
            (students["B22DCCN001"][1].user_id, "REGISTER", "contest_entry", "3",        {"contest": "Lập trình Web 2025"}),
            (students["B22DCCN001"][1].user_id, "DOWNLOAD", "certificate",    "1",        {"cert_qr": "demo"}),
        ]
        for uid, action, entity, eid, details in audit_entries:
            db.add(AuditLog(
                user_id=uid, action_type=action, entity_name=entity,
                entity_id=eid, details_json=details,
                created_at=ago(hours=audit_entries.index((uid, action, entity, eid, details)) + 1),
            ))
        await db.flush()
        print(f"  → {len(audit_entries)} audit logs")

        # ─────────────────────────────────────────────────────────────────────
        await db.commit()

    await engine.dispose()

    print("""
✅ Seed RICH data hoàn tất!

Dữ liệu đã thêm:
  • 3 khoa, 6 ngành, 8 lớp
  • 14 sinh viên mới (tổng ~17 SV)
  • 2 giám khảo mới (gv2@, gv3@)
  • 3 cuộc thi FINISHED + 1 REG_OPEN (tổng 6 contest)
  • Đầy đủ: score_criteria → judge_assignments → scores
            → round_results → contest_results → issued_certificates
  • 3 faculty cert templates (màn BCN)
  • 10 đánh giá sao từ SV
  • 3 Q&A trên Contest A hiện tại
  • 4 bài viết/tin tức
  • 6 system configs
  • 20 audit logs
""")


if __name__ == "__main__":
    asyncio.run(main())
