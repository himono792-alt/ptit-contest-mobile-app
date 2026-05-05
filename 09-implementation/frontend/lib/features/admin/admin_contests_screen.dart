import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/contest.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';

final adminContestsParamsProvider = StateProvider<_AdminContestsParams>(
  (ref) => const _AdminContestsParams(),
);

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
  return ContestListResponse.fromJson(res.data);
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: cardBorder)),
          ),
          child: Row(children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quản lý',
                      style: TextStyle(color: textMuted, fontSize: 11)),
                  SizedBox(height: 2),
                  Text('Cuộc thi',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                ],
              ),
            ),
            if (user.isOrganizer || user.isAdmin)
              FilledButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tạo cuộc thi — Phase F7')),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tạo cuộc thi'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(140, 38),
                    backgroundColor: ptitRed),
              ),
          ]),
        ),
        // Toolbar (search + filter)
        Container(
          padding: const EdgeInsets.fromLTRB(32, 18, 32, 0),
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
              icon: const Icon(Icons.refresh, color: textMuted),
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
              padding: const EdgeInsets.all(24),
              child: data.items.isEmpty
                  ? const Center(
                      child: Text('Không có cuộc thi nào',
                          style: TextStyle(color: textMuted)))
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
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          border: Border(bottom: BorderSide(color: cardBorder)),
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
        ]),
      ),
      // Rows
      ...items.map((c) => _ContestRow(c: c)).toList(),
      // Footer
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: cardBorder)),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        alignment: Alignment.centerLeft,
        child: Text('Tổng: $total cuộc thi',
            style: const TextStyle(color: textMuted, fontSize: 12)),
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
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textMuted,
            letterSpacing: 0.5),
      );
}

class _ContestRow extends StatelessWidget {
  final ContestSummary c;
  const _ContestRow({required this.c});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy');
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chi tiết: ${c.slug} — Phase F7')),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: cardBorder)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          SizedBox(
              width: 50,
              child: Text('#${c.contestId}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      fontWeight: FontWeight.w500))),
          Expanded(
            flex: 4,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.title,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(c.slug,
                  style: const TextStyle(fontSize: 11, color: textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          Expanded(flex: 2, child: Pill.status(c.status)),
          Expanded(
            flex: 2,
            child: Text('${fmt.format(c.startAt)} → ${fmt.format(c.endAt)}',
                style: const TextStyle(fontSize: 12, color: textMuted)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${c.deliveryMode} · ${c.participationMode == "TEAM" ? "Đội" : "Cá nhân"}',
              style: const TextStyle(fontSize: 12, color: textMuted),
              maxLines: 1, overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: Text(
              c.maxEntries != null ? 'max ${c.maxEntries}' : '—',
              style: const TextStyle(fontSize: 12, color: textMuted),
            ),
          ),
        ]),
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
              style: const TextStyle(color: textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ]),
      ),
    );
  }
}
