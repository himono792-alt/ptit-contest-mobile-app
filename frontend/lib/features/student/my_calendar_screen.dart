// Sprint 20+ Item 3 (2026-05-09) — Lịch của tôi.
//
// Hiển thị lịch các cuộc thi SV đã đăng ký, group theo tháng, sort by
// contest_start_at asc. Reuse myEntriesProvider không thêm endpoint mới.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/help_button.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/m_top_bar.dart';
import 'my_registrations_screen.dart';

class MyCalendarScreen extends ConsumerWidget {
  const MyCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(myEntriesProvider);
    return Scaffold(
      appBar: const MTopBar(title: 'Lịch của tôi', actions: [
        HelpButton(id: 'sv_my_calendar'),
      ]),
      body: asyncList.when(
        loading: () => const MCardListSkeleton(count: 3, textLines: 2),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Text('Không tải được lịch',
                style: TextStyle(color: context.textMuted, fontSize: 13)),
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return _emptyState(context);
          }
          // Group by year-month, sort items theo contest_start_at asc
          final sorted = [...entries]..sort((a, b) {
              final aDate =
                  DateTime.tryParse(a['contest_start_at'] ?? '') ?? DateTime(2099);
              final bDate =
                  DateTime.tryParse(b['contest_start_at'] ?? '') ?? DateTime(2099);
              return aDate.compareTo(bDate);
            });
          final groups = <String, List<Map<String, dynamic>>>{};
          for (final e in sorted) {
            final dt = DateTime.tryParse(e['contest_start_at'] ?? '');
            if (dt == null) continue;
            final key = '${dt.month}/${dt.year}';
            groups.putIfAbsent(key, () => []).add(e);
          }

          return RefreshIndicator(
            color: ptitRed,
            onRefresh: () async => ref.invalidate(myEntriesProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s24),
              children: [
                for (final entry in groups.entries) ...[
                  _MonthHeader(label: 'Tháng ${entry.key}'),
                  const SizedBox(height: AppSpacing.s8),
                  ...entry.value.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                        child: _CalendarItem(entry: e),
                      )),
                  const SizedBox(height: AppSpacing.s12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) => const EmptyView(
        icon: Icons.calendar_today_outlined,
        title: 'Chưa có sự kiện nào',
        subtitle: 'Đăng ký cuộc thi để xuất hiện lịch ở đây.',
      );
}

class _MonthHeader extends StatelessWidget {
  final String label;
  const _MonthHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s4),
      child: Text(label.toUpperCase(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: context.textMuted,
            letterSpacing: 1.5,
          )),
    );
  }
}

class _CalendarItem extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _CalendarItem({required this.entry});

  String _statusLabel(String cs) {
    switch (cs) {
      case 'REG_OPEN':
        return 'Đăng ký';
      case 'REG_CLOSED':
        return 'Đóng ĐK';
      case 'ONGOING':
        return 'Đang thi';
      case 'FINISHED':
        return 'Kết thúc';
      case 'PUBLISHED':
        return 'Sắp diễn ra';
      default:
        return cs;
    }
  }

  Color _statusColor(BuildContext context, String cs) {
    switch (cs) {
      case 'REG_OPEN':
        return ptitRed;
      case 'ONGOING':
        return context.successGreen;
      case 'FINISHED':
        return context.textMuted;
      default:
        return context.infoBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = (entry['contest_status'] as String?) ?? '';
    final start = DateTime.tryParse(entry['contest_start_at'] ?? '');
    final dayStr = start != null ? DateFormat('dd').format(start) : '—';
    final timeStr = start != null ? DateFormat('HH:mm').format(start) : '';
    final dowStr =
        start != null ? _vnDow(start.weekday) : '';

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.push('/contests/${entry['contest_slug']}'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border.all(color: context.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(children: [
          // Date pill
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
            decoration: BoxDecoration(
              color: context.ptitRedSoft,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Column(children: [
              Text(dayStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: ptitRed,
                    height: 1,
                    letterSpacing: -0.4,
                  )),
              const SizedBox(height: 2),
              Text(dowStr,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: ptitRed,
                    letterSpacing: 0.8,
                  )),
            ]),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry['contest_title'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimary,
                      letterSpacing: -0.2,
                      height: 1.3,
                    )),
                const SizedBox(height: 3),
                Row(children: [
                  Icon(Icons.access_time,
                      size: 12, color: context.textMuted),
                  const SizedBox(width: AppSpacing.s4),
                  Text(timeStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.textMuted,
                      )),
                ]),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 3),
            decoration: BoxDecoration(
              color: _statusColor(context, cs).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.tight),
            ),
            child: Text(_statusLabel(cs),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _statusColor(context, cs),
                )),
          ),
        ]),
      ),
    );
  }

  String _vnDow(int weekday) {
    switch (weekday) {
      case 1:
        return 'T2';
      case 2:
        return 'T3';
      case 3:
        return 'T4';
      case 4:
        return 'T5';
      case 5:
        return 'T6';
      case 6:
        return 'T7';
      case 7:
        return 'CN';
      default:
        return '';
    }
  }
}
