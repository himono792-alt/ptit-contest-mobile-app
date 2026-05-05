import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Color palette matching 05-mockups tokens.css (PTIT brand).
/// Anchor: PTIT red #C8102E ≈ oklch(0.547 0.207 19).
const Color ptitRed = Color(0xFFC8102E);
const Color ptitRedSoft = Color(0xFFFEE5E9); // ≈ oklch(0.965 0.022 19)
const Color ptitRedDark = Color(0xFFA00D24);
const Color appBg = Color(0xFFFAF8F5); // ink-50 — warm-leaning bg
const Color cardBorder = Color(0xFFEDE7DF); // ink-200 — softer border
const Color textPrimary = Color(0xFF1C1815); // ink-900 — warm dark
const Color textMuted = Color(0xFF7A6F65); // ink-600 — warm muted
const Color textFaint = Color(0xFFA39B92); // ink-500
const Color successGreen = Color(0xFF16A34A);
const Color successSoft = Color(0xFFDCFCE7);
const Color warnOrange = Color(0xFFD97706);
const Color warnSoft = Color(0xFFFEF3C7);
const Color infoBlue = Color(0xFF2563EB);
const Color infoSoft = Color(0xFFDBEAFE);

// Soft layered shadow — phong cách Linear/Notion (mockup tokens.css)
final List<BoxShadow> shadowSm = [
  BoxShadow(color: const Color(0xFF14100A).withValues(alpha: 0.06), offset: const Offset(0, 1), blurRadius: 3),
  BoxShadow(color: const Color(0xFF14100A).withValues(alpha: 0.04), offset: const Offset(0, 1), blurRadius: 2),
];
final List<BoxShadow> shadowMd = [
  BoxShadow(color: const Color(0xFF14100A).withValues(alpha: 0.06), offset: const Offset(0, 4), blurRadius: 12),
  BoxShadow(color: const Color(0xFF14100A).withValues(alpha: 0.04), offset: const Offset(0, 2), blurRadius: 4),
];

/// TextStyle helpers — Plus Jakarta Sans + tighter tracking (mockup style).
TextStyle _jakarta(double size, FontWeight weight, {Color? color, double? letterSpacing, double? height}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: size,
    fontWeight: weight,
    color: color ?? textPrimary,
    letterSpacing: letterSpacing ?? -size * 0.015, // ≈ -0.015em
    height: height,
  );
}

final ThemeData ptitLightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ptitRed,
    primary: ptitRed,
    surface: Colors.white,
    onSurface: textPrimary,
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: appBg,
  // Apply Plus Jakarta Sans cho toàn bộ default text widgets.
  textTheme: GoogleFonts.plusJakartaSansTextTheme().apply(
    bodyColor: textPrimary,
    displayColor: textPrimary,
  ).copyWith(
    bodyLarge: _jakarta(15, FontWeight.w500),
    bodyMedium: _jakarta(13, FontWeight.w500),
    bodySmall: _jakarta(12, FontWeight.w500, color: textMuted),
    titleLarge: _jakarta(20, FontWeight.w800, letterSpacing: -0.5),
    titleMedium: _jakarta(15, FontWeight.w700, letterSpacing: -0.3),
    titleSmall: _jakarta(13, FontWeight.w600),
    labelLarge: _jakarta(14, FontWeight.w600),
    labelMedium: _jakarta(12, FontWeight.w600),
    labelSmall: _jakarta(11, FontWeight.w600),
    headlineLarge: _jakarta(28, FontWeight.w800, letterSpacing: -0.84),
    headlineMedium: _jakarta(22, FontWeight.w800, letterSpacing: -0.66),
    headlineSmall: _jakarta(18, FontWeight.w700, letterSpacing: -0.45),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: ptitRed,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: _jakarta(14, FontWeight.w700, color: Colors.white),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: textPrimary,
      side: const BorderSide(color: cardBorder),
      minimumSize: const Size(double.infinity, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: _jakarta(13, FontWeight.w600),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ptitRed,
      textStyle: _jakarta(13, FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: ptitRed, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    labelStyle: _jakarta(12, FontWeight.w500, color: textMuted),
    hintStyle: _jakarta(13, FontWeight.w400, color: textFaint),
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: textPrimary,
    elevation: 0,
    centerTitle: false,
    surfaceTintColor: Colors.white,
    titleTextStyle: _jakarta(15, FontWeight.w700, letterSpacing: -0.3),
    iconTheme: const IconThemeData(color: textMuted, size: 20),
    shape: const Border(bottom: BorderSide(color: cardBorder, width: 1)),
  ),
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    titleTextStyle: _jakarta(16, FontWeight.w800, letterSpacing: -0.32),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: textPrimary,
    contentTextStyle: _jakarta(13, FontWeight.w500, color: Colors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ),
);
