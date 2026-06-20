// SV-10 — "Của tôi" tab: list entries SV đã đăng ký + status entry + action.
//
// Dùng GET /me/entries (mới ở backend) trả các entry kèm contest info.
// Action:
//   - PENDING/APPROVED + contest REG_OPEN → nút Hủy đăng ký
//   - APPROVED + contest ONGOING (requires_submission) → nút Nộp bài
//   - Contest FINISHED → tap tới Kết quả

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/help_button.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';
import 'student_shell.dart' show studentTabProvider;

final myEntriesProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/me/entries');
  return (res.data as List).cast<Map<String, dynamic>>();
});

class MyRegistrationsScreen extends ConsumerStatefulWidget {
  const MyRegistrationsScreen({super.key});
  @override
  ConsumerState<MyRegistrationsScreen> createState() =>
      _MyRegistrationsScreenState();
}

class _MyRegistrationsScreenState extends ConsumerState<MyRegistrationsScreen> {
  String _filter = 'Tất cả';

  bool _matchesFilter(Map<String, dynamic> e) {
    if (_filter == 'Tất cả') return true;
    final cs = (e['contest_status'] as String?) ?? '';
    if (_filter == 'Đang dự thi') {
      return ['REG_OPEN', 'REG_CLOSED', 'ONGOING'].contains(cs);
    }
    if (_filter == 'Đã hoàn thành') return cs == 'FINISHED';
    if (_filter == 'Chờ duyệt') {
      return e['registration_status'] == 'PENDING';
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(myEntriesProvider);
    return Scaffold(
      appBar: const MTopBar(title: 'Của tôi', actions: [
        HelpButton(id: 'sv_my_registrations'),
      ]),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final f in [
                'Tất cả',
                'Chờ duyệt',
                'Đang dự thi',
                'Đã hoàn thành'
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _filter == f ? ptitRed : context.cardBg,
                        border: Border.all(
                            color: _filter == f ? ptitRed : context.cardBorder),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(f,
                          style: TextStyle(
                            fontSize: 11,
                            color: _filter == f ? Colors.white : context.textMuted,
                            fontWeight: FontWeight.w500,
                          )),
                    ),
                  ),
                ),
            ]),
          ),
        ),
        Expanded(
          child: asyncList.when(
            loading: () =>
                // Phase 2 step 5: skeleton thay spinner
                const MCardListSkeleton(count: 3, textLines: 3),
            error: (e, _) => Center(
                child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(FriendlyError.of(e),
                        style: TextStyle(color: context.textMuted)))),
            data: (entries) {
              final filtered = entries.where(_matchesFilter).toList();
              if (filtered.isEmpty) {
                return _filter == 'Tất cả'
                    ? EmptyView(
                        icon: Icons.how_to_reg_outlined,
                        title: 'Bạn chưa đăng ký cuộc thi nào',
                        subtitle: 'Khám phá các cuộc thi đang mở và ghi danh ngay hôm nay.',
                        action: FilledButton.icon(
                          icon: const Icon(Icons.search),
                          label: const Text('Khám phá cuộc thi'),
                          onPressed: () => ref.read(studentTabProvider.notifier).state = 1,
                        ),
                      )
                    : EmptyView(
                        icon: Icons.inbox_outlined,
                        title: 'Không có entry nào ở mục "$_filter"',
                      );
              }
              // Redesign 2026-06-20: stat strip (toàn bộ entries) + gom nhóm
              // theo giai đoạn (filtered).
              final groups = <String, List<Map<String, dynamic>>>{};
              for (final e in filtered) {
                groups.putIfAbsent(_entryCategory(e), () => []).add(e);
              }
              final cats =
                  _entryCategoryOrder.where(groups.containsKey).toList();
              return RefreshIndicator(
                color: ptitRed,
                onRefresh: () async => ref.invalidate(myEntriesProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: [
                    _RegStatStrip(entries: entries),
                    const SizedBox(height: 12),
                    for (final cat in cats) ...[
                      _RegGroupHeader(
                        label: cat,
                        count: groups[cat]!.length,
                        color: _entryCategoryColor(context, cat),
                      ),
                      for (final e in groups[cat]!) _EntryCard(entry: e),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// Redesign 2026-06-20: nhóm giai đoạn + stat strip cho "Đăng ký của tôi".
const _entryCategoryOrder = [
  'Đang dự thi',
  'Chờ duyệt',
  'Đã hoàn thành',
  'Khác',
];

String _entryCategory(Map<String, dynamic> e) {
  final rs = e['registration_status'] as String?;
  final cs = e['contest_status'] as String?;
  if (rs == 'PENDING') return 'Chờ duyệt';
  if (cs == 'FINISHED') return 'Đã hoàn thành';
  if (['REG_OPEN', 'REG_CLOSED', 'ONGOING'].contains(cs)) {
    return 'Đang dự thi';
  }
  return 'Khác';
}

Color _entryCategoryColor(BuildContext context, String cat) {
  switch (cat) {
    case 'Đang dự thi':
      return ptitRed;
    case 'Chờ duyệt':
      return context.warnOrange;
    case 'Đã hoàn thành':
      return context.successGreen;
    default:
      return context.textMuted;
  }
}

class _RegStatStrip extends StatelessWidget {
  final List<Map<String, dynamic>> entries;
  const _RegStatStrip({required this.entries});

  @override
  Widget build(BuildContext context) {
    int byCat(String c) =>
        entries.where((e) => _entryCategory(e) == c).length;
    return Row(children: [
      Expanded(
        child: _RegStat(
          value: '${entries.length}',
          label: 'Tổng đăng ký',
          color: ptitRed,
          icon: Icons.how_to_reg_outlined,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _RegStat(
          value: '${byCat('Chờ duyệt')}',
          label: 'Chờ duyệt',
          color: context.warnOrange,
          icon: Icons.hourglass_empty_outlined,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: _RegStat(
          value: '${byCat('Đang dự thi')}',
          label: 'Đang dự thi',
          color: context.infoBlue,
          icon: Icons.flag_outlined,
        ),
      ),
    ]);
  }
}

class _RegStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _RegStat(
      {required this.value,
      required this.label,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
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
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: context.textMuted)),
        ],
      ),
    );
  }
}

class _RegGroupHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _RegGroupHeader(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.2)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: context.cardBorder.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.tight),
          ),
          child: Text('$count',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: context.textMuted)),
        ),
      ]),
    );
  }
}

class _EntryCard extends ConsumerWidget {
  final Map<String, dynamic> entry;
  const _EntryCard({required this.entry});

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hủy đăng ký?'),
        content: Text('Hủy đăng ký "${entry['contest_title']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Không')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ptitRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy đăng ký'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final api = ref.read(apiClientProvider);
      await api.dio.delete('/contests/${entry['contest_id']}/registration');
      ref.invalidate(myEntriesProvider);
      if (!context.mounted) return;
      AppToast.success(context, 'Đã hủy đăng ký');
    } on DioException catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, e);
    }
  }

  /// Sprint 17 (2026-05-08) S17-3: visual progress bar theo stage.
  /// Map contest_status + registration_status → % + color.
  Widget _buildProgress(BuildContext context, String cs, String rs) {
    final double percent;
    final Color barColor;
    final String label;

    if (rs == 'PENDING') {
      percent = 0.10;
      barColor = context.warnOrange;
      label = 'Chờ BTC duyệt';
    } else if (cs == 'REG_OPEN' || cs == 'REG_CLOSED') {
      percent = 0.25;
      barColor = context.infoBlue;
      label = 'Đã đăng ký';
    } else if (cs == 'ONGOING') {
      percent = 0.65;
      barColor = ptitRed;
      label = 'Đang dự thi';
    } else if (cs == 'FINISHED') {
      percent = 1.0;
      barColor = context.successGreen;
      label = 'Đã kết thúc';
    } else {
      percent = 0.05;
      barColor = context.textMuted;
      label = cs;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                    letterSpacing: 0.3)),
          ),
          Text('${(percent * 100).toInt()}%',
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: barColor)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 5,
            backgroundColor: context.cardBorder,
            valueColor: AlwaysStoppedAnimation(barColor),
          ),
        ),
      ],
    );
  }

  Future<void> _navSubmit(BuildContext context, WidgetRef ref) async {
    try {
      final res = await ref
          .read(apiClientProvider)
          .dio
          .get('/contests/${entry['contest_id']}/rounds');
      final rounds = res.data as List;
      if (rounds.isEmpty) {
        if (!context.mounted) return;
        AppToast.info(context, 'Cuộc thi chưa có round');
        return;
      }
      if (!context.mounted) return;
      context.push('/rounds/${rounds.first['round_id']}/submit');
    } on DioException catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = (entry['contest_status'] as String?) ?? '—';
    final rs = (entry['registration_status'] as String?) ?? '—';
    final isPending = rs == 'PENDING';
    final isApproved = rs == 'APPROVED';
    final canCancel = (rs == 'PENDING' || rs == 'APPROVED') &&
        ['REG_OPEN', 'REG_CLOSED'].contains(cs);
    final canSubmit = isApproved && cs == 'ONGOING';
    final isFinished = cs == 'FINISHED';
    final fmt = DateFormat('dd/MM/yy');

    return MCard(
      onTap: () => context.push('/contests/${entry['contest_slug']}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(entry['contest_title'] as String,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 6),
            Pill.status(cs),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Pill(
              label: isPending ? 'Chờ duyệt' : (isApproved ? 'Đã duyệt' : 'Từ chối'),
              icon: isPending
                  ? Icons.hourglass_empty
                  : (isApproved ? Icons.check_circle_outline : Icons.cancel_outlined),
              color: isApproved
                  ? context.successGreen
                  : (isPending ? context.warnOrange : ptitRed),
              bg: isApproved
                  ? context.successSoft
                  : (isPending ? context.warnSoft : context.ptitRedSoft),
            ),
            const SizedBox(width: 6),
            Text('${entry['entry_type']}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textMuted)),
          ]),
          if ((entry['registration_note'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Ghi chú: ${entry['registration_note']}',
                style: TextStyle(
                    fontSize: 11, color: context.textMuted, fontStyle: FontStyle.italic)),
          ],
          const SizedBox(height: 8),
          Text(
            'Đăng ký ${fmt.format(DateTime.parse(entry['created_at']).toLocal())}'
            ' · Thi ${fmt.format(DateTime.parse(entry['contest_start_at']).toLocal())}'
            ' → ${fmt.format(DateTime.parse(entry['contest_end_at']).toLocal())}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.textFaint),
          ),
          // Sprint 17 (2026-05-08) S17-3: progress bar theo contest_status
          const SizedBox(height: 10),
          _buildProgress(context, cs, rs),
          if (canCancel || canSubmit || isFinished) ...[
            const SizedBox(height: 10),
            Row(children: [
              if (canSubmit)
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.upload_file, size: 14),
                    label: Text('Nộp bài',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textPrimary)),
                    onPressed: () => _navSubmit(context, ref),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10)),
                  ),
                ),
              if (isFinished)
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.emoji_events_outlined, size: 14),
                    label: Text('Xem kết quả',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.textPrimary)),
                    onPressed: () =>
                        context.push('/contests/${entry['contest_slug']}'),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 32),
                        padding: const EdgeInsets.symmetric(horizontal: 10)),
                  ),
                ),
              if (canSubmit || isFinished) const SizedBox(width: 8),
              if (canCancel)
                OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined,
                      size: 14, color: ptitRed),
                  label: Text('Hủy',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(color: ptitRed)),
                  onPressed: () => _cancel(context, ref),
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      side: BorderSide(color: context.ptitRedSoft)),
                ),
            ]),
          ],
        ],
      ),
    );
  }
}
