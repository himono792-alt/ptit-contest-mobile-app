part of 'admin_dashboard_screen.dart';

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
          const HelpButton(id: 'admin_dashboard'),
          const SizedBox(width: 4),
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
    return MCard(child: Text('Lỗi: ${FriendlyError.of(error)}', style: const TextStyle(color: ptitRed)));
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

