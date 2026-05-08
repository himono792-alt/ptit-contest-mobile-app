# Changelog — PTIT Contest Frontend

Tất cả thay đổi notable cho frontend (web + APK) được ghi tại đây.

Format dựa trên [Keep a Changelog](https://keepachangelog.com/), versioning [SemVer](https://semver.org/).

---

## [Unreleased]

— (chưa có thay đổi mới)

---

## [1.0.0] — 2026-05-08

Production v1.0 stable — 30+ screens responsive web/mobile + APK 25.9 MB.

### Added (Sprint 19 — Login redesign + Sidebar collapsible Pattern B)
- **S19-1 Web 2-column login** — Branding panel gradient red (logo + headline + 4 stats + footer) + Form panel right (≥900px)
- **S19-2 Role tabs decorative** — 4 chip Sinh viên/GV-BTC/BCN khoa/Quản trị + "Ghi nhớ tôi" SharedPreferences + SSO PTIT disabled "Coming soon"
- **S19-3 Mobile onboarding** — 3 slides PageView (trophy/register/award) + dots + skip + "Tiếp tục"/"Bắt đầu" + persist `onboarding.completed`
- **S19-4 OTP 6-box** — 6 controllers + auto-focus next + backspace prev + paste 6 digit + auto-verify + countdown 5:00 mono font + Gửi lại link
- **Splash screen** — Trung gian khi auth boot, gradient red logo + spinner
- **Sidebar collapsible Pattern B** (VS Code/Slack/Sentry) — Expanded 240px ↔ Rail 64px (icon-only + tooltip), AnimatedContainer width transition

### Fixed (Sprint 19 hotfix series #1-#14)
- Android flicker StudentShell trước login → SplashScreen redirect intermediate
- Mobile bottom nav admin section header rendered as item → filter `isSection`
- Tab switch admin AnimatedSwitcher overlap → bỏ animation
- GoRouter MaterialPage slide animation chèn lên khi switchTab → `NoTransitionPage`
- Sidebar UX iterate 10 hotfix (collapsible → toggle overlap → left-rail → Sentry-style → click target → traverse debounce → cooldown → armed flag → bỏ hover-peek → Pattern B icon-only rail) — final clean industry-standard

### Added (Sprint 18 — P3 polish design folder)
- Stat card icons (fire/check/trophy) home SV
- Avatar gradient red→purple (`ptitGradientAvatar`) profile
- EmptyView enhanced — icon 72 + bg circle ptitRedSoft + heading bold + subtitle
- ⌘K kbd hint search bar web ≥768
- OKLCH 9-stop brand tokens `ptitRed50..900`
- Hotfix dark mode `_StatTone.neutral` cream → `context.cardBg`
- Hotfix judge "Đã chấm" state — BE enrich is_scored + FE filter hero count + pill green

### Added (Sprint 17 — P2 design)
- Featured contest hero "SỰ KIỆN NỔI BẬT" SV home (gradient red + CTA dynamic)
- Profile achievement stats — 3 columns (Cuộc thi/Giải/Cert)
- My contests progress bar 5 stage (PENDING 10% → đăng ký 25% → ONGOING 65% → FINISHED 100%)
- Notifications time-bucket grouping (Hôm nay / Tuần này / Cũ hơn)

### Added (Sprint 16 — P1 design)
- **Leaderboard SV** — Podium top-3 (gold/silver/bronze pillar) + rank table với "BẠN" highlight
- **GV "Hôm nay cần chấm" hero card** — Gradient red + count + CTA
- **SV submission countdown timer** — Timer.periodic 1s, 4 state color (hot/warn/normal/overdue)
- **Contest detail timeline visual** — Vertical line + 3-state dots (done/active/next)
- **Contest detail 5 tabs** — Tổng quan / Lịch trình / Thể lệ / Giải thưởng / Tài trợ

### Added (Sprint 15 — Strict role separation)
- Sidebar items strict theo role (gỡ `|| user.isAdmin` cho non-admin items)
- BTC dashboard `_BTCWorkflowGuideCard` 4-step workflow guide
- Admin dashboard `_AdminSystemHealthCard` + `_AdminAuditTailCard`
- Welcome message role-specific (GV/BCN/Admin)

### Added (Sprint 14 — IA improvements P1+P2)
- BCN sidebar split 3 lane: Đề xuất QĐ1 / Kết quả QĐ2 / (QĐ3 cert template existed)
- Section grouping sidebar 4 nhóm (Tổng quan / Người dùng / Hệ thống / Cộng đồng)
- Backup tách route riêng `/admin/backup`
- GV "Tạo cuộc thi" sidebar item

### Added (Sprint 13 — Audit log filter + behavior polish)
- Audit log advanced filter — search user/action/contest/time range
- Pull-to-refresh 4 list view chính
- Skeleton coverage 14 instance admin còn thiếu
- Bell badge animated pulse khi unread tăng

### Added (Sprint 11)
- Cert template approve UI — BCN duyệt QĐ3
- Submission lock UI — GV anti-tamper khi judging
- Cert HTML render link verify

### Added (Sprint 9-9b)
- Self-signup SV (signup_screen)
- OTP login screen 2-stage
- Sessions CRUD trong contest_admin_detail
- Reviews summary card 4 stat
- AD-05 Excel export wired

### Added (Sprint 8 — P0 UI/UX)
- Touch target ≥44dp (WCAG 2.5.5)
- Reduce-motion handling (WCAG 2.3.3)
- EmptyView shared widget
- Skeleton coverage 11 screen perceived load -300ms

### Added (Sprint 5 — Semantics deep wrap)
- 9 widget categories (login/submission/register/profile/sidebar/admin contests/approval queue/monitor/notifications) wrap Semantics(label, button, hint)

### Added (Sprint 3)
- R2 file upload submission (Cloudflare R2 multipart ≤10MB)
- Sentry frontend error tracking — `SENTRY_DSN_FRONTEND` qua dart-define
- A11y baseline — axe-core 24→0 violations (html-has-lang + meta-viewport fix)

### Added (Sprint 2)
- Dark mode token system — 484 theme tokens light/dark
- C3+M1 ShellRoute wrap sub-routes desktop sidebar consistency
- C4 admin breakpoint 768→1024
- M3 achievementGold tokens (tách warn semantic)

### Added (Phase 2 Sprint 1 — Quick wins)
- Notification deep-link (5 route ảo /me/* map tab index)
- Bulk approve entries (productivity ~30x)
- Excel export 4 sheets contest report
- Biometric login APK (FaceID/TouchID)
- Loading skeleton shimmer 5 screens

### Added (Phase A — Design tokens)
- spacing.dart (AppSpacing 4-base scale)
- radius.dart (AppRadius tight/sm/md/lg)
- durations.dart (AppDuration fast/base/slow)
- breakpoints.dart (AppBreakpoint mobile/tablet/desktop/wide)
- design_lint.ps1 script + DESIGN-REVIEW-CHECKLIST.md

### Added (Phase 0 — Initial 2026-05-04)
- Flutter 3.27 + Material 3 setup
- 4 actor flow (SV/GV/BCN/Admin) end-to-end
- 28 feature screen responsive
- GoRouter 14 routes
- Riverpod 2.6 state management
- Dio + JWT interceptor + secure storage
- Cloudflare Pages deploy via wrangler

---

## Reference

- Báo cáo CNPM: `../../11-docs/2026-05-07_bao-cao-cnpm_v02.md` (~1500 dòng, full Sprint 1-19)
- Backend changelog: `../backend/CHANGELOG.md`
