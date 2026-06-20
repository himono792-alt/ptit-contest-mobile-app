part of 'admin_dashboard_screen.dart';

// ============== Sprint 21+ : BCN/HOD Dashboard Rich ==============
//
// Mockup: header + 4 stat cards (Queue chờ / Sắp hạn ≤24h / CT đang diễn ra / SV khoa)
// + 2-col Queue ưu tiên (top 5 SLA) + Hiệu suất duyệt donut + Cảnh báo.
// Data: pendingApprovalsProvider + hodFacultyStatsProvider (đã có).
// SLA giả định 48h từ submit; "sắp hạn" = (deadline - now) ≤ 24h.

const int _kBCNApprovalSlaHours = 48;

class _BCNDashboardRich extends ConsumerWidget {
  final dynamic user;
  const _BCNDashboardRich({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPending = ref.watch(pendingApprovalsProvider);
    final asyncFaculty = ref.watch(hodFacultyStatsProvider);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 1200;
    final today = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(today);
    final weekNo = _isoWeekNumberHod(today);

    final facultyName = asyncFaculty.maybeWhen(
        data: (d) => (d?['faculty_name'] as String?) ?? 'Khoa',
        orElse: () => 'Khoa');

    // Sprint 28 hotfix #7: short name 2 từ cuối cho greeting (vd "Tran Van B"
    // → "Văn B"). Fallback về full name nếu chỉ 1 từ.
    final fullName = (user.fullName as String?) ?? '';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final userName = parts.length >= 2
        ? '${parts[parts.length - 2]} ${parts.last}'
        : (parts.isNotEmpty ? parts.first : '');

    return ColoredBox(
      color: context.appBg,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          isCompact ? AppSpacing.s16 : AppSpacing.s32,
          AppSpacing.s24,
          isCompact ? AppSpacing.s16 : AppSpacing.s32,
          AppSpacing.s32,
        ),
        children: [
          _BCNHeader(
              facultyName: facultyName,
              userName: userName,
              dateStr: dateStr,
              weekNo: weekNo,
              isCompact: isCompact),
          const SizedBox(height: AppSpacing.s24),
          asyncPending.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                  child: CircularProgressIndicator(
                      color: ptitRed, strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Text('Không tải được dữ liệu duyệt: $e',
                  style: TextStyle(color: context.textMuted, fontSize: 13)),
            ),
            data: (pendingList) {
              final ongoing = asyncFaculty.maybeWhen(
                  data: (d) => (d?['contests_ongoing'] as int?) ?? 0,
                  orElse: () => 0);
              final totalStudents = asyncFaculty.maybeWhen(
                  data: (d) => (d?['total_unique_students'] as int?) ?? 0,
                  orElse: () => 0);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BCNStatRow(
                      pendingList: pendingList,
                      contestsOngoing: ongoing,
                      totalStudents: totalStudents,
                      isCompact: isCompact),
                  const SizedBox(height: AppSpacing.s24),
                  if (isCompact) ...[
                    _BCNQueuePriority(pendingList: pendingList),
                    const SizedBox(height: AppSpacing.s24),
                    _BCNApprovalDonut(pendingList: pendingList),
                    const SizedBox(height: AppSpacing.s16),
                    _BCNAlertsCard(pendingList: pendingList),
                  ] else
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 7,
                              child: _BCNQueuePriority(
                                  pendingList: pendingList)),
                          const SizedBox(width: AppSpacing.s24),
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _BCNApprovalDonut(pendingList: pendingList),
                                const SizedBox(height: AppSpacing.s16),
                                _BCNAlertsCard(pendingList: pendingList),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

int _isoWeekNumberHod(DateTime date) {
  final dayOfYear = int.parse(DateFormat('D').format(date));
  final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
  if (woy < 1) return _isoWeekNumberHod(DateTime(date.year - 1, 12, 28));
  if (woy > 52) {
    final lastWeek = _isoWeekNumberHod(DateTime(date.year, 12, 28));
    if (lastWeek == 53) return 53;
    return 1;
  }
  return woy;
}

/// Sprint 28 hotfix #7 (2026-05-10): BCN header sinh động — time-aware
/// greeting + sub-line stats (queue chờ duyệt + cuộc thi khoa + thứ/tuần) +
/// gradient subtle. Stats từ pendingApprovalsProvider + hodFacultyStatsProvider.
class _BCNHeader extends ConsumerWidget {
  final String facultyName;
  final String userName;
  final String dateStr;
  final int weekNo;
  final bool isCompact;

  const _BCNHeader({
    required this.facultyName,
    required this.userName,
    required this.dateStr,
    required this.weekNo,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final g = _greetingByHour(now.hour);
    final dayName = _dayNameVi(now.weekday);

    final asyncPending = ref.watch(pendingApprovalsProvider);
    final pendingCount = asyncPending.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );
    final asyncFaculty = ref.watch(hodFacultyStatsProvider);
    final ongoingCount = asyncFaculty.maybeWhen(
      data: (data) => (data?['contests_ongoing'] as int?) ?? 0,
      orElse: () => 0,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppSpacing.s16 : AppSpacing.s24,
        vertical: isCompact ? AppSpacing.s16 : AppSpacing.s20,
      ),
      decoration: _dashHeaderGradient(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BCN · $facultyName',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: ptitRed,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: AppSpacing.s4),
                Text('${g.greeting}, $userName ${g.emoji}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isCompact ? 22 : 26,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.7,
                      height: 1.1,
                    )),
                const SizedBox(height: AppSpacing.s8),
                Wrap(
                  spacing: AppSpacing.s12,
                  runSpacing: AppSpacing.s4,
                  children: [
                    _DashHeaderChip(
                      icon: '⏰',
                      label: '$pendingCount đề xuất',
                      hint: pendingCount > 0 ? 'chờ duyệt' : 'queue trống',
                    ),
                    _DashHeaderChip(
                      icon: '🏛',
                      label: '$ongoingCount cuộc thi',
                      hint: 'đang diễn ra',
                    ),
                    _DashHeaderChip(
                      icon: '📅',
                      label: dayName,
                      hint: '$dateStr · Tuần $weekNo',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          const HelpButton(id: 'bcn_dashboard'),
        ],
      ),
    );
  }
}

class _BCNStatRow extends ConsumerWidget {
  final List<dynamic> pendingList;
  final int contestsOngoing;
  final int totalStudents;
  final bool isCompact;
  const _BCNStatRow({
    required this.pendingList,
    required this.contestsOngoing,
    required this.totalStudents,
    required this.isCompact,
  });

  /// Format delta number → "▲ +N" green / "▼ -N" red / "— ổn định" muted.
  ({String text, Color color}) _formatDelta(
      BuildContext context, int delta, String suffix) {
    if (delta > 0) {
      return (text: '▲ +$delta $suffix', color: context.successGreen);
    } else if (delta < 0) {
      return (text: '▼ ${delta.abs()} $suffix', color: ptitRed);
    }
    return (text: '— ổn định', color: context.textMuted);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDeltas = ref.watch(bcnDeltasProvider);
    final deltas = asyncDeltas.valueOrNull;

    final now = DateTime.now();
    // Sắp hạn ≤24h: deadline = submit + SLA(48h); (deadline - now) ≤ 24h
    // tức submit ≤ now - 24h.
    final urgent = pendingList.where((ap) {
      final submitted = DateTime.tryParse(ap['submitted_at'] ?? '');
      if (submitted == null) return false;
      final deadline = submitted.add(const Duration(hours: _kBCNApprovalSlaHours));
      return deltas == null
          ? deadline.difference(now).inHours <= 24
          : false; // BE đã trả urgent_count, fallback dùng client-side khi BE chưa lên
    }).length;

    final beUrgent = (deltas?['urgent_count'] as int?) ?? urgent;
    final beQueueDelta = (deltas?['queue_pending_delta_24h'] as int?) ?? 0;
    final beOngoingDelta =
        (deltas?['contests_ongoing_delta_7d'] as int?) ?? 0;
    final beStudentsDelta = (deltas?['students_delta_30d'] as int?) ?? 0;

    final queueDelta = _formatDelta(context, -beQueueDelta, 'hôm qua');
    final ongoingDelta =
        _formatDelta(context, beOngoingDelta, 'tuần này');
    final studentsDelta =
        _formatDelta(context, beStudentsDelta, '');

    final cards = <Widget>[
      _StatCardRich(
        label: 'QUEUE CHỜ DUYỆT',
        value: '${pendingList.length}',
        trend: pendingList.isEmpty ? '— rảnh' : queueDelta.text,
        trendColor:
            pendingList.isEmpty ? context.textMuted : queueDelta.color,
        progressColor: ptitRed,
        progress: (pendingList.length / 30).clamp(0.0, 1.0),
      ),
      _StatCardRich(
        label: 'SẮP HẠN (≤ 24H)',
        value: '$beUrgent',
        trend: beUrgent > 0 ? '⚠ Cần xử lý' : '— ổn',
        trendColor: beUrgent > 0 ? ptitRed : context.textMuted,
        progressColor: ptitRed,
        progress: (beUrgent / 10).clamp(0.0, 1.0),
      ),
      _StatCardRich(
        label: 'CT ĐANG DIỄN RA',
        value: '$contestsOngoing',
        trend: contestsOngoing == 0 ? '— ổn định' : ongoingDelta.text,
        trendColor:
            contestsOngoing == 0 ? context.textMuted : ongoingDelta.color,
        progressColor: context.successGreen,
        progress: (contestsOngoing / 20).clamp(0.0, 1.0),
      ),
      _StatCardRich(
        label: 'SV KHOA',
        value: '$totalStudents',
        trend: studentsDelta.text,
        trendColor: studentsDelta.color,
        progressColor: context.infoBlue,
        progress: (totalStudents / 1000).clamp(0.0, 1.0),
      ),
    ];

    if (isCompact) {
      return Column(
        children: [
          Row(children: [
            Expanded(child: cards[0]),
            const SizedBox(width: AppSpacing.s12),
            Expanded(child: cards[1]),
          ]),
          const SizedBox(height: AppSpacing.s12),
          Row(children: [
            Expanded(child: cards[2]),
            const SizedBox(width: AppSpacing.s12),
            Expanded(child: cards[3]),
          ]),
        ],
      );
    }
    return Row(children: [
      for (var i = 0; i < cards.length; i++) ...[
        Expanded(child: cards[i]),
        if (i < cards.length - 1) const SizedBox(width: AppSpacing.s16),
      ],
    ]);
  }
}

class _BCNQueuePriority extends StatelessWidget {
  final List<dynamic> pendingList;
  const _BCNQueuePriority({required this.pendingList});

  @override
  Widget build(BuildContext context) {
    // Sort by submitted_at asc (cũ nhất sắp hết SLA trước).
    final sorted = [...pendingList]
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['submitted_at'] ?? '') ??
            DateTime(2099);
        final bDate = DateTime.tryParse(b['submitted_at'] ?? '') ??
            DateTime(2099);
        return aDate.compareTo(bDate);
      });
    final top5 = sorted.take(5).toList();
    final now = DateTime.now();
    final urgentCount = top5.where((ap) {
      final submitted = DateTime.tryParse(ap['submitted_at'] ?? '');
      if (submitted == null) return false;
      final deadline =
          submitted.add(const Duration(hours: _kBCNApprovalSlaHours));
      return deadline.difference(now).inHours <= 24;
    }).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Queue ưu tiên',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: context.textPrimary,
                  )),
            ),
            if (urgentCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.ptitRedSoft,
                  borderRadius: BorderRadius.circular(AppRadius.tight),
                ),
                child: Text('$urgentCount sắp hết hạn',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: ptitRed,
                    )),
              ),
          ]),
          const SizedBox(height: AppSpacing.s12),
          if (top5.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
              child: Center(
                child: Text('Không có đề xuất nào chờ duyệt',
                    style:
                        TextStyle(color: context.textMuted, fontSize: 12)),
              ),
            )
          else
            ...top5
                .asMap()
                .entries
                .map((entry) => Padding(
                      padding: EdgeInsets.only(
                          bottom: entry.key < top5.length - 1
                              ? AppSpacing.s12
                              : 0,
                          top: entry.key == 0 ? 0 : 0),
                      child: _BCNQueueItem(approval: entry.value),
                    ))
                ,
        ],
      ),
    );
  }
}

class _BCNQueueItem extends StatelessWidget {
  final Map<String, dynamic> approval;
  const _BCNQueueItem({required this.approval});

  String _stepLabel(String step) {
    switch (step) {
      case 'BCN_QD1':
        return 'QĐ1';
      case 'BCN_QD2':
        return 'QĐ2';
      case 'BCN_QD3':
        return 'QĐ3';
      default:
        return step;
    }
  }

  /// Format remaining time tới deadline (now - submitted + 48h).
  ({String remainText, Color color}) _remainMeta(BuildContext context) {
    final now = DateTime.now();
    final submitted = DateTime.tryParse(approval['submitted_at'] ?? '');
    if (submitted == null) {
      return (remainText: '—', color: context.textMuted);
    }
    final deadline =
        submitted.add(const Duration(hours: _kBCNApprovalSlaHours));
    final diff = deadline.difference(now);
    if (diff.isNegative) {
      return (remainText: 'Quá hạn', color: ptitRed);
    }
    final hours = diff.inHours;
    final days = diff.inDays;
    final String label;
    if (hours < 24) {
      label = 'còn ${hours}h';
    } else if (days < 7) {
      final remH = hours - days * 24;
      label = remH > 0 ? 'còn ${days}d ${remH}h' : 'còn $days ngày';
    } else {
      label = '$days ngày';
    }
    final color = hours <= 24
        ? ptitRed
        : (days <= 2 ? context.warnOrange : context.textMuted);
    return (remainText: label, color: color);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM HH:mm');
    final submitted = DateTime.tryParse(approval['submitted_at'] ?? '');
    final deadline =
        submitted?.add(const Duration(hours: _kBCNApprovalSlaHours));
    final remain = _remainMeta(context);
    final stepStr = _stepLabel((approval['step'] as String?) ?? '');
    final title = (approval['contest_title'] as String?) ?? '—';
    final note = (approval['submission_note'] as String?) ?? '';
    final round = approval['revision_round'] as int? ?? 1;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: context.cardBorder.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.tight),
        border: Border.all(color: context.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8, vertical: 1),
              decoration: BoxDecoration(
                color: context.ptitRedSoft,
                borderRadius: BorderRadius.circular(AppRadius.tight),
              ),
              child: Text(stepStr,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: ptitRed,
                  )),
            ),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                    letterSpacing: -0.2,
                  )),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
              'Đề xuất lần $round${note.isNotEmpty ? " · $note" : ""}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.textMuted,
              )),
          const SizedBox(height: 6),
          Row(children: [
            Text(remain.remainText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: remain.color,
                )),
            const SizedBox(width: AppSpacing.s8),
            if (deadline != null)
              Text(fmt.format(deadline.toLocal()),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: context.textMuted,
                  )),
          ]),
        ],
      ),
    );
  }
}

// ============== Donut chart Hiệu suất duyệt 30d ==============
//
// Sprint 23 (2026-05-09): wire BE thật từ approvalStatsProvider.
// Endpoint: GET /api/reports/approval-stats?days=30

class _BCNApprovalDonut extends ConsumerWidget {
  final List<dynamic> pendingList;
  const _BCNApprovalDonut({required this.pendingList});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(approvalStatsProvider);
    final stats = asyncStats.valueOrNull;
    final approved = (stats?['approved'] as int?) ?? 0;
    final revision = (stats?['revision_requested'] as int?) ?? 0;
    final reject = (stats?['rejected'] as int?) ?? 0;
    final total = approved + revision + reject;
    final avgHours = stats?['avg_processing_hours'] as num?;
    final avgStr = avgHours == null
        ? '—'
        : (avgHours < 1
            ? '< 1h'
            : '${avgHours.toStringAsFixed(1)}h');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hiệu suất duyệt (30d)',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.2,
              )),
          const SizedBox(height: AppSpacing.s16),
          Row(children: [
            // Donut chart
            SizedBox(
              width: 110,
              height: 110,
              child: CustomPaint(
                painter: _DonutPainter(
                  segments: [
                    (value: approved, color: context.successGreen),
                    (value: revision, color: context.warnOrange),
                    (value: reject, color: ptitRed),
                  ],
                  ringWidth: 14,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$total',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: context.textPrimary,
                            height: 1,
                            letterSpacing: -0.6,
                          )),
                      const SizedBox(height: 2),
                      Text('ĐÃ DUYỆT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: context.textMuted,
                            letterSpacing: 1.2,
                          )),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DonutLegend(
                      color: context.successGreen,
                      label: 'Approved',
                      value: '$approved'),
                  const SizedBox(height: 6),
                  _DonutLegend(
                      color: context.warnOrange,
                      label: 'Yêu cầu sửa',
                      value: '$revision'),
                  const SizedBox(height: 6),
                  _DonutLegend(
                      color: ptitRed, label: 'Reject', value: '$reject'),
                ],
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.s12),
          Text('TB thời gian xử lý: $avgStr',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.textMuted,
              )),
        ],
      ),
    );
  }
}

class _DonutLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _DonutLegend(
      {required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: AppSpacing.s8),
      Expanded(
        child: Text(label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.textPrimary,
            )),
      ),
      Text(value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.2,
          )),
    ]);
  }
}

class _DonutPainter extends CustomPainter {
  final List<({int value, Color color})> segments;
  final double ringWidth;
  const _DonutPainter({required this.segments, required this.ringWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (s, e) => s + e.value);
    if (total <= 0) return;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide / 2) - ringWidth / 2;

    var startAngle = -3.14159 / 2; // 12 o'clock start
    final gap = 0.025; // small gap between segments
    for (final seg in segments) {
      final sweep = (seg.value / total) * (2 * 3.14159) - gap;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle + gap / 2,
        sweep,
        false,
        paint,
      );
      startAngle += sweep + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.ringWidth != ringWidth;
}

// ============== Cảnh báo card ==============

class _BCNAlertsCard extends StatelessWidget {
  final List<dynamic> pendingList;
  const _BCNAlertsCard({required this.pendingList});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final urgent = pendingList.where((ap) {
      final submitted = DateTime.tryParse(ap['submitted_at'] ?? '');
      if (submitted == null) return false;
      final deadline =
          submitted.add(const Duration(hours: _kBCNApprovalSlaHours));
      return deadline.difference(now).inHours <= 24;
    }).length;

    final alerts = <_BCNAlert>[
      if (urgent > 0)
        _BCNAlert(
          icon: Icons.access_time_outlined,
          color: context.warnOrange,
          bgColor: context.warnSoft,
          text: '$urgent đề xuất sắp hết SLA 24h',
        ),
      _BCNAlert(
        icon: Icons.description_outlined,
        color: context.infoBlue,
        bgColor: context.infoSoft,
        text: 'Báo cáo BGH tháng 5 đến hạn 10/05',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cảnh báo',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.2,
              )),
          const SizedBox(height: AppSpacing.s12),
          ...alerts.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
                  decoration: BoxDecoration(
                    color: a.bgColor,
                    borderRadius: BorderRadius.circular(AppRadius.tight),
                  ),
                  child: Row(children: [
                    Icon(a.icon, size: 14, color: a.color),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(a.text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: a.color,
                          )),
                    ),
                  ]),
                ),
              )),
        ],
      ),
    );
  }
}

class _BCNAlert {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String text;
  const _BCNAlert({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.text,
  });
}

