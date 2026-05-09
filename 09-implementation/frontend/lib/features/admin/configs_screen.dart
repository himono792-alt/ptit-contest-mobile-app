import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/pill.dart';

// Sprint 13 Batch A (2026-05-08): bỏ autoDispose cho configs ít đổi.
// Admin invalidate sau PATCH (đã wire) → fresh cache automatic.
final configsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/configs');
  return res.data as List<dynamic>;
});

class ConfigsScreen extends ConsumerWidget {
  const ConfigsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(configsProvider);
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
                  Text('Cấu hình hệ thống',
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
              onPressed: () => ref.invalidate(configsProvider),
            ),
          ]),
        ),
        // Sprint 14 P2.1 (2026-05-08): _BackupRestoreCard tách ra sidebar
        // item riêng (Backup & Restore — slug=backup) trong admin_shell. Configs
        // screen giờ chỉ list configs để IA cleaner.
        Expanded(
          child: asyncList.when(
            // Sprint 8c (2026-05-07): skeleton thay spinner.
            loading: () => const MCardListSkeleton(count: 5),
            error: (e, _) => Center(
                child: Text('Lỗi: ${_msg(e)}',
                    style: const TextStyle(color: ptitRed))),
            data: (items) => SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 14 : 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Sprint 21 hotfix (2026-05-09): maintenance utilities card.
                    const _MaintenanceCard(),
                    const SizedBox(height: 16),
                    items.isEmpty
                  ? Center(
                      child: Text('Không có config nào',
                          style: TextStyle(color: context.textMuted)))
                  : MCard(
                      padding: EdgeInsets.zero,
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          decoration: BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            border: Border(
                                bottom: BorderSide(color: context.cardBorder)),
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(10)),
                          ),
                          child: Row(children: const [
                            Expanded(flex: 3, child: _Th('Key')),
                            Expanded(flex: 4, child: _Th('Value')),
                            SizedBox(width: 80, child: _Th('Type')),
                            Expanded(flex: 2, child: _Th('Updated')),
                            SizedBox(width: 60, child: _Th('')),
                          ]),
                        ),
                        ...items.map((it) =>
                            _ConfigRow(data: it as Map<String, dynamic>)),
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
                          child: Text('Tổng: ${items.length} config',
                              style: TextStyle(
                                  color: context.textMuted, fontSize: 12)),
                        ),
                      ]),
                    ),
                  ]),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Sprint 21 hotfix (2026-05-09): card maintenance utilities trong ConfigsScreen.
/// Hiện tại có 1 button: backfill `host_faculty_id` cho contests legacy
/// (BCN không thấy trong queue duyệt vì host_faculty_id NULL).
class _MaintenanceCard extends ConsumerStatefulWidget {
  const _MaintenanceCard();
  @override
  ConsumerState<_MaintenanceCard> createState() => _MaintenanceCardState();
}

class _MaintenanceCardState extends ConsumerState<_MaintenanceCard> {
  bool _busy = false;

  Future<void> _backfill() async {
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/admin/backfill-host-faculty');
      final data = res.data as Map<String, dynamic>;
      final updated = data['updated_count'] as int? ?? 0;
      final skipped = data['skipped_count'] as int? ?? 0;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '✓ Backfill xong: cập nhật $updated contests, bỏ qua $skipped')),
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? '${e.response?.data['detail']}'
          : (e.message ?? '');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.build_circle_outlined, size: 18, color: context.warnOrange),
          const SizedBox(width: 8),
          Text('Bảo trì dữ liệu',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.2)),
        ]),
        const SizedBox(height: 6),
        Text(
            'Backfill `host_faculty_id` cho cuộc thi legacy (NULL → faculty của creator). '
            'Chạy 1 lần là đủ. BCN sau đó thấy được trong queue duyệt QĐ1.',
            style: TextStyle(fontSize: 12, color: context.textMuted, height: 1.5)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.cleaning_services_outlined, size: 18),
            label: Text(_busy
                ? 'Đang chạy...'
                : 'Backfill host_faculty_id cho contests'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: context.warnOrange,
            ),
            onPressed: _busy ? null : _backfill,
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

class _ConfigRow extends ConsumerWidget {
  final Map<String, dynamic> data;
  const _ConfigRow({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    final isSensitive = data['is_sensitive'] as bool? ?? false;
    final updated = DateTime.parse(data['updated_at']);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.cardBorder)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          flex: 3,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Flexible(
                    child: SelectableText(data['config_key'] ?? '',
                        style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.textPrimary)),
                  ),
                  if (isSensitive) ...[
                    const SizedBox(width: 6),
                    Pill(label: 'SENSITIVE', color: ptitRed, bg: context.ptitRedSoft),
                  ],
                ]),
                if (data['description'] != null) ...[
                  const SizedBox(height: 3),
                  Text(data['description'],
                      style: TextStyle(fontSize: 11, color: context.textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ]),
        ),
        Expanded(
          flex: 4,
          child: SelectableText(
            data['config_value']?.toString() ?? '—',
            style: TextStyle(
                fontFamily: 'monospace', fontSize: 12, color: context.textPrimary),
            maxLines: 3,
          ),
        ),
        SizedBox(
            width: 80,
            child: Text(data['value_type'] ?? '',
                style: TextStyle(fontSize: 11, color: context.textMuted))),
        Expanded(
          flex: 2,
          child: Text(fmt.format(updated),
              style: TextStyle(fontSize: 11, color: context.textMuted)),
        ),
        SizedBox(
          width: 60,
          child: IconButton(
            tooltip: 'Sửa value',
            iconSize: 18,
            visualDensity: VisualDensity.compact, constraints: const BoxConstraints(minWidth: 44, minHeight: 44), // P0 #4 hit area ≥44 (WCAG 2.5.5)
            onPressed: () => _openEdit(context, ref),
            icon: Icon(Icons.edit_outlined, color: context.infoBlue),
          ),
        ),
      ]),
    );
  }

  Future<void> _openEdit(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfigEditDialog(data: data),
    );
    if (ok == true) ref.invalidate(configsProvider);
  }
}

class _ConfigEditDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  const _ConfigEditDialog({required this.data});
  @override
  ConsumerState<_ConfigEditDialog> createState() => _ConfigEditDialogState();
}

class _ConfigEditDialogState extends ConsumerState<_ConfigEditDialog> {
  late TextEditingController _value;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _value = TextEditingController(
        text: widget.data['config_value']?.toString() ?? '');
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.patch('/admin/configs/${widget.data['config_key']}',
          data: {'config_value': _value.text});
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: ${_msg(e)}')));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.data['value_type'] ?? 'STRING';
    return AlertDialog(
      title: Text('Sửa ${widget.data['config_key']}'),
      content: SizedBox(
        width: 480,
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.data['description'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(widget.data['description'],
                      style:
                          TextStyle(fontSize: 12, color: context.textMuted)),
                ),
              Text('Type: $type',
                  style:
                      TextStyle(fontSize: 11, color: context.textMuted)),
              const SizedBox(height: 8),
              TextField(
                controller: _value,
                maxLines: type == 'JSON' ? 6 : 1,
                decoration: const InputDecoration(labelText: 'Value *'),
              ),
            ]),
      ),
      actions: [
        TextButton(
            onPressed:
                _busy ? null : () => Navigator.pop(context, false),
            child: const Text('Hủy')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: ptitRed),
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

String _msg(Object e) => e is DioException
    ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
    : '$e';

// Sprint 6 (2026-05-07): AD-04 — Backup / Restore admin actions.
//
// Backend wrap pg_dump / pg_restore CLI qua POST /admin/backup, POST /admin/restore.
// Backup: response { filename, size_mb, created_at } — chỉ cần show snackbar.
// Restore: cần upload file backup .sql, confirm 2 lần (không thể hoàn tác).
//
// Để giữ scope sprint nhỏ, version đầu chỉ implement Backup (POST không body) và
// nút Restore dạng placeholder mở dialog hướng dẫn admin chạy CLI trên server
// (an toàn hơn — restore qua HTTP upload là rủi ro lớn).
class _BackupRestoreCard extends ConsumerStatefulWidget {
  @override
  ConsumerState<_BackupRestoreCard> createState() => _BackupRestoreCardState();
}

class _BackupRestoreCardState extends ConsumerState<_BackupRestoreCard> {
  bool _busy = false;
  Map<String, dynamic>? _lastBackup;

  Future<void> _doBackup() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tạo bản sao lưu DB'),
        content: const Text(
            'Hệ thống sẽ chạy pg_dump trên schema ptit_contest. '
            'Quá trình này có thể mất 1-3 phút tùy size DB.\n\n'
            'File backup .sql sẽ lưu vào /backups trên server.\n\n'
            'Tiếp tục?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: ptitRed),
              child: const Text('Tạo backup')),
        ],
      ),
    );
    if (ok != true) return;

    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.post('/admin/backup');
      if (!mounted) return;
      setState(() {
        _lastBackup = res.data as Map<String, dynamic>;
        _busy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Backup thành công: ${_lastBackup?['filename'] ?? 'completed'}'),
        backgroundColor: context.successGreen,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi backup: ${_msg(e)}')));
    }
  }

  Future<void> _showRestoreInfo() async {
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Khôi phục từ backup'),
        content: const SingleChildScrollView(
          child: Text(
            'CẢNH BÁO: Restore sẽ ghi đè TOÀN BỘ dữ liệu hiện tại — '
            'không thể hoàn tác.\n\n'
            'Vì lý do an toàn, restore chỉ có thể chạy trực tiếp trên server '
            'qua CLI bằng tài khoản DBA:\n\n'
            '  psql -U postgres -d ptit_contest \\\n'
            '       -f /backups/<filename>.sql\n\n'
            'Liên hệ admin DB để được hỗ trợ. Endpoint POST /admin/restore '
            'chỉ available trong môi trường staging.',
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đã hiểu')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.backup_outlined,
                size: 16, color: context.textPrimary),
            const SizedBox(width: 8),
            Text('Sao lưu / Khôi phục DB (AD-04)',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary)),
          ]),
          const SizedBox(height: 6),
          Text(
            'pg_dump schema ptit_contest. File backup lưu trên server (volume /backups). '
            'Restore yêu cầu can thiệp DBA qua CLI.',
            style: TextStyle(fontSize: 11, color: context.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 10, runSpacing: 10, children: [
            FilledButton.icon(
              onPressed: _busy ? null : _doBackup,
              icon: _busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_outlined, size: 16),
              label: Text(_busy ? 'Đang backup...' : 'Tạo backup ngay'),
              style: FilledButton.styleFrom(
                backgroundColor: context.successGreen,
                foregroundColor: Colors.white,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _showRestoreInfo,
              icon: const Icon(Icons.history, size: 16),
              label: const Text('Khôi phục backup...'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ptitRed,
                side: BorderSide(color: context.cardBorder),
              ),
            ),
          ]),
          if (_lastBackup != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.successSoft,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Row(children: [
                Icon(Icons.check_circle,
                    size: 14, color: context.successGreen),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Backup gần nhất: ${_lastBackup!['filename'] ?? 'unknown'} '
                    '(${_lastBackup!['size_mb'] ?? '?'} MB)',
                    style: TextStyle(
                        fontSize: 11.5, color: context.textPrimary),
                  ),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }
}
