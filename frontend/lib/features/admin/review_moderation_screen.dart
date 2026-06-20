// AD-06 — Admin moderation cho contest reviews (SV-11 SV đã review).
//
// /admin/reviews → list, có filter only_hidden + contest_id.
// PATCH /admin/reviews/{id}/moderate body { is_visible, moderation_note }.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/pill.dart';

final reviewModerationFilterProvider = StateProvider<bool>((_) => false);

final reviewModerationListProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final onlyHidden = ref.watch(reviewModerationFilterProvider);
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/reviews', queryParameters: {
    'only_hidden': onlyHidden,
    'page': 1,
    'size': 100,
  });
  return res.data as List<dynamic>;
});

class ReviewModerationScreen extends ConsumerWidget {
  const ReviewModerationScreen({super.key});

  Future<void> _moderate(
      BuildContext context, WidgetRef ref, int reviewId, bool visible) async {
    final note = await showDialog<String>(
      context: context,
      builder: (_) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text(visible ? 'Hiện lại review' : 'Ẩn review này'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(visible
                ? 'Review sẽ hiện trở lại cho SV thấy.'
                : 'Review sẽ bị ẩn (giữ trong DB nhưng không hiện công khai).'),
            const SizedBox(height: 12),
            TextField(
                controller: ctrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: 'Lý do (tuỳ chọn)')),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy')),
            FilledButton(
                onPressed: () => Navigator.pop(context, ctrl.text.trim()),
                child: const Text('Xác nhận')),
          ],
        );
      },
    );
    if (note == null) return;
    final api = ref.read(apiClientProvider);
    try {
      await api.dio.patch('/admin/reviews/$reviewId/moderate',
          data: {'is_visible': visible, 'moderation_note': note.isEmpty ? null : note});
      ref.invalidate(reviewModerationListProvider);
      if (!context.mounted) return;
      AppToast.success(context, 'Đã ${visible ? "hiện" : "ẩn"} review #$reviewId');
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(reviewModerationListProvider);
    final onlyHidden = ref.watch(reviewModerationFilterProvider);
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: context.appBg,
      body: Column(children: [
        if (!isMobile) Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          color: context.cardBg,
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quản trị', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textMuted)),
                  SizedBox(height: 2),
                  Text('Đánh giá / bình luận',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ]),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(isMobile ? 14 : 32, isMobile ? 12 : 16, isMobile ? 14 : 32, 0),
          child: Row(children: [
            FilterChip(
              label: const Text('Chỉ hiện đã ẩn'),
              selected: onlyHidden,
              onSelected: (v) =>
                  ref.read(reviewModerationFilterProvider.notifier).state = v,
              selectedColor: context.ptitRedSoft,
              checkmarkColor: ptitRed,
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Làm mới',
              icon: Icon(Icons.refresh, color: context.textMuted),
              onPressed: () => ref.invalidate(reviewModerationListProvider),
            ),
          ]),
        ),
        Expanded(
          child: asyncList.when(
            // Sprint 8c (2026-05-07): skeleton thay spinner.
            loading: () => const MCardListSkeleton(count: 4),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi: ${e.toString()}',
                    style: const TextStyle(color: ptitRed)),
              ),
            ),
            data: (reviews) => reviews.isEmpty
                ? const EmptyView(
                    icon: Icons.rate_review_outlined,
                    title: 'Chưa có review nào',
                    subtitle: 'Các đánh giá của sinh viên sẽ hiện ở đây.',
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(isMobile ? 14 : 24, 16, isMobile ? 14 : 24, 24),
                    itemCount: reviews.length,
                    itemBuilder: (_, i) {
                      final r = reviews[i] as Map<String, dynamic>;
                      final visible = r['is_visible'] as bool? ?? true;
                      final fmt = DateFormat('dd/MM/yy HH:mm');
                      return MCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                ...List.generate(
                                    5,
                                    (i) => Icon(
                                          i < (r['rating'] as int)
                                              ? Icons.star
                                              : Icons.star_border,
                                          color: context.warnOrange,
                                          size: 16,
                                        )),
                                const SizedBox(width: 8),
                                Text('Review #${r['review_id']}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: context.textMuted,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text(
                                    'Contest #${r['contest_id']} · SV #${r['student_id']}',
                                    style: TextStyle(
                                        fontSize: 11, color: context.textMuted)),
                                const Spacer(),
                                Pill(
                                  label: visible ? 'HIỆN' : 'ẨN',
                                  color:
                                      visible ? context.successGreen : ptitRed,
                                  bg: visible
                                      ? context.successSoft
                                      : context.ptitRedSoft,
                                ),
                              ]),
                              const SizedBox(height: 6),
                              Text(
                                  (r['comment_text'] ?? '(không có comment)')
                                      .toString(),
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: context.textPrimary,
                                      height: 1.5)),
                              const SizedBox(height: 8),
                              Row(children: [
                                Text(
                                    'Tạo: ${fmt.format(DateTime.parse(r['created_at']).toLocal())}',
                                    style: TextStyle(
                                        fontSize: 11, color: context.textMuted)),
                                const Spacer(),
                                if (visible)
                                  TextButton.icon(
                                    icon: const Icon(Icons.visibility_off,
                                        size: 16, color: ptitRed),
                                    label: const Text('Ẩn',
                                        style: TextStyle(color: ptitRed)),
                                    onPressed: () => _moderate(
                                        context, ref, r['review_id'] as int, false),
                                  )
                                else
                                  TextButton.icon(
                                    icon: Icon(Icons.visibility,
                                        size: 16, color: context.successGreen),
                                    label: Text('Hiện lại',
                                        style: TextStyle(color: context.successGreen)),
                                    onPressed: () => _moderate(
                                        context, ref, r['review_id'] as int, true),
                                  ),
                              ]),
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
