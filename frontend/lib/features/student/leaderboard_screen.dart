// Sprint 16 (2026-05-08): Leaderboard SV theo design sv-12 + SVW-06.
// - Top-3 podium với gold/silver/bronze
// - Table rank #4+ với highlight row "BẠN" nếu entry là của user
// - State: loading skeleton / empty / error
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';

final _leaderboardProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$contestId/leaderboard');
  return res.data as List<dynamic>;
});

/// Sprint 16 — endpoint trả MyResult của user, dùng để biết entry_id của SV
/// trong contest này → highlight row "BẠN" trong leaderboard.
final _myEntryInContestProvider =
    FutureProvider.autoDispose.family<int?, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/me/results');
    final list = res.data as List<dynamic>;
    for (final r in list) {
      if ((r as Map)['contest_id'] == contestId) {
        return r['entry_id'] as int?;
      }
    }
  } catch (_) {}
  return null;
});

class LeaderboardScreen extends ConsumerWidget {
  final int contestId;
  final String contestTitle;

  const LeaderboardScreen({
    super.key,
    required this.contestId,
    required this.contestTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(_leaderboardProvider(contestId));
    final asyncMyEntry = ref.watch(_myEntryInContestProvider(contestId));
    final myEntryId = asyncMyEntry.value;

    return Scaffold(
      backgroundColor: context.appBg,
      appBar: MTopBar(
        title: 'Bảng xếp hạng',
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: Icon(Icons.arrow_back, color: context.textMuted),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        color: ptitRed,
        onRefresh: () async {
          ref.invalidate(_leaderboardProvider(contestId));
          ref.invalidate(_myEntryInContestProvider(contestId));
        },
        child: asyncList.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: ptitRed)),
          error: (e, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              MCard(
                backgroundColor: context.ptitRedSoft,
                child: Text('Lỗi: ${_msg(e)}',
                    style: const TextStyle(color: ptitRed, fontSize: 13)),
              ),
            ],
          ),
          data: (items) => items.isEmpty
              ? _EmptyLeaderboard(contestTitle: contestTitle)
              : _LeaderboardBody(
                  items: items.cast<Map<String, dynamic>>(),
                  myEntryId: myEntryId,
                  contestTitle: contestTitle,
                ),
        ),
      ),
    );
  }
}

class _LeaderboardBody extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int? myEntryId;
  final String contestTitle;

  const _LeaderboardBody({
    required this.items,
    required this.myEntryId,
    required this.contestTitle,
  });

  @override
  Widget build(BuildContext context) {
    final top3 = items.where((r) => (r['rank_no'] as int? ?? 0) <= 3).toList();
    final rest = items.where((r) => (r['rank_no'] as int? ?? 0) > 3).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero contest title
        Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            gradient: ptitGradientHero,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.emoji_events, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Text('BẢNG XẾP HẠNG',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ]),
              const SizedBox(height: 6),
              Text(contestTitle,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2)),
              const SizedBox(height: 4),
              Text('${items.length} thí sinh tham gia',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Podium top-3
        if (top3.isNotEmpty) ...[
          _Podium(items: top3, myEntryId: myEntryId),
          const SizedBox(height: 22),
        ],

        // Table rank #4+
        if (rest.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text('Xếp hạng còn lại',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.textMuted,
                    letterSpacing: 0.6)),
          ),
          ...rest.map((r) => _RankRow(item: r, myEntryId: myEntryId)),
        ],
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final int? myEntryId;

  const _Podium({required this.items, required this.myEntryId});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? findRank(int rank) =>
        items.firstWhere((e) => e['rank_no'] == rank, orElse: () => {});

    final r1 = findRank(1);
    final r2 = findRank(2);
    final r3 = findRank(3);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (r2!.isNotEmpty)
          Expanded(
              child: _PodiumColumn(
                  data: r2, height: 110, color: const Color(0xFFC0C0C0),
                  rank: 2, myEntryId: myEntryId))
        else
          const Expanded(child: SizedBox.shrink()),
        const SizedBox(width: 8),
        if (r1!.isNotEmpty)
          Expanded(
              child: _PodiumColumn(
                  data: r1, height: 140, color: const Color(0xFFFFC107),
                  rank: 1, myEntryId: myEntryId))
        else
          const Expanded(child: SizedBox.shrink()),
        const SizedBox(width: 8),
        if (r3!.isNotEmpty)
          Expanded(
              child: _PodiumColumn(
                  data: r3, height: 90, color: const Color(0xFFCD7F32),
                  rank: 3, myEntryId: myEntryId))
        else
          const Expanded(child: SizedBox.shrink()),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final Map<String, dynamic> data;
  final double height;
  final Color color;
  final int rank;
  final int? myEntryId;

  const _PodiumColumn({
    required this.data,
    required this.height,
    required this.color,
    required this.rank,
    required this.myEntryId,
  });

  @override
  Widget build(BuildContext context) {
    final isMe = myEntryId != null && data['entry_id'] == myEntryId;
    final score = data['final_score'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle với rank badge
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: ptitGradientHero,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 3),
              ),
              child: Center(
                child: Text(
                  _initials(data['display_name'] as String? ?? '?'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.appBg, width: 2)),
              child: Center(
                child: Text('$rank',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          data['display_name'] as String? ?? '?',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.textPrimary),
        ),
        if (isMe)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Pill(
                label: 'BẠN',
                color: Colors.white,
                bg: ptitRed),
          ),
        if (score != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('${score.toStringAsFixed(2)} đ',
                style: TextStyle(
                    fontSize: 11,
                    color: context.textMuted,
                    fontWeight: FontWeight.w600)),
          ),
        const SizedBox(height: 6),
        // Pillar
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22),
            ),
          ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _RankRow extends StatelessWidget {
  final Map<String, dynamic> item;
  final int? myEntryId;

  const _RankRow({required this.item, required this.myEntryId});

  @override
  Widget build(BuildContext context) {
    final isMe = myEntryId != null && item['entry_id'] == myEntryId;
    final rank = item['rank_no'] as int? ?? 0;
    final score = item['final_score'];
    final award = item['award_title'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? context.ptitRedSoft : context.cardBg,
        border: Border.all(
            color: isMe ? ptitRed : context.cardBorder,
            width: isMe ? 1.5 : 1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Text('#$rank',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isMe ? ptitRed : context.textMuted)),
        ),
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  item['display_name'] as String? ?? '?',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: isMe ? FontWeight.w800 : FontWeight.w600,
                      color:
                          isMe ? ptitRed : context.textPrimary),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                Pill(label: 'BẠN', color: Colors.white, bg: ptitRed),
              ],
              if (award != null && award.isNotEmpty) ...[
                const SizedBox(width: 6),
                Pill(
                    label: award,
                    color: const Color(0xFFB45309),
                    bg: const Color(0xFFFEF3C7)),
              ],
            ],
          ),
        ),
        if (score != null)
          Text('${(score as num).toStringAsFixed(2)} đ',
              style: TextStyle(
                  fontSize: 12,
                  color: context.textMuted,
                  fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _EmptyLeaderboard extends StatelessWidget {
  final String contestTitle;
  const _EmptyLeaderboard({required this.contestTitle});

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(40),
        children: [
          const SizedBox(height: 80),
          Icon(Icons.emoji_events_outlined,
              size: 72, color: context.textMuted),
          const SizedBox(height: 16),
          Text('Chưa có bảng xếp hạng',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary)),
          const SizedBox(height: 6),
          Text(
              'BTC chưa publish kết quả $contestTitle. Quay lại sau khi cuộc thi kết thúc.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: context.textMuted)),
        ],
      );
}

String _msg(Object e) => e is DioException
    ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
    : '$e';
