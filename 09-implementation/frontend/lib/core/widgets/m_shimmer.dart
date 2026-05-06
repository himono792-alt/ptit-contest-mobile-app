/// Loading skeleton widgets — Phase 2 sprint 1 step 5 (2026-05-06).
///
/// Replace `CircularProgressIndicator` ở các screens async (notifications, contests,
/// my registrations, results, home). Pattern modern Facebook/Twitter/Slack:
/// hiện placeholder mimic content layout với gradient sáng-mờ chạy ngang →
/// user cảm giác load ~2x faster (perceived performance).
///
/// Usage:
/// ```dart
/// asyncData.when(
///   loading: () => const _NotificationListSkeleton(count: 5),
///   error: ...,
///   data: ...,
/// )
/// ```
library;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../app_colors.dart';
import '../theme.dart';

/// Color palette neutral xám nhạt (chọn C1 — KHÔNG dùng đỏ PTIT vì gây nhức mắt).
const Color _shimmerBase = Color(0xFFE5E7EB);
const Color _shimmerHighlight = Color(0xFFF3F4F6);

/// Period 1500ms (chọn B1 — smooth, không quá nhanh/chậm).
const Duration _shimmerPeriod = Duration(milliseconds: 1500);


/// Wrap child với shimmer animation. Reusable nếu cần custom skeleton riêng.
class MShimmer extends StatelessWidget {
  final Widget child;
  const MShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _shimmerBase,
      highlightColor: _shimmerHighlight,
      period: _shimmerPeriod,
      child: child,
    );
  }
}


/// Skeleton placeholder cho 1 card (vd notification, contest, entry).
/// Layout: title bar + 2 lines text + tag pill. Match MCard kích thước.
class MCardSkeleton extends StatelessWidget {
  /// Số dòng text body (default 2).
  final int textLines;
  /// Có hiện tag pill ở góc phải không (default true).
  final bool showTag;
  const MCardSkeleton({super.key, this.textLines = 2, this.showTag = true});

  @override
  Widget build(BuildContext context) {
    return MShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: title bar 60% + tag pill
            Row(children: [
              Expanded(
                child: _bar(width: double.infinity, height: 14, maxFraction: 0.6),
              ),
              if (showTag) ...[
                const SizedBox(width: 8),
                _bar(width: 56, height: 18, radius: 9),
              ],
            ]),
            const SizedBox(height: 10),
            // Body text lines
            for (int i = 0; i < textLines; i++) ...[
              _bar(
                width: double.infinity,
                height: 11,
                maxFraction: i == textLines - 1 ? 0.75 : 0.95,
              ),
              if (i < textLines - 1) const SizedBox(height: 6),
            ],
            const SizedBox(height: 8),
            // Footer: small timestamp
            _bar(width: 80, height: 9),
          ],
        ),
      ),
    );
  }

  /// Helper: 1 bar chữ nhật bo góc, animation shimmer wrap bên ngoài.
  static Widget _bar({
    required double width,
    required double height,
    double radius = 4,
    double? maxFraction,
  }) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: maxFraction,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _shimmerBase,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}


/// Skeleton danh sách N cards. Dùng cho notifications, my entries, contests.
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
      itemBuilder: (_, __) => MCardSkeleton(
        textLines: textLines,
        showTag: showTag,
      ),
    );
  }
}


/// Skeleton row đơn giản — dùng cho results rank list (rank · SV · score).
class MListItemSkeleton extends StatelessWidget {
  const MListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return MShimmer(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.cardBorder),
        ),
        child: Row(children: [
          // Rank circle
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _shimmerBase,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              MCardSkeleton._bar(width: double.infinity, height: 12, maxFraction: 0.7),
              const SizedBox(height: 6),
              MCardSkeleton._bar(width: double.infinity, height: 9, maxFraction: 0.4),
            ]),
          ),
          const SizedBox(width: 12),
          // Score / award badge
          MCardSkeleton._bar(width: 60, height: 22, radius: 11),
        ]),
      ),
    );
  }
}
