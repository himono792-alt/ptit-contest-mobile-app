# Contributing — PTIT Contest Frontend

Cảm ơn bạn quan tâm đóng góp cho project! Đây là hướng dẫn để contributor mới onboard nhanh.

---

## Quick start

```bash
# 1. Fork repo + clone
git clone https://github.com/YOUR_USERNAME/ptit-contest-flutter.git
cd ptit-contest-flutter

# 2. Cài Flutter 3.27+ từ https://docs.flutter.dev/get-started/install
flutter doctor   # check setup OK

# 3. Install deps
flutter pub get

# 4. Run dev (web)
flutter run -d chrome \
  --dart-define=API_BASE=https://ptit-contest-mobile-app-production.up.railway.app
```

→ Browser auto-open với app

---

## Workflow

1. **Tạo issue** mô tả bug/feature trước khi code (xem `.github/ISSUE_TEMPLATE/`).
2. **Branch naming**: `feature/<short-desc>` · `fix/<short-desc>` · `docs/<short-desc>`
3. **Code change** — tuân thủ rules dưới.
4. **Local test** — `flutter run -d chrome` smoke test 4 viewport (1440/1024/768/567).
5. **Build verify** — `flutter build web --release` không error.
6. **Commit message** Conventional Commits.
7. **Pull request** — kèm screenshot 4 viewport + light/dark mode nếu UI-affecting.

---

## Commit convention (Conventional Commits)

```
<type>(<scope>): <subject>
```

**Types:**
- `feat` — Tính năng mới (vd screen mới, widget mới)
- `fix` — Bug fix
- `refactor` — Refactor không thay đổi UI
- `perf` — Tối ưu performance (vd skeleton loading)
- `docs` — Chỉ docs (README/CHANGELOG/comment)
- `test` — Chỉ test
- `chore` — Dependency bump / build config

**Scopes** (optional):
- `auth` · `student` · `admin` · `theme` · `widgets` · `router` · `core` · ...

**Examples:**
```
feat(student): leaderboard screen với podium top-3 + table rank
fix(s19): NoTransitionPage cho /admin tab switch (bỏ slide animation)
refactor(admin): sidebar collapsible Pattern B (icon-only rail)
docs(readme): Sprint 19 highlights
chore(deps): bump shared_preferences 2.5.3 → 2.5.5
```

---

## Code style

### Dart
- **Dart 3.6** null safety strict.
- **Const constructor** ở đâu được — Flutter perf optimization.
- **Naming**: lowerCamelCase variable/function, UpperCamelCase class, `_privateField`, `kConstant` cho top-level const.
- **Linter**: `flutter analyze` trước commit. Project dùng `flutter_lints` rules.

### Widget structure
- Stateless > Stateful khi có thể.
- ConsumerWidget thay StatelessWidget khi cần Riverpod.
- ConsumerStatefulWidget khi cần local state + Riverpod.
- Tách `_PrivateHelperWidget` riêng cho readability — ưu tiên reusable trong cùng file thay function.

### Theme tokens (BẮT BUỘC)
KHÔNG hard-code hex/size/radius/duration. Dùng tokens:
- Color: `context.appBg`, `context.cardBg`, `context.textPrimary`, `ptitRed`, `ptitRed500`...
- Spacing: `AppSpacing.xs/sm/md/lg/xl/xxl/3xl`
- Radius: `AppRadius.tight/sm/md/lg`
- Duration: `AppDuration.fast/base/slow`
- Breakpoint: `AppBreakpoint.mobile/tablet/desktop/wide`

Run `design_lint.ps1` để check violation.

---

## Patterns project

### Riverpod state
```dart
final myProvider = FutureProvider.autoDispose<List<Foo>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/path');
  return (res.data as List).map((j) => Foo.fromJson(j)).toList();
});

// In widget:
final asyncData = ref.watch(myProvider);
return asyncData.when(
  loading: () => MCardListSkeleton(count: 3),
  error: (e, _) => Center(child: Text('Lỗi: $e')),
  data: (items) => ListView(...),
);
```

### Navigate
```dart
context.push('/contests/${slug}');           // push (back-able)
context.go('/admin/contests');               // replace
context.go('/admin/contests/${id}/manage');  // deep-link
```

### Theme adaptive
```dart
Container(
  color: context.cardBg,           // adaptive light/dark
  border: Border.all(color: context.cardBorder),
  child: Text('hello',
      style: TextStyle(color: context.textPrimary)),
)
```

### Skeleton loading
```dart
asyncData.when(
  loading: () => const MCardListSkeleton(count: 3, textLines: 2),
  data: (items) => ...,
)
```

### Empty state
```dart
const EmptyView(
  icon: Icons.emoji_events_outlined,
  title: 'Chưa có cuộc thi nào',
  subtitle: 'Hãy quay lại sau khi BTC mở thêm cuộc thi mới.',
)
```

---

## Build & Deploy

### Web (Cloudflare Pages)

```bash
.\build_deploy.ps1   # PowerShell Windows
```

### APK Android

```bash
flutter build apk --release \
  --dart-define=API_BASE=https://ptit-contest-mobile-app-production.up.railway.app \
  --dart-define=SENTRY_DSN_FRONTEND=...
```

APK output: `build/app/outputs/flutter-apk/app-release.apk` ~25.9 MB.

---

## Testing

⚠️ Unit/widget test suite empty (defer post-graduation). Verify bằng:
- `flutter analyze` — static analysis
- `flutter run -d chrome` — manual smoke 4 viewport
- Chrome DevTools DOM/network inspect cho a11y check

---

## Pull Request checklist

Trước khi mở PR:

- [ ] `flutter analyze` không error
- [ ] `flutter build web --release` build OK
- [ ] Test manual 4 viewport (1440 / 1024 / 768 / 567px)
- [ ] Test cả light + dark mode
- [ ] Screenshot kèm PR description
- [ ] Update CHANGELOG.md `[Unreleased]` section
- [ ] Update README.md nếu thêm screen/feature mới

---

## Reference

- README: `README.md`
- CHANGELOG: `CHANGELOG.md`
- Backend: `../backend/README.md`
- Báo cáo CNPM: `../../11-docs/2026-05-07_bao-cao-cnpm_v02.md`
