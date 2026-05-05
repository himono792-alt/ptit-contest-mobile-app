import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';

/// Show modal review dialog cho 1 contest.
///
/// Returns true nếu user đã submit/update thành công.
Future<bool?> showReviewDialog(
  BuildContext context, {
  required int contestId,
  required String contestTitle,
  int? existingRating,
  String? existingComment,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => ReviewDialog(
      contestId: contestId,
      contestTitle: contestTitle,
      existingRating: existingRating,
      existingComment: existingComment,
    ),
  );
}

class ReviewDialog extends ConsumerStatefulWidget {
  final int contestId;
  final String contestTitle;
  final int? existingRating;
  final String? existingComment;
  const ReviewDialog({
    super.key,
    required this.contestId,
    required this.contestTitle,
    this.existingRating,
    this.existingComment,
  });
  @override
  ConsumerState<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends ConsumerState<ReviewDialog> {
  late int _rating;
  late TextEditingController _comment;
  bool _busy = false;

  bool get _isEdit => widget.existingRating != null;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingRating ?? 0;
    _comment = TextEditingController(text: widget.existingComment ?? '');
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1 || _rating > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phải chọn rating từ 1-5 sao')));
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = {
        'rating': _rating,
        if (_comment.text.isNotEmpty) 'comment_text': _comment.text.trim(),
      };
      if (_isEdit) {
        await api.dio
            .patch('/contests/${widget.contestId}/reviews/me', data: data);
      } else {
        await api.dio
            .post('/contests/${widget.contestId}/reviews', data: data);
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Đã cập nhật review' : 'Đã gửi review')));
    } catch (e) {
      if (mounted) {
        final msg = e is DioException
            ? (e.response?.data is Map ? '${e.response?.data['detail']}' : e.message ?? '')
            : '$e';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi: $msg')));
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEdit ? 'Sửa đánh giá' : 'Đánh giá cuộc thi',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(widget.contestTitle,
                    style: const TextStyle(fontSize: 12, color: textMuted)),
                const SizedBox(height: 18),
                const Text('Rating *',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 8),
                Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      final on = star <= _rating;
                      return IconButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() => _rating = star),
                        icon: Icon(on ? Icons.star : Icons.star_border,
                            size: 36,
                            color: on ? Colors.amber.shade600 : textMuted),
                      );
                    })),
                Center(
                  child: Text(
                    _rating == 0
                        ? 'Chọn 1-5 sao'
                        : '$_rating sao — ${_ratingLabel(_rating)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: _rating == 0 ? textMuted : textPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Bình luận (tuỳ chọn)',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textPrimary)),
                const SizedBox(height: 6),
                TextField(
                  controller: _comment,
                  maxLines: 4,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    hintText: 'Cuộc thi tổ chức tốt, đề bài hay,...',
                  ),
                ),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.pop(context, false),
                      child: const Text('Hủy')),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                        backgroundColor: ptitRed,
                        minimumSize: const Size(140, 38)),
                    child: _busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(_isEdit ? 'Cập nhật' : 'Gửi đánh giá'),
                  ),
                ]),
              ]),
        ),
      ),
    );
  }

  String _ratingLabel(int r) => switch (r) {
        1 => 'Rất tệ',
        2 => 'Tệ',
        3 => 'Bình thường',
        4 => 'Tốt',
        5 => 'Rất tốt',
        _ => '',
      };
}
