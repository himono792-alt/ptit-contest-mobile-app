// ContestAdminDetailScreen — full-screen admin drill-down quản lý 1 contest.
//
// Route: /admin/contests/:id
//
// 6 tab:
//   1. Tổng quan         — info + workflow buttons (Submit QĐ1, Open Reg, Submit QĐ2, Publish, Delete)
//   2. Vòng & Phiên       — rounds + rubric criteria
//   3. Đăng ký           — entries queue (PENDING → approve/reject)
//   4. Chấm điểm          — judge assignments per round (assign judge → entry)
//   5. Kết quả            — compute → list with award editor → submit QĐ2 → publish
//   6. Chứng nhận         — templates + issue certs

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';

// ---------- Providers ----------

final contestDetailAdminProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  // GET /contests/{slug} cần slug; ta lấy slug qua list show_all then find
  final list = await api.dio.get('/contests',
      queryParameters: {'show_all': true, 'size': 200});
  final items = (list.data['items'] ?? list.data) as List<dynamic>;
  final found = items.cast<Map<String, dynamic>>().firstWhere(
        (c) => c['contest_id'] == contestId,
        orElse: () => {},
      );
  if (found.isEmpty) {
    throw DioException(
      requestOptions: RequestOptions(path: '/contests/$contestId'),
      message: 'Contest #$contestId không tồn tại hoặc không có quyền xem',
    );
  }
  // Detail by slug để có rounds + sessions
  final detail = await api.dio.get('/contests/${found['slug']}');
  return detail.data as Map<String, dynamic>;
});

final contestRoundsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$contestId/rounds');
  return res.data as List<dynamic>;
});

final contestEntriesProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$contestId/entries');
  return res.data as List<dynamic>;
});

final roundResultsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, roundId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/rounds/$roundId/results');
    return res.data as List<dynamic>;
  } catch (_) {
    return [];
  }
});

final contestResultsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/contests/$contestId/results');
    return res.data as List<dynamic>;
  } catch (_) {
    return [];
  }
});

final certTemplatesProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$contestId/certificate-templates');
  return res.data as List<dynamic>;
});

// ---------- Screen ----------

class ContestAdminDetailScreen extends ConsumerStatefulWidget {
  final int contestId;
  const ContestAdminDetailScreen({super.key, required this.contestId});

  @override
  ConsumerState<ContestAdminDetailScreen> createState() =>
      _ContestAdminDetailScreenState();
}

class _ContestAdminDetailScreenState
    extends ConsumerState<ContestAdminDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(contestDetailAdminProvider(widget.contestId));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator(color: ptitRed)),
        error: (e, _) => _ErrorView(
          error: e,
          onBack: () => context.pop(),
        ),
        data: (contest) => Column(children: [
          _Header(contest: contest, onRefresh: () {
            ref.invalidate(contestDetailAdminProvider(widget.contestId));
          }),
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: ptitRed,
              unselectedLabelColor: textMuted,
              indicatorColor: ptitRed,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Vòng & Phiên'),
                Tab(text: 'Đăng ký'),
                Tab(text: 'Chấm điểm'),
                Tab(text: 'Kết quả'),
                Tab(text: 'Chứng nhận'),
              ],
            ),
          ),
          const Divider(height: 1, color: cardBorder),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _OverviewTab(contestId: widget.contestId, contest: contest),
                _RoundsTab(contestId: widget.contestId),
                _EntriesTab(contestId: widget.contestId),
                _JudgingTab(contestId: widget.contestId),
                _ResultsTab(contestId: widget.contestId, contestStatus: contest['status'] as String),
                _CertsTab(contestId: widget.contestId),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------- Header ----------

class _Header extends StatelessWidget {
  final Map<String, dynamic> contest;
  final VoidCallback onRefresh;
  const _Header({required this.contest, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      color: Colors.white,
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, size: 20, color: textPrimary),
          onPressed: () => context.pop(),
          tooltip: 'Quay lại',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('#${contest['contest_id']}',
                  style: const TextStyle(fontSize: 11, color: textMuted)),
              const SizedBox(width: 8),
              Pill.status(contest['status'] as String),
              const SizedBox(width: 6),
              Pill(
                label: contest['delivery_mode'] ?? 'HYBRID',
                color: textMuted,
                bg: const Color(0xFFF3F4F6),
              ),
              const SizedBox(width: 6),
              Pill(
                label: contest['participation_mode'] ?? 'INDIVIDUAL',
                color: textMuted,
                bg: const Color(0xFFF3F4F6),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              contest['title'] as String,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text('Slug: ${contest['slug']}',
                style: const TextStyle(fontSize: 11, color: textMuted)),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, color: textMuted, size: 20),
          tooltip: 'Refresh',
          onPressed: onRefresh,
        ),
      ]),
    );
  }
}

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMsg)),
      );
      ref.invalidate(contestDetailAdminProvider(widget.contestId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi $label: ${_msgOf(e)}')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa cuộc thi')),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xóa: ${_msgOf(e)}')),
      );
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

    String _safeFmt(dynamic v) =>
        v == null ? '—' : fmt.format(DateTime.parse(v as String).toLocal());

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Workflow timeline
        MCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Workflow tiếp theo',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textPrimary)),
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
            const Text(
              'Workflow chuẩn: DRAFT → submit QĐ1 → BCN duyệt → APPROVED → mở reg → SV đăng ký → ONGOING → judge chấm → FINISHED → tính kết quả → submit QĐ2 → BCN duyệt → publish → cấp cert.',
              style: TextStyle(fontSize: 11, color: textMuted, height: 1.5),
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
            _InfoRow('Loại', '${c['contest_type'] ?? '—'} · ${c['delivery_mode']} · ${c['participation_mode']}'),
            _InfoRow('Mở đăng ký', _safeFmt(c['reg_open_at'])),
            _InfoRow('Đóng đăng ký', _safeFmt(c['reg_close_at'])),
            _InfoRow('Bắt đầu thi', _safeFmt(c['start_at'])),
            _InfoRow('Kết thúc thi', _safeFmt(c['end_at'])),
            _InfoRow('Số entry tối đa', '${c['max_entries'] ?? "—"}'),
            _InfoRow('Cần nộp bài', (c['requires_submission'] == true) ? 'Có' : 'Không'),
            _InfoRow('Công khai', (c['is_public'] == true) ? 'Có' : 'Không'),
            _InfoRow('Submission policy', (c['submission_policy'] ?? '—').toString()),
            _InfoRow('Created at', _safeFmt(c['created_at'])),
          ]),
        ),
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
        backgroundColor: bg ?? Colors.white,
        foregroundColor: fg ?? textPrimary,
        side: const BorderSide(color: cardBorder),
        elevation: 0,
        textStyle:
            GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                style: const TextStyle(
                    fontSize: 11.5, color: textMuted, letterSpacing: 0.2)),
          ),
          Expanded(
              child:
                  Text(v, style: const TextStyle(fontSize: 13, color: textPrimary))),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo round')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tạo round: ${_msgOf(e)}')),
      );
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
        Expanded(
          child: asyncRounds.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: ptitRed)),
            error: (e, _) => Center(
                child: Text('Lỗi: ${_msgOf(e)}',
                    style: const TextStyle(color: ptitRed))),
            data: (rounds) => rounds.isEmpty
                ? const _Empty('Chưa có vòng nào. Thêm round đầu tiên để judge chấm.')
                : ListView.builder(
                    itemCount: rounds.length,
                    itemBuilder: (_, i) => _RoundCard(
                      contestId: widget.contestId,
                      round: rounds[i] as Map<String, dynamic>,
                    ),
                  ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã thêm criterion')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${_msgOf(e)}')),
      );
    }
  }

  Future<void> _computeRoundResults() async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio
          .post('/rounds/${widget.round['round_id']}/compute-results');
      ref.invalidate(roundResultsProvider(widget.round['round_id'] as int));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã compute ${(res.data as List).length} kết quả round')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi compute: ${_msgOf(e)}')),
      );
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
            Pill(label: r['round_type'].toString(), color: infoBlue, bg: infoSoft),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.bar_chart, size: 18, color: warnOrange),
            tooltip: 'Compute kết quả round (sau khi judge chấm xong)',
            onPressed: _computeRoundResults,
          ),
        ]),
        if ((r['description'] ?? '').toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(r['description'] as String,
              style: const TextStyle(fontSize: 12, color: textMuted)),
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
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Chưa có criterion nào',
                        style: TextStyle(fontSize: 12, color: textMuted)),
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
                            style: const TextStyle(
                                fontSize: 11, color: textMuted)),
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
                  value: _type,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cần chọn thời gian bắt đầu + kết thúc')),
                    );
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

// ---------- TAB 3: Entries ----------

class _EntriesTab extends ConsumerStatefulWidget {
  final int contestId;
  const _EntriesTab({required this.contestId});

  @override
  ConsumerState<_EntriesTab> createState() => _EntriesTabState();
}

class _EntriesTabState extends ConsumerState<_EntriesTab> {
  Future<void> _decide(int entryId, String action) async {
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.patch('/entries/$entryId',
          data: {'action': action, 'note': action == 'reject' ? 'Reject từ admin panel' : null});
      ref.invalidate(contestEntriesProvider(widget.contestId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã ${action == 'approve' ? 'duyệt' : 'từ chối'} entry')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${_msgOf(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncEntries = ref.watch(contestEntriesProvider(widget.contestId));
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Đăng ký của SV — duyệt entries',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
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
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i] as Map<String, dynamic>;
                      final st = e['status'] as String;
                      return MCard(
                        child: Row(children: [
                          Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Entry #${e['entry_id']} · ${e['entry_kind']}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(
                                      'SV user #${e['student_user_id'] ?? '—'}'
                                      ' · Team ${e['team_id'] ?? '—'}'
                                      ' · Đăng ký lúc ${_safeFmtIso(e['registered_at'])}',
                                      style: const TextStyle(
                                          fontSize: 11, color: textMuted)),
                                ]),
                          ),
                          Pill.status(st),
                          const SizedBox(width: 10),
                          if (st == 'PENDING') ...[
                            IconButton(
                              icon: const Icon(Icons.check,
                                  color: successGreen, size: 20),
                              tooltip: 'Duyệt',
                              onPressed: () =>
                                  _decide(e['entry_id'] as int, 'approve'),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.close, color: ptitRed, size: 20),
                              tooltip: 'Từ chối',
                              onPressed: () =>
                                  _decide(e['entry_id'] as int, 'reject'),
                            ),
                          ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã assign judge')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${_msgOf(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncRounds = ref.watch(contestRoundsProvider(widget.contestId));
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Phân công Judge cho từng round',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text(
            'Mỗi assignment = 1 judge chấm 1 entry trong 1 round. Cần entry_id (ID đăng ký SV) + judge_id (ID judge từ tab Quản lý user).',
            style: TextStyle(fontSize: 11, color: textMuted)),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Vui lòng nhập số Entry/Judge ID hợp lệ')),
                    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã compute ${(res.data as List).length} kết quả')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi compute: ${_msgOf(e)}')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã submit QĐ2 cho BCN duyệt')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${_msgOf(e)}')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã publish, contest = FINISHED')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi publish: ${_msgOf(e)}')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã update award')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${_msgOf(e)}')),
      );
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
              bg: warnOrange,
              fg: Colors.white,
              onTap: _submitQd2),
          _ActionBtn(
              label: '3. Publish results (cần BCN OK)',
              icon: Icons.publish,
              bg: successGreen,
              fg: Colors.white,
              onTap: _publish),
        ]),
        const SizedBox(height: 6),
        Text('Status hiện tại: $st',
            style: const TextStyle(fontSize: 11, color: textMuted)),
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
                            child: Text('#${r['rank'] ?? '-'}',
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
                                      'Entry #${r['entry_id']} · Final score ${r['final_score']?.toStringAsFixed(2) ?? '—'}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700)),
                                  if ((r['award_title'] ?? '').toString().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Pill(
                                        label: r['award_title'] as String,
                                        color: warnOrange,
                                        bg: warnSoft,
                                      ),
                                    ),
                                ]),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 18, color: textMuted),
                            tooltip: 'Sửa giải thưởng',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo template — chờ BCN duyệt (QĐ3)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${_msgOf(e)}')),
      );
    }
  }

  Future<void> _activate(int templateId) async {
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.patch('/certificate-templates/$templateId/activate');
      ref.invalidate(certTemplatesProvider(widget.contestId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã activate template')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${_msgOf(e)}')),
      );
    }
  }

  Future<void> _issueCerts(bool onlyAward) async {
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio.post(
          '/contests/${widget.contestId}/certificates/issue',
          data: {'only_with_award': onlyAward});
      if (!mounted) return;
      final issued = (res.data is Map) ? (res.data['issued'] ?? 0) : 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cấp $issued certificates')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${_msgOf(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncTpl = ref.watch(certTemplatesProvider(widget.contestId));
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
        const Text(
            'Workflow: tạo template → BCN duyệt (QĐ3) qua tab Phê duyệt → BTC activate → cấp cert hàng loạt cho results.',
            style: TextStyle(fontSize: 11, color: textMuted)),
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
                      final st = t['approval_status'] as String? ?? '—';
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
                                    Pill(label: 'Approval: $st',
                                        color: st == 'APPROVED' ? successGreen : warnOrange,
                                        bg: st == 'APPROVED' ? successSoft : warnSoft),
                                    const SizedBox(width: 6),
                                    if (isActive)
                                      const Pill(
                                        label: 'ACTIVE',
                                        color: successGreen,
                                        bg: successSoft,
                                      ),
                                  ]),
                                ]),
                          ),
                          if (st == 'APPROVED' && !isActive)
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
            const Text(
                'HTML template — dùng {{full_name}}, {{student_code}}, {{award_title}}, {{contest_title}}, {{issued_date}}, {{qr_code}}',
                style: TextStyle(fontSize: 11, color: textMuted)),
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

// ---------- Helpers ----------

String _msgOf(Object e) {
  if (e is DioException) {
    if (e.response?.data is Map && (e.response!.data as Map)['detail'] != null) {
      return (e.response!.data as Map)['detail'].toString();
    }
    return e.message ?? '$e';
  }
  return '$e';
}

String _safeFmtIso(dynamic iso) {
  if (iso == null) return '—';
  try {
    return DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(iso as String).toLocal());
  } catch (_) {
    return '—';
  }
}

class _Empty extends StatelessWidget {
  final String msg;
  const _Empty(this.msg);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inbox_outlined, size: 48, color: textMuted),
            const SizedBox(height: 10),
            Text(msg,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textMuted, fontSize: 13)),
          ]),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onBack;
  const _ErrorView({required this.error, required this.onBack});
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: ptitRed),
            const SizedBox(height: 12),
            Text('Lỗi: ${_msgOf(error)}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onBack, child: const Text('Quay lại')),
          ]),
        ),
      );
}
