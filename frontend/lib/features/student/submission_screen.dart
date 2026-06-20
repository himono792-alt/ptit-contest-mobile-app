import 'dart:async';

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
import '../../core/widgets/app_toast.dart';
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

/// Sprint 16 (2026-05-08): round detail provider — dùng cho countdown timer.
/// Trả Map raw, FE chỉ cần `submission_close_at` + `end_at`.
final roundDetailProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, int>(
        (ref, roundId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/rounds/$roundId');
    return res.data as Map<String, dynamic>?;
  } catch (_) {
    return null;
  }
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
      AppToast.info(context, 'File quá lớn (${(file.size / 1024 / 1024).toStringAsFixed(1)} MB). Tối đa 10 MB.');
      return;
    }
    setState(() => _pendingFile = file);
  }

  Future<void> _submit() async {
    final link = _linkCtrl.text.trim();
    if (link.isNotEmpty && !RegExp(r'^https?://').hasMatch(link)) {
      AppToast.info(context, 'External link cần bắt đầu bằng http:// hoặc https://');
      return;
    }
    if (link.isEmpty && _textCtrl.text.trim().isEmpty && _pendingFile == null) {
      AppToast.info(context, 'Cần nhập ít nhất 1 trong: link / text / upload file');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xác nhận nộp bài?'),
        content: const Text(
            'Sau khi nộp, bạn vẫn có thể nộp lại bản mới trước hạn. Tiếp tục?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Nộp bài')),
        ],
      ),
    );
    if (confirmed != true) return;
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
      AppToast.success(
        context,
        _pendingFile != null ? 'Nộp bài + upload file thành công. BTC sẽ chấm sau khi vòng kết thúc.' : 'Nộp bài thành công. BTC sẽ chấm sau khi vòng kết thúc.',
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
      AppToast.error(context, e);
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
              // Sprint 16 (2026-05-08): countdown timer hero card theo design sv-10.
              _CountdownHeroCard(roundId: widget.roundId),
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
              // Sprint 5 a11y: explicit Semantics cho mỗi TextField để screen reader
              // nghe rõ "Tiêu đề bài làm input" + hint context.
              Semantics(
                label: 'Tiêu đề bài làm',
                hint: 'Đặt tên ngắn gọn cho version này',
                textField: true,
                child: TextField(
                  controller: _titleCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Tiêu đề bài làm'),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'External link Drive hoặc GitHub',
                hint: 'Dán URL bài làm online',
                textField: true,
                child: TextField(
                  controller: _linkCtrl,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'External link (Drive/GitHub)',
                    hintText: 'https://github.com/...',
                    prefixIcon: Icon(Icons.link, size: 18),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Nội dung text bài làm',
                hint: 'Tuỳ chọn — nhập text trực tiếp thay link',
                textField: true,
                multiline: true,
                child: TextField(
                  controller: _textCtrl,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(labelText: 'Nội dung text (tùy chọn)'),
                ),
              ),
              const SizedBox(height: 12),
              Semantics(
                label: 'Ghi chú',
                hint: 'Vd lần 2 đã sửa lỗi compile',
                textField: true,
                child: TextField(
                  controller: _noteCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                      labelText: 'Ghi chú (vd: lần 2 đã sửa)'),
                ),
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
                    ? Semantics(
                        label: 'Đính kèm file bài làm',
                        button: true,
                        hint: 'Mở dialog chọn PDF, Word, Excel, ZIP — tối đa 10MB',
                        child: InkWell(
                        onTap: _pickFile,
                        excludeFromSemantics: true,
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
                        ),
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
                          tooltip: 'Bỏ file',
                          icon: const Icon(Icons.close,
                              color: ptitRed, size: 18),
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
              Semantics(
                label: _pendingFile != null ? 'Nộp bài + Upload file' : 'Nộp bài',
                button: true,
                enabled: !_loading,
                hint: _loading
                    ? 'Đang xử lý, vui lòng chờ'
                    : 'Submit version mới của bài làm',
                child: FilledButton.icon(
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

/// Sprint 16 (2026-05-08): Countdown hero card "Còn lại HH:MM:SS".
/// - Tick mỗi giây qua Timer.periodic, dispose khi unmount.
/// - 3 trạng thái: hot (<1h, gradient red), warn (<24h, orange), normal (xanh).
/// - Quá hạn: hiển thị "Đã quá hạn" + disabled style.
class _CountdownHeroCard extends ConsumerStatefulWidget {
  final int roundId;
  const _CountdownHeroCard({required this.roundId});

  @override
  ConsumerState<_CountdownHeroCard> createState() => _CountdownHeroCardState();
}

class _CountdownHeroCardState extends ConsumerState<_CountdownHeroCard> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Tick mỗi giây để countdown live update.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncRound = ref.watch(roundDetailProvider(widget.roundId));
    return asyncRound.when(
      loading: () => const SizedBox(
          height: 110,
          child: Center(
              child: CircularProgressIndicator(color: ptitRed, strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
      data: (round) {
        if (round == null) return const SizedBox.shrink();
        final closeStr = round['submission_close_at'] ?? round['end_at'];
        if (closeStr == null) return const SizedBox.shrink();
        final closeAt = DateTime.parse(closeStr as String).toLocal();
        final remaining = closeAt.difference(DateTime.now());
        return _CountdownView(closeAt: closeAt, remaining: remaining);
      },
    );
  }
}

class _CountdownView extends StatelessWidget {
  final DateTime closeAt;
  final Duration remaining;
  const _CountdownView({required this.closeAt, required this.remaining});

  @override
  Widget build(BuildContext context) {
    final overdue = remaining.isNegative;
    final hot = !overdue && remaining < const Duration(hours: 1);
    final warn = !overdue && !hot && remaining < const Duration(hours: 24);
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    final Color bg;
    final Gradient? gradient;
    final Color fg = Colors.white;
    final IconData icon;
    String label;
    String time;

    if (overdue) {
      bg = const Color(0xFF6B7280);
      gradient = null;
      icon = Icons.lock_clock;
      label = 'Đã quá hạn nộp';
      time = '— —:— —:— —';
    } else if (hot) {
      bg = ptitRed;
      gradient = ptitGradientHero;
      icon = Icons.timer;
      label = 'Sắp hết hạn';
      time = _fmtRemaining(remaining);
    } else if (warn) {
      bg = const Color(0xFFEA580C);
      gradient = const LinearGradient(
        colors: [Color(0xFFEA580C), Color(0xFFF97316)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      icon = Icons.timer_outlined;
      label = 'Còn lại';
      time = _fmtRemaining(remaining);
    } else {
      bg = const Color(0xFF10B981);
      gradient = const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF34D399)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
      icon = Icons.schedule;
      label = 'Còn lại';
      time = _fmtRemaining(remaining);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: const [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: fg.withValues(alpha: 0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4)),
          ]),
          const SizedBox(height: 6),
          Text(time,
              style: TextStyle(
                  color: fg,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontFamily: 'monospace',
                  height: 1.0)),
          const SizedBox(height: 6),
          Text('Hạn nộp: ${fmt.format(closeAt)}',
              style: TextStyle(
                  color: fg.withValues(alpha: 0.85), fontSize: 11)),
        ],
      ),
    );
  }

  String _fmtRemaining(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
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
