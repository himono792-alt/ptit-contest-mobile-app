import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/pill.dart';
import 'contest_list_screen.dart';
import 'my_results_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends ConsumerWidget {
  /// Callback để switch tab (gọi từ shell). null = không hiện shortcut.
  final ValueChanged<int>? onSwitchTab;
  const HomeScreen({super.key, this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: ptitRed)));
    }
    final initial = user.fullName.isNotEmpty
        ? user.fullName.split(' ').last.substring(0, 1).toUpperCase()
        : 'U';

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          // ============== Header: avatar + greeting + bell ==============
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
            child: Row(children: [
              // Avatar + greeting đều click được → switch sang tab Tôi (index 5)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  onTap: () => onSwitchTab?.call(5),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: context.ptitRedSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: GoogleFonts.plusJakartaSans(
                              color: ptitRed,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Xin chào,',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    color: context.textMuted,
                                    fontWeight: FontWeight.w500)),
                            Text(
                              user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _BellButton(),
            ]),
          ),

          // ============== Search bar (placeholder hiện tại) ==============
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: GestureDetector(
              onTap: () => onSwitchTab?.call(1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  border: Border.all(color: context.cardBorder),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(children: [
                  Icon(Icons.search, size: 17, color: context.textFaint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Tìm cuộc thi, BTC...',
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 13, color: context.textFaint)),
                  ),
                ]),
              ),
            ),
          ),

          // ============== Body scrollable: stats + featured ==============
          Expanded(
            child: RefreshIndicator(
              color: ptitRed,
              onRefresh: () async {
                ref.invalidate(contestListProvider);
                ref.invalidate(myResultsProvider);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                children: [
                  _StatsRow(onSwitchTab: onSwitchTab),
                  const SizedBox(height: 22),
                  _SectionHead(
                    title: 'Cuộc thi nổi bật',
                    actionLabel: 'Xem tất cả',
                    onAction: () => onSwitchTab?.call(1),
                  ),
                  const SizedBox(height: 10),
                  const _FeaturedContests(),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ===================== Stats row =====================

class _StatsRow extends ConsumerWidget {
  final ValueChanged<int>? onSwitchTab;
  const _StatsRow({this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(myResultsProvider);
    final contests = ref.watch(contestListProvider);

    final completed = results.maybeWhen(data: (r) => r.length, orElse: () => 0);
    final awarded = results.maybeWhen(
      data: (r) => r.where((x) => (x.awardTitle ?? '').isNotEmpty).length,
      orElse: () => 0,
    );
    final ongoing = contests.maybeWhen(
      data: (d) => d.items.where((c) =>
          c.status == 'PUBLISHED' ||
          c.status == 'REG_OPEN' ||
          c.status == 'REG_CLOSED' ||
          c.status == 'ONGOING').length,
      orElse: () => 0,
    );

    return Row(children: [
      Expanded(
        child: _StatCard(
          value: '$ongoing',
          label: 'Đang diễn ra',
          tone: _StatTone.brand,
          onTap: () => onSwitchTab?.call(1),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatCard(
          value: '$completed',
          label: 'Đã hoàn thành',
          tone: _StatTone.neutral,
          onTap: () => onSwitchTab?.call(2),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatCard(
          value: '$awarded',
          label: 'Giải thưởng',
          // Sprint 2 fix M3 (2026-05-06): tone gold thay vì warn để tránh
          // dark mode render brown lệch palette (warnSoftDark = amber-900).
          tone: _StatTone.gold,
          onTap: () => onSwitchTab?.call(2),
        ),
      ),
    ]);
  }
}

enum _StatTone { brand, neutral, warn, gold }

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final _StatTone tone;
  final VoidCallback? onTap;
  const _StatCard({
    required this.value,
    required this.label,
    required this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _StatTone.brand => (bg: context.ptitRedSoft, fg: ptitRed),
      _StatTone.warn => (bg: context.warnSoft, fg: context.warnOrange),
      _StatTone.gold => (bg: context.achievementGoldSoft, fg: context.achievementGold),
      _StatTone.neutral => (bg: const Color(0xFFF1ECE5), fg: context.textPrimary),
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colors.fg,
                  letterSpacing: -0.78,
                  height: 1,
                )),
            const SizedBox(height: 6),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.fg.withValues(alpha: 0.85),
                )),
          ],
        ),
      ),
    );
  }
}

// ===================== Section head =====================

class _SectionHead extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionHead({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: context.textPrimary,
            )),
      ),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Text(actionLabel!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ptitRed,
              )),
        ),
    ]);
  }
}

// ===================== Featured contests =====================

class _FeaturedContests extends ConsumerWidget {
  const _FeaturedContests();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(contestListProvider);
    return asyncList.when(
      // Phase 2 step 5: skeleton 3 contest cards thay spinner
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: MCardListSkeleton(
          count: 3,
          textLines: 2,
          padding: EdgeInsets.zero,
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
            child: Text('Không tải được cuộc thi',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: context.textMuted))),
      ),
      data: (data) {
        // Lấy 3 contests đầu tiên (priority: REG_OPEN > PUBLISHED > others)
        final sorted = [...data.items]
          ..sort((a, b) {
            int score(String s) => switch (s) {
                  'REG_OPEN' => 0,
                  'ONGOING' => 1,
                  'PUBLISHED' => 2,
                  'REG_CLOSED' => 3,
                  _ => 4,
                };
            return score(a.status).compareTo(score(b.status));
          });
        final featured = sorted.take(3).toList();
        if (featured.isEmpty) {
          return MCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Chưa có cuộc thi nào.',
                  style: GoogleFonts.plusJakartaSans(
                      color: context.textMuted, fontSize: 13),
                ),
              ),
            ),
          );
        }
        return Column(
            children: featured.map((c) => _FeaturedCard(contest: c)).toList());
      },
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final dynamic contest;
  const _FeaturedCard({required this.contest});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    return MCard(
      onTap: () => context.push('/contests/${contest.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover stripe
          Container(
            height: 6,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: ptitGradientHeroColors),
              borderRadius: BorderRadius.circular(AppRadius.tight),
            ),
          ),
          Row(children: [
            Expanded(
              child: Text(contest.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: context.textPrimary,
                    height: 1.3,
                  )),
            ),
            const SizedBox(width: 8),
            Pill.status(contest.status),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.calendar_today_outlined, size: 13, color: context.textFaint),
            const SizedBox(width: 4),
            Text('${fmt.format(contest.startAt)} – ${fmt.format(contest.endAt)}',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: context.textMuted, fontWeight: FontWeight.w500)),
            const SizedBox(width: 14),
            Icon(Icons.location_on_outlined, size: 13, color: context.textFaint),
            const SizedBox(width: 4),
            Text(_modeLabel(contest.deliveryMode),
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, color: context.textMuted, fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }

  String _modeLabel(String m) =>
      m == 'ONLINE' ? 'Online' : (m == 'OFFLINE' ? 'Offline' : 'Hybrid');
}

// ===================== Bell button (with badge) =====================

class _BellButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(notificationsProvider);
    final unread = asyncData.maybeWhen(
      data: (d) => d['unread_count'] as int? ?? 0,
      orElse: () => 0,
    );
    // Sprint 3 a11y (2026-05-07): wrap notification bell với Semantics rõ hơn
    // (IconButton có tooltip default nhưng không nói số unread).
    final unreadHint = unread > 0
        ? 'Mở thông báo, $unread thông báo chưa đọc'
        : 'Mở thông báo';
    return Stack(clipBehavior: Clip.none, children: [
      Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border.all(color: context.cardBorder),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Semantics(
          label: unreadHint,
          button: true,
          excludeSemantics: true, // tránh nested với IconButton inner
          child: IconButton(
          iconSize: 18,
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.notifications_outlined, color: context.textPrimary),
          onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
        ),
      ),
      if (unread > 0)
        Positioned(
          right: 6,
          top: 6,
          child: Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: ptitRed,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
    ]);
  }
}
