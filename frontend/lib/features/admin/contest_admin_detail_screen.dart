// ContestAdminDetailScreen — full-screen admin drill-down quản lý 1 contest.
//
// Route: /admin/contests/:id
//
// 6 tab:
//   1. Tổng quan         — info + workflow buttons (Submit QĐ1, Open Reg, Submit QĐ2, Publish, Delete)
//   2. Vòng & Phiên       — rounds + rubric criteria
//   3. Đăng ký           — entries queue (PENDING → approve/reject)
//   4. Chấm điểm          — judge assignments per round (assign judge → entry)
//   5. Kết quả            — compute → list with award editor → submit QĐ2 → publish
//   6. Chứng nhận         — templates + issue certs

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/download_helper.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/m_card.dart';
import '../../core/widgets/pill.dart';
import '../../core/xlsx_export_helper.dart';

part 'contest_admin_detail_setup.dart';
part 'contest_admin_detail_participation.dart';
part 'contest_admin_detail_results.dart';
part 'contest_admin_detail_helpers.dart';

// ---------- Providers ----------

final contestDetailAdminProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  // GET /contests/{slug} cần slug; ta lấy slug qua list show_all then find
  final list = await api.dio.get('/contests',
      queryParameters: {'show_all': true, 'size': 200});
  final items = (list.data['items'] ?? list.data) as List<dynamic>;
  final found = items.cast<Map<String, dynamic>>().firstWhere(
        (c) => c['contest_id'] == contestId,
        orElse: () => {},
      );
  if (found.isEmpty) {
    throw DioException(
      requestOptions: RequestOptions(path: '/contests/$contestId'),
      message: 'Contest #$contestId không tồn tại hoặc không có quyền xem',
    );
  }
  // Detail by slug để có rounds + sessions
  final detail = await api.dio.get('/contests/${found['slug']}');
  return detail.data as Map<String, dynamic>;
});

final contestRoundsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$contestId/rounds');
  return res.data as List<dynamic>;
});

/// Sprint 9 Group 2 (2026-05-07): sessions list cho contest_admin_detail.
/// /api/contests/{id}/sessions trả ContestSessionOut (session_name, type, start_at,
/// end_at, location_text, room_text, online_meeting_url).
final contestSessionsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$contestId/sessions');
  return res.data as List<dynamic>;
});

final contestEntriesProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$contestId/entries');
  return res.data as List<dynamic>;
});

/// Sprint 9 Group 3 (2026-05-07): reviews summary cho 1 contest.
/// Endpoint trả total/avg_rating/visible_count/hidden_count.
final contestReviewsSummaryProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/contests/$contestId/reviews/summary');
    return res.data as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
});

/// Sprint 12 (2026-05-08): contest stats real-time (GV-07 endpoint).
/// Trả entries by status, submissions, rounds progress, avg score, review rate.
final contestStatsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/contests/$contestId/stats');
    return res.data as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
});

final roundResultsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, roundId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/rounds/$roundId/results');
    return res.data as List<dynamic>;
  } catch (_) {
    return [];
  }
});

final contestResultsProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/contests/$contestId/results');
    return res.data as List<dynamic>;
  } catch (_) {
    return [];
  }
});

final certTemplatesProvider = FutureProvider.autoDispose
    .family<List<dynamic>, int>((ref, contestId) async {
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests/$contestId/certificate-templates');
  return res.data as List<dynamic>;
});

// ---------- Screen ----------

class ContestAdminDetailScreen extends ConsumerStatefulWidget {
  final int contestId;
  const ContestAdminDetailScreen({super.key, required this.contestId});

  @override
  ConsumerState<ContestAdminDetailScreen> createState() =>
      _ContestAdminDetailScreenState();
}

class _ContestAdminDetailScreenState
    extends ConsumerState<ContestAdminDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDetail = ref.watch(contestDetailAdminProvider(widget.contestId));

    return Scaffold(
      backgroundColor: context.appBg,
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator(color: ptitRed)),
        error: (e, _) => _ErrorView(
          error: e,
          onBack: () => context.pop(),
        ),
        data: (contest) => Column(children: [
          _Header(contest: contest, onRefresh: () {
            ref.invalidate(contestDetailAdminProvider(widget.contestId));
          }),
          Container(
            color: context.cardBg,
            child: TabBar(
              controller: _tab,
              isScrollable: true,
              labelColor: ptitRed,
              unselectedLabelColor: context.textMuted,
              indicatorColor: ptitRed,
              indicatorWeight: 2.5,
              labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Tổng quan'),
                Tab(text: 'Vòng & Phiên'),
                Tab(text: 'Đăng ký'),
                Tab(text: 'Chấm điểm'),
                Tab(text: 'Kết quả'),
                Tab(text: 'Chứng nhận'),
              ],
            ),
          ),
          Divider(height: 1, color: context.cardBorder),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _OverviewTab(contestId: widget.contestId, contest: contest),
                _RoundsTab(contestId: widget.contestId),
                _EntriesTab(contestId: widget.contestId),
                _JudgingTab(contestId: widget.contestId),
                _ResultsTab(contestId: widget.contestId, contestStatus: contest['status'] as String),
                _CertsTab(contestId: widget.contestId),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ---------- Header ----------

class _Header extends StatelessWidget {
  final Map<String, dynamic> contest;
  final VoidCallback onRefresh;
  const _Header({required this.contest, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 18),
      color: context.cardBg,
      child: Row(children: [
        IconButton(
          // Sprint 3 a11y fix: tooltip cho back arrow IconButton
          tooltip: 'Quay lại',
          icon: Icon(Icons.arrow_back, size: 20, color: context.textPrimary),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('#${contest['contest_id']}',
                  style: TextStyle(fontSize: 11, color: context.textMuted)),
              const SizedBox(width: 8),
              Pill.status(contest['status'] as String),
              const SizedBox(width: 6),
              Pill(
                label: contest['delivery_mode'] ?? 'HYBRID',
                color: context.textMuted,
                bg: const Color(0xFFF3F4F6),
              ),
              const SizedBox(width: 6),
              Pill(
                label: contest['participation_mode'] ?? 'INDIVIDUAL',
                color: context.textMuted,
                bg: const Color(0xFFF3F4F6),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              contest['title'] as String,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            const SizedBox(height: 2),
            Text('Slug: ${contest['slug']}',
                style: TextStyle(fontSize: 11, color: context.textMuted)),
          ]),
        ),
        IconButton(
          tooltip: 'Làm mới',
          icon: Icon(Icons.refresh, color: context.textMuted, size: 20),
          onPressed: onRefresh,
        ),
      ]),
    );
  }
}

