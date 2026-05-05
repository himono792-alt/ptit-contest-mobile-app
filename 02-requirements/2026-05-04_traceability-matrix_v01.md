# Ma trận Traceability: Chức năng ↔ Schema ↔ API

**Phiên bản:** v01 (2026-05-04)
**Schema reference:** `ptit_contest` v02 — 39 bảng (xem `08-database/2026-05-04_sqlapp_v02.sql`)
**Requirements source:** `02-requirements/2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`

---

## 1. Tổng quan

| Actor | Mã | Số chức năng | Coverage v02 | Gap |
|---|---|---|---|---|
| Sinh viên | SV | 11 | 10/11 | SV-11 (review/rating) |
| Giảng viên / BTC | GV | 7 | 7/7 | (full) |
| Ban Chủ nhiệm khoa | BCN | 6 | 5/6 | BCN-06 (certificate) |
| Admin | AD | 6 | 5/6 | AD-04 (system config) |
| **Tổng** | | **30** | **27/30** | **3 gap → cần SQL v03** |

**Quy ước cột:**
- **Bảng đọc / Bảng ghi**: chỉ liệt kê bảng nghiệp vụ chính. `audit_logs` được ghi ngầm cho mọi action có ảnh hưởng dữ liệu (không lặp lại trong từng dòng).
- **RBAC**: viết theo role_code enum (`STUDENT`, `ORGANIZER`, `JUDGE`, `HOD`, `ADMIN`) + scope (`own` / `assigned` / `faculty`).
- **API endpoint**: theo convention REST, prefix `/api/`, dùng `me` cho self-service, `admin` cho admin-only.

---

## 2. Sinh viên — 11 chức năng (Mã SV)

| Mã | Chức năng | Loại | Bảng đọc | Bảng ghi | RBAC | API endpoint | Quy định / Biểu mẫu | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| SV-01 | Đăng ký / Đăng nhập / Đăng xuất | Lưu trữ, Tra cứu | `app_users`, `student_directory`, `roles` | `app_users`, `students`, `user_roles` | `PUBLIC` (register), `STUDENT` (login) | `POST /api/auth/register` `POST /api/auth/login` `POST /api/auth/logout` | SV_QĐ1: MSSV không trùng (check `student_directory`), email `@ptit.edu.vn`, mật khẩu ≥6 ký tự. SV_BM1 | Login bằng email+password hoặc OTP 6 chữ số (theo memory tech stack) |
| SV-02 | Quản lý thông tin cá nhân | Lưu trữ | `app_users`, `students`, `student_directory` | `app_users` (avatar/phone/password), `students` (bio) | `STUDENT` (own) | `GET /api/me` `PATCH /api/me` `PATCH /api/me/password` `POST /api/auth/forgot-password` | Form Profile | Forgot-password cần token reset — schema chưa có `password_reset_tokens`, có thể dùng JWT short-lived |
| SV-03 | Xóa tài khoản | Lưu trữ | `app_users` | `app_users` (status=`DELETED`) | `STUDENT` (own) | `DELETE /api/me` | Chính sách bảo mật dữ liệu | Soft delete (set status), giữ `student_directory` để audit |
| SV-04 | Tìm kiếm và lọc cuộc thi | Tra cứu | `contests`, `contest_rounds`, `faculties` | — | `STUDENT` | `GET /api/contests?q=&mode=&status=&faculty=` | SV_BM2 | Chỉ trả contests có `status` IN (`PUBLISHED`,`REG_OPEN`,`ONGOING`,`FINISHED`) |
| SV-05 | Xem chi tiết cuộc thi | Tra cứu | `contests`, `contest_rounds`, `contest_sessions`, `articles`, `faculties` | — | `STUDENT` | `GET /api/contests/{slug}` `GET /api/contests/{slug}/articles` | — | Hiển thị description, rules_text, award_text, lịch thi từng round/session |
| SV-06 | Đăng ký tham gia cuộc thi | Lưu trữ | `contests`, `contest_entries`, `teams` | `contest_entries`, `teams`, `team_members` | `STUDENT` (own) | `POST /api/contests/{id}/register` `POST /api/contests/{id}/teams` `POST /api/teams/{id}/members` | QĐ-01, SV_QĐ2: auto check điều kiện + khóa khi hết hạn / đủ slot. SV_BM3, BM01 | Backend check `registration_close_at`, `max_entries`, partial unique index `uq_contest_individual_entry` đã ngăn đăng ký 2 lần |
| SV-07 | Xác nhận đăng ký | Lưu trữ | `contest_entries` | `notifications`, `notification_recipients` | `SYSTEM` (auto) | (background trigger) | — | Trigger sau SV-06 thành công, gửi email + tạo bản ghi notification |
| SV-08 | Nộp bài thi | Lưu trữ, Kết xuất | `submissions`, `contest_rounds`, `contest_entries` | `submissions`, `submission_versions`, `submission_files` | `STUDENT` (own entry) | `POST /api/rounds/{id}/submissions` `POST /api/submissions/{id}/versions` `POST /api/submissions/{id}/files` | QĐ-04 (định dạng/dung lượng), QĐ-02/SV_QĐ3 (status: Pending/Submitted/Late). SV_BM4, BM01 | Status `LATE` nếu `submitted_at > round.submission_close_at`, tự động dựa vào trigger backend |
| SV-09 | Quản lý lịch sử tham gia | Tra cứu, Kết xuất | `contest_entries`, `contests`, `round_results`, `contest_results`, `submissions` | — | `STUDENT` (own) | `GET /api/me/registrations` `GET /api/me/results` `GET /api/me/certificates/{contest_id}` | QĐ-02 (trạng thái). BM01, SV_BM1 | Tải certificate PDF — phụ thuộc BCN-06 (gap, xem section 6) |
| SV-10 | Hủy đăng ký | Lưu trữ | `contest_entries`, `contests` | `contest_entries` (status=`CANCELLED`), `entry_status_logs` | `STUDENT` (own, time-bounded) | `DELETE /api/contests/{id}/registration` | QĐ-03: chỉ cho hủy nếu `now() < contest.start_at - 7 days` (configurable) | Backend check thời gian, log vào `entry_status_logs` |
| SV-11 ⚠️ | Đánh giá cuộc thi | Lưu trữ | `contests`, `contest_results` | **(GAP — thiếu bảng `contest_reviews`)** | `STUDENT` (chỉ sau khi cuộc thi `FINISHED` và có `contest_result` của mình) | `POST /api/contests/{id}/reviews` `GET /api/contests/{id}/reviews` | Review logic: rating 1-5 sao + comment. SV_BM5 | **GAP**: Schema v02 KHÔNG có bảng review. Đề xuất v03 thêm `contest_reviews(review_id, contest_id, student_id, rating, comment, is_visible, created_at)` với UNIQUE `(contest_id, student_id)` |

---

## 3. Giảng viên / Ban tổ chức — 7 chức năng (Mã GV)

| Mã | Chức năng | Loại | Bảng đọc | Bảng ghi | RBAC | API endpoint | Quy định | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| GV-01 | Quản lý tài khoản giảng viên | Lưu trữ, Tra cứu | `app_users`, `organizers`, `faculties` | `app_users`, `organizers` | `ORGANIZER` (own) | `POST /api/auth/login` `GET /api/me` `PATCH /api/me` `PATCH /api/me/password` | Email `@ptit.edu.vn`, mã GV duy nhất | Tài khoản GV do Admin tạo trước (AD-02), GV chỉ login + update profile |
| GV-02 | Tạo và quản lý cuộc thi | Lưu trữ, Tra cứu | `contests`, `contest_rounds`, `contest_sessions`, `contest_entries` | `contests`, `contest_rounds`, `contest_sessions`, `contest_organizers`, `workflow_approvals` | `ORGANIZER` (created_by self) | `POST /api/contests` (DRAFT) `PATCH /api/contests/{id}` `DELETE /api/contests/{id}` `POST /api/contests/{id}/rounds` `POST /api/contests/{id}/sessions` `POST /api/contests/{id}/submit-for-approval` | GV_QĐ1: mỗi cuộc thi có mã (slug) duy nhất, full thông tin trước khi submit | DELETE chỉ khi `status=DRAFT` AND không có `contest_entries`. Submit-for-approval chuyển `DRAFT → PROPOSED` + tạo `workflow_approvals(target=CONTEST_PROPOSAL, step=BCN_QD1)` |
| GV-03 | Phê duyệt đăng ký thí sinh | Lưu trữ, Tra cứu | `contest_entries`, `students`, `student_directory`, `teams`, `team_members`, `contests` | `contest_entries` (registration_status, approved_by, approved_at), `entry_status_logs` | `ORGANIZER` (assigned via `contest_organizers`) | `GET /api/contests/{id}/entries?status=PENDING` `PATCH /api/contests/{id}/entries/{entry_id}` (action: approve/reject) | GV_QĐ2: kiểm tra điều kiện + số lượng tối đa | Nếu reject phải có `registration_note`. Notify SV qua `notifications` |
| GV-04 | Quản lý bài thi | Lưu trữ, Tra cứu | `submissions`, `submission_versions`, `submission_files`, `contest_rounds` | `submissions` (is_locked, status=`LOCKED`) | `ORGANIZER` (assigned) | `GET /api/rounds/{id}/submissions` `GET /api/submissions/{id}` `GET /api/submission-files/{id}/download` `POST /api/submissions/{id}/lock` | QĐ-01: khóa bài thi sau thời hạn | Auto lock khi `now() > round.submission_close_at` (cron job hoặc trigger) |
| GV-05 | Chấm bài và nhập điểm | Tính toán, Lưu trữ | `judge_assignments`, `submissions`, `round_score_criteria`, `scores` | `judge_assignments` (assign), `scores` (insert/update), `round_results` (auto compute) | `JUDGE` (own assignment) hoặc `ORGANIZER` (assign judges) | `POST /api/contests/{id}/judges` (assign) `POST /api/rounds/{id}/judge-assignments` (phân công cụ thể) `GET /api/me/judge-assignments` `POST /api/assignments/{id}/scores` `POST /api/rounds/{id}/compute-results` | QĐ-04, GV_QĐ3: thang điểm 10 hoặc 100, công thức TB nếu nhiều giám khảo | `round_results.total_score = SUM(score_value × weight_percent / 100)` qua tất cả `scores` của entry. Weight enforce ở `round_score_criteria` |
| GV-06 | Công bố kết quả | Lưu trữ | `round_results`, `contest_results`, `workflow_approvals` | `contest_results`, `notifications`, `workflow_approvals` (target=CONTEST_RESULT) | `ORGANIZER` | `POST /api/contests/{id}/results/compute` `POST /api/contests/{id}/results/submit-for-approval` `POST /api/contests/{id}/results/publish` | — | Flow: compute (tổng hợp round → final) → submit-for-approval (tạo BCN_QD2) → chờ BCN duyệt → publish (set `published_at`, gửi notification cho SV). Publish CHỈ allowed khi `workflow_approvals.status='APPROVED'` cho BCN_QD2 |
| GV-07 | Thống kê và báo cáo | Kết xuất, Tổng hợp | `contests`, `contest_entries`, `submissions`, `round_results`, `contest_results` | — (hoặc cache vào `articles`) | `ORGANIZER` | `GET /api/contests/{id}/stats` `GET /api/contests/{id}/report.xlsx` | Thuật toán tính tổng hợp | Stats: tổng đăng ký, tỷ lệ duyệt, số bài nộp, điểm TB, tỷ lệ pass. Export Excel dùng `openpyxl` |

---

## 4. Ban Chủ nhiệm khoa — 6 chức năng (Mã BCN)

| Mã | Chức năng | Loại | Bảng đọc | Bảng ghi | RBAC | API endpoint | Quy định | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| BCN-01 | Đăng nhập / Đăng xuất | Lưu trữ | `app_users`, `department_heads`, `roles` | `app_users` (last_login_at) | `HOD` | `POST /api/auth/login` `POST /api/auth/logout` `GET /api/me` | — | Tài khoản BCN do Admin tạo (AD-02), gắn `department_heads.faculty_id` để biết duyệt cuộc thi của khoa nào |
| BCN-02 | Phê duyệt đề xuất cuộc thi (BCN_QĐ1) | Lưu trữ | `workflow_approvals` (target=`CONTEST_PROPOSAL`), `contests`, `organizers`, `contest_rounds` | `workflow_approvals` (status, reviewed_by, reviewed_at, bcn_comment), `contests` (status `PROPOSED → PUBLISHED` hoặc `REVISION_REQUESTED`) | `HOD` (where `department_heads.faculty_id = contests.host_faculty_id`) | `GET /api/me/pending-approvals?type=CONTEST_PROPOSAL` `GET /api/approvals/{id}` `POST /api/approvals/{id}/decide` (action: approve / reject / request_revision, comment) | BCN_QĐ1: cuộc thi phải có đề xuất rõ ràng về mục tiêu, kinh phí, nguồn lực | Decision: APPROVE → contest.status=PUBLISHED; REQUEST_REVISION → status=REVISION_REQUESTED + tăng `revision_round` cho lần submit tiếp theo; REJECT → status=DRAFT (BTC sửa lại từ đầu) |
| BCN-03 | Giám sát tiến độ cuộc thi | Tra cứu | `contests` (where host_faculty_id=own), `contest_entries`, `submissions`, `round_results`, `contest_sessions` | — | `HOD` (own faculty) | `GET /api/admin/contests/monitor?faculty_id={own}` `GET /api/admin/contests/{id}/progress` | — | Dashboard: số contest đang chạy, % hoàn thành mỗi giai đoạn (đăng ký / nộp bài / chấm điểm) |
| BCN-04 | Phê duyệt kết quả chung cuộc (BCN_QĐ2) | Lưu trữ | `workflow_approvals` (target=`CONTEST_RESULT`), `contest_results`, `round_results` | `workflow_approvals`, `contest_results` (`bcn_approval_status`) | `HOD` (own faculty) | `GET /api/me/pending-approvals?type=CONTEST_RESULT` `POST /api/approvals/{id}/decide` | BCN_QĐ2: kết quả phải được rà soát trước khi phê duyệt | Tương tự BCN-02 nhưng cho kết quả. APPROVE → BTC mới được publish (GV-06) |
| BCN-05 | Thống kê và báo cáo tổng hợp | Kết xuất, Tổng hợp | `contests`, `contest_entries`, `contest_results`, `students`, `student_directory`, `faculties`, `majors` | — | `HOD` | `GET /api/reports/faculty-summary?faculty_id={own}&year={yyyy}` `GET /api/reports/faculty-summary.xlsx` | — | Số cuộc thi/năm, số SV tham gia (theo khoa/ngành), giải thưởng đã trao, đánh giá hiệu quả |
| BCN-06 ⚠️ | Xuất giấy chứng nhận / chứng chỉ | Kết xuất | `contest_results`, `students`, `contests` | **(GAP — thiếu bảng `certificate_templates`, `issued_certificates`)** | `HOD` (approve mẫu), `SYSTEM` (generate) | `POST /api/contests/{id}/certificates/template` `POST /api/contests/{id}/certificates/issue` `GET /api/certificates/{cert_id}.pdf` `GET /api/certificates/verify/{qr_code}` (public) | BCN_QĐ3: giấy chứng nhận có mã QR xác thực | **GAP**: Schema v02 chỉ có `contest_results.award_title` (text). Đề xuất v03 thêm: `certificate_templates(template_id, contest_id, html_template, approved_by)` + `issued_certificates(cert_id, contest_result_id, qr_code UK, pdf_url, issued_at, revoked_at)` |

---

## 5. Admin — 6 chức năng (Mã AD)

| Mã | Chức năng | Loại | Bảng đọc | Bảng ghi | RBAC | API endpoint | Ghi chú |
|---|---|---|---|---|---|---|---|
| AD-01 | Đăng nhập / Đăng xuất | Lưu trữ | `app_users` | `app_users` (last_login_at) | `ADMIN` | `POST /api/auth/login` `POST /api/auth/logout` | Tài khoản admin seed sẵn từ migration |
| AD-02 | Quản lý tài khoản | Lưu trữ, Tra cứu | `app_users`, `user_roles`, `roles`, `students`, `organizers`, `judges`, `department_heads`, `student_directory` | `app_users` (CRUD + lock/unlock), `user_roles` (assign role), `students`/`organizers`/`judges`/`department_heads` (tạo profile tương ứng) | `ADMIN` | `GET /api/admin/users?role=&status=` `POST /api/admin/users` `PATCH /api/admin/users/{id}` `DELETE /api/admin/users/{id}` `POST /api/admin/users/{id}/lock` `PATCH /api/admin/users/{id}/roles` `POST /api/admin/students/import` (import từ `student_directory`) | Tạo BCN: cần chỉ định `faculty_id` + flag `is_primary_approver`. Tạo SV: thường import bulk từ CSV vào `student_directory` rồi mới tạo `app_users` khi SV tự đăng ký |
| AD-03 | Quản lý khoa / ngành | Lưu trữ | `faculties`, `majors`, `academic_classes` | `faculties`, `majors`, `academic_classes` | `ADMIN` | `GET POST PATCH DELETE /api/admin/faculties` `GET POST PATCH DELETE /api/admin/majors` `GET POST PATCH DELETE /api/admin/classes` | Cấu trúc: `faculty (1) → majors (N) → classes (N) → student_directory (N)` |
| AD-04 ⚠️ | Quản lý hệ thống | Lưu trữ | **(GAP — thiếu bảng `system_configs`)** | **(GAP — thiếu bảng `system_configs`)** | `ADMIN` | `GET /api/admin/configs` `PATCH /api/admin/configs/{key}` `POST /api/admin/backup` (CLI wrapper) `POST /api/admin/restore` | Cấu hình: OTP timeout, max file size, email SMTP, ... | **GAP**: Schema v02 không có bảng config. Đề xuất v03 thêm `system_configs(config_key VARCHAR PK, config_value TEXT, value_type VARCHAR, description TEXT, updated_by, updated_at)` — pattern key-value đơn giản. Backup/restore là CLI `pg_dump` wrapper, không cần schema |
| AD-05 | Thống kê toàn hệ thống | Kết xuất, Tổng hợp | All business tables | — | `ADMIN` | `GET /api/admin/reports/system-summary` `GET /api/admin/reports/system-summary.xlsx` | Tổng contest/năm, total SV active, tỷ lệ hoàn thành toàn hệ thống |
| AD-06 | Audit & kiểm soát | Tra cứu, Lưu trữ | `audit_logs`, `contest_reviews` (gap), `notifications` | `audit_logs` (insert from middleware), `contest_reviews` (kiểm duyệt — gap) | `ADMIN` | `GET /api/admin/audit-logs?user_id=&action=&entity=&from=&to=` `GET /api/admin/anomaly-reports` `PATCH /api/admin/reviews/{id}/moderate` (gap) | `details_json JSONB` cho phép search linh hoạt. Kiểm duyệt review phụ thuộc SV-11 (gap) |

---

## 6. GAP analysis — đề xuất SQL v03

Có **3 chức năng (10%)** chưa được cover bởi schema v02. Cần bổ sung trong v03:

### GAP-1: SV-11 Đánh giá cuộc thi → Bảng `contest_reviews`

```sql
CREATE TABLE contest_reviews (
    review_id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_id       BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    student_id       BIGINT NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    rating           SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment_text     TEXT,
    is_visible       BOOLEAN NOT NULL DEFAULT TRUE,   -- admin có thể ẩn (AD-06)
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (contest_id, student_id)                   -- mỗi SV chỉ review 1 lần / contest
);
```

**Liên quan:** SV-11 (write), AD-06 (moderate `is_visible`).

### GAP-2: BCN-06 Xuất giấy chứng nhận → 2 bảng `certificate_templates` + `issued_certificates`

```sql
CREATE TABLE certificate_templates (
    template_id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_id           BIGINT NOT NULL REFERENCES contests(contest_id) ON DELETE CASCADE,
    template_name        VARCHAR(150) NOT NULL,
    html_template        TEXT NOT NULL,                -- Jinja2 / mustache
    background_image_url TEXT,
    approved_by          BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    approved_at          TIMESTAMPTZ,
    is_active            BOOLEAN NOT NULL DEFAULT FALSE,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE issued_certificates (
    cert_id              BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    contest_result_id    BIGINT NOT NULL REFERENCES contest_results(contest_result_id) ON DELETE CASCADE,
    template_id          BIGINT REFERENCES certificate_templates(template_id) ON DELETE SET NULL,
    qr_code              VARCHAR(64) NOT NULL UNIQUE,  -- public verify code
    pdf_url              TEXT NOT NULL,
    issued_by            BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    issued_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    revoked_at           TIMESTAMPTZ,
    revoke_reason        TEXT
);
```

**Liên quan:** BCN-06 (write), SV-09 (download cert qua `GET /api/me/certificates/{contest_id}`).

### GAP-3: AD-04 Quản lý cấu hình hệ thống → Bảng `system_configs`

```sql
CREATE TABLE system_configs (
    config_key       VARCHAR(100) PRIMARY KEY,         -- vd: 'otp.timeout_seconds', 'upload.max_size_mb'
    config_value     TEXT NOT NULL,
    value_type       VARCHAR(20) NOT NULL,             -- 'int', 'string', 'bool', 'json'
    description      TEXT,
    is_sensitive     BOOLEAN NOT NULL DEFAULT FALSE,   -- mask trong UI
    updated_by       BIGINT REFERENCES app_users(user_id) ON DELETE SET NULL,
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed config mặc định
INSERT INTO system_configs (config_key, config_value, value_type, description) VALUES
('otp.timeout_seconds',      '300',  'int',    'Thời gian hết hạn OTP (giây)'),
('upload.max_size_mb',       '50',   'int',    'Kích thước file upload tối đa (MB)'),
('cancel.min_days_before',   '7',    'int',    'Số ngày tối thiểu trước thi để hủy đăng ký'),
('rating.allowed_after_finish', 'true', 'bool', 'Cho phép review sau khi contest FINISHED');
```

**Liên quan:** AD-04 (CRUD), tất cả services khác đọc config khi cần.

### Tổng kết gap

| Gap | Bảng cần thêm | Số dòng SQL ước tính | Ưu tiên |
|---|---|---|---|
| GAP-1 | `contest_reviews` | ~15 | Medium (chức năng phụ) |
| GAP-2 | `certificate_templates`, `issued_certificates` | ~30 | High (BCN-06 là chức năng chính của BCN) |
| GAP-3 | `system_configs` | ~20 + seed data | High (cần ngay từ phase 1) |

**Đề xuất:** Tạo SQL v03 (`2026-05-XX_sqlapp_v03.sql`) gộp cả 3 gap. Ước tính thêm ~80 dòng so với v02.

---

## 7. Hướng dẫn sử dụng matrix này

**Cho backend dev (FastAPI):**
- Cột "API endpoint" là spec router. Mỗi endpoint → 1 function trong `routers/{actor}.py`.
- Cột "RBAC" map vào `dependencies/auth.py` decorator: `@require_role(STUDENT)`, `@require_owner_or_role(ORGANIZER)`.
- Cột "Bảng đọc/ghi" giúp viết `models/` và `schemas/` Pydantic — biết bảng nào cần SQLAlchemy ORM model.

**Cho frontend dev (Flutter):**
- Cột "Chức năng" + "RBAC" giúp routing: SV chỉ thấy SV-* endpoints (build APK), 3 role admin thấy GV-*/BCN-*/AD-* (build Web).
- Cột "API endpoint" = source of truth khi viết `services/api_client.dart`.

**Cho QA / test:**
- Mỗi dòng = 1 user story để viết test case (`10-testing/`). Đánh số `TC-SV-01-01`, `TC-SV-01-02`, ... cho các sub-case.

**Cho báo cáo CNPM:**
- Section "Phân tích yêu cầu" có sẵn matrix coverage 27/30 + gap analysis có giải pháp.
- Section "Thiết kế hệ thống" reference được tới ER diagram + SQL schema.

---

**Sources:**
- Requirements: `02-requirements/2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`
- Schema: `08-database/2026-05-04_sqlapp_v02.sql`
- ER diagram: `08-database/2026-05-04_er-diagram_v01.mermaid`
