**HỌC VIỆN CÔNG NGHỆ BƯU CHÍNH VIỄN THÔNG**

--- KHOA CÔNG NGHỆ THÔNG TIN ---

BÁO CÁO MÔN

**CÔNG NGHỆ PHẦN MỀM**

Đề tài

**HỆ THỐNG QUẢN LÝ CUỘC THI**

**SINH VIÊN PTIT**

Sinh viên thực hiện: \[Họ và tên SV\]

Mã sinh viên: \[MSSV\]

Lớp: \[Lớp\]

Giảng viên hướng dẫn: \[Tên giảng viên\]

Học kỳ 2 --- Năm học 2025-2026

*Hà Nội, tháng 5 năm 2026*

**LỜI CAM ĐOAN**

Em xin cam đoan rằng nội dung trong báo cáo này là kết quả nghiên cứu và triển khai của riêng em dưới sự hướng dẫn của giảng viên. Toàn bộ mã nguồn, thiết kế và tài liệu đều do em tự thực hiện hoặc được trích dẫn rõ ràng từ các nguồn tham khảo công khai.

Các kết quả số liệu, biểu đồ và mã nguồn đính kèm phản ánh trung thực quá trình triển khai dự án từ giai đoạn yêu cầu, thiết kế, lập trình đến triển khai sản phẩm lên môi trường thực tế (production deployment).

Nếu phát hiện có sao chép không trích dẫn từ tài liệu khác, em xin chịu hoàn toàn trách nhiệm và mọi hình thức kỷ luật theo quy chế của Học viện.

*Hà Nội, ngày 07 tháng 5 năm 2026 (cập nhật v02 sau Sprint 2+3+4+5 + Phase A+B+C + Sentry FE + R2 storage)*

**Sinh viên thực hiện**

*\[Họ và tên SV\]*

**MỤC LỤC**

**DANH MỤC TỪ VIẾT TẮT**

  -------------- ------------------------------------------------------ ----------------------------------------------------
  **Viết tắt**   **Đầy đủ**                                             **Ý nghĩa**
  API            Application Programming Interface                      Giao diện lập trình ứng dụng
  APK            Android Package                                        Tệp cài đặt ứng dụng Android
  BCN            Ban Chủ nhiệm khoa                                     Người duyệt cấp 2 trong workflow
  BTC            Ban Tổ chức                                            Giảng viên tổ chức cuộc thi (ORGANIZER)
  CSP            Content Security Policy                                Chính sách bảo mật nội dung HTTP header
  CORS           Cross-Origin Resource Sharing                          Cơ chế chia sẻ tài nguyên giữa các domain
  DXA            Twentieths of a Point                                  Đơn vị đo trong file Office (1440 = 1 inch)
  FCM            Firebase Cloud Messaging                               Dịch vụ push notification của Google
  GV             Giảng viên                                             Người tổ chức cuộc thi (ORGANIZER role)
  HOD            Head of Department                                     Trưởng khoa, đồng nghĩa BCN
  HSTS           HTTP Strict Transport Security                         Bắt buộc HTTPS, chống SSL stripping
  JWT            JSON Web Token                                         Chuẩn token xác thực dạng signed JSON
  MCP            Model Context Protocol                                 Giao thức kết nối tool với LLM
  ORM            Object Relational Mapping                              Ánh xạ đối tượng - cơ sở dữ liệu (SQLAlchemy)
  OTP            One-Time Password                                      Mã xác thực 1 lần dùng
  PARA           Projects-Areas-Resources-Archives                      Phương pháp tổ chức tri thức cá nhân
  PTIT           Posts and Telecommunications Institute of Technology   Học viện Công nghệ Bưu chính Viễn thông
  QĐ1/QĐ2/QĐ3    Quyết định 1/2/3                                       Workflow phê duyệt: đề xuất / kết quả / chứng nhận
  RBAC           Role-Based Access Control                              Phân quyền dựa trên vai trò
  SMTP           Simple Mail Transfer Protocol                          Giao thức gửi email truyền thống
  SPA            Single Page Application                                Ứng dụng web 1 trang động
  SSO            Single Sign-On                                         Đăng nhập 1 lần dùng nhiều hệ thống
  SV             Sinh viên                                              STUDENT role
  TLS            Transport Layer Security                               Mã hoá kết nối HTTPS
  UI/UX          User Interface / User Experience                       Giao diện và trải nghiệm người dùng
  -------------- ------------------------------------------------------ ----------------------------------------------------

**CHƯƠNG 1 --- TỔNG QUAN DỰ ÁN**

**1.1 Lý do chọn đề tài**

Tại Học viện Công nghệ Bưu chính Viễn thông (PTIT), các cuộc thi sinh viên (Olympic Tin học, Hackathon, Workshop demo, CTF) được tổ chức đều đặn nhưng quy trình quản lý hiện tại còn dựa nhiều vào Excel, email và Google Forms. Ban tổ chức (BTC) phải gửi danh sách đăng ký qua nhiều kênh, Ban chủ nhiệm khoa (BCN) duyệt thủ công, kết quả công bố muộn và việc xác thực chứng nhận sau cuộc thi gặp khó khăn.

Đề tài này hướng tới xây dựng một hệ thống quản lý cuộc thi tập trung, hỗ trợ đầy đủ workflow phê duyệt 2 cấp BTC ↔ BCN, cho phép sinh viên (SV) đăng ký và theo dõi tiến trình từ điện thoại di động, đồng thời cung cấp dashboard quản trị cho admin trên trình duyệt máy tính.

Đề tài lựa chọn bộ công cụ hiện đại (FastAPI, PostgreSQL, Flutter) nhằm thực tập kỹ năng full-stack, đồng thời tận dụng các dịch vụ miễn phí (Railway, Cloudflare Pages, Brevo, Sentry) để triển khai sản phẩm thật lên Internet, không dừng lại ở mức prototype trên máy cá nhân.

**1.2 Mục tiêu**

Sản phẩm cần đạt được các mục tiêu chính sau:

-   Quản lý đầy đủ vòng đời 1 cuộc thi từ DRAFT, đề xuất QĐ1, mở đăng ký, ONGOING (chấm bài), kết quả QĐ2, đến cấp chứng nhận QĐ3.

-   Hỗ trợ 4 vai trò người dùng riêng biệt: Sinh viên (SV), Giảng viên/BTC (GV), Ban Chủ nhiệm khoa (BCN), Quản trị hệ thống (Admin).

-   Cung cấp 1 codebase Flutter biên dịch cả APK Android (sinh viên) và Web (BTC/BCN/Admin) để thuận tiện duy trì.

-   Audit log đầy đủ mọi thao tác mutating (POST/PATCH/PUT/DELETE) phục vụ tracking và kiểm soát.

-   Triển khai thật lên Internet với HTTPS, JWT auth, rate limit và security headers đạt chuẩn A+ securityheaders.com.

-   Email production thật cho forgot password, welcome admin tạo SV, OTP login alternative và mirror notification critical.

-   Tổng chi phí vận hành 0 đồng/tháng (trial credit) hoặc tối đa 5 USD/tháng sau trial --- phù hợp môi trường giáo dục.

**1.3 Phạm vi**

**1.3.1 Trong phạm vi (in-scope)**

-   Đăng ký, đăng nhập (email + password, refresh token, biometric trên APK).

-   Tạo cuộc thi (GV) → đề xuất BCN duyệt QĐ1 → mở đăng ký → SV đăng ký cá nhân/đội → BTC duyệt entries → ONGOING → judges chấm điểm → tính kết quả → submit BCN duyệt QĐ2 → publish → cấp chứng nhận QĐ3.

-   Quản lý 25+ bảng PostgreSQL (identity/RBAC, master data khoa-ngành, contest/round/session, entry/team, submission, judging/score, review, notification, certificate, workflow\_approval, audit\_log, system\_config).

-   Báo cáo và xuất kết quả ra file Excel 4 sheet (Tổng quan / Vòng - kết quả / Submissions / Metadata).

-   Notification deep-link: SV nhấn thông báo \"Đơn đã được duyệt\" sẽ được chuyển thẳng tới tab \"Của tôi\".

-   Bulk approve entries (lên tới 100 entries trong 1 request) cho GV duyệt nhanh.

-   Loading skeleton shimmer thay thế spinner cho cảm giác tải trang nhanh hơn.

**1.3.2 Ngoài phạm vi (out-of-scope)**

-   Tích hợp cổng đăng nhập SSO của PTIT (cần phối hợp với phòng IT của trường, không khả thi trong phạm vi đồ án).

-   Push notification mobile thật qua Firebase FCM (đề xuất Phase 3, cần Firebase project + APN cert iOS).

-   AI auto-grading code submission (đề xuất Phase 3, cần OpenAI/Claude API + Docker sandbox).

-   Live streaming / video call cho cuộc thi online (out of scope, focus quản trị).

-   Đa ngôn ngữ EN/VI (đề xuất Phase 3 nếu mở rộng quốc tế).

**1.4 Bốn vai trò người dùng**

Hệ thống phân quyền theo 4 vai trò riêng biệt, mỗi vai trò có bộ chức năng riêng và không bị gộp:

  --------------------- ------------------ ------------------------------------------------------------------------------------------------------------------------------------------------
  **Vai trò**           **Số chức năng**   **Trách nhiệm chính**
  SV (Sinh viên)        11                 Đăng ký tài khoản, xem cuộc thi, đăng ký tham gia (cá nhân/đội), nộp bài, xem kết quả, đánh giá cuộc thi
  GV/BTC (Giảng viên)   7                  Tạo và vận hành cuộc thi, đề xuất BCN duyệt, duyệt entries (đơn lẻ + bulk), chấm bài, công bố kết quả, cấp chứng nhận
  BCN (Trưởng khoa)     6                  Phê duyệt đề xuất cuộc thi (QĐ1), phê duyệt kết quả chung cuộc (QĐ2), phê duyệt template chứng nhận (QĐ3), giám sát tiến độ contests theo khoa
  Admin (Quản trị)      6                  Quản lý user (CRUD + lock/unlock), khoa/ngành/lớp, cấu hình hệ thống, audit log toàn cục, báo cáo system summary
  --------------------- ------------------ ------------------------------------------------------------------------------------------------------------------------------------------------

**1.5 Phương pháp tiếp cận**

Đồ án được tổ chức theo phương pháp PARA (Projects-Areas-Resources-Archives) kết hợp lifecycle phát triển phần mềm chuẩn (research → requirements → IA → wireframes → mockups → design system → prototypes → database → implementation → testing → docs). Folder dự án có 11 sub-folder rõ ràng, naming convention \`YYYY-MM-DD\_chu-de\_v01.ext\`.

Quá trình triển khai thật được chia thành các giai đoạn (phase) lặp tăng tiến (iterative): Sprint 0 audit và sửa lỗi nền tảng, Phase 1 Production Foundation (Sentry/Rate limit/Refresh token/Email/HSTS), Phase 2 Sprint 1 Quick Wins (5 cải tiến UX/productivity), tiếp theo là Phase 2 Sprint 2 và Phase 3 dài hạn.

Mỗi step trong roadmap đều có overview 4 mục bắt buộc trước khi code: Mục tiêu / Sẽ làm / Ảnh hưởng / Cải tiến đo được --- phương pháp này giúp đánh giá ROI từng task và tránh làm code không cần thiết.

**CHƯƠNG 2 --- PHÂN TÍCH YÊU CẦU**

**2.1 Yêu cầu chức năng (Functional Requirements)**

**2.1.1 Nhóm chức năng SV (11 chức năng)**

Sinh viên là đối tượng người dùng chính sử dụng APK Android. Các chức năng được thiết kế mobile-first với bottom navigation 6 tab.

-   SV-01: Đăng nhập (email + password, JWT HS256). Tùy chọn OTP login (mã 6 chữ số gửi email, TTL 5 phút).

-   SV-01b: Đăng ký tài khoản mới với email \@ptit.edu.vn, full\_name, password ≥6 ký tự.

-   SV-01c: Quên mật khẩu (gửi email reset link, TTL 15 phút). Reset token đảm bảo single-use.

-   SV-02: Cập nhật hồ sơ cá nhân với 11 trường mở rộng (DOB, gender, CCCD, place\_of\_birth, address, ethnicity, religion, nationality, secondary\_email, phone, avatar\_url).

-   SV-03: Đổi mật khẩu (verify password cũ trước khi cho đổi). Soft delete tài khoản (status=DELETED).

-   SV-04: Browse danh sách cuộc thi (search theo title, filter theo status REG\_OPEN/PUBLISHED/ONGOING/FINISHED).

-   SV-05: Xem chi tiết cuộc thi (banner, mô tả, lịch trình, vòng thi, host khoa, prize).

-   SV-06: Đăng ký tham gia cuộc thi --- cá nhân hoặc theo đội (TEAM mode cần tạo team trước, leader+member).

-   SV-07: Nhận thông báo (notification) với deep-link tới screen liên quan (Step 1 Phase 2).

-   SV-08: Nộp bài (submission) cho từng round/contest có yêu cầu nộp file. Hỗ trợ external link (Google Drive/GitHub) + text answer + multipart upload BYTEA ≤10MB.

-   SV-09: Xem kết quả cá nhân (rank, điểm các vòng, giải thưởng nhận được). Xác thực chứng nhận qua mã QR.

-   SV-10: Hủy đăng ký (PENDING/APPROVED + contest REG\_OPEN). Đánh giá cuộc thi sau khi FINISHED (rating 1-5 sao + comment).

**2.1.2 Nhóm chức năng GV/BTC (7 chức năng)**

-   GV-01: Login + dashboard tổng quan (số contests đang chạy, số entries pending duyệt, số cert đã cấp).

-   GV-02: Tạo cuộc thi (CRUD): title, slug, description, rules, awards, banner, dates, mode (INDIVIDUAL/TEAM), delivery\_mode (ONLINE/OFFLINE/HYBRID), team\_min/max\_members, max\_entries.

-   GV-02b: Submit đề xuất (QĐ1) tới BCN duyệt. Sau khi APPROVED → mở đăng ký.

-   GV-03: Duyệt entries (đơn lẻ + bulk lên tới 100 entries 1 request). Reject phải có reason.

-   GV-04: Quản lý vòng thi (rounds), phiên thi (sessions), gán judges cho từng round.

-   GV-05: Chấm điểm (scoring) theo tiêu chí (criteria) hoặc tổng quát. Lock/unlock submission.

-   GV-06: Compute kết quả → submit (QĐ2) tới BCN → publish. Cấp chứng nhận (QĐ3) qua template.

-   GV-07: Báo cáo theo cuộc thi (số entries, completion rate, average rating). Xuất Excel 4 sheets.

**2.1.3 Nhóm chức năng BCN (6 chức năng)**

-   BCN-01: Login + dashboard pending approval theo khoa của BCN.

-   BCN-02: Phê duyệt QĐ1 --- cuộc thi đề xuất từ BTC. Decision: APPROVE/REJECT/REQUEST\_REVISION.

-   BCN-03: Giám sát tiến độ contests theo khoa (% completion mỗi giai đoạn).

-   BCN-04: Phê duyệt QĐ2 --- kết quả chung cuộc trước khi publish.

-   BCN-05: Phê duyệt QĐ3 --- template chứng nhận trước khi cấp hàng loạt. Báo cáo tổng hợp theo khoa.

-   BCN-06: Xem audit log của các action liên quan tới khoa mình.

**2.1.4 Nhóm chức năng Admin (6 chức năng)**

-   AD-01: Login + dashboard system-wide (tổng users, tổng contests, tổng submissions, tổng cert).

-   AD-02: Quản lý user (CRUD, assign roles, lock/unlock account, reset password).

-   AD-03: Quản lý master data: khoa (faculties), ngành (majors), lớp (academic\_classes), student\_directory.

-   AD-04: Cấu hình hệ thống (system\_configs): rate limit, OTP expiry, upload max size, allowed extensions.

-   AD-05: Báo cáo system summary theo năm (số contests, entries, submissions, cert, reviews trung bình).

-   AD-06: Xem và moderate audit log toàn cục, moderate review/comment.

**2.2 Yêu cầu phi chức năng (Non-Functional Requirements)**

  -------- ------------------------------ ------------ ----------------------------------------------------------------------------------------------------
  **Mã**   **Yêu cầu**                    **Mức độ**   **Triển khai thực tế**
  NF-01    Bảo mật JWT auth               Bắt buộc     JWT HS256, access TTL 60p, refresh token 7 ngày sliding window
  NF-02    HTTPS bắt buộc                 Bắt buộc     HSTS max-age 1 năm, includeSubDomains, preload-ready
  NF-03    Rate limit chống brute-force   Bắt buộc     slowapi: 200/min default, 10/min login, 5/min register, 20/min refresh
  NF-04    Audit log mọi mutation         Bắt buộc     ASGI middleware async queue + worker fire-and-forget
  NF-05    Responsive web + APK           Bắt buộc     1 codebase Flutter, 2 build target. Web ≥900px sidebar, mobile bottom nav
  NF-06    Error tracking                 Quan trọng   Sentry production-grade, free tier 5K events/tháng
  NF-07    Email transactional            Quan trọng   Brevo HTTP API (port 443), 300 email/ngày free
  NF-08    Security headers A+            Quan trọng   6 headers: HSTS, CSP, Permissions-Policy, Referrer-Policy, X-Content-Type-Options, X-Frame-Options
  NF-09    Perceived performance          Mong muốn    Loading skeleton shimmer thay spinner ở 5 SV screens
  NF-10    Biometric login mobile         Mong muốn    local\_auth Flutter, FaceID/Vân tay APK Android
  NF-11    Cost = 0đ                      Mong muốn    Railway trial credit + Cloudflare Pages free + Brevo free + Sentry free
  -------- ------------------------------ ------------ ----------------------------------------------------------------------------------------------------

**2.3 Workflow phê duyệt 2 cấp BTC ↔ BCN**

Đây là điểm đặc thù của hệ thống: trước khi 1 cuộc thi được công khai cho SV đăng ký hoặc kết quả được công bố, đều phải qua 2 lớp duyệt --- BTC tạo và đề xuất, BCN của khoa chủ trì có quyền APPROVE / REJECT / REQUEST\_REVISION (yêu cầu chỉnh sửa và submit lại).

**2.3.1 QĐ1 --- Đề xuất cuộc thi**

-   GV/BTC tạo contest ở status DRAFT, điền đầy đủ thông tin (title, dates, rules, awards, host\_faculty\_id).

-   GV submit POST /api/contests/{id}/submit-for-approval --- tạo workflow\_approval(target=CONTEST\_PROPOSAL, step=BCN\_QD1, status=PENDING).

-   BCN của khoa chủ trì nhận thông báo, mở dashboard \"Phê duyệt\", xem snapshot JSON của contest.

-   BCN quyết định: APPROVE → contest sang status PUBLISHED → mở đăng ký. REJECT → contest về DRAFT, GV phải submit lại bản revision\_round mới.

**2.3.2 QĐ2 --- Kết quả chung cuộc**

-   Sau khi contest FINISHED và judges chấm xong, GV gọi POST /api/contests/{id}/results/compute để tính rank và điểm cuối.

-   GV review bảng xếp hạng, chỉnh giải thưởng (award\_title) cho các entry top.

-   GV submit POST /api/contests/{id}/results/submit-for-approval --- tạo workflow\_approval(target=CONTEST\_RESULT, step=BCN\_QD2).

-   BCN duyệt → GV publish → contest\_results.published\_at = now → SV thấy kết quả trong tab \"Kết quả\" của họ.

**2.3.3 QĐ3 --- Cấp chứng nhận**

-   GV upload template chứng nhận (HTML hoặc image), submit BCN duyệt template.

-   BCN APPROVE template → GV gọi issue cert hàng loạt cho top 3 / top 10 / tất cả entries APPROVED tùy cấu hình.

-   Mỗi cert có mã QR unique (256-bit random) trỏ tới /api/verify/{qr\_code} để verify công khai.

**CHƯƠNG 3 --- THIẾT KẾ HỆ THỐNG**

**3.1 Kiến trúc tổng thể (3-tier)**

Hệ thống được thiết kế theo kiến trúc 3 tầng kinh điển, với mỗi tầng được host trên dịch vụ chuyên biệt và miễn phí (hoặc trial credit):

  -------------- -------------------------------------------------------- --------------------------------- -----------------------------------------------------------
  **Tầng**       **Công nghệ**                                            **Host**                          **URL**
  Presentation   Flutter Web + APK Android                                Cloudflare Pages (free)           https://ptit-contest-app.pages.dev
  Application    FastAPI (Python 3.11) + SQLAlchemy 2.0 async + asyncpg   Railway (Hobby trial credit)      https://ptit-contest-mobile-app-production.up.railway.app
  Data           PostgreSQL 16 (managed)                                  Railway Postgres add-on           Internal connection string
  Email          Brevo Transactional Email HTTP API                       Brevo SaaS (free 300/d)           api.brevo.com/v3/smtp/email
  Monitoring     Sentry (FastAPI integration)                             Sentry SaaS (free 5K events/mo)   mrb-personal.sentry.io
  -------------- -------------------------------------------------------- --------------------------------- -----------------------------------------------------------

Frontend Flutter dùng dio (HTTP client) gọi Backend qua HTTPS, có CORS regex match \`\[a-z0-9-\]+\\.pages\\.dev\|\[a-z0-9-\]+\\.up\\.railway\\.app\|192\\.168\\.\\d+\\.\\d+\|\...\`. Backend quản lý JWT, RBAC, audit log, cập nhật DB qua connection pool 5+10. Pool riêng cho audit middleware (2+2 conn) để không block worker chính.

**3.2 Cơ sở dữ liệu (PostgreSQL \~25 bảng)**

Schema được tổ chức theo 13 nhóm logic, đặt trong namespace ptit\_contest:

-   Identity & RBAC (4): app\_users, roles, user\_roles, sessions.

-   Master data (5): faculties, majors, academic\_classes, student\_directory, students/organizers/judges/department\_heads (4 profile tables, OneToOne với app\_users).

-   Contest core (3): contests, contest\_organizers, contest\_rounds.

-   Entry & Team (4): contest\_entries, teams, team\_members, entry\_status\_logs.

-   Submission (3): submissions, submission\_versions, submission\_files (BYTEA in-DB tạm thời cho demo).

-   Judging (4): score\_criteria, judge\_assignments, scores, round\_results, contest\_results.

-   Workflow (1): workflow\_approvals (target\_type ENUM CONTEST\_PROPOSAL/CONTEST\_RESULT/CERTIFICATE\_TEMPLATE).

-   Notification (2): notifications (target\_route deep-link), notification\_recipients.

-   Certificate (2): cert\_templates, issued\_certificates (qr\_code unique).

-   Review (2): contest\_reviews, contest\_review\_replies.

-   System (2): audit\_logs (track mọi POST/PATCH/PUT/DELETE), system\_configs (key-value cấu hình runtime).

Tất cả bảng có created\_at/updated\_at TIMESTAMPTZ, soft delete ở status field thay vì hard DELETE. Foreign key cascade rules được thiết kế cẩn thận: identity dùng RESTRICT, master data dùng SET NULL, contest core dùng CASCADE.

**3.3 RBAC --- Phân quyền theo vai trò**

Hệ thống dùng cơ chế Role-Based Access Control với 5 role:

-   STUDENT: SV thường, chỉ truy cập features/student/\*.

-   ORGANIZER: GV/BTC, có thể tạo và quản lý contests mình host.

-   JUDGE: được assign chấm điểm các submission của round.

-   HOD: BCN, duyệt contests và results trong khoa mình quản lý.

-   ADMIN: full access, có thể impersonate mọi role khác.

1 user có thể có nhiều role (vd GV gv\@ptit.edu.vn có cả ADMIN + JUDGE + ORGANIZER cho mục đích demo). JWT payload chứa list role\_codes, frontend đọc để render sidebar admin shell tương ứng. Backend dùng dependency \`CurrentUser\` + helper \`\_ensure\_organizer\_of\_contest\`, \`\_ensure\_btc\`, \`\_ensure\_admin\` để check quyền per-endpoint.

**3.4 Authentication & Refresh Token**

Quy trình xác thực được thiết kế tối ưu cho cả web và mobile:

-   POST /auth/login với email + password → trả TokenOut chứa access\_token (TTL 60 phút) + refresh\_token (TTL 7 ngày).

-   Mọi request gọi API kèm \`Authorization: Bearer \<access\_token\>\`. Backend decode JWT, lookup user, attach vào request context.

-   Khi access token hết hạn (sau 60 phút), client gọi POST /auth/refresh với refresh\_token → backend validate type claim \"refresh\", rotate token mới (sliding window), trả token pair mới.

-   Refresh token được lưu trong flutter\_secure\_storage (encrypted Android KeyStore) trên APK; localStorage trên web (kém secure hơn nhưng đủ cho demo).

-   OTP login alternative: POST /auth/otp/request → backend sinh mã 6 chữ số bcrypt-hashed lưu in-memory dict (TTL 5p, lock 30p sau 5 sai), gửi email. POST /auth/otp/verify → trả token pair giống login thường.

-   Biometric login (APK only): user bật toggle trong Profile → mở app lần sau, FaceID/Vân tay prompt → POST /auth/refresh tự động → vào app trong 1-2 giây.

**3.5 Audit Log Middleware**

Mỗi request POST/PATCH/PUT/DELETE đi qua AuditASGIMiddleware (pure ASGI, không phải BaseHTTPMiddleware để tránh buffer body). Middleware có 2 phần:

-   Enqueue: trích xuất method, path, user\_id (từ JWT), status\_code, request\_id → put vào asyncio.Queue (maxsize=1000, drop nếu full).

-   Worker: 1 background async task chạy lifespan của app, drain queue và insert AuditLog qua engine pool riêng (2+2 conn), không block main worker pool.

Trade-off: nếu queue đầy (\>1000 mutation chưa flush, cực kỳ hiếm), audit bị drop + log warning. Acceptable vì request không nên fail vì audit log.

**CHƯƠNG 4 --- TRIỂN KHAI**

**4.1 Tech stack chốt**

  ----------------------- -------------------------------------------------------------
  **OS server**           Ubuntu Server 24.04 LTS (qua WSL2)
  **Backend framework**   FastAPI 0.115+ (Python 3.11)
  **ORM**                 SQLAlchemy 2.0 async + asyncpg
  **Database**            PostgreSQL 16 (Railway managed)
  **Auth**                JWT HS256 (python-jose) + bcrypt
  **Email**               Brevo Transactional Email HTTP API + Jinja2 templates
  **Error tracking**      Sentry SDK FastAPI integration
  **Rate limit**          slowapi + Redis-ready
  **Frontend**            Flutter 3.x (1 codebase, 2 build target)
  **State management**    Riverpod 2.6 (autoDispose, code-gen)
  **Routing**             go\_router 14
  **HTTP client**         dio 5.7
  **Secure storage**      flutter\_secure\_storage 9.2 (Android KeyStore)
  **Biometric**           local\_auth 2.3
  **Loading UX**          shimmer 3.0
  **Excel export**        openpyxl 3.1 (Python)
  **Backend host**        Railway (Hobby trial \$5 credit)
  **Frontend host**       Cloudflare Pages (free 500 builds/mo + unlimited bandwidth)
  **Email host**          Brevo (free 300 email/d)
  **Monitoring**          Sentry (free 5K events/mo)
  ----------------------- -------------------------------------------------------------

**4.2 Backend (FastAPI) --- 99 endpoints qua 14 router**

Backend được tổ chức theo Clean Architecture-lite: routers (HTTP layer), services (business logic), models (SQLAlchemy ORM), schemas (Pydantic v2 DTOs). Tổng cộng 99 endpoints chia theo 14 router:

  --------------- ----------------- ---------------------------------------------------------------------------
  **Router**      **Số endpoint**   **Mục đích**
  auth            7                 Login, register, refresh, logout, OTP request/verify, /me
  users           5                 Profile CRUD, change password, forgot/reset password
  contests        15                CRUD, transition-status, rounds, sessions, stats
  approvals       8                 QĐ1/QĐ2/QĐ3 submit + decide + revision
  entries         10                Register individual/team, list, review (đơn lẻ + bulk), my-entries
  teams           6                 Create team, add/remove member, my-teams
  submissions     8                 Submit, version, file upload, download, lock/unlock
  judging         7                 Assign judges, score (criteria-based), round-results
  results         6                 Compute, list, update award, publish, my-results
  reviews         4                 Rate contest, list reviews, moderate
  notifications   3                 List, mark-read, mark-all-read
  certificates    6                 Issue, verify QR, render, revoke (đề xuất Sprint 2)
  reports         5                 Stats per contest, monitor, faculty-summary, system-summary, export Excel
  admin           9                 CRUD users, master data, configs, audit logs
  --------------- ----------------- ---------------------------------------------------------------------------

**4.3 Frontend (Flutter) --- 27+ screens responsive**

Frontend là 1 codebase Flutter biên dịch 2 build target. Logic chia theo features/student/\* (chỉ render trên APK Android) và features/admin/\* (chỉ render trên web). Layout responsive theo width:

-   SV web wide (≥900px): sidebar trái 240px trắng + content 900px max width, breakpoint chuyển từ MobileFrame.

-   SV web mobile (\<900px) + APK Android: MobileFrame 400px container + bottom nav 6 tabs (Trang chủ / Cuộc thi / Của tôi / Kết quả / Thông báo / Tôi).

-   Admin web ≥768px: sidebar trái 240px đen + main content full width.

-   Admin mobile \<768px + APK (hiếm dùng): AppBar + Drawer + bottom nav 5 items.

Tổng số screens hiện tại 27+ với các sub-screens: ContestDetail, Register, TeamManagement, Submission, EditProfile, CertVerify, ForgotPassword 2-step, ContestAdminDetail 6-tabs (Tổng quan / Vòng & Phiên / Đăng ký / Chấm điểm / Kết quả / Chứng nhận).

**4.4 Phase 1 --- Production Foundation (5 step DONE)**

**4.4.1 Step 1: Sentry error tracking**

Tích hợp Sentry SDK với 4 integrations (Starlette, FastAPI, SQLAlchemy, Asyncio). Init trước khi tạo FastAPI() để catch cả lỗi import / startup config. Release tag tự động đọc từ Railway env RAILWAY\_GIT\_COMMIT\_SHA. send\_default\_pii=False (GDPR-safer). attach\_stacktrace=True cho mọi log WARNING+. Skip init nếu SENTRY\_DSN rỗng (dev mode).

**4.4.2 Step 2: Rate limit**

Dùng slowapi (FastAPI port của flask-limiter). Storage memory (Redis-ready qua REDIS\_URL env nếu sau scale). Đọc IP từ X-Forwarded-For (fix bug Railway proxy đổi IP socket peer mỗi request). Tier limits: 200/min default, 10/min POST /auth/login, 5/min POST /auth/register, 20/min POST /auth/refresh.

Bug đã fix: \@limiter.limit() decorator gọi \`kwargs.get(\"response\")\` để inject rate-limit headers. Endpoint trả Pydantic model (không phải Response) → kwargs.get → None → \_inject\_headers(None) → 500. Phải thêm \`response: Response\` vào signature mọi endpoint dùng \@limiter.

**4.4.3 Step 3: Refresh token JWT**

Implement stateless refresh token (không lưu DB). TTL 7 ngày, sliding window: mỗi lần dùng /auth/refresh sẽ rotate token mới với iat hiện tại. Type claim \"refresh\" để phân biệt với access token (security: chống dùng access token gọi /auth/refresh và ngược lại).

Test 6/6 PASS: login trả refresh\_token, /auth/refresh hợp lệ trả token mới với iat tăng, /auth/refresh sai trả 401, /auth/refresh dùng access token trả 401 (type claim check), rate limit 20/phút hoạt động.

**4.4.4 Step 4: Email service Brevo HTTP API**

Migrate phức tạp nhất Phase 1. Ban đầu dùng SMTP qua aiosmtplib (port 587 STARTTLS) nhưng Railway Hobby plan block outbound TCP port 25/465/587 → SMTPConnectTimeoutError. Phải migrate sang Brevo Transactional Email HTTP API (POST https://api.brevo.com/v3/smtp/email) qua port 443.

4 use case email implemented: forgot password (link reset 15p), welcome (admin tạo SV → temp password), OTP login (mã 6 chữ số 5p), notification mirror (event critical). 4 templates Jinja2 với header xanh PTIT. Pattern fire-and-forget qua FastAPI BackgroundTasks không block response.

> \# email\_service.py --- Brevo HTTP API (port 443)
> async with httpx.AsyncClient(timeout=15) as client:
> response = await client.post(
> \"https://api.brevo.com/v3/smtp/email\",
> headers={\"api-key\": BREVO\_API\_KEY},
> json=payload
> )

**4.4.5 Step 5: HSTS + 5 Security Headers**

Pure ASGI middleware add 6 security headers vào mọi response. Đạt grade A+ trên securityheaders.com:

-   Strict-Transport-Security: max-age=31536000; includeSubDomains; preload (1 năm).

-   Content-Security-Policy: default-src \'none\'; frame-ancestors \'none\' (chặt nhất cho API JSON).

-   X-Content-Type-Options: nosniff (chống MIME sniffing exploit).

-   X-Frame-Options: DENY (chống clickjacking).

-   Referrer-Policy: strict-origin-when-cross-origin (chống leak referrer cross-origin).

-   Permissions-Policy: disable geolocation, microphone, camera, payment, \... (BE không dùng).

Bug fix: HSTS không xuất hiện ở response đầu vì check \`scope\[\"scheme\"\] == \"https\"\` luôn FALSE (Railway proxy terminate TLS → backend nhận scheme=\"http\"). Fix: helper \`\_is\_https\_request(scope)\` đọc X-Forwarded-Proto header.

**4.5 Phase 2 Sprint 1 --- Quick Wins (5 step DONE)**

**4.5.1 Step 1: Notification deep-link**

Thêm column \`notifications.target\_route VARCHAR(255)\` nullable + idempotent migration ALTER TABLE ở lifespan startup. Backend \`notify\_users(target\_route=\...)\` thread param qua \`Notification.target\_route\`. Frontend \`studentTabProvider = StateProvider\<int\>\` global → StudentShell \`\_idx\` → \`ref.watch\`. NotificationsScreen onTap map \`\_shellTabRoutes\` ảo (\`/me/entries\` → tab 2, \`/me/results\` → 3, \...) → set provider state.

Bug đã fix: route \`/me/entries\` không có trong GoRouter (6 tab là \*\*state\*\*, không phải route URL). Fix: dùng global Provider thay vì context.push(). Bug v2: NotificationsScreen mở từ icon chuông top bar che StudentShell underneath → set tab=2 nhưng user không thấy. Fix: \`Navigator.canPop()\` → \`Navigator.pop()\` để đóng modal.

**4.5.2 Step 2: Bulk approve entries**

Endpoint \`POST /api/contests/{cid}/entries/bulk-review\` body BulkReviewIn (entry\_ids max 100, action APPROVE/REJECT, note optional). Service \`bulk\_review\_entries\` partial commit pattern: dedup ids, verify quyền 1 lần, loop + try/except per entry → return (success\_count, failed list). Frontend checkbox per row PENDING + button \"Chọn tất cả PENDING (N)\" + floating action bar bottom với confirmation dialog.

Cải tiến đo được: 50 entries × 3s = 2.5 phút (manual click từng row) → 1 request = 5 giây = \~30x productivity tăng cho GV.

**4.5.3 Step 2.5: Wire notification vào review entries**

Helper \`\_resolve\_recipient\_user\_ids(db, entry)\`: INDIVIDUAL → 1 SV (Student.user\_id), TEAM → JOIN team\_members → all member user\_ids. Sau khi commit review (review\_entry hoặc bulk\_review\_entries), gọi \`notification\_service.notify\_users(target\_route=\"/me/entries\")\` → SV nhận thông báo \"Đơn đã được duyệt/từ chối\" với deep-link tới tab \"Của tôi\".

**4.5.4 Step 3: Excel export 4 sheets**

Tích hợp openpyxl. Sheet 1 Tổng quan: Hạng / Tên SV-Team / Mã SV / Tổng điểm / Giải thưởng / BCN duyệt. Sheet 2 Vòng - kết quả: Vòng / Tên vòng / Hạng / Entry ID / Tên / Tổng điểm / Điểm TB / Đậu. Sheet 3 Submissions: Vòng / Submission ID / Entry / Trạng thái / Phiên bản / Đã nộp lúc. Sheet 4 Metadata: Mã contest / Slug / Tên / Trạng thái / Hình thức / Bắt đầu / Kết thúc / Người xuất / Thời gian xuất.

Format: header bold xanh PTIT (\#1E3A8A), freeze pane row 1, autofilter, autosize columns. Endpoint \`GET /api/contests/{cid}/results/export.xlsx\` trả StreamingResponse 64KB chunks. CORS expose Content-Disposition cho FE đọc filename.

Frontend conditional export: web \`dart:html\` Blob + AnchorElement.click() để trigger download; mobile throw UnsupportedError. Pattern giống cert\_open\_web.dart đã có sẵn.

**4.5.5 Step 4: Biometric login (APK Android)**

Package \`local\_auth: \^2.3.0\`. BiometricService wrapper LocalAuthentication với isAvailable() (kIsWeb skip) + authenticate() (biometricOnly + stickyAuth). Tận dụng refresh token đã có Phase 1 step 3. Toggle bật/tắt trong ProfileScreen (Switch widget hide trên web qua kIsWeb).

Flow: lần đầu user login email/pass → save refresh\_token vào secure storage. Bật toggle \"Đăng nhập sinh trắc\" → prompt FaceID 1 lần để confirm. Lần sau mở app → LoginScreen initState auto-prompt → POST /auth/refresh → set state → router redirect khỏi /login.

**4.5.6 Step 5: Loading skeleton shimmer**

Package \`shimmer: \^3.0.0\`. Tạo widget MShimmer (Shimmer.fromColors gradient \#E5E7EB → \#F3F4F6, period 1500ms) + 3 preset reusable: MCardSkeleton (mimic MCard layout: title 60% + N text lines + tag pill + timestamp), MCardListSkeleton (ListView N cards), MListItemSkeleton (rank circle + 2 lines + score badge --- cho results).

Replace CircularProgressIndicator ở 5 SV screens: notifications (5 cards), contest\_list (4 cards), my\_registrations (3 cards textLines=3), my\_results (3 row skeletons), home (3 cuộc thi nổi bật). Perceived load time \~2x faster theo nghiên cứu UX của Facebook và Twitter.

**4.6 Bonus migration: Netlify → Cloudflare Pages**

Netlify free tier có quota 300 build minutes/tháng. Sau khi deploy 7 lần test trong 1 ngày (Phase 1 step 5 + Phase 2 step 1 v1/v2 + step 2 + step 3), Netlify hết quota → \"Site not available\" → không deploy được nữa. Phải migrate sang dịch vụ thay thế.

Cloudflare Pages free tier: 500 build minutes/tháng + unlimited bandwidth + 5 concurrent builds. Setup qua wrangler CLI (cần Node.js). Sau khi deploy, URL mới \`https://ptit-contest-app.pages.dev\`. Phải update URL canonical 6 chỗ:

-   app/config.py default frontend\_base\_url.

-   app/main.py migration UPDATE seed system\_configs.qr\_verify\_url\_base (idempotent: WHERE config\_value NOT LIKE %pages.dev%).

-   init-schema.sql seed (cho fresh DB).

-   08-database/2026-05-06\_sqlapp\_v04.sql canonical schema.

-   Railway env FRONTEND\_BASE\_URL.

-   CORS allow\_origin\_regex thêm \`\[a-z0-9-\]+\\.pages\\.dev\`.

Netlify project deleted sau migration. URL \`luxury-crostata-3c5c69.netlify.app\` giờ trả \"Site not found\".

**4.7 Phase A --- Design tokens cleanup (2026-05-06)**

Phase A là code-level cleanup tiền-Phase B audit. Mục tiêu: thiết lập design system formal trước khi audit visual + UX, để các fixes sau dùng tokens đồng nhất.

**4.7.1 4 token files mới**

- `lib/core/spacing.dart` --- AppSpacing.xs(4), sm(8), md(16), lg(24), xl(32), xxl(48). Replace literal padding.
- `lib/core/radius.dart` --- AppRadius.tight(2), sm(8), md(12), lg(16), xl(24), pill(999). Replace BorderRadius.circular(literal).
- `lib/core/durations.dart` --- AppDuration.fast(150ms), normal(300ms), slow(500ms). Replace Duration() inline.
- `lib/core/breakpoints.dart` --- AppBreakpoint.mobile(<600), tablet(<900), desktop(<1200), wide(>=1200). Material standard.

**4.7.2 design_lint.ps1 + DESIGN-REVIEW-CHECKLIST.md**

Script PowerShell chạy regex grep tìm 5 categories violations:
1. Hex literal trong features/* (vi phạm token)
2. SizedBox(width/height) literal (vi phạm AppSpacing)
3. BorderRadius.circular(số) literal
4. Duration(milliseconds: số) literal
5. MediaQuery.of(...).size.width >= literal

Initial run: 334 violations. Sau apply tokens: 269 violations (-19%). Category 3 + 5 = 0% (radius + breakpoint dùng tokens 100%).

**4.7.3 CLAUDE.md frontend setup**

Update `lib/CLAUDE.md` với rule: "MUST dùng AppColors/AppRadius/AppSpacing/AppDuration/textTheme trong features/. Zero literal hex/size/radius. Test cả light+dark. Run design_lint.ps1 trước commit."

**4.8 Phase B --- UX visual audit (đợt 1+2, 2026-05-06)**

Phase B là audit-only (không code) sử dụng skill `ui-ux-pro-max` để evaluate eye-flow, intent-based interaction, mobile reflow, surface elevation. Output là backlog UX, không patch trực tiếp.

**4.8.1 Methodology**

Phương pháp: screenshot 4 màn × 3 viewport (1440px desktop / 768px tablet / 380px mobile narrow) trên production deploy. Đối chiếu với 4 nhóm POUR (Perceivable / Operable / Understandable / Robust). Severity: Critical / Major / Minor.

**4.8.2 Đợt 1 (2026-05-06 buổi sáng)**

Coverage: 4 screens × 3 viewport = 12 screenshots. Screens: Home SV, Contest List, Contest Detail, Profile.

Findings: 2 Critical + 3 Major + 4 Minor. Top issues:

- C1 Sort Contest List ngược Home (REG_OPEN xuống cuối thay vì đầu, vi phạm hierarchy "active priority").
- C2 Meta chips render text trống ở dark mode (chẩn đoán đầu là backend thiếu fields, sau xác minh là theme drift bg/text).
- M1 Contest Detail desktop 1440 mất sidebar (route không nằm trong ShellRoute).
- M2 Avatar Profile gradient ≠ Login (false positive, 2 widget cùng dùng `ptitGradientHero`).
- M3 Stat "Giải thưởng" dùng tone warn trong dark mode → render brown thay vì gold.

**4.8.3 Đợt 2 (2026-05-06 buổi chiều)**

Coverage thêm 3 screens × 3 viewport = 9 screenshots. Screens: Login, Submission, Approval Queue BCN. Defer Admin Dashboard vì chưa có user ADMIN seed.

Findings: 2 Critical + 3 Major + 3 Minor:

- C3 Submission `/rounds/:id/submit` mất sidebar/shell ở 1440 (cùng pattern với M1).
- C4 Approval Queue BCN ở 768 không collapse sidebar → main content cramp 528px.
- M4 Login form căng full 1440px (nên cap maxWidth 480px).
- M5 Demo creds box (SV/GV/BCN) lộ ở production deploy.
- M6 Login footer "POST /api/auth/login · JWT HS256" lộ implementation details.

Tổng audit Phase B đợt 1+2: **4 Critical + 6 Major + 7 Minor = 17 findings** trên 21/24 screens. Admin Dashboard defer cho đợt 3.

File: `11-docs/ux-audit-2026-05-06.md` (449 dòng).

**4.9 Sprint 2 --- UX fix triển khai (2026-05-06 evening)**

Sprint 2 fix 10 findings từ Phase B audit theo recommend order ROI giảm dần. Mục tiêu: Critical 4→0, Major 6→2, demo-ready chuyên nghiệp.

**4.9.1 5 commits triển khai**

1. **C3+M1** (`aea2703`): Wrap `/contests/:slug`, `/contests/:slug/register`, `/rounds/:roundId/submit` vào `StudentShellScaffold` desktop sidebar. File mới `student_shell_scaffold.dart` ~250 LOC. Mobile vẫn render child raw (existing back-arrow behavior).

2. **C4** (`da08155`): `admin_shell.dart` threshold 768→1024 (Material standard). 768px tablet giờ collapse hamburger drawer + bottom nav, không còn sidebar cramp.

3. **M4+M5+M6** (`d158439`): Login form wrap `Center + ConstrainedBox(maxWidth: 480)`. Demo creds box + POST footer wrap `if (!kReleaseMode) ...` → ẩn ở production build.

4. **C1+C2** (`751241a`): Contest List sort theo `_statusOrder` map (REG_OPEN=0, ONGOING=1, ..., FINISHED=4, CANCELLED=5), tie-break startAt desc. `_MetaChip` bg theme-aware (dark mode dùng `cardBorder.withValues(alpha:0.5)` thay vì hardcoded cream).

5. **M3** (`f430b00`): Thêm tokens `achievementGold` + `achievementGoldSoft` (light + dark variants). Stat "Giải thưởng" đổi tone `warn → gold`. Light: amber-700/amber-100. Dark: amber-300/amber-950.

**4.9.2 E2E verify**

Test qua Chrome MCP localhost:5050: 6 luồng critical pass:

- Login form 1440 cap 480px center (M4 ✓)
- Olympic REG_OPEN ở vị trí #1 thay vì #3 (C1 ✓)
- Meta chips dark mode hiện rõ "Khoa #1 / Cá nhân / Offline" (C2 ✓)
- Stat "Giải thưởng" tone gold thay vì nâu (M3 ✓)
- `/contests/<slug>` và `/rounds/<id>/submit` desktop có sidebar trái (C3+M1 ✓)
- BCN 768px → hamburger + bottom nav (C4 ✓)
- M5+M6: dev mode show demo creds + footer; release build (`flutter build web --release`) verify hide hoàn toàn.

**4.9.3 Cải tiến đo được**

| Severity | Trước Sprint 2 | Sau Sprint 2 |
|---|:---:|:---:|
| Critical | 4 | 0 |
| Major | 6 | 2 |
| Minor | 7 | 7 (backlog) |

M2 verified false positive (Profile + Login đều dùng `ptitGradientHero` từ trước). Critical=0 đạt target.

**4.10 Phase C --- A11y baseline pass (2026-05-07)**

Phase C audit accessibility theo WCAG 2.1 AA dùng axe-core 4.10.0 inject qua Chrome MCP, scan 4 screens × 2 viewport (1440 + 567) = 8 scans trên local release build (`flutter build web --release` + Python http.server 5050).

**4.10.1 Findings baseline**

Tất cả 8 scans cùng 3 violations đồng nhất (page-level):

| Severity | Issue | Fix |
|---|---|---|
| Critical | `meta-viewport` Flutter disable zoom (WCAG 1.4.4) | Inject script override sau `flutter-first-frame` event |
| Critical | `button-name` Claude extension overlay button | False positive, không fix được trong code Flutter |
| Serious | `html-has-lang` missing (WCAG 3.1.1) | Thêm `<html lang="vi">` |

**META issue (silent, không xuất hiện trong axe report)**: Flutter web canvaskit render mọi UI vào `<canvas>` element. `<flt-semantics-host>` tồn tại nhưng `children.length = 0` → screen reader không đọc được nội dung Flutter widgets. Đây là giới hạn fundamental của Flutter web canvaskit cho assistive technology.

**4.10.2 Fixes applied (`web/index.html`)**

```html
<html lang="vi">
<title>PTIT Contest</title>
<script>
  window.addEventListener('flutter-first-frame', function() {
    var v = document.querySelector('meta[flt-viewport]');
    if (v) v.setAttribute('content', 'width=device-width, initial-scale=1.0');
  });
</script>
```

**4.10.3 Re-scan verify**

Sau rebuild release + re-run axe.run() ở 8 scans:

| Trước | Sau |
|:---:|:---:|
| 24 violations (3×8) | 8 violations (1×8) |

8 violations còn lại đều là `button-name` Claude extension (sẽ disappear ở production deploy không có extension).

→ **Real WCAG 2.1 AA violations = 0** ✓ baseline pass cho top 4 screens.

File: `11-docs/a11y-baseline-2026-05-07.md` (~310 dòng).

**4.10.4 Caveat quan trọng**

axe pass ≠ accessible. Flutter canvaskit Semantics tree rỗng → screen reader (NVDA/JAWS/VoiceOver) vẫn không đọc được nội dung Flutter widget. Phase C document baseline này như WARNING. Sprint 3 a11y deep cần wrap critical widgets bằng `Semantics(label, button)` hoặc đánh giá switch sang `--web-renderer html`.

**4.11 Phase B đợt 3 + Sprint 4 UX fix (2026-05-07)**

Sau khi seed account `gv@ptit.edu.vn` với `roles=[ADMIN, JUDGE, ORGANIZER]`, Phase B audit được mở rộng coverage 21/24 → 24/24 screens. Đợt 3 audit BCN/Admin Dashboard, BCN Giám sát, Admin Cuộc thi (3 screens × 3 viewport).

**4.11.1 Findings đợt 3**

Tổng đợt 3: **1 Critical + 4 Major + 5 Minor = 10 findings** mới. Aggregate Phase B (đợt 1+2+3): **5 Critical + 10 Major + 10 Minor = 25 findings** trên đầy đủ 24 screens. Tài liệu: `11-docs/ux-audit-2026-05-06.md`.

| ID | Severity | Tóm tắt |
|---|---|---|
| C5 | Critical | Pill widget status badge wrap broken khi width 567px (text "ONGOING" wrap 2 dòng vỡ layout) |
| M7 | Major | BCN Dashboard chỉ có 2 stats card, thiếu "Tổng cuộc thi" + "Vai trò" |
| M8 | Major | Admin Dashboard "Vai trò" hiển thị `null` cho HOD user (BE schema thiếu mapping) |
| M9 | Major | Admin Cuộc thi sort default = `created_at DESC`, nên sort theo `statusOrder` (DRAFT/PROPOSED → ONGOING → FINISHED) cho usability |
| M10 | Major | Admin Cuộc thi "Số entry" chỉ hiển thị count (vd "12"), nên thêm format "12/100" cho insight capacity |

**4.11.2 Sprint 4 fix triển khai**

Sprint 4 fix toàn bộ 1 Critical + 4 Major đợt 3 trong ~3-4h. Sau Sprint 4, **Phase B audit closed: Critical=0, Major=0** (chỉ còn 10 minor backlog defer).

| Fix | File | Note |
|---|---|---|
| C5 | `core/widgets/pill.dart` | Thêm `softWrap: false, maxLines: 1, overflow: TextOverflow.visible` |
| M7 | `features/admin/admin_dashboard_screen.dart` | Thêm `_HodStatsRow` 4 cards + provider `hodFacultyStatsProvider` gọi `/api/reports/faculty-summary` |
| M8 | `features/admin/admin_dashboard_screen.dart` | Đổi value display từ `null` → "HOD" cho user role HOD |
| M9 | `features/admin/admin_contests_screen.dart` | Map `statusOrder` cho sort: DRAFT/PROPOSED=0, ONGOING=1, FINISHED=2 |
| M10 | `features/admin/admin_contests_screen.dart` | Format `${entriesCount}/${maxEntries}` thay vì chỉ count |

**4.12 Sprint 3 + Sprint 5 --- A11y Semantics deep wrap (2026-05-07)**

Hai sprint a11y nối tiếp nhau giải quyết Phase C META issue (Flutter canvaskit Semantics rỗng):

**4.12.1 Sprint 3 baseline (~25 elements)**

Sprint 3 wrap 5 widget categories quan trọng nhất với pattern `Semantics(label, button, selected, hint, child: MaterialWidget)`:
- Login form fields + submit button
- Bottom navigation 6 tabs (Student shell)
- Primary CTA buttons (Đăng ký tham gia / Nộp bài / Đăng nhập)
- Sidebar admin items
- Notifications card list

Cần Tab key user trigger để Flutter detect assistive tech và render Semantics tree (canvaskit limit). Long-term recommend evaluate `--web-renderer html`.

**4.12.2 HTML renderer eval (decision document)**

Trước khi đi tiếp Sprint 5, em eval `--web-renderer html` trên Flutter 3.27.1 với 4 tiêu chí: visual regression / a11y improvement / performance / forward compatibility.

| Tiêu chí | canvaskit | html |
|---|---|---|
| Visual fidelity | ✅ Native | ⚠️ Một số animation degrade |
| A11y keyboard | ⚠️ Cần Tab trigger | ✅ Native DOM |
| First paint | 8.0MB main.dart.js | 1.5MB (-6.5MB) |
| Forward compat | ✅ Stable | ❌ Flutter 3.29 sẽ remove |

Decision: **KEEP canvaskit + tiếp tục wrap Semantics deeper** vì Flutter 3.29 (release Q3 2026) sẽ remove HTML renderer hoàn toàn. Tài liệu: `11-docs/html-renderer-eval-2026-05-07.md`.

**4.12.3 Sprint 5 deep wrap 9 categories**

Sprint 5 mở rộng coverage gấp 2-3 lần Sprint 3 với pattern chuẩn hoá:

```dart
Semantics(
  label: 'X — mô tả ngắn',
  button: true,
  enabled: condition,
  onTap: handler,  // forward cho assistive tech
  hint: 'Hint giải thích thao tác/yêu cầu',
  child: ExcludeSemantics(child: MaterialWidget(onTap: handler, ...)),
)
```

| # | Category | Sample label |
|---|---|---|
| 1 | Login form | "Đăng nhập Đăng nhập với email và mật khẩu" |
| 2 | Submission form | 4 TextField double-label aria + file picker + Nộp bài button |
| 3 | Register team + CTA | "Đăng ký tham gia" enabled / "Không nhận đăng ký, Đang diễn ra" disabled |
| 4 | Profile menu (DRY helper) | "Cập nhật thông tin Mở dialog hoặc màn hình..." |
| 5 | Admin sidebar 10 tabs | "Dashboard Đang ở mục này" / "Cuộc thi Chuyển sang mục Cuộc thi" |
| 6 | Admin Cuộc thi | "Olympic Tin học PTIT 2026, ONGOING, 1 đăng ký..." (label tổng hợp) |
| 7 | Approval Queue 3 button | "Reject — từ chối đề xuất Cần nhập comment lý do từ chối" + Request revision + Approve |
| 8 | BCN Giám sát monitor | "Cuộc thi X, trạng thái Y, A đề xuất, B bài nộp. Đăng ký P%, Nộp bài Q%, Chấm điểm R%" |
| 9 | Notifications card | "Đã đọc. [CONTEST] Title. Message. Lúc datetime Mở chi tiết" |

**4.12.4 Cải tiến đo được Sprint 5**

| Screen | Sprint 3 baseline | Sprint 5 actual | Δ |
|---|---|---|---|
| Login form | ~12 | 21 | +75% |
| Profile / Tôi | ~16 | 39 | +144% |
| Submission form | (chưa wrap) | 44 | NEW |
| Admin Dashboard | ~18 | 33 | +83% |
| Admin Cuộc thi | ~20 | 35 | +75% |
| BCN Giám sát | ~20 | 43 | +115% |
| Approval Queue dialog | ~12 | 22 | +83% |
| Notifications | (chưa wrap) | 22 | NEW |
| **Tổng 9 screen sample** | **~141** | **281** | **+99%** |

Live verify 8/9 + 1 partial qua live Semantics tree (click `flt-semantics-placeholder` "Enable accessibility" để Flutter render tree). Build canvaskit release pass 37.8s, no compile error. Deploy: `https://ptit-contest-app.pages.dev` commit `da72b3e` push `main`. Tài liệu: `11-docs/sprint5-a11y-baseline-2026-05-07.md`.

**4.13 Bổ sung infra 2026-05-07: Sentry FE + R2 upload**

Hai tính năng infrastructure được wire trong cùng ngày 2026-05-07:

**4.13.1 Sentry frontend Flutter Web**

Wire `sentry_flutter` package vào `main.dart`, init wrapper với DSN inject qua `--dart-define=SENTRY_DSN_FRONTEND=...`. Project Sentry: `mrb-personal/ptit-contest-flutter` (ID 4511345155571712), tag `app.platform: flutter-web` để tách FE vs BE issues. Verified capture qua test exception, Issue PTIT-CONTEST-FLUTTER-1 hiển thị đầy đủ release + environment + breadcrumbs.

```dart
const _sentryDsnFrontend = String.fromEnvironment('SENTRY_DSN_FRONTEND');
Future<void> main() async {
  usePathUrlStrategy();
  if (_sentryDsnFrontend.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = _sentryDsnFrontend;
      options.release = const String.fromEnvironment('APP_RELEASE', defaultValue: 'dev');
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
      options.sendDefaultPii = false;
    }, appRunner: () { ... });
  }
}
```

**4.13.2 Cloudflare R2 object storage**

Wire `aiobotocore` S3-compatible client vào BE `app/core/r2_client.py`. Bucket `ptit-contest-submissions` với hierarchy:

```
contests/{contest_id}/rounds/{round_id}/entries/{entry_id}/v{version}/{filename}
```

Lazy migration policy: submission cũ giữ BYTEA in-DB, submission mới upload R2 → presigned URL download. E2E verify pass với 61B text file `r2-verify-test.txt` upload SV → download GV. Free tier 10GB cho dev, scale lên paid sau khi production thực sự.

**CHƯƠNG 5 --- ĐÁNH GIÁ VÀ CẢI TIẾN**

**5.1 Hạn chế hiện tại**

**5.1.1 Hạn chế chức năng**

-   Đăng ký theo đội (TEAM) --- UI Flutter đã hoàn thiện cho create team, add member, register team mode. Tuy nhiên flow nhận lời mời tham gia team chưa có UI thực sự (BE đủ endpoint, FE tạm dùng popup).

-   Quét QR camera --- CertVerifyScreen hiện chỉ paste mã QR thủ công, chưa tích hợp camera scan thật. Icon Icons.qr\_code\_scanner gợi ý feature có nhưng chưa wire qrscanner package.

-   ~~Submission file upload --- hỗ trợ external link (Google Drive/GitHub) + text answer + multipart upload BYTEA ≤10MB. Production thật cần chuyển sang S3/R2 storage thay vì BYTEA in-DB.~~ **(ĐÃ FIX 2026-05-07)** Wire Cloudflare R2 với hierarchy `contests/{cid}/rounds/{rid}/entries/{eid}/v{n}/{filename}`. Lazy migration policy giữ BYTEA cũ. E2E verify pass (chương 4.13.2).

-   Search nâng cao --- \`/contests?q=\...\` chỉ ILIKE trên title. Chưa có full-text search Postgres tsvector, filter ghép nhiều tiêu chí, relevance ranking.

-   Pagination --- hầu hết list dùng pagination kiểu offset-based. Khi data tăng lớn (\>1000 contests), UX kém. Nên migrate cursor-based pagination + infinite scroll.

-   Live ranking khi GV chấm --- SV phải refresh tab \"Kết quả\" để xem update. Nên dùng WebSocket hoặc polling 30s.

**5.1.2 Hạn chế kỹ thuật**

-   Audit log search/filter --- DB có data đầy đủ nhưng admin UI chỉ là list cuộn. Cần filter theo user/action/contest/time range.

-   Cert revoke --- chưa có UI cho BCN revoke cert đã issue. Cần column \`revoked\_at + revoked\_reason\` + endpoint POST + audit trail.

-   ~~Sentry frontend --- hiện chỉ có BE Sentry. JS error trên Flutter Web chưa được capture.~~ **(ĐÃ FIX 2026-05-07)** Wire `sentry_flutter` package qua `--dart-define=SENTRY_DSN_FRONTEND=...`. Project `mrb-personal/ptit-contest-flutter` tách FE/BE qua tag `app.platform`. Verified capture (chương 4.13.1).

-   CI/CD --- chưa có GitHub Actions auto deploy. Mỗi lần push code phải manual \`wrangler pages deploy\` (frontend) và Railway tự deploy (backend OK).

-   xlsx import users --- admin chưa có chức năng upload Excel để bulk insert SV. Hiện chỉ create từng người 1.

-   Contest cloning --- GV chưa thể clone contest cũ (giữ rounds + scoring config + judges) để tạo contest mới giống template.

-   Auto-assign judges --- JUDGE phải được GV manually assign vào round. Không có random load balance.

**5.1.3 Hạn chế UI/UX**

-   ~~Dark mode --- chưa có~~. **(ĐÃ FIX)** Dark mode hoàn thiện 100% sau Phase A + Sprint 2 (484 tokens light/dark, 14 surface tokens, `achievementGold` mới thêm). Toggle ở Profile screen, persist `flutter.theme_mode` trong SharedPreferences.

-   i18n --- chưa có. Toàn bộ UI tiếng Việt. SV quốc tế kẹt.

-   ~~Flutter canvaskit Semantics rỗng (Phase C audit phát hiện) --- screen reader (NVDA / JAWS / VoiceOver) **không đọc được** nội dung Flutter widget vì framework render canvas, không có DOM elements thật. `<flt-semantics-host>` tồn tại nhưng children rỗng. Đây là giới hạn fundamental của Flutter web canvaskit, axe scan KHÔNG flag. Sprint 3 a11y deep cần wrap critical widgets bằng `Semantics(label, button)` hoặc switch sang `--web-renderer html` (DOM-based, slower).~~ **(ĐÃ FIX 2026-05-07 qua Sprint 3+5)** 9 widget categories wrap Semantics deep (login/submission/register/profile/sidebar 10 tabs/admin contests/approval queue/monitor/notifications). Coverage +99% nodes vs Sprint 3 baseline (chương 4.12). **Caveat còn lại:** Flutter canvaskit yêu cầu Tab key user trigger hoặc click `flt-semantics-placeholder` để render Semantics tree (assistive tech detection). Screen reader user sẽ trigger tự động qua AT shortcut. HTML renderer eval đã làm — quyết định KEEP canvaskit vì Flutter 3.29 sẽ remove HTML renderer.

-   7 minor UX backlog từ Phase B audit (search placeholder text inconsistency / bottom nav 6-item tight 380px / Profile empty state thiếu CTA / Contest Detail meta chip không có tooltip / Submission empty state CTA-less / Approval inbox empty CTA-less / Brand label "Cổng quản lý" không cân với "Sinh viên") --- chưa fix, defer Sprint 3.

-   Bottom sheet --- đa số confirm dialog dùng AlertDialog. Nên migrate sang ModalBottomSheet cho UX mobile-native.

-   Sidebar admin search --- admin có 9-10 tab, không có search nhanh navigate. Có thể thêm Cmd+K command palette.

-   Animation transition --- chuyển tab cứng. Có thể dùng Hero animation hoặc PageTransitionsBuilder cho smooth.

-   Empty state --- chỉ Icon + text. Có thể thêm illustration SVG cho personality.

**5.2 Lessons learned (13 bug fixes / patterns documented)**

Quá trình triển khai phát hiện 13 bug / pattern đáng chú ý, đã fix và document để tránh tái lặp:

1\. \*\*HSTS không xuất hiện\*\*: Railway/Cloudflare proxy terminate TLS → \`scope.scheme=http\` ở backend → fix đọc \`X-Forwarded-Proto\` header (giống pattern rate\_limit X-Forwarded-For đã có Phase 1.2).

2\. \*\*Notification click không nav\*\*: Route \`/me/entries\` không có trong GoRouter (6 tab là \*\*state\*\*, không phải route URL) → fix studentTabProvider global + map \_shellTabRoutes.

3\. \*\*Notification icon chuông flow\*\*: Modal NotificationsScreen che StudentShell → fix set tab provider + \`Navigator.pop()\` nếu canPop.

4\. \*\*Railway hobby block port 587\*\*: SMTP không gửi được → migrate Brevo HTTP API qua port 443 (HTTPS không bao giờ block).

5\. \*\*CORS Content-Disposition\*\* không expose default → \`expose\_headers=\[\"Content-Disposition\"\]\` cho FE đọc filename xlsx download.

6\. \*\*Flutter \`activeThumbColor\`\*\* chỉ Flutter 3.27+ → dùng \`activeColor\` cho compat (project dùng Flutter SDK cũ hơn).

7\. \*\*Migration UPDATE filter\*\*: \`LIKE \'%netlify%\'\` không match localhost (seed v3 cũ) → dùng \`NOT LIKE \'%pages.dev%\'\` để catch all non-canonical.

8\. \*\*Service Worker cache Flutter Web\*\*: hard refresh chưa đủ, cần unregister SW + Clear site data sau mỗi deploy. Memory đã ghi pattern: \`caches.delete()\` + \`serviceWorker.getRegistrations().forEach(unregister)\`.

9\. \*\*Cloudflare Pages Direct Upload\*\*: project tạo bằng `wrangler pages deploy` ban đầu KHÔNG có Git connection — Settings tab không có option enable. Phải tiếp tục manual deploy 30s mỗi lần. Workaround: keep wrangler workflow, document trong memory để future-em không tốn thời gian tìm kiếm.

10\. \*\*Flutter canvaskit a11y limitation\*\*: framework render `<canvas>` → axe scan thấy DOM rỗng → screen reader không có nội dung đọc. `<flt-semantics-host>` chỉ render khi assistive tech được Flutter detect. Cần wrap `Semantics(label, button)` cho widgets quan trọng hoặc switch `--web-renderer html`.

11\. \*\*Flutter `flt-viewport` hardcode\*\*: framework auto-inject `<meta name="viewport">` với `maximum-scale=1.0, user-scalable=no` (vi phạm WCAG 1.4.4 Resize text). Phải override sau `flutter-first-frame` event:
```javascript
window.addEventListener('flutter-first-frame', function() {
  var v = document.querySelector('meta[flt-viewport]');
  if (v) v.setAttribute('content', 'width=device-width, initial-scale=1.0');
});
```

12\. \*\*Sprint 2 UX audit pattern hiệu quả\*\*: ROI sort fix theo Critical → Major → Minor; audit-first-then-fix; screenshot 3 viewport (1440 / 768 / 567); group commit per file (5 commits cho 9 fixes vì share file). Critical 4→0 trong ~4h. Pattern reusable cho future audit cycles.

13\. \*\*Audit C2 false-diagnose\*\*: Phase B đợt 1 nói "Contest List meta chips render text rỗng do schema thiếu fields". Verify backend `ContestSummary` schema thấy đã có đủ `delivery_mode`, `participation_mode`, `host_faculty_id`. Bug thật là dark mode `_MetaChip` widget hardcode bg `Color(0xFFF7F2EC)` (cream) với text dùng `context.textPrimary` (theme-aware) → dark mode = light text trên light bg = invisible. Lesson: visual bug có thể có root cause khác hẳn surface symptom — phải verify code path trước khi đề xuất schema change.

**5.3 Roadmap Phase 2 Sprint 2 (DONE 2026-05-06)**

Sprint 2 đã pivot từ planned-roadmap (dark mode/audit search/cert revoke ban đầu liệt kê v01 báo cáo) sang **UX fix backlog từ Phase B audit** vì priority audit findings cao hơn:

| # | Module | Status | Note |
|---|---|---|---|
| 1 | Dark mode full app | DONE pre-Sprint 2 | 484 tokens, 14 surfaces (Phase A) |
| 2 | C3+M1 ShellRoute wrap sub-routes | DONE | `student_shell_scaffold.dart` ~250 LOC |
| 3 | C4 Admin shell breakpoint 768→1024 | DONE | Material standard |
| 4 | M4+M5+M6 Login form polish | DONE | maxWidth 480 + hide creds + footer kReleaseMode |
| 5 | C1+C2 Contest List sort + chip dark | DONE | statusOrder map + theme-aware bg |
| 6 | M3 achievementGold tokens | DONE | Tách khỏi warn semantic |
| 7 | Sentry frontend (Sprint 2 plan v01) | PENDING | Defer Sprint 3 |
| 8 | Audit log search + filter (Sprint 2 plan v01) | PENDING | Defer Sprint 3 |
| 9 | Cert revoke + audit trail (Sprint 2 plan v01) | PENDING | Defer Sprint 3 |
| 10 | xlsx import users (Sprint 2 plan v01) | PENDING | Defer Sprint 3 |
| 11 | Contest cloning (Sprint 2 plan v01) | PENDING | Defer Sprint 3 |
| 12 | Bottom sheet thay dialog (Sprint 2 plan v01) | PENDING | Defer Sprint 3 |
| 13 | Phase C a11y baseline | DONE 2026-05-07 | 24→0 real violations |

**Cải tiến đo được Sprint 2**: Critical 4→0, Major 6→2, Minor 7 backlog. Real WCAG 2.1 AA violations 24→0 (axe-core 4.10.0).

**5.3.bis Roadmap Sprint 3+4+5 (DONE 2026-05-07)**

3 sprint nối tiếp triển khai trong cùng ngày 2026-05-07, tổng ~14h work:

| STT | Module | Status | Note |
|---|---|---|---|
| 1 | a11y Semantics() Sprint 3 baseline | ✅ DONE | 5 widget categories ~25 elements (chương 4.12.1) |
| 2 | File upload S3/R2 cho submissions | ✅ DONE | Bucket `ptit-contest-submissions` lazy migration (chương 4.13.2) |
| 3 | Sentry frontend Flutter Web | ✅ DONE | Tag `app.platform: flutter-web` tách FE/BE (chương 4.13.1) |
| 4 | Phase B đợt 3 Admin Dashboard audit | ✅ DONE | 24/24 screens coverage. 1C+4M+5m findings (chương 4.11.1) |
| 5 | Sprint 4 fix Phase B đợt 3 | ✅ DONE | C5 + M7-M10 (chương 4.11.2). Phase B closed: Critical=0, Major=0 |
| 6 | HTML renderer eval | ✅ DONE | Decision KEEP canvaskit (Flutter 3.29 sẽ remove HTML) |
| 7 | a11y Semantics() Sprint 5 deep wrap | ✅ DONE | 9 categories +99% nodes vs Sprint 3 (chương 4.12.3) |

**5.3.ter Roadmap Sprint 6+ (planned)**

| STT | Module | Effort | ROI | Tóm tắt |
|---|---|---|---|---|
| 1 | Audit log search + filter UI | 1 ngày | 7 | Filter user/action/contest/time, paginate. |
| 2 | xlsx import users (admin bulk) | 1 ngày | 7 | openpyxl parse + bulk insert. |
| 3 | Contest cloning (template duplicate) | 1 ngày | 7 | Clone giữ rounds + scoring config + judges. |
| 4 | Cert revoke + audit trail | 0.5 ngày | 6 | Column `revoked_at + revoked_reason` + endpoint POST. |
| 5 | a11y headingLevel deep | 0.5 ngày | 5 | Cần upgrade Flutter 3.30+ (3.27 chưa support `headingLevel` đầy đủ). |
| 6 | Bottom sheet thay AlertDialog | 1 ngày | 5 | UX mobile-native. |
| 7 | i18n EN/VI (.arb files) | 2 ngày | 4 | SV quốc tế. |

**5.4 Roadmap Phase 3 Strategic (\~3-6 tháng)**

Các module phức tạp hơn, hướng làm sau khi tốt nghiệp hoặc nếu có thời gian extend đồ án:

-   **a11y deep --- Switch `--web-renderer html` hoặc full Semantics() audit (1-2 tuần)**: Phase C document META issue Flutter canvaskit Semantics rỗng. 2 lựa chọn: (a) build với HTML renderer (DOM-based, screen reader read được, trade-off perf cho complex animations), (b) audit toàn app + wrap ~50-100 widgets bằng `Semantics(label, button)`. Combo: (b) cho top critical widgets + (a) eval prod feasibility.

-   WebSocket real-time (3-4 ngày): Notification realtime + ranking live khi GV chấm xong → SV thấy update ngay. Cần Redis pub/sub.

-   FCM push notification (3-4 ngày): Mobile push thật ngoài app (notification banner Android). Cần Firebase project + APN cert iOS.

-   AI auto-grading (1-2 tuần): Dùng GPT-4 hoặc Claude API chấm code SV nộp + sinh feedback. Cost \~\$0.1/submission. Cần Docker sandbox chạy code an toàn.

-   i18n EN/VI (2 ngày): .arb files Flutter, 2 ngôn ngữ.

-   PTIT SSO integration (defer): Cần phối hợp phòng IT của PTIT, không khả thi trong phạm vi đồ án.

**CHƯƠNG 6 --- KẾT LUẬN**

**6.1 Kết quả đạt được**

Đề tài đã hoàn thành mục tiêu xây dựng hệ thống quản lý cuộc thi sinh viên PTIT từ giai đoạn requirements, thiết kế, lập trình tới triển khai sản phẩm thật lên Internet, vượt mức kỳ vọng \"prototype demo\" của một đồ án CNPM thông thường. Các kết quả chính:

-   Backend FastAPI 99 endpoints qua 14 router, 43 SQLAlchemy 2.0 async models, \~5500 dòng code Python. Schema PostgreSQL \~25 bảng + 16 ENUM types.

-   Frontend Flutter 1 codebase 2 build target (APK Android 23MB + Web 2.8MB main.dart.js). 27+ screens responsive web/mobile.

-   Phase 1 Production Foundation hoàn thành 100% (5/5 step): Sentry + Rate limit + Refresh token + Email Brevo HTTP API + HSTS A+ với 6 security headers (đạt grade A+ securityheaders.com).

-   Phase 2 Sprint 1 Quick Wins hoàn thành 100% (5/5 step): Notification deep-link + Bulk approve entries (productivity \~30x cho GV) + Excel export 4 sheets + Biometric login APK + Loading skeleton shimmer 5 screens.

-   Migration thành công Netlify → Cloudflare Pages (free 500 builds/mo + unlimited bandwidth) sau khi Netlify hết quota build minutes.

-   **Phase A Design tokens** (2026-05-06): 4 token files mới (spacing/radius/durations/breakpoints) + design_lint.ps1 script + DESIGN-REVIEW-CHECKLIST.md. Lint violations 334→269 (-19%). Category 3+5 (radius + breakpoint) đạt 0% violations.

-   **Phase B UX visual audit** đợt 1+2 (2026-05-06): 21/24 screens × 3 viewport (1440/768/567). 17 findings (4 Critical + 6 Major + 7 Minor) document tại `11-docs/ux-audit-2026-05-06.md` (449 dòng).

-   **Sprint 2 UX fix** (2026-05-06 evening): 9/9 fixes triển khai theo ROI sort. Critical 4→0, Major 6→2. 5 commits push GitHub + manual deploy Cloudflare Pages.

-   **Phase C A11y baseline** (2026-05-07): axe-core 4.10.0 scan 8 viewports. WCAG 2.1 AA real violations 24→0. Document META issue Flutter canvaskit Semantics rỗng cho Sprint 3 deep.

-   **Phase B đợt 3 + Sprint 4** (2026-05-07): coverage Phase B đầy đủ 24/24 screens với 1C+4M+5m mới. Sprint 4 fix Critical=0, Major=0 (chỉ 10 minor backlog).

-   **Sprint 3 + Sprint 5 a11y Semantics deep wrap** (2026-05-07): 9 widget categories (~281 nodes vs Sprint 3 baseline 141 = +99%). Pattern chuẩn `Semantics(label, button, enabled, onTap, hint, child: ExcludeSemantics(MaterialWidget))`. HTML renderer eval decision KEEP canvaskit.

-   **Sentry frontend + R2 storage** (2026-05-07): Sentry FE Flutter Web wire xong (tag `app.platform`). Cloudflare R2 wire submission upload với hierarchy `contests/{cid}/rounds/{rid}/entries/{eid}/v{n}/`. Lazy migration policy.

-   Document hoá 13 bug fixes quan trọng với root cause + solution để tránh tái lặp trong tương lai.

-   Tổng chi phí vận hành: 0 đồng/tháng (Railway trial credit) + sau trial \$5/tháng --- phù hợp dự án giáo dục.

**6.2 Bài học kinh nghiệm**

Qua quá trình triển khai dự án thật từ A-Z, em rút ra các bài học quan trọng:

-   \*\*Production deployment khác xa local dev\*\*: Railway block outbound port 587 SMTP, Cloudflare/Railway proxy terminate TLS → \`scope.scheme=http\`, Netlify hết quota build minutes --- những vấn đề này không gặp khi dev local. Cần migrate sang HTTP API (port 443) và đọc X-Forwarded-Proto header.

-   \*\*Service Worker cache Flutter Web\*\* rất \"ngoan cố\": hard refresh chưa đủ, phải unregister SW + Clear site data + reload sau mỗi deploy. Mẹo: thêm timestamp query param hoặc dùng Cloudflare Pages purge API.

-   \*\*CORS expose\_headers\*\* mặc định chỉ cho 6 simple headers. Khi cần FE đọc Content-Disposition (filename download), Content-Length, Set-Cookie phải set explicit \`expose\_headers=\[\...\]\`.

-   \*\*Sliding window refresh token\*\* + biometric tận dụng tốt hạ tầng Phase 1: lần đầu login email/pass save refresh, lần sau biometric prompt → /auth/refresh → vào app trong 1-2 giây. KHÔNG cần redesign auth backend.

-   \*\*Pattern provider global + canPop\*\*: 6 tab bottom nav là state, không phải route URL. Deep-link nav giữa các tab phải dùng global Riverpod Provider thay vì context.push() → tránh \"page not found\".

-   \*\*Idempotent migration UPDATE seed\*\* rất hữu ích: dùng \`WHERE config\_value NOT LIKE %canonical%\` để catch all non-canonical values, không phải hardcode old value cụ thể (vd %netlify% miss localhost).

**6.3 Hướng phát triển tiếp theo**

Sau khi kết thúc đồ án CNPM, hệ thống có thể tiếp tục phát triển theo 3 hướng:

\*\*Hướng 1 --- Sprint 3 Productivity & A11y (\~10-15h, 1-2 tuần)\*\*: 7 module priority cao ở chương 5.3.bis. Top 3: (1) a11y Semantics() top 10 widgets fix Phase C META issue, (2) Sentry frontend bổ sung JS error capture (BE đã có), (3) File upload S3/R2 cho submissions thay vì link external.

\*\*Hướng 2 --- Mở rộng Phase 3 (\~3-6 tháng)\*\*: Tích hợp WebSocket cho real-time notification, FCM push mobile, AI auto-grading code submission qua OpenAI/Claude API, i18n EN/VI cho SV quốc tế. Eval `--web-renderer html` cho a11y deep.

\*\*Hướng 3 --- Sản xuất hoá\*\*: Nếu PTIT IT chấp nhận cooperation, có thể tích hợp SSO PTIT cổng đào tạo, migrate file storage từ BYTEA sang S3/R2, scale Postgres qua read replica, container hoá qua Docker Compose / Kubernetes cho high availability.

Codebase hiện tại đã có foundation đủ tốt (Clean Architecture, RBAC, audit log, security A+, dark mode 100%, design tokens, WCAG 2.1 AA baseline pass) để extend các hướng trên mà không cần refactor lớn. Tài liệu memory + Notion + báo cáo này là source of truth cho future maintainer.

**PHỤ LỤC A --- URL PRODUCTION VÀ TÀI KHOẢN DEMO**

**A.1 URL Production**

  ---------------------------------------- ----------------------------------------------------------------------------------
  **Frontend Web**                         https://ptit-contest-app.pages.dev
  **Backend API**                          https://ptit-contest-mobile-app-production.up.railway.app
  **API Documentation (Swagger)**          https://ptit-contest-mobile-app-production.up.railway.app/api/docs
  **GitHub Repository**                    https://github.com/himono792-alt/ptit-contest-mobile-app
  **Sentry Dashboard**                     https://mrb-personal.sentry.io
  **Brevo Email Dashboard**                https://app.brevo.com
  **Cloudflare Pages Dashboard**           https://dash.cloudflare.com
  **Railway Project (brilliant-solace)**   https://railway.com
  **SecurityHeaders.com Scan**             https://securityheaders.com/?q=ptit-contest-mobile-app-production.up.railway.app
  ---------------------------------------- ----------------------------------------------------------------------------------

**A.2 Tài khoản demo (password chung: abc123)**

  ---------------------------- ------------------------- ------------------------- -----------------------------------------------------
  **Vai trò**                  **Email**                 **Roles**                 **Ghi chú**
  Sinh viên                    b22dccn001\@ptit.edu.vn   STUDENT                   2 entries FINISHED + 2 cert Giải Nhất sẵn data demo
  Giảng viên + Admin + Judge   gv\@ptit.edu.vn           ADMIN, JUDGE, ORGANIZER   Quản trị toàn hệ thống cho mục đích demo
  Trưởng khoa (BCN)            bcn\@ptit.edu.vn          HOD                       Phê duyệt QĐ1/QĐ2/QĐ3 các contest thuộc khoa
  ---------------------------- ------------------------- ------------------------- -----------------------------------------------------

**A.3 Stats 2 ngày làm việc (2026-05-06 + 2026-05-07)**

| Metric | 2026-05-06 (Phase A+B+Sprint 2+C) | 2026-05-07 (Phase B đợt 3+Sprint 3+4+5+infra) | Tổng |
|---|---|---|---|
| Tasks completed | 43 | 31+ | 74+ |
| Files thay đổi | 35+ | 25+ | 60+ |
| Findings audited | 17 (Phase B đợt 1+2) | 10 (Phase B đợt 3) | 27 (loại 2 dup) → 25 unique |
| Critical/Major resolved | 4C → 0, 6M → 2 | 1C → 0, 4M → 0 | All Critical+Major closed |
| A11y nodes | (chưa wrap) | 141 baseline → 281 (+99%) | 281 nodes 9 screen sample |
| Infra wire | Sentry BE + Email | Sentry FE + R2 storage | Full observability + storage |
| Commits push main | 5 | 6+ (last `da72b3e`) | 11+ |
| Deploy Cloudflare Pages | 5 | 4 | 9 |

-   24 bug fixes / patterns documented (13 chương 5.2 + 11 mới 2026-05-07 trong sprint5 + html-eval doc).

-   2 migration: Netlify → Cloudflare Pages, URL canonical 6 chỗ.

-   A+ securityheaders.com với 6 security headers.

-   Zero downtime trong toàn bộ quá trình migration.

-   Phase B audit closed (Critical=0, Major=0).

-   A11y deep wrap 9/9 categories — 8/9 live verified, 1/9 partial (cần REG_OPEN contest dev env).

**TÀI LIỆU THAM KHẢO**

\[1\] FastAPI Documentation --- https://fastapi.tiangolo.com/

\[2\] Flutter Documentation --- https://docs.flutter.dev/

\[3\] SQLAlchemy 2.0 Documentation --- https://docs.sqlalchemy.org/

\[4\] Riverpod 2 Documentation --- https://riverpod.dev/

\[5\] Pydantic v2 Documentation --- https://docs.pydantic.dev/

\[6\] Brevo Transactional Email API --- https://developers.brevo.com/reference/sendtransacemail

\[7\] Cloudflare Pages --- https://developers.cloudflare.com/pages/

\[8\] Railway Deploy Guide --- https://docs.railway.app/

\[9\] Sentry FastAPI Integration --- https://docs.sentry.io/platforms/python/integrations/fastapi/

\[10\] OWASP Security Headers Best Practices --- https://owasp.org/www-project-secure-headers/

\[11\] HSTS Preload List --- https://hstspreload.org/

\[12\] Flutter local\_auth package --- https://pub.dev/packages/local\_auth

\[13\] Flutter shimmer package --- https://pub.dev/packages/shimmer

\[14\] openpyxl Documentation --- https://openpyxl.readthedocs.io/

\[15\] Material Design Guidelines --- https://m3.material.io/
