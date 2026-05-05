import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/models/submission.dart';
import '../../core/theme.dart';

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
        const SnackBar(content: Text('Nộp bài thành công'), backgroundColor: Colors.green),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Nộp bài thi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Existing submission
            asyncSub.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => Card(
                color: ptitRedSoft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('$e', style: const TextStyle(color: ptitRed)),
                ),
              ),
              data: (s) => s == null
                  ? const _NoSubmissionYet()
                  : _ExistingSubmission(sub: s),
            ),
            const SizedBox(height: 16),
            const Text('Nộp version mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Tiêu đề bài làm')),
            const SizedBox(height: 12),
            TextField(
              controller: _linkCtrl,
              decoration: const InputDecoration(
                labelText: 'External link (Drive/GitHub)',
                hintText: 'https://github.com/...',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textCtrl,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Nội dung text (tùy chọn)'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú (vd: lần 2 đã sửa)')),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.send),
              label: Text(_loading ? 'Đang gửi...' : 'Nộp bài'),
              onPressed: _loading ? null : _submit,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
              child: const Text(
                'ℹ️ Bạn có thể nộp lại nhiều lần trước hạn. Mỗi lần là 1 version, hệ thống tự dùng version mới nhất.',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSubmissionYet extends StatelessWidget {
  const _NoSubmissionYet();
  @override
  Widget build(BuildContext context) => Card(
        color: Colors.grey.shade50,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Text('Bạn chưa nộp version nào trong round này.', style: TextStyle(color: Colors.grey)),
        ),
      );
}

class _ExistingSubmission extends StatelessWidget {
  final SubmissionDetail sub;
  const _ExistingSubmission({required this.sub});
  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Submission #${sub.submissionId}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              _statusChip(sub.status),
            ]),
            const SizedBox(height: 6),
            Text('Hiện đang ở version ${sub.currentVersionNo} · ${sub.versions.length} versions',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (sub.submittedAt != null)
              Text('Submit gần nhất: ${fmt.format(sub.submittedAt!.toLocal())}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (sub.versions.isNotEmpty) ...[
              const Divider(height: 16),
              ...sub.versions.reversed.take(3).map((v) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('v${v.versionNo} · ${v.title ?? "(no title)"} · ${fmt.format(v.submittedAt.toLocal())}',
                        style: const TextStyle(fontSize: 12)),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String s) {
    final color = s == 'LATE' ? Colors.orange : (s == 'LOCKED' ? Colors.red : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
      child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
