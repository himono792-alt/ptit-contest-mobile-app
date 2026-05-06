import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
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
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(children: [
        if (!isMobile) Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
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
            IconButton(
              tooltip: 'Refresh',
              icon: Icon(Icons.refresh, color: context.textMuted),
              onPressed: () => ref.invalidate(myAssignmentsProvider),
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
            data: (items) => items.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.gavel, size: 56, color: context.textMuted),
                        SizedBox(height: 12),
                        Text(
                            'Bạn chưa có assignment nào.\nGV BTC cần phân công bạn chấm round trước.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.textMuted, fontSize: 13)),
                      ]),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(isMobile ? 14 : 24, 16, isMobile ? 14 : 24, 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) =>
                        _AssignmentCard(data: items[i] as Map<String, dynamic>),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  const _AssignmentCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yy HH:mm');
    final canSeeId = data['can_view_identity'] as bool? ?? false;

    return MCard(
      onTap: () => _openScoreDialog(context, ref),
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
            Pill(
              label: canSeeId ? 'Open judging' : 'Blind',
              color: canSeeId ? context.infoBlue : context.warnOrange,
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
              color: context.ptitRedSoft,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text('Tap để nhập điểm',
                style: TextStyle(
                    fontSize: 11, color: ptitRed, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _openScoreDialog(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ScoreDialog(assignment: data),
    );
    if (ok == true) ref.invalidate(myAssignmentsProvider);
  }
}

class _ScoreDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> assignment;
  const _ScoreDialog({required this.assignment});
  @override
  ConsumerState<_ScoreDialog> createState() => _ScoreDialogState();
}

class _ScoreDialogState extends ConsumerState<_ScoreDialog> {
  List<Map<String, dynamic>>? _criteria;
  final Map<int, TextEditingController> _scoreCtrls = {};
  final Map<int, TextEditingController> _commentCtrls = {};
  bool _busy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadCriteria();
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

  Future<void> _loadCriteria() async {
    try {
      final api = ref.read(apiClientProvider);
      final res =
          await api.dio.get('/rounds/${widget.assignment['round_id']}/criteria');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      setState(() {
        _criteria = list;
        for (final c in list) {
          _scoreCtrls[c['criterion_id']] = TextEditingController();
          _commentCtrls[c['criterion_id']] = TextEditingController();
        }
      });
    } catch (e) {
      setState(() => _loadError = _msg(e));
    }
  }

  Future<void> _submit() async {
    if (_criteria == null || _criteria!.isEmpty) return;

    final scores = <Map<String, dynamic>>[];
    for (final c in _criteria!) {
      final id = c['criterion_id'] as int;
      final raw = _scoreCtrls[id]?.text.trim() ?? '';
      if (raw.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cần điểm cho "${c['criterion_name']}"')));
        return;
      }
      final val = double.tryParse(raw);
      if (val == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Điểm không hợp lệ ở "${c['criterion_name']}"')));
        return;
      }
      final maxScore = double.parse(c['max_score'].toString());
      if (val < 0 || val > maxScore) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Điểm "${c['criterion_name']}" phải 0..$maxScore')));
        return;
      }
      scores.add({
        'criterion_id': id,
        'score_value': val,
        if (_commentCtrls[id]!.text.isNotEmpty)
          'comment_text': _commentCtrls[id]!.text,
      });
    }

    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post(
          '/assignments/${widget.assignment['assignment_id']}/scores',
          data: {'scores': scores});
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã submit điểm')));
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
    return Dialog(
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
                  Text('Chấm điểm — Assignment #${a['assignment_id']}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                      'Round #${a['round_id']} · Entry #${a['entry_id']}'
                      '${a['submission_id'] != null ? ' · Submission #${a['submission_id']}' : ''}',
                      style: TextStyle(fontSize: 12, color: context.textMuted)),
                ]),
          ),
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context, false)),
        ]),
      ),
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _criteria!.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                      child: Text(
                          'Round này chưa có criteria. GV BTC cần thêm rubric trước.',
                          style: TextStyle(color: context.textMuted))),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tiêu chí chấm',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: context.textMuted,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 10),
                    ..._criteria!.map((c) => _buildCriterion(context, c)),
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
          FilledButton.icon(
            onPressed:
                (_busy || (_criteria?.isEmpty ?? true)) ? null : _submit,
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Submit điểm'),
            style: FilledButton.styleFrom(
                minimumSize: const Size(140, 38),
                backgroundColor: ptitRed),
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
          color: const Color(0xFFFAFAFA),
          border: Border.all(color: context.cardBorder),
          borderRadius: BorderRadius.circular(8),
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
                    color: context.infoBlue,
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
}

String _msg(Object e) => e is DioException
    ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
    : '$e';
