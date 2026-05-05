import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/router.dart';
import 'core/theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: PtitContestApp()));
}

class PtitContestApp extends ConsumerWidget {
  const PtitContestApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'PTIT Contest',
      debugShowCheckedModeBanner: false,
      theme: ptitLightTheme,
      routerConfig: router,
    );
  }
}
