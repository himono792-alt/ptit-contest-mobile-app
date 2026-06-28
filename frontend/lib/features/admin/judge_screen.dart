// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/config.dart';
import '../../core/secure_storage.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/help_button.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/pill.dart';

final myAssignmentsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/me/judge-assignments');
  return res.data as List<dynamic>;
});

class JudgeScreen extends ConsumerWidget {
  const JudgeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(myAssignmentsProvider);
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
                  Text('Judge',
                      style: TextStyle(color: context.textMuted, fontSize: 11)),
                  SizedBox(height: 2),
                  Text('Bài cần chấm',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                ],
              ),
            ),
            const HelpButton(id: 'gv_judge'),
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: context.textMuted),
              onPressed: () => ref.invalidate(myAssignmentsProvider),
            ),
          ]),
        ),
        Expanded(
          child: asyncList.when(
            // Sprint 8c (2026-05-07): skeleton thay spinner.
            loading: () => const MCardListSkeleton(count: 3),
            error: (e, _) => Center(
                child: Text(FriendlyError.of(e),
                    style: const TextStyle(color: ptitRed))),
            data: (items) => items.isEmpty
                ? const EmptyView(
                    icon: Icons.gavel,
                    title: 'Chưa có assignment nào',
                    subtitle: 'GV/BTC cần phân công bạn chấm round trước.',
                  )
                : _JudgeBody(items: items.cast<Map<String, dynamic>>()),
          ),
        ),
      ]),
    );
  }
}

// Redesign 2026-06-20: tái cấu trúc — hero + stat strip + nhóm theo cuộc thi →
// vòng (collapsible) với progress bar. Scale tốt khi chấm nhiều cuộc thi.
class _JudgeBody extends ConsumerWidget {
  final List<Map<String, dynamic>> items;
  const _JudgeBody({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final unscored =
        items.where((it) => it['is_scored'] != true).toList();
    final scoredCount = items.length - unscored.length;

    // Nhóm theo cuộc thi.
    final byContest = <String, List<Map<String, dynamic>>>{};
    final contestTitleByKey = <String, String>{};
    for (final it in items) {
      final cid = it['contest_id'];
      final key = cid?.toString() ?? 'round-${it['round_id']}';
      byContest.putIfAbsent(key, () => []).add(it);
      contestTitleByKey[key] = (it['contest_title'] as String?) ??
          'Cuộc thi #${cid ?? '—'}';
    }
    // Cuộc thi còn bài chưa chấm lên đầu.
    final keys = byContest.keys.toList()
      ..sort((a, b) {
        int remaining(String k) =>
            byContest[k]!.where((it) => it['is_scored'] != true).length;
        final r = remaining(b).compareTo(remaining(a));
        if (r != 0) return r;
        return contestTitleByKey[a]!.compareTo(contestTitleByKey[b]!);
      });

    final firstUnscored = unscored.isNotEmpty ? unscored.first : null;

    return ListView(
      padding: EdgeInsets.fromLTRB(
          isMobile ? 14 : 24, 16, isMobile ? 14 : 24, 24),
      children: [
        _TodayJudgingHeroCard(
          count: unscored.length,
          onStart: firstUnscored == null
              ? () {}
              : () => _openScoreDialog(context, ref, firstUnscored,
                  remaining: unscored.skip(1).toList()),
        ),
        const SizedBox(height: 16),
        _JudgeStatStrip(
          total: items.length,
          scored: scoredCount,
          pending: unscored.length,
        ),
        const SizedBox(height: 16),
        for (final k in keys)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ContestJudgeGroup(
              contestTitle: contestTitleByKey[k]!,
              assignments: byContest[k]!,
            ),
          ),
      ],
    );
  }
}

class _JudgeStatStrip extends StatelessWidget {
  final int total;
  final int scored;
  final int pending;
  const _JudgeStatStrip(
      {required this.total, required this.scored, required this.pending});

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : scored / total;
    return Row(children: [
      Expanded(
        child: _JudgeMiniStat(
          value: '$pending',
          label: 'Cần chấm',
          color: ptitRed,
          icon: Icons.gavel_outlined,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _JudgeMiniStat(
          value: '$scored',
          label: 'Đã chấm',
          color: context.successGreen,
          icon: Icons.check_circle_outline,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _JudgeMiniStat(
          value: '${(pct * 100).round()}%',
          label: 'Tiến độ',
          color: infoBlue,
          icon: Icons.donut_large_outlined,
        ),
      ),
    ]);
  }
}

class _JudgeMiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _JudgeMiniStat(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      color: context.textPrimary)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.textMuted)),
            ],
          ),
        ),
      ]),
    );
  }
}

/// Nhóm 1 cuộc thi: header (tên + tiến độ + chevron) + collapsible nội dung
/// nhóm tiếp theo vòng. Mặc định mở nếu còn bài chưa chấm.
class _ContestJudgeGroup extends StatefulWidget {
  final String contestTitle;
  final List<Map<String, dynamic>> assignments;
  const _ContestJudgeGroup(
      {required this.contestTitle, required this.assignments});

  @override
  State<_ContestJudgeGroup> createState() => _ContestJudgeGroupState();
}

class _ContestJudgeGroupState extends State<_ContestJudgeGroup> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    final pending =
        widget.assignments.where((it) => it['is_scored'] != true).length;
    _expanded = pending > 0;
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.assignments.length;
    final scored =
        widget.assignments.where((it) => it['is_scored'] == true).length;
    final pct = total == 0 ? 0.0 : scored / total;
    final allDone = scored == total && total > 0;

    // Nhóm theo vòng.
    final byRound = <int, List<Map<String, dynamic>>>{};
    final roundLabel = <int, String>{};
    for (final it in widget.assignments) {
      final rid = (it['round_id'] as int?) ?? 0;
      byRound.putIfAbsent(rid, () => []).add(it);
      final no = it['round_no'];
      final name = it['round_name'] as String?;
      roundLabel[rid] = name != null
          ? (no != null ? 'Vòng $no · $name' : name)
          : 'Vòng #$rid';
    }
    final roundIds = byRound.keys.toList()
      ..sort((a, b) {
        final na = (byRound[a]!.first['round_no'] as int?) ?? a;
        final nb = (byRound[b]!.first['round_no'] as int?) ?? b;
        return na.compareTo(nb);
      });

    return Container(
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: [
        // Header.
        InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (allDone ? context.successGreen : ptitRed)
                        .withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                      allDone ? Icons.verified_outlined : Icons.gavel,
                      color: allDone ? context.successGreen : ptitRed,
                      size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.contestTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary)),
                      const SizedBox(height: 2),
                      Text('Đã chấm $scored/$total bài',
                          style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: context.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    color: context.textMuted, size: 22),
              ]),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.tight),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 5,
                  backgroundColor: context.cardBorder.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation(
                      allDone ? context.successGreen : ptitRed),
                ),
              ),
            ]),
          ),
        ),
        // Nội dung collapsible.
        if (_expanded) ...[
          Divider(height: 1, color: context.cardBorder),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Column(children: [
              for (final rid in roundIds) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Row(children: [
                    Icon(Icons.flag_outlined,
                        size: 14, color: context.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(roundLabel[rid]!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                    ),
                    Text('${byRound[rid]!.length} bài',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.textMuted)),
                  ]),
                ),
                for (final it in _orderRound(byRound[rid]!)) _AssignmentCard(data: it),
              ],
            ]),
          ),
        ],
      ]),
    );
  }

  // Chưa chấm lên trước, đã chấm xuống sau.
  List<Map<String, dynamic>> _orderRound(List<Map<String, dynamic>> list) {
    final pending = list.where((it) => it['is_scored'] != true).toList();
    final done = list.where((it) => it['is_scored'] == true).toList();
    return [...pending, ...done];
  }
}

class _AssignmentCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  const _AssignmentCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    final canSeeId = data['can_view_identity'] as bool? ?? false;
    // Sprint 18 fix (2026-05-08): is_scored + scored_count enriched từ BE.
    final isScored = data['is_scored'] == true;
    final scored = data['scored_count'] as int? ?? 0;
    final total = data['total_criteria'] as int? ?? 0;

    return MCard(
      onTap: () => _openScoreDialog(context, ref, data),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Assignment #${data['assignment_id']}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary)),
            ),
            // Sprint 18: pill "Đã chấm" green ưu tiên hiện nếu scored.
            if (isScored)
              Pill(
                label: 'Đã chấm',
                color: context.successGreen,
                bg: context.successSoft,
              )
            else
              Pill(
                label: canSeeId ? 'Open judging' : 'Blind',
                color: canSeeId ? infoBlue : context.warnOrange,
                bg: canSeeId ? context.infoSoft : context.warnSoft,
              ),
          ]),
          const SizedBox(height: 6),
          Text(
              'Round #${data['round_id']} · Entry #${data['entry_id']}'
              '${data['submission_id'] != null ? ' · Submission #${data['submission_id']}' : ''}',
              style: TextStyle(fontSize: 12, color: context.textMuted)),
          const SizedBox(height: 4),
          Text('Assigned at: ${fmt.format(DateTime.parse(data['assigned_at']))}',
              style: TextStyle(fontSize: 11, color: context.textMuted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isScored ? context.successSoft : context.ptitRedSoft,
              borderRadius: BorderRadius.circular(AppRadius.tight),
            ),
            child: Text(
                isScored
                    ? 'Đã chấm $scored/$total tiêu chí · Tap xem/sửa'
                    : (total > 0
                        ? 'Tap để chấm điểm ($total tiêu chí)'
                        : 'Tap để nhập điểm'),
                style: TextStyle(
                    fontSize: 11,
                    color: isScored ? context.successGreen : ptitRed,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

}

// Sprint 16 (2026-05-08): top-level helper để hero card + assignment card share.
// Q2: `remaining` enables "Lưu & tiếp" chaining through unscored assignments.
Future<void> _openScoreDialog(
    BuildContext context, WidgetRef ref, Map<String, dynamic> data,
    {List<Map<String, dynamic>> remaining = const []}) async {
  final result = await showDialog<Object?>(
    context: context,
    builder: (_) => _ScoreDialog(assignment: data, hasNext: remaining.isNotEmpty),
  );
  ref.invalidate(myAssignmentsProvider);
  if (result == 'next' && remaining.isNotEmpty && context.mounted) {
    await _openScoreDialog(context, ref, remaining.first,
        remaining: remaining.sublist(1));
  }
}

class _ScoreDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> assignment;
  final bool hasNext;
  const _ScoreDialog({required this.assignment, this.hasNext = false});
  @override
  ConsumerState<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends ConsumerState<_ScoreDialog> {
  List<Map<String, dynamic>>? _criteria;
  final Map<int, TextEditingController> _scoreCtrls = {};
  final Map<int, TextEditingController> _commentCtrls = {};
  bool _busy = false;
  String? _loadError;

  // Bài làm của SV
  Map<String, dynamic>? _submission;
  bool _submissionLoading = false;
  String? _submissionError;

  // Điểm đã chấm: criterion_id → ScoreOut
  Map<int, Map<String, dynamic>> _existingScores = {};

  @override
  void initState() {
    super.initState();
    _loadCriteria();
    _loadSubmission();
  }

  @override
  void dispose() {
    for (final c in _scoreCtrls.values) {
      c.dispose();
    }
    for (final c in _commentCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSubmission() async {
    setState(() => _submissionLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final submissionId = widget.assignment['submission_id'];
      final roundId = widget.assignment['round_id'];
      final entryId = widget.assignment['entry_id'];

      Map<String, dynamic>? found;
      if (submissionId != null) {
        // Fast path: submission_id đã có trong assignment → fetch detail trực tiếp
        final res = await api.dio.get('/submissions/$submissionId');
        found = res.data as Map<String, dynamic>;
      } else {
        // Fallback: BTC tạo assignment trước khi SV nộp —
        // list submissions của round rồi tìm entry, sau đó fetch detail để có files
        final listRes = await api.dio.get('/rounds/$roundId/submissions');
        final list = (listRes.data as List).cast<Map<String, dynamic>>();
        final stub = list.where((s) => s['entry_id'] == entryId).firstOrNull;
        if (stub != null) {
          final detailRes =
              await api.dio.get('/submissions/${stub['submission_id']}');
          found = detailRes.data as Map<String, dynamic>;
        }
      }

      setState(() {
        _submission = found;
        _submissionLoading = false;
      });
    } catch (e) {
      setState(() {
        _submissionError = FriendlyError.of(e);
        _submissionLoading = false;
      });
    }
  }

  Future<void> _loadCriteria() async {
    try {
      final api = ref.read(apiClientProvider);
      final assignmentId = widget.assignment['assignment_id'];

      // Load criteria + existing scores song song
      final results = await Future.wait([
        api.dio.get('/rounds/${widget.assignment['round_id']}/criteria'),
        api.dio.get('/assignments/$assignmentId/scores'),
      ]);

      final list = (results[0].data as List).cast<Map<String, dynamic>>();
      final scoreList = (results[1].data as List).cast<Map<String, dynamic>>();
      final scoresByCriterion = {
        for (final s in scoreList) s['criterion_id'] as int: s,
      };

      setState(() {
        _criteria = list;
        _existingScores = scoresByCriterion;
        for (final c in list) {
          final id = c['criterion_id'] as int;
          final existing = scoresByCriterion[id];
          _scoreCtrls[id] = TextEditingController(
            text: existing != null
                ? existing['score_value'].toString()
                : '',
          );
          _commentCtrls[id] = TextEditingController(
            text: existing?['comment_text'] as String? ?? '',
          );
        }
      });
    } catch (e) {
      setState(() => _loadError = FriendlyError.of(e));
    }
  }

  Future<List<Map<String, dynamic>>?> _buildScores() async {
    if (_criteria == null || _criteria!.isEmpty) return null;
    final scores = <Map<String, dynamic>>[];
    for (final c in _criteria!) {
      final id = c['criterion_id'] as int;
      final raw = _scoreCtrls[id]?.text.trim() ?? '';
      if (raw.isEmpty) {
        AppToast.info(context, 'Cần điểm cho "${c['criterion_name']}"');
        return null;
      }
      final val = double.tryParse(raw);
      if (val == null) {
        AppToast.info(context, 'Điểm không hợp lệ ở "${c['criterion_name']}"');
        return null;
      }
      final maxScore = double.parse(c['max_score'].toString());
      if (val < 0 || val > maxScore) {
        AppToast.info(context, 'Điểm "${c['criterion_name']}" phải 0..$maxScore');
        return null;
      }
      scores.add({
        'criterion_id': id,
        'score_value': val,
        if (_commentCtrls[id]!.text.isNotEmpty)
          'comment_text': _commentCtrls[id]!.text,
      });
    }
    return scores;
  }

  Future<void> _submit({bool andNext = false}) async {
    final scores = await _buildScores();
    if (scores == null) return;
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post(
          '/assignments/${widget.assignment['assignment_id']}/scores',
          data: {'scores': scores});
      if (!mounted) return;
      Navigator.pop(context, andNext ? 'next' : true);
      AppToast.success(context, 'Đã submit điểm');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () => _submit(),
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
            child: _criteria == null
                ? SizedBox(
                    width: 640,
                    height: 240,
                    child: Center(
                        child: _loadError == null
                            ? const CircularProgressIndicator(color: ptitRed)
                            : Text('Lỗi load criteria: $_loadError',
                                style: const TextStyle(color: ptitRed))))
                : _buildContent(context),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final a = widget.assignment;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.cardBorder)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      _existingScores.isNotEmpty
                          ? 'Sửa điểm — Assignment #${a['assignment_id']}'
                          : 'Chấm điểm — Assignment #${a['assignment_id']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (_existingScores.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Pill(
                        label: 'Đã chấm',
                        color: const Color(0xFF059669),
                        bg: const Color(0xFFD1FAE5),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      'Round #${a['round_id']} · Entry #${a['entry_id']}'
                      '${a['submission_id'] != null ? ' · Submission #${a['submission_id']}' : ''}',
                      style: TextStyle(fontSize: 12, color: context.textMuted)),
                ]),
          ),
          IconButton(
              tooltip: 'Đóng',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context, false)),
        ]),
      ),
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Bài làm của SV ── (luôn hiện, kể cả SV chưa nộp)
              _buildSubmissionPanel(context),
              const SizedBox(height: 16),
              Divider(color: context.cardBorder),
              const SizedBox(height: 12),
              // ── Tiêu chí chấm ──
              if (_criteria!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                      child: Text(
                          'Round này chưa có criteria. GV BTC cần thêm rubric trước.',
                          style: TextStyle(color: context.textMuted))),
                )
              else ...[
                Text('Tiêu chí chấm',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.textMuted,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),
                ..._criteria!.map((c) => _buildCriterion(context, c)),
              ],
            ],
          ),
        ),
      ),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: context.cardBorder)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
              onPressed:
                  _busy ? null : () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          const SizedBox(width: 10),
          if (widget.hasNext) ...[
            OutlinedButton.icon(
              onPressed: (_busy || (_criteria?.isEmpty ?? true))
                  ? null
                  : () => _submit(andNext: true),
              icon: const Icon(Icons.skip_next, size: 16),
              label: const Text('Lưu & tiếp'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(120, 38)),
            ),
            const SizedBox(width: 8),
          ],
          Tooltip(
            message: 'Ctrl+Enter',
            child: FilledButton.icon(
              onPressed:
                  (_busy || (_criteria?.isEmpty ?? true)) ? null : () => _submit(),
              icon: Icon(
                _existingScores.isNotEmpty ? Icons.edit : Icons.send,
                size: 16,
              ),
              label: Text(
                _existingScores.isNotEmpty ? 'Cập nhật điểm' : 'Submit điểm',
              ),
              style: FilledButton.styleFrom(
                  minimumSize: const Size(140, 38),
                  backgroundColor: ptitRed),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildCriterion(BuildContext context, Map<String, dynamic> c) {
    final id = c['criterion_id'] as int;
    final maxScore = c['max_score'].toString();
    final weight = c['weight_percent'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appBg,
          border: Border.all(color: context.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(c['criterion_name'] ?? '',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              if (weight != null)
                Pill(
                    label: 'weight $weight%',
                    color: infoBlue,
                    bg: context.infoSoft),
              const SizedBox(width: 6),
              Pill(
                  label: 'max $maxScore',
                  color: context.textMuted,
                  bg: const Color(0xFFF3F4F6)),
            ]),
            if (c['description'] != null) ...[
              const SizedBox(height: 4),
              Text(c['description'],
                  style: TextStyle(fontSize: 11, color: context.textMuted)),
            ],
            const SizedBox(height: 8),
            Row(children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _scoreCtrls[id],
                  decoration: InputDecoration(
                    labelText: 'Điểm *',
                    isDense: true,
                    hintText: '0–$maxScore',
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _commentCtrls[id],
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    isDense: true,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  /// Panel hiển thị bài làm (file, link, text answer) của SV.
  Widget _buildSubmissionPanel(BuildContext context) {
    if (_submissionLoading) {
      return Row(children: [
        const SizedBox(
            width: 14, height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: ptitRed)),
        const SizedBox(width: 8),
        Text('Đang tải bài làm…',
            style: TextStyle(fontSize: 12, color: context.textMuted)),
      ]);
    }
    if (_submissionError != null) {
      return Row(children: [
        Icon(Icons.warning_amber_rounded, size: 14, color: context.textMuted),
        const SizedBox(width: 6),
        Text('Không tải được bài làm: $_submissionError',
            style: TextStyle(fontSize: 12, color: context.textMuted)),
      ]);
    }
    if (_submission == null) {
      return Row(children: [
        Icon(Icons.inbox_outlined, size: 14, color: context.textMuted),
        const SizedBox(width: 6),
        Text('SV chua nop bai cho vong nay.',
            style: TextStyle(fontSize: 12, color: context.textMuted)),
      ]);
    }

    // Lấy version mới nhất (version_no cao nhất)
    final versions = (_submission!['versions'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    if (versions.isEmpty) {
      return Row(children: [
        Icon(Icons.inbox_outlined, size: 14, color: context.textMuted),
        const SizedBox(width: 6),
        Text('SV chưa nộp file nào.',
            style: TextStyle(fontSize: 12, color: context.textMuted)),
      ]);
    }
    versions.sort((a, b) =>
        (b['version_no'] as int).compareTo(a['version_no'] as int));
    final latest = versions.first;
    final files = (latest['files'] as List? ?? []).cast<Map<String, dynamic>>();
    final externalLink = latest['external_link'] as String?;
    final textAnswer = latest['text_answer'] as String?;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.folder_open_outlined, size: 14, color: context.textMuted),
        const SizedBox(width: 6),
        Text(
          'Bài làm — Version #${latest['version_no']}',
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.textMuted,
              letterSpacing: 0.5),
        ),
      ]),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appBg,
          border: Border.all(color: context.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Files
          if (files.isNotEmpty) ...[
            ...files.map((f) => _buildFileRow(context, f)),
          ] else if (externalLink == null && textAnswer == null)
            Text('(Không có tệp đính kèm)',
                style: TextStyle(fontSize: 12, color: context.textMuted)),
          // External link
          if (externalLink != null && externalLink.isNotEmpty) ...[
            if (files.isNotEmpty) const SizedBox(height: 6),
            _buildLinkRow(context, externalLink),
          ],
          // Text answer
          if (textAnswer != null && textAnswer.isNotEmpty) ...[
            if (files.isNotEmpty || externalLink != null)
              const SizedBox(height: 8),
            Text('Câu trả lời văn bản:',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.textMuted)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: context.cardBorder),
              ),
              child: SelectableText(
                textAnswer,
                style: TextStyle(fontSize: 12, color: context.textPrimary),
              ),
            ),
          ],
        ]),
      ),
    ]);
  }

  // Download file dùng dart:html XHR trực tiếp (responseType='blob') để giữ
  // binary data nguyên vẹn và tránh vấn đề async context trong Flutter web.
  Future<void> _downloadFile(String fileUrl, String fileName) async {
    try {
      final token = await ref.read(tokenStorageProvider).readToken();
      final fullUrl = '${AppConfig.apiBaseUrl}$fileUrl';

      final request = html.HttpRequest();
      request.open('GET', fullUrl, async: true);
      request.responseType = 'arraybuffer';
      if (token != null && token.isNotEmpty) {
        request.setRequestHeader('Authorization', 'Bearer $token');
      }

      final completer = Completer<void>();
      request.onLoad.listen((_) {
        try {
          if (request.status != 200) {
            completer.completeError(
              Exception('HTTP ${request.status}: không tải được file'),
            );
            return;
          }
          final buffer = request.response as ByteBuffer;
          final bytes = buffer.asUint8List();
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          Future.delayed(
            const Duration(milliseconds: 300),
            () => html.Url.revokeObjectUrl(url),
          );
          completer.complete();
        } catch (e) {
          completer.completeError(e);
        }
      });
      request.onError.listen((_) {
        completer.completeError(Exception('Không kết nối được máy chủ. Kiểm tra mạng hoặc thử lại sau.'));
      });

      request.send();
      await completer.future;
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    }
  }

  static String _mimeOf(String name) {
    final n = name.toLowerCase();
    if (n.endsWith('.pdf')) return 'application/pdf';
    if (n.endsWith('.zip')) return 'application/zip';
    if (n.endsWith('.docx')) return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    if (n.endsWith('.xlsx')) return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    if (n.endsWith('.png')) return 'image/png';
    if (n.endsWith('.jpg') || n.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  Widget _buildFileRow(BuildContext context, Map<String, dynamic> f) {
    final fileName = f['file_name'] as String? ?? 'file';
    final fileUrl = f['file_url'] as String? ?? '';
    final bytes = f['file_size_bytes'] as int?;
    final sizeLabel = bytes == null
        ? ''
        : bytes < 1024
            ? ' · ${bytes}B'
            : bytes < 1024 * 1024
                ? ' · ${(bytes / 1024).toStringAsFixed(0)}KB'
                : ' · ${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => _downloadFile(fileUrl, fileName),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Row(children: [
            Icon(Icons.attach_file, size: 14, color: ptitRed),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$fileName$sizeLabel',
                style: const TextStyle(
                    fontSize: 12,
                    color: ptitRed,
                    decoration: TextDecoration.underline),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.download_outlined, size: 14, color: context.textMuted),
          ]),
        ),
      ),
    );
  }

  Widget _buildLinkRow(BuildContext context, String url) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => html.window.open(url, '_blank'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
        child: Row(children: [
          Icon(Icons.link, size: 14, color: infoBlue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              url,
              style: TextStyle(
                  fontSize: 12,
                  color: infoBlue,
                  decoration: TextDecoration.underline),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.open_in_new, size: 14, color: context.textMuted),
        ]),
      ),
    );
  }
}


/// Sprint 16 (2026-05-08): hero card "Hôm nay cần chấm" theo design gv-01.
/// - Gradient red `ptitGradientHero`, count to + CTA bắt đầu chấm bài đầu tiên.
/// - Click "Bắt đầu chấm" mở dialog của assignment đầu tiên trong list.
class _TodayJudgingHeroCard extends StatelessWidget {
  final int count;
  final VoidCallback onStart;

  const _TodayJudgingHeroCard({required this.count, required this.onStart});

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, dd/MM').format(DateTime.now());
    // Sprint 18 fix (2026-05-08): khi count=0 (đã chấm hết) → gradient xanh
    // success + label "Đã chấm xong tất cả" thay vì gradient red disabled.
    final allDone = count == 0;
    final gradient = allDone
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF10B981), Color(0xFF34D399)],
          )
        : ptitGradientHero;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(allDone ? Icons.check_circle_outline : Icons.gavel,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(allDone ? 'Đã chấm xong tất cả' : 'Hôm nay cần chấm',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4)),
              ]),
              const SizedBox(height: 8),
              if (allDone)
                Text('Hoàn thành',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1))
              else
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                  Text('$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w800,
                          height: 1)),
                  const SizedBox(width: 6),
                  Text('bài',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                ]),
              const SizedBox(height: 2),
              Text(today,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 11)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        if (!allDone)
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Bắt đầu chấm'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ptitRed,
              minimumSize: const Size(140, 40),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.tight)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
      ]),
    );
  }
}
