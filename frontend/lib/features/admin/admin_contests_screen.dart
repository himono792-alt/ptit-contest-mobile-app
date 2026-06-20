import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/models/contest.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/help_button.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';
import 'create_contest_dialog.dart';

final adminContestsParamsProvider = StateProvider<_AdminContestsParams>(
  (ref) => const _AdminContestsParams(),
);

// Sprint 4 fix M9 (2026-05-07): admin cuộc thi sort theo status priority
// thay vì ID arbitrary. Match pattern Sprint 2 C1 (Contest List SV).
const _adminStatusOrder = {
  'REG_OPEN': 0,
  'ONGOING': 1,
  'PUBLISHED': 2,
  'REG_CLOSED': 3,
  'PROPOSED': 4,
  'DRAFT': 5,
  'REVISION_REQUESTED': 6,
  'FINISHED': 7,
  'CANCELLED': 8,
};

final adminContestsProvider =
    FutureProvider.autoDispose<ContestListResponse>((ref) async {
  final params = ref.watch(adminContestsParamsProvider);
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests', queryParameters: {
    'show_all': true,
    'size': 100,
    if (params.q != null && params.q!.isNotEmpty) 'q': params.q,
    if (params.status != null) 'status': params.status,
  });
  final response = ContestListResponse.fromJson(res.data);
  // Sort: status priority asc, tie-break startAt desc (newest first)
  final sortedItems = List<ContestSummary>.from(response.items)
    ..sort((a, b) {
      final orderA = _adminStatusOrder[a.status] ?? 99;
      final orderB = _adminStatusOrder[b.status] ?? 99;
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

class AdminContestsScreen extends ConsumerStatefulWidget {
  const AdminContestsScreen({super.key});
  @override
  ConsumerState<AdminContestsScreen> createState() =>
      _AdminContestsScreenState();
}

class _AdminContestsScreenState extends ConsumerState<AdminContestsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value!;
    final asyncList = ref.watch(adminContestsProvider);
    final params = ref.watch(adminContestsParamsProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: context.appBg,
      body: Column(children: [
        // Top bar
        if (!isMobile) Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            color: context.cardBg,
            border: Border(bottom: BorderSide(color: context.cardBorder)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quản lý',
                      style: TextStyle(color: context.textMuted, fontSize: 11)),
                  SizedBox(height: 2),
                  Text('Cuộc thi',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                ],
              ),
            ),
            const HelpButton(id: 'gv_contests'),
            const SizedBox(width: 4),
            if (user.isOrganizer || user.isAdmin)
              Semantics(
                label: 'Tạo cuộc thi mới',
                button: true,
                hint: 'Mở dialog điền thông tin contest mới',
                child: FilledButton.icon(
                  onPressed: () async {
                    final created = await showCreateContestDialog(context);
                    if (created == true) {
                      ref.invalidate(adminContestsProvider);
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tạo cuộc thi'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(140, 38),
                      backgroundColor: ptitRed),
                ),
              ),
          ]),
        ),
        // Toolbar (search + filter)
        Container(
          padding: EdgeInsets.fromLTRB(isMobile ? 14 : 32, isMobile ? 12 : 18, isMobile ? 14 : 32, 0),
          child: Row(children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo tên cuộc thi...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                  onSubmitted: (v) => ref
                      .read(adminContestsParamsProvider.notifier)
                      .state = params.copyWith(q: v),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('Trạng thái',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.textMuted,
                )),
            const SizedBox(width: 8),
            SizedBox(
              width: 180,
              height: 40,
              child: DropdownButtonFormField<String?>(
                initialValue: params.status,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(value: 'DRAFT', child: Text('DRAFT')),
                  DropdownMenuItem(value: 'PROPOSED', child: Text('PROPOSED')),
                  DropdownMenuItem(
                      value: 'REVISION_REQUESTED',
                      child: Text('REVISION_REQUESTED')),
                  DropdownMenuItem(value: 'PUBLISHED', child: Text('PUBLISHED')),
                  DropdownMenuItem(value: 'REG_OPEN', child: Text('REG_OPEN')),
                  DropdownMenuItem(value: 'REG_CLOSED', child: Text('REG_CLOSED')),
                  DropdownMenuItem(value: 'ONGOING', child: Text('ONGOING')),
                  DropdownMenuItem(value: 'FINISHED', child: Text('FINISHED')),
                  DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
                ],
                onChanged: (v) => ref
                    .read(adminContestsParamsProvider.notifier)
                    .state = params.copyWith(status: v, clearStatus: v == null),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: context.textMuted),
              onPressed: () => ref.invalidate(adminContestsProvider),
            ),
          ]),
        ),
        // Body
        Expanded(
          child: asyncList.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => _ErrorView(
                error: e,
                onRetry: () => ref.invalidate(adminContestsProvider)),
            data: (data) => data.items.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(isMobile ? 14 : 24),
                    child: EmptyView(
                      icon: Icons.emoji_events_outlined,
                      title: 'Chưa có cuộc thi nào',
                      subtitle:
                          'Tạo cuộc thi đầu tiên để bắt đầu workflow phê duyệt.',
                      action: FilledButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo cuộc thi'),
                        onPressed: () async {
                          final created =
                              await showCreateContestDialog(context);
                          if (created == true) {
                            ref.invalidate(adminContestsProvider);
                          }
                        },
                      ),
                    ),
                  )
                // Redesign 2026-06-20: stat strip + bảng gom nhóm trạng thái.
                : ListView(
                    padding: EdgeInsets.all(isMobile ? 14 : 24),
                    children: [
                      _ContestStatStrip(items: data.items),
                      const SizedBox(height: 16),
                      MCard(
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        child: _ContestsTable(
                            items: data.items, total: data.total),
                      ),
                    ],
                  ),
          ),
        ),
      ]),
    );
  }
}

class _AdminContestsParams {
  final String? q;
  final String? status;
  const _AdminContestsParams({this.q, this.status});

  _AdminContestsParams copyWith({String? q, String? status, bool clearStatus = false}) =>
      _AdminContestsParams(
        q: q ?? this.q,
        status: clearStatus ? null : (status ?? this.status),
      );
}

// Redesign 2026-06-20: nhóm trạng thái + màu category cho accent/strip.
const _statusCategoryOrder = [
  'Đang diễn ra',
  'Chờ duyệt',
  'Bản nháp',
  'Đã công bố',
  'Đã kết thúc',
  'Khác',
];

String _statusCategory(String s) {
  switch (s) {
    case 'REG_OPEN':
    case 'ONGOING':
    case 'REG_CLOSED':
      return 'Đang diễn ra';
    case 'PROPOSED':
    case 'REVISION_REQUESTED':
      return 'Chờ duyệt';
    case 'DRAFT':
      return 'Bản nháp';
    case 'PUBLISHED':
      return 'Đã công bố';
    case 'FINISHED':
    case 'CANCELLED':
      return 'Đã kết thúc';
    default:
      return 'Khác';
  }
}

Color _categoryColor(BuildContext context, String cat) {
  switch (cat) {
    case 'Đang diễn ra':
      return context.successGreen;
    case 'Chờ duyệt':
      return context.warnOrange;
    case 'Đã công bố':
      return context.infoBlue;
    case 'Bản nháp':
      return ptitRed;
    default:
      return context.textMuted;
  }
}

class _ContestStatStrip extends StatelessWidget {
  final List<ContestSummary> items;
  const _ContestStatStrip({required this.items});

  @override
  Widget build(BuildContext context) {
    int byCat(String cat) =>
        items.where((c) => _statusCategory(c.status) == cat).length;
    return Row(children: [
      Expanded(
        child: _ContestStat(
          value: '${items.length}',
          label: 'Tổng cuộc thi',
          color: ptitRed,
          icon: Icons.emoji_events_outlined,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ContestStat(
          value: '${byCat('Đang diễn ra')}',
          label: 'Đang diễn ra',
          color: context.successGreen,
          icon: Icons.play_circle_outline,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ContestStat(
          value: '${byCat('Chờ duyệt')}',
          label: 'Chờ duyệt',
          color: context.warnOrange,
          icon: Icons.hourglass_empty_outlined,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ContestStat(
          value: '${byCat('Bản nháp')}',
          label: 'Bản nháp',
          color: context.textMuted,
          icon: Icons.edit_note_outlined,
        ),
      ),
    ]);
  }
}

class _ContestStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _ContestStat(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
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
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.textMuted)),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ContestsTable extends StatelessWidget {
  final List<ContestSummary> items;
  final int total;
  const _ContestsTable({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    // Gom nhóm theo category (items đã sort theo status priority).
    final groups = <String, List<ContestSummary>>{};
    for (final c in items) {
      groups.putIfAbsent(_statusCategory(c.status), () => []).add(c);
    }
    final cats = _statusCategoryOrder.where(groups.containsKey).toList();

    return Column(children: [
      // Header cột.
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: context.appBg,
          border: Border(bottom: BorderSide(color: context.cardBorder)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(children: const [
          SizedBox(width: 54, child: _Th('ID')),
          Expanded(flex: 4, child: _Th('Tên cuộc thi')),
          Expanded(flex: 2, child: _Th('Trạng thái')),
          Expanded(flex: 2, child: _Th('Thời gian')),
          Expanded(flex: 2, child: _Th('Hình thức')),
          SizedBox(width: 80, child: _Th('Số entry')),
          SizedBox(width: 60, child: _Th('')),
        ]),
      ),
      // Nhóm + rows.
      for (final cat in cats) ...[
        _GroupBand(
            label: cat,
            count: groups[cat]!.length,
            color: _categoryColor(context, cat)),
        ...groups[cat]!.map((c) => _ContestRow(c: c)),
      ],
      // Footer.
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.cardBorder)),
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        alignment: Alignment.centerLeft,
        child: Text('Tổng: $total cuộc thi',
            style: TextStyle(color: context.textMuted, fontSize: 12)),
      ),
    ]);
  }
}

/// Dải tiêu đề nhóm trạng thái xen giữa các hàng bảng.
class _GroupBand extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _GroupBand(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        border: Border(bottom: BorderSide(color: context.cardBorder)),
      ),
      child: Row(children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.3)),
        const SizedBox(width: 8),
        Text('$count',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.textMuted)),
      ]),
    );
  }
}

class _Th extends StatelessWidget {
  final String label;
  const _Th(this.label);
  @override
  Widget build(BuildContext context) => Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: context.textMuted,
            letterSpacing: 0.5),
      );
}

class _ContestRow extends ConsumerStatefulWidget {
  final ContestSummary c;
  const _ContestRow({required this.c});
  @override
  ConsumerState<_ContestRow> createState() => _ContestRowState();
}

class _ContestRowState extends ConsumerState<_ContestRow> {
  bool _busy = false;

  Future<void> _submitForApproval() async {
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/contests/${widget.c.contestId}/submit-for-approval', data: {
        'note': 'Submit từ admin contests list.',
      });
      if (!mounted) return;
      AppToast.success(context, 'Đã submit #${widget.c.contestId} cho BCN duyệt — chờ BCN phê duyệt QĐ1.');
      ref.invalidate(adminContestsProvider);
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final fmt = DateFormat('dd/MM/yy');
    final canSubmit = c.status == 'DRAFT' || c.status == 'REVISION_REQUESTED';
    final accent = _categoryColor(context, _statusCategory(c.status));
    return Semantics(
      label: '${c.title}, ${c.status}, ${c.entriesCount} đăng ký',
      button: true,
      hint: 'Mở trang quản lý chi tiết cuộc thi #${c.contestId}',
      child: InkWell(
      excludeFromSemantics: true,
      onTap: () => context.push('/admin/contests/${c.contestId}/manage'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(13, 12, 16, 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.cardBorder),
            left: BorderSide(color: accent, width: 3),
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
              width: 50,
              child: Text('#${c.contestId}',
                  style: TextStyle(
                      fontSize: 12,
                      color: context.textMuted,
                      fontWeight: FontWeight.w500))),
          Expanded(
            flex: 4,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.title,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(c.slug,
                  style: TextStyle(fontSize: 11, color: context.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Expanded(flex: 2, child: Pill.status(c.status)),
          Expanded(
            flex: 2,
            child: Text('${fmt.format(c.startAt)} → ${fmt.format(c.endAt)}',
                style: TextStyle(fontSize: 12, color: context.textMuted)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${c.deliveryMode} · ${c.participationMode == "TEAM" ? "Đội" : "Cá nhân"}',
              style: TextStyle(fontSize: 12, color: context.textMuted),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              // Sprint 4 fix M10 (2026-05-07): format "X/max" thay vì "max N".
              // Admin/BCN cần thấy actual count đã đăng ký, không phải chỉ max setting.
              // Nếu max_entries null = unlimited, chỉ hiện count. Nếu count = 0 + max
              // unlimited → "—".
              c.maxEntries != null
                  ? '${c.entriesCount}/${c.maxEntries}'
                  : (c.entriesCount > 0 ? '${c.entriesCount}' : '—'),
              style: TextStyle(fontSize: 12, color: context.textMuted),
            ),
          ),
          // Action: Submit cho BCN duyệt (chỉ nếu DRAFT/REVISION_REQUESTED)
          SizedBox(
            width: 60,
            child: canSubmit
                ? (_busy
                    ? const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: ptitRed)),
                      )
                    : IconButton(
                        tooltip: 'Submit cho BCN duyệt',
                        iconSize: 18,
                        visualDensity: VisualDensity.compact, constraints: const BoxConstraints(minWidth: 44, minHeight: 44), // P0 #4 hit area ≥44 (WCAG 2.5.5)
                        icon: const Icon(Icons.send, color: ptitRed),
                        onPressed: _submitForApproval,
                      ))
                : const SizedBox.shrink(),
          ),
        ]),
      ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: ptitRed),
          const SizedBox(height: 12),
          Text(FriendlyError.of(error),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ]),
      ),
    );
  }
}
