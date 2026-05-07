import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';

final approvalTypeFilterProvider = StateProvider<String?>((_) => null);

final pendingApprovalsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final type = ref.watch(approvalTypeFilterProvider);
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/me/pending-approvals',
      queryParameters: type != null ? {'type_filter': type} : null);
  return res.data as List<dynamic>;
});

class ApprovalQueueScreen extends ConsumerWidget {
  const ApprovalQueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(pendingApprovalsProvider);
    final type = ref.watch(approvalTypeFilterProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: context.appBg,
      body: Column(children: [
        // Top bar
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
                  Text('BCN', style: TextStyle(color: context.textMuted, fontSize: 11)),
                  SizedBox(height: 2),
                  Text('Phê duyệt đề xuất',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                ],
              ),
            ),
          ]),
        ),
        // Filter
        Container(
          padding: EdgeInsets.fromLTRB(isMobile ? 14 : 32, isMobile ? 12 : 18, isMobile ? 14 : 32, 0),
          child: Row(children: [
            SizedBox(
              width: 280,
              height: 40,
              child: DropdownButtonFormField<String?>(
                value: type,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Loại đề xuất',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(
                      value: 'CONTEST_PROPOSAL',
                      child: Text('QĐ1 — Đề xuất cuộc thi')),
                  DropdownMenuItem(
                      value: 'CONTEST_RESULT',
                      child: Text('QĐ2 — Kết quả cuộc thi')),
                ],
                onChanged: (v) =>
                    ref.read(approvalTypeFilterProvider.notifier).state = v,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: context.textMuted),
              onPressed: () => ref.invalidate(pendingApprovalsProvider),
            ),
          ]),
        ),
        // Body
        Expanded(
          child: asyncList.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => _ErrorView(
                error: e,
                onRetry: () => ref.invalidate(pendingApprovalsProvider)),
            data: (items) => items.isEmpty
                ? const _EmptyView()
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(isMobile ? 14 : 24, 16, isMobile ? 14 : 24, 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) =>
                        _ApprovalCard(data: items[i] as Map<String, dynamic>),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _ApprovalCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  const _ApprovalCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    final submittedAt = DateTime.parse(data['submitted_at']);
    final isQd1 = data['target_type'] == 'CONTEST_PROPOSAL';

    return MCard(
      onTap: () => _openDetailDialog(context, ref, data['approval_id'] as int),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                data['contest_title'] ?? '#${data['contest_id']}',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Pill(
              label: isQd1 ? 'QĐ1 Đề xuất' : 'QĐ2 Kết quả',
              color: isQd1 ? context.infoBlue : context.warnOrange,
              bg: isQd1 ? context.infoSoft : context.warnSoft,
            ),
            const SizedBox(width: 6),
            Pill.status(data['status'] as String),
          ]),
          const SizedBox(height: 6),
          Text(
            'Slug: ${data['contest_slug'] ?? '—'} · Vòng revision #${data['revision_round']} · '
            'Submitted by user #${data['submitted_by']} lúc ${fmt.format(submittedAt)}',
            style: TextStyle(fontSize: 12, color: context.textMuted),
          ),
          if ((data['submission_note'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.appBg,
                border: Border.all(color: context.cardBorder),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text('“${data['submission_note']}”',
                  style: TextStyle(fontSize: 12, color: context.textPrimary)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openDetailDialog(
      BuildContext context, WidgetRef ref, int approvalId) async {
    await showDialog(
      context: context,
      builder: (_) => _ApprovalDetailDialog(approvalId: approvalId),
    );
    ref.invalidate(pendingApprovalsProvider);
  }
}

class _ApprovalDetailDialog extends ConsumerStatefulWidget {
  final int approvalId;
  const _ApprovalDetailDialog({required this.approvalId});

  @override
  ConsumerState<_ApprovalDetailDialog> createState() =>
      _ApprovalDetailDialogState();
}

class _ApprovalDetailDialogState
    extends ConsumerState<_ApprovalDetailDialog> {
  final _commentCtrl = TextEditingController();
  bool _busy = false;
  Map<String, dynamic>? _detail;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio.get('/approvals/${widget.approvalId}');
      setState(() => _detail = res.data as Map<String, dynamic>);
    } catch (e) {
      setState(() => _loadError = _msgOf(e));
    }
  }

  String _msgOf(Object e) => e is DioException
      ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
      : '$e';

  Future<void> _decide(String action) async {
    if (action != 'approve' && _commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần nhập comment khi reject/request_revision')),
      );
      return;
    }
    setState(() => _busy = true);
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.post('/approvals/${widget.approvalId}/decide', data: {
        'action': action,
        if (_commentCtrl.text.trim().isNotEmpty) 'comment': _commentCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã ${_actionLabel(action)} thành công')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${_msgOf(e)}')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _actionLabel(String a) => switch (a) {
        'approve' => 'phê duyệt',
        'reject' => 'từ chối',
        'request_revision' => 'yêu cầu chỉnh sửa',
        _ => a,
      };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 700),
        child: _detail == null
            ? SizedBox(
                width: 720,
                height: 240,
                child: Center(
                  child: _loadError == null
                      ? const CircularProgressIndicator(color: ptitRed)
                      : Text('Lỗi: $_loadError',
                          style: const TextStyle(color: ptitRed)),
                ),
              )
            : _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final d = _detail!;
    final fmt = DateFormat('dd/MM/yy HH:mm');
    final isQd1 = d['target_type'] == 'CONTEST_PROPOSAL';
    final snapshot = d['snapshot_json'];
    final snapshotPretty = snapshot == null
        ? '— (no snapshot)'
        : const JsonEncoder.withIndent('  ').convert(snapshot);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.cardBorder)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d['contest_title'] ?? '#${d['contest_id']}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(children: [
                Pill(
                  label: isQd1 ? 'QĐ1 Đề xuất' : 'QĐ2 Kết quả',
                  color: isQd1 ? context.infoBlue : context.warnOrange,
                  bg: isQd1 ? context.infoSoft : context.warnSoft,
                ),
                const SizedBox(width: 6),
                Pill.status(d['status'] as String),
                const SizedBox(width: 6),
                Text('Vòng revision #${d['revision_round']}',
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
              ]),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ]),
      ),
      // Body scrollable
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _kv(context, 'Submitted by', 'User #${d['submitted_by']}'),
            _kv(context, 'Submitted at', fmt.format(DateTime.parse(d['submitted_at']))),
            if ((d['submission_note'] ?? '').toString().isNotEmpty)
              _kv(context, 'BTC note', d['submission_note']),
            if (d['reviewed_by'] != null)
              _kv(context, 'Last reviewed by', 'User #${d['reviewed_by']}'),
            if (d['bcn_comment'] != null)
              _kv(context, 'Last BCN comment', d['bcn_comment']),
            const SizedBox(height: 12),
            Text('Snapshot dữ liệu đã submit',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.textMuted, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border.all(color: context.cardBorder),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: SelectableText(
                snapshotPretty,
                style: TextStyle(
                    fontFamily: 'monospace', fontSize: 11, color: context.textPrimary, height: 1.4),
              ),
            ),
            const SizedBox(height: 18),
            Text('Comment của BCN (bắt buộc nếu reject hoặc request revision)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.textPrimary)),
            const SizedBox(height: 6),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Nhập lý do hoặc yêu cầu chỉnh sửa...',
              ),
            ),
          ]),
        ),
      ),
      // Footer actions
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.cardBorder)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          // Sprint 5 a11y: 3 BCN action buttons với label rõ ràng cho screen reader
          Semantics(
            label: 'Reject — từ chối đề xuất',
            button: true,
            enabled: !_busy,
            hint: 'Cần nhập comment lý do từ chối',
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _decide('reject'),
              icon: const Icon(Icons.close, size: 16, color: ptitRed),
              label: const Text('Reject', style: TextStyle(color: ptitRed)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(120, 38),
                side: const BorderSide(color: ptitRed),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            label: 'Request revision — yêu cầu chỉnh sửa',
            button: true,
            enabled: !_busy,
            hint: 'Trả về cho BTC sửa, cần nhập comment hướng dẫn',
            child: OutlinedButton.icon(
              onPressed: _busy ? null : () => _decide('request_revision'),
              icon: Icon(Icons.history, size: 16, color: context.warnOrange),
              label: Text('Request revision',
                  style: TextStyle(color: context.warnOrange)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(160, 38),
                side: BorderSide(color: context.warnOrange),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            label: 'Approve — phê duyệt đề xuất',
            button: true,
            enabled: !_busy,
            hint: 'Chấp nhận đề xuất, contest được publish',
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _decide('approve'),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(120, 38),
                backgroundColor: context.successGreen,
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _kv(BuildContext context, String k, dynamic v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 140,
            child: Text(k,
                style: TextStyle(
                    fontSize: 11, color: context.textMuted, letterSpacing: 0.3)),
          ),
          Expanded(
              child: Text('$v',
                  style: TextStyle(
                      fontSize: 13, color: context.textPrimary, height: 1.4))),
        ]),
      );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox_outlined, size: 56, color: context.textMuted),
            SizedBox(height: 12),
            Text('Không có đề xuất nào đang chờ duyệt',
                style: TextStyle(color: context.textMuted, fontSize: 13)),
          ]),
        ),
      );
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
              style: TextStyle(color: context.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ]),
      ),
    );
  }
}
