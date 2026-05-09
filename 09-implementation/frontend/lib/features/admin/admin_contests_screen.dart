import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/contest.dart';
import '../../core/theme.dart';
import '../../core/widgets/empty_view.dart';
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
            SizedBox(
              width: 220,
              height: 40,
              child: DropdownButtonFormField<String?>(
                value: params.status,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Trạng thái',
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
            data: (data) => Padding(
              padding: EdgeInsets.all(isMobile ? 14 : 24),
              child: data.items.isEmpty
                  ? const EmptyView(
                      icon: Icons.emoji_events_outlined,
                      title: 'Chưa có cuộc thi nào',
                      subtitle: 'Tạo cuộc thi đầu tiên để bắt đầu workflow phê duyệt.',
                    )
                  : MCard(
                      padding: EdgeInsets.zero,
                      margin: EdgeInsets.zero,
                      child: _ContestsTable(items: data.items, total: data.total),
                    ),
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

class _ContestsTable extends StatelessWidget {
  final List<ContestSummary> items;
  final int total;
  const _ContestsTable({required this.items, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: Color(0xFFF9FAFB),
          border: Border(bottom: BorderSide(color: context.cardBorder)),
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(children: const [
          SizedBox(width: 50, child: _Th('ID')),
          Expanded(flex: 4, child: _Th('Tên cuộc thi')),
          Expanded(flex: 2, child: _Th('Trạng thái')),
          Expanded(flex: 2, child: _Th('Thời gian')),
          Expanded(flex: 2, child: _Th('Hình thức')),
          SizedBox(width: 80, child: _Th('Số entry')),
          SizedBox(width: 60, child: _Th('')),
        ]),
      ),
      // Rows
      ...items.map((c) => _ContestRow(c: c)),
      // Footer
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.cardBorder)),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        alignment: Alignment.centerLeft,
        child: Text('Tổng: $total cuộc thi',
            style: TextStyle(color: context.textMuted, fontSize: 12)),
      ),
    ]);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã submit #${widget.c.contestId} cho BCN duyệt')),
      );
      ref.invalidate(adminContestsProvider);
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
          : '$e';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.c;
    final fmt = DateFormat('dd/MM/yy');
    final canSubmit = c.status == 'DRAFT' || c.status == 'REVISION_REQUESTED';
    return Semantics(
      label: '${c.title}, ${c.status}, ${c.entriesCount} đăng ký',
      button: true,
      hint: 'Mở trang quản lý chi tiết cuộc thi #${c.contestId}',
      child: InkWell(
      excludeFromSemantics: true,
      onTap: () => context.push('/admin/contests/${c.contestId}/manage'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.cardBorder)),
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
          Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ]),
      ),
    );
  }
}
