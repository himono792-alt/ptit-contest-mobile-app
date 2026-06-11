/// Animation durations + curves — theo frontend-design skill.
///
/// Nguyên tắc: mọi `Duration(milliseconds: N)` trong animation/transition phải
/// dùng một trong 3 constant dưới đây.
///
/// Lý do: Material guideline khuyến nghị 150/250/400ms cho 3 cấp độ tương tác.
/// Trộn lẫn 200ms / 300ms / 500ms khắp nơi tạo cảm giác "không nhất quán".
///
/// Usage:
/// ```dart
/// AnimatedContainer(duration: AppDuration.fast, ...)      // 150ms — hover
/// AnimatedSwitcher(duration: AppDuration.base, ...)       // 250ms — default
/// PageRouteBuilder(transitionDuration: AppDuration.slow)  // 400ms — page nav
///
/// Curves.easeOut → AppCurve.easeOut (consistency wrapper)
/// ```
library;

import 'package:flutter/animation.dart';

class AppDuration {
  AppDuration._();

  /// 150ms — hover, focus, micro-interactions.
  static const Duration fast = Duration(milliseconds: 150);

  /// 250ms — default for menu open, drawer, tab switch.
  static const Duration base = Duration(milliseconds: 250);

  /// 400ms — page transition, large content reveal.
  static const Duration slow = Duration(milliseconds: 400);
}

class AppCurve {
  AppCurve._();

  /// Material default — entering elements (most common).
  static const Curve easeOut = Curves.easeOutCubic;

  /// Both directions — toggles, expanding panels.
  static const Curve easeInOut = Curves.easeInOutCubic;

  /// Exit elements (less common; pair với easeOut cho enter).
  static const Curve easeIn = Curves.easeInCubic;
}
