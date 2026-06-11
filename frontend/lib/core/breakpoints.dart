/// Responsive breakpoints — theo frontend-design skill.
///
/// Nguyên tắc: mọi `MediaQuery.sizeOf(context).width < N` phải dùng
/// một trong 4 constant dưới đây thay vì literal pixel.
///
/// Lý do: app PTIT chạy responsive web (Cloudflare Pages) + mobile APK.
/// Test target: 360px (mobile narrow) / 768px (tablet) / 1024px (laptop) / 1440px (desktop).
///
/// Usage:
/// ```dart
/// final isMobile = MediaQuery.sizeOf(context).width < kBpMd;
/// final isCompact = isMobile(context);   // helper
///
/// LayoutBuilder(builder: (ctx, c) {
///   if (c.maxWidth < kBpMd) return MobileLayout();
///   if (c.maxWidth < kBpLg) return TabletLayout();
///   return DesktopLayout();
/// });
/// ```
library;

import 'package:flutter/widgets.dart';

/// 640px — landscape phone / small tablet.
const double kBpSm = 640.0;

/// 768px — tablet portrait (default mobile cutoff).
const double kBpMd = 768.0;

/// 1024px — tablet landscape / small laptop.
const double kBpLg = 1024.0;

/// 1280px — desktop.
const double kBpXl = 1280.0;

/// True nếu viewport hiện tại < kBpMd (mobile narrow + portrait).
bool isMobile(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kBpMd;

/// True nếu viewport hiện tại < kBpLg (mobile + tablet).
bool isCompact(BuildContext context) =>
    MediaQuery.sizeOf(context).width < kBpLg;

/// True nếu viewport hiện tại >= kBpLg (laptop + desktop).
bool isWide(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kBpLg;
