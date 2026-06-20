part of 'contest_admin_detail_screen.dart';

// ---------- TAB 1: Overview ----------

class _OverviewTab extends ConsumerStatefulWidget {
  final int contestId;
  final Map<String, dynamic> contest;
  const _OverviewTab({required this.contestId, required this.contest});

  @override
  ConsumerState<_OverviewTab> createState() => _OverviewTabState();
}

class _OverviewTabState extends ConsumerState<_OverviewTab> {
  bool _busy = false;

  Future<void> _action(String label, Future<void> Function() fn,
      {String successMsg = 'Thành công'}) async {
    setState(() => _busy = true);
    try {
      await fn();
      if (!mounted) return;
      AppToast.success(context, successMsg);
      ref.invalidate(contestDetailAdminProvider(widget.contestId));
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa cuộc thi?'),
        content: Text('Xóa #${widget.contestId} — "${widget.contest['title']}"?'
            '\n\nHành động không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ptitRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.delete('/contests/${widget.contestId}');
      if (!mounted) return;
      AppToast.success(context, 'Đã xóa cuộc thi');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  Future<void> _patchStatus(String newStatus) async {
    final api = ref.read(apiClientProvider);
    await api.dio.post('/contests/${widget.contestId}/transition-status',
        queryParameters: {'target': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.contest;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final st = c['status'] as String;

    String safeFmt(dynamic v) =>
        v == null ? '—' : fmt.format(DateTime.parse(v as String).toLocal());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Workflow timeline
        MCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Workflow tiếp theo',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10, children: [
              if (st == 'DRAFT' || st == 'REVISION_REQUESTED')
                _ActionBtn(
                  label: 'Submit QĐ1 cho BCN',
                  icon: Icons.send,
                  busy: _busy,
                  onTap: () => _action('Submit QĐ1', () async {
                    final api = ref.read(apiClientProvider);
                    await api.dio.post('/contests/${widget.contestId}/submit-for-approval',
                        data: {'note': 'Submit từ ContestAdminDetail'});
                  }, successMsg: 'Đã submit QĐ1, contest = PROPOSED'),
                ),
              if (st == 'PUBLISHED' || st == 'APPROVED')
                _ActionBtn(
                  label: 'Mở đăng ký (REG_OPEN)',
                  icon: Icons.lock_open,
                  busy: _busy,
                  onTap: () => _action('Mở đăng ký',
                      () => _patchStatus('REG_OPEN'),
                      successMsg: 'Contest đã chuyển REG_OPEN, SV có thể đăng ký'),
                ),
              if (st == 'REG_OPEN')
                _ActionBtn(
                  label: 'Đóng đăng ký → ONGOING',
                  icon: Icons.play_arrow,
                  busy: _busy,
                  onTap: () => _action('ONGOING',
                      () => _patchStatus('ONGOING'),
                      successMsg: 'Contest đã ONGOING, judge có thể chấm'),
                ),
              if (st == 'ONGOING')
                _ActionBtn(
                  label: 'Kết thúc thi → FINISHED',
                  icon: Icons.flag,
                  busy: _busy,
                  onTap: () => _action('FINISHED',
                      () => _patchStatus('FINISHED'),
                      successMsg: 'Contest = FINISHED, qua tab Kết quả để compute'),
                ),
              // Sprint 6 (2026-05-07): GV-07 — xuất báo cáo tổng hợp cuộc thi.
              _ActionBtn(
                label: 'Xuất báo cáo Excel (GV-07)',
                icon: Icons.assessment_outlined,
                bg: const Color(0xFF1E3A8A),
                fg: Colors.white,
                busy: _busy,
                onTap: () => exportXlsxFromEndpoint(
                  context: context,
                  dio: ref.read(apiClientProvider).dio,
                  path: '/contests/${widget.contestId}/report.xlsx',
                  fallbackFilename:
                      'bao-cao-contest-${widget.contestId}.xlsx',
                ),
              ),
              _ActionBtn(
                label: 'Xóa cuộc thi',
                icon: Icons.delete_outline,
                bg: ptitRed,
                fg: Colors.white,
                busy: _busy,
                onTap: _delete,
              ),
            ]),
            const SizedBox(height: 6),
            Text(
              'Workflow chuẩn: DRAFT → submit QĐ1 → BCN duyệt → APPROVED → mở reg → SV đăng ký → ONGOING → judge chấm → FINISHED → tính kết quả → submit QĐ2 → BCN duyệt → publish → cấp cert.',
              style: TextStyle(fontSize: 11, color: context.textMuted, height: 1.5),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        // Info grid
        MCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Thông tin cuộc thi',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _InfoRow('Mô tả', (c['description'] ?? '—').toString()),
            _InfoRow('Khoa chủ trì', 'ID #${c['host_faculty_id'] ?? '—'}'),
            _InfoRow('Hình thức', '${c['delivery_mode']} · ${c['participation_mode']}'),
            _InfoRow('Địa điểm', (c['location_text'] ?? '—').toString()),
            _InfoRow('Mở đăng ký', safeFmt(c['registration_open_at'])),
            _InfoRow('Đóng đăng ký', safeFmt(c['registration_close_at'])),
            _InfoRow('Bắt đầu thi', safeFmt(c['start_at'])),
            _InfoRow('Kết thúc thi', safeFmt(c['end_at'])),
            _InfoRow('Số entry tối đa', '${c['max_entries'] ?? "—"}'),
            _InfoRow('Team size', c['participation_mode'] == 'TEAM'
                ? '${c['team_min_members'] ?? "?"} - ${c['team_max_members'] ?? "?"} thành viên'
                : 'Cá nhân'),
            _InfoRow('Cần nộp bài', (c['requires_submission'] == true) ? 'Có' : 'Không'),
            _InfoRow('Công khai', (c['is_public'] == true) ? 'Có' : 'Không'),
            _InfoRow('Created at', safeFmt(c['created_at'])),
            _InfoRow('Owner user_id', '#${c['created_by'] ?? '—'}'),
          ]),
        ),
        // Sprint 12 (2026-05-08): real-time contest stats từ /contests/{id}/stats.
        const SizedBox(height: 12),
        _ContestStatsCard(contestId: widget.contestId),
        // Sprint 9 Group 3 (2026-05-07): reviews summary từ SV-11.
        const SizedBox(height: 12),
        _ReviewsSummaryCard(contestId: widget.contestId),
      ]),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool busy;
  final Color? bg;
  final Color? fg;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.busy = false,
      this.bg,
      this.fg});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: busy ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: bg ?? context.cardBg,
        foregroundColor: fg ?? context.textPrimary,
        side: BorderSide(color: context.cardBorder),
        elevation: 0,
        textStyle:
            GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String k;
  final String v;
  const _InfoRow(this.k, this.v);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 160,
            child: Text(k,
                style: TextStyle(
                    fontSize: 11.5, color: context.textMuted, letterSpacing: 0.2)),
          ),
          Expanded(
              child:
                  Text(v, style: TextStyle(fontSize: 13, color: context.textPrimary))),
        ]),
      );
}

// ---------- TAB 2: Rounds + Sessions ----------

class _RoundsTab extends ConsumerStatefulWidget {
  final int contestId;
  const _RoundsTab({required this.contestId});

  @override
  ConsumerState<_RoundsTab> createState() => _RoundsTabState();
}

class _RoundsTabState extends ConsumerState<_RoundsTab> {
  Future<void> _addRound() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddRoundDialog(),
    );
    if (result == null) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.post('/contests/${widget.contestId}/rounds', data: result);
      ref.invalidate(contestRoundsProvider(widget.contestId));
      if (!mounted) return;
      AppToast.success(context, 'Đã tạo round');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  /// Sprint 9 Group 2 (2026-05-07): thêm session vào contest.
  Future<void> _addSession() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddSessionDialog(),
    );
    if (result == null) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.post('/contests/${widget.contestId}/sessions',
          data: result);
      ref.invalidate(contestSessionsProvider(widget.contestId));
      if (!mounted) return;
      AppToast.success(context, 'Đã tạo phiên thi');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRounds = ref.watch(contestRoundsProvider(widget.contestId));
    final asyncSessions =
        ref.watch(contestSessionsProvider(widget.contestId));
    // Sprint 9 Group 2: SingleChildScrollView wrap để có thể scroll cả 2 section
    // (rounds + sessions). Mỗi ListView dùng shrinkWrap + NeverScrollableScrollPhysics
    // để không conflict với outer scroll.
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ===== Section 1: Vòng thi =====
        Row(children: [
          const Expanded(
            child: Text('Vòng thi & Rubric chấm điểm',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          FilledButton.icon(
            onPressed: _addRound,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Thêm vòng'),
            style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14)),
          ),
        ]),
        const SizedBox(height: 12),
        asyncRounds.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: ptitRed)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi: ${_msgOf(e)}',
                style: const TextStyle(color: ptitRed)),
          ),
          data: (rounds) => rounds.isEmpty
              ? const _Empty(
                  'Chưa có vòng nào. Thêm round đầu tiên để judge chấm.')
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rounds.length,
                  itemBuilder: (_, i) => _RoundCard(
                    contestId: widget.contestId,
                    round: rounds[i] as Map<String, dynamic>,
                  ),
                ),
        ),
        const SizedBox(height: 24),
        // ===== Section 2: Phiên thi =====
        Row(children: [
          const Expanded(
            child: Text('Phiên thi & lịch trình',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          FilledButton.icon(
            onPressed: _addSession,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Thêm phiên'),
            style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14)),
          ),
        ]),
        const SizedBox(height: 12),
        asyncSessions.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(color: ptitRed)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi: ${_msgOf(e)}',
                style: const TextStyle(color: ptitRed)),
          ),
          data: (sessions) => sessions.isEmpty
              ? const _Empty(
                  'Chưa có phiên thi. Thêm phiên để định lịch trình + check-in.')
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sessions.length,
                  itemBuilder: (_, i) =>
                      _SessionCard(session: sessions[i] as Map<String, dynamic>),
                ),
        ),
      ]),
    );
  }
}

class _RoundCard extends ConsumerStatefulWidget {
  final int contestId;
  final Map<String, dynamic> round;
  const _RoundCard({required this.contestId, required this.round});

  @override
  ConsumerState<_RoundCard> createState() => _RoundCardState();
}

class _RoundCardState extends ConsumerState<_RoundCard> {
  List<dynamic>? _criteria;
  bool _loadingCrit = false;

  Future<void> _loadCriteria() async {
    setState(() => _loadingCrit = true);
    try {
      final api = ref.read(apiClientProvider);
      final res = await api.dio.get('/rounds/${widget.round['round_id']}/criteria');
      setState(() => _criteria = res.data as List<dynamic>);
    } catch (_) {
      setState(() => _criteria = []);
    } finally {
      setState(() => _loadingCrit = false);
    }
  }

  Future<void> _addCriterion() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddCriterionDialog(),
    );
    if (result == null) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.post('/rounds/${widget.round['round_id']}/criteria',
          data: result);
      _loadCriteria();
      if (!mounted) return;
      AppToast.success(context, 'Đã thêm criterion');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  /// Sprint 9 Group 3 (2026-05-07): xóa criterion khỏi rubric.
  Future<void> _deleteCriterion(int criterionId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa criterion?'),
        content: Text('Sẽ xóa "$name" khỏi rubric. Score đã chấm dùng criterion này sẽ orphan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: ptitRed),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.delete(
          '/rounds/${widget.round['round_id']}/criteria/$criterionId');
      _loadCriteria();
      if (!mounted) return;
      AppToast.success(context, 'Đã xóa criterion');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  Future<void> _computeRoundResults() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio
          .post('/rounds/${widget.round['round_id']}/compute-results');
      ref.invalidate(roundResultsProvider(widget.round['round_id'] as int));
      if (!mounted) return;
      AppToast.success(context, 'Đã compute ${(res.data as List).length} kết quả round');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.round;
    return MCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('Vòng ${r['round_no']} — ${r['round_name']}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          if (r['round_type'] != null && r['round_type'] != 'OTHER')
            Pill(label: r['round_type'].toString(), color: context.infoBlue, bg: context.infoSoft),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.bar_chart, size: 18, color: context.warnOrange),
            tooltip: 'Compute kết quả round (sau khi judge chấm xong)',
            onPressed: _computeRoundResults,
          ),
        ]),
        if ((r['description'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(r['description'] as String,
              style: TextStyle(fontSize: 12, color: context.textMuted)),
        ],
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: EdgeInsets.zero,
            title: const Text('Rubric (criteria)',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            onExpansionChanged: (open) {
              if (open && _criteria == null) _loadCriteria();
            },
            children: [
              if (_loadingCrit)
                const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator(color: ptitRed))),
              if (_criteria != null) ...[
                if (_criteria!.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Chưa có criterion nào',
                        style: TextStyle(fontSize: 12, color: context.textMuted)),
                  )
                else
                  ..._criteria!.map((c) {
                    final m = c as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Expanded(
                            child: Text('${m['criterion_name']}',
                                style: const TextStyle(fontSize: 12))),
                        const SizedBox(width: 8),
                        Text('Max ${m['max_score']} · ${m['weight_percent'] ?? 0}%',
                            style: TextStyle(
                                fontSize: 11, color: context.textMuted)),
                        // Sprint 9 Group 3 (2026-05-07): xóa criterion.
                        IconButton(
                          tooltip: 'Xóa',
                          icon: Icon(Icons.delete_outline,
                              size: 16, color: context.warnOrange),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 44, minHeight: 44),
                          onPressed: () => _deleteCriterion(
                              m['criterion_id'] as int,
                              m['criterion_name'] as String),
                        ),
                      ]),
                    );
                  }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addCriterion,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Thêm criterion'),
                  ),
                ),
              ],
            ],
          )),
        ]),
      ]),
    );
  }
}

class _AddRoundDialog extends StatefulWidget {
  const _AddRoundDialog();
  @override
  State<_AddRoundDialog> createState() => _AddRoundDialogState();
}

class _AddRoundDialogState extends State<_AddRoundDialog> {
  final _name = TextEditingController(text: 'Vòng chính');
  final _desc = TextEditingController();
  final _order = TextEditingController(text: '1');
  String _type = 'FINAL';
  DateTime? _startAt;
  DateTime? _endAt;

  Future<void> _pickDate(bool isStart) async {
    final base = isStart ? _startAt : _endAt;
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      initialDate: base ?? DateTime.now(),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base ?? DateTime.now()),
    );
    if (t == null) return;
    setState(() {
      final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
      if (isStart) {
        _startAt = dt;
      } else {
        _endAt = dt;
      }
    });
  }

  String _fmtDt(DateTime? d) =>
      d == null ? 'Chưa chọn' : DateFormat('dd/MM/yy HH:mm').format(d);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Thêm vòng thi',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên vòng *')),
            const SizedBox(height: 10),
            TextField(
                controller: _desc,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Mô tả')),
            const SizedBox(height: 10),
            Row(children: [
              SizedBox(
                width: 100,
                child: TextField(
                    controller: _order,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Thứ tự *')),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Loại'),
                  items: const [
                    DropdownMenuItem(value: 'QUALIFIER', child: Text('Vòng loại')),
                    DropdownMenuItem(value: 'PRELIMINARY', child: Text('Sơ khảo')),
                    DropdownMenuItem(value: 'SEMI_FINAL', child: Text('Bán kết')),
                    DropdownMenuItem(value: 'FINAL', child: Text('Chung kết')),
                    DropdownMenuItem(value: 'OTHER', child: Text('Khác')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'FINAL'),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 14),
                  label: Text('Bắt đầu: ${_fmtDt(_startAt)}',
                      style: const TextStyle(fontSize: 11)),
                  onPressed: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 14),
                  label: Text('Kết thúc: ${_fmtDt(_endAt)}',
                      style: const TextStyle(fontSize: 11)),
                  onPressed: () => _pickDate(false),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  if (_startAt == null || _endAt == null) {
                    AppToast.success(context, 'Cần chọn thời gian bắt đầu + kết thúc');
                    return;
                  }
                  Navigator.pop(context, {
                    'round_no': int.tryParse(_order.text) ?? 1,
                    'round_name': _name.text.trim(),
                    'round_type': _type,
                    'description': _desc.text.trim().isEmpty
                        ? null
                        : _desc.text.trim(),
                    'start_at': _startAt!.toUtc().toIso8601String(),
                    'end_at': _endAt!.toUtc().toIso8601String(),
                  });
                },
                style: FilledButton.styleFrom(minimumSize: const Size(120, 38)),
                child: const Text('Tạo'),
              ),
            ])
          ]),
        ),
      ),
    );
  }
}

class _AddCriterionDialog extends StatefulWidget {
  const _AddCriterionDialog();
  @override
  State<_AddCriterionDialog> createState() => _AddCriterionDialogState();
}

class _AddCriterionDialogState extends State<_AddCriterionDialog> {
  final _name = TextEditingController();
  final _max = TextEditingController(text: '10');
  final _weight = TextEditingController(text: '100');
  final _order = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Thêm criterion',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
                controller: _name,
                decoration: const InputDecoration(
                    labelText: 'Tên tiêu chí *',
                    hintText: 'vd: Sáng tạo, Kỹ thuật, Trình bày')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: TextField(
                      controller: _max,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Max score *', hintText: '10'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: _weight,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Weight % (0-100)', hintText: '100'))),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: TextField(
                    controller: _order,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Order')),
              ),
            ]),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'criterion_name': _name.text.trim(),
                    'max_score': double.tryParse(_max.text) ?? 10,
                    'weight_percent': double.tryParse(_weight.text) ?? 100,
                    'display_order': int.tryParse(_order.text) ?? 1,
                  });
                },
                style: FilledButton.styleFrom(minimumSize: const Size(120, 38)),
                child: const Text('Thêm'),
              ),
            ])
          ]),
        ),
      ),
    );
  }
}

