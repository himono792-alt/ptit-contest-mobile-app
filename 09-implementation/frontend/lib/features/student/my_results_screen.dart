import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/result.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
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
      appBar: const MTopBar(title: 'Kết quả'),
      body: asyncResults.when(
        loading: () => const Center(child: CircularProgressIndicator(color: ptitRed)),
        error: (e, _) {
          final msg = e is DioException
              ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
              : '$e';
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(msg, style: const TextStyle(color: textMuted))));
        },
        data: (results) => RefreshIndicator(
          color: ptitRed,
          onRefresh: () async => ref.invalidate(myResultsProvider),
          child: results.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'Chưa có kết quả nào.\nKết quả sẽ hiện sau khi cuộc thi FINISHED + BCN duyệt.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textMuted),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: results.length,
                  itemBuilder: (_, i) => _ResultCard(result: results[i]),
                ),
        ),
      ),
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
      backgroundColor: hasAward ? ptitRedSoft : Colors.white,
      borderColor: hasAward ? ptitRed : cardBorder,
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
              style: const TextStyle(fontSize: 12, color: textMuted)),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: cardBorder, height: 1)),
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
              label: const Text('Xem mã QR chứng nhận'),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Vào "Tôi → Xác thực chứng nhận" để tra mã QR. (Tải PDF: render qua /api/certificates/{qr}/render)'),
                    duration: Duration(seconds: 4)));
              },
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
          Text(label, style: const TextStyle(fontSize: 12, color: textMuted)),
          Text(value,
              style: TextStyle(
                fontSize: bold ? 16 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                color: color ?? textPrimary,
              )),
        ],
      );
}
