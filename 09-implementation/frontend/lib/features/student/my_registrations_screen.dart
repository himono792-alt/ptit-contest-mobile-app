// SV-10 — "Của tôi" tab: list entries SV đã đăng ký + status entry + action.
//
// Dùng GET /me/entries (mới ở backend) trả các entry kèm contest info.
// Action:
//   - PENDING/APPROVED + contest REG_OPEN → nút Hủy đăng ký
//   - APPROVED + contest ONGOING (requires_submission) → nút Nộp bài
//   - Contest FINISHED → tap tới Kết quả

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';

final myEntriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/me/entries');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class MyRegistrationsScreen extends ConsumerStatefulWidget {
  const MyRegistrationsScreen({super.key});
  @override
  ConsumerState<MyRegistrationsScreen> createState() =>
      _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends ConsumerState<MyRegistrationsScreen> {
  String _filter = 'Tất cả';

  bool _matchesFilter(Map<String, dynamic> e) {
    if (_filter == 'Tất cả') return true;
    final cs = (e['contest_status'] as String?) ?? '';
    if (_filter == 'Đang dự thi') {
      return ['REG_OPEN', 'REG_CLOSED', 'ONGOING'].contains(cs);
    }
    if (_filter == 'Đã hoàn thành') return cs == 'FINISHED';
    if (_filter == 'Chờ duyệt') {
      return e['registration_status'] == 'PENDING';
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(myEntriesProvider);
    return Scaffold(
      appBar: const MTopBar(title: 'Của tôi'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in [
                'Tất cả',
                'Chờ duyệt',
                'Đang dự thi',
                'Đã hoàn thành'
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _filter == f ? ptitRed : Colors.white,
                        border: Border.all(
                            color: _filter == f ? ptitRed : context.cardBorder),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(f,
                          style: TextStyle(
                            fontSize: 11,
                            color: _filter == f ? Colors.white : context.textMuted,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: asyncList.when(
            loading: () =>
                // Phase 2 step 5: skeleton thay spinner
                const MCardListSkeleton(count: 3, textLines: 3),
            error: (e, _) {
              final msg = e is DioException
                  ? (e.response?.data is Map
                      ? '${e.response?.data['detail']}'
                      : e.message ?? '')
                  : '$e';
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Lỗi: $msg',
                          style: TextStyle(color: context.textMuted))));
            },
            data: (entries) {
              final filtered = entries.where(_matchesFilter).toList();
              if (filtered.isEmpty) {
                return RefreshIndicator(
                  color: ptitRed,
                  onRefresh: () async => ref.invalidate(myEntriesProvider),
                  child: ListView(children: [
                    const SizedBox(height: 60),
                    Icon(Icons.inbox_outlined,
                        size: 64, color: context.textMuted.withValues(alpha: 0.6)),
                    const SizedBox(height: 12),
                    Text(
                      _filter == 'Tất cả'
                          ? 'Chưa đăng ký cuộc thi nào.\nMở tab Cuộc thi để duyệt + đăng ký.'
                          : 'Không có entry nào ở mục "$_filter"',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: context.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 60),
                  ]),
                );
              }
              return RefreshIndicator(
                color: ptitRed,
                onRefresh: () async => ref.invalidate(myEntriesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _EntryCard(entry: filtered[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  final Map<String, dynamic> entry;
  const _EntryCard({required this.entry});

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy đăng ký?'),
        content: Text('Hủy đăng ký "${entry['contest_title']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ptitRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.delete('/contests/${entry['contest_id']}/registration');
      ref.invalidate(myEntriesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã hủy đăng ký')));
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? '${e.response?.data['detail']}'
          : (e.message ?? '');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    }
  }

  Future<void> _navSubmit(BuildContext context, WidgetRef ref) async {
    try {
      final res = await ref
          .read(apiClientProvider)
          .dio
          .get('/contests/${entry['contest_id']}/rounds');
      final rounds = res.data as List;
      if (rounds.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cuộc thi chưa có round')));
        return;
      }
      if (!context.mounted) return;
      context.push('/rounds/${rounds.first['round_id']}/submit');
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('${e.message}')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = (entry['contest_status'] as String?) ?? '—';
    final rs = (entry['registration_status'] as String?) ?? '—';
    final isPending = rs == 'PENDING';
    final isApproved = rs == 'APPROVED';
    final canCancel = (rs == 'PENDING' || rs == 'APPROVED') &&
        ['REG_OPEN', 'REG_CLOSED'].contains(cs);
    final canSubmit = isApproved && cs == 'ONGOING';
    final isFinished = cs == 'FINISHED';
    final fmt = DateFormat('dd/MM/yy');

    return MCard(
      onTap: () => context.push('/contests/${entry['contest_slug']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(entry['contest_title'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 6),
            Pill.status(cs),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Pill(
              label: isPending
                  ? 'Chờ BTC duyệt'
                  : (isApproved ? 'BTC đã duyệt' : rs),
              color: isApproved
                  ? context.successGreen
                  : (isPending ? context.warnOrange : ptitRed),
              bg: isApproved
                  ? context.successSoft
                  : (isPending ? context.warnSoft : context.ptitRedSoft),
            ),
            const SizedBox(width: 6),
            Text('${entry['entry_type']}',
                style: TextStyle(fontSize: 11, color: context.textMuted)),
          ]),
          if ((entry['registration_note'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Ghi chú: ${entry['registration_note']}',
                style: TextStyle(
                    fontSize: 11, color: context.textMuted, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 8),
          Text(
            'Đăng ký ${fmt.format(DateTime.parse(entry['created_at']).toLocal())}'
            ' · Thi ${fmt.format(DateTime.parse(entry['contest_start_at']).toLocal())}'
            ' → ${fmt.format(DateTime.parse(entry['contest_end_at']).toLocal())}',
            style: TextStyle(fontSize: 10, color: context.textFaint),
          ),
          if (canCancel || canSubmit || isFinished) ...[
            const SizedBox(height: 10),
            Row(children: [
              if (canSubmit)
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.upload_file, size: 14),
                    label: const Text('Nộp bài',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () => _navSubmit(context, ref),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10)),
                  ),
                ),
              if (isFinished)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.emoji_events_outlined, size: 14),
                    label: const Text('Xem kết quả',
                        style: TextStyle(fontSize: 12)),
                    onPressed: () =>
                        context.push('/contests/${entry['contest_slug']}'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10)),
                  ),
                ),
              if (canSubmit || isFinished) const SizedBox(width: 8),
              if (canCancel)
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined,
                      size: 14, color: ptitRed),
                  label: const Text('Hủy',
                      style: TextStyle(fontSize: 11, color: ptitRed)),
                  onPressed: () => _cancel(context, ref),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: BorderSide(color: context.ptitRedSoft)),
                ),
            ]),
          ],
        ],
      ),
    );
  }
}
