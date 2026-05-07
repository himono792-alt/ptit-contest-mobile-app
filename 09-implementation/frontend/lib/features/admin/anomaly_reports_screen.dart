// AD-06 — Anomaly reports screen.
//
// GET /admin/anomaly-reports → server scan audit_logs + business tables để phát
// hiện hành vi bất thường (vd: 1 user lock-unlock liên tục, contest publish
// không qua workflow, judge tự chấm bài của mình, review spam cùng IP).
//
// Response dạng list { type, severity, entity_id, entity_type, detected_at,
//   description, count, related_user_id, suggested_action }.
//
// Sprint 6 (2026-05-07).

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';

final anomalyFilterProvider = StateProvider<String?>((_) => null);

final anomalyReportsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final severity = ref.watch(anomalyFilterProvider);
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/anomaly-reports',
      queryParameters: severity != null ? {'severity': severity} : null);
  if (res.data is List) return res.data as List<dynamic>;
  if (res.data is Map && res.data['items'] != null) {
    return res.data['items'] as List<dynamic>;
  }
  return [];
});

class AnomalyReportsScreen extends ConsumerWidget {
  const AnomalyReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(anomalyReportsProvider);
    final severity = ref.watch(anomalyFilterProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: context.appBg,
      body: Column(children: [
        if (!isMobile)
          Container(
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
                    Text('Quản trị',
                        style: TextStyle(
                            color: context.textMuted, fontSize: 11)),
                    const SizedBox(height: 2),
                    Text('Báo cáo bất thường (AD-06)',
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
                onPressed: () => ref.invalidate(anomalyReportsProvider),
              ),
            ]),
          ),
        // Filter chips
        Padding(
          padding: EdgeInsets.fromLTRB(
              isMobile ? 14 : 24, 14, isMobile ? 14 : 24, 0),
          child: Wrap(spacing: 8, children: [
            _SeverityChip(label: 'Tất cả', value: null, current: severity, ref: ref),
            _SeverityChip(label: 'Cao', value: 'HIGH', current: severity, ref: ref),
            _SeverityChip(label: 'Trung bình', value: 'MEDIUM', current: severity, ref: ref),
            _SeverityChip(label: 'Thấp', value: 'LOW', current: severity, ref: ref),
          ]),
        ),
        Expanded(
          child: asyncList.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => _ErrorView(error: e, ref: ref),
            data: (items) => items.isEmpty
                ? Center(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined,
                              size: 56, color: context.successGreen),
                          const SizedBox(height: 12),
                          Text('Không phát hiện bất thường',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary)),
                          const SizedBox(height: 4),
                          Text('Hệ thống đang hoạt động bình thường.',
                              style: TextStyle(
                                  fontSize: 12, color: context.textMuted)),
                        ]),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(isMobile ? 14 : 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) =>
                        _AnomalyCard(data: items[i] as Map<String, dynamic>),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? current;
  final WidgetRef ref;
  const _SeverityChip(
      {required this.label,
      required this.value,
      required this.current,
      required this.ref});

  @override
  Widget build(BuildContext context) {
    final isActive = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) =>
          ref.read(anomalyFilterProvider.notifier).state = value,
      selectedColor: context.ptitRedSoft,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isActive ? ptitRed : context.textPrimary,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _AnomalyCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AnomalyCard({required this.data});

  Color _sevColor(BuildContext c, String? sev) {
    switch (sev) {
      case 'HIGH':
        return ptitRed;
      case 'MEDIUM':
        return c.warnOrange;
      case 'LOW':
        return c.infoBlue;
      default:
        return c.textMuted;
    }
  }

  Color _sevBg(BuildContext c, String? sev) {
    switch (sev) {
      case 'HIGH':
        return c.ptitRedSoft;
      case 'MEDIUM':
        return c.warnSoft;
      case 'LOW':
        return c.infoSoft;
      default:
        return c.cardBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final sev = data['severity'] as String?;
    final detectedAt = data['detected_at'] != null
        ? fmt.format(DateTime.parse(data['detected_at']).toLocal())
        : '—';

    return MCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Pill(
            label: sev ?? 'INFO',
            color: _sevColor(context, sev),
            bg: _sevBg(context, sev),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(data['type']?.toString() ?? 'Anomaly',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary)),
          ),
          if (data['count'] != null)
            Text('×${data['count']}',
                style: TextStyle(
                    fontSize: 12, color: context.textMuted)),
        ]),
        const SizedBox(height: 6),
        Text(data['description']?.toString() ?? '',
            style: TextStyle(
                fontSize: 12.5, color: context.textPrimary, height: 1.5)),
        const SizedBox(height: 10),
        Wrap(spacing: 14, runSpacing: 4, children: [
          if (data['entity_type'] != null)
            _Meta('Entity',
                '${data['entity_type']} #${data['entity_id'] ?? '?'}'),
          if (data['related_user_id'] != null)
            _Meta('User', '#${data['related_user_id']}'),
          _Meta('Phát hiện', detectedAt),
        ]),
        if (data['suggested_action'] != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: context.infoSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(children: [
              Icon(Icons.lightbulb_outline,
                  size: 14, color: context.infoBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(data['suggested_action'].toString(),
                    style: TextStyle(
                        fontSize: 12, color: context.textPrimary)),
              ),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _Meta extends StatelessWidget {
  final String k;
  final String v;
  const _Meta(this.k, this.v);
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text('$k: ',
          style: TextStyle(fontSize: 11, color: context.textMuted)),
      Text(v,
          style: TextStyle(
              fontSize: 11,
              color: context.textPrimary,
              fontWeight: FontWeight.w600)),
    ]);
  }
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final WidgetRef ref;
  const _ErrorView({required this.error, required this.ref});
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
          FilledButton(
              onPressed: () => ref.invalidate(anomalyReportsProvider),
              child: const Text('Thử lại')),
        ]),
      ),
    );
  }
}
