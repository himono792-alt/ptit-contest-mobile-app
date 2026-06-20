import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/help_button.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/pill.dart';

class _AuditParams {
  final String? actionType;
  final String? entityName;
  final int? userId;
  // Sprint 13 Batch C (2026-05-08): date range filter cho audit log.
  final DateTime? dateFrom;
  final DateTime? dateTo;
  const _AuditParams(
      {this.actionType,
      this.entityName,
      this.userId,
      this.dateFrom,
      this.dateTo});
}

final auditParamsProvider =
    StateProvider<_AuditParams>((_) => const _AuditParams());

final auditLogsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final p = ref.watch(auditParamsProvider);
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/audit-logs', queryParameters: {
    'size': 100,
    if (p.actionType != null) 'action_type': p.actionType,
    if (p.entityName != null) 'entity_name': p.entityName,
    if (p.userId != null) 'user_id': p.userId,
    if (p.dateFrom != null) 'date_from': p.dateFrom!.toUtc().toIso8601String(),
    if (p.dateTo != null) 'date_to': p.dateTo!.toUtc().toIso8601String(),
  });
  return res.data as Map<String, dynamic>;
});

class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});
  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _actionCtrl = TextEditingController();
  final _entityCtrl = TextEditingController();
  final _userIdCtrl = TextEditingController();

  @override
  void dispose() {
    _actionCtrl.dispose();
    _entityCtrl.dispose();
    _userIdCtrl.dispose();
    super.dispose();
  }

  // Sprint 13 Batch C (2026-05-08): date range state cho filter.
  DateTime? _dateFrom;
  DateTime? _dateTo;

  void _applyFilter() {
    final params = _AuditParams(
      actionType: _actionCtrl.text.isEmpty ? null : _actionCtrl.text.trim(),
      entityName: _entityCtrl.text.isEmpty ? null : _entityCtrl.text.trim(),
      userId: _userIdCtrl.text.isEmpty ? null : int.tryParse(_userIdCtrl.text),
      dateFrom: _dateFrom,
      dateTo: _dateTo,
    );
    ref.read(auditParamsProvider.notifier).state = params;
  }

  Future<void> _pickDate(bool isFrom) async {
    final base = isFrom
        ? (_dateFrom ?? DateTime.now().subtract(const Duration(days: 7)))
        : (_dateTo ?? DateTime.now());
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (d == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = DateTime(d.year, d.month, d.day);
      } else {
        // Set to end of day for inclusive filter
        _dateTo = DateTime(d.year, d.month, d.day, 23, 59, 59);
      }
    });
    _applyFilter();
  }

  void _clearDates() {
    setState(() {
      _dateFrom = null;
      _dateTo = null;
    });
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(auditLogsProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: context.appBg,
      body: Column(children: [
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
                  Text('Quản trị',
                      style: TextStyle(color: context.textMuted, fontSize: 11)),
                  SizedBox(height: 2),
                  Text('Audit log',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                ],
              ),
            ),
            const HelpButton(id: 'admin_audit'),
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: context.textMuted),
              onPressed: () => ref.invalidate(auditLogsProvider),
            ),
          ]),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(isMobile ? 14 : 32, isMobile ? 12 : 18, isMobile ? 14 : 32, 0),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _actionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Action type',
                      hintText: 'CREATE, UPDATE, DELETE...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _entityCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Entity name',
                      hintText: 'app_users, contests...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _applyFilter(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 120,
                height: 40,
                child: TextField(
                  controller: _userIdCtrl,
                  decoration: const InputDecoration(
                    labelText: 'User ID',
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  onSubmitted: (_) => _applyFilter(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _applyFilter,
                icon: const Icon(Icons.filter_alt_outlined, size: 16),
                label: const Text('Lọc'),
                style: FilledButton.styleFrom(
                    minimumSize: const Size(80, 40), backgroundColor: ptitRed),
              ),
            ]),
            // Sprint 13 Batch C (2026-05-08): date range filter row.
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.date_range,
                  size: 16, color: context.textMuted),
              const SizedBox(width: 6),
              Text('Từ ngày:',
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => _pickDate(true),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10)),
                child: Text(
                  _dateFrom == null
                      ? 'Tất cả'
                      : DateFormat('dd/MM/yyyy').format(_dateFrom!),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Text('Đến ngày:',
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => _pickDate(false),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(120, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10)),
                child: Text(
                  _dateTo == null
                      ? 'Tất cả'
                      : DateFormat('dd/MM/yyyy').format(_dateTo!),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (_dateFrom != null || _dateTo != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Xóa filter ngày',
                  onPressed: _clearDates,
                  icon: Icon(Icons.clear, size: 16, color: context.textMuted),
                  constraints: const BoxConstraints(
                      minWidth: 36, minHeight: 36),
                  padding: EdgeInsets.zero,
                ),
              ],
            ]),
          ]),
        ),
        Expanded(
          child: asyncList.when(
            // Sprint 8b (2026-05-07): skeleton thay spinner.
            loading: () => const MCardListSkeleton(count: 6),
            error: (e, _) => Center(
                child: Text('Lỗi: ${FriendlyError.of(e)}',
                    style: const TextStyle(color: ptitRed))),
            data: (data) {
              final items =
                  (data['items'] as List).cast<Map<String, dynamic>>();
              final total = data['total'] as int;
              return Padding(
                padding: EdgeInsets.all(isMobile ? 14 : 24),
                child: items.isEmpty
                    ? const EmptyView(
                        icon: Icons.history,
                        title: 'Không có log nào',
                        subtitle: 'Audit log sẽ ghi nhận hành động admin/GV/BCN khi có thay đổi data.',
                      )
                    : MCard(
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        child: Column(children: [
                          Container(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            decoration: BoxDecoration(
                              color: Color(0xFFF9FAFB),
                              border: Border(
                                  bottom: BorderSide(color: context.cardBorder)),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(10)),
                            ),
                            child: Row(children: const [
                              SizedBox(width: 60, child: _Th('ID')),
                              SizedBox(width: 70, child: _Th('User')),
                              SizedBox(width: 100, child: _Th('Action')),
                              SizedBox(width: 130, child: _Th('Entity')),
                              SizedBox(width: 100, child: _Th('IP')),
                              Expanded(child: _Th('Details')),
                              SizedBox(width: 130, child: _Th('Time')),
                            ]),
                          ),
                          ...items.map((it) => _AuditRow(data: it)),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              border: Border(
                                  top: BorderSide(color: context.cardBorder)),
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(10)),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text('Tổng: $total log',
                                style: TextStyle(
                                    color: context.textMuted, fontSize: 12)),
                          ),
                        ]),
                      ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _Th extends StatelessWidget {
  final String label;
  const _Th(this.label);
  @override
  Widget build(BuildContext context) => Text(label,
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.textMuted,
          letterSpacing: 0.5));
}

class _AuditRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AuditRow({required this.data});

  Color _actionColor(BuildContext context, String? action) {
    switch (action) {
      case 'CREATE':
      case 'INSERT':
        return context.successGreen;
      case 'UPDATE':
      case 'PATCH':
        return context.infoBlue;
      case 'DELETE':
      case 'LOCK':
      case 'REJECT':
        return ptitRed;
      default:
        return context.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy HH:mm:ss');
    final created = DateTime.parse(data['created_at']);
    final action = data['action_type'] as String?;
    final details = data['details_json'];
    final detailsText = details == null
        ? '—'
        : const JsonEncoder().convert(details);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.cardBorder)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 60,
            child: Text('#${data['log_id']}',
                style: TextStyle(
                    fontSize: 11, color: context.textMuted))),
        SizedBox(
            width: 70,
            child: Text(
                data['user_id'] != null ? '#${data['user_id']}' : '—',
                style: TextStyle(fontSize: 11, color: context.textMuted))),
        SizedBox(
          width: 100,
          child: action == null
              ? Text('—',
                  style: TextStyle(fontSize: 11, color: context.textMuted))
              : Pill(
                  label: action,
                  color: _actionColor(context, action),
                  bg: _actionColor(context, action).withValues(alpha: 0.15),
                ),
        ),
        SizedBox(
          width: 130,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['entity_name'] ?? '',
                    style: TextStyle(
                        fontSize: 11,
                        color: context.textPrimary,
                        fontWeight: FontWeight.w600)),
                if (data['entity_id'] != null)
                  Text('#${data['entity_id']}',
                      style: TextStyle(
                          fontSize: 10, color: context.textMuted)),
              ]),
        ),
        SizedBox(
            width: 100,
            child: Text(data['ip_address'] ?? '—',
                style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: context.textMuted))),
        Expanded(
          child: Text(detailsText,
              style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: context.textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
        SizedBox(
            width: 130,
            child: Text(fmt.format(created),
                style: TextStyle(fontSize: 10, color: context.textMuted))),
      ]),
    );
  }
}
