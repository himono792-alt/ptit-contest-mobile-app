# Ma trận Traceability: Chức năng ↔ Schema ↔ API

**Phiên bản:** v02 (2026-05-04) — đồng bộ với schema v03
**Schema reference:** `ptit_contest` v03 — 43 bảng (xem `08-database/2026-05-04_sqlapp_v03.sql`)
**Requirements source:** `02-requirements/2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`
**Thay đổi từ v01:** 3 GAP đã được giải quyết bởi schema v03 (contest_reviews, certificate_templates+issued_certificates, system_configs)

---

## 1. Tổng quan

| Actor | Mã | Số chức năng | Coverage v03 | Trạng thái |
|---|---|---|---|---|
| Sinh viên | SV | 11 | **11/11** | ✅ Full |
| Giảng viên / BTC | GV | 7 | **7/7** | ✅ Full |
| Ban Chủ nhiệm khoa | BCN | 6 | **6/6** | ✅ Full |
| Admin | AD | 6 | **6/6** | ✅ Full |
| **Tổng** | | **30** | **30/30** | ✅ **Full coverage** |

**Quy ước cột:**
- **Bảng đọc / Bảng ghi**: chỉ liệt kê bảng nghiệp vụ chính. `audit_logs` được ghi ngầm cho mọi action có ảnh hưởng dữ liệu (không lặp lại trong từng dòng).
- **RBAC**: viết theo role_code enum (`STUDENT`, `ORGANIZER`, `JUDGE`, `HOD`, `ADMIN`) + scope (`own` / `assigned` / `faculty`).
- **API endpoint**: theo convention REST, prefix `/api/`, dùng `me` cho self-service, `admin` cho admin-only.

---

## 2. Sinh viên — 11 chức năng (Mã SV)

| Mã | Chức năng | Loại | Bảng đọc | Bảng ghi | RBAC | API endpoint | Quy định / Biểu mẫu | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| SV-01 | Đăng ký / Đăng nhập / Đăng xuất | Lưu trữ, Tra cứu | `app_users`, `student_directory`, `roles` | `app_users`, `students`, `user_roles` | `PUBLIC` (register), `STUDENT` (login) | `POST /api/auth/register` `POST /api/auth/login` `POST /api/auth/logout` | SV_QĐ1: MSSV không trùng, email @ptit.edu.vn, mật khẩu ≥6. SV_BM1 | OTP 6 chữ số config qua `system_configs.otp.code_length` + `otp.timeout_seconds` |
| SV-02 | Quản lý thông tin cá nhân | Lưu trữ | `app_users`, `students`, `student_directory` | `app_users`, `students` | `STUDENT` (own) | `GET /api/me` `PATCH /api/me` `PATCH /api/me/password` `POST /api/auth/forgot-password` | Form Profile | Forgot-password dùng JWT short-lived (không cần bảng riêng) |
| SV-03 | Xóa tài khoản | Lưu trữ | `app_users` | `app_users` (status=DELETED) | `STUDENT` (own) | `DELETE /api/me` | Chính sách bảo mật dữ liệu | Soft delete |
| SV-04 | Tìm kiếm và lọc cuộc thi | Tra cứu | `contests`, `contest_rounds`, `faculties` | — | `STUDENT` | `GET /api/contests?q=&mode=&status=&faculty=` | SV_BM2 | Chỉ trả contests có status IN (PUBLISHED, REG_OPEN, ONGOING, FINISHED) |
| SV-05 | Xem chi tiết cuộc thi | Tra cứu | `contests`, `contest_rounds`, `contest_sessions`, `articles`, `contest_reviews` | — | `STUDENT` | `GET /api/contests/{slug}` `GET /api/contests/{slug}/articles` `GET /api/contests/{slug}/reviews` | — | Hiển thị thêm rating trung bình + reviews từ `contest_reviews` (chỉ visible) |
| SV-06 | Đăng ký tham gia cuộc thi | Lưu trữ | `contests`, `contest_entries`, `teams` | `contest_entries`, `teams`, `team_members` | `STUDENT` (own) | `POST /api/contests/{id}/register` `POST /api/contests/{id}/teams` `POST /api/teams/{id}/members` | QĐ-01, SV_QĐ2. SV_BM3, BM01 | Backend check `registration_close_at`, `max_entries`. Partial unique index ngăn đăng ký 2 lần |
| SV-07 | Xác nhận đăng ký | Lưu trữ | `contest_entries` | `notifications`, `notification_recipients` | `SYSTEM` (auto) | (background trigger) | — | Trigger sau SV-06 |
| SV-08 | Nộp bài thi | Lưu trữ, Kết xuất | `submissions`, `contest_rounds`, `contest_entries`, `system_configs` | `submissions`, `submission_versions`, `submission_files` | `STUDENT` (own entry) | `POST /api/rounds/{id}/submissions` `POST /api/submissions/{id}/versions` `POST /api/submissions/{id}/files` | QĐ-04, QĐ-02/SV_QĐ3. SV_BM4, BM01 | Validate file size theo `system_configs.upload.max_size_mb`, extensions theo `upload.allowed_extensions` |
| SV-09 | Quản lý lịch sử tham gia | Tra cứu, Kết xuất | `contest_entries`, `contests`, `round_results`, `contest_results`, `submissions`, `issued_certificates` | — | `STUDENT` (own) | `GET /api/me/registrations` `GET /api/me/results` `GET /api/me/certificates/{contest_id}` | QĐ-02. BM01, SV_BM1 | Tải certificate PDF từ `issued_certificates.pdf_url` (cover bởi BCN-06) |
| SV-10 | Hủy đăng ký | Lưu trữ | `contest_entries`, `contests`, `system_configs` | `contest_entries` (status=CANCELLED), `entry_status_logs` | `STUDENT` (own, time-bounded) | `DELETE /api/contests/{id}/registration` | QĐ-03 | Threshold ngày từ `system_configs.cancel.min_days_before` (default 7) |
| SV-11 ✅ | Đánh giá cuộc thi | Lưu trữ | `contests`, `contest_results`, `system_configs` | `contest_reviews` | `STUDENT` (sau khi contest FINISHED và có result của mình) | `POST /api/contests/{id}/reviews` `GET /api/contests/{id}/reviews` `PATCH /api/contests/{id}/reviews/me` | Review logic: rating 1-5 + comment. SV_BM5 | ✅ **Resolved v03** — bảng `contest_reviews(review_id, contest_id, student_id, rating, comment_text, is_visible, moderated_by, moderated_at)` UNIQUE (contest_id, student_id). Check flag `system_configs.rating.allowed_after_finish` |

---

## 3. Giảng viên / Ban tổ chức — 7 chức năng (Mã GV)

| Mã | Chức năng | Loại | Bảng đọc | Bảng ghi | RBAC | API endpoint | Quy định | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| GV-01 | Quản lý tài khoản giảng viên | Lưu trữ, Tra cứu | `app_users`, `organizers`, `faculties` | `app_users`, `organizers` | `ORGANIZER` (own) | `POST /api/auth/login` `GET /api/me` `PATCH /api/me` `PATCH /api/me/password` | Email @ptit.edu.vn, mã GV duy nhất | Tài khoản GV do Admin tạo (AD-02) |
| GV-02 | Tạo và quản lý cuộc thi | Lưu trữ, Tra cứu | `contests`, `contest_rounds`, `contest_sessions`, `contest_entries` | `contests`, `contest_rounds`, `contest_sessions`, `contest_organizers`, `workflow_approvals` | `ORGANIZER` (created_by self) | `POST /api/contests` `PATCH /api/contests/{id}` `DELETE /api/contests/{id}` `POST /api/contests/{id}/rounds` `POST /api/contests/{id}/sessions` `POST /api/contests/{id}/submit-for-approval` | GV_QĐ1 | Submit-for-approval: DRAFT→PROPOSED + tạo `workflow_approvals(target=CONTEST_PROPOSAL, step=BCN_QD1)` |
| GV-03 | Phê duyệt đăng ký thí sinh | Lưu trữ, Tra cứu | `contest_entries`, `students`, `student_directory`, `teams`, `team_members`, `contests` | `contest_entries`, `entry_status_logs` | `ORGANIZER` (assigned via `contest_organizers`) | `GET /api/contests/{id}/entries?status=PENDING` `PATCH /api/contests/{id}/entries/{entry_id}` | GV_QĐ2 | Reject phải có `registration_note`. Notify SV qua `notifications` |
| GV-04 | Quản lý bài thi | Lưu trữ, Tra cứu | `submissions`, `submission_versions`, `submission_files`, `contest_rounds` | `submissions` (is_locked, status=LOCKED) | `ORGANIZER` (assigned) | `GET /api/rounds/{id}/submissions` `GET /api/submissions/{id}` `GET /api/submission-files/{id}/download` `POST /api/submissions/{id}/lock` | QĐ-01 | Auto lock khi `now() > round.submission_close_at` |
| GV-05 | Chấm bài và nhập điểm | Tính toán, Lưu trữ | `judge_assignments`, `submissions`, `round_score_criteria`, `scores` | `judge_assignments`, `scores`, `round_results` (auto compute) | `JUDGE` (own assignment) hoặc `ORGANIZER` (assign judges) | `POST /api/contests/{id}/judges` `POST /api/rounds/{id}/judge-assignments` `GET /api/me/judge-assignments` `POST /api/assignments/{id}/scores` `POST /api/rounds/{id}/compute-results` | QĐ-04, GV_QĐ3 | `round_results.total_score = SUM(score_value × weight_percent / 100)` |
| GV-06 | Công bố kết quả | Lưu trữ | `round_results`, `contest_results`, `workflow_approvals` | `contest_results`, `notifications`, `workflow_approvals` (target=CONTEST_RESULT) | `ORGANIZER` | `POST /api/contests/{id}/results/compute` `POST /api/contests/{id}/results/submit-for-approval` `POST /api/contests/{id}/results/publish` | — | Publish CHỈ allowed khi `workflow_approvals.status=APPROVED` cho BCN_QD2 |
| GV-07 | Thống kê và báo cáo | Kết xuất, Tổng hợp | `contests`, `contest_entries`, `submissions`, `round_results`, `contest_results`, `contest_reviews` | — | `ORGANIZER` | `GET /api/contests/{id}/stats` `GET /api/contests/{id}/report.xlsx` | Thuật toán tính tổng hợp | Stats có thêm avg rating từ `contest_reviews` |

---

## 4. Ban Chủ nhiệm khoa — 6 chức năng (Mã BCN)

| Mã | Chức năng | Loại | Bảng đọc | Bảng ghi | RBAC | API endpoint | Quy định | Ghi chú |
|---|---|---|---|---|---|---|---|---|
| BCN-01 | Đăng nhập / Đăng xuất | Lưu trữ | `app_users`, `department_heads`, `roles` | `app_users` (last_login_at) | `HOD` | `POST /api/auth/login` `POST /api/auth/logout` `GET /api/me` | — | Tài khoản BCN do Admin tạo (AD-02) |
| BCN-02 | Phê duyệt đề xuất cuộc thi (BCN_QĐ1) | Lưu trữ | `workflow_approvals`, `contests`, `organizers`, `contest_rounds` | `workflow_approvals`, `contests` (status PROPOSED→PUBLISHED hoặc REVISION_REQUESTED) | `HOD` (where `department_heads.faculty_id = contests.host_faculty_id`) | `GET /api/me/pending-approvals?type=CONTEST_PROPOSAL` `GET /api/approvals/{id}` `POST /api/approvals/{id}/decide` | BCN_QĐ1 | APPROVE → PUBLISHED. REQUEST_REVISION → REVISION_REQUESTED + tăng `revision_round`. REJECT → DRAFT |
| BCN-03 | Giám sát tiến độ cuộc thi | Tra cứu | `contests`, `contest_entries`, `submissions`, `round_results`, `contest_sessions` | — | `HOD` (own faculty) | `GET /api/admin/contests/monitor?faculty_id={own}` `GET /api/admin/contests/{id}/progress` | — | Dashboard % hoàn thành mỗi giai đoạn |
| BCN-04 | Phê duyệt kết quả chung cuộc (BCN_QĐ2) | Lưu trữ | `workflow_approvals`, `contest_results`, `round_results` | `workflow_approvals`, `contest_results` (`bcn_approval_status`) | `HOD` (own faculty) | `GET /api/me/pending-approvals?type=CONTEST_RESULT` `POST /api/approvals/{id}/decide` | BCN_QĐ2 | APPROVE → BTC publish được (GV-06) |
| BCN-05 | Thống kê và báo cáo tổng hợp | Kết xuất, Tổng hợp | `contests`, `contest_entries`, `contest_results`, `students`, `student_directory`, `faculties`, `majors` | — | `HOD` | `GET /api/reports/faculty-summary?faculty_id={own}&year={yyyy}` `GET /api/reports/faculty-summary.xlsx` | — | Số contest/năm, số SV theo khoa/ngành, giải thưởng đã trao |
| BCN-06 ✅ | Xuất giấy chứng nhận / chứng chỉ | Kết xuất | `contest_results`, `students`, `contests`, `certificate_templates`, `issued_certificates`, `system_configs` | `certificate_templates`, `issued_certificates` | `HOD` (approve template), `SYSTEM` (generate cert) | `POST /api/contests/{id}/certificates/templates` `PATCH /api/certificates/templates/{id}/approve` `PATCH /api/certificates/templates/{id}/activate` `POST /api/contests/{id}/certificates/issue` `GET /api/certificates/{cert_id}.pdf` `GET /verify/{qr_code}` (public) | BCN_QĐ3 | ✅ **Resolved v03** — 2 bảng `certificate_templates(html_template, approved_by, is_active)` + `issued_certificates(qr_code UK, pdf_url, revoked_at)`. QR base URL từ `system_configs.certificate.qr_verify_url_base`. Partial unique index `uq_contest_active_template` đảm bảo 1 contest = 1 active template |

---

## 5. Admin — 6 chức năng (Mã AD)

| Mã | Chức năng | Loại | Bảng đọc | Bảng ghi | RBAC | API endpoint | Ghi chú |
|---|---|---|---|---|---|---|---|
| AD-01 | Đăng nhập / Đăng xuất | Lưu trữ | `app_users` | `app_users` (last_login_at) | `ADMIN` | `POST /api/auth/login` `POST /api/auth/logout` | Tài khoản admin seed sẵn từ migration |
| AD-02 | Quản lý tài khoản | Lưu trữ, Tra cứu | `app_users`, `user_roles`, `roles`, `students`, `organizers`, `judges`, `department_heads`, `student_directory` | `app_users`, `user_roles`, `students`/`organizers`/`judges`/`department_heads` | `ADMIN` | `GET /api/admin/users` `POST /api/admin/users` `PATCH /api/admin/users/{id}` `DELETE /api/admin/users/{id}` `POST /api/admin/users/{id}/lock` `PATCH /api/admin/users/{id}/roles` `POST /api/admin/students/import` | Tạo BCN: chỉ định `faculty_id` + flag `is_primary_approver`. Tạo SV: bulk import vào `student_directory` |
| AD-03 | Quản lý khoa / ngành | Lưu trữ | `faculties`, `majors`, `academic_classes` | `faculties`, `majors`, `academic_classes` | `ADMIN` | `CRUD /api/admin/faculties` `CRUD /api/admin/majors` `CRUD /api/admin/classes` | Cấu trúc: faculty (1) → majors (N) → classes (N) → directory (N) |
| AD-04 ✅ | Quản lý hệ thống | Lưu trữ | `system_configs` | `system_configs`, (backup/restore: shell out) | `ADMIN` | `GET /api/admin/configs` `GET /api/admin/configs/{key}` `PATCH /api/admin/configs/{key}` `POST /api/admin/backup` (CLI wrapper) `POST /api/admin/restore` | ✅ **Resolved v03** — bảng `system_configs(config_key PK, config_value, value_type ENUM[INT/STRING/BOOL/JSON], description, is_sensitive, updated_by)`. Đã seed 11 config: OTP (timeout/length), upload (max_size/extensions), cancel (min_days), rating (allowed_after_finish), SMTP (host/port/user/password — sensitive), certificate (qr_verify_url_base) |
| AD-05 | Thống kê toàn hệ thống | Kết xuất, Tổng hợp | All business tables | — | `ADMIN` | `GET /api/admin/reports/system-summary` `GET /api/admin/reports/system-summary.xlsx` | — |
| AD-06 | Audit & kiểm soát | Tra cứu, Lưu trữ | `audit_logs`, `contest_reviews`, `notifications` | `audit_logs` (insert from middleware), `contest_reviews` (kiểm duyệt: is_visible, moderated_by, moderated_at) | `ADMIN` | `GET /api/admin/audit-logs?user_id=&action=&entity=&from=&to=` `GET /api/admin/anomaly-reports` `PATCH /api/admin/reviews/{id}/moderate` | `details_json JSONB` cho phép search linh hoạt. Kiểm duyệt review giờ đã implement được (cover bởi SV-11) |

---

## 6. Schema v03 changelog — 3 GAP đã giải quyết

Các bảng dưới đây đã được thêm vào `08-database/2026-05-04_sqlapp_v03.sql`:

| Gap (v02) | Resolved by (v03) | Bảng thêm | Liên quan chức năng |
|---|---|---|---|
| ✅ GAP-1: SV-11 thiếu chỗ lưu rating | `contest_reviews` | 1 bảng | SV-11 (write), AD-06 (moderate) |
| ✅ GAP-2: BCN-06 không có template + cert | `certificate_templates`, `issued_certificates` | 2 bảng | BCN-06 (write), SV-09 (download) |
| ✅ GAP-3: AD-04 thiếu chỗ lưu config | `system_configs` (+ enum `config_value_type_enum`) | 1 bảng | AD-04 (write), SV-08/SV-10/SV-11 (read) |

**Tổng:** 4 bảng mới + 1 enum + 7 index + 11 seed config.
**Schema size:** v02 có 39 bảng → v03 có 43 bảng.

Chi tiết DDL xem trong file SQL v03 hoặc xem ER diagram v02 (`08-database/2026-05-04_er-diagram_v02.mermaid`).

---

## 7. Hướng dẫn sử dụng matrix này

**Cho backend dev (FastAPI):**
- Cột "API endpoint" là spec router. Mỗi endpoint → 1 function trong `routers/{actor}.py`.
- Cột "RBAC" map vào `dependencies/auth.py` decorator.
- Cột "Bảng đọc/ghi" giúp viết `models/` và `schemas/` Pydantic.
- Lưu ý: bảng `system_configs` cần wrap trong helper `get_config(key)` để cast theo `value_type`.

**Cho frontend dev (Flutter):**
- Cột "Chức năng" + "RBAC" → routing render theo role.
- Cột "API endpoint" = source of truth cho `services/api_client.dart`.

**Cho QA / test:**
- Mỗi dòng = 1 user story. Đánh số TC-SV-01-01, TC-SV-01-02, ...
- Test workflow phê duyệt 2 cấp đặc biệt: cần test happy path + revision loop 1/2/3 lần + reject.

**Cho báo cáo CNPM:**
- Section phân tích yêu cầu: matrix coverage 30/30 + lịch sử resolve gap (v01 → v02).
- Section thiết kế: reference ER diagram v02 + SQL schema v03.

---

**Sources:**
- Requirements: `02-requirements/2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`
- Schema: `08-database/2026-05-04_sqlapp_v03.sql`
- ER diagram: `08-database/2026-05-04_er-diagram_v02.mermaid`
- Matrix v01 (history): `02-requirements/2026-05-04_traceability-matrix_v01.md`
