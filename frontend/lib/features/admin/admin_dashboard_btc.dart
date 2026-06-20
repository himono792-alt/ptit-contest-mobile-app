part of 'admin_dashboard_screen.dart';

/// BTC only — workflow guide card hiển thị 4 step workflow.
class _BTCWorkflowGuideCard extends StatelessWidget {
  const _BTCWorkflowGuideCard();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('1', 'Tạo cuộc thi', 'Sidebar → Cuộc thi → Tạo cuộc thi → điền thông tin → Lưu nháp'),
      ('2', 'Submit BCN duyệt (QĐ1)', 'Trong contest detail → tab Tổng quan → Submit QĐ1'),
      ('3', 'Mở đăng ký + Chấm bài', 'BCN duyệt OK → trạng thái REG_OPEN → SV đăng ký → Chấm bài'),
      ('4', 'Submit kết quả (QĐ2) + Cấp cert', 'Compute results → Submit QĐ2 → Activate cert template → Cấp cert'),
    ];
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.checklist_outlined,
                size: 16, color: context.textPrimary),
            const SizedBox(width: 6),
            const Text('Workflow tiếp theo (BTC)',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          ...steps.map((s) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.ptitRedSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(s.$1,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: ptitRed)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$2,
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimary)),
                          const SizedBox(height: 2),
                          Text(s.$3,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.textMuted,
                                  height: 1.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ============== Sprint 21: GV/BTC Dashboard Rich ==============

class _BTCDashboardRich extends ConsumerWidget {
  final dynamic user;
  const _BTCDashboardRich({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(adminContestsProvider);
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 1200;
    final today = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(today);
    final weekNo = _isoWeekNumber(today);

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
          _BTCHeader(
            userName: _shortName(user.fullName),
            dateStr: dateStr,
            weekNo: weekNo,
            isCompact: isCompact,
          ),
          const SizedBox(height: AppSpacing.s24),
          asyncList.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(
                  child: CircularProgressIndicator(
                      color: ptitRed, strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.s24),
              child: Text('Không tải được dữ liệu: $e',
                  style: TextStyle(color: context.textMuted, fontSize: 13)),
            ),
            data: (data) {
              final items = data.items;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BTCStatRow(items: items, isCompact: isCompact),
                  const SizedBox(height: AppSpacing.s24),
                  if (isCompact) ...[
                    _BTCMyContests(items: items),
                    const SizedBox(height: AppSpacing.s24),
                    _BTCUpcomingEvents(items: items),
                    const SizedBox(height: AppSpacing.s24),
                    const _BTCActivityFeed(),
                  ] else ...[
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 7, child: _BTCMyContests(items: items)),
                          const SizedBox(width: AppSpacing.s24),
                          Expanded(
                              flex: 4,
                              child: _BTCUpcomingEvents(items: items)),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s24),
                    const _BTCActivityFeed(),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _shortName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[parts.length - 2]} ${parts.last}';
    }
    return parts.first;
  }

  int _isoWeekNumber(DateTime date) {
    final dayOfYear = int.parse(DateFormat('D').format(date));
    final woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) return _isoWeekNumber(DateTime(date.year - 1, 12, 28));
    if (woy > 52) {
      final lastWeek = _isoWeekNumber(DateTime(date.year, 12, 28));
      if (lastWeek == 53) return 53;
      return 1;
    }
    return woy;
  }
}

/// Sprint 28 hotfix #7 (2026-05-10): GV header sinh động — time-aware greeting
/// + sub-line stats (cuộc thi đang tổ chức + bài chờ chấm + thứ/tuần) +
/// gradient subtle. Stats từ adminContestsProvider (Cuộc thi của tôi).
class _BTCHeader extends ConsumerWidget {
  final String userName;
  final String dateStr;
  final int weekNo;
  final bool isCompact;

  const _BTCHeader({
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

    final asyncContests = ref.watch(adminContestsProvider);
    final activeCount = asyncContests.maybeWhen(
      data: (resp) => resp.items.where((c) {
        return c.status == 'REG_OPEN' ||
            c.status == 'REG_CLOSED' ||
            c.status == 'ONGOING';
      }).length,
      orElse: () => 0,
    );
    final draftCount = asyncContests.maybeWhen(
      data: (resp) => resp.items
          .where((c) => c.status == 'DRAFT' || c.status == 'PROPOSED')
          .length,
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
                Text('GV / BTC',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: ptitRed,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: AppSpacing.s4),
                Text('${g.greeting}, $userName ${g.emoji}',
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
                      icon: '🎯',
                      label: '$activeCount cuộc thi',
                      hint: 'đang tổ chức',
                    ),
                    _DashHeaderChip(
                      icon: '📝',
                      label: '$draftCount bản nháp',
                      hint: draftCount > 0 ? 'chờ submit' : 'đã clear',
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
          const HelpButton(id: 'gv_dashboard'),
          const SizedBox(width: AppSpacing.s4),
          _CreateContestButton(),
        ],
      ),
    );
  }
}

class _CreateContestButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () async {
          final created = await showCreateContestDialog(context);
          if (created == true) {
            ref.invalidate(adminContestsProvider);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE63946), Color(0xFFFF6B7E)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x33E63946),
                  blurRadius: 10,
                  offset: Offset(0, 3)),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.add, size: 16, color: Colors.white),
            const SizedBox(width: AppSpacing.s4),
            Text('Tạo cuộc thi',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
          ]),
        ),
      ),
    );
  }
}

class _BTCStatRow extends ConsumerWidget {
  final List<ContestSummary> items;
  final bool isCompact;
  const _BTCStatRow({required this.items, required this.isCompact});

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
    final asyncDeltas = ref.watch(btcDeltasProvider);
    final deltas = asyncDeltas.valueOrNull;

    final ongoingFromList = items
        .where((c) => c.status == 'ONGOING' || c.status == 'REG_OPEN')
        .length;
    final pendingRegFromList = items
        .where((c) => c.status == 'REG_OPEN')
        .fold<int>(0, (sum, c) => sum + c.entriesCount);

    // Ưu tiên BE deltas, fallback derive từ items khi chưa có.
    final ongoing =
        (deltas?['contests_ongoing'] as int?) ?? ongoingFromList;
    final pendingJudge =
        (deltas?['submissions_pending_judge'] as int?) ?? 0;
    final judged24h = (deltas?['submissions_judged_24h'] as int?) ?? 0;
    final pendingReg =
        (deltas?['registrations_pending'] as int?) ?? pendingRegFromList;
    final regDelta24h =
        (deltas?['registrations_pending_delta_24h'] as int?) ?? 0;
    final totalStudents = (deltas?['students_total'] as int?) ??
        items.fold<int>(0, (sum, c) => sum + c.entriesCount);
    final ongoingDelta7d =
        (deltas?['contests_ongoing_delta_7d'] as int?) ?? 0;

    final ongoingTrend = _formatDelta(context, ongoingDelta7d, 'tuần này');
    final regTrend = _formatDelta(context, regDelta24h, 'trong 24h');

    final cards = <Widget>[
      _StatCardRich(
        label: 'CT ĐANG DIỄN RA',
        value: '$ongoing',
        trend: ongoing == 0 ? '— ổn định' : ongoingTrend.text,
        trendColor:
            ongoing == 0 ? context.textMuted : ongoingTrend.color,
        progressColor: context.successGreen,
        progress: (ongoing / 10).clamp(0.0, 1.0),
      ),
      _StatCardRich(
        label: 'BÀI CHỜ CHẤM',
        value: '$pendingJudge',
        trend: judged24h > 0
            ? '▼ $judged24h đã chấm hôm qua'
            : pendingJudge > 0
                ? '— chờ xử lý'
                : '— chưa có bài',
        trendColor: judged24h > 0
            ? context.successGreen
            : (pendingJudge > 0 ? ptitRed : context.textMuted),
        progressColor: ptitRed,
        progress: (pendingJudge / 20).clamp(0.0, 1.0),
      ),
      _StatCardRich(
        label: 'ĐĂNG KÝ PENDING',
        value: '$pendingReg',
        trend: pendingReg == 0 ? '— ổn định' : regTrend.text,
        trendColor:
            pendingReg == 0 ? context.textMuted : regTrend.color,
        progressColor: context.warnOrange,
        progress: (pendingReg / 100).clamp(0.0, 1.0),
      ),
      _StatCardRich(
        label: 'SINH VIÊN THAM GIA',
        value: '$totalStudents',
        trend: '— ổn định',
        trendColor: context.textMuted,
        progressColor: context.infoBlue,
        progress: (totalStudents / 500).clamp(0.0, 1.0),
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

class _StatCardRich extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final Color trendColor;
  final Color progressColor;
  final double progress;

  const _StatCardRich({
    required this.label,
    required this.value,
    required this.trend,
    required this.trendColor,
    required this.progressColor,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: context.textMuted,
                letterSpacing: 1.1,
              )),
          const SizedBox(height: AppSpacing.s12),
          Text(value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.9,
                height: 1,
              )),
          const SizedBox(height: AppSpacing.s8),
          Text(trend,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: trendColor,
              )),
          const SizedBox(height: AppSpacing.s8),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.tight),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 3,
              backgroundColor: progressColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(progressColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chiều cao cố định cho card "Cuộc thi của tôi". Trước dùng AspectRatio 1.55
/// nên card phình cao khi cột rộng ra (màn to) → đẩy "Hoạt động gần đây" xuống.
/// Height cố định giữ card gọn, mọi thứ nằm trong 1 màn hình.
const double _kContestCardHeight = 172;

class _BTCMyContests extends ConsumerWidget {
  final List<ContestSummary> items;
  const _BTCMyContests({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sorted = [...items]
      ..sort((a, b) {
        int score(String s) => switch (s) {
              'REG_OPEN' => 0,
              'ONGOING' => 1,
              'REG_CLOSED' => 2,
              'DRAFT' => 3,
              'PUBLISHED' => 4,
              _ => 9,
            };
        return score(a.status).compareTo(score(b.status));
      });
    final featured = sorted.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BTCSectionHead(
          title: 'Cuộc thi của tôi',
          actionLabel: 'Xem tất cả',
          onAction: () => context.go('/admin/contests'),
        ),
        const SizedBox(height: AppSpacing.s12),
        if (featured.isEmpty)
          _emptyCard(context)
        else
          // Sprint 23 fix (2026-05-09): GridView shrinkWrap + IntrinsicHeight
          // bug height-overflow → Activity feed đè contest row 2.
          // Chuyển sang Column với 2 hàng Row, mỗi card AspectRatio cố định.
          Column(
            children: [
              for (var rowIdx = 0; rowIdx < (featured.length / 2).ceil(); rowIdx++) ...[
                if (rowIdx > 0) const SizedBox(height: AppSpacing.s12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: _kContestCardHeight,
                        child: _BTCContestCard(contest: featured[rowIdx * 2]),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: rowIdx * 2 + 1 < featured.length
                          ? SizedBox(
                              height: _kContestCardHeight,
                              child: _BTCContestCard(
                                  contest: featured[rowIdx * 2 + 1]),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ],
          ),
      ],
    );
  }

  Widget _emptyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Text('Chưa có cuộc thi nào',
            style: TextStyle(color: context.textMuted, fontSize: 13)),
      ),
    );
  }
}

class _BTCContestCard extends StatelessWidget {
  final ContestSummary contest;
  const _BTCContestCard({required this.contest});

  ({String label, Color color, Color bgSoft}) _statusMeta(BuildContext context) {
    switch (contest.status) {
      case 'ONGOING':
        return (
          label: 'ONGOING',
          color: context.successGreen,
          bgSoft: context.successSoft
        );
      case 'REG_CLOSED':
        return (
          label: 'JUDGING',
          color: context.infoBlue,
          bgSoft: context.infoSoft
        );
      case 'REG_OPEN':
        return (
          label: 'REG OPEN',
          color: ptitRed,
          bgSoft: context.ptitRedSoft,
        );
      case 'DRAFT':
        return (
          label: 'DRAFT',
          color: context.warnOrange,
          bgSoft: context.warnSoft,
        );
      case 'PUBLISHED':
        return (
          label: 'PUBLISHED',
          color: context.infoBlue,
          bgSoft: context.infoSoft
        );
      case 'FINISHED':
        return (
          label: 'FINISHED',
          color: context.textMuted,
          bgSoft: context.cardBorder.withValues(alpha: 0.4),
        );
      default:
        return (
          label: contest.status,
          color: context.textMuted,
          bgSoft: context.cardBorder.withValues(alpha: 0.4),
        );
    }
  }

  double _calcProgress() {
    switch (contest.status) {
      case 'DRAFT':
        return 0.15;
      case 'PUBLISHED':
        return 0.25;
      case 'REG_OPEN':
        return 0.4;
      case 'REG_CLOSED':
        return 0.7;
      case 'ONGOING':
        return 0.85;
      case 'FINISHED':
        return 1.0;
      default:
        return 0.0;
    }
  }

  String _shortCode() {
    final base = contest.slug.replaceAll('-', '').toUpperCase();
    return '#${base.substring(0, base.length > 9 ? 9 : base.length)}';
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM');
    final meta = _statusMeta(context);
    final pct = _calcProgress();
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => context.go('/admin/contests'),
      child: Container(
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
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8, vertical: 2),
                decoration: BoxDecoration(
                  color: meta.bgSoft,
                  borderRadius: BorderRadius.circular(AppRadius.tight),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: meta.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s4),
                  Text(meta.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: meta.color,
                        letterSpacing: 0.6,
                      )),
                ]),
              ),
              const Spacer(),
              Text(_shortCode(),
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: context.textMuted,
                  )),
            ]),
            const SizedBox(height: AppSpacing.s8),
            Text(contest.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.3,
                  height: 1.25,
                )),
            const SizedBox(height: AppSpacing.s4),
            Text(
                'Vòng loại · ${fmt.format(contest.startAt)} → ${fmt.format(contest.endAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.textMuted,
                )),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.tight),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 4,
                backgroundColor: context.cardBorder.withValues(alpha: 0.4),
                valueColor: AlwaysStoppedAnimation(meta.color),
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Row(children: [
              _InfoChunk(
                  label: 'SV',
                  value: '${contest.entriesCount}',
                  color: context.textPrimary),
              const SizedBox(width: AppSpacing.s12),
              _InfoChunk(
                  label: 'tiến độ',
                  value: '${(pct * 100).round()}%',
                  color: ptitRed),
            ]),
          ],
        ),
      ),
    );
  }
}

class _InfoChunk extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _InfoChunk(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.2,
          )),
      const SizedBox(width: 3),
      Text(label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w500,
            color: context.textMuted,
          )),
    ]);
  }
}

class _BTCUpcomingEvents extends ConsumerWidget {
  final List<ContestSummary> items;
  const _BTCUpcomingEvents({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final upcoming = items
        .where((c) =>
            c.startAt.isAfter(now) ||
            (c.registrationCloseAt != null &&
                c.registrationCloseAt!.isAfter(now)) ||
            c.status == 'REG_OPEN' ||
            c.status == 'PUBLISHED' ||
            c.status == 'ONGOING')
        .toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
    final list = upcoming.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BTCSectionHead(title: 'Lịch sắp tới'),
        const SizedBox(height: AppSpacing.s12),
        if (list.isEmpty)
          _emptyCard(context)
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: context.cardBg,
              border: Border.all(color: context.cardBorder),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: list
                  .asMap()
                  .entries
                  .map((entry) => Padding(
                        padding: EdgeInsets.only(
                            bottom: entry.key < list.length - 1
                                ? AppSpacing.s12
                                : 0),
                        child: _BTCEventItem(contest: entry.value),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _emptyCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Text('Chưa có sự kiện sắp tới',
            style: TextStyle(color: context.textMuted, fontSize: 12)),
      ),
    );
  }
}

class _BTCEventItem extends StatelessWidget {
  final ContestSummary contest;
  const _BTCEventItem({required this.contest});

  @override
  Widget build(BuildContext context) {
    final dayStr = DateFormat('dd/MM').format(contest.startAt);
    final timeStr = DateFormat('HH:mm').format(contest.startAt);
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: context.ptitRedSoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(children: [
          Text(dayStr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: ptitRed,
                height: 1,
                letterSpacing: -0.3,
              )),
          const SizedBox(height: 2),
          Text(timeStr,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: ptitRed,
                letterSpacing: 0.4,
              )),
        ]),
      ),
      const SizedBox(width: AppSpacing.s12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contest.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                  letterSpacing: -0.2,
                  height: 1.3,
                )),
            const SizedBox(height: 2),
            Text(
                '${contest.deliveryMode == "ONLINE" ? "Online" : contest.deliveryMode == "OFFLINE" ? "Offline" : "Hybrid"} · ${contest.entriesCount} thí sinh',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.textMuted,
                )),
          ],
        ),
      ),
    ]);
  }
}

class _BTCSectionHead extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _BTCSectionHead({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Text(title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: context.textPrimary,
            )),
      ),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8, vertical: 0),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
          child: Text(actionLabel!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: ptitRed,
              )),
        ),
    ]);
  }
}

// ============== Sprint 23: GV Activity Feed ==============
//
// Mockup BTC dashboard "Hoạt động gần đây" — terminal-style mono log với
// icons ✓ ▶ ! cho approve / submit / reject.
// Data: activityFeedProvider → /api/reports/activity-feed?limit=10

class _BTCActivityFeed extends ConsumerWidget {
  const _BTCActivityFeed();

  ({String icon, Color color}) _actionMeta(BuildContext context, String action) {
    switch (action) {
      case 'approve_q1':
      case 'approve_q2':
        return (icon: '✓', color: context.successGreen);
      case 'submit_proposal':
        return (icon: '▶', color: context.infoBlue);
      case 'request_revision':
        return (icon: '!', color: context.warnOrange);
      case 'reject':
        return (icon: '✗', color: ptitRed);
      case 'register':
        return (icon: '+', color: context.successGreen);
      case 'submit_work':
        return (icon: '↑', color: context.infoBlue);
      case 'judge_locked':
        return (icon: '★', color: context.warnOrange);
      default:
        return (icon: '·', color: context.textMuted);
    }
  }

  String _actionText(String action) {
    switch (action) {
      case 'approve_q1':
        return 'BCN duyệt QĐ1';
      case 'approve_q2':
        return 'BCN duyệt QĐ2';
      case 'submit_proposal':
        return 'GV submit đề xuất';
      case 'request_revision':
        return 'BCN yêu cầu chỉnh sửa';
      case 'reject':
        return 'BCN từ chối';
      case 'register':
        return 'SV đăng ký';
      case 'submit_work':
        return 'SV nộp bài';
      case 'judge_locked':
        return 'GV chấm xong';
      default:
        return action;
    }
  }

  String _formatRelative(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes}m trước';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(ts.toLocal());
    if (diff.inDays < 2) return 'Hôm qua';
    if (diff.inDays < 7) return '${diff.inDays}d trước';
    return DateFormat('dd/MM').format(ts.toLocal());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(activityFeedProvider);
    final items = asyncList.valueOrNull ?? [];

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
            Icon(Icons.terminal_outlined,
                size: 16, color: context.textMuted),
            const SizedBox(width: AppSpacing.s8),
            Text('Hoạt động gần đây',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                  letterSpacing: -0.2,
                )),
          ]),
          const SizedBox(height: AppSpacing.s12),
          if (asyncList.isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s24),
              child: Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: context.textMuted))),
            )
          else if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
              child: Text('Chưa có hoạt động nào',
                  style: TextStyle(color: context.textMuted, fontSize: 12)),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: context.cardBorder.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.tight),
              ),
              child: Column(
                children: items.map<Widget>((it) {
                  final action = (it['action'] as String?) ?? '';
                  final meta = _actionMeta(context, action);
                  final ts = DateTime.tryParse(it['timestamp'] ?? '') ??
                      DateTime.now();
                  final actor = (it['actor_name'] as String?) ?? '—';
                  final contest =
                      (it['contest_title'] as String?) ?? '';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Time
                          SizedBox(
                            width: 64,
                            child: Text(_formatRelative(ts),
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: context.textMuted,
                                )),
                          ),
                          // Icon
                          SizedBox(
                            width: 18,
                            child: Text(meta.icon,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: meta.color,
                                )),
                          ),
                          Expanded(
                            child: Text.rich(
                              TextSpan(children: [
                                TextSpan(
                                    text: _actionText(action),
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: meta.color,
                                    )),
                                TextSpan(
                                    text: ' $actor ',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: context.textPrimary,
                                    )),
                                if (contest.isNotEmpty)
                                  TextSpan(
                                      text: '· $contest',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: context.textMuted,
                                      )),
                              ]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ]),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
