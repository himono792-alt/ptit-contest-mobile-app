/// Sprint 8 P0 #3 (2026-05-07): Honor OS-level "Reduce motion" preference.
///
/// WCAG 2.3.3 (Animation from Interactions, AAA) + 2.2.2 (Pause Stop Hide, A)
/// — user vestibular disorders bị nausea/dizzy với parallax + slide transition.
///
/// Flutter expose flag qua `MediaQuery.disableAnimationsOf(context)` (true khi
/// macOS/iOS/Windows/Android có "Reduce motion" hoặc "Remove animations" enabled).
///
/// Usage:
/// ```dart
/// final dur = context.reduceMotion ? Duration.zero : AppDuration.base;
/// AnimatedSwitcher(duration: dur, child: ...)
/// ```
///
/// Hoặc helper page route:
/// ```dart
/// Navigator.push(context, reduceMotionRoute(builder: (_) => MyScreen()));
/// ```
library;

import 'package:flutter/material.dart';

extension ReduceMotion on BuildContext {
  /// True nếu OS đang flag "disable animations" (Reduce motion).
  /// Dùng để conditionally rút ngắn duration → 0ms hoặc skip Hero/parallax.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);
}

/// PageRoute factory honoring reduce-motion. Khi flag bật, transitionDuration=0
/// → page xuất hiện instant không slide, an toàn cho vestibular user.
///
/// Drop-in replacement cho `MaterialPageRoute(builder: ...)` ở các navigator
/// .push() có animation chuyển trang dài.
PageRoute<T> reduceMotionRoute<T>({
  required WidgetBuilder builder,
  required BuildContext context,
  RouteSettings? settings,
}) {
  if (context.reduceMotion) {
    // Instant route: no slide, no fade.
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (ctx, _, __) => builder(ctx),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
  return MaterialPageRoute<T>(builder: builder, settings: settings);
}
