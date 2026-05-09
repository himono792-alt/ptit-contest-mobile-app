# CHANGELOG — PTIT Contest Management

Tài liệu thay đổi giữa các sprint cho hệ thống quản lý cuộc thi PTIT.

Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning [SemVer](https://semver.org/).

---

## [v1.0 — 2026-05-08] Sprint 8-13: Audit + 100% UI coverage + polish

### Added

- **Sprint 9 Auth**: OTP passwordless login (2-stage: request → verify) + self-signup SV form 4 field. Routes `/otp-login` + `/signup`.
- **Sprint 9 Contest workflow**: Sessions CRUD UI trong tab "Vòng & Phiên" — _SessionCard + _AddSessionDialog (form: tên, type ONLINE/OFFLINE, datetime picker, location/URL conditional).
- **Sprint 9 Reviews + Judging**: DELETE rubric criterion với confirm dialog; _ReviewsSummaryCard 4 stat (Tổng/Sao TB/5 sao/≥4 sao).
- **Sprint 9b Admin export**: BE thêm endpoint `/admin/reports/system-summary.xlsx` — 3 sheets (Tổng quan/Phân loại user/Metadata).
- **Sprint 11 Workflow QĐ3**: Nút "Duyệt" cho HOD/Admin trên cert template card → PATCH approve. Hoàn thiện workflow phê duyệt 3 cấp.
- **Sprint 11 Submission lock**: Nút "Khóa submission" trên _JudgingTab anti-tamper khi judge chấm.
- **Sprint 12 Stats card**: _ContestStatsCard real-time GV-07 — 6 stat (Đăng ký/Chờ duyệt/Bài nộp/Vòng/Điểm TB/Tỷ lệ pass) trên _OverviewTab.
- **Sprint 13 Audit log filter**: Date range picker (date_from/date_to) + clear icon trên audit-log screen.
- **Sprint 13 UX polish**:
  - AnimatedSwitcher 220ms tab fade trong admin shell (wide + mobile).
  - AnimatedScale 250ms elasticOut bell badge khi unread > 0.
  - HapticFeedback.lightImpact khi tap bottom nav (no-op web, fires APK).
  - 4 master data provider bỏ autoDispose (cache cross-navigate).
- **Sprint 8 P0 UI/UX**:
  - EmptyView shared widget (icon + title + subtitle + optional action) — refactor 4 admin screen.
  - context.reduceMotion extension đọc MediaQuery.disableAnimationsOf (WCAG 2.3.3 + 2.2.2).
  - 11 IconButton với visualDensity.compact thêm constraints minWidth:44 minHeight:44 (WCAG 2.5.5).
- **Sprint 8b/c Skeleton coverage**: 11 screen từ CircularProgressIndicator → MCardListSkeleton (admin_users 5 / audit_log 6 / monitor 4 / contest_detail 3 / master_data 3 tabs / review_moderation / judge / anomaly / configs / team_management / +).

### Changed

- **Sprint 8 fix #2**: Deep-link `/admin/<tab>` không còn 404. AdminShell có `initialTab` param + helper `switchTab` đồng bộ URL bar.
- **Sprint 8 fix #4**: BCN Dashboard 4 stat cards (refactor inline Builder → ConsumerWidget riêng `_HodStatsContainer` với fallback chain).
- **Sprint 8 fix #5**: Admin/GV/BCN logout có confirm dialog "Đăng xuất?" giống SV.
- **Sprint 8 fix #6**: CCCD masked mặc định `123●●●●●●012` với eye icon toggle (PII privacy WCAG).
- **Sprint 13 build script**: `build_deploy.ps1` thêm flag `--tree-shake-icons` giảm bundle size.
- **Sprint 12 Decimal fix**: Helper `_parseNum` cho Pydantic Decimal-as-string serialization.
- **Sprint 9 Group 4**: AD-05 button nay click thành công download xlsx (BE endpoint mới).

### Fixed

- **Sprint 12 #38**: Reviews summary field name `average_rating` (BE thực) thay vì `avg_rating` (em đoán nhầm). UI đổi 4 stat hợp lý hơn.
- **Sprint 9 Group 1**: Login screen "Đăng nhập bằng OTP" button nay navigate `/otp-login` thay vì SnackBar "chưa wire UI".

### Removed

- Test User 81463 soft-deleted (`himono792+ptit81463@gmail.com`) — fake email seed test cleanup.
- email.smtp_host config Value rỗng → đặt `(disabled-railway-blocks-smtp-port)` rõ ràng cho admin sau.

### Production deploys

- 12 build deploy FE Cloudflare Pages
- 1 deploy BE Railway (Sprint 9b A AD-05)
- ~32 file diff (30 FE + 2 BE)
- 11+ bug fix verified live qua Chrome MCP

---

## [v0.9 — 2026-05-07] Sprint 4-7: A11y + dark mode + sentry FE + R2 + sprint 8 prep

### Added

- **Sprint 5 A11y deep wrap**: 9 widget categories Semantics() (login/submission/register/profile/sidebar/admin contests/approval/monitor/notifications). +99% nodes vs Sprint 3 baseline.
- **Sprint 6 Anomaly Reports** (AD-06): Server scan audit_logs phát hiện anomaly (lock-unlock rapid, judge tự chấm bài, review spam IP).
- **Sprint 6 Excel Export** (GV-07): 4 sheets (Tổng quan / Vòng / Submissions / Metadata) qua openpyxl.
- **Sprint 7 Dark mode toggle** cho GV/BCN/Admin (trước chỉ SV có).
- **Sentry FE Flutter Web**: Project mrb-personal/ptit-contest-flutter ID 4511345155571712.
- **R2 Object Storage**: Cloudflare R2 bucket `ptit-contest-submissions` cho file submission (S3-compat aiobotocore).
- **APK Android build**: Kotlin stdlib mismatch fix (KGP 2.2.0 + AGP 8 + Java 17). 25.7 MB.

### Changed

- **Phase A Design Tokens**: 4 token files mới (spacing/radius/durations/breakpoints) + design_lint.ps1. Lint violations 334→269 (-19%).
- **Phase B UX audit**: 24/24 screens, 25 findings → Sprint 2+4 đóng Critical=0, Major=0.

---

## [v0.8 — 2026-05-06] Sprint 0-3: Foundation + Quick Wins + a11y

- **Sprint 0**: 4 P0 + 3 P1 + 1 P2 fix (schema drift, cert verify 404, audit pool, Alembic).
- **Phase 1 Production Foundation**: Sentry + Rate limit + Refresh token + Email Brevo + HSTS A+ (6 security headers).
- **Phase 2 Sprint 1 Quick Wins**: Notification deep-link + Bulk approve entries + Excel export + Biometric login + Loading skeleton 5 SV screens.
- **Sprint 2 UX fix**: 9 fixes triển khai theo ROI sort. 5 commits.
- **Phase C A11y baseline**: axe-core 4.10.0 — 24→0 real violations (html-has-lang + meta-viewport fixed).
- **Sprint 3 A11y Semantics baseline**: 5 widget categories ~25 elements wrap.

---

## [v0.5 — 2026-05-05] v1.0 Initial release

- Backend: 99 endpoints qua 14 router (sau Sprint 9 thành 104), 43 SQLAlchemy 2.0 async models.
- Frontend: 27+ screens responsive web/mobile (sau Sprint 9 thành 28).
- E2E demo 2 contest INDIVIDUAL+TEAM với cert verify QR.
- Migration Netlify → Cloudflare Pages.

---

## Production URLs

- **FE Web**: `https://ptit-contest-app.pages.dev` (auto-CDN, manual deploy)
- **BE API**: `https://ptit-contest-mobile-app-production.up.railway.app` (Railway, auto-deploy git push)
- **Cert verify**: `https://ptit-contest-app.pages.dev/verify` (deep-link cho QR scan)
- **Object storage**: Cloudflare R2 bucket `ptit-contest-submissions`

## Test accounts (password chung `abc123`)

- `b22dccn001@ptit.edu.vn` — Sinh viên (Nguyễn Văn A)
- `gv@ptit.edu.vn` — GV (Nguyen Van A — ADMIN+JUDGE+ORGANIZER)
- `bcn@ptit.edu.vn` — BCN HOD khoa CNTT (Tran Van B)
- `admin@ptit.edu.vn` — Quản trị hệ thống

Seed: `09-implementation/backend/scripts/seed-test-users.py`.
