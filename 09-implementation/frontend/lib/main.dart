import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: depend_on_referenced_packages -- transitive từ Flutter SDK
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'core/theme_dark.dart';
import 'core/theme_provider.dart';
import 'features/onboarding/onboarding_screen.dart' show isOnboardingCompleted, onboardingCompletedFlag;

/// DSN frontend Sentry — inject qua dart-define ở build time.
/// `flutter build web --dart-define=SENTRY_DSN_FRONTEND=https://xxx@sentry.io/yyy`.
/// Skip init nếu rỗng (dev mode hoặc local) — giống pattern backend Phase 1 step 1.
const _sentryDsnFrontend = String.fromEnvironment('SENTRY_DSN_FRONTEND');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Sprint 19 (2026-05-08) S19-3: load onboarding flag sớm để router redirect
  // có info sync trong callback. SharedPreferences có cache in-memory sau lần
  // đầu init, nhưng để chắc chắn dùng flag global.
  onboardingCompletedFlag.value = await isOnboardingCompleted();

  // Sprint 3 (2026-05-07): Sentry frontend wrap runApp.
  // Backend đã có Sentry từ Phase 1 step 1, frontend bổ sung để full-stack
  // visibility — JS error Flutter Web + dart unhandled exceptions + zone errors.
  if (_sentryDsnFrontend.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = _sentryDsnFrontend;
        // Release tag — sau có thể inject git SHA qua dart-define
        // (`--dart-define=APP_RELEASE=$(git rev-parse --short HEAD)`).
        options.release = const String.fromEnvironment(
            'APP_RELEASE', defaultValue: 'dev');
        options.environment =
            kReleaseMode ? 'production' : 'development';
        // Performance tracing — sample 10% transactions để tránh tốn quota free
        // (Sentry free 5K events/mo + 10K transactions/mo).
        options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
        // PII safer — không gửi email/IP/user data theo default (GDPR).
        options.sendDefaultPii = false;
        // Attach stacktrace cho mọi log warning+ giúp debug Future errors.
        options.attachStacktrace = true;
      },
      appRunner: () {
        // Tag global platform cho mọi event để separate FE vs BE trong Sentry dashboard.
        Sentry.configureScope((scope) {
          scope.setTag('app.platform', 'flutter-web');
        });
        runApp(const ProviderScope(child: PtitContestApp()));
      },
    );
  } else {
    // Dev mode hoặc thiếu DSN — chạy app bình thường, log warning.
    debugPrint(
        'Sentry frontend skipped — SENTRY_DSN_FRONTEND rỗng (dev mode hoặc thiếu --dart-define).');
    runApp(const ProviderScope(child: PtitContestApp()));
  }
}

class PtitContestApp extends ConsumerWidget {
  const PtitContestApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Phase 2 Sprint 2 Step 1 (2026-05-06): wire theme mode provider
    // → user toggle trong Profile sẽ live-update mọi screen.
    final themeMode = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'PTIT Contest',
      debugShowCheckedModeBanner: false,
      theme: ptitLightTheme,
      darkTheme: ptitDarkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
