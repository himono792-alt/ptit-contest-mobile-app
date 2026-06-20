import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/models/contest_detail.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/m_shimmer.dart';
import '../../core/widgets/m_top_bar.dart';
import '../../core/widgets/pill.dart';
import 'review_dialog.dart';

final contestDetailProvider =
    FutureProvider.autoDispose.family<ContestDetail, String>((ref, slug) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$slug');
  return ContestDetail.fromJson(res.data);
});

class ContestDetailScreen extends ConsumerWidget {
  final String slug;
  const ContestDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(contestDetailProvider(slug));
    return Scaffold(
      appBar: MTopBar(
        title: 'Chi tiết',
        leading: IconButton(
          // Sprint 3 a11y fix (2026-05-07): tooltip làm accessible name.
          tooltip: 'Quay lại',
          icon: Icon(Icons.arrow_back, color: context.textMuted),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, color: context.textMuted, size: 20),
            tooltip: 'Sao chép link',
            onPressed: () async {
              final url =
                  'https://luxury-crostata-3c5c69.netlify.app/contests/$slug';
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              AppToast.info(context, 'Đã copy link: $url');
            },
          ),
        ],
      ),
      body: asyncData.when(
        // Sprint 8b (2026-05-07): skeleton thay spinner cho perceived perf SV detail.
        loading: () => const MCardListSkeleton(count: 3),
        error: (e, _) => Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Lỗi: $e',
                    style: TextStyle(color: context.textMuted)))),
        data: (c) => _buildBody(context, c),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ContestDetail c) {
    // Sprint 16 (2026-05-08): refactor sang 5 tabs theo design SVW-04 + timeline visual.
    return Stack(children: [
      DefaultTabController(
        length: 5,
        child: Column(children: [
          // ============ Hero banner: gradient + title overlay ============
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                gradient: ptitGradientHero,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                boxShadow: shadowMd,
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.emoji_events,
                            size: 13, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(_statusVi(c.status),
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                  Text(
                    c.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.45,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ============ Quick meta row ============
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 6, runSpacing: 6, children: [
              _MetaChip(
                  icon: Icons.school_outlined,
                  label: 'Khoa #${c.hostFacultyId ?? "?"}'),
              _MetaChip(
                  icon: c.participationMode == 'TEAM'
                      ? Icons.groups_outlined
                      : Icons.person_outline,
                  label: c.participationMode == 'TEAM' ? 'Đội' : 'Cá nhân'),
              _MetaChip(
                  icon: c.deliveryMode == 'ONLINE'
                      ? Icons.cloud_outlined
                      : (c.deliveryMode == 'OFFLINE'
                          ? Icons.location_on_outlined
                          : Icons.sync_alt),
                  label: _modeLabel(c.deliveryMode)),
              if (c.locationText != null && c.locationText!.isNotEmpty)
                _MetaChip(icon: Icons.place_outlined, label: c.locationText!),
            ]),
          ),
          const SizedBox(height: 12),

          // ============ TabBar (Sprint 16 S16-3) ============
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: context.cardBorder)),
            ),
            child: TabBar(
              isScrollable: true,
              labelColor: ptitRed,
              unselectedLabelColor: context.textMuted,
              indicatorColor: ptitRed,
              tabAlignment: TabAlignment.start,
              labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Lịch trình'),
                Tab(text: 'Thể lệ'),
                Tab(text: 'Giải thưởng'),
                Tab(text: 'Tài trợ'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(children: [
              _overviewTab(context, c),
              _scheduleTab(context, c),
              _rulesTab(context, c),
              _awardsTab(context, c),
              _sponsorsTab(context, c),
            ]),
          ),
        ]),
      ),

      // ============ Sticky bottom CTA bar ============
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: context.cardBg,
            border: Border(top: BorderSide(color: context.cardBorder)),
            boxShadow: shadowMd,
          ),
          child: SafeArea(
            top: false,
            child: c.isRegOpen
                ? Semantics(
                    label: 'Đăng ký tham gia cuộc thi',
                    button: true,
                    hint: 'Mở form đăng ký với thông tin và ghi chú',
                    child: FilledButton.icon(
                      icon: const Icon(Icons.app_registration, size: 18),
                      label: const Text('Đăng ký tham gia'),
                      onPressed: () => context.push(
                          '/contests/${c.slug}/register',
                          extra: c),
                    ),
                  )
                : Semantics(
                    label: 'Không nhận đăng ký, ${_statusVi(c.status)}',
                    button: true,
                    enabled: false,
                    child: FilledButton(
                      onPressed: null,
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEDE7DF)),
                      child: Text('Không nhận đăng ký (${_statusVi(c.status)})',
                          style: TextStyle(color: context.textMuted)),
                    ),
                  ),
          ),
        ),
      ),
    ]);
  }

  // ============ Sprint 16 (2026-05-08) — 5 tab builders ============

  Widget _overviewTab(BuildContext context, ContestDetail c) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (c.description != null) ...[
          _SectionHeader(icon: Icons.info_outline, title: 'Mô tả'),
          const SizedBox(height: 8),
          MCard(
            child: Text(c.description!,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.65,
                    color: context.textPrimary,
                    fontWeight: FontWeight.w500)),
          ),
        ] else
          _emptyTabHint(context, 'BTC chưa thêm mô tả cho cuộc thi này.'),
        if (c.isFinished) ...[
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.star_outline, size: 18),
            label: const Text('Đánh giá cuộc thi này'),
            onPressed: () => showReviewDialog(
              context,
              contestId: c.contestId,
              contestTitle: c.title,
            ),
          ),
        ],
      ],
    );
  }

  Widget _scheduleTab(BuildContext context, ContestDetail c) {
    final fmt = DateFormat('dd/MM/yyyy · HH:mm');
    final now = DateTime.now();
    // Build timeline events theo thứ tự thời gian thực tế
    final events = <_TimelineEvent>[
      if (c.registrationOpenAt != null)
        _TimelineEvent(
            icon: Icons.how_to_reg_outlined,
            title: 'Mở đăng ký',
            time: c.registrationOpenAt!),
      if (c.registrationCloseAt != null)
        _TimelineEvent(
            icon: Icons.event_busy_outlined,
            title: 'Đóng đăng ký',
            time: c.registrationCloseAt!),
      _TimelineEvent(
          icon: Icons.flag_outlined,
          title: 'Bắt đầu',
          time: c.startAt),
      _TimelineEvent(
          icon: Icons.emoji_events_outlined,
          title: 'Kết thúc',
          time: c.endAt),
    ];
    events.sort((a, b) => a.time.compareTo(b.time));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        for (var i = 0; i < events.length; i++)
          _TimelineRow(
            event: events[i],
            now: now,
            isLast: i == events.length - 1,
            fmt: fmt,
            isNext: events.where((e) => e.time.isAfter(now)).isNotEmpty &&
                events.firstWhere((e) => e.time.isAfter(now)) == events[i],
          ),
        if (c.maxEntries != null || c.isTeam) ...[
          const SizedBox(height: 16),
          MCard(
            child: Column(children: [
              if (c.maxEntries != null)
                _kvRow(context,
                    label: 'Số lượng', value: '${c.maxEntries} thí sinh'),
              if (c.maxEntries != null && c.isTeam) _Divider(),
              if (c.isTeam)
                _kvRow(context,
                    label: 'Quy mô đội',
                    value:
                        '${c.teamMinMembers}–${c.teamMaxMembers} thành viên'),
            ]),
          ),
        ],
      ],
    );
  }

  Widget _rulesTab(BuildContext context, ContestDetail c) {
    if (c.rulesText == null || c.rulesText!.isEmpty) {
      return _emptyTabFull(context,
          icon: Icons.gavel_outlined,
          message: 'BTC chưa cập nhật thể lệ cho cuộc thi này.');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        MCard(
          child: Text(c.rulesText!,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.65,
                  color: context.textPrimary,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _awardsTab(BuildContext context, ContestDetail c) {
    if (c.awardText == null || c.awardText!.isEmpty) {
      return _emptyTabFull(context,
          icon: Icons.workspace_premium_outlined,
          message: 'BTC chưa công bố giải thưởng.');
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        MCard(
          backgroundColor: context.warnSoft.withValues(alpha: 0.4),
          child: Text(c.awardText!,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  height: 1.65,
                  color: context.textPrimary,
                  fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _sponsorsTab(BuildContext context, ContestDetail c) {
    // Sprint 16: sponsors data chưa có trong ContestDetail — placeholder.
    return _emptyTabFull(context,
        icon: Icons.handshake_outlined,
        message: 'Cuộc thi này chưa có nhà tài trợ được công bố.');
  }

  Widget _emptyTabHint(BuildContext context, String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.textMuted, fontSize: 13)),
        ),
      );

  Widget _emptyTabFull(BuildContext context,
          {required IconData icon, required String message}) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: context.textMuted),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: context.textMuted, fontSize: 13)),
          ]),
        ),
      );

  String _modeLabel(String m) =>
      m == 'ONLINE' ? 'Online' : (m == 'OFFLINE' ? 'Offline' : 'Hybrid');

  String _statusVi(String s) => switch (s) {
        'DRAFT' => 'Nháp',
        'PROPOSED' => 'Chờ duyệt',
        'PUBLISHED' => 'Đã công bố',
        'REG_OPEN' => 'Đang mở ĐK',
        'REG_CLOSED' => 'Đóng đăng ký',
        'ONGOING' => 'Đang diễn ra',
        'FINISHED' => 'Đã kết thúc',
        'CANCELLED' => 'Đã hủy',
        'REVISION_REQUESTED' => 'Sửa lại',
        _ => s,
      };
}

// ===================== Reusable widgets =====================

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 16, color: ptitRed),
      const SizedBox(width: 6),
      Text(title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.textPrimary,
            letterSpacing: -0.2,
          )),
    ]);
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.cardBg,
        border: Border.all(color: context.cardBorder),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: context.textMuted),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: context.textPrimary,
                fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Divider(color: context.cardBorder, height: 16, thickness: 1);
}

Widget _kvRow(BuildContext context, {required String label, required String value, bool accent = false}) {
  return Row(children: [
    Expanded(
      child: Text(label,
          style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: context.textMuted,
              fontWeight: FontWeight.w500)),
    ),
    Text(value,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          color: accent ? ptitRed : context.textPrimary,
        )),
  ]);
}

// ============ Sprint 16 (2026-05-08) S16-2 — Timeline visual ============

class _TimelineEvent {
  final IconData icon;
  final String title;
  final DateTime time;
  _TimelineEvent({required this.icon, required this.title, required this.time});
}

class _TimelineRow extends StatelessWidget {
  final _TimelineEvent event;
  final DateTime now;
  final bool isLast;
  final bool isNext;
  final DateFormat fmt;

  const _TimelineRow({
    required this.event,
    required this.now,
    required this.isLast,
    required this.isNext,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = event.time.isBefore(now);
    final Color dotColor;
    final Color dotInner;
    if (isDone) {
      dotColor = context.successGreen;
      dotInner = Colors.white;
    } else if (isNext) {
      dotColor = ptitRed;
      dotInner = Colors.white;
    } else {
      dotColor = context.cardBorder;
      dotInner = context.appBg;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dot + connecting line column
          Column(children: [
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: dotInner, width: 3),
                boxShadow: isNext
                    ? [
                        BoxShadow(
                            color: ptitRed.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1)
                      ]
                    : null,
              ),
            ),
            if (!isLast)
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.only(top: 2),
                  color: isDone
                      ? context.successGreen.withValues(alpha: 0.4)
                      : context.cardBorder,
                ),
              ),
          ]),
          const SizedBox(width: 14),
          // Event content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: isNext ? context.ptitRedSoft : context.cardBg,
                  border: Border.all(
                      color: isNext ? ptitRed : context.cardBorder,
                      width: isNext ? 1.5 : 1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(children: [
                  Icon(event.icon,
                      size: 16,
                      color: isDone
                          ? context.successGreen
                          : (isNext ? ptitRed : context.textMuted)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title,
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isNext
                                    ? ptitRed
                                    : context.textPrimary)),
                        const SizedBox(height: 2),
                        Text(fmt.format(event.time),
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5, color: context.textMuted)),
                      ],
                    ),
                  ),
                  if (isDone)
                    Pill(
                        label: 'Đã qua',
                        color: context.successGreen,
                        bg: context.successSoft)
                  else if (isNext)
                    Pill(label: 'Sắp tới', color: Colors.white, bg: ptitRed),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
