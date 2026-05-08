# PTIT Contest — Frontend (Flutter)

Frontend Web + Mobile (APK Android) cho hệ thống quản lý cuộc thi sinh viên PTIT.

**Stack:** Flutter 3.27 · Dart 3.6 · Material 3 · Riverpod 2.6 · Dio · GoRouter · Sentry · Shimmer · local_auth (biometric APK) · shared_preferences

**Production Web:** https://ptit-contest-app.pages.dev — Cloudflare Pages, manual deploy via `build_deploy.ps1`
**APK Android:** `flutter build apk --release` (~25.9 MB, KGP 2.2.0 + AGP 8 + Java 17)

---

## Trạng thái v1.0 (2026-05-08)

| Thành phần | Trạng thái | Sprint |
|---|---|---|
| 4 actor flow (SV/GV/BCN/Admin) | ✅ Đầy đủ E2E | 1-7 |
| 30+ feature screens | ✅ Render đúng 4 viewport (1440/1024/768/567) | 1-19 |
| Light + Dark theme (Material 3 + 484 tokens) | ✅ Toggle ở Profile/Sidebar admin | Phase A + Sprint 7 |
| Responsive web/mobile | ✅ Sidebar ≥1024px, drawer/bottom nav <1024px | Sprint 2 |
| Auth: password + OTP 6-box + biometric (APK) | ✅ | Sprint 9 + 19 |
| Self-signup SV | ✅ | Sprint 9 |
| Mobile onboarding 3 slides | ✅ Lần đầu mở app | Sprint 19 |
| Workflow phê duyệt 3 cấp QĐ1+QĐ2+QĐ3 | ✅ | Sprint 11 |
| Strict role separation 4 actor | ✅ gv@ chỉ ORGANIZER+JUDGE, admin riêng | Sprint 15 |
| A11y WCAG 2.1 AA + Semantics deep wrap | ✅ axe-core 0 violations | Sprint 3+5 |
| Sentry FE error tracking | ✅ Tag `app.platform: flutter-web` | Sprint 7 |
| Skeleton loading 25+ screen | ✅ MCardListSkeleton + MListItemSkeleton | Sprint 8b/c + 13 |
| Token system | ✅ spacing/radius/durations/breakpoints + OKLCH 9-stop | Phase A + Sprint 18 |
| Touch target ≥44dp WCAG 2.5.5 | ✅ | Sprint 8 |
| Reduce-motion handling WCAG 2.3.3 | ✅ context.reduceMotion | Sprint 8 |
| EmptyView shared widget | ✅ Icon 72 + bg circle illustration | Sprint 8 + 18 |
| Pull-to-refresh 4 list view | ✅ | Sprint 13 |
| Audit log advanced filter | ✅ user/action/date range | Sprint 13 |
| **Sidebar collapsible Pattern B** | ✅ Icon-only rail 64px / Expanded 240px | Sprint 19 |
| **R2 file upload** | ✅ Cloudflare R2 ≤10MB | Sprint 3 |
| **Login web 2-column branding** | ✅ Sentry-style ≥900px | Sprint 19 |
| **OTP 6-box + countdown timer** | ✅ Auto-focus next + paste support | Sprint 19 |
| **Leaderboard SV (podium top-3)** | ✅ Gold/silver/bronze + "BẠN" highlight | Sprint 16 |
| **Contest detail 5 tabs + timeline** | ✅ Tổng quan/Lịch trình/Thể lệ/Giải thưởng/Tài trợ | Sprint 16 |
| **GV "Hôm nay cần chấm" hero** | ✅ Gradient red + filter scored vs unscored | Sprint 16 |
| **SV countdown timer submission** | ✅ Live tick mỗi giây + 4 state color | Sprint 16 |
| **Profile achievement stats** | ✅ Cuộc thi/Giải/Cert | Sprint 17 |
| **Featured contest hero SV Home** | ✅ "SỰ KIỆN NỔI BẬT" gradient | Sprint 17 |
| **Notifications time-bucket** | ✅ Hôm nay / Tuần này / Cũ hơn | Sprint 17 |
| **Splash screen** | ✅ Tránh flicker StudentShell trước login Android | Sprint 19 hotfix |

---

## Setup

### Yêu cầu
- Flutter 3.27+ + Dart 3.6+
- Android SDK (cho APK build) hoặc Chrome (cho web dev)

### Cài đặt + Run

```bash
cd 09-implementation/frontend

# Install deps
flutter pub get

# Run dev (web)
flutter run -d chrome \
  --dart-define=API_BASE=https://ptit-contest-mobile-app-production.up.railway.app

# Build production web + deploy Cloudflare
./build_deploy.ps1   # PowerShell Windows

# Build APK Android (release)
flutter build apk --release \
  --dart-define=API_BASE=https://ptit-contest-mobile-app-production.up.railway.app \
  --dart-define=SENTRY_DSN_FRONTEND=<your-dsn>
```

APK output: `build/app/outputs/flutter-apk/app-release.apk` (~25.9 MB)

---

## Cấu trúc

```
lib/
├── main.dart                  # MaterialApp.router + theme provider + Sentry init
├── core/
│   ├── api_client.dart        # Dio singleton + JWT interceptor + auto-refresh
│   ├── app_colors.dart        # context extension (theme-aware tokens)
│   ├── auth/
│   │   ├── auth_provider.dart # AsyncNotifier UserModel
│   │   ├── auth_service.dart  # Login/refresh/logout/biometric
│   │   └── biometric_service.dart  # local_auth FaceID/TouchID
│   ├── models/                # UserModel, ContestDetail, SubmissionDetail, MyResultModel
│   ├── reduce_motion.dart     # context.reduceMotion (WCAG 2.3.3)
│   ├── router.dart            # GoRouter — login/admin/student shells + 14 routes
│   ├── secure_storage.dart    # JWT persist (FlutterSecureStorage)
│   ├── spacing.dart           # AppSpacing 4-base scale
│   ├── radius.dart            # AppRadius scale (tight/sm/md/lg)
│   ├── durations.dart         # AppDuration (fast 150 / base 220 / slow 400)
│   ├── breakpoints.dart       # AppBreakpoint (mobile/tablet/desktop/wide)
│   ├── theme.dart             # Light theme (PTIT red brand) + ptitGradientHero/Avatar + ptitRed50..900
│   ├── theme_dark.dart        # Dark theme (warm-leaning)
│   ├── theme_provider.dart    # Riverpod theme mode toggle + persist
│   ├── widgets/               # MCard / Pill / EmptyView / m_shimmer / m_bottom_nav / ...
│   └── xlsx_export_helper.dart  # Excel download helper
└── features/
    ├── auth/                  # 5 screens
    │   ├── login_screen.dart        # 2-column web (Sprint 19) + role tabs + remember + SSO
    │   ├── otp_login_screen.dart    # 6-box OTP + countdown 5:00 (Sprint 19)
    │   ├── signup_screen.dart       # Self-signup SV
    │   ├── forgot_password_request_screen.dart
    │   └── splash_screen.dart       # Trung gian khi auth boot (Sprint 19 hotfix)
    ├── onboarding/
    │   └── onboarding_screen.dart   # 3 slides PageView (Sprint 19)
    ├── student/               # 16 screens
    │   ├── home_screen.dart           # Featured hero + stats icons + cuộc thi nổi bật
    │   ├── contest_list_screen.dart   # Search + filter + sort
    │   ├── contest_detail_screen.dart # 5 tabs + timeline visual (Sprint 16)
    │   ├── register_screen.dart       # Đăng ký cá nhân/team
    │   ├── team_management_screen.dart
    │   ├── submission_screen.dart     # Submit version + countdown timer (Sprint 16)
    │   ├── my_registrations_screen.dart  # Của tôi + progress bar (Sprint 17)
    │   ├── my_results_screen.dart     # Kết quả + cert verify
    │   ├── leaderboard_screen.dart    # Podium top-3 + table (Sprint 16, file mới)
    │   ├── notifications_screen.dart  # Time-bucket grouping (Sprint 17)
    │   ├── profile_screen.dart        # Avatar gradient + 3 achievement stats
    │   ├── edit_profile_screen.dart
    │   ├── cert_verify_screen.dart    # QR verify + HTML render
    │   ├── review_dialog.dart
    │   ├── student_shell.dart         # Bottom nav 6 tabs
    │   └── student_shell_scaffold.dart  # Sub-route wrapper desktop sidebar
    └── admin/                 # 13 screens
        ├── admin_shell.dart            # Sidebar collapsible Pattern B (Sprint 19)
        ├── admin_dashboard_screen.dart # Welcome + stats + workflow guide BTC
        ├── admin_contests_screen.dart  # Table 5 contests + create dialog
        ├── contest_admin_detail_screen.dart  # 6 tabs full management
        ├── admin_users_screen.dart     # User CRUD + role assignment
        ├── master_data_screen.dart     # Faculties/Majors/Classes
        ├── approval_queue_screen.dart  # 3 lane QĐ1/QĐ2/QĐ3 (Sprint 14)
        ├── monitor_screen.dart         # BCN giám sát tiến độ
        ├── judge_screen.dart           # GV chấm bài + hero "Hôm nay cần chấm"
        ├── review_moderation_screen.dart
        ├── audit_log_screen.dart       # Filter user/action/date (Sprint 13)
        ├── anomaly_reports_screen.dart
        ├── configs_screen.dart         # System configs
        └── create_contest_dialog.dart
```

---

## Test credentials (seed)

Email cố định, password chung **`abc123`**:
- `b22dccn001@ptit.edu.vn` — **Sinh viên** (SV-01)
- `gv@ptit.edu.vn` — **GV/BTC** (ORGANIZER + JUDGE, KHÔNG có ADMIN sau Sprint 15)
- `bcn@ptit.edu.vn` — **Ban Chủ nhiệm khoa** (HOD khoa CNTT)
- `admin@ptit.edu.vn` — **Quản trị** (ADMIN only)

Seed script BE: `../backend/scripts/seed-test-users.py`

---

## Theme tokens

### Brand colors (OKLCH 9-stop ramp — Sprint 18)
- `ptitRed50` → `ptitRed900` (FFF1F3 → 3D050D)
- `ptitRed500 = ptitRed = #C8102E` (anchor)
- `ptitRed100 = ptitRedSoft` (subtle bg)
- `ptitRed600 = ptitRedDark` (hover/pressed)

### Gradients
- `ptitGradientHero` — Hero card diagonal red→pink
- `ptitGradientAvatar` — Avatar profile red→purple (Sprint 18)

### Adaptive tokens (`context.*`)
- `appBg` · `cardBg` · `cardBorder`
- `textPrimary` · `textMuted` · `textFaint`
- `successGreen` · `successSoft`
- `warnOrange` · `warnSoft`
- `infoBlue` · `infoSoft`
- `achievementGold` · `achievementGoldSoft`

Tất cả auto-switch theo `Theme.of(context).brightness` (light/dark).

---

## Build & Deploy workflow

### Web (Cloudflare Pages)

```bash
cd 09-implementation/frontend
git push                       # Backend Railway auto-deploys nếu BE diff
.\build_deploy.ps1             # Build web + wrangler deploy
```

`build_deploy.ps1` runs:
1. `flutter clean`
2. `flutter build web --release --dart-define=API_BASE=...`
3. `wrangler pages deploy build/web --project-name=ptit-contest-app`

Output URL: `https://<hash>.ptit-contest-app.pages.dev` (alias production: `ptit-contest-app.pages.dev`).

### APK Android

```bash
flutter build apk --release \
  --dart-define=API_BASE=https://ptit-contest-mobile-app-production.up.railway.app \
  --dart-define=SENTRY_DSN_FRONTEND=https://...@sentry.io/...
```

APK: `build/app/outputs/flutter-apk/app-release.apk` ~25.9 MB.

Build config: KGP 2.2.0 + AGP 8 + Java 17 (xem memory `apk_android_build_2026-05-07.md`).

---

## Sprint highlights (Sprint 13-19)

| Sprint | Items | Mô tả |
|--------|-------|-------|
| **Sprint 13** | Audit log filter + behavior polish | Pull-to-refresh 4 list · Bell badge pulse · Skeleton 14 instance · Audit log filter widget |
| **Sprint 14** | IA improvements P1+P2 | BCN split 3 lane QĐ · Sidebar section grouping · Backup tách route · GV "Tạo cuộc thi" sidebar |
| **Sprint 15** | Strict role separation | Gỡ ADMIN role gv@ · BTC dashboard riêng · Admin dashboard SystemHealth + AuditTail |
| **Sprint 16** | P1 design (5 items) | GV today-judging hero · SV countdown timer · Leaderboard podium + table · Contest detail timeline · 5 tabs |
| **Sprint 17** | P2 design (4 items) | Featured hero "SỰ KIỆN NỔI BẬT" · Profile achievements · My-contests progress · Notifications time-bucket |
| **Sprint 18** | P3 polish (5 items) | Stat icons fire/check/trophy · Avatar gradient red→purple · EmptyView enhanced · ⌘K kbd hint · OKLCH 9-stop |
| **Sprint 19** | Login redesign + sidebar | Web 2-column branding · Onboarding 3 slides · OTP 6-box · Sidebar collapsible Pattern B (VS Code/Sentry) |

Chi tiết từng sprint xem báo cáo CNPM: `../../11-docs/2026-05-07_bao-cao-cnpm_v02.md`.

---

## Reference

- **Backend**: `../backend/README.md`
- **Báo cáo CNPM v02**: `../../11-docs/2026-05-07_bao-cao-cnpm_v02.md`
- **Design tokens audit**: `../../11-docs/design-audit-2026-05-06.md`
- **A11y baseline**: `../../11-docs/a11y-baseline-2026-05-07.md`
- **Sprint 5 a11y semantics**: `../../11-docs/sprint5-a11y-baseline-2026-05-07.md`
- **Sentry FE setup**: `../../11-docs/sentry-frontend-setup-2026-05-07.md`
- **HTML renderer eval**: `../../11-docs/html-renderer-eval-2026-05-07.md`
