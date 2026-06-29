part of 'contest_admin_detail_screen.dart';

// ---------- TAB 3: Entries ----------

class _EntriesTab extends ConsumerStatefulWidget {
  final int contestId;
  const _EntriesTab({required this.contestId});

  @override
  ConsumerState<_EntriesTab> createState() => _EntriesTabState();
}

class _EntriesTabState extends ConsumerState<_EntriesTab> {
  // Phase 2 sprint 1 step 2 (2026-05-06): bulk approve/reject
  // Set chứa entry_id đang được chọn (chỉ entries PENDING mới chọn được)
  final Set<int> _selectedIds = {};

  Future<void> _decide(int entryId, String action) async {
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.patch('/entries/$entryId',
          data: {'action': action, 'note': action == 'reject' ? 'Reject từ admin panel' : null});
      ref.invalidate(contestEntriesProvider(widget.contestId));
      if (!mounted) return;
      AppToast.success(context, 'Đã ${action == 'approve' ? 'duyệt' : 'từ chối'} entry');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  /// Bulk approve/reject N entries. Gọi POST /api/contests/{cid}/entries/bulk-review.
  Future<void> _bulkDecide(String action) async {
    if (_selectedIds.isEmpty) return;
    final ids = _selectedIds.toList();
    final actionLabel = action == 'approve' ? 'duyệt' : 'từ chối';

    // Confirmation dialog chống misclick
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận $actionLabel ${ids.length} entries'),
        content: Text(
          'Bạn sắp $actionLabel ${ids.length} đơn đăng ký. Hành động này không thể undo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? context.successGreen : ptitRed,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel.toUpperCase(),
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio.post(
        '/contests/${widget.contestId}/entries/bulk-review',
        data: {
          'entry_ids': ids,
          'action': action,
          'note': action == 'reject' ? 'Bulk reject từ admin panel' : null,
        },
      );
      final body = res.data as Map<String, dynamic>;
      final successCount = body['success_count'] ?? 0;
      final failed = (body['failed'] as List?) ?? [];
      _selectedIds.clear();
      ref.invalidate(contestEntriesProvider(widget.contestId));
      if (!mounted) return;
      final msg = failed.isEmpty
          ? 'Đã $actionLabel $successCount/${ids.length} entries'
          : 'Đã $actionLabel $successCount/${ids.length}, ${failed.length} lỗi (xem console)';
      if (failed.isEmpty) {
        AppToast.success(context, msg);
      } else {
        AppToast.info(context, msg);
      }
      if (failed.isNotEmpty) {
        debugPrint('Bulk review failed items: $failed');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  /// Toggle select all PENDING entries trong list hiện tại.
  void _toggleSelectAll(List<dynamic> entries) {
    final pendingIds = entries
        .where((e) => (e['registration_status'] as String?) == 'PENDING')
        .map((e) => e['entry_id'] as int)
        .toSet();
    setState(() {
      if (_selectedIds.containsAll(pendingIds) && _selectedIds.isNotEmpty) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(pendingIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncEntries = ref.watch(contestEntriesProvider(widget.contestId));
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Stack(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row: title + bulk select button (chỉ hiện khi có entries)
          asyncEntries.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (entries) {
              final pendingCount = entries
                  .where((e) =>
                      (e['registration_status'] as String?) == 'PENDING')
                  .length;
              return Row(children: [
                const Text('Đăng ký của SV — duyệt entries',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (pendingCount > 0)
                  TextButton.icon(
                    icon: Icon(
                      _selectedIds.isEmpty
                          ? Icons.check_box_outline_blank
                          : Icons.check_box,
                      size: 18,
                    ),
                    label: Text(_selectedIds.isEmpty
                        ? 'Chọn tất cả PENDING ($pendingCount)'
                        : 'Bỏ chọn tất cả'),
                    onPressed: () => _toggleSelectAll(entries),
                  ),
              ]);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: asyncEntries.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: ptitRed)),
              error: (e, _) => Center(
                  child: Text('Lỗi: ${_msgOf(e)}',
                      style: const TextStyle(color: ptitRed))),
              data: (entries) => entries.isEmpty
                  ? const _Empty('Chưa có SV nào đăng ký')
                  : ListView.builder(
                      // Padding bottom để bulk action bar không che row cuối
                      padding: EdgeInsets.only(
                          bottom: _selectedIds.isEmpty ? 0 : 80),
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[i] as Map<String, dynamic>;
                        final st =
                            e['registration_status'] as String? ?? 'PENDING';
                        final entryId = e['entry_id'] as int;
                        final isPending = st == 'PENDING';
                        final isSelected = _selectedIds.contains(entryId);
                        return MCard(
                          backgroundColor:
                              isSelected ? context.ptitRedSoft.withValues(alpha: 0.3) : null,
                          child: Row(children: [
                            // Checkbox: chỉ hiện cho PENDING (KHÔNG cho approved/rejected)
                            if (isPending)
                              Checkbox(
                                value: isSelected,
                                activeColor: ptitRed,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedIds.add(entryId);
                                    } else {
                                      _selectedIds.remove(entryId);
                                    }
                                  });
                                },
                              )
                            else
                              const SizedBox(width: 48),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Entry #$entryId · ${e['entry_type'] ?? '—'}',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(
                                        'SV student_id #${e['student_id'] ?? '—'}'
                                        ' · Team ${e['team_id'] ?? '—'}'
                                        ' · Đăng ký ${_safeFmtIso(e['created_at'])}'
                                        '${(e['registration_note'] ?? '').toString().isNotEmpty ? " · \"${e['registration_note']}\"" : ""}',
                                        style: TextStyle(
                                            fontSize: 11, color: context.textMuted)),
                                  ]),
                            ),
                            // Option B — cờ cảnh báo SV đăng ký dù trùng lịch.
                            if (e['schedule_conflict_ack'] == true) ...[
                              Tooltip(
                                message:
                                    'SV đã đăng ký dù được cảnh báo trùng lịch cuộc thi khác',
                                child: Pill(
                                  label: 'Trùng lịch',
                                  color: context.warnOrange,
                                  bg: context.warnSoft,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Pill.status(st),
                            const SizedBox(width: 10),
                            if (isPending) ...[
                              IconButton(
                                icon: Icon(Icons.check,
                                    color: context.successGreen, size: 20),
                                tooltip: 'Duyệt',
                                onPressed: () => _decide(entryId, 'approve'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: ptitRed, size: 20),
                                tooltip: 'Từ chối',
                                onPressed: () => _decide(entryId, 'reject'),
                              ),
                            ],
                          ]),
                        );
                      },
                    ),
            ),
          ),
        ]),
        // Floating bulk action bar — chỉ hiện khi có chọn ≥1
        if (_selectedIds.isNotEmpty)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Đã chọn ${_selectedIds.length} entries',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.textPrimary)),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Duyệt'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: context.successGreen,
                        foregroundColor: Colors.white),
                    onPressed: () => _bulkDecide('approve'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Từ chối'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: ptitRed,
                        foregroundColor: Colors.white),
                    onPressed: () => _bulkDecide('reject'),
                  ),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}

// ---------- TAB 4: Judging (assign judges per round) ----------

class _JudgingTab extends ConsumerStatefulWidget {
  final int contestId;
  const _JudgingTab({required this.contestId});

  @override
  ConsumerState<_JudgingTab> createState() => _JudgingTabState();
}

class _JudgingTabState extends ConsumerState<_JudgingTab> {
  Future<void> _assignJudge(int roundId) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AssignJudgeDialog(),
    );
    if (result == null) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio
          .post('/rounds/$roundId/judge-assignments', data: result);
      if (!mounted) return;
      AppToast.success(context, 'Đã assign judge');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  /// Sprint 11 #2 (2026-05-08): Khóa submission — ngăn SV nộp version mới
  /// trong khi judge đang chấm. POST /submissions/{id}/lock. Reason là note
  /// audit log (vd: "Đang chấm vòng 1, không nhận thêm version").
  Future<void> _lockSubmission() async {
    final ctrl = TextEditingController();
    final reasonCtrl = TextEditingController(
        text: 'Khóa khi judge đang chấm — không nhận version mới.');
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Khóa submission?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Sau khi khóa, SV không thể nộp version mới cho submission này. Audit log sẽ ghi reason.',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Submission ID *',
                helperText: 'Lấy từ judge view hoặc audit log',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Lý do khóa'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () {
              final id = int.tryParse(ctrl.text.trim());
              if (id == null) return;
              Navigator.pop(ctx, {
                'submission_id': id,
                'reason': reasonCtrl.text.trim(),
              });
            },
            style: FilledButton.styleFrom(backgroundColor: ptitRed),
            child: const Text('Khóa'),
          ),
        ],
      ),
    );
    if (result == null) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.post(
          '/submissions/${result['submission_id']}/lock',
          data: {
            if ((result['reason'] as String).isNotEmpty)
              'reason': result['reason'],
          });
      if (!mounted) return;
      AppToast.success(context, 'Đã khóa submission #${result['submission_id']}');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRounds = ref.watch(contestRoundsProvider(widget.contestId));
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
            child: Text('Phân công Judge cho từng round',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          // Sprint 11 #2 (2026-05-08): admin/BTC khóa submission anti-tamper.
          OutlinedButton.icon(
            onPressed: _lockSubmission,
            icon: const Icon(Icons.lock_outline, size: 16),
            label: const Text('Khóa submission'),
            style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
            'Mỗi assignment = 1 judge chấm 1 entry trong 1 round. Cần entry_id (ID đăng ký SV) + judge_id (ID judge từ tab Quản lý user).',
            style: TextStyle(fontSize: 11, color: context.textMuted)),
        const SizedBox(height: 12),
        Expanded(
          child: asyncRounds.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => Center(
                child: Text('Lỗi: ${_msgOf(e)}',
                    style: const TextStyle(color: ptitRed))),
            data: (rounds) => rounds.isEmpty
                ? const _Empty('Chưa có round. Tạo round ở tab "Vòng & Phiên" trước.')
                : ListView.builder(
                    itemCount: rounds.length,
                    itemBuilder: (_, i) {
                      final r = rounds[i] as Map<String, dynamic>;
                      return MCard(
                        child: Row(children: [
                          Expanded(
                            child: Text(
                                'Vòng ${r['round_no']} — ${r['round_name']}',
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700)),
                          ),
                          FilledButton.icon(
                            onPressed: () => _assignJudge(r['round_id'] as int),
                            icon: const Icon(Icons.person_add, size: 16),
                            label: const Text('Assign judge'),
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                            ),
                          ),
                        ]),
                      );
                    },
                  ),
          ),
        ),
      ]),
    );
  }
}

class _AssignJudgeDialog extends StatefulWidget {
  const _AssignJudgeDialog();
  @override
  State<_AssignJudgeDialog> createState() => _AssignJudgeDialogState();
}

class _AssignJudgeDialogState extends State<_AssignJudgeDialog> {
  final _entry = TextEditingController();
  final _judge = TextEditingController();
  bool _canViewIdent = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Assign judge → entry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
                controller: _entry,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Entry ID *',
                    helperText: 'Lấy từ tab "Đăng ký"')),
            const SizedBox(height: 10),
            TextField(
                controller: _judge,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Judge ID *',
                    helperText:
                        'judge_id từ bảng judges (admin/users → role JUDGE)')),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Cho phép xem danh tính SV',
                  style: TextStyle(fontSize: 13)),
              value: _canViewIdent,
              onChanged: (v) => setState(() => _canViewIdent = v),
            ),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  final eid = int.tryParse(_entry.text);
                  final jid = int.tryParse(_judge.text);
                  if (eid == null || jid == null) {
                    AppToast.info(context, 'Vui lòng nhập số Entry/Judge ID hợp lệ');
                    return;
                  }
                  Navigator.pop(context, {
                    'entry_id': eid,
                    'judge_id': jid,
                    'can_view_identity': _canViewIdent,
                  });
                },
                style: FilledButton.styleFrom(minimumSize: const Size(120, 38)),
                child: const Text('Assign'),
              ),
            ])
          ]),
        ),
      ),
    );
  }
}

