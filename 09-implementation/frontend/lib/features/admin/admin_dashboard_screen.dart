import 'package:dio/dio.dart';
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
import '../../core/xlsx_export_helper.dart';
import 'admin_contests_screen.dart' show adminContestsProvider;
import 'approval_queue_screen.dart' show pendingApprovalsProvider;
import 'create_contest_dialog.dart';

// Sprint 28 hotfix #7 (2026-05-10): shared helpers cho header sinh động —
// time-aware greeting + day name VN, dùng chung cho 3 actor (GV/BCN/Admin).
({String greeting, String emoji}) _greetingByHour(int hour) {
  if (hour >= 5 && hour < 11) return (greeting: 'Chào buổi sáng', emoji: '☀️');
  if (hour >= 11 && hour < 14) return (greeting: 'Chào buổi trưa', emoji: '🌤️');
  if (hour >= 14 && hour < 18) return (greeting: 'Chào buổi chiều', emoji: '🌇');
  if (hour >= 18 && hour < 22) return (greeting: 'Chào buổi tối', emoji: '🌙');
  return (greeting: 'Khuya rồi nhé', emoji: '🌌');
}

String _dayNameVi(int weekday) {
  const names = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];
  return names[(weekday - 1).clamp(0, 6)];
}

/// Mini stat chip cho header — emoji + label bold + hint subtle.
class _DashHeaderChip extends StatelessWidget {
  final String icon;
  final String label;
  final String hint;
  const _DashHeaderChip({
    required this.icon,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.textPrimary,
            )),
        const SizedBox(width: 4),
        Text(hint,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.textMuted,
            )),
      ],
    );
  }
}

/// Background gradient subtle cho header (3 actor reuse cùng pattern).
BoxDecoration _dashHeaderGradient(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        ptitRed.withValues(alpha: isDark ? 0.10 : 0.06),
        const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.08 : 0.04),
        Colors.transparent,
      ],
      stops: const [0.0, 0.55, 1.0],
    ),
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(color: context.cardBorder.withValues(alpha: 0.4)),
  );
}

final systemSummaryProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.read(authProvider).value;
  if (user == null || !user.isAdmin) return null;
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/admin/reports/system-summary');
  return res.data as Map<String, dynamic>;
});

final myStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  // Generic dashboard data — chỉ count contests
  final api = ref.watch(apiClientProvider);
  final res = await api.dio.get('/contests', queryParameters: {'show_all': true, 'size': 1});
  return res.data as Map<String, dynamic>;
});

// Sprint 4 fix M7 (2026-05-07): BCN/HOD dashboard stats từ faculty-summary endpoint.
// 4 cards thay vì 2 → fill space 1440 + meaningful info cho BCN role.
final hodFacultyStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.read(authProvider).value;
  if (user == null || !user.isHod) return null;
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/reports/faculty-summary');
    return res.data as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
});

// Sprint 23 (2026-05-09): real-time stats providers cho BCN/BTC dashboard.

final approvalStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.read(authProvider).value;
  if (user == null || (!user.isHod && !user.isAdmin)) return null;
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio
        .get('/reports/approval-stats', queryParameters: {'days': 30});
    return res.data as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
});

final bcnDeltasProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.read(authProvider).value;
  if (user == null || (!user.isHod && !user.isAdmin)) return null;
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/reports/bcn-deltas');
    return res.data as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
});

final btcDeltasProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>((ref) async {
  final user = ref.read(authProvider).value;
  if (user == null || (!user.isOrganizer && !user.isAdmin)) return null;
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/reports/btc-deltas');
    return res.data as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
});

final activityFeedProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final user = ref.read(authProvider).value;
  if (user == null || (!user.isOrganizer && !user.isAdmin)) return [];
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio
        .get('/reports/activity-feed', queryParameters: {'limit': 10});
    return (res.data['items'] as List?) ?? [];
  } catch (_) {
    return [];
  }
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value!;
    final asyncSummary = user.isAdmin ? ref.watch(systemSummaryProvider) : null;
    final asyncCount = ref.watch(myStatsProvider);

    // Sprint 21 (2026-05-09): GV/BTC pure (organizer, không HOD/admin) →
    // render dashboard rich theo mockup mới (4 stat cards + 2-col).
    if (user.isOrganizer && !user.isHod && !user.isAdmin) {
      return _BTCDashboardRich(user: user);
    }
    // Sprint 21+ (2026-05-09): BCN/HOD pure → render dashboard rich theo mockup.
    if (user.isHod && !user.isAdmin) {
      return _BCNDashboardRich(user: user);
    }

    final isMobile = MediaQuery.of(context).size.width < 768;
    // Sprint 4 fix: bỏ nested Scaffold — AdminDashboardScreen đã nằm trong shell's Scaffold.
    // Nested Scaffold → Scaffold truyền loose constraints cho body Column → Expanded trong Row = 0px.
    // Fix: return ColoredBox + Column trực tiếp để nhận tight constraints từ shell's Expanded.
    return ColoredBox(
      color: context.appBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Sprint 28 hotfix #7 (2026-05-10): admin top bar sinh động — time-aware
        // greeting + sub-line stats từ systemSummaryProvider + gradient subtle.
        // Mobile vẫn ẩn (đã có AppBar shell), wide ≥mobile mới render.
        if (!isMobile)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _AdminTopBarRich(user: user),
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 14 : 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Stats cards row
              if (user.isAdmin && asyncSummary != null)
                asyncSummary.when(
                  loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: ptitRed))),
                  error: (e, _) => _ErrorTile(error: e),
                  data: (data) => data == null ? const SizedBox.shrink() : _AdminStatsRow(data: data),
                )
              else if (user.isHod)
                // Sprint 8 fix #4 (2026-05-07): refactor BCN/HOD dashboard
                // — flatten conditional. Trước Sprint 4 dùng Builder + nested
                // .when chain → live ko render được (vẫn loading dù API 200).
                // Bây giờ tách thành widget riêng tự manage state, fallback rõ ràng.
                _HodStatsContainer(user: user)
              else
                asyncCount.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (data) => _SimpleStatsRow(totalContests: data?['total'] ?? 0, user: user),
                ),
              const SizedBox(height: 24),
              // Welcome card với role-specific message
              MCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Chào mừng, ${user.fullName} 👋', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Roles: ${user.roles.join(", ")}', style: TextStyle(color: context.textMuted, fontSize: 13)),
                  const SizedBox(height: 12),
                  Text(
                    // Sprint 15 (2026-05-08): role-specific welcome message rõ scope.
                    user.isAdmin
                        ? 'Module Quản trị hệ thống. Bạn quản lý tài khoản, cấu hình, '
                            'audit log, backup. Không tham gia tổ chức/duyệt cuộc thi cụ thể.'
                        : user.isHod
                            ? 'Module Ban Chủ nhiệm khoa. Bạn duyệt đề xuất cuộc thi (QĐ1), '
                                'duyệt kết quả (QĐ2), giám sát tiến độ — không trực tiếp tổ chức.'
                            : user.isOrganizer
                                ? 'Module Ban Tổ chức cuộc thi. Bạn tạo cuộc thi, gửi BCN duyệt, '
                                    'mở đăng ký, chấm bài, công bố kết quả.'
                                : 'Sidebar bên trái hiển thị các module bạn có quyền truy cập theo role.',
                    style: TextStyle(fontSize: 13, color: context.textPrimary, height: 1.6),
                  ),
                ]),
              ),
              // Sprint 15 Step 4 (2026-05-08): admin-specific dashboard panels.
              if (user.isAdmin) ...[
                const SizedBox(height: 24),
                const _AdminSystemHealthCard(),
                const SizedBox(height: 12),
                const _AdminAuditTailCard(),
              ],
              // Sprint 15 Step 3: BTC-specific dashboard "Workflow tiếp theo".
              if (user.isOrganizer && !user.isAdmin) ...[
                const SizedBox(height: 24),
                const _BTCWorkflowGuideCard(),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

/// Sprint 28 hotfix #7 (2026-05-10): Admin top bar sinh động — time-aware
/// greeting + sub-line stats từ systemSummaryProvider (users/contests/khoa) +
/// gradient subtle. Replace plain top bar cũ chỉ "Dashboard" + breadcrumb.
class _AdminTopBarRich extends ConsumerWidget {
  final dynamic user;
  const _AdminTopBarRich({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final g = _greetingByHour(now.hour);
    final dayName = _dayNameVi(now.weekday);
    final dateStr = DateFormat('dd/MM/yyyy').format(now);

    // Short name 2 từ cuối cho greeting.
    final fullName = (user.fullName as String?) ?? '';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    final userName = parts.length >= 2
        ? '${parts[parts.length - 2]} ${parts.last}'
        : (parts.isNotEmpty ? parts.first : 'Admin');

    // Stats real từ systemSummaryProvider.
    final asyncSummary = ref.watch(systemSummaryProvider);
    final usersCount = asyncSummary.maybeWhen(
      data: (d) => (d?['total_users'] as int?) ?? 0,
      orElse: () => 0,
    );
    final contestsCount = asyncSummary.maybeWhen(
      data: (d) => (d?['total_contests'] as int?) ?? 0,
      orElse: () => 0,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: _dashHeaderGradient(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('QUẢN TRỊ HỆ THỐNG',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: ptitRed,
                      letterSpacing: 1.2,
                    )),
                const SizedBox(height: 4),
                Text('${g.greeting}, $userName ${g.emoji}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                      letterSpacing: -0.7,
                      height: 1.1,
                    )),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _DashHeaderChip(
                      icon: '👥',
                      label: '$usersCount tài khoản',
                      hint: 'tổng hệ thống',
                    ),
                    _DashHeaderChip(
                      icon: '🏆',
                      label: '$contestsCount cuộc thi',
                      hint: 'đã tạo',
                    ),
                    _DashHeaderChip(
                      icon: '📅',
                      label: dayName,
                      hint: dateStr,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Sprint 6 (2026-05-07): AD-05 — xuất báo cáo toàn hệ thống. Admin only.
          if (user.isAdmin)
            FilledButton.icon(
              icon: const Icon(Icons.download, size: 16),
              label: const Text('Xuất Excel'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(140, 40),
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onPressed: () => exportXlsxFromEndpoint(
                context: context,
                dio: ref.read(apiClientProvider).dio,
                path: '/admin/reports/system-summary.xlsx',
                fallbackFilename:
                    'bao-cao-he-thong-${DateTime.now().toIso8601String().substring(0, 10)}.xlsx',
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminStatsRow extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AdminStatsRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // <600px → 2 cols. 600-1100px → 2-3 cols. ≥1100px → 4 cols.
    final cols = w < 600 ? 2 : (w < 1100 ? 2 : 4);
    final aspectRatio = w < 600 ? 1.5 : 1.9;
    return GridView.count(
      crossAxisCount: cols,
      shrinkWrap: true,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: aspectRatio,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(
            label: 'Tổng users',
            value: '${data['total_users'] ?? 0}',
            delta:
                'SV ${data['students_active']} · GV ${data['organizers']} · BCN ${data['department_heads']}'),
        _StatCard(
            label: 'Tổng contests',
            value: '${data['total_contests'] ?? 0}',
            delta: '${data['contests_finished']} đã kết thúc'),
        _StatCard(
            label: 'Bài nộp',
            value: '${data['total_submissions'] ?? 0}',
            color: context.infoBlue),
        _StatCard(
            label: 'Chứng nhận đã cấp',
            value: '${data['total_certificates_issued'] ?? 0}',
            color: ptitRed),
      ],
    );
  }
}

class _SimpleStatsRow extends StatelessWidget {
  final int totalContests;
  final dynamic user;
  const _SimpleStatsRow({required this.totalContests, required this.user});
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < 600) {
      // Mobile: stack 2 cards thẳng đứng cho dễ đọc
      return Column(children: [
        _StatCard(label: 'Cuộc thi public', value: '$totalContests'),
        const SizedBox(height: 12),
        _StatCard(
            label: 'Vai trò của bạn',
            // Sprint 4 fix M8 (2026-05-07): value là role chính (vd "HOD", "ADMIN")
            // hoặc "Đa vai trò" nếu user có nhiều role. Trước đây value=count "1"
            // confusing — số "1" trông như count cuộc thi/user, không phải role.
            value: user.roles.length == 1
                ? user.roles.first.toString()
                : 'Đa vai trò',
            delta: user.roles.length > 1 ? user.roles.join(', ') : null),
      ]);
    }
    return Row(children: [
      Expanded(child: _StatCard(label: 'Cuộc thi public', value: '$totalContests')),
      const SizedBox(width: 14),
      Expanded(
          child: _StatCard(
              label: 'Vai trò của bạn',
              value: user.roles.length.toString(),
              delta: user.roles.join(", "))),
    ]);
  }
}

/// Sprint 8 fix #4 (2026-05-07): wrapper widget tự handle async lifecycle
/// cho BCN dashboard. Trước đây dùng inline Builder + nested .when bị stuck
/// loading state ở production. Giờ dùng ConsumerWidget riêng + fallback chain
/// rõ ràng: priority asyncHod.value → asyncCount.value → SizedBox.shrink.
class _HodStatsContainer extends ConsumerWidget {
  final dynamic user;
  const _HodStatsContainer({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHod = ref.watch(hodFacultyStatsProvider);
    final asyncCount = ref.watch(myStatsProvider);

    // Trường hợp tốt nhất: faculty-summary trả data → 4 cards BCN-specific.
    final hodData = asyncHod.value;
    if (hodData != null) {
      return _HodStatsRow(stats: hodData, user: user);
    }

    // Fallback: count contests + role chip — luôn render được.
    final countData = asyncCount.value;
    if (countData != null) {
      return _SimpleStatsRow(
        totalContests: (countData['total'] as int?) ?? 0,
        user: user,
      );
    }

    // Cả 2 chưa có — show skeleton-y placeholder thay vì shrink trắng.
    // (Sprint 8 fix #4: trước đây SizedBox.shrink → user nghĩ broken).
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.textMuted,
          ),
        ),
      ),
    );
  }
}

// Sprint 4 fix M7 (2026-05-07): BCN/HOD 4 stats cards thay vì 2 → fill 1440 width
// + meaningful info BCN role. Pull từ /api/reports/faculty-summary endpoint.
class _HodStatsRow extends StatelessWidget {
  final Map<String, dynamic> stats;
  final dynamic user;
  const _HodStatsRow({required this.stats, required this.user});
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final totalContests = (stats['total_contests'] as int?) ?? 0;
    final ongoing = (stats['contests_ongoing'] as int?) ?? 0;
    final pending = (stats['contests_draft_or_pending'] as int?) ?? 0;
    final cards = [
      _StatCard(
        label: 'Tổng cuộc thi',
        value: '$totalContests',
        delta: 'khoa của bạn',
      ),
      _StatCard(
        label: 'Đang diễn ra',
        value: '$ongoing',
        color: ptitRed,
      ),
      _StatCard(
        label: 'Chờ duyệt',
        value: '$pending',
        delta: 'cần BCN action',
      ),
      _StatCard(
        label: 'Vai trò của bạn',
        value: user.roles.length == 1
            ? user.roles.first.toString()
            : 'Đa vai trò',
        delta: user.roles.length > 1 ? user.roles.join(', ') : null,
      ),
    ];
    if (w < 600) {
      // Mobile: 2x2 grid stack
      return Column(children: [
        Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 10),
          Expanded(child: cards[1]),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: cards[2]),
          const SizedBox(width: 10),
          Expanded(child: cards[3]),
        ]),
      ]);
    }
    // Desktop ≥600: 4 columns horizontal
    return Row(
      children: [
        for (int i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? delta;
  final Color? color;
  const _StatCard({required this.label, required this.value, this.delta, this.color});
  @override
  Widget build(BuildContext context) => MCard(
        margin: EdgeInsets.zero,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 11, color: context.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color ?? context.textPrimary)),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Flexible(
              child: Text(delta!,
                  style: TextStyle(fontSize: 10, color: context.textMuted),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ]),
      );
}

class _ErrorTile extends StatelessWidget {
  final Object error;
  const _ErrorTile({required this.error});
  @override
  Widget build(BuildContext context) {
    final msg = error is DioException
        ? ((error as DioException).response?.data is Map ? '${(error as DioException).response?.data['detail']}' : (error as DioException).message ?? '')
        : '$error';
    return MCard(child: Text('Lỗi: $msg', style: const TextStyle(color: ptitRed)));
  }
}

// ============================================================
// Sprint 15 (2026-05-08): role-specific dashboard panels
// ============================================================

/// Admin only — System health card (mock data hiện tại, BE chưa expose).
/// Render 3 module: API gateway / Database / Mail queue với status dot.
class _AdminSystemHealthCard extends StatelessWidget {
  const _AdminSystemHealthCard();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.health_and_safety_outlined,
                size: 16, color: context.textPrimary),
            const SizedBox(width: 6),
            const Text('System health',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('cập nhật real-time',
                style: TextStyle(
                    fontSize: 10.5,
                    color: context.textFaint,
                    fontFamily: 'monospace')),
          ]),
          const SizedBox(height: 12),
          if (isMobile)
            Column(children: const [
              _HealthTile(name: 'API gateway', value: '< 500', unit: 'ms', status: 'OK'),
              SizedBox(height: 8),
              _HealthTile(name: 'Database', value: 'OK', unit: '', status: 'OK'),
              SizedBox(height: 8),
              _HealthTile(name: 'R2 storage', value: '< 1', unit: 'GB', status: 'OK'),
            ])
          else
            Row(children: const [
              Expanded(child: _HealthTile(name: 'API gateway', value: '< 500', unit: 'ms', status: 'OK')),
              SizedBox(width: 12),
              Expanded(child: _HealthTile(name: 'Database', value: 'OK', unit: '', status: 'OK')),
              SizedBox(width: 12),
              Expanded(child: _HealthTile(name: 'R2 storage', value: '< 1', unit: 'GB', status: 'OK')),
            ]),
        ],
      ),
    );
  }
}

class _HealthTile extends StatelessWidget {
  final String name;
  final String value;
  final String unit;
  final String status;
  const _HealthTile({
    required this.name,
    required this.value,
    required this.unit,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final ok = status == 'OK';
    final color = ok ? context.successGreen : context.warnOrange;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border(top: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(99)),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                name.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  color: context.textMuted,
                  fontFamily: 'monospace',
                  letterSpacing: 0.6,
                ),
              ),
            ),
            Text(status,
                style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(unit,
                    style: TextStyle(
                        fontSize: 11, color: context.textMuted)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Admin only — Audit log live tail (5 entries gần nhất).
class _AdminAuditTailCard extends ConsumerWidget {
  const _AdminAuditTailCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLogs = ref.watch(_recentAuditLogsProvider);
    return MCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.history, size: 16, color: context.textPrimary),
            const SizedBox(width: 6),
            const Text('Audit log gần nhất',
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 8),
          asyncLogs.when(
            loading: () => Padding(
              padding: const EdgeInsets.all(8),
              child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: context.textMuted)),
            ),
            error: (_, __) => Text('—',
                style:
                    TextStyle(fontSize: 12, color: context.textFaint)),
            data: (rows) {
              if (rows.isEmpty) {
                return Text('Chưa có hoạt động.',
                    style: TextStyle(
                        fontSize: 12.5,
                        color: context.textMuted,
                        fontStyle: FontStyle.italic));
              }
              return Column(
                children: rows.take(5).map<Widget>((r) {
                  final ts = r['created_at'] as String?;
                  final action = r['action_type']?.toString() ?? '?';
                  final entity = r['entity_name']?.toString() ?? '?';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(children: [
                      Text(_shortTs(ts),
                          style: TextStyle(
                              fontSize: 10.5,
                              color: context.textFaint,
                              fontFamily: 'monospace')),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _actionColor(context, action),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(action,
                            style: const TextStyle(
                                fontSize: 9.5,
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(entity,
                            style: TextStyle(
                                fontSize: 12,
                                color: context.textPrimary),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ]),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _shortTs(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }

  Color _actionColor(BuildContext context, String action) {
    final a = action.toUpperCase();
    if (a == 'POST' || a == 'CREATE') return context.successGreen;
    if (a == 'PATCH' || a == 'UPDATE') return context.infoBlue;
    if (a == 'DELETE') return ptitRed;
    return context.textMuted;
  }
}

final _recentAuditLogsProvider =
    FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final user = ref.read(authProvider).value;
  if (user == null || !user.isAdmin) return const [];
  final api = ref.watch(apiClientProvider);
  try {
    final res = await api.dio.get('/admin/audit-logs', queryParameters: {
      'page': 1,
      'size': 5,
    });
    return (res.data['items'] as List?)?.toList() ?? [];
  } catch (_) {
    return const [];
  }
});

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
                      child: AspectRatio(
                        aspectRatio: 1.55,
                        child: _BTCContestCard(contest: featured[rowIdx * 2]),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: rowIdx * 2 + 1 < featured.length
                          ? AspectRatio(
                              aspectRatio: 1.55,
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
