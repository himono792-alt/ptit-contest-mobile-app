import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/widgets/app_toast.dart';

/// Dialog SV gửi phúc khảo kết quả cho 1 bài dự thi (entry).
///
/// Trả về true nếu gửi thành công.
Future<bool?> showAppealDialog(
  BuildContext context, {
  required int contestId,
  required int entryId,
  required String contestTitle,
  int? roundId,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => AppealDialog(
      contestId: contestId,
      entryId: entryId,
      contestTitle: contestTitle,
      roundId: roundId,
    ),
  );
}

class AppealDialog extends ConsumerStatefulWidget {
  final int contestId;
  final int entryId;
  final String contestTitle;
  final int? roundId;
  const AppealDialog({
    super.key,
    required this.contestId,
    required this.entryId,
    required this.contestTitle,
    this.roundId,
  });

  @override
  ConsumerState<AppealDialog> createState() => _AppealDialogState();
}

class _AppealDialogState extends ConsumerState<AppealDialog> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().length < 3) {
      AppToast.info(context, 'Tiêu đề cần ít nhất 3 ký tự');
      return;
    }
    if (_content.text.trim().length < 5) {
      AppToast.info(context, 'Nội dung phúc khảo cần ít nhất 5 ký tự');
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.post('/contests/${widget.contestId}/appeals', data: {
        'entry_id': widget.entryId,
        if (widget.roundId != null) 'round_id': widget.roundId,
        'title': _title.text.trim(),
        'content_text': _content.text.trim(),
      });
      if (!mounted) return;
      Navigator.pop(context, true);
      AppToast.success(context, 'Đã gửi phúc khảo. BTC sẽ xem xét.');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.gavel_outlined, size: 20, color: context.infoBlue),
                const SizedBox(width: 8),
                const Text('Gửi phúc khảo',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 4),
              Text(widget.contestTitle,
                  style: TextStyle(fontSize: 12, color: context.textMuted)),
              const SizedBox(height: 16),
              Text('Tiêu đề *',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _title,
                maxLength: 255,
                decoration: const InputDecoration(
                  hintText: 'VD: Xin xem lại điểm phần trình bày',
                ),
              ),
              const SizedBox(height: 6),
              Text('Lý do / nội dung phúc khảo *',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary)),
              const SizedBox(height: 6),
              TextField(
                controller: _content,
                maxLines: 5,
                maxLength: 2000,
                decoration: const InputDecoration(
                  hintText:
                      'Trình bày cụ thể vì sao bạn đề nghị xem lại kết quả...',
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.infoBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline,
                      size: 15, color: context.infoBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mỗi bài dự thi chỉ gửi 1 phúc khảo tại một thời điểm. '
                      'Bạn sẽ nhận thông báo khi BTC xử lý.',
                      style:
                          TextStyle(fontSize: 11, color: context.textMuted),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                TextButton(
                    onPressed:
                        _busy ? null : () => Navigator.pop(context, false),
                    child: const Text('Hủy')),
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: _busy ? null : _submit,
                  icon: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_outlined, size: 16),
                  label: const Text('Gửi phúc khảo'),
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(150, 40)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
