# Hạn chế và hướng phát triển

**Dự án:** Hệ thống Quản lý Cuộc thi Sinh viên PTIT
**Phiên bản hiện tại:** v1.0 (2026-05-06)
**Stack:** FastAPI + PostgreSQL (Railway) + Flutter Web (Netlify) + Flutter APK Android
**Live URL:** https://luxury-crostata-3c5c69.netlify.app

---

## 1. Tóm tắt phạm vi đã hoàn thành

Để đánh giá đúng hạn chế, cần đối chiếu với phạm vi đã làm được.

### 1.1 Backend (FastAPI)

- 96 endpoints REST chia theo 14 router (auth, users, contests, approvals, entries, teams, submissions, judging, results, reviews, notifications, certificates, reports, admin).
- 43 bảng SQLAlchemy 2.0 async khớp 1-1 với schema SQL v03 (43 tables).
- JWT auth (HS256, 8h) + RBAC 5 role (STUDENT, ORGANIZER, JUDGE, HOD, ADMIN).
- Workflow phê duyệt 2 cấp BTC↔BCN: QĐ1 (đề xuất cuộc thi) + QĐ2 (kết quả) + QĐ3 (template chứng nhận).
- Audit middleware tự động ghi mọi request mutating vào `audit_logs` (pure ASGI, separate engine pool 2 conn).
- Idempotent migration `ALTER TABLE ADD COLUMN IF NOT EXISTS` ở startup cho 9 trường profile mở rộng.

### 1.2 Frontend (Flutter)

- 1 codebase, 2 build target: APK Android (~23 MB) + Flutter Web (~2.8 MB main.dart.js).
- Responsive: SV web wide (≥900 px) chuyển sang sidebar layout. Admin web mobile (<768 px hoặc native APK) chuyển sang bottom nav + drawer.
- 18 màn cốt lõi: 6 SV mobile (Trang chủ, Cuộc thi, Của tôi, Kết quả, Thông báo, Tôi) + 9 admin (Dashboard, Cuộc thi, Phê duyệt, Giám sát, Chấm bài, Quản lý user, Khoa/Ngành, Bình luận, Cấu hình, Audit log) + ContestAdminDetailScreen 6 tab + EditProfileScreen 11 fields + ForgotPassword 2 screens.
- State: Riverpod 2.6 với autoDispose providers. Routing: go_router 14.
- Token storage: dual-mode (Flutter Secure Storage trên mobile, dart:html localStorage trên web qua conditional import).

### 1.3 Triển khai

- Backend: Railway (PostgreSQL + container) — https://ptit-contest-mobile-app-production.up.railway.app
- Frontend Web: Netlify (drag-drop build/web, SPA fallback `_redirects`).
- APK: build local — `build/app/outputs/flutter-apk/app-release.apk`.
- Demo data sẵn 3 role + 5 contest + 1 entry đã chạy đủ workflow QĐ1+QĐ2+QĐ3.

---

## 2. Hạn chế hiện tại

### 2.1 Hạn chế về chức năng

#### 2.1.1 Đăng ký theo đội (TEAM registration)

Backend đã có 4 endpoint cho team (`POST /contests/{id}/teams`, `POST /teams/{id}/members`, `POST /contests/{id}/register/team`, `GET /teams/{id}`) nhưng UI Flutter chỉ implement đăng ký cá nhân. Khi sinh viên mở contest có `participation_mode=TEAM`, màn đăng ký hiển thị thông báo "chức năng tạo team chưa implement trên mobile". Đây là gap nghiêm trọng nhất vì các cuộc thi như Hackathon thường yêu cầu đội 3-5 người.

#### 2.1.2 Quét QR camera

`CertVerifyScreen` chỉ cho phép paste mã QR thủ công, chưa tích hợp camera để scan QR thật. Trong khi đó icon trên màn là `Icons.qr_code_scanner` gợi ý có scan camera. UX bất nhất giữa thiết kế và implement.

#### 2.1.3 Email service thật

Endpoint `POST /auth/forgot-password` hiện hoạt động ở "dev mode" — trả thẳng `dev_reset_token` trong response để frontend auto-fill. Khi production phải tích hợp email provider (SendGrid, Mailgun, hoặc SMTP nội bộ PTIT) để gửi link reset thật. Tương tự, các notification quan trọng (BCN duyệt cuộc thi, kết quả công bố) hiện chỉ insert vào bảng `notifications`, không có push notification hay email gửi tới user.

#### 2.1.4 Bulk notification khi publish results

`POST /contests/{id}/results/publish` trả về `notified_count: 0` với comment `TODO: thêm bulk notification thật`. Khi BTC publish kết quả, hệ thống không tự động tạo notification cho tất cả các SV đã đăng ký. Họ phải tự mở "Của tôi" để biết kết quả.

#### 2.1.5 Notification deep-link

Tap vào 1 thông báo trong `NotificationsScreen` hiện chỉ mark-read mà không deep-link tới resource liên quan (entry, submission, result, certificate). UX kém so với kỳ vọng người dùng quen với app như Gmail / Slack.

#### 2.1.6 Submission file upload

Form nộp bài ở `SubmissionScreen` chỉ hỗ trợ external link (Google Drive, GitHub) + text answer, chưa cho upload file trực tiếp lên server. Backend cũng không có S3/MinIO storage. Với cuộc thi có quy định "nộp file PDF báo cáo" thì phải dùng đường vòng qua Drive.

#### 2.1.7 Search nâng cao

Tìm kiếm cuộc thi (`/contests?q=...`) chỉ match trên `title` qua SQL `ILIKE`. Không có:
- Full-text search (Postgres `tsvector` hoặc Elasticsearch).
- Filter ghép nhiều tiêu chí (theo khoa + thời gian + delivery_mode).
- Tìm theo nội dung mô tả, rules, awards.
- Sắp xếp theo độ liên quan (relevance ranking).

#### 2.1.8 Phân trang infinite scroll

Hầu hết list dùng pagination kiểu `?page=1&size=50` với UI hiển thị toàn bộ dữ liệu trong 1 trang. Khi data tăng (vd 1000+ contests), UX kém. Cần infinite scroll hoặc pagination với nút Next/Prev.

### 2.2 Hạn chế về kỹ thuật

#### 2.2.1 Migration quản lý đơn giản

Hiện dùng ALTER TABLE idempotent ở startup cho thay đổi schema mới (9 trường profile). Cách này dễ bug khi:
- Migration phức tạp hơn (đổi tên cột, đổi kiểu dữ liệu).
- Nhiều instance backend chạy song song (race condition khi cùng ALTER).
- Cần rollback xuống version cũ.

Đúng pattern là dùng Alembic (đã có sẵn trong dự án nhưng không thực sự sử dụng cho thay đổi gần đây).

#### 2.2.2 Audit middleware single-pool

Audit middleware dùng 1 engine pool tách riêng (2 connections) để insert log. Khi traffic tăng, pool 2 conn trở thành bottleneck. Cách tốt hơn: dùng background queue (Celery + Redis) hoặc fire-and-forget với write-ahead log.

#### 2.2.3 Không có rate limiting

Các endpoint nhạy cảm (POST /auth/login, POST /auth/forgot-password) không có rate limiting. Kẻ tấn công có thể brute-force password hoặc spam reset email. Cần `slowapi` hoặc Redis-based rate limit.

#### 2.2.4 JWT không có refresh token

JWT hết hạn 8h. Khi hết hạn user bị buộc đăng nhập lại, không có refresh token để rolling renewal. UX kém với app mobile mở suốt ngày.

#### 2.2.5 Không có CSRF protection

Backend chấp nhận JWT trong header `Authorization: Bearer`. Cookie-based session sẽ cần CSRF token nhưng vì dùng header nên không thiếu. Tuy nhiên CORS regex hiện cho phép `*.netlify.app` + `*.vercel.app` + `*.up.railway.app` — nếu attacker tạo subdomain trên các domain này có thể attack. Cần whitelist chính xác.

#### 2.2.6 Token web fallback localStorage

Trên Flutter web khi truy cập qua HTTP IP LAN (không HTTPS), Service Worker bị disable nên `flutter_secure_storage` không hoạt động. Đã fallback về `dart:html localStorage` nhưng kém bảo mật hơn (XSS có thể đọc token). Production bắt buộc HTTPS.

#### 2.2.7 Không có monitoring / alerting

Backend không có:
- Application Performance Monitoring (Sentry, DataDog).
- Health check endpoint chi tiết (chỉ có `/health` trả `{status: ok}`).
- Metrics (Prometheus / Grafana).
- Log aggregation (ELK, Loki).

Khi production có lỗi, dev team phải SSH vào Railway xem log raw.

#### 2.2.8 Không có CI/CD tự động

Deploy hiện thủ công:
- Backend: `git push` lên GitHub → Railway auto deploy.
- Frontend Web: `flutter build web` local → drag-drop folder vào Netlify UI.
- APK: `flutter build apk` local → copy file qua điện thoại.

Cần GitHub Actions workflow:
- Auto test backend trước khi merge PR.
- Auto build APK + upload artifact.
- Auto deploy frontend qua Netlify CLI từ CI.

### 2.3 Hạn chế về UX/UI

#### 2.3.1 Không có dark mode

Toàn app chỉ có 1 theme sáng (PTIT brand red + warm bg `#FAF8F5`). Người dùng quen dùng dark mode buổi tối sẽ thấy chói.

#### 2.3.2 Không đa ngôn ngữ

Tất cả label cứng tiếng Việt. Không hỗ trợ tiếng Anh cho sinh viên quốc tế. Cần `flutter_localizations` + ARB files.

#### 2.3.3 Không có loading skeleton

Các màn loading hiển thị `CircularProgressIndicator` đơn lẻ giữa màn. Đẹp hơn là dùng skeleton screen mô phỏng layout chuẩn (như Facebook / LinkedIn).

#### 2.3.4 Không có undo

Các action xóa / hủy đăng ký không có undo. Click nhầm là mất luôn. Có thể dùng SnackBar "Đã hủy đăng ký · Hoàn tác" trong 5 giây.

#### 2.3.5 Bottom nav 6 tabs hơi chật trên màn nhỏ

Trên iPhone SE / điện thoại 4.7" thì bottom nav 6 tabs làm label bị cắt. Có thể giảm xuống 5 tab + đẩy 1 tab vào FAB.

### 2.4 Hạn chế về testing

#### 2.4.1 Không có unit test backend

Code backend không có test (thư mục `backend/tests/` rỗng). Verify chủ yếu qua Chrome MCP E2E trên dev server. Khi refactor, không có test để bắt regression.

#### 2.4.2 Không có integration test Flutter

Flutter cũng không có test. Mọi feature verify qua manual trên web + APK. Không có Flutter widget test, integration test hay golden test.

#### 2.4.3 Không có load test

Backend chưa benchmark performance. Không biết với 1000 user truy cập đồng thời thì response time như thế nào. Cần `locust` hoặc `k6` chạy load test.

### 2.5 Hạn chế về quản trị

#### 2.5.1 Không có dashboard analytics

Admin dashboard hiện chỉ hiển thị 4 con số đơn giản (tổng users, tổng contests, bài nộp, certs). Không có biểu đồ thống kê theo thời gian, theo khoa, theo loại cuộc thi. Quyết định kinh doanh khó đưa ra với data raw như vậy.

#### 2.5.2 Không có bulk operation

Admin moderation review chỉ ẩn/hiện từng review một. Khi spam ồ ạt cần ẩn 50+ review không có "Select all → Hide selected". Tương tự với users CRUD.

#### 2.5.3 Không có export Excel

Báo cáo (faculty summary, contest stats) chỉ hiển thị trong UI, không có nút Export Excel/PDF. BCN cần in báo cáo cuối kỳ phải copy thủ công.

#### 2.5.4 Không có audit search/filter

Audit log có hiển thị nhưng không có filter theo user_id, action_type, time range. Khi điều tra sự cố phải scroll hết bảng.

---

## 3. Hướng phát triển

Sắp xếp theo độ ưu tiên giảm dần (P0 = blocker production, P3 = nice-to-have):

### 3.1 Ngắn hạn (1-2 tháng) — P0/P1

#### 3.1.1 Hoàn thành TEAM registration UI [P0]

- Tạo `team_management_screen.dart` cho SV: tạo team, mời member qua email/MSV, accept/decline invitation.
- Cập nhật `register_screen.dart` để route đúng team flow khi contest team-mode.
- Backend đã đủ endpoint, chỉ cần frontend.
- **Effort**: 1-2 ngày.

#### 3.1.2 Email service production [P0]

- Tích hợp SendGrid (free tier 100 email/ngày) hoặc SMTP của PTIT.
- Endpoint `forgot-password` gửi email link thật thay vì trả token trong response.
- Bulk notification khi publish results: queue email cho tất cả SV đã đăng ký.
- **Effort**: 2-3 ngày.

#### 3.1.3 File upload submission [P1]

- Tích hợp S3 (AWS) hoặc Cloudflare R2 (free tier 10GB).
- Backend endpoint `POST /submissions/{id}/upload` với multipart form data.
- Generate signed URL cho file private (chỉ judge + SV chính chủ download).
- Frontend `submission_screen.dart` thêm `FilePicker` widget.
- **Effort**: 3-4 ngày.

#### 3.1.4 Refresh token [P1]

- Backend trả thêm `refresh_token` (30 ngày) khi login.
- Endpoint `POST /auth/refresh` để renew access token.
- Frontend interceptor: khi nhận 401, gọi refresh trước khi retry request.
- **Effort**: 1-2 ngày.

#### 3.1.5 Rate limiting [P1]

- Tích hợp `slowapi` hoặc `fastapi-limiter` với Redis backend (Railway có Redis plugin).
- Áp dụng cho endpoint nhạy cảm: login (5/min/IP), forgot-password (3/hour/IP), register (3/hour/IP).
- **Effort**: 1 ngày.

### 3.2 Trung hạn (3-6 tháng) — P1/P2

#### 3.2.1 Real-time notification (WebSocket) [P2]

- Backend WebSocket endpoint `/ws/notifications` để push real-time.
- Khi BCN approve/reject, SV nhận noti ngay không cần refresh.
- Tăng UX engagement đáng kể.
- **Effort**: 1 tuần (gồm reconnection logic, scaling với multiple instances).

#### 3.2.2 QR scan camera [P2]

- Tích hợp `mobile_scanner` package vào `cert_verify_screen.dart`.
- Trên web dùng `qr_code_scanner` hoặc fallback nhập tay.
- **Effort**: 1-2 ngày.

#### 3.2.3 Push notification (FCM) [P2]

- Tích hợp Firebase Cloud Messaging cho APK.
- Backend gửi noti qua FCM Admin SDK khi có event quan trọng.
- iOS cần Apple Push Notification Service (APN) — phức tạp hơn.
- **Effort**: 1 tuần.

#### 3.2.4 Full-text search [P2]

- Postgres `tsvector` cho cột `title` + `description` + `rules_text`.
- Index GIN, query với `to_tsquery('vietnamese', 'keyword')`.
- Hoặc dùng Meilisearch (open source, đơn giản hơn Elasticsearch).
- **Effort**: 3-4 ngày.

#### 3.2.5 Analytics dashboard với chart [P2]

- Tích hợp `fl_chart` hoặc `syncfusion_flutter_charts` cho Flutter web.
- Backend endpoint trả time-series data (registrations theo ngày, submissions theo round).
- Admin dashboard có line chart, bar chart, pie chart.
- **Effort**: 1 tuần.

#### 3.2.6 Export Excel / PDF [P2]

- Backend dùng `openpyxl` (đã có) để export Excel báo cáo.
- PDF dùng `weasyprint` (Python) hoặc `pdfkit`.
- Frontend nút "Tải báo cáo Excel" trong report screen.
- **Effort**: 3-4 ngày.

#### 3.2.7 Internationalization (i18n) [P2]

- Tích hợp `flutter_localizations` + `intl` ARB files.
- Tạo file `app_vi.arb` (tiếng Việt) + `app_en.arb` (tiếng Anh).
- Switch ngôn ngữ trong Profile.
- **Effort**: 1 tuần (rất nhiều string cần extract).

### 3.3 Dài hạn (6-12 tháng) — P2/P3

#### 3.3.1 Microservices migration [P3]

Hiện tại là monolith FastAPI. Khi scale lên 50k user, cân nhắc tách:
- `auth-service` (login, JWT, RBAC).
- `contest-service` (CRUD contests, rounds).
- `judging-service` (rubric, scores, results — CPU intensive).
- `notification-service` (email, push, WebSocket).

Communicate qua message queue (RabbitMQ / Kafka).

**Effort**: 3-6 tháng.

#### 3.3.2 AI-powered features [P3]

- **Auto-grading**: dùng LLM (OpenAI / Claude) để chấm điểm bài luận, code review.
- **Plagiarism detection**: so sánh bài nộp giữa các SV để phát hiện sao chép.
- **Smart matching**: gợi ý cuộc thi phù hợp với SV dựa trên history (collaborative filtering).
- **Chatbot hỗ trợ**: AI assistant trả lời câu hỏi SV về thể lệ cuộc thi.

**Effort**: 3-6 tháng cho mỗi feature.

#### 3.3.3 Tích hợp hệ thống PTIT [P3]

- SSO với hệ thống đăng nhập trung tâm PTIT (CAS / OAuth2).
- Đồng bộ student_directory với cổng đào tạo PTIT (auto-import sinh viên mới).
- Tích hợp với hệ thống điểm số PTIT (cộng điểm rèn luyện cho SV thắng cuộc thi).
- API webhook cho các module PTIT khác.

**Effort**: 2-3 tháng (phụ thuộc vào hợp tác PTIT).

#### 3.3.4 Mobile app store deployment [P3]

- Đăng ký Google Play Console ($25 lifetime) + Apple Developer Program ($99/năm).
- Build iOS app (cần Mac).
- Quy trình review của Apple/Google (1-2 tuần).
- Update CI/CD để auto deploy lên store khi merge main.

**Effort**: 1-2 tháng.

#### 3.3.5 Cuộc thi dạng tournament / bracket [P3]

Hiện chỉ hỗ trợ cuộc thi dạng "single round" hoặc "multi-round eliminate". Có thể mở rộng:
- Bracket tournament (8/16/32 đội đấu loại trực tiếp).
- Round-robin (mỗi đội đấu với mọi đội khác).
- Swiss-system (như cờ vua).

Cần thiết kế thêm bảng `matches`, UI bracket visualization.

**Effort**: 2 tháng.

### 3.4 Cải thiện chất lượng — P1 (xuyên suốt)

#### 3.4.1 Test coverage

- Backend: pytest + httpx async client. Mục tiêu coverage ≥80%.
- Frontend: Flutter widget test cho component, integration test cho user flow chính.
- E2E: Playwright cho web, Appium cho APK.

#### 3.4.2 CI/CD pipeline

- GitHub Actions: lint + test trên PR, auto deploy backend/frontend trên main.
- Codecov badge trên README.
- Pre-commit hook: black, ruff (Python), dart format, dart analyze.

#### 3.4.3 Documentation

- API docs auto-generate từ OpenAPI (có sẵn ở `/api/docs`).
- Architecture doc với C4 model diagram.
- Onboarding guide cho dev mới.
- User manual cho SV/GV/BCN/Admin.

#### 3.4.4 Security hardening

- Penetration test định kỳ.
- OWASP Top 10 checklist.
- HTTPS-only (HSTS header).
- Content Security Policy (CSP) headers.
- Audit log với immutability (append-only).

#### 3.4.5 Performance optimization

- Database query với `EXPLAIN ANALYZE` để tìm slow query.
- Redis cache cho `/contests` list (TTL 30s).
- CDN cho static assets (Cloudflare).
- Image optimization (WebP, lazy load).
- Bundle size Flutter web (hiện ~2.8 MB).

---

## 4. Kết luận

Dự án PTIT Contest Management v1.0 đã hoàn thành **30/30 chức năng** trong matrix yêu cầu, triển khai full-stack lên cloud (Railway + Netlify + APK) với **96 endpoint backend** + **18 màn frontend** + **workflow phê duyệt 2 cấp** (QĐ1+QĐ2+QĐ3) chạy ổn định E2E.

Tuy nhiên vẫn còn **3 hạn chế nghiêm trọng** (TEAM registration UI, email service, file upload) và **các hạn chế về kỹ thuật** (test coverage, CI/CD, monitoring) cần khắc phục trước khi đưa vào production thật.

Hướng phát triển ngắn hạn ưu tiên hoàn thiện 5 P0/P1 items (TEAM, email, upload, refresh token, rate limit) — ước tính **2-3 tuần** với 1 dev full-time. Trung hạn cần **2-3 tháng** để có WebSocket, push notification, full-text search, analytics dashboard, i18n. Dài hạn (6-12 tháng) hướng đến tích hợp sâu với hệ thống PTIT chính thức và thử nghiệm AI-powered features.

Với tốc độ phát triển hiện tại của dự án (1 tuần 100+ tasks, deploy lên cloud chạy ổn định), nhóm phát triển có thể đạt được mục tiêu production-ready trong **3 tháng** nếu được phân bổ đủ resource (1 backend dev + 1 frontend dev + 0.5 DevOps).

---

**Người chuẩn bị tài liệu**: Nhóm CNPM
**Ngày**: 2026-05-06
**Phiên bản**: 1.0
