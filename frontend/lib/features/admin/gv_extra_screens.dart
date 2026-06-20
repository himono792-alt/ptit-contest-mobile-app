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
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/help_button.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/xlsx_export_helper.dart';
import 'admin_contests_screen.dart' show adminContestsProvider;

// ============== Screen 1: Lịch & deadline ==============

// Redesign 2026-06-20: tái cấu trúc đầy đủ — stat strip + toggle Timeline /
// Lịch tháng + nhóm theo mốc thời gian. Scale tốt khi nhiều cuộc thi.

/// Gom mọi mốc thời gian (mở/đóng ĐK, bắt đầu, kết thúc) của contests organizer
/// thành danh sách event đã sort. ALL = cả quá khứ lẫn tương lai (month view cần
/// quá khứ để chấm dot ngày cũ); timeline chỉ show tương lai.
List<_DeadlineEvent> _buildDeadlineEvents(
    BuildContext context, List<ContestSummary> items) {
  final events = <_DeadlineEvent>[];
  for (final c in items) {
    if (c.registrationOpenAt != null) {
      events.add(_DeadlineEvent(
        when: c.registrationOpenAt!,
        label: 'Mở đăng ký',
        contest: c,
        color: context.infoBlue,
        icon: Icons.lock_open_outlined,
      ));
    }
    if (c.registrationCloseAt != null) {
      events.add(_DeadlineEvent(
        when: c.registrationCloseAt!,
        label: 'Đóng đăng ký',
        contest: c,
        color: context.warnOrange,
        icon: Icons.lock_outline,
      ));
    }
    events.add(_DeadlineEvent(
      when: c.startAt,
      label: 'Bắt đầu thi',
      contest: c,
      color: ptitRed,
      icon: Icons.flag_outlined,
    ));
    events.add(_DeadlineEvent(
      when: c.endAt,
      label: 'Kết thúc thi',
      contest: c,
      color: context.successGreen,
      icon: Icons.emoji_events_outlined,
    ));
  }
  events.sort((a, b) => a.when.compareTo(b.when));
  return events;
}

class GvCalendarDeadlineScreen extends ConsumerStatefulWidget {
  const GvCalendarDeadlineScreen({super.key});

  @override
  ConsumerState<GvCalendarDeadlineScreen> createState() =>
      _GvCalendarDeadlineScreenState();
}

class _GvCalendarDeadlineScreenState
    extends ConsumerState<GvCalendarDeadlineScreen> {
  bool _monthView = false;
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(adminContestsProvider);
    return ColoredBox(
      color: context.appBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ScreenHeader(
          breadcrumb: 'BTC',
          title: 'Lịch & deadline',
          subtitle:
              'Các mốc thời gian quan trọng — đăng ký, vòng loại, công bố.',
          helpId: 'gv_calendar',
        ),
        Expanded(
          child: asyncList.when(
            loading: () => const MCardListSkeleton(count: 4, textLines: 2),
            error: (e, _) => _ErrorBox(error: '$e'),
            data: (data) {
              final all = _buildDeadlineEvents(context, data.items);
              final now = DateTime.now();
              final upcoming =
                  all.where((e) => e.when.isAfter(now)).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.s16,
                        AppSpacing.s16, AppSpacing.s16, AppSpacing.s8),
                    child: _DeadlineStatStrip(upcoming: upcoming),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16, vertical: AppSpacing.s4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _CalViewToggle(
                        monthView: _monthView,
                        onChanged: (v) => setState(() => _monthView = v),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _monthView
                        ? _MonthGridView(
                            all: all,
                            visibleMonth: _visibleMonth,
                            selectedDay: _selectedDay,
                            onPrev: () => setState(() => _visibleMonth =
                                DateTime(_visibleMonth.year,
                                    _visibleMonth.month - 1)),
                            onNext: () => setState(() => _visibleMonth =
                                DateTime(_visibleMonth.year,
                                    _visibleMonth.month + 1)),
                            onSelectDay: (d) =>
                                setState(() => _selectedDay = d),
                          )
                        : _TimelineView(events: upcoming),
                  ),
                ],
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ---------- Stat strip ----------

class _DeadlineStatStrip extends StatelessWidget {
  final List<_DeadlineEvent> upcoming;
  const _DeadlineStatStrip({required this.upcoming});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final in24h = upcoming
        .where((e) => e.when.difference(now).inHours < 24)
        .length;
    final thisWeek = upcoming
        .where((e) => e.when.difference(now).inDays < 7)
        .length;
    return Row(children: [
      Expanded(
        child: _MiniStat(
          value: '${upcoming.length}',
          label: 'Sắp tới',
          color: ptitRed,
          icon: Icons.event_note_outlined,
        ),
      ),
      const SizedBox(width: AppSpacing.s8),
      Expanded(
        child: _MiniStat(
          value: '$in24h',
          label: 'Trong 24h',
          color: context.warnOrange,
          icon: Icons.alarm_outlined,
        ),
      ),
      const SizedBox(width: AppSpacing.s8),
      Expanded(
        child: _MiniStat(
          value: '$thisWeek',
          label: 'Tuần này',
          color: context.infoBlue,
          icon: Icons.date_range_outlined,
        ),
      ),
    ]);
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;
  const _MiniStat({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
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
      child: Row(children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      height: 1.1,
                      letterSpacing: -0.5)),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.textMuted)),
            ],
          ),
        ),
      ]),
    );
  }
}

// ---------- View toggle ----------

class _CalViewToggle extends StatelessWidget {
  final bool monthView;
  final ValueChanged<bool> onChanged;
  const _CalViewToggle({required this.monthView, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.cardBorder.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _toggleBtn(context, Icons.timeline, 'Dòng thời gian', !monthView,
            () => onChanged(false)),
        _toggleBtn(context, Icons.calendar_month_outlined, 'Lịch tháng',
            monthView, () => onChanged(true)),
      ]),
    );
  }

  Widget _toggleBtn(BuildContext context, IconData icon, String label,
      bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? context.cardBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 15,
              color: active ? ptitRed : context.textMuted),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: active ? context.textPrimary : context.textMuted)),
        ]),
      ),
    );
  }
}

// ---------- Timeline view (nhóm theo mốc) ----------

class _TimelineView extends StatelessWidget {
  final List<_DeadlineEvent> events;
  const _TimelineView({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const EmptyView(
        icon: Icons.event_available_outlined,
        title: 'Không có deadline nào sắp tới',
        subtitle: 'Các mốc thời gian của cuộc thi sẽ hiện ở đây.',
      );
    }
    // Nhóm theo bucket thời gian.
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final groups = <String, List<_DeadlineEvent>>{};
    for (final e in events) {
      final d = DateTime(e.when.year, e.when.month, e.when.day);
      final diff = d.difference(today).inDays;
      final String key;
      if (diff <= 0) {
        key = 'Hôm nay';
      } else if (diff == 1) {
        key = 'Ngày mai';
      } else if (diff < 7) {
        key = 'Tuần này';
      } else if (e.when.year == now.year && e.when.month == now.month) {
        key = 'Tháng này';
      } else {
        key = 'Sau này';
      }
      groups.putIfAbsent(key, () => []).add(e);
    }
    const order = ['Hôm nay', 'Ngày mai', 'Tuần này', 'Tháng này', 'Sau này'];
    final keys = order.where(groups.containsKey).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s24),
      children: [
        for (final k in keys) ...[
          Padding(
            padding: const EdgeInsets.only(
                top: AppSpacing.s12, bottom: AppSpacing.s8),
            child: Row(children: [
              Text(k,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.2)),
              const SizedBox(width: AppSpacing.s8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(
                  color: context.cardBorder.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.tight),
                ),
                child: Text('${groups[k]!.length}',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: context.textMuted)),
              ),
            ]),
          ),
          for (var i = 0; i < groups[k]!.length; i++)
            _TimelineTile(
              event: groups[k]![i],
              isLast: i == groups[k]!.length - 1,
            ),
        ],
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final _DeadlineEvent event;
  final bool isLast;
  const _TimelineTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rail: dot + đường nối dọc.
          SizedBox(
            width: 28,
            child: Column(children: [
              const SizedBox(height: 6),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: event.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.appBg, width: 2),
                  boxShadow: [
                    BoxShadow(
                        color: event.color.withValues(alpha: 0.4),
                        blurRadius: 4)
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: context.cardBorder,
                  ),
                ),
            ]),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s8),
              child: _DeadlineEventCard(event: event),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card mô tả 1 mốc — dùng chung cho timeline + danh sách ngày của month view.
class _DeadlineEventCard extends StatelessWidget {
  final _DeadlineEvent event;
  const _DeadlineEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final remaining = event.when.difference(DateTime.now());
    final overdue = remaining.isNegative;
    final remainStr = overdue
        ? 'đã qua'
        : remaining.inDays >= 1
            ? 'còn ${remaining.inDays} ngày'
            : 'còn ${remaining.inHours}h ${remaining.inMinutes % 60}m';
    final urgent = !overdue && remaining.inHours < 24;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.go('/admin/contests'),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          border: Border.all(
              color: urgent
                  ? event.color.withValues(alpha: 0.5)
                  : context.cardBorder),
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          // Accent bar trái màu theo loại mốc.
          Container(
            width: 4,
            height: 56,
            decoration: BoxDecoration(
              color: event.color,
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.md)),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: event.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(event.icon, color: event.color, size: 19),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
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
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8, vertical: 3),
              decoration: BoxDecoration(
                color: (overdue ? context.textMuted : event.color)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.tight),
              ),
              child: Text(remainStr,
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: overdue ? context.textMuted : event.color)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------- Month grid view ----------

class _MonthGridView extends StatelessWidget {
  final List<_DeadlineEvent> all;
  final DateTime visibleMonth;
  final DateTime selectedDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelectDay;
  const _MonthGridView({
    required this.all,
    required this.visibleMonth,
    required this.selectedDay,
    required this.onPrev,
    required this.onNext,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    // Map ngày -> events (chỉ trong tháng đang xem cho grid).
    final byDay = <int, List<_DeadlineEvent>>{};
    for (final e in all) {
      if (e.when.year == visibleMonth.year &&
          e.when.month == visibleMonth.month) {
        byDay.putIfAbsent(e.when.day, () => []).add(e);
      }
    }
    final daysInMonth =
        DateTime(visibleMonth.year, visibleMonth.month + 1, 0).day;
    final firstWeekday = DateTime(visibleMonth.year, visibleMonth.month, 1)
        .weekday; // Mon=1..Sun=7
    final leadingBlanks = firstWeekday - 1;
    final totalCells = leadingBlanks + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    final selectedEvents = (selectedDay.year == visibleMonth.year &&
            selectedDay.month == visibleMonth.month)
        ? (byDay[selectedDay.day] ?? const [])
        : const <_DeadlineEvent>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s8, AppSpacing.s16, AppSpacing.s24),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.s12),
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
          child: Column(children: [
            // Header tháng.
            Row(children: [
              Text('Tháng ${visibleMonth.month}/${visibleMonth.year}',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.3)),
              const Spacer(),
              _navBtn(context, Icons.chevron_left, onPrev),
              const SizedBox(width: 4),
              _navBtn(context, Icons.chevron_right, onNext),
            ]),
            const SizedBox(height: AppSpacing.s12),
            // Nhãn thứ.
            Row(
              children: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(d,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: context.textMuted)),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 6),
            // Grid.
            for (var r = 0; r < rows; r++)
              Row(
                children: List.generate(7, (c) {
                  final cellIdx = r * 7 + c;
                  final dayNum = cellIdx - leadingBlanks + 1;
                  if (dayNum < 1 || dayNum > daysInMonth) {
                    return const Expanded(child: SizedBox(height: 46));
                  }
                  final dayEvents = byDay[dayNum] ?? const [];
                  final isToday = today.year == visibleMonth.year &&
                      today.month == visibleMonth.month &&
                      today.day == dayNum;
                  final isSelected = selectedDay.year == visibleMonth.year &&
                      selectedDay.month == visibleMonth.month &&
                      selectedDay.day == dayNum;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onSelectDay(DateTime(
                          visibleMonth.year, visibleMonth.month, dayNum)),
                      child: Container(
                        height: 46,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? ptitRed.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: isSelected
                              ? Border.all(
                                  color: ptitRed.withValues(alpha: 0.5))
                              : isToday
                                  ? Border.all(color: context.cardBorder)
                                  : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('$dayNum',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: isToday || isSelected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? ptitRed
                                      : isToday
                                          ? context.textPrimary
                                          : context.textMuted,
                                )),
                            const SizedBox(height: 3),
                            SizedBox(
                              height: 5,
                              child: dayEvents.isEmpty
                                  ? null
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: dayEvents
                                          .take(3)
                                          .map((e) => Container(
                                                width: 5,
                                                height: 5,
                                                margin: const EdgeInsets
                                                    .symmetric(horizontal: 1),
                                                decoration: BoxDecoration(
                                                  color: e.color,
                                                  shape: BoxShape.circle,
                                                ),
                                              ))
                                          .toList(),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
          ]),
        ),
        const SizedBox(height: AppSpacing.s16),
        // Danh sách event của ngày đang chọn.
        Row(children: [
          Icon(Icons.event_outlined, size: 15, color: context.textMuted),
          const SizedBox(width: 6),
          Text(
              'Ngày ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary)),
        ]),
        const SizedBox(height: AppSpacing.s8),
        if (selectedEvents.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border.all(color: context.cardBorder),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Center(
              child: Text('Không có mốc nào trong ngày này',
                  style: TextStyle(color: context.textMuted, fontSize: 12.5)),
            ),
          )
        else
          for (final e in selectedEvents) ...[
            _DeadlineEventCard(event: e),
            const SizedBox(height: AppSpacing.s8),
          ],
      ],
    );
  }

  Widget _navBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: context.cardBorder.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, size: 18, color: context.textPrimary),
      ),
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

// ============== Screen 2: Kết quả contests organizer ==============

// Redesign 2026-06-20: stat strip + ô tìm kiếm + nhóm theo tháng kết thúc.

class GvResultsScreen extends ConsumerStatefulWidget {
  const GvResultsScreen({super.key});

  @override
  ConsumerState<GvResultsScreen> createState() => _GvResultsScreenState();
}

class _GvResultsScreenState extends ConsumerState<GvResultsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final asyncList = ref.watch(adminContestsProvider);
    return ColoredBox(
      color: context.appBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _ScreenHeader(
          breadcrumb: 'BTC',
          title: 'Kết quả',
          subtitle:
              'Tổng hợp kết quả các cuộc thi đã hoàn thành — link bảng xếp hạng + xuất Excel.',
          helpId: 'gv_results',
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
                return const EmptyView(
                  icon: Icons.emoji_events_outlined,
                  title: 'Chưa có cuộc thi nào kết thúc',
                  subtitle: 'Kết quả sẽ hiển thị sau khi contest FINISHED.',
                );
              }
              final totalParticipants =
                  finished.fold<int>(0, (s, c) => s + c.entriesCount);
              final lastEnd = finished.first.endAt;
              // Lọc theo từ khóa.
              final q = _query.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? finished
                  : finished
                      .where((c) => c.title.toLowerCase().contains(q))
                      .toList();
              // Nhóm theo tháng kết thúc (giữ thứ tự mới → cũ).
              final groups = <String, List<ContestSummary>>{};
              for (final c in filtered) {
                final k = 'Tháng ${c.endAt.month}/${c.endAt.year}';
                groups.putIfAbsent(k, () => []).add(c);
              }

              return ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  Row(children: [
                    Expanded(
                      child: _MiniStat(
                        value: '${finished.length}',
                        label: 'Cuộc thi đã xong',
                        color: context.successGreen,
                        icon: Icons.emoji_events_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: _MiniStat(
                        value: '$totalParticipants',
                        label: 'Tổng thí sinh',
                        color: context.infoBlue,
                        icon: Icons.groups_outlined,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: _MiniStat(
                        value: DateFormat('dd/MM').format(lastEnd.toLocal()),
                        label: 'Gần nhất',
                        color: ptitRed,
                        icon: Icons.history_outlined,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.s12),
                  SizedBox(
                    height: 42,
                    child: TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Tìm cuộc thi đã kết thúc...',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        isDense: true,
                        filled: true,
                        fillColor: context.cardBg,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: context.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: BorderSide(color: context.cardBorder),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.s24),
                      child: Center(
                        child: Text('Không tìm thấy cuộc thi phù hợp',
                            style: TextStyle(
                                color: context.textMuted, fontSize: 13)),
                      ),
                    )
                  else
                    for (final entry in groups.entries) ...[
                      Padding(
                        padding: const EdgeInsets.only(
                            top: AppSpacing.s12, bottom: AppSpacing.s8),
                        child: Row(children: [
                          Text(entry.key,
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: context.textPrimary,
                                  letterSpacing: -0.2)),
                          const SizedBox(width: AppSpacing.s8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 1),
                            decoration: BoxDecoration(
                              color: context.cardBorder.withValues(alpha: 0.4),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.tight),
                            ),
                            child: Text('${entry.value.length}',
                                style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: context.textMuted)),
                          ),
                        ]),
                      ),
                      for (final c in entry.value) ...[
                        _ResultContestRow(contest: c),
                        const SizedBox(height: AppSpacing.s12),
                      ],
                    ],
                ],
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
    final gold = context.achievementGold;
    return Container(
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
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Accent bar vàng (đã trao giải).
        Container(
          width: 4,
          decoration: BoxDecoration(
            color: gold,
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadius.md)),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Icon(Icons.emoji_events,
                          color: gold, size: 21),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(contest.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              height: 1.2,
                              letterSpacing: -0.3)),
                    ),
                    const SizedBox(width: AppSpacing.s8),
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
                  const SizedBox(height: AppSpacing.s12),
                  Row(children: [
                    _resultChip(context, Icons.event_outlined,
                        'Kết thúc ${fmt.format(contest.endAt.toLocal())}'),
                    const SizedBox(width: AppSpacing.s8),
                    _resultChip(context, Icons.groups_outlined,
                        '${contest.entriesCount} thí sinh'),
                  ]),
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
                        style:
                            FilledButton.styleFrom(backgroundColor: ptitRed),
                        onPressed: () => _exportXlsx(context, ref),
                      ),
                    ),
                  ]),
                ]),
          ),
        ),
      ]),
    );
  }

  Widget _resultChip(BuildContext context, IconData icon, String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 4),
      decoration: BoxDecoration(
        color: context.cardBorder.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.tight),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: context.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.textMuted)),
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
          helpId: 'gv_stats',
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
                return const EmptyView(
                  icon: Icons.bar_chart_outlined,
                  title: 'Chưa có dữ liệu thống kê',
                  subtitle: 'Dữ liệu sẽ hiện sau khi có cuộc thi hoàn thành.',
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
          helpId: 'gv_export',
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
  final String? helpId;
  const _ScreenHeader({
    required this.breadcrumb,
    required this.title,
    required this.subtitle,
    this.helpId,
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
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
          ),
          if (helpId != null) HelpButton(id: helpId!),
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

