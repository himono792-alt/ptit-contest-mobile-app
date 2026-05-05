import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';

const _ALL_ROLES = ['ADMIN', 'ORGANIZER', 'JUDGE', 'HOD', 'STUDENT'];

class _UsersParams {
  final String? roleFilter;
  final String? statusFilter;
  final String? q;
  const _UsersParams({this.roleFilter, this.statusFilter, this.q});
  _UsersParams copyWith(
          {String? roleFilter,
          String? statusFilter,
          String? q,
          bool clearRole = false,
          bool clearStatus = false,
          bool clearQ = false}) =>
      _UsersParams(
        roleFilter: clearRole ? null : (roleFilter ?? this.roleFilter),
        statusFilter:
            clearStatus ? null : (statusFilter ?? this.statusFilter),
        q: clearQ ? null : (q ?? this.q),
      );
}

final usersParamsProvider =
    StateProvider<_UsersParams>((_) => const _UsersParams());

final usersListProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final p = ref.watch(usersParamsProvider);
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/users', queryParameters: {
    'size': 100,
    if (p.roleFilter != null) 'role': p.roleFilter,
    if (p.statusFilter != null) 'status': p.statusFilter,
    if (p.q != null && p.q!.isNotEmpty) 'q': p.q,
  });
  return res.data as Map<String, dynamic>;
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(usersListProvider);
    final params = ref.watch(usersParamsProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(children: [
        // Top bar
        if (!isMobile) Container(
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
                  Text('Quản lý user',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: textPrimary)),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _openBulkImportDialog(),
              icon: const Icon(Icons.upload_file, size: 16),
              label: const Text('Import CSV SV'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(140, 38)),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _openCreateDialog(),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Tạo user'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(140, 38),
                  backgroundColor: ptitRed),
            ),
          ]),
        ),
        // Filters
        Container(
          padding: EdgeInsets.fromLTRB(isMobile ? 14 : 32, isMobile ? 12 : 18, isMobile ? 14 : 32, 0),
          child: Row(children: [
            Expanded(
              child: SizedBox(
                height: 40,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Tìm theo email hoặc tên...',
                    prefixIcon: Icon(Icons.search, size: 18),
                    isDense: true,
                  ),
                  onSubmitted: (v) => ref
                      .read(usersParamsProvider.notifier)
                      .state = params.copyWith(q: v, clearQ: v.isEmpty),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 180,
              height: 40,
              child: DropdownButtonFormField<String?>(
                value: params.roleFilter,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Tất cả')),
                  ..._ALL_ROLES.map(
                      (r) => DropdownMenuItem(value: r, child: Text(r))),
                ],
                onChanged: (v) =>
                    ref.read(usersParamsProvider.notifier).state =
                        params.copyWith(roleFilter: v, clearRole: v == null),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 160,
              height: 40,
              child: DropdownButtonFormField<String?>(
                value: params.statusFilter,
                isDense: true,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Tất cả')),
                  DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE')),
                  DropdownMenuItem(value: 'LOCKED', child: Text('LOCKED')),
                  DropdownMenuItem(value: 'DELETED', child: Text('DELETED')),
                ],
                onChanged: (v) => ref
                    .read(usersParamsProvider.notifier)
                    .state = params.copyWith(
                  statusFilter: v,
                  clearStatus: v == null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh, color: textMuted),
              onPressed: () => ref.invalidate(usersListProvider),
            ),
          ]),
        ),
        Expanded(
          child: asyncList.when(
            loading: () => const Center(
                child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => _ErrorView(
                error: e, onRetry: () => ref.invalidate(usersListProvider)),
            data: (data) {
              final items =
                  (data['items'] as List).cast<Map<String, dynamic>>();
              final total = data['total'] as int;
              return Padding(
                padding: EdgeInsets.all(isMobile ? 14 : 24),
                child: items.isEmpty
                    ? const Center(
                        child: Text('Không có user',
                            style: TextStyle(color: textMuted)))
                    : MCard(
                        padding: EdgeInsets.zero,
                        margin: EdgeInsets.zero,
                        child: _UsersTable(
                            items: items, total: total, refresh: () {
                          ref.invalidate(usersListProvider);
                        }),
                      ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _openCreateDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _CreateUserDialog(),
    );
    if (ok == true) ref.invalidate(usersListProvider);
  }

  Future<void> _openBulkImportDialog() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => const _BulkImportDialog(),
    );
    if (ok == true) ref.invalidate(usersListProvider);
  }
}

// ---------- Bulk Import CSV Dialog ----------
//
// Admin paste CSV vào textarea (header bắt buộc:
//   student_code,ptit_email,full_name,faculty_code,major_code,class_code).
// Parse client-side, POST /admin/students/import body { rows: [...] }.

class _BulkImportDialog extends ConsumerStatefulWidget {
  const _BulkImportDialog();
  @override
  ConsumerState<_BulkImportDialog> createState() => _BulkImportDialogState();
}

class _BulkImportDialogState extends ConsumerState<_BulkImportDialog> {
  final _csv = TextEditingController(text:
      'student_code,ptit_email,full_name,faculty_code,major_code,class_code\n'
      'B22DCCN999,b22dccn999@ptit.edu.vn,Nguyễn Văn Demo,CNTT,KHMT,B22CN01\n');
  bool _busy = false;
  String? _resultMsg;

  Future<void> _import() async {
    final lines = _csv.text.trim().split(RegExp(r'\r?\n'));
    if (lines.length < 2) {
      setState(() => _resultMsg = 'CSV cần ít nhất 1 header + 1 dòng data');
      return;
    }
    final header = lines.first
        .split(',')
        .map((s) => s.trim().toLowerCase())
        .toList();
    const required = ['student_code', 'ptit_email', 'full_name'];
    for (final col in required) {
      if (!header.contains(col)) {
        setState(() => _resultMsg = 'Thiếu cột bắt buộc: $col');
        return;
      }
    }
    final rows = <Map<String, dynamic>>[];
    for (var i = 1; i < lines.length; i++) {
      final l = lines[i].trim();
      if (l.isEmpty) continue;
      final cells = l.split(',').map((s) => s.trim()).toList();
      final m = <String, dynamic>{};
      for (var j = 0; j < header.length && j < cells.length; j++) {
        if (cells[j].isNotEmpty) m[header[j]] = cells[j];
      }
      if (m.containsKey('student_code') &&
          m.containsKey('ptit_email') &&
          m.containsKey('full_name')) {
        rows.add(m);
      }
    }
    if (rows.isEmpty) {
      setState(() => _resultMsg = 'Không có dòng data hợp lệ');
      return;
    }

    setState(() {
      _busy = true;
      _resultMsg = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final res =
          await api.dio.post('/admin/students/import', data: {'rows': rows});
      final d = res.data as Map<String, dynamic>;
      setState(() => _resultMsg =
          'Inserted ${d['inserted']} · Skipped ${d['skipped']}'
          '${(d['errors'] as List).isEmpty ? "" : "\nErrors: ${(d['errors'] as List).join("; ")}"}');
    } catch (e) {
      final msg = e is DioException
          ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
          : '$e';
      setState(() => _resultMsg = 'Lỗi: $msg');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Bulk import student directory (CSV)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
                'Paste CSV với header: student_code, ptit_email, full_name, faculty_code, major_code, class_code',
                style: TextStyle(fontSize: 11, color: textMuted)),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _csv,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(12),
                ),
              ),
            ),
            if (_resultMsg != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  border: Border.all(color: cardBorder),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(_resultMsg!,
                    style: const TextStyle(
                        fontSize: 12, color: textPrimary, height: 1.5)),
              ),
            ],
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context, _resultMsg != null),
                  child: const Text('Đóng')),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _import,
                icon: _busy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload, size: 16),
                label: const Text('Import'),
                style: FilledButton.styleFrom(minimumSize: const Size(120, 38)),
              ),
            ])
          ]),
        ),
      ),
    );
  }
}

class _UsersTable extends ConsumerWidget {
  final List<Map<String, dynamic>> items;
  final int total;
  final VoidCallback refresh;
  const _UsersTable(
      {required this.items, required this.total, required this.refresh});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF9FAFB),
          border: Border(bottom: BorderSide(color: cardBorder)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
        ),
        child: Row(children: const [
          SizedBox(width: 50, child: _Th('ID')),
          Expanded(flex: 3, child: _Th('User')),
          Expanded(flex: 3, child: _Th('Roles')),
          Expanded(flex: 2, child: _Th('Status')),
          Expanded(flex: 2, child: _Th('Last login')),
          SizedBox(width: 130, child: _Th('Actions')),
        ]),
      ),
      ...items.map((u) => _UserRow(data: u, refresh: refresh)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: cardBorder)),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
        ),
        alignment: Alignment.centerLeft,
        child: Text('Tổng: $total user',
            style: const TextStyle(color: textMuted, fontSize: 12)),
      ),
    ]);
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

class _UserRow extends ConsumerStatefulWidget {
  final Map<String, dynamic> data;
  final VoidCallback refresh;
  const _UserRow({required this.data, required this.refresh});
  @override
  ConsumerState<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<_UserRow> {
  bool _busy = false;

  Future<void> _action(String path, String method, String successMsg) async {
    setState(() => _busy = true);
    final api = ref.read(apiClientProvider);
    try {
      if (method == 'POST') {
        await api.dio.post(path);
      } else if (method == 'DELETE') {
        await api.dio.delete(path);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(successMsg)));
      widget.refresh();
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
          : '$e';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.data;
    final fmt = DateFormat('dd/MM/yy HH:mm');
    final isLocked = u['status'] == 'LOCKED';
    final isDeleted = u['status'] == 'DELETED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: cardBorder)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
            width: 50,
            child: Text('#${u['user_id']}',
                style: const TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    fontWeight: FontWeight.w500))),
        Expanded(
          flex: 3,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u['full_name'] ?? '',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(u['email'] ?? '',
                    style: const TextStyle(fontSize: 11, color: textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ]),
        ),
        Expanded(
          flex: 3,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: ((u['roles'] as List?) ?? [])
                .map<Widget>((r) => Pill(
                      label: '$r',
                      color: ptitRed,
                      bg: ptitRedSoft,
                    ))
                .toList(),
          ),
        ),
        Expanded(flex: 2, child: Pill.status(u['status'] as String)),
        Expanded(
          flex: 2,
          child: Text(
              u['last_login_at'] != null
                  ? fmt.format(DateTime.parse(u['last_login_at']))
                  : '—',
              style: const TextStyle(fontSize: 11, color: textMuted)),
        ),
        SizedBox(
          width: 130,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (!isDeleted)
                    IconButton(
                      tooltip: isLocked ? 'Unlock' : 'Lock',
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _action(
                          '/admin/users/${u['user_id']}/${isLocked ? 'unlock' : 'lock'}',
                          'POST',
                          isLocked ? 'Đã unlock' : 'Đã lock'),
                      icon: Icon(
                          isLocked ? Icons.lock_open : Icons.lock_outline,
                          color: isLocked ? successGreen : warnOrange),
                    ),
                  IconButton(
                    tooltip: 'Đổi roles',
                    iconSize: 18,
                    visualDensity: VisualDensity.compact,
                    onPressed: () async {
                      final roles =
                          await showDialog<List<String>>(
                        context: context,
                        builder: (_) => _RolesDialog(
                            currentRoles: List<String>.from(u['roles'] ?? [])),
                      );
                      if (roles != null) {
                        try {
                          final api = ref.read(apiClientProvider);
                          await api.dio
                              .patch('/admin/users/${u['user_id']}/roles',
                                  data: {'role_codes': roles});
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Đã cập nhật roles')));
                          widget.refresh();
                        } catch (e) {
                          if (!mounted) return;
                          final msg = e is DioException
                              ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
                              : '$e';
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi: $msg')));
                        }
                      }
                    },
                    icon: const Icon(Icons.shield_outlined, color: infoBlue),
                  ),
                  if (!isDeleted)
                    IconButton(
                      tooltip: 'Xóa',
                      iconSize: 18,
                      visualDensity: VisualDensity.compact,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Xóa user?'),
                            content: Text(
                                'Soft delete user #${u['user_id']} (${u['email']})?'),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Hủy')),
                              FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  style: FilledButton.styleFrom(
                                      backgroundColor: ptitRed),
                                  child: const Text('Xóa')),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _action('/admin/users/${u['user_id']}',
                              'DELETE', 'Đã soft-delete');
                        }
                      },
                      icon:
                          const Icon(Icons.delete_outline, color: ptitRed),
                    ),
                ]),
        ),
      ]),
    );
  }
}

// ---------- CREATE DIALOG ----------

class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();
  @override
  ConsumerState<_CreateUserDialog> createState() =>
      _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _email = TextEditingController();
  final _password = TextEditingController(text: 'abc123');
  final _fullName = TextEditingController();
  final _phone = TextEditingController();
  final Set<String> _roles = {'STUDENT'};
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_email.text.isEmpty ||
        _password.text.isEmpty ||
        _fullName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email/Password/Full name bắt buộc')));
      return;
    }
    if (_roles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phải chọn ít nhất 1 role')));
      return;
    }
    setState(() => _busy = true);
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.post('/admin/users', data: {
        'email': _email.text.trim(),
        'password': _password.text,
        'full_name': _fullName.text.trim(),
        if (_phone.text.isNotEmpty) 'phone': _phone.text.trim(),
        'role_codes': _roles.toList(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo user ${_email.text}')));
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException
          ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
          : '$e';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tạo user mới',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                TextField(
                    controller: _email,
                    decoration: const InputDecoration(labelText: 'Email *')),
                const SizedBox(height: 8),
                TextField(
                    controller: _password,
                    decoration: const InputDecoration(labelText: 'Password *'),
                    obscureText: true),
                const SizedBox(height: 8),
                TextField(
                    controller: _fullName,
                    decoration:
                        const InputDecoration(labelText: 'Full name *')),
                const SizedBox(height: 8),
                TextField(
                    controller: _phone,
                    decoration:
                        const InputDecoration(labelText: 'Phone (optional)')),
                const SizedBox(height: 14),
                const Text('Roles *',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  children: _ALL_ROLES.map((r) {
                    final selected = _roles.contains(r);
                    return FilterChip(
                      label: Text(r),
                      selected: selected,
                      onSelected: (v) => setState(
                          () => v ? _roles.add(r) : _roles.remove(r)),
                      selectedColor: ptitRedSoft,
                      checkmarkColor: ptitRed,
                    );
                  }).toList(),
                ),
                if (_roles.contains('STUDENT') ||
                    _roles.contains('HOD'))
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      '⚠ Note: STUDENT cần directory_id, HOD cần faculty_id. Profile fields không có ở dialog này — tạo sẽ fail nếu chọn STUDENT/HOD. Dùng API trực tiếp hoặc bổ sung field sau.',
                      style: TextStyle(
                          fontSize: 11, color: warnOrange, height: 1.4),
                    ),
                  ),
                const SizedBox(height: 18),
                Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.of(context).pop(false),
                          child: const Text('Hủy')),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: _busy ? null : _submit,
                        style: FilledButton.styleFrom(
                            backgroundColor: ptitRed,
                            minimumSize: const Size(120, 38)),
                        child: _busy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Text('Tạo'),
                      ),
                    ]),
              ]),
        ),
      ),
    );
  }
}

// ---------- ROLES DIALOG ----------

class _RolesDialog extends StatefulWidget {
  final List<String> currentRoles;
  const _RolesDialog({required this.currentRoles});
  @override
  State<_RolesDialog> createState() => _RolesDialogState();
}

class _RolesDialogState extends State<_RolesDialog> {
  late Set<String> _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.currentRoles.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi roles'),
      content: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _ALL_ROLES.map((r) {
          final on = _selected.contains(r);
          return FilterChip(
            label: Text(r),
            selected: on,
            onSelected: (v) =>
                setState(() => v ? _selected.add(r) : _selected.remove(r)),
            selectedColor: ptitRedSoft,
            checkmarkColor: ptitRed,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()),
          style: FilledButton.styleFrom(backgroundColor: ptitRed),
          child: const Text('Lưu'),
        ),
      ],
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
              style: const TextStyle(color: textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ]),
      ),
    );
  }
}
