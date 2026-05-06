import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
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
  // File pending upload (chưa submit). Sau khi submit version, sẽ upload file kèm theo.
  PlatformFile? _pendingFile;
  double? _uploadProgress;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _linkCtrl.dispose();
    _textCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
        'png', 'jpg', 'jpeg', 'gif', 'zip', 'txt', 'csv'
      ],
      withData: true, // Cần withData=true để có file.bytes (web không có file.path)
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.size > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('File quá lớn (${(file.size / 1024 / 1024).toStringAsFixed(1)} MB). Tối đa 10 MB.')),
      );
      return;
    }
    setState(() => _pendingFile = file);
  }

  Future<void> _submit() async {
    final link = _linkCtrl.text.trim();
    if (link.isNotEmpty && !RegExp(r'^https?://').hasMatch(link)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('External link cần bắt đầu bằng http:// hoặc https://')),
      );
      return;
    }
    if (link.isEmpty && _textCtrl.text.trim().isEmpty && _pendingFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cần nhập ít nhất 1 trong: link / text / upload file')),
      );
      return;
    }
    setState(() {
      _loading = true;
      _uploadProgress = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      // Step 1: tạo version
      final res = await api.dio.post(
        '/rounds/${widget.roundId}/submissions/me/versions',
        data: {
          'title': _titleCtrl.text.isEmpty ? null : _titleCtrl.text,
          'external_link': _linkCtrl.text.isEmpty ? null : _linkCtrl.text,
          'text_answer': _textCtrl.text.isEmpty ? null : _textCtrl.text,
          'note': _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
        },
      );
      final versionId = res.data['submission_version_id'] as int;

      // Step 2: nếu có file pending, upload kèm theo
      if (_pendingFile != null) {
        final file = _pendingFile!;
        final formData = FormData.fromMap({
          'file': MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
          ),
        });
        await api.dio.post(
          '/submissions/versions/$versionId/files',
          data: formData,
          onSendProgress: (sent, total) {
            if (total > 0 && mounted) {
              setState(() => _uploadProgress = sent / total);
            }
          },
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_pendingFile != null
              ? 'Nộp bài + upload file thành công'
              : 'Nộp bài thành công'),
          backgroundColor: context.successGreen,
        ),
      );
      _titleCtrl.clear();
      _linkCtrl.clear();
      _textCtrl.clear();
      _noteCtrl.clear();
      setState(() {
        _pendingFile = null;
        _uploadProgress = null;
      });
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
            // Sprint 3 a11y fix: tooltip cho back arrow IconButton
            tooltip: 'Quay lại',
            icon: Icon(Icons.arrow_back, color: context.textMuted),
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
                  backgroundColor: context.ptitRedSoft,
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
              const SizedBox(height: 12),
              // ============== File picker ==============
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _pendingFile != null ? context.successSoft : context.appBg,
                  border: Border.all(
                      color: _pendingFile != null ? context.successGreen : context.cardBorder,
                      width: 1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: _pendingFile == null
                    ? InkWell(
                        onTap: _pickFile,
                        child: Row(children: [
                          Icon(Icons.attach_file, color: context.textMuted, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Đính kèm file (tuỳ chọn)',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: context.textPrimary,
                                        fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text(
                                    'PDF, Word, Excel, PPT, ảnh, ZIP — tối đa 10 MB',
                                    style: TextStyle(
                                        fontSize: 11, color: context.textMuted)),
                              ],
                            ),
                          ),
                          Icon(Icons.add, color: ptitRed, size: 20),
                        ]),
                      )
                    : Row(children: [
                        Icon(Icons.insert_drive_file,
                            color: context.successGreen, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_pendingFile!.name,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: context.successGreen),
                                  overflow: TextOverflow.ellipsis),
                              Text(
                                  '${(_pendingFile!.size / 1024).toStringAsFixed(1)} KB',
                                  style: TextStyle(
                                      fontSize: 11, color: context.textMuted)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              color: ptitRed, size: 18),
                          tooltip: 'Bỏ file',
                          onPressed: _loading
                              ? null
                              : () => setState(() => _pendingFile = null),
                        ),
                      ]),
              ),
              if (_uploadProgress != null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _uploadProgress,
                  color: ptitRed,
                  backgroundColor: context.ptitRedSoft,
                ),
                Text(
                    'Đang upload file: ${(_uploadProgress! * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, color: context.textMuted)),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                icon: const Icon(Icons.send, size: 16),
                label: Text(_loading
                    ? (_uploadProgress != null
                        ? 'Đang upload...'
                        : 'Đang gửi...')
                    : (_pendingFile != null
                        ? 'Nộp bài + Upload file'
                        : 'Nộp bài')),
                onPressed: _loading ? null : _submit,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: context.infoSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 16, color: context.infoBlue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bạn có thể nộp lại nhiều lần trước hạn. Mỗi lần là 1 version, hệ thống tự dùng version mới nhất.',
                      style: TextStyle(fontSize: 12, color: context.infoBlue, height: 1.4),
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
        child: Row(children: [
          Icon(Icons.upload_outlined, size: 18, color: context.textMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bạn chưa nộp version nào trong round này.',
              style: TextStyle(color: context.textMuted, fontSize: 12),
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
              style: TextStyle(color: context.textMuted, fontSize: 12)),
          if (sub.submittedAt != null)
            Text(
                'Submit gần nhất: ${fmt.format(sub.submittedAt!.toLocal())}',
                style: TextStyle(color: context.textMuted, fontSize: 12)),
          if (sub.versions.isNotEmpty) ...[
            Divider(height: 16, color: context.cardBorder),
            ...sub.versions.reversed.take(3).map((v) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                      'v${v.versionNo} · ${v.title ?? "(no title)"} · ${fmt.format(v.submittedAt.toLocal())}',
                      style: TextStyle(fontSize: 12, color: context.textPrimary)),
                )),
          ],
        ],
      ),
    );
  }
}
