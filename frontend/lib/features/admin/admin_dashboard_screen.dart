import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/errors/friendly_error.dart';
import '../../core/models/contest.dart';
import '../../core/spacing.dart';
import '../../core/theme.dart';
import '../../core/widgets/help_button.dart';
import '../../core/widgets/m_card.dart';
import '../../core/xlsx_export_helper.dart';
import 'admin_contests_screen.dart' show adminContestsProvider;
import 'approval_queue_screen.dart' show pendingApprovalsProvider;
import 'create_contest_dialog.dart';

part 'admin_dashboard_admin.dart';
part 'admin_dashboard_btc.dart';
part 'admin_dashboard_bcn.dart';

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

