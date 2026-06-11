# Sentry Frontend Flutter Web setup

**Ngày**: 2026-05-07
**Sprint**: Sprint 3 item #5 (sau Phase C a11y)
**Backend Sentry**: đã có Phase 1 step 1 (`app/main.py` init với 4 integrations)

---

## TL;DR

Frontend Flutter Web giờ tự capture:
- Dart unhandled exceptions (`runZonedGuarded` automatic via `SentryFlutter.init` `appRunner`)
- Flutter framework errors (`FlutterError.onError` automatic)
- Async / Future errors (zone error handling)
- HTTP errors khi wire `dio_sentry_interceptor` (optional, chưa wire)

Tag `app.platform: flutter-web` giúp tách event FE vs BE trong Sentry dashboard.

---

## Setup Sentry project Flutter

### 1. Tạo project trên Sentry dashboard

```
https://sentry.io → New Project → Platform: Flutter
```

Tên project: `ptit-contest-flutter` (hoặc tên khác). Sau create, copy DSN:
```
https://abcdef123456@o000000.ingest.sentry.io/4500000000000000
```

### 2. Set env var khi build

Cloudflare Pages project KHÔNG có env var (dùng wrangler manual deploy). Inject DSN qua dart-define:

```powershell
$SENTRY_DSN = "https://abcdef@o000000.ingest.sentry.io/4500000000000000"
$GIT_SHA = (git rev-parse --short HEAD)

cd 09-implementation/frontend
flutter build web --release `
  --dart-define=API_BASE=https://ptit-contest-mobile-app-production.up.railway.app `
  --dart-define=SENTRY_DSN_FRONTEND=$SENTRY_DSN `
  --dart-define=APP_RELEASE=$GIT_SHA

npx wrangler pages deploy build/web --project-name=ptit-contest-app --commit-dirty=true --branch=main
```

→ Mỗi commit khác nhau sẽ có release tag riêng → Sentry track regression theo deploy.

### 3. Test capture error

Sau deploy, mở app production → trigger 1 error có chủ đích:

```dart
// Tạm thêm button "Throw test error" trong dev:
ElevatedButton(
  onPressed: () => throw Exception('Sentry test event'),
  child: const Text('Throw'),
)
```

Hoặc dùng JavaScript console:
```js
throw new Error('Manual sentry test');
```

→ Mở Sentry dashboard → Issues tab → thấy event mới với:
- Tag: `app.platform: flutter-web`
- Release: $GIT_SHA
- Environment: production
- Stacktrace đầy đủ

---

## Code changes

### 1. `pubspec.yaml`

```yaml
dependencies:
  sentry_flutter: ^8.10.0
```

### 2. `lib/main.dart`

```dart
import 'package:sentry_flutter/sentry_flutter.dart';

const _sentryDsnFrontend = String.fromEnvironment('SENTRY_DSN_FRONTEND');

Future<void> main() async {
  usePathUrlStrategy();

  if (_sentryDsnFrontend.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsnFrontend;
        options.release = const String.fromEnvironment('APP_RELEASE', defaultValue: 'dev');
        options.environment = kReleaseMode ? 'production' : 'development';
        options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
        options.sendDefaultPii = false;
        options.attachStacktrace = true;
      },
      appRunner: () {
        Sentry.configureScope((scope) {
          scope.setTag('app.platform', 'flutter-web');
        });
        runApp(const ProviderScope(child: PtitContestApp()));
      },
    );
  } else {
    debugPrint('Sentry frontend skipped — SENTRY_DSN_FRONTEND rỗng');
    runApp(const ProviderScope(child: PtitContestApp()));
  }
}
```

---

## Sentry options chốt

| Option | Value | Lý do |
|---|---|---|
| `dsn` | từ dart-define | Skip init nếu rỗng (dev mode) |
| `release` | git short SHA | Track regression theo deploy |
| `environment` | `production` / `development` | Filter events trong dashboard |
| `tracesSampleRate` | 0.1 (prod) / 1.0 (dev) | Tiết kiệm quota free 10K transactions/mo |
| `sendDefaultPii` | `false` | GDPR — không gửi email/IP/user data |
| `attachStacktrace` | `true` | Debug Future errors dễ hơn |
| Global tag | `app.platform: flutter-web` | Tách FE vs BE trong Sentry dashboard |

---

## Caveat

### Quota free Sentry

- 5,000 events/month
- 10,000 transactions/month (perf monitoring)

Với 100 user × 30 events/user/month = 3000 events. OK cho graduation project. Sau này scale → upgrade Team plan ($26/mo).

### PII off

`sendDefaultPii: false` nghĩa là Sentry **KHÔNG tự** capture:
- User email
- User IP
- Browser cookies

Khi cần thêm context user (vd để debug bug user-specific), dùng `Sentry.configureScope` set tag manually:
```dart
Sentry.configureScope((scope) {
  scope.setUser(SentryUser(id: user.userId.toString(), username: user.fullName));
});
```

Đặt ở `auth_provider.dart` sau login successful. Set null khi logout.

### Source maps cho dart2js

Default `flutter build web --release` minify code. Stack trace Sentry sẽ là minified vars (`a.b.c` thay vì `_LoginScreenState.submit`). Để source map work:
1. Build với `--source-maps`
2. Upload source map lên Sentry qua `sentry-cli`

Skip cho v1 — minified stack vẫn debug được nếu có git SHA + dart cố pattern recognition.

---

## Pending

- Anh tạo Sentry project Flutter + lấy DSN
- Anh test deploy với `--dart-define=SENTRY_DSN_FRONTEND=...`
- Verify capture event qua Sentry dashboard
- Wire dio interceptor cho HTTP error tracking (optional)
- Wire user context sau login (optional)

File: `lib/main.dart` (modified, ~70 dòng), `pubspec.yaml` (+1 dep)
