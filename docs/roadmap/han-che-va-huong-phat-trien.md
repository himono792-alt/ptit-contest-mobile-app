# Hạn chế và hướng phát triển

**Dự án:** Hệ thống Quản lý Cuộc thi Sinh viên PTIT
**Phiên bản tài liệu:** v2.0 (cập nhật 2026-06-16)
**Stack:** FastAPI + PostgreSQL 16 + Flutter (Web + APK Android)
**Mô hình triển khai hiện tại:** Docker Compose clone-and-run (chạy local). Bản triển khai cloud (Railway + Cloudflare Pages) đã **ngừng từ 2026-06-11** — chuyển sang demo offline bằng Docker để chấm/bảo vệ.

> **Lưu ý đọc:** Bản v1.0 (2026-05-06) của tài liệu này liệt kê nhiều hạn chế nay **đã khắc phục** (rate limit, refresh token, dark mode, skeleton, Excel export, email thật, file storage, test backend...). Mục 2 bên dưới tổng hợp các mục đã đóng; mục 3 chỉ còn các hạn chế **thực sự đang tồn tại**.

---

## 1. Phạm vi đã hoàn thành

### 1.1 Backend (FastAPI)

- **116 endpoints** REST qua 16 router module.
- **44 bảng** PostgreSQL (43 bảng baseline trong `init-schema.sql` v04 + `faculty_cert_templates` thêm qua **Alembic migration `0002`**) + **19 ENUM types**, ánh xạ 1-1 với SQLAlchemy 2.0 async.
- **JWT (access 60p) + refresh token (7 ngày)** + RBAC 5 role (STUDENT, ORGANIZER, JUDGE, HOD, ADMIN).
- Workflow phê duyệt 2 cấp BTC↔BCN: QĐ1 (đề xuất) + QĐ2 (kết quả) + QĐ3 (template chứng nhận).
- Audit middleware (pure ASGI) tự ghi mọi request mutating vào `audit_logs`.
- **Rate limiting** (slowapi) trên endpoint nhạy cảm (login, OTP, forgot-password).
- **Email thật** qua Brevo HTTP API (port 443) — password reset, welcome, OTP, mirror notification. Dual-mode `console`/`brevo`.
- **Cloudflare R2** (S3-compatible) cho lưu file bài nộp.
- **Export Excel** (openpyxl) cho báo cáo khoa / hệ thống.
- **Bulk notification khi publish kết quả** — tạo notification + deep-link cho mọi SV đăng ký APPROVED (thêm 2026-06-16).
- **Sentry** error tracking + performance (FE + BE).
- **Bộ test pytest** — 26 test (auth/RBAC, contest, workflow, publish-notification) chạy với Postgres nhúng `pgserver`, không cần Docker/DB ngoài (thêm 2026-06-16).

### 1.2 Frontend (Flutter)

- 1 codebase, 2 build target: APK Android (~25 MB) + Flutter Web.
- Responsive: SV web sidebar (≥900px) / mobile bottom-nav; admin breakpoint riêng.
- **Dark mode** đầy đủ (token theme sáng/tối) + nút toggle (SV/GV/BCN/Admin).
- **Loading skeleton** (shimmer theme-aware) thay cho spinner đơn.
- Giao diện theo actor: SV (Home/Cuộc thi/Của tôi/Kết quả/Lịch/Chứng nhận/Thông báo/Tôi), GV/BTC, BCN, Admin — dashboard giàu (stat cards, donut chart, activity feed, leaderboard podium).
- **Đăng ký theo đội (TEAM)** có UI (`team_management_screen.dart`) — tạo đội, thêm thành viên, đăng ký đội.
- State: Riverpod 2.6 autoDispose. Routing: go_router 14.

### 1.3 Triển khai

- Docker Compose clone-and-run (`docker compose up`) → backend + Postgres + seed demo đầy đủ (2 khoa, SV/GV/BCN/Admin, cuộc thi mẫu chạy đủ workflow).
- Web client viewer DB (DBGate) kèm trong compose để xem dữ liệu.

---

## 2. Các hạn chế v1.0 đã khắc phục

| Hạn chế (v1.0) | Trạng thái | Cách khắc phục |
|---|---|---|
| Đăng ký theo đội chỉ có ở backend | ✅ Đã làm | `team_management_screen.dart` nối vào luồng đăng ký |
| Email service "dev mode" trả token | ✅ Đã làm | Brevo HTTP API + template Jinja2 |
| Bulk notification khi publish kết quả (TODO) | ✅ Đã làm (2026-06-16) | `publish_results` tạo notification thật + deep-link |
| Không có refresh token | ✅ Đã làm | `/auth/refresh` + rotate (7 ngày) |
| Không có rate limiting | ✅ Đã làm | slowapi trên login/OTP/forgot-password |
| File upload bài nộp không có storage | ✅ Backend xong | Cloudflare R2 (endpoint upload riêng) |
| Migration chỉ ALTER ở startup | ✅ Một phần | Alembic dùng thật cho thay đổi mới (migration `0002`) |
| Không có dark mode | ✅ Đã làm | Theme sáng/tối + toggle |
| Không có loading skeleton | ✅ Đã làm | Shimmer theme-aware |
| Không có export Excel | ✅ Đã làm | openpyxl báo cáo khoa/hệ thống |
| Không có unit test backend | ✅ Đã làm (2026-06-16) | pytest 26 test + Postgres nhúng |
| Không có monitoring | ✅ Một phần | Sentry FE + BE (chưa có Prometheus/Grafana) |
| Analytics dashboard chỉ 4 con số | ✅ Một phần | Donut chart, real-time stats, activity feed |
| Tìm kiếm chỉ theo title (ILIKE) | ✅ Đã làm (2026-06-16) | Full-text search title/mô tả/thể lệ/giải thưởng + GIN index + ranking |
| Hủy đăng ký không kiểm tra thời gian (TODO) | ✅ Đã làm (2026-06-16) | Enforce `cancel.min_days_before` trước ngày thi |
| Không ẩn/hiện review hàng loạt | ✅ Đã làm (2026-06-16) | Endpoint `PATCH /admin/reviews/bulk-moderate` |
| Không khóa/xóa user hàng loạt | ✅ Đã làm (2026-06-16) | Endpoint `POST /admin/users/bulk-status` (LOCK/UNLOCK/DELETE) |
| Không có CI/CD | ✅ Một phần (2026-06-16) | GitHub Actions chạy `pytest` + ruff mỗi PR (chưa auto-deploy) |

---

## 3. Hạn chế hiện tại

### 3.1 Chức năng

- **Quét QR bằng camera:** `CertVerifyScreen` chỉ cho paste mã thủ công, chưa tích hợp `mobile_scanner` dù icon là `qr_code_scanner` (lệch giữa thiết kế và thực tế).
- **Phân trang:** dùng `?page&size`, chưa có infinite scroll — UX kém khi data lớn.

### 3.2 Kỹ thuật

- **CI chạy test đã có, deploy còn thủ công:** GitHub Actions (`backend-tests.yml`) chạy `pytest` mỗi PR; chưa có auto-deploy (do đã chuyển demo Docker local).
- **Test frontend mới ở mức cơ bản:** đã thêm unit + widget test (model parsing, Pill, EmptyView); chưa có golden test (cần sinh baseline) và integration test luồng chính.
- **Chưa load test:** chưa benchmark response time ở mức tải cao (locust/k6).
- **Audit middleware pool nhỏ:** insert log đồng bộ trong request; tải cao nên chuyển background queue.
- **Monitoring nâng cao:** đã có Sentry nhưng chưa có metrics (Prometheus/Grafana) / log aggregation.
- **CORS regex còn rộng** + token web fallback `localStorage` khi chạy HTTP LAN (XSS đọc được) — chấp nhận được cho demo local, production cần whitelist chính xác + HTTPS.

### 3.3 UX/UI

- **Chưa đa ngôn ngữ (i18n):** label cứng tiếng Việt; cần `flutter_localizations` + ARB.
- **Chưa có Undo:** action xóa/hủy không hoàn tác được.
- **Bottom nav nhiều tab** hơi chật trên màn nhỏ.

---

## 4. Hướng phát triển

### 4.1 Ngắn hạn (1-2 tuần) — P1

- **Mở rộng CI:** thêm build APK artifact + lint dart analyze (đã có job `pytest` + ruff). *(~1 ngày.)*
- **QR scan camera:** `mobile_scanner` cho APK, fallback nhập tay trên web. *(~1-2 ngày.)*
- **Mở rộng test frontend:** thêm golden test (baseline) + integration test luồng đăng ký/nộp bài (đã có unit + widget test cơ bản). *(~2 ngày.)*
- **Nối file upload vào luồng nộp version chính** (dùng R2 đã có). *(~1-2 ngày.)*

### 4.2 Trung hạn (1-3 tháng) — P2

- **Real-time notification (WebSocket):** push khi BCN duyệt / kết quả công bố.
- **Push notification (FCM)** cho APK.
- **Đa ngôn ngữ (i18n)** Việt/Anh.
- **Analytics nâng cao:** chart time-series (đăng ký theo ngày, bài nộp theo vòng), filter audit log.
- **Load test + tối ưu:** k6/locust, Redis cache cho `/contests`.

### 4.3 Dài hạn (6-12 tháng) — P3

- Tích hợp SSO + cổng đào tạo PTIT (auto-import sinh viên, cộng điểm rèn luyện).
- AI features: auto-grading, phát hiện đạo bài, gợi ý cuộc thi.
- Cuộc thi dạng bracket/round-robin/Swiss.
- Đưa app lên Google Play / App Store.
- Cân nhắc tách microservices khi scale lớn.

---

## 5. Kết luận

Dự án đã hoàn thành đầy đủ matrix chức năng với **116 endpoint backend**, **44 bảng**, workflow phê duyệt 2 cấp, và đã **đóng gần hết các hạn chế của bản v1.0** (rate limit, refresh token, email thật, file storage, dark mode, skeleton, Excel export, bulk notification, và bộ test backend).

Các hạn chế còn lại chủ yếu là **nâng cao trải nghiệm và quy trình kỹ thuật** (CI/CD, test frontend, QR scan, real-time, i18n) chứ không còn blocker chức năng. Với mô hình demo Docker clone-and-run hiện tại, hệ thống chạy trọn vẹn offline để chấm/bảo vệ. Ưu tiên hợp lý tiếp theo là **CI/CD + bổ sung test frontend** để củng cố chất lượng, sau đó tới các tính năng nâng cao trung hạn.

---

**Người chuẩn bị tài liệu:** Nhóm CNPM
**Ngày cập nhật:** 2026-06-16
**Phiên bản:** 2.0
