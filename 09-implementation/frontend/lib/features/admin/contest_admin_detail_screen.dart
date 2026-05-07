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

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/download_helper.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';
import '../../core/xlsx_export_helper.dart';

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
      backgroundColor: context.appBg,
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
            color: context.cardBg,
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: ptitRed,
              unselectedLabelColor: context.textMuted,
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
          Divider(height: 1, color: context.cardBorder),
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
      color: context.cardBg,
      child: Row(children: [
        IconButton(
          // Sprint 3 a11y fix: tooltip cho back arrow IconButton
          tooltip: 'Quay lại',
          icon: Icon(Icons.arrow_back, size: 20, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('#${contest['contest_id']}',
                  style: TextStyle(fontSize: 11, color: context.textMuted)),
              const SizedBox(width: 8),
              Pill.status(contest['status'] as String),
              const SizedBox(width: 6),
              Pill(
                label: contest['delivery_mode'] ?? 'HYBRID',
                color: context.textMuted,
                bg: const Color(0xFFF3F4F6),
              ),
              const SizedBox(width: 6),
              Pill(
                label: contest['participation_mode'] ?? 'INDIVIDUAL',
                color: context.textMuted,
                bg: const Color(0xFFF3F4F6),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              contest['title'] as String,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text('Slug: ${contest['slug']}',
                style: TextStyle(fontSize: 11, color: context.textMuted)),
          ]),
        ),
        IconButton(
          icon: Icon(Icons.refresh, color: context.textMuted, size: 20),
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
            _InfoRow('Mở đăng ký', _safeFmt(c['registration_open_at'])),
            _InfoRow('Đóng đăng ký', _safeFmt(c['registration_close_at'])),
            _InfoRow('Bắt đầu thi', _safeFmt(c['start_at'])),
            _InfoRow('Kết thúc thi', _safeFmt(c['end_at'])),
            _InfoRow('Số entry tối đa', '${c['max_entries'] ?? "—"}'),
            _InfoRow('Team size', c['participation_mode'] == 'TEAM'
                ? '${c['team_min_members'] ?? "?"} - ${c['team_max_members'] ?? "?"} thành viên'
                : 'Cá nhân'),
            _InfoRow('Cần nộp bài', (c['requires_submission'] == true) ? 'Có' : 'Không'),
            _InfoRow('Công khai', (c['is_public'] == true) ? 'Có' : 'Không'),
            _InfoRow('Created at', _safeFmt(c['created_at'])),
            _InfoRow('Owner user_id', '#${c['created_by'] ?? '—'}'),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: failed.isEmpty ? context.successGreen : Colors.orange,
      ));
      if (failed.isNotEmpty) {
        debugPrint('Bulk review failed items: $failed');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi bulk: ${_msgOf(e)}')),
      );
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

  /// Phase 2 sprint 1 step 3 (2026-05-06): download Excel kết quả contest.
  /// 4 sheets (Tổng quan / Vòng / Submissions / Metadata).
  Future<void> _exportXlsx() async {
    final api = ref.read(apiClientProvider);
    try {
      // Show snack báo đang chuẩn bị file (UX: large contests có thể mất 3-5s)
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đang chuẩn bị file Excel...'),
        duration: Duration(seconds: 1),
      ));

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã tải về: $filename'),
          backgroundColor: context.successGreen,
        ));
      } on UnsupportedError catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Không hỗ trợ trên platform này')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xuất Excel: ${_msgOf(e)}')),
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
                            icon: Icon(Icons.edit_outlined,
                                size: 18, color: context.textMuted),
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
      final d = res.data is Map ? res.data as Map : {};
      final issued = d['issued_count'] ?? d['issued'] ?? 0;
      final skipped = d['skipped_count'] ?? d['skipped'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cấp $issued certificates · skipped $skipped')),
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
        Text(
            'Workflow: tạo template → BCN duyệt (QĐ3) qua tab Phê duyệt → BTC activate → cấp cert hàng loạt cho results.',
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
            Icon(Icons.inbox_outlined, size: 48, color: context.textMuted),
            const SizedBox(height: 10),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted, fontSize: 13)),
          ]),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onBack;
  const _ErrorView({required this.error, required this.onBack});
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
          FilledButton(onPressed: onBack, child: const Text('Quay lại')),
        ]),
      ),
    );
  }
}
