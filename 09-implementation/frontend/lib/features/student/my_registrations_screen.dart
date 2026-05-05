import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/contest.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';

final myContestsProvider = FutureProvider.autoDispose<List<ContestSummary>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests', queryParameters: {'size': 50});
  return ContestListResponse.fromJson(res.data).items;
});

class MyRegistrationsScreen extends ConsumerStatefulWidget {
  const MyRegistrationsScreen({super.key});
  @override
  ConsumerState<MyRegistrationsScreen> createState() => _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends ConsumerState<MyRegistrationsScreen> {
  String _filter = 'Tất cả';

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(myContestsProvider);
    return Scaffold(
      appBar: const MTopBar(title: 'Của tôi'),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            for (final f in ['Tất cả', 'Đang dự thi', 'Đã hoàn thành'])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  onTap: () => setState(() => _filter = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _filter == f ? ptitRed : Colors.white,
                      border: Border.all(color: _filter == f ? ptitRed : cardBorder),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(f, style: TextStyle(
                      fontSize: 11,
                      color: _filter == f ? Colors.white : textMuted,
                      fontWeight: FontWeight.w500,
                    )),
                  ),
                ),
              ),
          ]),
        ),
        Expanded(
          child: asyncList.when(
            loading: () => const Center(child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: textMuted))),
            data: (contests) {
              final filtered = _filter == 'Tất cả' ? contests
                  : contests.where((c) {
                      if (_filter == 'Đã hoàn thành') return c.status == 'FINISHED';
                      return ['REG_OPEN', 'REG_CLOSED', 'ONGOING', 'PUBLISHED'].contains(c.status);
                    }).toList();
              if (filtered.isEmpty) {
                return const Center(
                    child: Padding(padding: EdgeInsets.all(32),
                        child: Text('Chưa đăng ký cuộc thi nào.\nMở tab Cuộc thi để duyệt + đăng ký.',
                            textAlign: TextAlign.center, style: TextStyle(color: textMuted))));
              }
              return RefreshIndicator(
                color: ptitRed,
                onRefresh: () async => ref.invalidate(myContestsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _RegItem(contest: filtered[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _RegItem extends ConsumerWidget {
  final ContestSummary contest;
  const _RegItem({required this.contest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MCard(
      onTap: () => context.push('/contests/${contest.slug}'),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(contest.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                const SizedBox(width: 6),
                Pill.status(contest.status),
              ]),
              const SizedBox(height: 4),
              Text('${contest.participationMode == "TEAM" ? "Đội" : "Cá nhân"}',
                  style: const TextStyle(color: textMuted, fontSize: 11)),
            ],
          ),
        ),
        if (contest.status == 'ONGOING' || contest.status == 'REG_OPEN')
          GestureDetector(
            onTap: () => _navSubmit(context, ref, contest),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: ptitRed, borderRadius: BorderRadius.circular(6)),
              child: const Text('Nộp bài', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
      ]),
    );
  }

  Future<void> _navSubmit(BuildContext context, WidgetRef ref, ContestSummary c) async {
    try {
      final res = await ref.read(apiClientProvider).dio.get('/contests/${c.contestId}/rounds');
      final rounds = res.data as List;
      if (rounds.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cuộc thi chưa có round')));
        return;
      }
      if (!context.mounted) return;
      context.push('/rounds/${rounds.first['round_id']}/submit');
    } on DioException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${e.message}')));
    }
  }
}
