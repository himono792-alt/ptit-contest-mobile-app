import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'core/theme_dark.dart';
import 'core/theme_provider.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: PtitContestApp()));
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
