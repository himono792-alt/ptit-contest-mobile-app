import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';

final configsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/configs');
  return res.data as List<dynamic>;
});

class ConfigsScreen extends ConsumerWidget {
  const ConfigsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(configsProvider);

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
                  Text('Cấu hình hệ thống',
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
              onPressed: () => ref.invalidate(configsProvider),
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
            data: (items) => Padding(
              padding: const EdgeInsets.all(24),
              child: items.isEmpty
                  ? const Center(
                      child: Text('Không có config nào',
                          style: TextStyle(color: textMuted)))
                  : MCard(
                      padding: EdgeInsets.zero,
                      margin: EdgeInsets.zero,
                      child: Column(children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF9FAFB),
                            border: Border(
                                bottom: BorderSide(color: cardBorder)),
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
                          decoration: const BoxDecoration(
                            border: Border(
                                top: BorderSide(color: cardBorder)),
                            borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(10)),
                          ),
                          alignment: Alignment.centerLeft,
                          child: Text('Tổng: ${items.length} config',
                              style: const TextStyle(
                                  color: textMuted, fontSize: 12)),
                        ),
                      ]),
                    ),
            ),
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
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder)),
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
                        style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textPrimary)),
                  ),
                  if (isSensitive) ...[
                    const SizedBox(width: 6),
                    Pill(label: 'SENSITIVE', color: ptitRed, bg: ptitRedSoft),
                  ],
                ]),
                if (data['description'] != null) ...[
                  const SizedBox(height: 3),
                  Text(data['description'],
                      style: const TextStyle(fontSize: 11, color: textMuted),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ]),
        ),
        Expanded(
          flex: 4,
          child: SelectableText(
            data['config_value']?.toString() ?? '—',
            style: const TextStyle(
                fontFamily: 'monospace', fontSize: 12, color: textPrimary),
            maxLines: 3,
          ),
        ),
        SizedBox(
            width: 80,
            child: Text(data['value_type'] ?? '',
                style: const TextStyle(fontSize: 11, color: textMuted))),
        Expanded(
          flex: 2,
          child: Text(fmt.format(updated),
              style: const TextStyle(fontSize: 11, color: textMuted)),
        ),
        SizedBox(
          width: 60,
          child: IconButton(
            tooltip: 'Sửa value',
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            onPressed: () => _openEdit(context, ref),
            icon: const Icon(Icons.edit_outlined, color: infoBlue),
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
                          const TextStyle(fontSize: 12, color: textMuted)),
                ),
              Text('Type: $type',
                  style:
                      const TextStyle(fontSize: 11, color: textMuted)),
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
