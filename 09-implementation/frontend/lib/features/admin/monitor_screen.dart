import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';

final monitorProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/contests/monitor');
  return res.data as Map<String, dynamic>;
});

class MonitorScreen extends ConsumerWidget {
  const MonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(monitorProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(children: [
        // Top bar
        if (!isMobile) Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: context.cardBorder)),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BCN', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textMuted)),
                  SizedBox(height: 2),
                  Text('Giám sát tiến độ',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: context.textMuted),
              onPressed: () => ref.invalidate(monitorProvider),
            ),
          ]),
        ),
        Expanded(
          child: asyncData.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => _ErrorView(
                error: e, onRetry: () => ref.invalidate(monitorProvider)),
            data: (data) {
              final items = (data['items'] as List).cast<Map<String, dynamic>>();
              final total = data['total'] as int;
              return SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 14 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng: $total cuộc thi',
                        style: TextStyle(
                            fontSize: 12, color: context.textMuted)),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text('Không có cuộc thi nào',
                              style: TextStyle(color: context.textMuted)),
                        ),
                      )
                    else
                      ...items.map((it) => _MonitorCard(data: it)),
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _MonitorCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MonitorCard({required this.data});

  String _pctText(double? pct) =>
      pct == null ? 'chưa có' : '${pct.toStringAsFixed(0)}%';

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy');
    final regPct = (data['registration_pct'] as num?)?.toDouble();
    final subPct = (data['submission_pct'] as num?)?.toDouble();
    final judgePct = (data['judging_pct'] as num?)?.toDouble();

    String dateRange = '';
    if (data['start_at'] != null && data['end_at'] != null) {
      final s = DateTime.parse(data['start_at']);
      final e = DateTime.parse(data['end_at']);
      dateRange = '${fmt.format(s)} → ${fmt.format(e)}';
    }

    // Sprint 5 Semantics: tổng hợp summary cho screen reader
    final title = data['title'] ?? '';
    final status = data['status'] ?? '';
    final entries = data['total_entries'] ?? 0;
    final subs = data['total_submissions'] ?? 0;
    final summary =
        '$title, trạng thái $status. $entries đề xuất, $subs bài nộp. '
        'Đăng ký ${_pctText(regPct)}, Nộp bài ${_pctText(subPct)}, '
        'Chấm điểm ${_pctText(judgePct)}.';

    return Semantics(
      container: true,
      label: summary,
      child: MCard(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] ?? '',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary)),
                    const SizedBox(height: 2),
                    Text(data['slug'] ?? '',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textMuted)),
                  ]),
            ),
            const SizedBox(width: 8),
            Pill.status(data['status'] as String),
          ]),
          if (dateRange.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.calendar_today, size: 12, color: context.textMuted),
              const SizedBox(width: 4),
              Text(dateRange,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textMuted)),
              const SizedBox(width: 16),
              Text(
                  '${data['total_entries']} entries · ${data['total_submissions']} submissions',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textMuted)),
            ]),
          ],
          const SizedBox(height: 14),
          _Progress(
              label: 'Đăng ký', pct: regPct, color: ptitRed),
          const SizedBox(height: 8),
          _Progress(
              label: 'Nộp bài', pct: subPct, color: context.infoBlue),
          const SizedBox(height: 8),
          _Progress(
              label: 'Chấm điểm', pct: judgePct, color: context.successGreen),
        ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final String label;
  final double? pct;
  final Color color;
  const _Progress(
      {required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    // Backend returns 0-100 (already a percentage), not 0-1 ratio.
    final ratio = ((pct ?? 0) / 100).clamp(0.0, 1.0);
    final pctText = pct == null ? '—' : '${pct!.toStringAsFixed(0)}%';
    final semanticValue = pct == null ? 'chưa có dữ liệu' : '${pct!.toStringAsFixed(0)} phần trăm';
    return Semantics(
      label: label,
      value: semanticValue,
      child: ExcludeSemantics(child: Row(children: [
      SizedBox(
        width: 90,
        child: Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textPrimary)),
      ),
      Expanded(
        child: Stack(children: [
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          FractionallySizedBox(
            widthFactor: ratio,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 44,
        child: Text(pctText,
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ),
    ])),
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
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textMuted)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ]),
      ),
    );
  }
}
