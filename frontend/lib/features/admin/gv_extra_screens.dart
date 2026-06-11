// Sprint 23 Step 4 (2026-05-09): 4 GV/BTC screens placeholder build thật.
// Tận dụng providers + endpoints có sẵn (adminContestsProvider, system-summary
// XLSX export). Không tạo BE mới.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/contest.dart';
import '../../core/spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/xlsx_export_helper.dart';
import 'admin_contests_screen.dart' show adminContestsProvider;

// ============== Screen 1: Lịch & deadline ==============

class GvCalendarDeadlineScreen extends ConsumerWidget {
  const GvCalendarDeadlineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(adminContestsProvider);
    return ColoredBox(
      color: context.appBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ScreenHeader(
          breadcrumb: 'BTC',
          title: 'Lịch & deadline',
          subtitle: 'Các mốc thời gian quan trọng — đăng ký, vòng loại, công bố.',
        ),
        Expanded(
          child: asyncList.when(
            loading: () => const MCardListSkeleton(count: 4, textLines: 2),
            error: (e, _) => _ErrorBox(error: '$e'),
            data: (data) {
              // Build deadlines list từ contests organizer
              final now = DateTime.now();
              final events = <_DeadlineEvent>[];
              for (final c in data.items) {
                if (c.registrationOpenAt != null &&
                    c.registrationOpenAt!.isAfter(now)) {
                  events.add(_DeadlineEvent(
                    when: c.registrationOpenAt!,
                    label: 'Mở đăng ký',
                    contest: c,
                    color: context.infoBlue,
                    icon: Icons.lock_open_outlined,
                  ));
                }
                if (c.registrationCloseAt != null &&
                    c.registrationCloseAt!.isAfter(now)) {
                  events.add(_DeadlineEvent(
                    when: c.registrationCloseAt!,
                    label: 'Đóng đăng ký',
                    contest: c,
                    color: context.warnOrange,
                    icon: Icons.lock_outline,
                  ));
                }
                if (c.startAt.isAfter(now)) {
                  events.add(_DeadlineEvent(
                    when: c.startAt,
                    label: 'Bắt đầu thi',
                    contest: c,
                    color: ptitRed,
                    icon: Icons.flag_outlined,
                  ));
                }
                if (c.endAt.isAfter(now)) {
                  events.add(_DeadlineEvent(
                    when: c.endAt,
                    label: 'Kết thúc thi',
                    contest: c,
                    color: context.successGreen,
                    icon: Icons.emoji_events_outlined,
                  ));
                }
              }
              events.sort((a, b) => a.when.compareTo(b.when));
              if (events.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s32),
                    child: Text(
                        'Không có deadline nào sắp tới.\nTạo contest mới để theo dõi mốc thời gian.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.textMuted, fontSize: 13)),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s16),
                itemCount: events.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.s8),
                itemBuilder: (_, i) => _DeadlineRow(event: events[i]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _DeadlineEvent {
  final DateTime when;
  final String label;
  final ContestSummary contest;
  final Color color;
  final IconData icon;
  const _DeadlineEvent({
    required this.when,
    required this.label,
    required this.contest,
    required this.color,
    required this.icon,
  });
}

class _DeadlineRow extends StatelessWidget {
  final _DeadlineEvent event;
  const _DeadlineRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final remaining = event.when.difference(DateTime.now());
    final remainStr = remaining.inDays >= 1
        ? '${remaining.inDays} ngày'
        : '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.go('/admin/contests'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border.all(color: context.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(event.icon, color: event.color, size: 20),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${event.label} · ${event.contest.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                        letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text(fmt.format(event.when.toLocal()),
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8, vertical: 3),
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.tight),
            ),
            child: Text('còn $remainStr',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: event.color)),
          ),
        ]),
      ),
    );
  }
}

// ============== Screen 2: Kết quả contests organizer ==============

class GvResultsScreen extends ConsumerWidget {
  const GvResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(adminContestsProvider);
    return ColoredBox(
      color: context.appBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ScreenHeader(
          breadcrumb: 'BTC',
          title: 'Kết quả',
          subtitle:
              'Tổng hợp kết quả các cuộc thi đã hoàn thành — link bảng xếp hạng + xuất Excel.',
        ),
        Expanded(
          child: asyncList.when(
            loading: () => const MCardListSkeleton(count: 3, textLines: 2),
            error: (e, _) => _ErrorBox(error: '$e'),
            data: (data) {
              final finished = data.items
                  .where((c) => c.status == 'FINISHED')
                  .toList()
                ..sort((a, b) => b.endAt.compareTo(a.endAt));
              if (finished.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s32),
                    child: Text(
                        'Chưa có cuộc thi nào kết thúc.\nKết quả sẽ hiển thị ở đây sau khi contest FINISHED.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: context.textMuted, fontSize: 13)),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s16),
                itemCount: finished.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.s12),
                itemBuilder: (_, i) =>
                    _ResultContestRow(contest: finished[i]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ResultContestRow extends ConsumerWidget {
  final ContestSummary contest;
  const _ResultContestRow({required this.contest});

  Future<void> _exportXlsx(BuildContext context, WidgetRef ref) async {
    await exportXlsxFromEndpoint(
      context: context,
      dio: ref.read(apiClientProvider).dio,
      path: '/contests/${contest.contestId}/results/export.xlsx',
      fallbackFilename:
          'ket-qua-${contest.slug}-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmt = DateFormat('dd/MM/yyyy');
    return MCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(contest.title,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.3)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8, vertical: 2),
            decoration: BoxDecoration(
              color: context.successSoft,
              borderRadius: BorderRadius.circular(AppRadius.tight),
            ),
            child: Text('FINISHED',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: context.successGreen,
                    letterSpacing: 0.5)),
          ),
        ]),
        const SizedBox(height: AppSpacing.s4),
        Text('Kết thúc ${fmt.format(contest.endAt.toLocal())} · ${contest.entriesCount} thí sinh',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.textMuted)),
        const SizedBox(height: AppSpacing.s12),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.leaderboard_outlined, size: 16),
              label: const Text('Bảng xếp hạng'),
              onPressed: () => context.push(
                  '/contests/${contest.contestId}/leaderboard',
                  extra: contest.title),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.download_outlined, size: 16),
              label: const Text('Xuất Excel'),
              style: FilledButton.styleFrom(backgroundColor: ptitRed),
              onPressed: () => _exportXlsx(context, ref),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ============== Screen 3: Thống kê GV ==============

class GvStatsScreen extends ConsumerWidget {
  const GvStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(adminContestsProvider);
    return ColoredBox(
      color: context.appBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ScreenHeader(
          breadcrumb: 'BTC',
          title: 'Thống kê',
          subtitle:
              'Phân bố trạng thái cuộc thi + tổng số đăng ký / hoàn thành.',
        ),
        Expanded(
          child: asyncList.when(
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: ptitRed, strokeWidth: 2)),
            error: (e, _) => _ErrorBox(error: '$e'),
            data: (data) {
              final items = data.items;
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.s32),
                    child: Text('Chưa có dữ liệu thống kê',
                        style: TextStyle(
                            color: context.textMuted, fontSize: 13)),
                  ),
                );
              }
              // Group by status
              final statusOrder = const [
                'DRAFT',
                'PUBLISHED',
                'REG_OPEN',
                'REG_CLOSED',
                'ONGOING',
                'FINISHED',
                'CANCELLED'
              ];
              final counts = <String, int>{
                for (final s in statusOrder) s: 0
              };
              for (final c in items) {
                counts[c.status] = (counts[c.status] ?? 0) + 1;
              }
              final maxCount = counts.values.fold(0,
                  (max, v) => v > max ? v : max);
              final totalEntries = items.fold<int>(
                  0, (sum, c) => sum + c.entriesCount);

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  _StatsBoxRow(
                    items: [
                      _StatsCell(
                          label: 'Tổng cuộc thi',
                          value: '${items.length}',
                          color: context.textPrimary),
                      _StatsCell(
                          label: 'Đang diễn ra',
                          value:
                              '${counts['ONGOING']! + counts['REG_OPEN']! + counts['REG_CLOSED']!}',
                          color: context.successGreen),
                      _StatsCell(
                          label: 'Đã hoàn thành',
                          value: '${counts['FINISHED']}',
                          color: context.infoBlue),
                      _StatsCell(
                          label: 'Tổng đăng ký',
                          value: '$totalEntries',
                          color: ptitRed),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  Text('Phân bố theo trạng thái',
                      style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary)),
                  const SizedBox(height: AppSpacing.s12),
                  ...statusOrder.map((s) {
                    final count = counts[s]!;
                    if (count == 0) return const SizedBox.shrink();
                    final pct = maxCount > 0 ? count / maxCount : 0.0;
                    return Padding(
                      padding:
                          const EdgeInsets.only(bottom: AppSpacing.s8),
                      child: _StatsBar(
                          label: s, count: count, pct: pct),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _StatsCell {
  final String label;
  final String value;
  final Color color;
  const _StatsCell(
      {required this.label, required this.value, required this.color});
}

class _StatsBoxRow extends StatelessWidget {
  final List<_StatsCell> items;
  const _StatsBoxRow({required this.items});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.s12,
      crossAxisSpacing: AppSpacing.s12,
      childAspectRatio: isMobile ? 1.5 : 2.2,
      children: items
          .map((it) => Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  border: Border.all(color: context.cardBorder),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(it.label.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: context.textMuted,
                            letterSpacing: 1.0)),
                    const SizedBox(height: AppSpacing.s8),
                    Text(it.value,
                        style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: it.color,
                            letterSpacing: -0.6,
                            height: 1)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _StatsBar extends StatelessWidget {
  final String label;
  final int count;
  final double pct;
  const _StatsBar(
      {required this.label, required this.count, required this.pct});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(
        width: 110,
        child: Text(label,
            style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: context.textMuted)),
      ),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.tight),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 14,
            backgroundColor: context.cardBorder.withValues(alpha: 0.4),
            valueColor: AlwaysStoppedAnimation(ptitRed),
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.s8),
      SizedBox(
        width: 30,
        child: Text('$count',
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: context.textPrimary)),
      ),
    ]);
  }
}

// ============== Screen 4: Xuất báo cáo GV ==============

class GvExportReportScreen extends ConsumerWidget {
  const GvExportReportScreen({super.key});

  Future<void> _exportSystemSummary(
      BuildContext context, WidgetRef ref) async {
    await exportXlsxFromEndpoint(
      context: context,
      dio: ref.read(apiClientProvider).dio,
      path: '/admin/reports/system-summary.xlsx',
      fallbackFilename:
          'bao-cao-tong-hop-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: context.appBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ScreenHeader(
          breadcrumb: 'BTC',
          title: 'Xuất báo cáo',
          subtitle:
              'Xuất Excel danh sách thí sinh + điểm + chứng nhận của cuộc thi.',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.s16),
            children: [
              _ExportCard(
                title: 'Báo cáo tổng hợp hệ thống',
                description:
                    '4 sheet Excel: tổng users / contests / entries + summary stats. Quyền ADMIN/HOD xem được.',
                icon: Icons.description_outlined,
                onExport: () => _exportSystemSummary(context, ref),
              ),
              const SizedBox(height: AppSpacing.s12),
              MCard(
                padding: const EdgeInsets.all(AppSpacing.s16),
                margin: EdgeInsets.zero,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Xuất theo từng cuộc thi',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              letterSpacing: -0.2)),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                          'Vào "Cuộc thi của tôi" → chọn contest → tab "Kết quả" → button "Xuất Excel" để xuất riêng từng cuộc thi (4 sheet: Tổng quan / Vòng-kết quả / Submissions / Metadata).',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: context.textMuted,
                              height: 1.5)),
                      const SizedBox(height: AppSpacing.s12),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.emoji_events_outlined,
                            size: 16),
                        label: const Text('Đi tới Cuộc thi của tôi'),
                        onPressed: () => context.go('/admin/contests'),
                      ),
                    ]),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _ExportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onExport;
  const _ExportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return MCard(
      padding: const EdgeInsets.all(AppSpacing.s16),
      margin: EdgeInsets.zero,
      child: Row(children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.ptitRedSoft,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: ptitRed, size: 24),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text(description,
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: context.textMuted,
                        height: 1.4)),
              ]),
        ),
        const SizedBox(width: AppSpacing.s12),
        FilledButton.icon(
          icon: const Icon(Icons.download_outlined, size: 16),
          label: const Text('Xuất'),
          style: FilledButton.styleFrom(
              minimumSize: const Size(100, 40), backgroundColor: ptitRed),
          onPressed: onExport,
        ),
      ]),
    );
  }
}

// ============== Shared header + error widgets ==============

class _ScreenHeader extends StatelessWidget {
  final String breadcrumb;
  final String title;
  final String subtitle;
  const _ScreenHeader({
    required this.breadcrumb,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (isMobile) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s32, vertical: AppSpacing.s20),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border(bottom: BorderSide(color: context.cardBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(breadcrumb,
              style: TextStyle(color: context.textMuted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(title,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12.5,
                  color: context.textMuted,
                  height: 1.5)),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String error;
  const _ErrorBox({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Text('Lỗi: $error',
            style: TextStyle(color: context.textMuted, fontSize: 12)),
      ),
    );
  }
}

