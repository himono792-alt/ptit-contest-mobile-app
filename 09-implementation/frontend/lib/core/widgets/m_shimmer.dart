/// Loading skeleton widgets — Sprint 25 polish (2026-05-09).
///
/// Refactor từ Sprint 1.5 hardcoded colors → theme-aware + stagger animation
/// + reduced-motion support theo Material 3 / Apple HIG / modern apps pattern
/// (Facebook, LinkedIn, YouTube).
///
/// Nguyên tắc:
///   - Bg skeleton = subtle overlay trên cardBg (4% black light / 8% white dark)
///   - Bars radius 6 cho mềm mắt
///   - Period 1200ms — sweet spot smooth
///   - Stagger delay 80ms giữa các cards (wave effect)
///   - Respect MediaQuery.disableAnimations → fallback pulse static
///
/// Usage:
/// ```dart
/// asyncData.when(
///   loading: () => const MCardListSkeleton(count: 5),
///   error: ...,
///   data: ...,
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../app_colors.dart';

/// Period 1200ms — modern smooth (giảm từ 1500ms).
const Duration _kShimmerPeriod = Duration(milliseconds: 1200);

/// Stagger delay giữa các card trong list (wave effect).
const Duration _kStaggerDelay = Duration(milliseconds: 80);

/// Bar radius — soft 6 thay vì vuông 4.
const double _kBarRadius = 6.0;

/// Theme-aware skeleton colors — derive từ context để fit light/dark.
({Color base, Color highlight, Color surface}) _skeletonColors(BuildContext context) {
  if (context.isDark) {
    // Dark mode: surface card sáng nhẹ + base/highlight thấp tone hơn cardBg
    return (
      base: const Color(0xFF2A2724), // cardBg dark + ~4% lighter
      highlight: const Color(0xFF3D3936), // base + 8% lighter
      surface: const Color(0xFF231F1C), // dark surface khác card chút
    );
  }
  return (
    base: const Color(0xFFE9ECEF), // gray-200 mềm mắt
    highlight: const Color(0xFFF6F7F9), // gray-50 nhẹ
    surface: const Color(0xFFFCFCFD), // surface trắng-off
  );
}

/// Wrap child với shimmer animation (theme-aware + reduced-motion).
class MShimmer extends StatelessWidget {
  final Widget child;
  const MShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = _skeletonColors(context);
    // Respect MediaQuery.disableAnimations cho a11y reduced-motion preference.
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    if (reducedMotion) {
      // Fallback: opacity pulse static thay shimmer animation.
      return _StaticPulse(child: child);
    }
    return Shimmer.fromColors(
      baseColor: colors.base,
      highlightColor: colors.highlight,
      period: _kShimmerPeriod,
      child: child,
    );
  }
}

/// Static pulse fallback khi user prefer reduced motion.
class _StaticPulse extends StatefulWidget {
  final Widget child;
  const _StaticPulse({required this.child});

  @override
  State<_StaticPulse> createState() => _StaticPulseState();
}

class _StaticPulseState extends State<_StaticPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.5, end: 0.85).animate(_ctrl),
      child: widget.child,
    );
  }
}

/// Skeleton placeholder cho 1 card (vd notification, contest, entry).
/// Theme-aware: surface invert dark/light, không có border, bars rounded.
class MCardSkeleton extends StatelessWidget {
  /// Số dòng text body (default 2).
  final int textLines;
  /// Có hiện tag pill ở góc phải không (default true).
  final bool showTag;
  /// Stagger index — tăng delay theo position trong list (default 0).
  final int staggerIndex;
  const MCardSkeleton({
    super.key,
    this.textLines = 2,
    this.showTag = true,
    this.staggerIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _skeletonColors(context);
    return _StaggeredFadeIn(
      delay: _kStaggerDelay * staggerIndex,
      child: MShimmer(
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: title bar + tag pill
              Row(children: [
                Expanded(
                  child: _bar(
                      colors.base,
                      height: 14,
                      maxFraction: 0.55 + (staggerIndex % 3) * 0.08),
                ),
                if (showTag) ...[
                  const SizedBox(width: 10),
                  _bar(colors.base, width: 56, height: 18, radius: 9),
                ],
              ]),
              const SizedBox(height: 12),
              // Body text lines — variation widths cho tự nhiên
              for (int i = 0; i < textLines; i++) ...[
                _bar(
                  colors.base,
                  height: 10,
                  maxFraction: i == textLines - 1
                      ? 0.65 + (staggerIndex % 4) * 0.05
                      : 0.92 - (i * 0.04),
                ),
                if (i < textLines - 1) const SizedBox(height: 7),
              ],
              const SizedBox(height: 10),
              // Footer: small timestamp
              _bar(colors.base, width: 78, height: 9),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper: 1 bar chữ nhật bo góc, color truyền in vì shimmer wrap ngoài.
  static Widget _bar(
    Color baseColor, {
    double? width,
    required double height,
    double radius = _kBarRadius,
    double? maxFraction,
  }) {
    final inner = Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
    if (maxFraction == null) return inner;
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: maxFraction,
      child: inner,
    );
  }
}

/// Subtle fade-in delay cho stagger wave effect.
class _StaggeredFadeIn extends StatefulWidget {
  final Duration delay;
  final Widget child;
  const _StaggeredFadeIn({required this.delay, required this.child});

  @override
  State<_StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<_StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
        child: widget.child,
      ),
    );
  }
}

/// Skeleton danh sách N cards với stagger delay (wave effect).
class MCardListSkeleton extends StatelessWidget {
  final int count;
  final EdgeInsetsGeometry padding;
  final int textLines;
  final bool showTag;
  const MCardListSkeleton({
    super.key,
    this.count = 4,
    this.padding = const EdgeInsets.all(16),
    this.textLines = 2,
    this.showTag = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, i) => MCardSkeleton(
        textLines: textLines,
        showTag: showTag,
        staggerIndex: i,
      ),
    );
  }
}

/// Skeleton row đơn giản — list item với avatar/rank circle + 2 bars + badge.
class MListItemSkeleton extends StatelessWidget {
  /// Stagger index — tăng delay theo position trong list (default 0).
  final int staggerIndex;
  const MListItemSkeleton({super.key, this.staggerIndex = 0});

  @override
  Widget build(BuildContext context) {
    final colors = _skeletonColors(context);
    return _StaggeredFadeIn(
      delay: _kStaggerDelay * staggerIndex,
      child: MShimmer(
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            // Avatar / rank circle
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colors.base,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MCardSkeleton._bar(
                      colors.base, height: 12, maxFraction: 0.65),
                  const SizedBox(height: 7),
                  MCardSkeleton._bar(
                      colors.base, height: 9, maxFraction: 0.4),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Score / award badge
            MCardSkeleton._bar(
                colors.base, width: 60, height: 22, radius: 11),
          ]),
        ),
      ),
    );
  }
}
