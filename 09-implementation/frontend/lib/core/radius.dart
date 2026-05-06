/// Border radius scale — theo design system audit 2026-05-06.
///
/// Nguyên tắc: mọi `BorderRadius.circular(N)` trong UI features/ phải
/// dùng một trong 4 constant dưới đây.
///
/// Lý do: audit phát hiện 6 giá trị radius khác nhau (5/6/7/8/14/16) cho
/// cùng vai trò card/button — không có pattern, mắt cảm giác "không ổn định".
/// Quy ước: 10 cho card, 12 cho button/input, 20 cho dialog/hero, 999 cho pill.
///
/// Usage:
/// ```dart
/// BorderRadius.circular(AppRadius.sm)   // 10 — card / row stripe
/// BorderRadius.circular(AppRadius.md)   // 12 — button / input / interactive
/// BorderRadius.circular(AppRadius.lg)   // 20 — dialog / modal / hero card
/// BorderRadius.circular(AppRadius.pill) // 999 — fully rounded (avatar, chip)
/// ```
library;

class AppRadius {
  AppRadius._();

  /// 4 — micro-radius cho thin elements (height ≤6px): hairline divider,
  /// cover stripe, badge dot. Dùng radius lớn hơn sẽ tạo full circle ends.
  static const double tight = 4.0;

  /// 10 — card, row stripe, secondary surface.
  static const double sm = 10.0;

  /// 12 — button, input, interactive element (matches theme.dart filledButton).
  static const double md = 12.0;

  /// 20 — dialog, modal, hero card (matches theme.dart dialogTheme).
  static const double lg = 20.0;

  /// 999 — fully rounded (avatar circle, chip, badge, FAB).
  static const double pill = 999.0;
}
