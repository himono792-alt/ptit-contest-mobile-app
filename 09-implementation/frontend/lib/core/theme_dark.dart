/// Dark theme tokens — Phase 2 Sprint 2 Step 1 (2026-05-06).
///
/// Pattern: invert ink scale từ light theme (warm-leaning), giữ ptitRed brand.
/// Material 3 ThemeData.dark base + override colorScheme + textTheme + components.
///
/// Pair với theme.dart (light tokens). Switch qua themeProvider state.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'theme.dart' show ptitRed;

// ============== Dark color palette ==============

/// Brand không đổi — đỏ PTIT giữ nguyên cả 2 theme.
const Color ptitRedDarkSoft = Color(0xFF4A1822); // ≈ ptitRedSoft inverted (dark variant)

/// Background warm dark — không đen tuyền để dễ đọc + match brand warm-leaning.
const Color appBgDark = Color(0xFF1C1815); // ink-900 inverted thành bg
const Color cardBgDark = Color(0xFF25211D); // ink-850 — surface card nổi nhẹ
const Color cardBorderDark = Color(0xFF2D2A26); // ink-800 — border subtle

/// Text scale — dark theme dùng warm white tones, giữ contrast > 4.5:1
const Color textPrimaryDark = Color(0xFFFAF8F5); // ≈ appBg light inverted
const Color textMutedDark = Color(0xFFA39B92); // ink-500 (giữ giống light — middle gray)
const Color textFaintDark = Color(0xFF6B6357); // ink-700 dark variant

// Status colors dark — slightly desaturated để bớt chói
const Color successGreenDark = Color(0xFF22C55E);
const Color successSoftDark = Color(0xFF14532D);
const Color warnOrangeDark = Color(0xFFF59E0B);
const Color warnSoftDark = Color(0xFF78350F);
// Sprint 2 fix M3 (2026-05-06): achievementGold dark mode tokens.
// fg = amber-300 (light gold), bg = amber-950 (gần đen, đậm gold) thay vì
// amber-900 brown như warn. Stat "Giải thưởng" sẽ feel gold thay vì nâu.
const Color achievementGoldDark = Color(0xFFFCD34D); // amber-300
const Color achievementGoldSoftDark = Color(0xFF422006); // amber-950
const Color infoBlueDark = Color(0xFF3B82F6);
const Color infoSoftDark = Color(0xFF1E3A8A);

/// Soft layered shadow — dark mode nhẹ hơn light vì bg tối khó nhìn shadow
final List<BoxShadow> shadowSmDark = [
  BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 1), blurRadius: 3),
];
final List<BoxShadow> shadowMdDark = [
  BoxShadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(0, 4), blurRadius: 12),
];

// ============== Helpers ==============

TextStyle _jakartaDark(double size, FontWeight weight,
    {Color? color, double? letterSpacing, double? height}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color ?? textPrimaryDark,
    letterSpacing: letterSpacing ?? -size * 0.015,
    height: height,
  );
}

// ============== ThemeData dark ==============

final ThemeData ptitDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ptitRed,
    primary: ptitRed,
    surface: cardBgDark,
    onSurface: textPrimaryDark,
    brightness: Brightness.dark,
  ),
  scaffoldBackgroundColor: appBgDark,
  textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).apply(
    bodyColor: textPrimaryDark,
    displayColor: textPrimaryDark,
  ).copyWith(
    bodyLarge: _jakartaDark(15, FontWeight.w500),
    bodyMedium: _jakartaDark(13, FontWeight.w500),
    bodySmall: _jakartaDark(12, FontWeight.w500, color: textMutedDark),
    titleLarge: _jakartaDark(20, FontWeight.w800, letterSpacing: -0.5),
    titleMedium: _jakartaDark(15, FontWeight.w700, letterSpacing: -0.3),
    titleSmall: _jakartaDark(13, FontWeight.w600),
    labelLarge: _jakartaDark(14, FontWeight.w600),
    labelMedium: _jakartaDark(12, FontWeight.w600),
    labelSmall: _jakartaDark(11, FontWeight.w600),
    headlineLarge: _jakartaDark(28, FontWeight.w800, letterSpacing: -0.84),
    headlineMedium: _jakartaDark(22, FontWeight.w800, letterSpacing: -0.66),
    headlineSmall: _jakartaDark(18, FontWeight.w700, letterSpacing: -0.45),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ptitRed,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: _jakartaDark(14, FontWeight.w700, color: Colors.white),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: textPrimaryDark,
      side: const BorderSide(color: cardBorderDark),
      minimumSize: const Size(double.infinity, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: _jakartaDark(13, FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ptitRed,
      textStyle: _jakartaDark(13, FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: cardBorderDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: cardBorderDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ptitRed, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    labelStyle: _jakartaDark(12, FontWeight.w500, color: textMutedDark),
    hintStyle: _jakartaDark(13, FontWeight.w400, color: textFaintDark),
    fillColor: cardBgDark,
    filled: true,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: cardBgDark,
    foregroundColor: textPrimaryDark,
    elevation: 0,
    centerTitle: false,
    surfaceTintColor: cardBgDark,
    titleTextStyle: _jakartaDark(15, FontWeight.w700, letterSpacing: -0.3),
    iconTheme: const IconThemeData(color: textMutedDark, size: 20),
    shape: const Border(bottom: BorderSide(color: cardBorderDark, width: 1)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: cardBgDark,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: _jakartaDark(16, FontWeight.w800, letterSpacing: -0.32),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: cardBgDark,
    contentTextStyle: _jakartaDark(13, FontWeight.w500, color: textPrimaryDark),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
  cardTheme: const CardThemeData(
    color: cardBgDark,
    surfaceTintColor: cardBgDark,
  ),
  dividerColor: cardBorderDark,
);
