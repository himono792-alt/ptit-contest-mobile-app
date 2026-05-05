# Cải tiến module — toàn vẹn Backend + Frontend

Tài liệu phân tích theo từng module và roadmap cải tiến sắp xếp theo **ROI** (Return on Investment = Impact ÷ Effort).

---

## 1. Methodology

### Ký hiệu

- **Impact**: 1 (thấp) → 5 (rất cao)
- **Effort**: 1 (≤ 0.5 ngày) → 5 (>2 tuần)
- **ROI** = Impact × 2 ÷ Effort. ROI ≥ 4 = Quick win.
- **Trạng thái BE/FE**: ✅ Done, ⚠️ Partial, ❌ Missing

### Tiêu chí đánh giá Impact

- User-facing impact: bao nhiêu user hưởng lợi
- Workflow blocker: nếu thiếu thì user kẹt thật sự
- Technical debt: gỡ bỏ được nợ kỹ thuật về sau
- Demo wow factor: ấn tượng cho thầy hướng dẫn / khách hàng

---

## 2. Backend modules (14)

### 2.1 `auth` — Đăng nhập / đăng ký

**Trạng thái**: ✅ Login + JWT + register + forgot/reset (dev mode token)

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Email service thật (SendGrid/SMTP PTIT) | 5 | 2 | 5.0 | Forgot password chỉ còn dev token, prod cần email thật |
| Refresh token + rotating | 4 | 2 | 4.0 | JWT 8h → user phải re-login mỗi sáng → bực |
| Rate limit login + forgot | 4 | 1 | 8.0 | **Quick win** — chống brute-force |
| OAuth2 / SSO PTIT | 3 | 5 | 1.2 | Tích hợp cổng đào tạo PTIT |
| 2FA TOTP cho admin/HOD | 4 | 3 | 2.7 | Bảo vệ account quyền cao |
| Email verification at register | 3 | 1 | 6.0 | Confirm email PTIT trước khi active account |

**Top ưu tiên**: Rate limit (1 ngày) → Email verification → Email service prod

### 2.2 `users` — Profile

**Trạng thái**: ✅ /me GET + PATCH (11 fields), change password, soft delete

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Avatar upload (S3/R2) | 4 | 3 | 2.7 | Hiện chỉ có avatar_url field, không có endpoint upload |
| Activity log "lần truy cập gần nhất" | 2 | 1 | 4.0 | Track per-device session |
| Export profile data (GDPR) | 2 | 2 | 2.0 | User download data của mình |
| Block / unblock user khác (cho group) | 1 | 3 | 0.7 | Future for messaging feature |

**Top ưu tiên**: Activity log → Avatar upload

### 2.3 `contests` — CRUD cuộc thi

**Trạng thái**: ✅ CRUD + transition-status + rounds + sessions

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Full-text search Postgres `tsvector` | 4 | 2 | 4.0 | **Quick win** — Tìm theo title/desc/rules với GIN index |
| Filter ghép nhiều tiêu chí | 4 | 1 | 8.0 | **Quick win** — faculty + delivery + date range + prize |
| Pagination cursor-based | 3 | 1 | 6.0 | Hiện offset-based, kém hiệu suất với data lớn |
| Soft delete + restore | 3 | 1 | 6.0 | Hiện DELETE hard. SV/GV có thể undo |
| Contest cloning (làm template) | 4 | 1 | 8.0 | **Quick win** — Tổ chức contest tương tự năm sau |
| Recurring contest (định kỳ) | 3 | 3 | 2.0 | Auto-create contest hàng tháng/năm |
| Contest categories/tags | 3 | 1 | 6.0 | Hashtag để SV browse theo chủ đề |
| Bulk import contests CSV | 2 | 2 | 2.0 | Cho admin import nhiều contest cùng lúc |

**Top ưu tiên**: Filter + Cloning + Tags (3 quick wins, 3 ngày total)

### 2.4 `approvals` — Workflow phê duyệt 2 cấp

**Trạng thái**: ✅ Submit QĐ1+QĐ2 + BCN decide + revision loop

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| WebSocket real-time notify BCN | 4 | 3 | 2.7 | BCN biết ngay khi có request |
| Auto-escalate sau 48h không decision | 3 | 2 | 3.0 | Reminder + escalate to ADMIN |
| Approval delegation (BCN ủy quyền) | 3 | 2 | 3.0 | BCN nghỉ phép → assign tạm |
| Comment thread (không chỉ 1 note) | 2 | 2 | 2.0 | Dialogue revision |
| Approval template / preset | 2 | 1 | 4.0 | "Reject vì lý do X thường gặp" |
| Approval analytics dashboard | 3 | 2 | 3.0 | BCN xem stats: avg time, reject rate |

**Top ưu tiên**: Auto-escalate → Approval template

### 2.5 `entries` — Đăng ký SV

**Trạng thái**: ✅ Register individual + GV approve + SV cancel + /me/entries

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Waitlist khi contest full | 4 | 2 | 4.0 | **Quick win** — Khi `max_entries` đủ thì queue |
| Bulk approve entries | 4 | 1 | 8.0 | **Quick win** — Check-all + approve một loạt |
| Auto-approve nếu match criteria | 3 | 2 | 3.0 | Vd: SV cùng khoa + GPA ≥7 |
| Entry quota theo khoa | 3 | 2 | 3.0 | Mỗi khoa max N entry |
| Withdrawal reason analytics | 2 | 1 | 4.0 | Tại sao SV hủy đăng ký |

**Top ưu tiên**: Bulk approve + Waitlist (3 ngày, ROI cao)

### 2.6 `teams` — Đội thi đấu

**Trạng thái**: ⚠️ Backend đủ 4 endpoints (create, add member, get, register team) nhưng **frontend chưa có UI**

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Frontend UI team management | 5 | 2 | 5.0 | **Critical** — Chặn cuộc thi team |
| Invitation system (email link join team) | 3 | 2 | 3.0 | Leader gửi invite, member accept |
| Team chat / discussion | 2 | 5 | 0.8 | Future for collab |
| Team profile page (avatar, motto) | 2 | 1 | 4.0 | Brand cho team |
| Auto team formation | 1 | 4 | 0.5 | AI gợi ý team theo skill |

**Top ưu tiên**: Frontend team UI (P0 — module này đã có backend, chỉ thiếu UI)

### 2.7 `submissions` — Bài nộp

**Trạng thái**: ✅ POST/GET versions + lock. ⚠️ Chỉ external link + text answer, không upload file

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| File upload S3/R2 (PDF, ZIP) | 5 | 3 | 3.3 | Workflow blocker — cuộc thi báo cáo bắt buộc PDF |
| Multi-file upload (up to N) | 3 | 1 | 6.0 | Code + slides + report cùng lúc |
| Plagiarism detection | 4 | 5 | 1.6 | Compare giữa các bài nộp |
| Code execution sandbox | 4 | 5 | 1.6 | Auto-test code submission |
| Version diff viewer | 3 | 2 | 3.0 | So sánh v1 vs v2 |
| Late submission penalty config | 2 | 1 | 4.0 | Auto trừ điểm % theo phút trễ |

**Top ưu tiên**: File upload (P0 nếu tổ chức cuộc thi có file)

### 2.8 `judging` — Chấm điểm

**Trạng thái**: ✅ Rubric + assignment + score bulk + compute

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Anonymous grading mode | 4 | 2 | 4.0 | **Quick win** — Hide SV identity, fair judge |
| Multiple judges per entry + average | 4 | 2 | 4.0 | Hiện 1 judge → có thể bias |
| Inter-rater reliability stats | 3 | 2 | 3.0 | Phát hiện judge chấm khác biệt lớn |
| Auto-assign judges (round-robin) | 4 | 1 | 8.0 | **Quick win** — Thay vì assign manual |
| Judge comment public/private | 3 | 1 | 6.0 | Show feedback cho SV |
| AI-assisted grading suggestion | 4 | 5 | 1.6 | LLM gợi ý điểm dựa rubric |
| Calibration set (judge train) | 2 | 3 | 1.3 | Judge thử chấm mẫu trước |

**Top ưu tiên**: Auto-assign + Anonymous grading + Judge comment (4 ngày, 3 quick wins)

### 2.9 `results` — Kết quả + Publish

**Trạng thái**: ✅ Compute + Submit QĐ2 + Publish. ⚠️ `notified_count: 0` không thực sự gửi

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Bulk notification + email khi publish | 5 | 2 | 5.0 | **Critical** — SV cần biết khi có kết quả |
| Recompute results (sửa rubric weight retroactive) | 3 | 2 | 3.0 | Khi phát hiện sai sót sau publish |
| Results visualization (chart) | 3 | 2 | 3.0 | Distribution score, top winners |
| Export results PDF/Excel | 4 | 1 | 8.0 | **Quick win** — BCN in báo cáo |
| Compare results across years | 3 | 2 | 3.0 | Trend per faculty |

**Top ưu tiên**: Bulk noti + Export (3 ngày)

### 2.10 `reviews` — Đánh giá cuộc thi

**Trạng thái**: ✅ POST/PATCH/GET + summary

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Review reply (BTC trả lời) | 3 | 2 | 3.0 | Thread review |
| Review categories (Tổ chức / Đề thi / Giải thưởng) | 3 | 1 | 6.0 | Rate riêng từng phần |
| Verified review (only SV đã tham gia) | 4 | 1 | 8.0 | **Quick win** — Đã filter rồi nhưng add badge |
| Review helpful votes | 2 | 2 | 2.0 | Bubble up review hữu ích |
| Review moderation auto (spam detect) | 3 | 3 | 2.0 | LLM detect spam trước khi public |

**Top ưu tiên**: Verified badge + Categories (1.5 ngày)

### 2.11 `notifications` — Thông báo

**Trạng thái**: ✅ List + mark-read + mark-all-read. ⚠️ Chỉ in-app, không push/email

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| FCM push notification (Android) | 5 | 3 | 3.3 | App đóng vẫn nhận được |
| APNs push (iOS) | 5 | 4 | 2.5 | Cần Apple Dev Account $99/year |
| Email digest hàng ngày | 4 | 2 | 4.0 | **Quick win** — Tổng hợp noti/ngày |
| Notification preference (chọn loại nhận) | 3 | 2 | 3.0 | SV opt-out spam |
| Deep-link tới resource | 5 | 1 | 10.0 | **Quick win** — Backend trả thêm `target_route`, FE navigate |
| Group notifications by type | 2 | 1 | 4.0 | UI gom nhóm |
| Read time tracking | 2 | 1 | 4.0 | Stats: bao nhiêu user đọc |

**Top ưu tiên**: Deep-link (1 ngày, ROI 10) → Email digest → FCM push

### 2.12 `certificates` — Chứng nhận + QR verify

**Trạng thái**: ✅ Template + BCN approve + Activate + Issue + QR verify + HTML render

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| PDF generation thật (weasyprint) | 5 | 2 | 5.0 | Hiện HTML, in ra PDF chất lượng kém |
| Cert đẹp với background image PTIT | 3 | 1 | 6.0 | **Quick win** — Upload background_image_url |
| Blockchain verify (NFT-like) | 2 | 5 | 0.8 | Future demo công nghệ |
| Bulk download certs ZIP | 3 | 1 | 6.0 | **Quick win** — Admin tải hết certs cuộc thi |
| Cert sharing social media | 3 | 2 | 3.0 | LinkedIn / Facebook badge |
| Cert revocation (recall) | 4 | 1 | 8.0 | **Quick win** — Khi phát hiện gian lận |
| Cert template marketplace | 1 | 4 | 0.5 | Future — chia sẻ template giữa khoa |

**Top ưu tiên**: Cert revoke + Bulk download + Background image (2.5 ngày)

### 2.13 `reports` — Báo cáo / Stats

**Trạng thái**: ✅ system-summary + (faculty-summary endpoint có nhưng không dùng UI)

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Time-series stats (registrations theo ngày) | 4 | 2 | 4.0 | Cho chart trend |
| Faculty comparison report | 4 | 2 | 4.0 | So sánh khoa nào active hơn |
| SV personal report (cuối kỳ) | 3 | 2 | 3.0 | Tổng kết cuộc thi đã tham gia + rank |
| Export Excel/CSV report | 4 | 1 | 8.0 | **Quick win** — Cho BCN đem in |
| Custom date range stats | 3 | 1 | 6.0 | Filter theo tuần/tháng/quý |
| Predictive analytics (ML) | 3 | 5 | 1.2 | Forecast số đăng ký |

**Top ưu tiên**: Export + Time-series (3 ngày)

### 2.14 `admin` — Quản trị

**Trạng thái**: ✅ Users CRUD + master data + configs + audit + review moderation + bulk import

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Audit log filter + search | 4 | 1 | 8.0 | **Quick win** — Hiện scroll dài, không filter |
| Audit log export | 3 | 1 | 6.0 | **Quick win** — Cho compliance |
| Roles permissions matrix UI | 3 | 2 | 3.0 | Visual grid role × resource × CRUD |
| User import từ Excel (.xlsx) | 4 | 1 | 8.0 | **Quick win** — Hiện chỉ CSV paste |
| Configs JSON schema validation | 3 | 2 | 3.0 | Tránh sai key/value |
| Soft delete recovery dashboard | 3 | 2 | 3.0 | Restore user/contest đã xóa |
| Health check chi tiết | 2 | 1 | 4.0 | DB / Redis / S3 / Email status |

**Top ưu tiên**: Audit search + filter + export + xlsx import (3 ngày, 4 quick wins)

---

## 3. Frontend modules (3 chính)

### 3.1 `auth/` — Login + Forgot Password

**Trạng thái**: ✅ Login + Forgot 2 screens (Request + Reset)

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Biometric login (FaceID/TouchID) | 4 | 2 | 4.0 | **Mobile native** UX |
| Remember me checkbox | 3 | 1 | 6.0 | **Quick win** — Lưu email, không pass |
| Auto-login khi mở app (refresh token) | 5 | 2 | 5.0 | Critical UX |
| Welcome onboarding (3 slides) | 3 | 2 | 3.0 | Cho user mới hiểu app |
| Login với Google (OAuth) | 4 | 3 | 2.7 | Social login |
| Captcha (hCaptcha free) | 3 | 1 | 6.0 | **Quick win** — Anti-bot |

**Top ưu tiên**: Remember me + Auto-login + Captcha (4 ngày)

### 3.2 `student/` — SV mobile app (8 màn)

**Trạng thái**: ✅ 8 màn hoàn chỉnh + responsive

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| **Team registration UI** | 5 | 2 | 5.0 | **P0** — backend đã có |
| QR scan camera (cert verify) | 4 | 1 | 8.0 | **Quick win** — package mobile_scanner |
| File upload submission | 5 | 2 | 5.0 | **P0** — sau khi BE có S3 |
| Notification deep-link | 5 | 1 | 10.0 | **Quick win** — sau khi BE return target_route |
| Loading skeleton | 3 | 1 | 6.0 | **Quick win** — perceived perf |
| Empty state illustration | 2 | 1 | 4.0 | Polish UI |
| Dark mode | 4 | 3 | 2.7 | User demand cao |
| Swipe actions (Slidable) | 3 | 1 | 6.0 | Native mobile UX |
| Bottom sheet thay dialog | 3 | 1 | 6.0 | Native mobile UX |
| Haptic feedback | 2 | 1 | 4.0 | Polish |
| Recommendation contest (collab filter) | 4 | 4 | 2.0 | "Cho bạn" section trên home |
| Calendar view contests | 3 | 2 | 3.0 | Lịch tháng dạng calendar |
| Search global Cmd+K | 3 | 2 | 3.0 | Tìm contest/cert/sv |

**Top ưu tiên**: Team UI + QR scan + Deep-link + Skeleton (5 ngày, 4 P0/quick wins)

### 3.3 `admin/` — Web sidebar + Mobile drawer (10 màn)

**Trạng thái**: ✅ 10 màn + responsive + ContestAdminDetail 6 tabs

| Cải tiến | Impact | Effort | ROI | Note |
|---|---|---|---|---|
| Cmd+K command palette | 4 | 1 | 8.0 | **Quick win** — Power user love |
| Bulk actions (review, users) | 4 | 2 | 4.0 | Checkbox + bulk toolbar |
| Sidebar search | 3 | 1 | 6.0 | **Quick win** — Filter 10 items |
| Inline edit cells | 4 | 2 | 4.0 | Edit award_title không qua dialog |
| Drag-drop reorder rounds/criteria | 3 | 2 | 3.0 | UX tốt hơn nhập số |
| Stepper workflow ContestAdminDetail | 4 | 2 | 4.0 | 6 tabs → wizard linear |
| Dashboard chart sparkline | 3 | 2 | 3.0 | Trend 7 ngày |
| Quick filter chips (saved view) | 3 | 1 | 6.0 | "Contests cần tôi duyệt" |
| Activity feed real-time | 4 | 3 | 2.7 | WebSocket audit log live |
| Right-click context menu | 3 | 2 | 3.0 | Web power user |
| Export tab content (CSV/PDF) | 4 | 2 | 4.0 | Mọi list export được |

**Top ưu tiên**: Cmd+K + Sidebar search + Bulk actions (4 ngày, 3 quick wins)

---

## 4. Cross-cutting concerns

### 4.1 Performance

| Cải tiến | Impact | Effort | ROI |
|---|---|---|---|
| Database indexes audit (slow query log) | 4 | 2 | 4.0 |
| Redis cache `/contests` list (TTL 30s) | 4 | 1 | 8.0 |
| CDN images (Cloudflare) | 3 | 1 | 6.0 |
| Bundle size Flutter web (defer route) | 3 | 2 | 3.0 |
| Riverpod cache keepAlive | 3 | 1 | 6.0 |

### 4.2 Security

| Cải tiến | Impact | Effort | ROI |
|---|---|---|---|
| Rate limiting (slowapi + Redis) | 5 | 1 | 10.0 |
| HTTPS-only HSTS header | 4 | 1 | 8.0 |
| CSP headers | 3 | 1 | 6.0 |
| OWASP Top 10 audit | 5 | 5 | 2.0 |
| Penetration test (đặt 3rd-party) | 5 | 5 | 2.0 |
| Secrets management (Vault) | 4 | 3 | 2.7 |
| Audit immutability (append-only) | 3 | 2 | 3.0 |

### 4.3 Testing

| Cải tiến | Impact | Effort | ROI |
|---|---|---|---|
| Backend pytest + httpx async (cov 80%) | 5 | 5 | 2.0 |
| Flutter widget test (component) | 4 | 4 | 2.0 |
| Integration test (Maestro mobile) | 4 | 3 | 2.7 |
| Playwright E2E web | 4 | 3 | 2.7 |
| Load test (k6 / locust) | 4 | 2 | 4.0 |
| Contract test (Pact) | 3 | 3 | 2.0 |

### 4.4 DevOps / Observability

| Cải tiến | Impact | Effort | ROI |
|---|---|---|---|
| GitHub Actions CI (test + build) | 5 | 2 | 5.0 |
| Auto-deploy backend on main push | 4 | 1 | 8.0 |
| Sentry error tracking | 5 | 1 | 10.0 |
| Prometheus metrics + Grafana | 4 | 3 | 2.7 |
| Log aggregation (Loki + Grafana) | 4 | 3 | 2.7 |
| Pre-commit hooks (black, ruff, dart format) | 3 | 1 | 6.0 |
| Renovate bot (auto bump deps) | 3 | 1 | 6.0 |

---

## 5. Roadmap sắp xếp theo ROI

### TIER 1 — Quick wins ROI ≥ 8 (làm trước)

Effort 11-12 ngày, gồm 14 items đem lại impact lớn nhất:

| # | Module | Cải tiến | Impact | Effort | ROI |
|---|---|---|---|---|---|
| 1 | notifications | **Deep-link tới resource** | 5 | 1 | 10.0 |
| 2 | security | **Rate limit (slowapi+Redis)** | 5 | 1 | 10.0 |
| 3 | devops | **Sentry error tracking** | 5 | 1 | 10.0 |
| 4 | auth | Rate limit login + forgot | 4 | 1 | 8.0 |
| 5 | contests | Filter ghép nhiều tiêu chí | 4 | 1 | 8.0 |
| 6 | contests | Contest cloning | 4 | 1 | 8.0 |
| 7 | entries | Bulk approve | 4 | 1 | 8.0 |
| 8 | judging | Auto-assign judges | 4 | 1 | 8.0 |
| 9 | results | Export Excel/PDF | 4 | 1 | 8.0 |
| 10 | reviews | Verified badge | 4 | 1 | 8.0 |
| 11 | certificates | Cert revoke | 4 | 1 | 8.0 |
| 12 | admin | Audit search + filter | 4 | 1 | 8.0 |
| 13 | admin | xlsx import users | 4 | 1 | 8.0 |
| 14 | student | QR scan camera | 4 | 1 | 8.0 |
| 15 | student | Deep-link FE | 5 | 1 | 10.0 |
| 16 | admin | Cmd+K palette | 4 | 1 | 8.0 |
| 17 | performance | Redis cache list | 4 | 1 | 8.0 |
| 18 | security | HSTS HTTPS-only | 4 | 1 | 8.0 |
| 19 | devops | Auto-deploy CI | 4 | 1 | 8.0 |

### TIER 2 — High value ROI 5-7.9 (sprint sau)

~15 items, effort 2-3 tuần:
- Email service prod, Refresh token, File upload S3
- Bulk notification publish, Multi-judges
- Loading skeleton, Bottom sheet, Sidebar search
- Inline edit, Stepper conversion
- Pagination cursor, Soft delete restore, Tags

### TIER 3 — Strategic ROI 2-4.9 (medium-long term)

- Dark mode, i18n, Real-time WebSocket
- Push notification FCM/APNs
- Plagiarism detection, AI-assisted grading
- Anonymous grading, Approval delegation
- Recommendation contest, Calendar view

### TIER 4 — Future visions ROI <2

- Microservices migration
- Blockchain cert
- Mobile app store (Google Play, Apple Store)
- Predictive analytics ML
- Integration PTIT SSO

---

## 6. Sprint planning gợi ý

### Sprint 1 — "Quick wins blast" (2 tuần)

Pick 14 items từ TIER 1:
- 4 ngày backend: Rate limit + Filter + Cloning + Bulk approve + Auto-judge + Cert revoke + Audit search + xlsx import + Cache + HSTS
- 3 ngày frontend: QR scan + Deep-link + Cmd+K + Skeleton (overlap với sprint UI)
- 3 ngày DevOps: Sentry + Auto-deploy + Pre-commit
- **Total**: 10 ngày = 1 sprint 2 tuần

**Outcome**: Production-ready level (security + perf + power user features), perceived performance tăng 50%, error tracking 100%.

### Sprint 2 — "Critical features" (2 tuần)

- 5 ngày: Team registration UI (frontend) + Email service prod + File upload S3 (P0 missing features)
- 3 ngày: Refresh token + Notification email digest + Multi-judges
- 2 ngày: Verified review badge + Categories + Soft delete restore

**Outcome**: 3 P0 missing features hoàn thành (TEAM, email, upload), workflow đủ cho production.

### Sprint 3 — "Polish + Mobile native" (2 tuần)

- 4 ngày: Dark mode (full app) + Bottom sheet + Swipe actions
- 3 ngày: Stepper workflow ContestAdminDetail + Sidebar search + Inline edit
- 3 ngày: Bulk actions (review + users) + Drag-drop reorder + Empty illustration

**Outcome**: UX modern, đẹp, native feel mobile, web power user happy.

### Sprint 4 — "Real-time + Push" (2 tuần)

- 4 ngày: WebSocket real-time (notifications + audit feed)
- 4 ngày: FCM push notification (Android) + APNs setup
- 2 ngày: Recommendation engine + Calendar view

**Outcome**: App engagement tăng vọt, user gắn bó.

---

## 7. Tổng kết — Thứ tự thực hiện

### Nếu chỉ có 2 tuần (1 sprint)

Làm **Sprint 1** — 14 quick wins ROI cao nhất.

**Top 5 không thể bỏ**:
1. Sentry error tracking (1 ngày) — Production cần biết user gặp lỗi gì
2. Rate limit security (1 ngày) — Anti-brute-force
3. Notification deep-link (1 ngày BE + 0.5 FE) — UX boost mạnh
4. Cmd+K palette (1 ngày) — Power user love
5. Loading skeleton (1 ngày) — Perceived perf

### Nếu có 1 tháng (2 sprint)

Sprint 1 + Sprint 2 = quick wins + critical missing features.

### Nếu có 2 tháng (4 sprint)

Sprint 1-4 = production-ready với polish UX và real-time.

### Nếu có 6 tháng (12 sprint)

+ TIER 3 (Dark mode, i18n, AI features, microservices migration).

---

## 8. Bảng tóm tắt module bằng heat map

```
            BE Done | BE Cải tiến | FE Done | FE Cải tiến | ROI tổng
auth         ✅      ⚠️ Email      ✅       ⚠️ Bio+remember  HIGH
users        ✅      ⚠️ Avatar     ✅       ✅              MEDIUM
contests     ✅      ⚠️ Search     ✅       ⚠️ Calendar     HIGH
approvals    ✅      ⚠️ Realtime   ✅       ✅              MEDIUM
entries      ✅      ⚠️ Bulk       ✅       ✅              HIGH
teams        ✅      ❌ +Invite    ❌       ❌ Critical     CRITICAL
submissions  ✅      ⚠️ Upload     ✅       ⚠️ FilePicker   CRITICAL
judging      ✅      ⚠️ AutoAssign ✅       ✅              HIGH
results      ✅      ⚠️ Export     ✅       ⚠️ Chart        HIGH
reviews      ✅      ⚠️ Reply      ✅       ✅              MEDIUM
notifications ✅     ⚠️ Push       ✅       ⚠️ Deep-link    HIGH
certificates ✅      ⚠️ PDF gen    ✅       ⚠️ QR scan      HIGH
reports      ✅      ⚠️ Export     ⚠️       ⚠️ Chart        HIGH
admin        ✅      ⚠️ Search     ✅       ⚠️ Cmd+K        HIGH
```

**Critical**: 2 modules (teams, submissions) thiếu UI/upload — cần fix trước.
**High ROI**: 9 modules có quick wins ngay sprint 1.
**Medium**: 3 modules đã ổn, cải tiến tăng-trưởng.

---

**Người chuẩn bị**: Nhóm CNPM
**Ngày**: 2026-05-06
**Phiên bản**: 1.0
