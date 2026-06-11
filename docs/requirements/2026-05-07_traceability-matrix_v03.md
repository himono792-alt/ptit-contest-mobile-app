# Ma trận Traceability: Chức năng ↔ Schema ↔ API ↔ UI

**Phiên bản:** v03 (2026-05-07) — bổ sung cột **UI status**
**Schema reference:** `ptit_contest` v03 — 43 bảng (xem `08-database/2026-05-04_sqlapp_v03.sql`)
**Requirements source:** `02-requirements/2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`
**Frontend source:** `09-implementation/frontend/lib/` (Flutter, Sprint 6 finished 2026-05-07)
**Thay đổi từ v02:** Thêm cột "UI status" với 3 trạng thái ✅/⚠/❌ + đường dẫn file Flutter; ghi chú policy SV-01 self-register; cập nhật 3 export xlsx + AD-04 Backup + AD-06 Anomaly đã có UI.

---

## 1. Tổng quan

| Actor | Mã | Số chức năng | Schema/API | UI deployed | Trạng thái |
|---|---|---|---|---|---|
| Sinh viên | SV | 11 | 11/11 | **11/11** | ✅ Full |
| Giảng viên / BTC | GV | 7 | 7/7 | **7/7** | ✅ Full |
| Ban Chủ nhiệm khoa | BCN | 6 | 6/6 | **6/6** | ✅ Full |
| Admin | AD | 6 | 6/6 | **6/6** | ✅ Full |
| **Tổng** | | **30** | **30/30** | **30/30** | ✅ **Full coverage** |

**Quy ước cột UI status:**

- ✅ — UI hoàn chỉnh, gọi đúng endpoint, đã test thủ công.
- ⚠ — UI có nhưng còn hạn chế (vd: chỉ hỗ trợ web không hỗ trợ mobile, hoặc chưa có happy-path nâng cao).
- ❌ — Chưa có UI, chỉ có schema + endpoint.

**Quy ước cột "Bảng đọc / Bảng ghi"**: chỉ liệt kê bảng nghiệp vụ chính. `audit_logs` được ghi ngầm cho mọi action có ảnh hưởng dữ liệu.
**RBAC**: theo `role_code` enum (`STUDENT`, `ORGANIZER`, `JUDGE`, `HOD`, `ADMIN`) + scope (`own` / `assigned` / `faculty`).

---

## 2. Sinh viên — 11 chức năng (Mã SV)

| Mã | Chức năng | API endpoint | UI status | UI file (Flutter) | Ghi chú |
|---|---|---|---|---|---|
| SV-01 | Đăng nhập / Đăng xuất | `POST /api/auth/login` `POST /api/auth/logout` | ✅ | `features/auth/login_screen.dart` + `core/auth/auth_provider.dart` | Có biometric login (refresh token). **Self-register tắt theo policy** — tài khoản SV cấp sẵn theo email @ptit.edu.vn (do trường), trường hợp ngoại lệ → GV/Admin tạo qua AD-02 |
| SV-02 | Quản lý thông tin cá nhân | `GET /api/me` `PATCH /api/me` `PATCH /api/me/password` `POST /api/auth/forgot-password` | ✅ | `features/student/profile_screen.dart` + `edit_profile_screen.dart` + `auth/forgot_password_*.dart` | OTP 6 chữ số config qua `system_configs` |
| SV-03 | Xóa tài khoản | `DELETE /api/me` | ✅ | `features/student/profile_screen.dart` (action "Xóa tài khoản" + confirm dialog) | Soft delete |
| SV-04 | Tìm kiếm và lọc cuộc thi | `GET /api/contests?q=&mode=&status=&faculty=` | ✅ | `features/student/contest_list_screen.dart` | Filter UI có q + status chips |
| SV-05 | Xem chi tiết cuộc thi | `GET /api/contests/{slug}` `GET /api/contests/{slug}/articles` `GET /api/contests/{slug}/reviews` | ✅ | `features/student/contest_detail_screen.dart` | Hiện rating trung bình + reviews |
| SV-06 | Đăng ký tham gia cuộc thi | `POST /api/contests/{id}/register/individual` `POST /api/contests/{id}/teams` `POST /api/teams/{id}/members` | ✅ | `features/student/register_screen.dart` + `team_management_screen.dart` | Tự switch flow individual/team theo `participation_mode` |
| SV-07 | Xác nhận đăng ký | (background trigger) | ✅ | `features/student/notifications_screen.dart` | Auto-trigger sau SV-06; deep-link tab 'Của tôi' |
| SV-08 | Nộp bài thi | `POST /api/rounds/{id}/submissions` `POST /api/submissions/{id}/versions` `POST /api/submissions/{id}/files` | ✅ | `features/student/submission_screen.dart` | Multi-version + file upload, validate size/extensions |
| SV-09 | Quản lý lịch sử tham gia | `GET /api/me/registrations` `GET /api/me/results` `GET /api/me/certificates/{contest_id}` | ✅ | `features/student/my_registrations_screen.dart` + `my_results_screen.dart` + `cert_verify_screen.dart` | Tải PDF chứng chỉ + verify QR public |
| SV-10 | Hủy đăng ký | `DELETE /api/contests/{id}/registration` | ✅ | `features/student/my_registrations_screen.dart` (action "Hủy") | Threshold ngày từ `system_configs.cancel.min_days_before` |
| SV-11 | Đánh giá cuộc thi | `POST/PATCH /api/contests/{id}/reviews` | ✅ | `features/student/review_dialog.dart` (entry từ contest_detail + my_results) | Rating 1-5 + comment, edit được sau khi đã review |

---

## 3. Giảng viên / Ban tổ chức — 7 chức năng (Mã GV)

| Mã | Chức năng | API endpoint | UI status | UI file (Flutter) | Ghi chú |
|---|---|---|---|---|---|
| GV-01 | Quản lý tài khoản giảng viên | `GET /api/me` `PATCH /api/me` `PATCH /api/me/password` | ✅ | `features/auth/login_screen.dart` + (chia sẻ profile_screen với SV) | Tài khoản GV do Admin tạo |
| GV-02 | Tạo và quản lý cuộc thi | `POST /api/contests` `PATCH/DELETE /api/contests/{id}` `POST /api/contests/{id}/rounds` `POST /api/contests/{id}/sessions` `POST /api/contests/{id}/submit-for-approval` | ✅ | `features/admin/admin_contests_screen.dart` + `create_contest_dialog.dart` + `contest_admin_detail_screen.dart` (tab Tổng quan + Vòng & Phiên) | Submit-for-approval workflow QĐ1 đầy đủ |
| GV-03 | Phê duyệt đăng ký thí sinh | `GET /api/contests/{id}/entries?status=PENDING` `PATCH /api/contests/{id}/entries/{entry_id}` | ✅ | `features/admin/contest_admin_detail_screen.dart` (tab Đăng ký) | Bulk approve/reject + registration_note |
| GV-04 | Quản lý bài thi | `GET /api/rounds/{id}/submissions` `GET /api/submissions/{id}` `GET /api/submission-files/{id}/download` `POST /api/submissions/{id}/lock` | ✅ | `features/admin/contest_admin_detail_screen.dart` (tab Đăng ký + Chấm điểm) | Auto-lock theo `submission_close_at` |
| GV-05 | Chấm bài và nhập điểm | `POST /api/contests/{id}/judges` `POST /api/rounds/{id}/judge-assignments` `GET /api/me/judge-assignments` `POST /api/assignments/{id}/scores` `POST /api/rounds/{id}/compute-results` | ✅ | `features/admin/contest_admin_detail_screen.dart` (tab Chấm điểm) + `judge_screen.dart` (judge tự chấm assignments của mình) | Rubric criteria + auto-compute round_results |
| GV-06 | Công bố kết quả | `POST /api/contests/{id}/results/compute` `POST /api/contests/{id}/results/submit-for-approval` `POST /api/contests/{id}/results/publish` | ✅ | `features/admin/contest_admin_detail_screen.dart` (tab Kết quả) | Publish CHỈ allowed khi BCN đã APPROVED |
| GV-07 | Thống kê và báo cáo | `GET /api/contests/{id}/stats` `GET /api/contests/{id}/report.xlsx` `GET /api/contests/{id}/results/export.xlsx` | ✅ | `features/admin/contest_admin_detail_screen.dart` (Tab Tổng quan: nút "Xuất báo cáo Excel"; Tab Kết quả: nút "4. Xuất Excel 4 sheets") + helper `core/xlsx_export_helper.dart` | **Sprint 6 (2026-05-07):** thêm nút report.xlsx đầy đủ |

---

## 4. Ban Chủ nhiệm khoa — 6 chức năng (Mã BCN)

| Mã | Chức năng | API endpoint | UI status | UI file (Flutter) | Ghi chú |
|---|---|---|---|---|---|
| BCN-01 | Đăng nhập / Đăng xuất | `POST /api/auth/login` `POST /api/auth/logout` `GET /api/me` | ✅ | `features/auth/login_screen.dart` | Tài khoản BCN do Admin tạo |
| BCN-02 | Phê duyệt đề xuất cuộc thi (BCN_QĐ1) | `GET /api/me/pending-approvals?type=CONTEST_PROPOSAL` `GET /api/approvals/{id}` `POST /api/approvals/{id}/decide` | ✅ | `features/admin/approval_queue_screen.dart` (filter `target_type=CONTEST_PROPOSAL`) | APPROVE / REQUEST_REVISION / REJECT đầy đủ |
| BCN-03 | Giám sát tiến độ cuộc thi | `GET /api/admin/contests/monitor` `GET /api/admin/contests/{id}/progress` | ✅ | `features/admin/monitor_screen.dart` | 3 progress bar: Đăng ký / Nộp bài / Chấm điểm |
| BCN-04 | Phê duyệt kết quả chung cuộc (BCN_QĐ2) | `GET /api/me/pending-approvals?type=CONTEST_RESULT` `POST /api/approvals/{id}/decide` | ✅ | `features/admin/approval_queue_screen.dart` (filter `target_type=CONTEST_RESULT`) | Sau khi APPROVE → BTC publish được |
| BCN-05 | Thống kê và báo cáo tổng hợp | `GET /api/reports/faculty-summary?faculty_id={own}&year={yyyy}` `GET /api/reports/faculty-summary.xlsx` | ✅ | `features/admin/admin_dashboard_screen.dart` (4 stats card cho HOD) + `monitor_screen.dart` (nút "Xuất Excel BCN-05") | **Sprint 6 (2026-05-07):** thêm nút export xlsx |
| BCN-06 | Xuất giấy chứng nhận / chứng chỉ | `POST /api/contests/{id}/certificates/templates` `PATCH /api/certificates/templates/{id}/approve` `PATCH /api/certificates/templates/{id}/activate` `POST /api/contests/{id}/certificates/issue` `GET /api/certificates/{cert_id}.pdf` `GET /verify/{qr_code}` (public) | ✅ | `features/admin/contest_admin_detail_screen.dart` (tab Chứng nhận) + SV download trong `my_results_screen.dart` + verify QR `cert_verify_screen.dart` | 1 contest = 1 active template (partial unique index) |

---

## 5. Admin — 6 chức năng (Mã AD)

| Mã | Chức năng | API endpoint | UI status | UI file (Flutter) | Ghi chú |
|---|---|---|---|---|---|
| AD-01 | Đăng nhập / Đăng xuất | `POST /api/auth/login` `POST /api/auth/logout` | ✅ | `features/auth/login_screen.dart` | Admin seed sẵn từ migration |
| AD-02 | Quản lý tài khoản | `GET /api/admin/users` `POST /api/admin/users` `PATCH /api/admin/users/{id}` `DELETE /api/admin/users/{id}` `POST /api/admin/users/{id}/lock` `PATCH /api/admin/users/{id}/roles` `POST /api/admin/students/import` | ✅ | `features/admin/admin_users_screen.dart` | CRUD đầy đủ + lock/unlock + bulk import SV (CSV) |
| AD-03 | Quản lý khoa / ngành | `CRUD /api/admin/faculties` `CRUD /api/admin/majors` `CRUD /api/admin/classes` | ✅ | `features/admin/master_data_screen.dart` (3 tab) | Hierarchy faculty → majors → classes |
| AD-04 | Quản lý hệ thống | `GET /api/admin/configs` `PATCH /api/admin/configs/{key}` `POST /api/admin/backup` `POST /api/admin/restore` | ⚠ | `features/admin/configs_screen.dart` (list configs + sửa value + nút "Tạo backup ngay") | **Sprint 6 (2026-05-07):** thêm `_BackupRestoreCard`. Backup full UI; Restore chỉ show hướng dẫn CLI cho DBA (an toàn hơn upload binary qua HTTP) |
| AD-05 | Thống kê toàn hệ thống | `GET /api/admin/reports/system-summary` `GET /api/admin/reports/system-summary.xlsx` | ✅ | `features/admin/admin_dashboard_screen.dart` (4 stats card cho ADMIN + nút "Xuất Excel AD-05") | **Sprint 6 (2026-05-07):** thêm nút export xlsx |
| AD-06 | Audit & kiểm soát | `GET /api/admin/audit-logs?user_id=&action=&entity=&from=&to=` `GET /api/admin/anomaly-reports` `PATCH /api/admin/reviews/{id}/moderate` | ✅ | `features/admin/audit_log_screen.dart` (audit) + `review_moderation_screen.dart` (moderate review) + `anomaly_reports_screen.dart` (anomaly) | **Sprint 6 (2026-05-07):** thêm `AnomalyReportsScreen` với filter severity HIGH/MEDIUM/LOW |

---

## 6. Sprint 6 (2026-05-07) — Changelog

UI/feature lift để cover 100% matrix:

| Việc | File mới / sửa | Liên quan |
|---|---|---|
| Helper `exportXlsxFromEndpoint` | `core/xlsx_export_helper.dart` (mới) | Reuse cho 3 export xlsx |
| Nút export GV-07 contest report | `features/admin/contest_admin_detail_screen.dart` (Workflow card) | GV-07 |
| Nút export BCN-05 faculty summary | `features/admin/monitor_screen.dart` (top bar) | BCN-05 |
| Nút export AD-05 system summary | `features/admin/admin_dashboard_screen.dart` (top bar, ADMIN-only) | AD-05 |
| Card Backup/Restore | `features/admin/configs_screen.dart` (`_BackupRestoreCard`) | AD-04 |
| Màn Anomaly reports | `features/admin/anomaly_reports_screen.dart` (mới) + entry trong `admin_shell.dart` | AD-06 |
| Migrate `0xFFFAFAFA` → `context.appBg` | 13 instance trong 11 admin screens | UI design system / dark mode consistency |
| Policy ghi chú SV-01 | Bảng SV-01 cột "Ghi chú" | Self-register tắt; account do trường cấp |

---

## 7. Hướng dẫn sử dụng matrix này

**Cho backend dev (FastAPI):**
- Cột "API endpoint" là spec router. Mỗi endpoint → 1 function trong `routers/{actor}.py`.
- Cột "RBAC" map vào `dependencies/auth.py` decorator.
- Cột "Bảng đọc/ghi" giúp viết `models/` và `schemas/` Pydantic.
- Lưu ý: bảng `system_configs` cần wrap trong helper `get_config(key)` để cast theo `value_type`.

**Cho frontend dev (Flutter):**
- Cột "UI file" là source of truth — 1 chức năng = 1-3 file Dart cụ thể.
- Cột "API endpoint" map sang `services/api_client.dart` calls.
- Helper xuất Excel: `core/xlsx_export_helper.dart` cho mọi endpoint trả binary xlsx.

**Cho QA / test:**
- Mỗi dòng = 1 user story. Đánh số TC-SV-01-01, TC-SV-01-02, ...
- Test workflow phê duyệt 2 cấp đặc biệt: cần test happy path + revision loop 1/2/3 lần + reject.
- 3 export xlsx mới cần test trên web (download trigger blob) — mobile sẽ fallback message.

**Cho báo cáo CNPM:**
- Section phân tích yêu cầu: matrix coverage 30/30 + 30/30 UI deployed.
- Section thiết kế: reference ER diagram v02 + SQL schema v03.
- Section implementation: lifecycle Sprint 1-6 với deliverables theo bảng changelog phần 6.

---

**Sources:**

- Requirements: `02-requirements/2026-05-03_app-qly-cuoc-thi-sv-ptit_v01.docx`
- Schema: `08-database/2026-05-04_sqlapp_v03.sql`
- ER diagram: `08-database/2026-05-04_er-diagram_v02.mermaid`
- Frontend: `09-implementation/frontend/lib/`
- Matrix v02 (history): `02-requirements/2026-05-04_traceability-matrix_v02.md`
