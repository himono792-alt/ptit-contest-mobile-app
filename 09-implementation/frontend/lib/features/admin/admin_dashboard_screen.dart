import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_card.dart';

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

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value!;
    final asyncSummary = user.isAdmin ? ref.watch(systemSummaryProvider) : null;
    final asyncCount = ref.watch(myStatsProvider);

    final isMobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(children: [
        // Top bar — ẩn user info + chỉ "Dashboard" trên mobile (đã có AppBar shell)
        if (!isMobile)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: context.cardBorder)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Trang chủ',
                          style: TextStyle(color: context.textMuted, fontSize: 11)),
                      SizedBox(height: 2),
                      Text('Dashboard',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                    ]),
              ),
              Text('${user.fullName} · ${user.roles.join(",")}',
                  style: TextStyle(color: context.textMuted, fontSize: 12)),
            ]),
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
              else if (user.isHod) ...[
                // Sprint 4 fix M7 (2026-05-07): BCN/HOD dashboard 4 cards thay vì 2.
                // Pull faculty-summary (BCN-05) + base contest count (myStats).
                Builder(builder: (_) {
                  final asyncHod = ref.watch(hodFacultyStatsProvider);
                  return asyncHod.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => asyncCount.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (d) => _SimpleStatsRow(
                          totalContests: d?['total'] ?? 0, user: user),
                    ),
                    data: (hod) => hod != null
                        ? _HodStatsRow(stats: hod, user: user)
                        : asyncCount.when(
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                            data: (d) => _SimpleStatsRow(
                                totalContests: d?['total'] ?? 0, user: user),
                          ),
                  );
                }),
              ] else
                asyncCount.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (data) => _SimpleStatsRow(totalContests: data?['total'] ?? 0, user: user),
                ),
              const SizedBox(height: 24),
              // Welcome card
              MCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Chào mừng, ${user.fullName} 👋', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Roles: ${user.roles.join(", ")}', style: TextStyle(color: context.textMuted, fontSize: 13)),
                  const SizedBox(height: 12),
                  Text(
                    'Bạn đã đăng nhập với quyền admin. Sidebar bên trái hiển thị các module bạn có quyền truy cập theo role.',
                    style: TextStyle(fontSize: 13, color: context.textPrimary, height: 1.6),
                  ),
                ]),
              ),
            ]),
          ),
        ),
      ]),
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
