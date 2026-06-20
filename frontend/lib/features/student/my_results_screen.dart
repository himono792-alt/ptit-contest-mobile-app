import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/result.dart';
import '../../core/theme.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/help_button.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/m_top_bar.dart';
import 'cert_verify_screen.dart';
import 'review_dialog.dart';

final myResultsProvider = FutureProvider.autoDispose<List<MyResultModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/me/results');
  return (res.data as List).map((j) => MyResultModel.fromJson(j)).toList();
});

class MyResultsScreen extends ConsumerWidget {
  const MyResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResults = ref.watch(myResultsProvider);
    return Scaffold(
      appBar: const MTopBar(title: 'Kết quả', actions: [
        HelpButton(id: 'sv_my_results'),
      ]),
      body: asyncResults.when(
        // Phase 2 step 5: skeleton thay spinner — list rank dùng MListItemSkeleton
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            MListItemSkeleton(),
            MListItemSkeleton(),
            MListItemSkeleton(),
          ],
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(FriendlyError.of(e), style: TextStyle(color: context.textMuted)),
          ),
        ),
        data: (results) => RefreshIndicator(
          color: ptitRed,
          onRefresh: () async => ref.invalidate(myResultsProvider),
          child: results.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 80),
                  EmptyView(
                    icon: Icons.emoji_events_outlined,
                    title: 'Chưa có kết quả',
                    subtitle:
                        'Kết quả sẽ xuất hiện sau khi cuộc thi bạn tham gia được chấm xong.',
                  ),
                ])
              // Redesign 2026-06-20: stat strip + gom nhóm theo tháng công bố.
              : Builder(builder: (_) {
                  final sorted = [...results]
                    ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
                  final groups = <String, List<MyResultModel>>{};
                  for (final r in sorted) {
                    final k =
                        'Tháng ${r.publishedAt.month}/${r.publishedAt.year}';
                    groups.putIfAbsent(k, () => []).add(r);
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _ResultStatStrip(results: results),
                      const SizedBox(height: 12),
                      for (final entry in groups.entries) ...[
                        _ResultGroupHeader(
                            label: entry.key, count: entry.value.length),
                        for (final r in entry.value)
                          _ResultCard(result: r),
                      ],
                    ],
                  );
                }),
        ),
      ),
    );
  }
}

// Redesign 2026-06-20: stat strip + group theo tháng cho "Kết quả của tôi".
class _ResultStatStrip extends StatelessWidget {
  final List<MyResultModel> results;
  const _ResultStatStrip({required this.results});

  @override
  Widget build(BuildContext context) {
    final awards =
        results.where((r) => (r.awardTitle ?? '').isNotEmpty).length;
    final ranks = results
        .map((r) => r.rankNo)
        .whereType<int>()
        .toList();
    final best = ranks.isEmpty ? null : ranks.reduce((a, b) => a < b ? a : b);
    return Row(children: [
      Expanded(
        child: _ResultStat(
          value: '${results.length}',
          label: 'Tổng kết quả',
          color: ptitRed,
          icon: Icons.emoji_events_outlined,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ResultStat(
          value: '$awards',
          label: 'Có giải',
          color: context.achievementGold,
          icon: Icons.workspace_premium_outlined,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _ResultStat(
          value: best == null ? '—' : '#$best',
          label: 'Hạng cao nhất',
          color: context.infoBlue,
          icon: Icons.military_tech_outlined,
        ),
      ),
    ]);
  }
}

class _ResultStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _ResultStat(
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

class _ResultGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  const _ResultGroupHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(children: [
        Icon(Icons.event_outlined, size: 15, color: context.textMuted),
        const SizedBox(width: 6),
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

class _ResultCard extends StatelessWidget {
  final MyResultModel result;
  const _ResultCard({required this.result});

  String _trophy() {
    switch (result.rankNo) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '🏆';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');
    final hasAward = result.awardTitle != null && result.awardTitle!.isNotEmpty;

    return MCard(
      backgroundColor: hasAward ? context.ptitRedSoft : context.cardBg,
      borderColor: hasAward ? ptitRed : context.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(_trophy(), style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          if (hasAward)
            Text(result.awardTitle!,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ptitRed)),
          const SizedBox(height: 4),
          Text(result.contestTitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: context.textMuted)),
          Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: context.cardBorder, height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                _ScoreRow(label: 'Tổng điểm (final_score)',
                    value: result.finalScore?.toStringAsFixed(2) ?? '—', bold: true, color: ptitRed),
                const SizedBox(height: 6),
                _ScoreRow(label: 'Xếp hạng', value: '${result.rankNo ?? '—'}'),
                const SizedBox(height: 6),
                _ScoreRow(label: 'Công bố', value: fmt.format(result.publishedAt.toLocal())),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.qr_code, size: 18),
              label: const Text('Xác thực / Tải chứng nhận'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CertVerifyScreen()),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.star_outline, size: 16),
              label: const Text('Đánh giá cuộc thi'),
              onPressed: () => showReviewDialog(
                context,
                contestId: result.contestId,
                contestTitle: result.contestTitle,
              ),
            ),
          ),
          // Sprint 16 (2026-05-08): button vào Bảng xếp hạng full
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.leaderboard_outlined, size: 16),
              label: const Text('Bảng xếp hạng'),
              onPressed: () => context.push(
                '/contests/${result.contestId}/leaderboard',
                extra: result.contestTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;
  const _ScoreRow({required this.label, required this.value, this.bold = false, this.color});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: context.textMuted)),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: color ?? context.textPrimary,
              )),
        ],
      );
}
