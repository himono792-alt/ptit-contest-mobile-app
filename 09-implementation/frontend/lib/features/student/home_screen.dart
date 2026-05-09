// Sprint 20 (2026-05-09) — Home redesign theo mockup:
//   - Header: greeting + date + bell button
//   - 3 hero gradient cards (red/blue/green) horizontal, click → contest detail
//   - 2-column layout:
//     * Left "Sắp diễn ra" timeline list 4 contests (date pill + title + tag)
//     * Right "Của tôi" stats panel 3 cards (participating / top rank / certificates)
//
// Responsive:
//   - ≥1100 wide: full 2-col layout với hero row
//   - 900-1100: hero row + 2-col stack tighter
//   - <900: hero stack vertical + sections stack

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/contest.dart';
import '../../core/models/result.dart';
import '../../core/spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import 'contest_list_screen.dart';
import 'my_registrations_screen.dart';
import 'my_results_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends ConsumerWidget {
  /// Callback để switch tab (gọi từ shell). null = không hiện shortcut.
  final ValueChanged<int>? onSwitchTab;
  const HomeScreen({super.key, this.onSwitchTab});

  /// Parse tên ngắn từ fullName (chữ cuối — vd "Phạm Minh Anh" → "Minh Anh"
  /// nếu có space, hoặc full nếu chỉ 1 từ). Heuristic VN: lấy 2 từ cuối.
  String _shortGreetingName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]} ${parts.last}';
    }
    return parts.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: ptitRed)));
    }

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;
    final today = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(today);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: ptitRed,
          onRefresh: () async {
            ref.invalidate(contestListProvider);
            ref.invalidate(myResultsProvider);
            ref.invalidate(myEntriesProvider);
          },
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              isWide ? AppSpacing.s32 : AppSpacing.s16,
              AppSpacing.s16,
              isWide ? AppSpacing.s32 : AppSpacing.s16,
              AppSpacing.s32,
            ),
            children: [
              // ========= Header: breadcrumb + greeting + date + bell =========
              _HomeHeader(
                userName: _shortGreetingName(user.fullName),
                dateStr: dateStr,
                isWide: isWide,
              ),
              const SizedBox(height: AppSpacing.s24),

              // ========= 3 hero gradient cards =========
              const _HeroRow(),
              const SizedBox(height: AppSpacing.s32),

              // ========= 2-column: Sắp diễn ra + Của tôi =========
              if (isWide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _UpcomingSection(onSwitchTab: onSwitchTab),
                      ),
                      const SizedBox(width: AppSpacing.s24),
                      Expanded(
                        flex: 4,
                        child: _MyStatsPanel(onSwitchTab: onSwitchTab),
                      ),
                    ],
                  ),
                )
              else ...[
                _UpcomingSection(onSwitchTab: onSwitchTab),
                const SizedBox(height: AppSpacing.s24),
                _MyStatsPanel(onSwitchTab: onSwitchTab),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============== Header ==============

class _HomeHeader extends StatelessWidget {
  final String userName;
  final String dateStr;
  final bool isWide;
  const _HomeHeader({
    required this.userName,
    required this.dateStr,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Trang chủ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textMuted,
                    letterSpacing: 0.4,
                  )),
              const SizedBox(height: AppSpacing.s4),
              Text('Chào, $userName 👋',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: isWide ? 24 : 20,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.6,
                    height: 1.1,
                  )),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        // Date chip
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
          decoration: BoxDecoration(
            color: context.cardBg,
            border: Border.all(color: context.cardBorder),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.calendar_today_outlined,
                size: 13, color: context.textMuted),
            const SizedBox(width: AppSpacing.s8),
            Text(dateStr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimary,
                )),
          ]),
        ),
        const SizedBox(width: AppSpacing.s8),
        const _NotificationButton(),
      ],
    );
  }
}

// ============== Notification button ==============

class _NotificationButton extends ConsumerWidget {
  const _NotificationButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(notificationsProvider);
    final unread = asyncData.maybeWhen(
      data: (d) => d['unread_count'] as int? ?? 0,
      orElse: () => 0,
    );
    final hint = unread > 0
        ? 'Mở thông báo, $unread chưa đọc'
        : 'Mở thông báo';
    return Semantics(
      label: hint,
      button: true,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen())),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
          decoration: BoxDecoration(
            color: context.cardBg,
            border: Border.all(color: context.cardBorder),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Stack(clipBehavior: Clip.none, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.notifications_outlined,
                  size: 14, color: context.textPrimary),
              const SizedBox(width: AppSpacing.s8),
              Text('Thông báo',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                  )),
            ]),
            if (unread > 0)
              Positioned(
                right: -4,
                top: -3,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ptitRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.cardBg, width: 1.5),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

// ============== 3 Hero gradient cards ==============

/// Palette 3 gradient theo mockup (red / blue / green-orange).
const _heroGradients = <List<Color>>[
  // Red: ptitRed → pink (HOT card)
  [Color(0xFFE63946), Color(0xFFFF6B7E)],
  // Blue: indigo → purple (Khoa cơ bản)
  [Color(0xFF4361EE), Color(0xFF7B2CBF)],
  // Green-orange: emerald → orange (Đa khoa)
  [Color(0xFF2A9D8F), Color(0xFFE76F51)],
];

const _heroLabels = <String>['CNTT · HOT', 'KHOA CƠ BẢN', 'ĐA KHOA'];

class _HeroRow extends ConsumerWidget {
  const _HeroRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(contestListProvider);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 900;

    return asyncList.when(
      loading: () => SizedBox(
        height: isCompact ? 180 : 200,
        child: Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 2 ? AppSpacing.s16 : 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data.items.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.s24),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border.all(color: context.cardBorder),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Center(
              child: Text('Chưa có cuộc thi nổi bật',
                  style: TextStyle(color: context.textMuted, fontSize: 13)),
            ),
          );
        }

        // Sort theo priority: REG_OPEN > ONGOING > PUBLISHED.
        // Sprint 20 fix (2026-05-09): loại FINISHED khỏi hero pool để
        // 3 card luôn highlight contests "đang nóng" — nếu data thiếu thì
        // fallback show ít card hơn 3 thay vì điền FINISHED cũ.
        final eligible =
            data.items.where((c) => c.status != 'FINISHED').toList();
        if (eligible.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.s24),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border.all(color: context.cardBorder),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Center(
              child: Text('Chưa có cuộc thi đang mở',
                  style: TextStyle(color: context.textMuted, fontSize: 13)),
            ),
          );
        }
        final sorted = [...eligible]
          ..sort((a, b) {
            int score(String s) => switch (s) {
                  'REG_OPEN' => 0,
                  'ONGOING' => 1,
                  'PUBLISHED' => 2,
                  _ => 9,
                };
            return score(a.status).compareTo(score(b.status));
          });
        final featured = sorted.take(3).toList();

        // Stack vertical khi compact, row horizontal khi wide.
        // Sprint 21 hotfix (2026-05-09): Column default crossAxisAlignment.center
        // khiến mỗi card width tự shrink theo content → render lệch trục.
        // Stretch để các card đều cùng full width.
        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(featured.length, (i) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: i < featured.length - 1 ? AppSpacing.s12 : 0),
                child: SizedBox(
                  height: 150,
                  child: _HeroCard(
                    contest: featured[i],
                    gradient: _heroGradients[i % _heroGradients.length],
                    tagLabel: _heroLabels[i % _heroLabels.length],
                  ),
                ),
              );
            }),
          );
        }
        return SizedBox(
          height: 195,
          child: Row(
            children: List.generate(featured.length, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: i < featured.length - 1 ? AppSpacing.s16 : 0),
                  child: _HeroCard(
                    contest: featured[i],
                    gradient: _heroGradients[i % _heroGradients.length],
                    tagLabel: _heroLabels[i % _heroLabels.length],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final ContestSummary contest;
  final List<Color> gradient;
  final String tagLabel;
  const _HeroCard({
    required this.contest,
    required this.gradient,
    required this.tagLabel,
  });

  String _statusSubtitle() {
    final now = DateTime.now();
    switch (contest.status) {
      case 'REG_OPEN':
        if (contest.registrationCloseAt != null) {
          final daysLeft =
              contest.registrationCloseAt!.difference(now).inDays;
          if (daysLeft >= 0) return 'Đăng ký mở · còn $daysLeft ngày';
        }
        return 'Đăng ký mở';
      case 'ONGOING':
        return 'Đang diễn ra';
      case 'PUBLISHED':
        final fmt = DateFormat('dd/MM');
        if (contest.registrationOpenAt != null) {
          return 'ĐK bắt đầu ${fmt.format(contest.registrationOpenAt!)}';
        }
        return 'Vòng loại ${fmt.format(contest.startAt)}';
      case 'REG_CLOSED':
        return 'Đã đóng đăng ký';
      case 'FINISHED':
        return 'Đã kết thúc';
      default:
        return contest.status;
    }
  }

  String _modeLabel() {
    return contest.participationMode == 'TEAM' ? 'nhóm' : 'thí sinh';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.push('/contests/${contest.slug}'),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.s20, AppSpacing.s16, AppSpacing.s20, AppSpacing.s16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 14,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tagLabel,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  )),
              const SizedBox(height: AppSpacing.s12),
              Text(contest.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.2,
                  )),
              const SizedBox(height: AppSpacing.s8),
              Text(_statusSubtitle(),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  )),
              const Spacer(),
              Text(
                  '${contest.entriesCount} ${_modeLabel()}'
                  '${contest.maxEntries != null ? " · tối đa ${contest.maxEntries}" : ""}',
                  style: GoogleFonts.jetBrainsMono(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ============== Sắp diễn ra section ==============

class _UpcomingSection extends ConsumerWidget {
  final ValueChanged<int>? onSwitchTab;
  const _UpcomingSection({this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(contestListProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(
          title: 'Sắp diễn ra',
          actionLabel: 'Xem tất cả →',
          onAction: () => onSwitchTab?.call(1),
        ),
        const SizedBox(height: AppSpacing.s12),
        asyncList.when(
          loading: () => Column(
            children: List.generate(
              4,
              (_) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    border: Border.all(color: context.cardBorder),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ),
          error: (_, __) => MCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Text('Không tải được lịch',
                  style: TextStyle(color: context.textMuted, fontSize: 12)),
            ),
          ),
          data: (data) {
            // Lấy contests sắp diễn ra: status REG_OPEN/PUBLISHED sort by startAt asc.
            final upcoming = [...data.items]
                .where((c) =>
                    c.status == 'REG_OPEN' ||
                    c.status == 'PUBLISHED' ||
                    c.status == 'REG_CLOSED' ||
                    c.status == 'ONGOING')
                .toList()
              ..sort((a, b) => a.startAt.compareTo(b.startAt));
            final list = upcoming.take(4).toList();
            if (list.isEmpty) {
              return MCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  child: Text('Chưa có sự kiện sắp diễn ra',
                      style:
                          TextStyle(color: context.textMuted, fontSize: 12)),
                ),
              );
            }
            return Column(
              children: list
                  .map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                        child: _UpcomingItem(contest: c),
                      ))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _UpcomingItem extends StatelessWidget {
  final ContestSummary contest;
  const _UpcomingItem({required this.contest});

  String _tagLabel() {
    // Suy ra tag từ participationMode + deliveryMode.
    if (contest.participationMode == 'TEAM') return 'Nhóm';
    return contest.deliveryMode == 'ONLINE'
        ? 'Online'
        : contest.deliveryMode == 'OFFLINE'
            ? 'Offline'
            : 'Hybrid';
  }

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('dd').format(contest.startAt);
    final monthShort = 'THG ${contest.startAt.month}';
    final timeStr = DateFormat('HH:mm').format(contest.startAt);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.push('/contests/${contest.slug}'),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border.all(color: context.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(children: [
          // Date pill
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s4, vertical: AppSpacing.s8),
            decoration: BoxDecoration(
              color: context.ptitRedSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(children: [
              Text(day,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ptitRed,
                    letterSpacing: -0.4,
                    height: 1,
                  )),
              const SizedBox(height: 2),
              Text(monthShort,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: ptitRed,
                    letterSpacing: 1,
                  )),
            ]),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contest.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                      letterSpacing: -0.2,
                    )),
                const SizedBox(height: 3),
                Text(
                    '${contest.deliveryMode == "ONLINE" ? "Online" : "Offline"} · $timeStr',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.textMuted,
                    )),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          // Tag pill
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8, vertical: 3),
            decoration: BoxDecoration(
              border: Border.all(color: context.cardBorder),
              borderRadius: BorderRadius.circular(AppRadius.tight),
            ),
            child: Text(_tagLabel(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.textMuted,
                  letterSpacing: 0.2,
                )),
          ),
        ]),
      ),
    );
  }
}

// ============== Của tôi stats panel ==============

class _MyStatsPanel extends ConsumerWidget {
  final ValueChanged<int>? onSwitchTab;
  const _MyStatsPanel({this.onSwitchTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEntries = ref.watch(myEntriesProvider);
    final asyncResults = ref.watch(myResultsProvider);

    final participating = asyncEntries.maybeWhen(
        data: (d) => d.length, orElse: () => 0);
    final results = asyncResults.maybeWhen(
        data: (r) => r, orElse: () => <MyResultModel>[]);

    final certCount =
        results.where((r) => (r.awardTitle ?? '').isNotEmpty).length;

    // Top rank: min rankNo trong results (loại null).
    MyResultModel? topRank;
    int? bestRank;
    for (final r in results) {
      if (r.rankNo == null) continue;
      if (bestRank == null || r.rankNo! < bestRank) {
        bestRank = r.rankNo;
        topRank = r;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHead(title: 'Của tôi'),
        const SizedBox(height: AppSpacing.s12),
        _MyStatCard(
          label: 'CUỘC THI ĐANG THAM GIA',
          value: '$participating',
          hint: participating > 0
              ? '$participating đăng ký active'
              : 'Đăng ký cuộc thi để bắt đầu',
          hintIcon: participating > 0 ? Icons.trending_up : null,
          onTap: () => onSwitchTab?.call(2),
        ),
        const SizedBox(height: AppSpacing.s12),
        _MyStatCard(
          label: 'XẾP HẠNG CAO NHẤT',
          value: bestRank != null ? '#$bestRank' : '—',
          hint: topRank != null
              ? topRank.contestTitle
              : 'Hoàn thành cuộc thi để có rank',
          onTap: () => onSwitchTab?.call(3),
        ),
        const SizedBox(height: AppSpacing.s12),
        _MyStatCard(
          label: 'CHỨNG NHẬN',
          value: '$certCount',
          hint: certCount > 0
              ? 'Sẵn sàng tải xuống'
              : 'Chưa có chứng nhận',
          onTap: () => onSwitchTab?.call(3),
        ),
      ],
    );
  }
}

class _MyStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String hint;
  final IconData? hintIcon;
  final VoidCallback? onTap;
  const _MyStatCard({
    required this.label,
    required this.value,
    required this.hint,
    this.hintIcon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: context.cardBg,
            border: Border.all(color: context.cardBorder),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: context.textMuted,
                    letterSpacing: 1.1,
                  )),
              const SizedBox(height: AppSpacing.s12),
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.9,
                    height: 1,
                  )),
              const SizedBox(height: AppSpacing.s8),
              Row(children: [
                if (hintIcon != null) ...[
                  Icon(hintIcon, size: 12, color: ptitRed),
                  const SizedBox(width: AppSpacing.s4),
                ],
                Expanded(
                  child: Text(hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted,
                      )),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ============== Section head ==============

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
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8, vertical: 0),
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
