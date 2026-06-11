import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'radius.dart';
export 'radius.dart'; // Re-export để files import theme.dart có sẵn AppRadius.

/// Color palette matching 05-mockups tokens.css (PTIT brand).
/// Anchor: PTIT red #C8102E ≈ oklch(0.547 0.207 19).
const Color ptitRed = Color(0xFFC8102E);
const Color ptitRedSoft = Color(0xFFFEE5E9); // ≈ oklch(0.965 0.022 19)
const Color ptitRedDark = Color(0xFFA00D24);

// Sprint 18 (2026-05-08) S18-5: OKLCH 9-stop ramp cho PTIT brand
// theo design tokens.css. Anchor 500 = ptitRed, đối xứng L từ 0.97 → 0.20.
// Hue ≈ 19, chroma scale theo L để giữ perceptual uniformity.
//
// Ưu tiên dùng các stop này thay vì `ptitRed.withValues(alpha:0.X)` ad-hoc
// vì OKLCH preserve perceived lightness tốt hơn alpha overlay.
const Color ptitRed50 = Color(0xFFFFF1F3);  // pale tint — bg subtle
const Color ptitRed100 = Color(0xFFFEE5E9); // = ptitRedSoft
const Color ptitRed200 = Color(0xFFFCC9D0); // hover bg
const Color ptitRed300 = Color(0xFFF89AA8); // disabled fg
const Color ptitRed400 = Color(0xFFEE5970); // accent secondary
const Color ptitRed500 = ptitRed;            // anchor brand
const Color ptitRed600 = ptitRedDark;        // hover/pressed
const Color ptitRed700 = Color(0xFF7E0A1C); // emphasized
const Color ptitRed800 = Color(0xFF5C0815); // dark mode bg pill
const Color ptitRed900 = Color(0xFF3D050D); // deepest, rare use
const Color appBg = Color(0xFFFAF8F5); // ink-50 — warm-leaning bg
const Color cardBorder = Color(0xFFEDE7DF); // ink-200 — softer border
const Color textPrimary = Color(0xFF1C1815); // ink-900 — warm dark
const Color textMuted = Color(0xFF7A6F65); // ink-600 — warm muted
const Color textFaint = Color(0xFFA39B92); // ink-500
const Color successGreen = Color(0xFF16A34A);
const Color successSoft = Color(0xFFDCFCE7);
const Color warnOrange = Color(0xFFD97706);
const Color warnSoft = Color(0xFFFEF3C7);
// Sprint 2 fix M3 (2026-05-06): achievementGold tokens — dùng cho stat card "Giải
// thưởng" + huy hiệu. Tách khỏi warn (dùng cho cảnh báo) để semantic rõ ràng.
// Light: amber-700 fg trên amber-100 bg → tone gold rõ rệt, không lẫn với warn.
const Color achievementGold = Color(0xFFB45309); // amber-700
const Color achievementGoldSoft = Color(0xFFFEF3C7); // amber-100 (light bg)
const Color infoBlue = Color(0xFF2563EB);
const Color infoSoft = Color(0xFFDBEAFE);

// Brand hero gradient — design audit M1 (2026-05-06).
// Trước đó copy-paste 6 chỗ; gom về 1 nguồn để khi rebrand chỉ sửa 1 list.
//
// Dùng `ptitGradientHero` cho hero card diagonal (topLeft → bottomRight).
// Dùng `LinearGradient(colors: ptitGradientHeroColors)` khi cần alignment khác
// (vd: horizontal default hoặc top → bottom).
const List<Color> ptitGradientHeroColors = [ptitRed, Color(0xFFFF6B7E)];
const LinearGradient ptitGradientHero = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: ptitGradientHeroColors,
);

// Sprint 18 (2026-05-08) S18-2: avatar gradient PTIT red → purple
// theo design SVW-07 `linear-gradient(135deg, #C8102E, #7C3AED)`.
// Riêng gradient cho avatar (không dùng cho hero card) để tránh đồng nhất
// brand identity quá strong với purple — purple chỉ accent.
const List<Color> ptitGradientAvatarColors = [ptitRed, Color(0xFF7C3AED)];
const LinearGradient ptitGradientAvatar = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: ptitGradientAvatarColors,
);

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      textStyle: _jakarta(14, FontWeight.w700, color: Colors.white),
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: textPrimary,
      side: const BorderSide(color: cardBorder),
      minimumSize: const Size(double.infinity, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
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
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: cardBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: cardBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    titleTextStyle: _jakarta(16, FontWeight.w800, letterSpacing: -0.32),
  ),
  snackBarTheme: SnackBarThemeData(
    backgroundColor: textPrimary,
    contentTextStyle: _jakarta(13, FontWeight.w500, color: Colors.white),
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
  ),
);
