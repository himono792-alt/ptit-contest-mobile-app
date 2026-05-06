/// Spacing scale — 4-base, theo design system audit 2026-05-06.
///
/// Nguyên tắc: mọi padding/margin/gap trong UI features/ phải dùng
/// một trong các constant dưới đây thay vì literal số nguyên.
///
/// Lý do: tránh drift kiểu "14px ở chỗ này, 13px ở chỗ kia" — design
/// system audit đã phát hiện 95 instances off-scale trong baseline.
///
/// Usage:
/// ```dart
/// Padding(padding: EdgeInsets.all(AppSpacing.s16))           // = 16
/// SizedBox(height: AppSpacing.s24)                           // = 24
/// EdgeInsets.symmetric(horizontal: AppSpacing.s16, vertical: AppSpacing.s12)
/// ```
///
/// Edge cases (intentional, không cần dùng AppSpacing):
/// - Input padding theme.dart `vertical: 13` (Material baseline ratio)
/// - Custom micro-spacing trong shared widget primitives (Pill, Badge)
library;

class AppSpacing {
  AppSpacing._();

  /// 4 — micro spacing (icon-text gap, badge inner padding).
  static const double s4 = 4.0;

  /// 8 — small gap (chip padding, list item gap).
  static const double s8 = 8.0;

  /// 12 — default tight (button vertical padding, dense card).
  static const double s12 = 12.0;

  /// 16 — default (card padding, screen edge, form field gap).
  static const double s16 = 16.0;

  /// 20 — slightly looser (section header bottom margin).
  static const double s20 = 20.0;

  /// 24 — section gap (between cards, between heading and body).
  static const double s24 = 24.0;

  /// 32 — large gap (between major sections, hero bottom).
  static const double s32 = 32.0;

  /// 48 — extra large (page top spacing, hero top).
  static const double s48 = 48.0;

  /// 64 — hero spacing (landing page sections, empty state vertical center).
  static const double s64 = 64.0;
}
