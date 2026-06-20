part of 'contest_admin_detail_screen.dart';

// ---------- Helpers ----------

String _msgOf(Object e) => FriendlyError.of(e);

/// Sprint 12 fix (2026-05-08): parse số từ JSON value bất kỳ (num hoặc string).
/// BE Pydantic serialize Decimal thành string mặc định (vd "8.8000000000000000")
/// nên phía FE phải tryParse trước khi format. Trả null nếu không parse được.
num? _parseNum(dynamic v) {
  if (v == null) return null;
  if (v is num) return v;
  if (v is String) {
    return num.tryParse(v.trim());
  }
  return null;
}

String _safeFmtIso(dynamic iso) {
  if (iso == null) return '—';
  try {
    return DateFormat('dd/MM/yy HH:mm').format(DateTime.parse(iso as String).toLocal());
  } catch (_) {
    return '—';
  }
}

/// Sprint 12 (2026-05-08): contest stats card real-time (GV-07).
/// 6 stat: entries Approved/Pending/Rejected · submissions · rounds progress · avg score.
class _ContestStatsCard extends ConsumerWidget {
  final int contestId;
  const _ContestStatsCard({required this.contestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStats = ref.watch(contestStatsProvider(contestId));
    return MCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.insights_outlined,
              size: 16, color: context.textPrimary),
          const SizedBox(width: 6),
          const Text('Tiến độ cuộc thi (real-time)',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        asyncStats.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: context.textMuted),
            ),
          ),
          error: (_, __) => Text('—',
              style: TextStyle(fontSize: 12, color: context.textFaint)),
          data: (s) {
            if (s == null) {
              return Text('Chưa có dữ liệu thống kê',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: context.textMuted,
                      fontStyle: FontStyle.italic));
            }
            final approved = s['approved_entries'] ?? 0;
            final pending = s['pending_entries'] ?? 0;
            final total = s['total_entries'] ?? 0;
            final submissions = s['total_submissions'] ?? 0;
            final submitted = s['submitted_count'] ?? 0;
            final roundsTotal = s['rounds_count'] ?? 0;
            final roundsDone = s['rounds_with_results'] ?? 0;
            // Sprint 12 fix (2026-05-08): BE serialize Decimal thành string
            // (Pydantic default), nên check num KHÔNG đủ — dùng helper _parseNum.
            final avgScore = _parseNum(s['average_final_score']);
            final passRate = _parseNum(s['pass_rate_percent']);
            final avgScoreStr =
                avgScore != null ? avgScore.toStringAsFixed(2) : '—';
            final passRateStr =
                passRate != null ? '${passRate.toStringAsFixed(0)}%' : '—';
            return Wrap(spacing: 0, runSpacing: 12, children: [
              SizedBox(
                width: 180,
                child: _StatBlock(
                  label: 'Đăng ký',
                  value: '$approved / $total',
                  hint: 'Đã duyệt / Tổng',
                  color: context.successGreen,
                ),
              ),
              SizedBox(
                width: 140,
                child: _StatBlock(
                  label: 'Chờ duyệt',
                  value: '$pending',
                  hint: 'PENDING',
                  color: context.warnOrange,
                ),
              ),
              SizedBox(
                width: 180,
                child: _StatBlock(
                  label: 'Bài nộp',
                  value: '$submitted / $submissions',
                  hint: 'Đúng hạn / Tổng',
                  color: context.infoBlue,
                ),
              ),
              SizedBox(
                width: 160,
                child: _StatBlock(
                  label: 'Vòng',
                  value: '$roundsDone / $roundsTotal',
                  hint: 'Đã chấm xong',
                ),
              ),
              SizedBox(
                width: 140,
                child: _StatBlock(
                  label: 'Điểm TB',
                  value: avgScoreStr,
                  hint: 'final_score',
                ),
              ),
              SizedBox(
                width: 140,
                child: _StatBlock(
                  label: 'Tỷ lệ pass',
                  value: passRateStr,
                  hint: 'top 50%',
                  color: context.achievementGold,
                ),
              ),
            ]);
          },
        ),
      ]),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final Color? color;
  const _StatBlock({
    required this.label,
    required this.value,
    this.hint,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10.5,
                color: context.textMuted,
                letterSpacing: 0.5)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color ?? context.textPrimary,
            )),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!,
              style: TextStyle(fontSize: 10, color: context.textFaint)),
        ],
      ],
    );
  }
}

/// Sprint 9 Group 3 (2026-05-07): reviews summary card cho _OverviewTab.
/// Hiển thị 4 stat: total / avg rating / visible / hidden.
class _ReviewsSummaryCard extends ConsumerWidget {
  final int contestId;
  const _ReviewsSummaryCard({required this.contestId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSummary = ref.watch(contestReviewsSummaryProvider(contestId));
    return MCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.rate_review_outlined,
              size: 16, color: context.textPrimary),
          const SizedBox(width: 6),
          const Text('Reviews từ SV',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        asyncSummary.when(
          loading: () => Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: context.textMuted),
            ),
          ),
          error: (e, _) => Text('—',
              style: TextStyle(fontSize: 12, color: context.textFaint)),
          data: (s) {
            if (s == null) {
              return Text('Chưa có review nào',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: context.textMuted,
                      fontStyle: FontStyle.italic));
            }
            // Sprint 12 fix #2 (2026-05-08): BE schema actual là `average_rating`
            // + `distribution` map (1-5 → count). KHÔNG có visible/hidden_count.
            // Hiển thị thay = top 5★ count + ≥4★ count để admin biết tỷ lệ tích cực.
            final total = s['total'] ?? 0;
            final avgNum = _parseNum(s['average_rating']);
            final avgStr = avgNum != null ? avgNum.toStringAsFixed(1) : '—';
            final dist = (s['distribution'] as Map?) ?? {};
            final five = (dist['5'] as num?)?.toInt() ?? 0;
            final four = (dist['4'] as num?)?.toInt() ?? 0;
            final positive = five + four; // ≥4★ count
            return Row(children: [
              _ReviewStat(label: 'Tổng', value: '$total'),
              _ReviewStat(
                label: 'Sao TB',
                value: avgStr,
                color: context.achievementGold,
              ),
              _ReviewStat(
                label: '5 sao',
                value: '$five',
                color: context.achievementGold,
              ),
              _ReviewStat(
                label: '≥4 sao',
                value: '$positive',
                color: context.successGreen,
              ),
            ]);
          },
        ),
      ]),
    );
  }
}

class _ReviewStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _ReviewStat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10.5,
                  color: context.textMuted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 3),
          Text(value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color ?? context.textPrimary,
              )),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final String msg;
  const _Empty(this.msg);
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inbox_outlined, size: 48, color: context.textMuted),
            const SizedBox(height: 10),
            Text(msg,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted, fontSize: 13)),
          ]),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onBack;
  const _ErrorView({required this.error, required this.onBack});
  @override
  Widget build(BuildContext context) {
    final msg = FriendlyError.of(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: ptitRed),
          const SizedBox(height: 12),
          Text(msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, fontSize: 12)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onBack, child: const Text('Quay lại')),
        ]),
      ),
    );
  }
}
