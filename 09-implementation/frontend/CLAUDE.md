# CLAUDE.md — CNPM Flutter Frontend

> Instructions cho Claude (và developer mới) khi làm việc trong `lib/`. Đọc file này TRƯỚC khi sửa UI.

---

## Stack

- Flutter (Dart 3.x), Material 3.
- State: Riverpod.
- Routing: go_router.
- HTTP: dio + retrofit-style API client (`lib/core/api_client.dart`).
- Backend: Railway production (`https://ptit-contest-be-production.up.railway.app`).
- Deploy web: Cloudflare Pages (`ptit-contest-app.pages.dev`).
- Build flag bắt buộc: `--dart-define=API_BASE=https://...railway.app`.

## Design system rules — MUST follow

Tất cả UI mới hoặc sửa UI phải tuân thủ. Tham khảo `11-docs/DESIGN-REVIEW-CHECKLIST.md` cho full checklist.

### Tokens (zero literal allowed in features/)

| Concept | Token | Đừng dùng |
|---|---|---|
| Color | `context.appBg / textPrimary / textMuted / cardBg / cardBorder / ptitRed / ptitRedSoft / successGreen / warnOrange / infoBlue / ...` | `Color(0xFF...)` |
| Radius | `BorderRadius.circular(AppRadius.tight \| sm \| md \| lg \| pill)` | `circular(8)`, `circular(14)` literal |
| Spacing | `EdgeInsets.all(AppSpacing.s16)`, `SizedBox(height: AppSpacing.s12)` | `EdgeInsets.all(14)`, `height: 18` |
| Duration | `AppDuration.fast / base / slow` | `Duration(milliseconds: 200)` |
| Breakpoint | `kBpSm / Md / Lg / Xl`, `isMobile(ctx) / isCompact(ctx) / isWide(ctx)` | `MediaQuery.sizeOf(c).width < 800` |
| Gradient | `ptitGradientHero` hoặc `LinearGradient(colors: ptitGradientHeroColors)` | inline `[ptitRed, Color(0xFFFF6B7E)]` |

### Typography (zero `TextStyle(fontSize:)` allowed)

```dart
// SAI:
Text('hello', style: TextStyle(fontSize: 12, color: context.textMuted))

// ĐÚNG:
Text('hello', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted))
```

Mapping size → textTheme variant:
- 11 → `labelSmall` (w600)
- 12 → `bodySmall` (w500) hoặc `labelMedium` (w600)
- 13 → `bodyMedium` (w500) hoặc `titleSmall` (w600)
- 14 → `labelLarge` (w600)
- 15 → `bodyLarge` (w500) hoặc `titleMedium` (w700)
- 18 → `headlineSmall` (w700)
- 20 → `titleLarge` (w800)
- 22 → `headlineMedium` (w800)
- 28 → `headlineLarge` (w800)

### Theme-aware color (light + dark mode)

```dart
// SAI (đóng băng theme light):
Container(color: appBg, child: Text(..., style: TextStyle(color: textPrimary)))

// ĐÚNG (invert tự động trong dark mode):
Container(color: context.appBg, child: Text(..., style: TextStyle(color: context.textPrimary)))
```

Test mọi screen mới ở **CẢ light + dark** trước khi merge. Toggle ở Profile → Theme Mode.

### Loading indicators

- Page-level center loading: `CircularProgressIndicator(color: ptitRed)`.
- Trong filled button (red bg): `CircularProgressIndicator(strokeWidth: 2, color: Colors.white)` — `Colors.white` đúng vì button bg cố định ptitRed.
- Trong list loading: dùng `MShimmer` skeleton, không spinner.

### Lint check trước commit

```powershell
cd 09-implementation/frontend
pwsh tool/design_lint.ps1
```

Nếu fail với violation MỚI (so với baseline `tool/post-phase-a-2026-05-06.txt`): fix trước khi push.

---

## Cấu trúc folder

```
lib/
  core/
    theme.dart              ← light theme + brand tokens (ptitRed, gradient...)
    theme_dark.dart         ← dark theme override
    app_colors.dart         ← AppColors extension on BuildContext
    spacing.dart            ← AppSpacing constants
    radius.dart             ← AppRadius constants
    durations.dart          ← AppDuration + AppCurve
    breakpoints.dart        ← kBpSm/Md/Lg/Xl + isMobile/Compact/Wide helpers
    api_client.dart         ← dio + retrofit
    auth/                   ← auth provider, biometric
    models/                 ← shared models
    widgets/                ← MCard, MTopBar, Pill, MShimmer, ...
  features/
    auth/                   ← login + forgot password
    student/                ← SV screens (home, contest list/detail, ...)
    admin/                  ← BCN/Admin screens (approval queue, contest mgmt, ...)
```

## Workflow

- Mỗi PR UI: chạy `flutter analyze lib/features/` + `pwsh tool/design_lint.ps1` + paste output vào PR description.
- Reviewer paste link `11-docs/DESIGN-REVIEW-CHECKLIST.md` để check từng dimension.
- Critical violation → block; Major → fix trong sprint; Minor → backlog.

## Lịch sử Phase A (2026-05-06)

- Phase A done: 334 → 269 violations (-19%).
- Cat 3 (off-radius) + Cat 5 (Material drift) về 0%.
- Defer: Cat 1 (45 admin_shell sidebar), Cat 2 (95 off-spacing — opportunistic), Cat 4 (129 ở 23 file lẻ — opportunistic).

Reference docs:
- `11-docs/audits/design-audit-2026-05-06.md` — audit gốc 7 dimension
- `tool/baseline-2026-05-06.txt` — baseline trước Phase A
- `tool/post-phase-a-2026-05-06.txt` — kết quả sau Phase A
- `11-docs/DESIGN-REVIEW-CHECKLIST.md` — checklist đầy đủ cho mọi PR
