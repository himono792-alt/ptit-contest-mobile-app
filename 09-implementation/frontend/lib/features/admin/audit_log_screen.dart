import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';

class _AuditParams {
  final String? actionType;
  final String? entityName;
  final int? userId;
  const _AuditParams({this.actionType, this.entityName, this.userId});
  _AuditParams copyWith(
          {String? actionType,
          String? entityName,
          int? userId,
          bool clearActionType = false,
          bool clearEntity = false,
          bool clearUserId = false}) =>
      _AuditParams(
        actionType: clearActionType ? null : (actionType ?? this.actionType),
        entityName: clearEntity ? null : (entityName ?? this.entityName),
        userId: clearUserId ? null : (userId ?? this.userId),
      );
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

  void _applyFilter() {
    final params = _AuditParams(
      actionType: _actionCtrl.text.isEmpty ? null : _actionCtrl.text.trim(),
      entityName: _entityCtrl.text.isEmpty ? null : _entityCtrl.text.trim(),
      userId: _userIdCtrl.text.isEmpty ? null : int.tryParse(_userIdCtrl.text),
    );
    ref.read(auditParamsProvider.notifier).state = params;
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(auditLogsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(children: [
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
                  Text('Quản trị',
                      style: TextStyle(color: textMuted, fontSize: 11)),
                  SizedBox(height: 2),
                  Text('Audit log',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, color: textMuted),
              onPressed: () => ref.invalidate(auditLogsProvider),
            ),
          ]),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(32, 18, 32, 0),
          child: Row(children: [
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
        ),
        Expanded(
          child: asyncList.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => Center(
                child: Text('Lỗi: ${_msg(e)}',
                    style: const TextStyle(color: ptitRed))),
            data: (data) {
              final items =
                  (data['items'] as List).cast<Map<String, dynamic>>();
              final total = data['total'] as int;
              return Padding(
                padding: const EdgeInsets.all(24),
                child: items.isEmpty
                    ? const Center(
                        child: Text('Không có log nào',
                            style: TextStyle(color: textMuted)))
                    : MCard(
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        child: Column(children: [
                          Container(
                            padding:
                                const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9FAFB),
                              border: Border(
                                  bottom: BorderSide(color: cardBorder)),
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
                            decoration: const BoxDecoration(
                              border: Border(
                                  top: BorderSide(color: cardBorder)),
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(10)),
                            ),
                            alignment: Alignment.centerLeft,
                            child: Text('Tổng: $total log',
                                style: const TextStyle(
                                    color: textMuted, fontSize: 12)),
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
      style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textMuted,
          letterSpacing: 0.5));
}

class _AuditRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AuditRow({required this.data});

  Color _actionColor(String? action) {
    switch (action) {
      case 'CREATE':
      case 'INSERT':
        return successGreen;
      case 'UPDATE':
      case 'PATCH':
        return infoBlue;
      case 'DELETE':
      case 'LOCK':
      case 'REJECT':
        return ptitRed;
      default:
        return textMuted;
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 60,
            child: Text('#${data['log_id']}',
                style: const TextStyle(
                    fontSize: 11, color: textMuted))),
        SizedBox(
            width: 70,
            child: Text(
                data['user_id'] != null ? '#${data['user_id']}' : '—',
                style: const TextStyle(fontSize: 11, color: textMuted))),
        SizedBox(
          width: 100,
          child: action == null
              ? const Text('—',
                  style: TextStyle(fontSize: 11, color: textMuted))
              : Pill(
                  label: action,
                  color: _actionColor(action),
                  bg: _actionColor(action).withValues(alpha: 0.15),
                ),
        ),
        SizedBox(
          width: 130,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['entity_name'] ?? '',
                    style: const TextStyle(
                        fontSize: 11,
                        color: textPrimary,
                        fontWeight: FontWeight.w600)),
                if (data['entity_id'] != null)
                  Text('#${data['entity_id']}',
                      style: const TextStyle(
                          fontSize: 10, color: textMuted)),
              ]),
        ),
        SizedBox(
            width: 100,
            child: Text(data['ip_address'] ?? '—',
                style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: textMuted))),
        Expanded(
          child: Text(detailsText,
              style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: textPrimary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
        SizedBox(
            width: 130,
            child: Text(fmt.format(created),
                style: const TextStyle(fontSize: 10, color: textMuted))),
      ]),
    );
  }
}

String _msg(Object e) => e is DioException
    ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
    : '$e';
