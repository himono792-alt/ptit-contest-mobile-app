import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/submission.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';

final mySubmissionProvider = FutureProvider.autoDispose
    .family<SubmissionDetail?, int>((ref, roundId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/rounds/$roundId/submissions/me');
  if (res.data == null) return null;
  return SubmissionDetail.fromJson(res.data);
});

class SubmissionScreen extends ConsumerStatefulWidget {
  final int roundId;
  const SubmissionScreen({super.key, required this.roundId});

  @override
  ConsumerState<SubmissionScreen> createState() => _SubmissionScreenState();
}

class _SubmissionScreenState extends ConsumerState<SubmissionScreen> {
  final _titleCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _textCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _textCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final link = _linkCtrl.text.trim();
    if (link.isNotEmpty && !RegExp(r'^https?://').hasMatch(link)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('External link cần bắt đầu bằng http:// hoặc https://')),
      );
      return;
    }
    if (link.isEmpty && _textCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần nhập ít nhất 1 trong: external link hoặc text answer')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post(
        '/rounds/${widget.roundId}/submissions/me/versions',
        data: {
          'title': _titleCtrl.text.isEmpty ? null : _titleCtrl.text,
          'external_link': _linkCtrl.text.isEmpty ? null : _linkCtrl.text,
          'text_answer': _textCtrl.text.isEmpty ? null : _textCtrl.text,
          'note': _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nộp bài thành công'), backgroundColor: successGreen),
      );
      _titleCtrl.clear();
      _linkCtrl.clear();
      _textCtrl.clear();
      _noteCtrl.clear();
      ref.invalidate(mySubmissionProvider(widget.roundId));
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map ? '${e.response?.data['detail']}' : e.message;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$msg')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSub = ref.watch(mySubmissionProvider(widget.roundId));
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: MTopBar(
          title: 'Nộp bài thi',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: textMuted),
            onPressed: () => context.pop(),
          ),
        ),
        body: RefreshIndicator(
          color: ptitRed,
          onRefresh: () async => ref.invalidate(mySubmissionProvider(widget.roundId)),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              asyncSub.when(
                loading: () => const SizedBox(
                    height: 60,
                    child: Center(child: CircularProgressIndicator(color: ptitRed))),
                error: (e, _) => MCard(
                  backgroundColor: ptitRedSoft,
                  child: Text('$e', style: const TextStyle(color: ptitRed, fontSize: 12)),
                ),
                data: (s) => s == null
                    ? const _NoSubmissionYet()
                    : _ExistingSubmission(sub: s),
              ),
              const SizedBox(height: 16),
              const Text('Nộp version mới',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Tiêu đề bài làm'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _linkCtrl,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'External link (Drive/GitHub)',
                  hintText: 'https://github.com/...',
                  prefixIcon: Icon(Icons.link, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textCtrl,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(labelText: 'Nội dung text (tùy chọn)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                    labelText: 'Ghi chú (vd: lần 2 đã sửa)'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.send, size: 16),
                label: Text(_loading ? 'Đang gửi...' : 'Nộp bài'),
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: infoSoft, borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [
                  Icon(Icons.info_outline, size: 16, color: infoBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn có thể nộp lại nhiều lần trước hạn. Mỗi lần là 1 version, hệ thống tự dùng version mới nhất.',
                      style: TextStyle(fontSize: 12, color: infoBlue, height: 1.4),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoSubmissionYet extends StatelessWidget {
  const _NoSubmissionYet();
  @override
  Widget build(BuildContext context) => MCard(
        backgroundColor: const Color(0xFFFAFAFA),
        flat: true,
        child: const Row(children: [
          Icon(Icons.upload_outlined, size: 18, color: textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bạn chưa nộp version nào trong round này.',
              style: TextStyle(color: textMuted, fontSize: 12),
            ),
          ),
        ]),
      );
}

class _ExistingSubmission extends StatelessWidget {
  final SubmissionDetail sub;
  const _ExistingSubmission({required this.sub});
  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Submission #${sub.submissionId}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const Spacer(),
            Pill.status(sub.status),
          ]),
          const SizedBox(height: 6),
          Text(
              'Version ${sub.currentVersionNo} · tổng ${sub.versions.length} versions',
              style: const TextStyle(color: textMuted, fontSize: 12)),
          if (sub.submittedAt != null)
            Text(
                'Submit gần nhất: ${fmt.format(sub.submittedAt!.toLocal())}',
                style: const TextStyle(color: textMuted, fontSize: 12)),
          if (sub.versions.isNotEmpty) ...[
            const Divider(height: 16, color: cardBorder),
            ...sub.versions.reversed.take(3).map((v) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      'v${v.versionNo} · ${v.title ?? "(no title)"} · ${fmt.format(v.submittedAt.toLocal())}',
                      style: const TextStyle(fontSize: 12, color: textPrimary)),
                )),
          ],
        ],
      ),
    );
  }
}
