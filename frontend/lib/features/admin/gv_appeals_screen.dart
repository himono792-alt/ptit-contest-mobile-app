// Phúc khảo kết quả — màn GV/BTC xử lý (2026-06-27).
// Tận dụng adminContestsProvider (lọc FINISHED) + endpoints phúc khảo BE.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/appeal.dart';
import '../../core/models/contest.dart';
import '../../core/spacing.dart';
import '../../core/theme.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/help_button.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/app_toast.dart';
import '../student/my_appeals_screen.dart' show AppealStatusBadge, appealStatusColor;
import 'admin_contests_screen.dart' show adminContestsProvider;

final contestAppealsProvider = FutureProvider.autoDispose
    .family<List<AppealModel>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$contestId/appeals');
  return (res.data as List).map((j) => AppealModel.fromJson(j)).toList();
});

class GvAppealsScreen extends ConsumerStatefulWidget {
  const GvAppealsScreen({super.key});
  @override
  ConsumerState<GvAppealsScreen> createState() => _GvAppealsScreenState();
}

class _GvAppealsScreenState extends ConsumerState<GvAppealsScreen> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(adminContestsProvider);
    return Scaffold(
      appBar: const MTopBar(title: 'Phúc khảo', actions: [
        HelpButton(id: 'gv_appeals'),
      ]),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(FriendlyError.of(e),
              style: TextStyle(color: context.textMuted)),
        ),
        data: (resp) {
          final finished =
              resp.items.where((c) => c.status == 'FINISHED').toList();
          if (finished.isEmpty) {
            return ListView(children: const [
              SizedBox(height: 80),
              EmptyView(
                icon: Icons.gavel_outlined,
                title: 'Chưa có cuộc thi đã công bố',
                subtitle:
                    'Phúc khảo chỉ áp dụng cho cuộc thi đã công bố kết quả (FINISHED).',
              ),
            ]);
          }
          _selectedId ??= finished.first.contestId;
          final selected = finished.firstWhere(
            (c) => c.contestId == _selectedId,
            orElse: () => finished.first,
          );
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              _ContestPicker(
                contests: finished,
                selectedId: selected.contestId,
                onChanged: (id) => setState(() => _selectedId = id),
              ),
              const SizedBox(height: AppSpacing.s12),
              _AppealWindowCard(contest: selected),
              const SizedBox(height: AppSpacing.s12),
              _AppealList(contest: selected),
            ],
          );
        },
      ),
    );
  }
}

class _ContestPicker extends StatelessWidget {
  final List<ContestSummary> contests;
  final int selectedId;
  final ValueChanged<int> onChanged;
  const _ContestPicker(
      {required this.contests,
      required this.selectedId,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(children: [
        Icon(Icons.emoji_events_outlined,
            size: 18, color: context.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedId,
              isExpanded: true,
              items: [
                for (final c in contests)
                  DropdownMenuItem(
                    value: c.contestId,
                    child: Text(c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13.5)),
                  ),
              ],
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ]),
    );
  }
}

/// Card đặt/đổi hạn phúc khảo (BTC). Gọi PATCH /contests/{id}/appeal-window.
class _AppealWindowCard extends ConsumerStatefulWidget {
  final ContestSummary contest;
  const _AppealWindowCard({required this.contest});
  @override
  ConsumerState<_AppealWindowCard> createState() => _AppealWindowCardState();
}

class _AppealWindowCardState extends ConsumerState<_AppealWindowCard> {
  bool _busy = false;

  Future<void> _setWindow(DateTime? deadline) async {
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).dio.patch(
        '/contests/${widget.contest.contestId}/appeal-window',
        data: {'appeal_deadline': deadline?.toUtc().toIso8601String()},
      );
      if (mounted) {
        AppToast.success(
            context,
            deadline == null
                ? 'Đã đóng kênh phúc khảo'
                : 'Đã mở phúc khảo đến ${DateFormat('dd/MM/yyyy').format(deadline)}');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;
    // Đặt hạn cuối ngày được chọn.
    await _setWindow(
        DateTime(picked.year, picked.month, picked.day, 23, 59, 59));
  }

  @override
  Widget build(BuildContext context) {
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.schedule_outlined, size: 18, color: context.infoBlue),
            const SizedBox(width: 8),
            const Text('Hạn nhận phúc khảo',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          Text(
            'BTC đặt thời hạn SV được gửi phúc khảo cho cuộc thi này. '
            'Đóng kênh = không nhận phúc khảo mới.',
            style: TextStyle(fontSize: 11.5, color: context.textMuted),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.event_available_outlined, size: 16),
                label: const Text('Đặt/đổi hạn'),
                onPressed: _busy ? null : _pickDeadline,
                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('Đóng kênh'),
                onPressed: _busy ? null : () => _setWindow(null),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _AppealList extends ConsumerWidget {
  final ContestSummary contest;
  const _AppealList({required this.contest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(contestAppealsProvider(contest.contestId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(FriendlyError.of(e),
            style: TextStyle(color: context.textMuted)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 24),
            child: EmptyView(
              icon: Icons.inbox_outlined,
              title: 'Chưa có phúc khảo',
              subtitle: 'Cuộc thi này chưa có yêu cầu phúc khảo nào.',
            ),
          );
        }
        final open = items.where((a) => a.isOpen).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, left: 2),
              child: Text('${items.length} phúc khảo · $open đang chờ',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary)),
            ),
            for (final a in items)
              _GvAppealCard(appeal: a, contestId: contest.contestId),
          ],
        );
      },
    );
  }
}

class _GvAppealCard extends ConsumerStatefulWidget {
  final AppealModel appeal;
  final int contestId;
  const _GvAppealCard({required this.appeal, required this.contestId});
  @override
  ConsumerState<_GvAppealCard> createState() => _GvAppealCardState();
}

class _GvAppealCardState extends ConsumerState<_GvAppealCard> {
  bool _busy = false;

  void _refresh() => ref.invalidate(contestAppealsProvider(widget.contestId));

  Future<void> _startReview() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .dio
          .post('/appeals/${widget.appeal.appealId}/start-review');
      _refresh();
      if (mounted) AppToast.success(context, 'Đã nhận xử lý');
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resolve(String decision) async {
    final controller = TextEditingController();
    final isAccept = decision == 'ACCEPTED';
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAccept ? 'Chấp nhận phúc khảo' : 'Từ chối phúc khảo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAccept
                  ? 'Sau khi chấp nhận, hãy chấm lại điểm → submit BCN duyệt lại → công bố lại kết quả.'
                  : 'Nêu rõ lý do để SV hiểu (kể cả khi đã xem lại và điểm đúng).',
              style: TextStyle(fontSize: 12, color: context.textMuted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText: 'Phản hồi cho sinh viên...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isAccept ? 'Chấp nhận' : 'Từ chối')),
        ],
      ),
    );
    if (ok != true) return;
    if (controller.text.trim().length < 5) {
      if (mounted) AppToast.info(context, 'Phản hồi cần ít nhất 5 ký tự');
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(apiClientProvider).dio.post(
        '/appeals/${widget.appeal.appealId}/resolve',
        data: {'decision': decision, 'response_text': controller.text.trim()},
      );
      _refresh();
      if (mounted) {
        AppToast.success(
            context, isAccept ? 'Đã chấp nhận phúc khảo' : 'Đã từ chối phúc khảo');
      }
    } catch (e) {
      if (mounted) AppToast.error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.appeal;
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(a.title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 8),
            AppealStatusBadge(appeal: a),
          ]),
          const SizedBox(height: 4),
          Text('Bài #${a.entryId} · gửi ${fmt.format(a.createdAt.toLocal())}',
              style: TextStyle(fontSize: 11, color: context.textMuted)),
          const SizedBox(height: 8),
          Text(a.contentText,
              style: TextStyle(fontSize: 12.5, color: context.textPrimary)),
          if (a.responseText != null && a.responseText!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: appealStatusColor(context, a.status)
                    .withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Phản hồi: ${a.responseText!}',
                  style:
                      TextStyle(fontSize: 12, color: context.textPrimary)),
            ),
          ],
          if (a.status == 'PENDING' || a.status == 'IN_REVIEW') ...[
            const SizedBox(height: 12),
            Row(children: [
              if (a.status == 'PENDING')
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Nhận xử lý'),
                    onPressed: _busy ? null : _startReview,
                    style:
                        OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                  ),
                ),
              if (a.status == 'IN_REVIEW') ...[
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Chấp nhận'),
                    onPressed: _busy ? null : () => _resolve('ACCEPTED'),
                    style: FilledButton.styleFrom(
                        backgroundColor: context.successGreen,
                        minimumSize: const Size(0, 38)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Từ chối'),
                    onPressed: _busy ? null : () => _resolve('REJECTED'),
                    style:
                        OutlinedButton.styleFrom(minimumSize: const Size(0, 38)),
                  ),
                ),
              ],
            ]),
          ],
        ],
      ),
    );
  }
}
