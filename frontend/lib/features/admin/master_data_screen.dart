import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';

// Sprint 13 Batch A (2026-05-08): bỏ autoDispose cho master data ít đổi
// (faculties/majors/classes). Avoid re-fetch khi user nav qua-lại tab.
// Admin invalidate sau create/edit/delete (đã có) → cache vẫn fresh.
final facultiesProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/faculties');
  return res.data as List<dynamic>;
});

final majorsProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/majors');
  return res.data as List<dynamic>;
});

final classesProvider =
    FutureProvider<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/classes');
  return res.data as List<dynamic>;
});

class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
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
                    Text('Khoa / Ngành / Lớp',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary)),
                  ],
                ),
              ),
            ]),
          ),
          Container(
            color: context.cardBg,
            child: TabBar(
              labelColor: ptitRed,
              unselectedLabelColor: context.textMuted,
              indicatorColor: ptitRed,
              labelStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Khoa (Faculties)'),
                Tab(text: 'Ngành (Majors)'),
                Tab(text: 'Lớp (Classes)'),
              ],
            ),
          ),
          const Expanded(
            child: TabBarView(children: [
              _FacultiesTab(),
              _MajorsTab(),
              _ClassesTab(),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ============================ FACULTIES ============================

class _FacultiesTab extends ConsumerWidget {
  const _FacultiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(facultiesProvider);
    return _SectionScaffold(
      onAdd: () => _openDialog(context, ref, null),
      onRefresh: () => ref.invalidate(facultiesProvider),
      addLabel: 'Tạo khoa',
      child: asyncList.when(
        // Sprint 8c (2026-05-07): skeleton thay spinner.
        loading: () => const MCardListSkeleton(count: 4),
        error: (e, _) => _ErrorView(error: e),
        data: (items) => MCard(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: Column(children: [
            _TableHeader(['ID', 'Code', 'Name', '']),
            ...items.map((it) => _TableRow(cells: [
                  '#${it['faculty_id']}',
                  it['faculty_code'] ?? '',
                  it['faculty_name'] ?? '',
                ], onEdit: () => _openDialog(context, ref, it as Map<String, dynamic>),
                  onDelete: () => _delete(context, ref, it['faculty_id'] as int))),
            _Footer(total: items.length, label: 'khoa'),
          ]),
        ),
      ),
    );
  }

  Future<void> _openDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? edit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _FacultyDialog(edit: edit),
    );
    if (ok == true) ref.invalidate(facultiesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa khoa?'),
        content: Text('Xóa faculty #$id? Sẽ fail nếu còn ngành/lớp.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: ptitRed),
              child: const Text('Xóa')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(apiClientProvider).dio.delete('/admin/faculties/$id');
      ref.invalidate(facultiesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${_msg(e)}')));
      }
    }
  }
}

class _FacultyDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? edit;
  const _FacultyDialog({required this.edit});
  @override
  ConsumerState<_FacultyDialog> createState() => _FacultyDialogState();
}

class _FacultyDialogState extends ConsumerState<_FacultyDialog> {
  late TextEditingController _code;
  late TextEditingController _name;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.edit?['faculty_code'] ?? '');
    _name = TextEditingController(text: widget.edit?['faculty_name'] ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.isEmpty || _name.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code và name bắt buộc')));
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      if (widget.edit == null) {
        await api.dio.post('/admin/faculties', data: {
          'faculty_code': _code.text.trim(),
          'faculty_name': _name.text.trim(),
        });
      } else {
        await api.dio.patch('/admin/faculties/${widget.edit!['faculty_id']}', data: {
          'faculty_code': _code.text.trim(),
          'faculty_name': _name.text.trim(),
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${_msg(e)}')));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.edit == null ? 'Tạo khoa' : 'Sửa khoa'),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _code, decoration: const InputDecoration(labelText: 'Code *')),
          const SizedBox(height: 8),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name *')),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: ptitRed),
          child: Text(widget.edit == null ? 'Tạo' : 'Lưu'),
        ),
      ],
    );
  }
}

// ============================ MAJORS ============================

class _MajorsTab extends ConsumerWidget {
  const _MajorsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(majorsProvider);
    return _SectionScaffold(
      onAdd: () => _openDialog(context, ref, null),
      onRefresh: () => ref.invalidate(majorsProvider),
      addLabel: 'Tạo ngành',
      child: asyncList.when(
        // Sprint 8c (2026-05-07): skeleton thay spinner.
        loading: () => const MCardListSkeleton(count: 4),
        error: (e, _) => _ErrorView(error: e),
        data: (items) => MCard(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: Column(children: [
            _TableHeader(['ID', 'Code', 'Name', 'Faculty', '']),
            ...items.map((it) => _TableRow(cells: [
                  '#${it['major_id']}',
                  it['major_code'] ?? '',
                  it['major_name'] ?? '',
                  it['faculty_id'] != null ? '#${it['faculty_id']}' : '—',
                ], onEdit: () => _openDialog(context, ref, it as Map<String, dynamic>),
                  onDelete: () => _delete(context, ref, it['major_id'] as int))),
            _Footer(total: items.length, label: 'ngành'),
          ]),
        ),
      ),
    );
  }

  Future<void> _openDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? edit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _MajorDialog(edit: edit),
    );
    if (ok == true) ref.invalidate(majorsProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(apiClientProvider).dio.delete('/admin/majors/$id');
      ref.invalidate(majorsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${_msg(e)}')));
      }
    }
  }
}

class _MajorDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? edit;
  const _MajorDialog({required this.edit});
  @override
  ConsumerState<_MajorDialog> createState() => _MajorDialogState();
}

class _MajorDialogState extends ConsumerState<_MajorDialog> {
  late TextEditingController _code;
  late TextEditingController _name;
  late TextEditingController _facultyId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.edit?['major_code'] ?? '');
    _name = TextEditingController(text: widget.edit?['major_name'] ?? '');
    _facultyId = TextEditingController(
        text: widget.edit?['faculty_id']?.toString() ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _facultyId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.isEmpty || _name.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code và name bắt buộc')));
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = {
        'major_code': _code.text.trim(),
        'major_name': _name.text.trim(),
        'faculty_id': _facultyId.text.isEmpty ? null : int.tryParse(_facultyId.text),
      };
      if (widget.edit == null) {
        await api.dio.post('/admin/majors', data: body);
      } else {
        await api.dio.patch('/admin/majors/${widget.edit!['major_id']}', data: body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${_msg(e)}')));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.edit == null ? 'Tạo ngành' : 'Sửa ngành'),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _code, decoration: const InputDecoration(labelText: 'Code *')),
          const SizedBox(height: 8),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name *')),
          const SizedBox(height: 8),
          TextField(
              controller: _facultyId,
              decoration: const InputDecoration(labelText: 'Faculty ID (optional)'),
              keyboardType: TextInputType.number),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: ptitRed),
          child: Text(widget.edit == null ? 'Tạo' : 'Lưu'),
        ),
      ],
    );
  }
}

// ============================ CLASSES ============================

class _ClassesTab extends ConsumerWidget {
  const _ClassesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(classesProvider);
    return _SectionScaffold(
      onAdd: () => _openDialog(context, ref, null),
      onRefresh: () => ref.invalidate(classesProvider),
      addLabel: 'Tạo lớp',
      child: asyncList.when(
        // Sprint 8c (2026-05-07): skeleton thay spinner.
        loading: () => const MCardListSkeleton(count: 4),
        error: (e, _) => _ErrorView(error: e),
        data: (items) => MCard(
          padding: EdgeInsets.zero,
          margin: EdgeInsets.zero,
          child: Column(children: [
            _TableHeader(['ID', 'Code', 'Name', 'Faculty', 'Major', '']),
            ...items.map((it) => _TableRow(cells: [
                  '#${it['class_id']}',
                  it['class_code'] ?? '',
                  it['class_name'] ?? '',
                  it['faculty_id'] != null ? '#${it['faculty_id']}' : '—',
                  it['major_id'] != null ? '#${it['major_id']}' : '—',
                ], onEdit: () => _openDialog(context, ref, it as Map<String, dynamic>),
                  onDelete: () => _delete(context, ref, it['class_id'] as int))),
            _Footer(total: items.length, label: 'lớp'),
          ]),
        ),
      ),
    );
  }

  Future<void> _openDialog(
      BuildContext context, WidgetRef ref, Map<String, dynamic>? edit) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ClassDialog(edit: edit),
    );
    if (ok == true) ref.invalidate(classesProvider);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, int id) async {
    try {
      await ref.read(apiClientProvider).dio.delete('/admin/classes/$id');
      ref.invalidate(classesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${_msg(e)}')));
      }
    }
  }
}

class _ClassDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic>? edit;
  const _ClassDialog({required this.edit});
  @override
  ConsumerState<_ClassDialog> createState() => _ClassDialogState();
}

class _ClassDialogState extends ConsumerState<_ClassDialog> {
  late TextEditingController _code;
  late TextEditingController _name;
  late TextEditingController _facultyId;
  late TextEditingController _majorId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.edit?['class_code'] ?? '');
    _name = TextEditingController(text: widget.edit?['class_name'] ?? '');
    _facultyId = TextEditingController(text: widget.edit?['faculty_id']?.toString() ?? '');
    _majorId = TextEditingController(text: widget.edit?['major_id']?.toString() ?? '');
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _facultyId.dispose();
    _majorId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_code.text.isEmpty || _name.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code và name bắt buộc')));
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = {
        'class_code': _code.text.trim(),
        'class_name': _name.text.trim(),
        'faculty_id': _facultyId.text.isEmpty ? null : int.tryParse(_facultyId.text),
        'major_id': _majorId.text.isEmpty ? null : int.tryParse(_majorId.text),
      };
      if (widget.edit == null) {
        await api.dio.post('/admin/classes', data: body);
      } else {
        await api.dio.patch('/admin/classes/${widget.edit!['class_id']}', data: body);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${_msg(e)}')));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.edit == null ? 'Tạo lớp' : 'Sửa lớp'),
      content: SizedBox(
        width: 360,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _code, decoration: const InputDecoration(labelText: 'Code *')),
          const SizedBox(height: 8),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name *')),
          const SizedBox(height: 8),
          TextField(
              controller: _facultyId,
              decoration: const InputDecoration(labelText: 'Faculty ID (optional)'),
              keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(
              controller: _majorId,
              decoration: const InputDecoration(labelText: 'Major ID (optional)'),
              keyboardType: TextInputType.number),
        ]),
      ),
      actions: [
        TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Hủy')),
        FilledButton(
          onPressed: _busy ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: ptitRed),
          child: Text(widget.edit == null ? 'Tạo' : 'Lưu'),
        ),
      ],
    );
  }
}

// ============================ SHARED WIDGETS ============================

class _SectionScaffold extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onRefresh;
  final String addLabel;
  final Widget child;
  const _SectionScaffold(
      {required this.onAdd,
      required this.onRefresh,
      required this.addLabel,
      required this.child});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Padding(
      padding: EdgeInsets.all(isMobile ? 14 : 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 18),
            label: Text(addLabel),
            style: FilledButton.styleFrom(
                minimumSize: const Size(140, 38), backgroundColor: ptitRed),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Refresh',
            icon: Icon(Icons.refresh, color: context.textMuted),
            onPressed: onRefresh,
          ),
        ]),
        const SizedBox(height: 14),
        Expanded(child: SingleChildScrollView(child: child)),
      ]),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<String> labels;
  const _TableHeader(this.labels);
  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      final isLast = i == labels.length - 1;
      final text = Text(labels[i],
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: context.textMuted,
              letterSpacing: 0.5));
      widgets.add(isLast
          ? SizedBox(width: 100, child: text)
          : Expanded(child: text));
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border(bottom: BorderSide(color: context.cardBorder)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      child: Row(children: widgets),
    );
  }
}

class _TableRow extends StatelessWidget {
  final List<String> cells;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TableRow({required this.cells, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.cardBorder)),
      ),
      child: Row(children: [
        ...cells.map((c) => Expanded(
              child: Text(c,
                  style: TextStyle(fontSize: 12, color: context.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            )),
        SizedBox(
          width: 100,
          child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            IconButton(
              tooltip: 'Sửa',
              iconSize: 18,
              visualDensity: VisualDensity.compact, constraints: const BoxConstraints(minWidth: 44, minHeight: 44), // P0 #4 hit area ≥44 (WCAG 2.5.5)
              onPressed: onEdit,
              icon: Icon(Icons.edit_outlined, color: context.infoBlue),
            ),
            IconButton(
              tooltip: 'Xóa',
              iconSize: 18,
              visualDensity: VisualDensity.compact, constraints: const BoxConstraints(minWidth: 44, minHeight: 44), // P0 #4 hit area ≥44 (WCAG 2.5.5)
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: ptitRed),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Footer extends StatelessWidget {
  final int total;
  final String label;
  const _Footer({required this.total, required this.label});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.cardBorder)),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        alignment: Alignment.centerLeft,
        child: Text('Tổng: $total $label',
            style: TextStyle(color: context.textMuted, fontSize: 12)),
      );
}

class _ErrorView extends StatelessWidget {
  final Object error;
  const _ErrorView({required this.error});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Lỗi: ${_msg(error)}',
            style: const TextStyle(color: ptitRed)),
      ),
    );
  }
}

String _msg(Object e) => e is DioException
    ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
    : '$e';
