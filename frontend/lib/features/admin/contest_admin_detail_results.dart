part of 'contest_admin_detail_screen.dart';

// ---------- TAB 5: Results ----------

class _ResultsTab extends ConsumerStatefulWidget {
  final int contestId;
  final String contestStatus;
  const _ResultsTab({required this.contestId, required this.contestStatus});

  @override
  ConsumerState<_ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends ConsumerState<_ResultsTab> {
  Future<void> _compute() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio
          .post('/contests/${widget.contestId}/results/compute');
      ref.invalidate(contestResultsProvider(widget.contestId));
      if (!mounted) return;
      AppToast.success(context, 'Đã compute ${(res.data as List).length} kết quả');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  Future<void> _submitQd2() async {
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.post(
          '/contests/${widget.contestId}/results/submit-for-approval',
          data: {'note': 'Submit kết quả từ admin panel'});
      ref.invalidate(contestDetailAdminProvider(widget.contestId));
      if (!mounted) return;
      AppToast.success(context, 'Đã submit QĐ2 cho BCN duyệt');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  Future<void> _publish() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Publish results?'),
        content: const Text(
            'Sau khi publish, SV sẽ thấy kết quả trong "Kết quả" của họ. Cần BCN_QĐ2 đã APPROVED.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Publish')),
        ],
      ),
    );
    if (ok != true) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.post('/contests/${widget.contestId}/results/publish');
      ref.invalidate(contestDetailAdminProvider(widget.contestId));
      ref.invalidate(contestResultsProvider(widget.contestId));
      if (!mounted) return;
      AppToast.success(context, 'Đã publish, contest = FINISHED');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  /// Phase 2 sprint 1 step 3 (2026-05-06): download Excel kết quả contest.
  /// 4 sheets (Tổng quan / Vòng / Submissions / Metadata).
  Future<void> _exportXlsx() async {
    final api = ref.read(apiClientProvider);
    try {
      // Show snack báo đang chuẩn bị file (UX: large contests có thể mất 3-5s)
      AppToast.info(context, 'Đang chuẩn bị file Excel...');

      final res = await api.dio.get<List<int>>(
        '/contests/${widget.contestId}/results/export.xlsx',
        options: Options(responseType: ResponseType.bytes),
      );
      if (!mounted) return;
      final bytes = Uint8List.fromList(res.data!);

      // Lấy filename từ Content-Disposition header (BE đã set chuẩn)
      String filename = 'ket-qua-contest-${widget.contestId}.xlsx';
      final cd = res.headers.value('content-disposition');
      if (cd != null) {
        final match = RegExp(r'filename="?([^"]+)"?').firstMatch(cd);
        if (match != null) filename = match.group(1)!;
      }

      try {
        downloadBytesAsFile(
          bytes,
          filename,
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        if (!mounted) return;
        AppToast.success(context, 'Đã tải về: $filename');
      } on UnsupportedError catch (e) {
        if (!mounted) return;
        AppToast.info(context, e.message ?? 'Không hỗ trợ trên platform này');
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  Future<void> _editAward(int crId, String currentAward) async {
    final ctrl = TextEditingController(text: currentAward);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sửa giải thưởng'),
        content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
                hintText: 'vd: Giải Nhất, Giải Nhì, Giải KK')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              child: const Text('Lưu')),
        ],
      ),
    );
    if (result == null) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.patch('/contest-results/$crId',
          data: {'award_title': result.isEmpty ? null : result});
      ref.invalidate(contestResultsProvider(widget.contestId));
      if (!mounted) return;
      AppToast.success(context, 'Đã update award');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncResults = ref.watch(contestResultsProvider(widget.contestId));
    final st = widget.contestStatus;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          _ActionBtn(
              label: '1. Compute kết quả contest',
              icon: Icons.calculate,
              onTap: _compute),
          _ActionBtn(
              label: '2. Submit QĐ2 cho BCN',
              icon: Icons.send,
              bg: context.warnOrange,
              fg: Colors.white,
              onTap: _submitQd2),
          _ActionBtn(
              label: '3. Publish results (cần BCN OK)',
              icon: Icons.publish,
              bg: context.successGreen,
              fg: Colors.white,
              onTap: _publish),
          // Phase 2 sprint 1 step 3 (2026-05-06): Excel export
          _ActionBtn(
              label: '4. Xuất Excel (4 sheets)',
              icon: Icons.download,
              bg: const Color(0xFF1E3A8A),
              fg: Colors.white,
              onTap: _exportXlsx),
        ]),
        const SizedBox(height: 6),
        Text('Status hiện tại: $st',
            style: TextStyle(fontSize: 11, color: context.textMuted)),
        const SizedBox(height: 14),
        const Text('Bảng xếp hạng (rank · award)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Expanded(
          child: asyncResults.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => Center(
                child: Text('Lỗi: ${_msgOf(e)}',
                    style: const TextStyle(color: ptitRed))),
            data: (rs) => rs.isEmpty
                ? const _Empty(
                    'Chưa có kết quả. Bấm "1. Compute" sau khi judge chấm xong.')
                : ListView.builder(
                    itemCount: rs.length,
                    itemBuilder: (_, i) {
                      final r = rs[i] as Map<String, dynamic>;
                      return MCard(
                        child: Row(children: [
                          SizedBox(
                            width: 40,
                            child: Text('#${r['rank_no'] ?? '-'}',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: ptitRed)),
                          ),
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Entry #${r['entry_id']} · Final score ${(r['final_score'] is num ? (r['final_score'] as num).toStringAsFixed(2) : (r['final_score']?.toString() ?? "—"))}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  if ((r['award_title'] ?? '').toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Pill(
                                        label: r['award_title'] as String,
                                        color: context.warnOrange,
                                        bg: context.warnSoft,
                                      ),
                                    ),
                                ]),
                          ),
                          IconButton(
                            tooltip: 'Chỉnh sửa',
                            icon: Icon(Icons.edit_outlined,
                                size: 18, color: context.textMuted),
                            onPressed: () => _editAward(
                                r['contest_result_id'] as int,
                                (r['award_title'] ?? '').toString()),
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

// ---------- TAB 6: Certificates ----------

class _CertsTab extends ConsumerStatefulWidget {
  final int contestId;
  const _CertsTab({required this.contestId});

  @override
  ConsumerState<_CertsTab> createState() => _CertsTabState();
}

class _CertsTabState extends ConsumerState<_CertsTab> {
  Future<void> _addTemplate() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _AddCertTemplateDialog(),
    );
    if (result == null) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio
          .post('/contests/${widget.contestId}/certificate-templates', data: result);
      ref.invalidate(certTemplatesProvider(widget.contestId));
      if (!mounted) return;
      AppToast.success(context, 'Đã tạo template — chờ BCN duyệt (QĐ3)');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  Future<void> _activate(int templateId) async {
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.patch('/certificate-templates/$templateId/activate');
      ref.invalidate(certTemplatesProvider(widget.contestId));
      if (!mounted) return;
      AppToast.success(context, 'Đã activate template');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  /// Sprint 11 #1 (2026-05-08): BCN/Admin duyệt cert template (QĐ3 workflow).
  /// Sau approve → BTC mới có thể Activate. Permission BE check qua role HOD/ADMIN.
  Future<void> _approve(int templateId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Duyệt template?'),
        content: const Text(
            'Sau khi duyệt, BTC sẽ có thể Activate template để cấp chứng nhận. Quyết định này sẽ ghi vào audit log.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Duyệt'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.patch('/certificate-templates/$templateId/approve');
      ref.invalidate(certTemplatesProvider(widget.contestId));
      if (!mounted) return;
      AppToast.success(context, 'Đã duyệt template — BTC có thể Activate');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  Future<void> _issueCerts(bool onlyAward) async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio.post(
          '/contests/${widget.contestId}/certificates/issue',
          data: {'only_with_award': onlyAward});
      if (!mounted) return;
      final d = res.data is Map ? res.data as Map : {};
      final issued = d['issued_count'] ?? d['issued'] ?? 0;
      final skipped = d['skipped_count'] ?? d['skipped'] ?? 0;
      AppToast.success(context, 'Đã cấp $issued certificates · skipped $skipped');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncTpl = ref.watch(certTemplatesProvider(widget.contestId));
    // Sprint 11 #1 (2026-05-08): user để conditional show button "Duyệt" cho HOD/Admin.
    final user = ref.watch(authProvider).value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: Text('Template chứng nhận',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
          FilledButton.icon(
            onPressed: _addTemplate,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Tạo template'),
            style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(horizontal: 14)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(
            'Workflow: tạo template → BCN duyệt (QĐ3) qua nút "Duyệt" → BTC activate → cấp cert hàng loạt cho results.',
            style: TextStyle(fontSize: 11, color: context.textMuted)),
        const SizedBox(height: 12),
        Expanded(
          flex: 2,
          child: asyncTpl.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => Center(
                child: Text('Lỗi: ${_msgOf(e)}',
                    style: const TextStyle(color: ptitRed))),
            data: (items) => items.isEmpty
                ? const _Empty('Chưa có template nào')
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final t = items[i] as Map<String, dynamic>;
                      final isApproved = t['approved_at'] != null;
                      final isActive = t['is_active'] == true;
                      return MCard(
                        child: Row(children: [
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '#${t['template_id']} — ${t['template_name']}',
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    Pill(
                                        label: isApproved
                                            ? 'BCN duyệt OK'
                                            : 'Chờ BCN duyệt (QĐ3)',
                                        color: isApproved ? context.successGreen : context.warnOrange,
                                        bg: isApproved ? context.successSoft : context.warnSoft),
                                    const SizedBox(width: 6),
                                    if (isActive)
                                      Pill(
                                        label: 'ACTIVE',
                                        color: context.successGreen,
                                        bg: context.successSoft,
                                      ),
                                  ]),
                                ]),
                          ),
                          // Sprint 11 #1 (2026-05-08): BCN/Admin duyệt cert template (QĐ3).
                          // Hiện trước Activate vì workflow là Approve → Activate.
                          if (!isApproved && user != null && (user.isHod || user.isAdmin))
                            FilledButton.icon(
                              onPressed: () => _approve(t['template_id'] as int),
                              icon: const Icon(Icons.check_circle_outline,
                                  size: 16),
                              label: const Text('Duyệt'),
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 34),
                                  backgroundColor: context.successGreen,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12)),
                            ),
                          if (isApproved && !isActive)
                            FilledButton.icon(
                              onPressed: () => _activate(t['template_id'] as int),
                              icon: const Icon(Icons.power_settings_new, size: 16),
                              label: const Text('Activate'),
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 34),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12)),
                            ),
                        ]),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Cấp chứng nhận hàng loạt',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _ActionBtn(
              label: 'Cấp cho người có giải',
              icon: Icons.workspace_premium,
              bg: ptitRed,
              fg: Colors.white,
              onTap: () => _issueCerts(true)),
          _ActionBtn(
              label: 'Cấp cho TẤT CẢ kết quả',
              icon: Icons.workspace_premium_outlined,
              onTap: () => _issueCerts(false)),
        ]),
      ]),
    );
  }
}

class _AddCertTemplateDialog extends StatefulWidget {
  const _AddCertTemplateDialog();
  @override
  State<_AddCertTemplateDialog> createState() => _AddCertTemplateDialogState();
}

class _AddCertTemplateDialogState extends State<_AddCertTemplateDialog> {
  final _name = TextEditingController(text: 'Template chính');
  final _html = TextEditingController(text: '''<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Chứng nhận</title>
<style>
  body { font-family: Georgia, serif; text-align: center; padding: 60px; background: #fefdfb; }
  h1 { font-size: 32px; color: #C8102E; margin-bottom: 30px; }
  .name { font-size: 28px; font-weight: bold; margin: 30px 0; }
  .award { font-size: 22px; color: #D97706; margin: 15px 0; }
  .footer { margin-top: 40px; font-size: 12px; color: #666; }
</style></head><body>
  <h1>CHỨNG NHẬN</h1>
  <p>Trao tặng cho</p>
  <div class="name">{{full_name}}</div>
  <p>MSV: {{student_code}}</p>
  <div class="award">{{award_title}}</div>
  <p>Cuộc thi: <b>{{contest_title}}</b></p>
  <div class="footer">Cấp ngày {{issued_date}} · Mã QR: {{qr_code}}</div>
</body></html>''');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('Tạo template chứng nhận',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Tên template *')),
            const SizedBox(height: 10),
            Text(
                'HTML template — dùng {{full_name}}, {{student_code}}, {{award_title}}, {{contest_title}}, {{issued_date}}, {{qr_code}}',
                style: TextStyle(fontSize: 11, color: context.textMuted)),
            const SizedBox(height: 6),
            Expanded(
              child: TextField(
                controller: _html,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(12)),
              ),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'template_name': _name.text.trim(),
                    'html_template': _html.text,
                  });
                },
                style: FilledButton.styleFrom(minimumSize: const Size(140, 38)),
                child: const Text('Tạo'),
              ),
            ])
          ]),
        ),
      ),
    );
  }
}

// ============================================================
// Sprint 9 Group 2 (2026-05-07): Sessions UI
// ============================================================

/// Card hiển thị 1 phiên thi: tên + type chip + thời gian + location/url.
class _SessionCard extends StatelessWidget {
  final Map<String, dynamic> session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context) {
    final type = session['session_type'] as String? ?? 'OFFLINE';
    final startAt = session['start_at'] as String?;
    final endAt = session['end_at'] as String?;
    final location = session['location_text'] as String?;
    final room = session['room_text'] as String?;
    final meetingUrl = session['online_meeting_url'] as String?;
    final dt = (startAt != null && endAt != null)
        ? '${_fmt(startAt)} → ${_fmt(endAt)}'
        : '—';
    final venue = type == 'ONLINE'
        ? (meetingUrl ?? '—')
        : [location, room].where((s) => s != null && s.isNotEmpty).join(' · ');
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(
                '#${session['session_id']} — ${session['session_name']}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
            Pill(
              label: type,
              kind: type == 'ONLINE' ? PillKind.info : PillKind.neutral,
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Icon(Icons.schedule, size: 13, color: context.textMuted),
            const SizedBox(width: 4),
            Text(dt,
                style: TextStyle(fontSize: 11.5, color: context.textMuted)),
          ]),
          if (venue.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(children: [
              Icon(
                  type == 'ONLINE'
                      ? Icons.link
                      : Icons.location_on_outlined,
                  size: 13,
                  color: context.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(venue,
                    style:
                        TextStyle(fontSize: 11.5, color: context.textMuted),
                    overflow: TextOverflow.ellipsis),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  String _fmt(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

/// Dialog tạo phiên thi mới — form: tên, type online/offline, start/end datetime,
/// location_text/room hoặc online_meeting_url tùy type.
class _AddSessionDialog extends StatefulWidget {
  const _AddSessionDialog();

  @override
  State<_AddSessionDialog> createState() => _AddSessionDialogState();
}

class _AddSessionDialogState extends State<_AddSessionDialog> {
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _room = TextEditingController();
  final _meetingUrl = TextEditingController();
  String _type = 'OFFLINE';
  DateTime? _start;
  DateTime? _end;
  String? _err;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _room.dispose();
    _meetingUrl.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (d == null || !mounted) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (t == null) return null;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  void _submit() {
    setState(() => _err = null);
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _err = 'Tên phiên tối thiểu 2 ký tự');
      return;
    }
    if (_start == null || _end == null) {
      setState(() => _err = 'Bắt buộc chọn thời gian bắt đầu + kết thúc');
      return;
    }
    if (!_end!.isAfter(_start!)) {
      setState(() => _err = 'Kết thúc phải sau bắt đầu');
      return;
    }
    final data = <String, dynamic>{
      'session_name': name,
      'session_type': _type,
      'start_at': _start!.toUtc().toIso8601String(),
      'end_at': _end!.toUtc().toIso8601String(),
    };
    if (_type == 'OFFLINE') {
      if (_location.text.trim().isNotEmpty) {
        data['location_text'] = _location.text.trim();
      }
      if (_room.text.trim().isNotEmpty) {
        data['room_text'] = _room.text.trim();
      }
    } else {
      if (_meetingUrl.text.trim().isNotEmpty) {
        data['online_meeting_url'] = _meetingUrl.text.trim();
      }
    }
    Navigator.pop(context, data);
  }

  String _fmtDt(DateTime? d) {
    if (d == null) return 'Chọn...';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Tạo phiên thi',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Tên phiên *',
                      hintText: 'Vòng sơ loại tuần 1'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Hình thức *'),
                  items: const [
                    DropdownMenuItem(
                        value: 'OFFLINE',
                        child: Text('Trực tiếp (OFFLINE)')),
                    DropdownMenuItem(
                        value: 'ONLINE', child: Text('Trực tuyến (ONLINE)')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'OFFLINE'),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final d = await _pickDateTime(
                            _start ?? DateTime.now().add(const Duration(days: 1)));
                        if (d != null) setState(() => _start = d);
                      },
                      child: Text('Bắt đầu: ${_fmtDt(_start)}'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final d = await _pickDateTime(_end ??
                            (_start ?? DateTime.now())
                                .add(const Duration(hours: 2)));
                        if (d != null) setState(() => _end = d);
                      },
                      child: Text('Kết thúc: ${_fmtDt(_end)}'),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                if (_type == 'OFFLINE') ...[
                  TextField(
                    controller: _location,
                    decoration: const InputDecoration(
                        labelText: 'Địa điểm',
                        hintText: 'Toà A1 PTIT cơ sở 1'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _room,
                    decoration: const InputDecoration(
                        labelText: 'Phòng', hintText: 'Phòng Lab CNTT'),
                  ),
                ] else
                  TextField(
                    controller: _meetingUrl,
                    decoration: const InputDecoration(
                        labelText: 'URL meeting',
                        hintText: 'https://meet.google.com/...'),
                  ),
                if (_err != null) ...[
                  const SizedBox(height: 8),
                  Text(_err!,
                      style: const TextStyle(color: ptitRed, fontSize: 12)),
                ],
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(120, 40)),
                    child: const Text('Tạo phiên'),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

