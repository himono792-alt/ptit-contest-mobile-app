import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/models/contest.dart';
import '../../core/theme.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/help_button.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';
import 'notifications_screen.dart';

class _ListParams {
  final String? q;
  final String? status;
  const _ListParams({this.q, this.status});
}

final contestListParamsProvider = StateProvider<_ListParams>((_) => const _ListParams());

// Sprint 2 fix C1 (2026-05-06): sort theo status priority để REG_OPEN/ONGOING
// luôn xuất hiện trước. Đợt 1 audit phát hiện Olympic 2026 (REG_OPEN) chìm xuống
// vị trí #3 sau 2 contest FINISHED — vi phạm hierarchy "active priority".
const _statusOrder = {
  'REG_OPEN': 0,
  'ONGOING': 1,
  'PUBLISHED': 2,
  'REG_CLOSED': 3,
  'FINISHED': 4,
  'CANCELLED': 5,
};

final contestListProvider = FutureProvider.autoDispose<ContestListResponse>((ref) async {
  final params = ref.watch(contestListParamsProvider);
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests', queryParameters: {
    'size': 50,
    if (params.q != null && params.q!.isNotEmpty) 'q': params.q,
    if (params.status != null) 'status': params.status,
  });
  final response = ContestListResponse.fromJson(res.data);
  // Sort: status priority asc, tie-break startAt desc (newest first)
  final sortedItems = List<ContestSummary>.from(response.items)
    ..sort((a, b) {
      final orderA = _statusOrder[a.status] ?? 99;
      final orderB = _statusOrder[b.status] ?? 99;
      if (orderA != orderB) return orderA.compareTo(orderB);
      return b.startAt.compareTo(a.startAt);
    });
  return ContestListResponse(
    items: sortedItems,
    total: response.total,
    page: response.page,
    size: response.size,
  );
});

class ContestListScreen extends ConsumerStatefulWidget {
  const ContestListScreen({super.key});
  @override
  ConsumerState<ContestListScreen> createState() => _ContestListScreenState();
}

class _ContestListScreenState extends ConsumerState<ContestListScreen> {
  final _searchCtrl = TextEditingController();
  bool _showFilters = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applySearch(String v) {
    final cur = ref.read(contestListParamsProvider);
    ref.read(contestListParamsProvider.notifier).state =
        _ListParams(q: v.isEmpty ? null : v.trim(), status: cur.status);
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(contestListProvider);
    final params = ref.watch(contestListParamsProvider);
    final hasFilter = (params.q ?? '').isNotEmpty || params.status != null;

    return Scaffold(
      appBar: MTopBar(title: 'Cuộc thi', actions: [
        const HelpButton(id: 'sv_contest_list'),
        IconButton(
          tooltip: 'Bộ lọc',
          icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: hasFilter ? ptitRed : context.textMuted),
          onPressed: () => setState(() => _showFilters = !_showFilters),
        ),
        NotificationBadge(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => const NotificationsScreen())),
        ),
        const SizedBox(width: 4),
      ]),
      body: Column(children: [
        // Search bar (always visible)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: SizedBox(
            height: 42,
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Đóng',
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applySearch('');
                          setState(() {});
                        },
                      ),
                hintText: 'Tìm theo tên cuộc thi...',
                isDense: true,
                fillColor: context.cardBg,
                filled: true,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: _applySearch,
            ),
          ),
        ),
        // Status filter chips (toggle)
        if (_showFilters)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _StatusChip(label: 'Tất cả', value: null, current: params.status),
                _StatusChip(label: 'Mở ĐK', value: 'REG_OPEN', current: params.status),
                _StatusChip(label: 'Đã công bố', value: 'PUBLISHED', current: params.status),
                _StatusChip(label: 'Đang diễn ra', value: 'ONGOING', current: params.status),
                _StatusChip(label: 'Kết thúc', value: 'FINISHED', current: params.status),
              ]),
            ),
          ),
        // List
        Expanded(
          child: asyncList.when(
            // Phase 2 step 5: skeleton thay spinner
            loading: () => const MCardListSkeleton(count: 4, textLines: 2),
            error: (e, _) => _ErrorView(error: e, onRetry: () => ref.invalidate(contestListProvider)),
            data: (data) => RefreshIndicator(
              color: ptitRed,
              onRefresh: () async => ref.invalidate(contestListProvider),
              child: data.items.isEmpty
                  // Sprint 18 (2026-05-08) S18-3: dùng EmptyView global enhanced
                  // (icon 72 + bg circle + heading bold) thay private text-only.
                  ? ListView(children: const [
                      SizedBox(height: 80),
                      EmptyView(
                        icon: Icons.emoji_events_outlined,
                        title: 'Chưa có cuộc thi nào',
                        subtitle:
                            'Hãy quay lại sau khi BTC mở thêm cuộc thi mới.',
                      ),
                    ])
                  // Redesign 2026-06-20: stat strip + gom nhóm trạng thái.
                  : Builder(builder: (_) {
                      final groups = <String, List<ContestSummary>>{};
                      for (final c in data.items) {
                        groups
                            .putIfAbsent(_svCategory(c.status), () => [])
                            .add(c);
                      }
                      final cats = _svCategoryOrder
                          .where(groups.containsKey)
                          .toList();
                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _SvContestStatStrip(items: data.items),
                          const SizedBox(height: 12),
                          for (final cat in cats) ...[
                            _SvGroupHeader(
                              label: cat,
                              count: groups[cat]!.length,
                              color: _svCategoryColor(context, cat),
                            ),
                            for (final c in groups[cat]!)
                              _ContestCard(contest: c),
                          ],
                        ],
                      );
                    }),
            ),
          ),
        ),
      ]),
    );
  }
}

class _StatusChip extends ConsumerWidget {
  final String label;
  final String? value;
  final String? current;
  const _StatusChip({required this.label, required this.value, required this.current});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = value == current;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: FilterChip(
        label: Text(label, style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: selected ? Colors.white : context.textPrimary,
        )),
        selected: selected,
        onSelected: (_) {
          final cur = ref.read(contestListParamsProvider);
          ref.read(contestListParamsProvider.notifier).state =
              _ListParams(q: cur.q, status: value);
        },
        selectedColor: ptitRed,
        backgroundColor: context.cardBg,
        side: BorderSide(color: selected ? ptitRed : context.cardBorder),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

// Sprint 18 (2026-05-08): private _EmptyView removed — replaced bằng global
// EmptyView widget với enhanced illustration (S18-3).

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final msg = FriendlyError.of(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: ptitRed),
          const SizedBox(height: 12),
          Text(msg, textAlign: TextAlign.center, style: TextStyle(color: context.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ]),
      ),
    );
  }
}

// Redesign 2026-06-20: nhóm trạng thái + stat strip cho SV.
const _svCategoryOrder = [
  'Đang mở đăng ký',
  'Đang diễn ra',
  'Sắp diễn ra',
  'Đã kết thúc',
  'Khác',
];

String _svCategory(String s) {
  switch (s) {
    case 'REG_OPEN':
      return 'Đang mở đăng ký';
    case 'ONGOING':
    case 'REG_CLOSED':
      return 'Đang diễn ra';
    case 'PUBLISHED':
      return 'Sắp diễn ra';
    case 'FINISHED':
    case 'CANCELLED':
      return 'Đã kết thúc';
    default:
      return 'Khác';
  }
}

Color _svCategoryColor(BuildContext context, String cat) {
  switch (cat) {
    case 'Đang mở đăng ký':
      return context.successGreen;
    case 'Đang diễn ra':
      return context.warnOrange;
    case 'Sắp diễn ra':
      return context.infoBlue;
    default:
      return context.textMuted;
  }
}

class _SvContestStatStrip extends StatelessWidget {
  final List<ContestSummary> items;
  const _SvContestStatStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    int byCat(String c) =>
        items.where((e) => _svCategory(e.status) == c).length;
    return Row(children: [
      Expanded(
        child: _SvStat(
          value: '${items.length}',
          label: 'Tổng cuộc thi',
          color: ptitRed,
          icon: Icons.emoji_events_outlined,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _SvStat(
          value: '${byCat('Đang mở đăng ký')}',
          label: 'Đang mở ĐK',
          color: context.successGreen,
          icon: Icons.how_to_reg_outlined,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _SvStat(
          value: '${byCat('Đang diễn ra')}',
          label: 'Đang diễn ra',
          color: context.warnOrange,
          icon: Icons.play_circle_outline,
        ),
      ),
    ]);
  }
}

class _SvStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _SvStat(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  color: context.textPrimary)),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: context.textMuted)),
        ],
      ),
    );
  }
}

class _SvGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SvGroupHeader(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: context.cardBorder.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.tight),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: context.textMuted)),
        ),
      ]),
    );
  }
}

class _ContestCard extends StatelessWidget {
  final ContestSummary contest;
  const _ContestCard({required this.contest});

  /// Gradient stripe theo status — visual marker để scan list nhanh.
  LinearGradient _stripeFor(BuildContext context, String status) {
    switch (status) {
      case 'REG_OPEN':
      case 'PUBLISHED':
        return const LinearGradient(colors: ptitGradientHeroColors);
      case 'ONGOING':
        return LinearGradient(colors: [context.warnOrange, const Color(0xFFFBBF24)]);
      case 'FINISHED':
        return LinearGradient(colors: [context.infoBlue, const Color(0xFF60A5FA)]);
      case 'CANCELLED':
        return const LinearGradient(
            colors: [Color(0xFF94A3B8), Color(0xFFCBD5E1)]);
      default:
        return const LinearGradient(
            colors: [Color(0xFFE5E0D8), Color(0xFFF1ECE5)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    // Sprint 3 a11y (2026-05-07): wrap card bằng Semantics để screen reader
    // đọc "title cuộc thi, status". Hint: nhấn để xem chi tiết.
    final statusLabel = switch (contest.status) {
      'REG_OPEN' => 'đang mở đăng ký',
      'ONGOING' => 'đang diễn ra',
      'PUBLISHED' => 'đã công bố',
      'REG_CLOSED' => 'đã đóng đăng ký',
      'FINISHED' => 'đã kết thúc',
      'CANCELLED' => 'đã hủy',
      _ => contest.status,
    };
    return Semantics(
      label: '${contest.title}, $statusLabel',
      button: true,
      hint: 'Nhấn để xem chi tiết cuộc thi',
      child: MCard(
      onTap: () => context.push('/contests/${contest.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient stripe theo status
          Container(
            height: 6,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: _stripeFor(context, contest.status),
              borderRadius: BorderRadius.circular(AppRadius.tight),
            ),
          ),
          Row(children: [
            Expanded(
              child: Text(contest.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: context.textPrimary,
                      letterSpacing: -0.2,
                      height: 1.3)),
            ),
            const SizedBox(width: 8),
            Pill.status(contest.status),
          ]),
          const SizedBox(height: 8),
          // Meta row 1: faculty · participation · mode
          Wrap(spacing: 8, runSpacing: 6, children: [
            _MetaChip(label: _facultyLabel(contest), icon: Icons.school_outlined),
            _MetaChip(
                label: contest.participationMode == "TEAM" ? 'Đội' : 'Cá nhân',
                icon: contest.participationMode == "TEAM"
                    ? Icons.groups_outlined
                    : Icons.person_outline),
            _MetaChip(
                label: _modeLabel(contest.deliveryMode),
                icon: contest.deliveryMode == 'ONLINE'
                    ? Icons.cloud_outlined
                    : (contest.deliveryMode == 'OFFLINE'
                        ? Icons.location_on_outlined
                        : Icons.sync_alt)),
          ]),
          const SizedBox(height: 10),
          // Footer: date + max entries
          Row(children: [
            Icon(Icons.calendar_today_outlined, size: 13, color: context.textFaint),
            const SizedBox(width: 4),
            Text('${fmt.format(contest.startAt)} – ${fmt.format(contest.endAt)}',
                style: TextStyle(
                    fontSize: 11,
                    color: context.textMuted,
                    fontWeight: FontWeight.w600)),
            if (contest.maxEntries != null) ...[
              const SizedBox(width: 14),
              Icon(Icons.people_outline, size: 13, color: context.textFaint),
              const SizedBox(width: 4),
              Text('max ${contest.maxEntries}',
                  style: TextStyle(
                      fontSize: 11,
                      color: context.textMuted,
                      fontWeight: FontWeight.w600)),
            ],
          ]),
        ],
      ),
    ),
    );
  }

  String _facultyLabel(ContestSummary c) =>
      c.hostFacultyId != null ? 'Khoa #${c.hostFacultyId}' : 'PTIT';

  String _modeLabel(String m) =>
      m == 'ONLINE' ? 'Online' : (m == 'OFFLINE' ? 'Offline' : 'Hybrid');
}

/// Inline pill nhỏ với icon + label, dùng làm meta tag trong card.
///
/// Sprint 2 fix C2 (2026-05-06): bg dùng theme-aware Theme.colorScheme.surfaceVariant
/// thay vì hardcoded `Color(0xFFF7F2EC)` cream. Lý do: trong dark mode, text dùng
/// `context.textPrimary` (light color) trên bg cream cứng → contrast quá thấp,
/// label gần như invisible (audit đợt 1 C2 misdiagnosed thành "schema thiếu fields").
class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        // Theme-aware bg: light mode → cream-ish, dark mode → dark-soft
        color: Theme.of(context).brightness == Brightness.dark
            ? context.cardBorder.withValues(alpha: 0.5)
            : const Color(0xFFF7F2EC),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: context.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10.5, color: context.textPrimary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
