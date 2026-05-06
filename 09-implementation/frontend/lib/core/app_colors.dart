/// Theme-aware color tokens — Phase 2 Sprint 2 Step 1c (2026-05-06).
///
/// Apply UI/UX Pro Max skill insight: thay vì widget hard-code const colors
/// (appBg, cardBorder, textPrimary từ light tokens), dùng extension on BuildContext
/// trả tokens phù hợp theo brightness hiện tại của Theme.of(context).
///
/// Pattern: `context.appBg`, `context.cardBg`, `context.textMuted` thay vì const.
///
/// Usage:
/// ```dart
/// Container(
///   color: context.cardBg,  // tự invert dark/light
///   child: Text('hello', style: TextStyle(color: context.textPrimary)),
/// )
/// ```
library;

import 'package:flutter/material.dart';

import 'theme.dart' as light;
import 'theme_dark.dart' as dark;

extension AppColors on BuildContext {
  /// True nếu theme hiện tại đang dark.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Brand colors — KHÔNG đổi giữa 2 theme.
  Color get ptitRed => light.ptitRed;
  Color get ptitRedSoft => isDark ? dark.ptitRedDarkSoft : light.ptitRedSoft;

  /// Background tokens — invert dark/light.
  Color get appBg => isDark ? dark.appBgDark : light.appBg;

  /// Card surface — Material 3 dùng cardColor từ ThemeData.
  Color get cardBg => Theme.of(this).cardColor;

  /// Border subtle — invert.
  Color get cardBorder => isDark ? dark.cardBorderDark : light.cardBorder;

  /// Text scale — invert. textMuted GIỮ NGUYÊN cả 2 theme (#A39B92 contrast tốt cả 2).
  Color get textPrimary => isDark ? dark.textPrimaryDark : light.textPrimary;
  Color get textMuted => isDark ? dark.textMutedDark : light.textMuted;
  Color get textFaint => isDark ? dark.textFaintDark : light.textFaint;

  /// Status colors — slightly desaturated cho dark theme.
  Color get successGreen => isDark ? dark.successGreenDark : light.successGreen;
  Color get successSoft => isDark ? dark.successSoftDark : light.successSoft;
  Color get warnOrange => isDark ? dark.warnOrangeDark : light.warnOrange;
  Color get warnSoft => isDark ? dark.warnSoftDark : light.warnSoft;
  Color get infoBlue => isDark ? dark.infoBlueDark : light.infoBlue;
  Color get infoSoft => isDark ? dark.infoSoftDark : light.infoSoft;
  // Sprint 2 fix M3 (2026-05-06): achievementGold semantic — stat huy hiệu, giải thưởng.
  Color get achievementGold => isDark ? dark.achievementGoldDark : light.achievementGold;
  Color get achievementGoldSoft => isDark ? dark.achievementGoldSoftDark : light.achievementGoldSoft;

  /// Material 3 ColorScheme — fallback khi cần colors chuẩn.
  ColorScheme get cs => Theme.of(this).colorScheme;
}
