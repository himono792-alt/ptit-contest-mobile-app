import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/contest.dart';
import '../../core/theme.dart';
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

final contestListProvider = FutureProvider.autoDispose<ContestListResponse>((ref) async {
  final params = ref.watch(contestListParamsProvider);
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests', queryParameters: {
    'size': 50,
    if (params.q != null && params.q!.isNotEmpty) 'q': params.q,
    if (params.status != null) 'status': params.status,
  });
  return ContestListResponse.fromJson(res.data);
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
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          _applySearch('');
                          setState(() {});
                        },
                      ),
                hintText: 'Tìm theo tên cuộc thi...',
                isDense: true,
                fillColor: Colors.white,
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
                  ? const _EmptyView()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: data.items.length,
                      itemBuilder: (_, i) => _ContestCard(contest: data.items[i]),
                    ),
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
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? ptitRed : context.cardBorder),
        showCheckmark: false,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(padding: EdgeInsets.all(32),
            child: Text('Chưa có cuộc thi nào', style: TextStyle(color: context.textMuted))),
      );
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    final msg = error is DioException
        ? ((error as DioException).response?.data is Map
            ? '${(error as DioException).response?.data['detail']}'
            : (error as DioException).message ?? '')
        : '$error';
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

class _ContestCard extends StatelessWidget {
  final ContestSummary contest;
  const _ContestCard({required this.contest});

  /// Gradient stripe theo status — visual marker để scan list nhanh.
  LinearGradient _stripeFor(String status) {
    switch (status) {
      case 'REG_OPEN':
      case 'PUBLISHED':
        return const LinearGradient(colors: [ptitRed, Color(0xFFFF6B7E)]);
      case 'ONGOING':
        return LinearGradient(colors: [context.warnOrange, Color(0xFFFBBF24)]);
      case 'FINISHED':
        return LinearGradient(colors: [context.infoBlue, Color(0xFF60A5FA)]);
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
    return MCard(
      onTap: () => context.push('/contests/${contest.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient stripe theo status
          Container(
            height: 6,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: _stripeFor(contest.status),
              borderRadius: BorderRadius.circular(3),
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
    );
  }

  String _facultyLabel(ContestSummary c) =>
      c.hostFacultyId != null ? 'Khoa #${c.hostFacultyId}' : 'PTIT';

  String _modeLabel(String m) =>
      m == 'ONLINE' ? 'Online' : (m == 'OFFLINE' ? 'Offline' : 'Hybrid');
}

/// Inline pill nhỏ với icon + label, dùng làm meta tag trong card.
class _MetaChip extends StatelessWidget {
  final String label;
  final IconData icon;
  const _MetaChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2EC),
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
