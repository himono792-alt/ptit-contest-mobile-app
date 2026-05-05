import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value!;
    final asyncSummary = user.isAdmin ? ref.watch(systemSummaryProvider) : null;
    final asyncCount = ref.watch(myStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Column(children: [
        // Top bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: cardBorder)),
          ),
          child: Row(children: [
            const Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Trang chủ', style: TextStyle(color: textMuted, fontSize: 11)),
                SizedBox(height: 2),
                Text('Dashboard', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: textPrimary)),
              ]),
            ),
            Text('${user.fullName} · ${user.roles.join(",")}',
                style: const TextStyle(color: textMuted, fontSize: 12)),
          ]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Stats cards row
              if (user.isAdmin && asyncSummary != null)
                asyncSummary.when(
                  loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: ptitRed))),
                  error: (e, _) => _ErrorTile(error: e),
                  data: (data) => data == null ? const SizedBox.shrink() : _AdminStatsRow(data: data),
                )
              else
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
                  Text('Roles: ${user.roles.join(", ")}', style: const TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 12),
                  const Text(
                    'Bạn đã đăng nhập với quyền admin. Sidebar bên trái hiển thị các module bạn có quyền truy cập theo role.',
                    style: TextStyle(fontSize: 13, color: textPrimary, height: 1.6),
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
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.9,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatCard(label: 'Tổng users', value: '${data['total_users'] ?? 0}', delta: 'SV ${data['students_active']} · GV ${data['organizers']} · BCN ${data['department_heads']}'),
        _StatCard(label: 'Tổng contests', value: '${data['total_contests'] ?? 0}', delta: '${data['contests_finished']} đã kết thúc'),
        _StatCard(label: 'Bài nộp', value: '${data['total_submissions'] ?? 0}', color: infoBlue),
        _StatCard(label: 'Chứng nhận đã cấp', value: '${data['total_certificates_issued'] ?? 0}', color: ptitRed),
      ],
    );
  }
}

class _SimpleStatsRow extends StatelessWidget {
  final int totalContests;
  final dynamic user;
  const _SimpleStatsRow({required this.totalContests, required this.user});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _StatCard(label: 'Cuộc thi public', value: '$totalContests')),
        const SizedBox(width: 14),
        Expanded(child: _StatCard(label: 'Vai trò của bạn', value: user.roles.length.toString(), delta: user.roles.join(", "))),
      ]);
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
          Text(label, style: const TextStyle(fontSize: 11, color: textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: color ?? textPrimary)),
          if (delta != null) ...[
            const SizedBox(height: 4),
            Flexible(
              child: Text(delta!,
                  style: const TextStyle(fontSize: 10, color: textMuted),
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
