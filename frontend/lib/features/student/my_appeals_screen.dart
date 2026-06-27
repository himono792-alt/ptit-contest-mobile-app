import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/appeal.dart';
import '../../core/theme.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/app_toast.dart';

final myAppealsProvider =
    FutureProvider.autoDispose<List<AppealModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/me/appeals');
  return (res.data as List).map((j) => AppealModel.fromJson(j)).toList();
});

/// Màu badge theo trạng thái phúc khảo (dùng chung SV + GV).
Color appealStatusColor(BuildContext context, String status) => switch (status) {
      'PENDING' => context.warnOrange,
      'IN_REVIEW' => context.infoBlue,
      'ACCEPTED' => context.successGreen,
      'REJECTED' => ptitRed,
      'CLOSED' => context.textMuted,
      _ => context.textMuted,
    };

class AppealStatusBadge extends StatelessWidget {
  final AppealModel appeal;
  const AppealStatusBadge({super.key, required this.appeal});

  @override
  Widget build(BuildContext context) {
    final c = appealStatusColor(context, appeal.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.tight),
      ),
      child: Text(appeal.statusLabel,
          style: TextStyle(
              fontSize: 10.5, fontWeight: FontWeight.w800, color: c)),
    );
  }
}

class MyAppealsScreen extends ConsumerWidget {
  const MyAppealsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myAppealsProvider);
    return Scaffold(
      appBar: const MTopBar(title: 'Phúc khảo của tôi'),
      body: async.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            MListItemSkeleton(),
            MListItemSkeleton(),
          ],
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(FriendlyError.of(e),
                style: TextStyle(color: context.textMuted)),
          ),
        ),
        data: (items) => RefreshIndicator(
          color: ptitRed,
          onRefresh: () async => ref.invalidate(myAppealsProvider),
          child: items.isEmpty
              ? ListView(children: const [
                  SizedBox(height: 80),
                  EmptyView(
                    icon: Icons.gavel_outlined,
                    title: 'Chưa có phúc khảo',
                    subtitle:
                        'Bạn có thể gửi phúc khảo từ màn Kết quả nếu cuộc thi còn mở kênh.',
                  ),
                ])
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final a in items)
                      _MyAppealCard(appeal: a),
                  ],
                ),
        ),
      ),
    );
  }
}

class _MyAppealCard extends ConsumerWidget {
  final AppealModel appeal;
  const _MyAppealCard({required this.appeal});

  Future<void> _withdraw(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rút phúc khảo?'),
        content: const Text(
            'Bạn chắc chắn muốn rút phúc khảo này? Sau khi rút, bạn có thể gửi lại nếu còn hạn.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Rút')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .post('/appeals/${appeal.appealId}/withdraw');
      ref.invalidate(myAppealsProvider);
      if (context.mounted) AppToast.success(context, 'Đã rút phúc khảo');
    } catch (e) {
      if (context.mounted) AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(appeal.title,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            AppealStatusBadge(appeal: appeal),
          ]),
          const SizedBox(height: 6),
          Text(appeal.contentText,
              style: TextStyle(fontSize: 12.5, color: context.textPrimary)),
          const SizedBox(height: 8),
          Text('Gửi lúc ${fmt.format(appeal.createdAt.toLocal())}',
              style: TextStyle(fontSize: 11, color: context.textMuted)),
          if (appeal.responseText != null &&
              appeal.responseText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    appealStatusColor(context, appeal.status).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: appealStatusColor(context, appeal.status)
                        .withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phản hồi của BTC',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: appealStatusColor(context, appeal.status))),
                  const SizedBox(height: 4),
                  Text(appeal.responseText!,
                      style: TextStyle(
                          fontSize: 12.5, color: context.textPrimary)),
                ],
              ),
            ),
          ],
          if (appeal.status == 'PENDING') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.undo, size: 15),
                label: const Text('Rút phúc khảo'),
                onPressed: () => _withdraw(context, ref),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
