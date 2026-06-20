// Admin shell — responsive theo screen width:
//   - Web wide (≥1024px): sidebar 240px (UX desktop hiện có)
//   - Mobile / Tablet (<1024px hoặc APK): AppBar + Drawer (full menu) + Bottom nav 5 items chính
//
// Cùng 1 set screens, chỉ thay đổi shell layout.
//
// Sprint 2 fix C4 (2026-05-06): hạ breakpoint 768 → 1024 (Material breakpoint chuẩn).
// Lý do: ở 768px tablet, sidebar 240px chiếm 31% width → main area còn 528px quá
// chen chúc cho dropdown filter + table. Material guideline: <1024px = mobile/tablet
// dùng drawer, ≥1024px = desktop dùng sidebar.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../core/widgets/app_toast.dart';
import '../../core/widgets/m_card.dart';
import 'admin_contests_screen.dart';
import 'admin_dashboard_screen.dart';
import 'anomaly_reports_screen.dart';
import 'bcn_extra_screens.dart';
import 'gv_extra_screens.dart';
import 'approval_queue_screen.dart';
import 'admin_users_screen.dart';
import 'audit_log_screen.dart';
import 'configs_screen.dart';
import 'create_contest_dialog.dart';
import 'judge_screen.dart';
import 'master_data_screen.dart';
import 'monitor_screen.dart';
import 'review_moderation_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  /// Sprint 8 fix #2 (2026-05-07): slug deep-link như 'contests', 'users'.
  /// Khi router truyền vào, AdminShell sẽ chọn tab tương ứng lần build đầu.
  /// Null → default tab Dashboard.
  final String? initialTab;
  const AdminShell({super.key, this.initialTab});
  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _idx = 0;
  bool _initialApplied = false;

  // Sprint 28 hotfix (2026-05-09): khi GoRouter reuse cùng State instance giữa
  // /admin và /admin/<tab> (vì cùng widget type AdminShell), `_initialApplied`
  // sticky=true sau lần đầu áp dụng → các lần `context.go('/admin/contests')`
  // tiếp theo từ widget khác (vd contest card trên dashboard) không trigger
  // re-apply → URL đổi nhưng `_idx` vẫn ở tab cũ ("có lúc vào được có lúc
  // không"). Reset cờ ở didUpdateWidget khi widget.initialTab thay đổi để
  // build kế tiếp re-apply đúng tab.
  //
  // Sprint 28 hotfix #2 (2026-05-09): mở rộng cho cả case initialTab thay đổi
  // sang `null` (browser back từ /admin/contests về /admin) — fix lúc trước
  // chỉ handle non-null nên back không reset _idx về Dashboard.
  @override
  void didUpdateWidget(covariant AdminShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTab != oldWidget.initialTab) {
      _initialApplied = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Build menu based on roles (dùng chung cho cả 2 layout)
    //
    // Sprint 15 (2026-05-08) STRICT ROLE SEPARATION:
    // - GV/BTC (ORGANIZER/JUDGE) thấy Cuộc thi + Chấm bài (KHÔNG thấy admin)
    // - BCN (HOD) thấy Phê duyệt 2 lane + Giám sát (KHÔNG thấy admin)
    // - Admin (ADMIN) thấy Tài khoản + Hệ thống (KHÔNG có Cuộc thi của tôi
    //   vì admin không phải BTC). Phân quyền strict, mỗi role 1 scope.
    //
    // Trước Sprint 15: condition `||` lỏng → admin thấy toàn bộ. Sai design.
    // Mockup design Linear/Notion: AdShell / GVShell / BCNShell riêng biệt.
    final items = <_NavItem>[
      _NavItem.section('Tổng quan'),
      _NavItem('dashboard', 'Dashboard', Icons.dashboard_outlined,
          const AdminDashboardScreen()),
    ];
    // Sprint 21 (2026-05-09): GV/BTC sidebar grouped 3 nhóm theo mockup.
    // TỔNG QUAN có thêm "Lịch & deadline", CUỘC THI gộp Chấm bài + Kết quả,
    // section "BÁO CÁO" mới với Thống kê + Xuất báo cáo (placeholders).
    if (user.isOrganizer) {
      // Thêm "Lịch & deadline" vào section TỔNG QUAN.
      items.add(_NavItem('gv-calendar', 'Lịch & deadline',
          Icons.event_note_outlined, const GvCalendarDeadlineScreen()));
      items.add(_NavItem.section('Cuộc thi'));
      items.add(_NavItem('contests', 'Cuộc thi của tôi',
          Icons.emoji_events_outlined, const AdminContestsScreen()));
      items.add(_NavItem('contests-new', 'Tạo cuộc thi',
          Icons.add_circle_outline, const _NewContestQuickScreen()));
      // Chấm bài đưa lên trong nhóm CUỘC THI (mockup mockup không tách "Chấm điểm").
      // Chỉ thêm khi user là Judge — pure Organizer không Judge thì skip.
      if (user.isJudge) {
        items.add(_NavItem('judge', 'Chấm bài',
            Icons.rate_review_outlined, const JudgeScreen()));
      }
      items.add(_NavItem('gv-results', 'Kết quả',
          Icons.workspace_premium_outlined, const GvResultsScreen()));
      items.add(_NavItem.section('Báo cáo'));
      items.add(_NavItem('gv-stats', 'Thống kê',
          Icons.bar_chart_outlined, const GvStatsScreen()));
      items.add(_NavItem('gv-export', 'Xuất báo cáo',
          Icons.file_download_outlined, const GvExportReportScreen()));
    }
    // Sprint 21+ (2026-05-09): BCN sidebar grouped 3 nhóm theo mockup.
    // PHÊ DUYỆT có thêm "Mẫu chứng nhận" placeholder. THEO DÕI thêm
    // "Thống kê khoa" + "Báo cáo BGH" placeholders.
    if (user.isHod) {
      items.add(_NavItem.section('Phê duyệt'));
      // Sprint 24 (2026-05-09): badge live count cho 2 lane QĐ1/QĐ2.
      items.add(_NavItem(
        'approvals-q1',
        'Đề xuất cuộc thi',
        Icons.fact_check_outlined,
        const ApprovalQueueScreen(lockedType: 'CONTEST_PROPOSAL'),
        badgeBuilder: (ref) {
          final list = ref.watch(pendingApprovalsProvider);
          return list.maybeWhen(
              data: (d) => d
                  .where((ap) => ap['target_type'] == 'CONTEST_PROPOSAL')
                  .length,
              orElse: () => 0);
        },
      ));
      items.add(_NavItem(
        'approvals-q2',
        'Kết quả cuộc thi',
        Icons.emoji_events_outlined,
        const ApprovalQueueScreen(lockedType: 'CONTEST_RESULT'),
        badgeBuilder: (ref) {
          final list = ref.watch(pendingApprovalsProvider);
          return list.maybeWhen(
              data: (d) => d
                  .where((ap) => ap['target_type'] == 'CONTEST_RESULT')
                  .length,
              orElse: () => 0);
        },
      ));
      items.add(_NavItem('bcn-cert-templates', 'Mẫu chứng nhận',
          Icons.workspace_premium_outlined,
          const BcnCertTemplatesScreen()));
      items.add(_NavItem.section('Theo dõi'));
      items.add(_NavItem('monitor', 'Giám sát',
          Icons.visibility_outlined, const MonitorScreen()));
      items.add(_NavItem('bcn-stats', 'Thống kê khoa',
          Icons.bar_chart_outlined, const BcnFacultyStatsScreen()));
      items.add(_NavItem('bcn-report-bgh', 'Báo cáo BGH',
          Icons.description_outlined, const BcnReportBghScreen()));
    }
    // Judge scope — chỉ JUDGE thuần (không Organizer). Pure judge rất hiếm.
    // Sprint 21: nếu user là Organizer → "Chấm bài" đã thêm trong section
    // CUỘC THI ở block isOrganizer trên. Block này chỉ chạy khi judge thuần.
    if (user.isJudge && !user.isOrganizer) {
      items.add(_NavItem.section('Chấm điểm'));
      items.add(_NavItem('judge', 'Chấm bài',
          Icons.rate_review_outlined, const JudgeScreen()));
    }
    // Admin scope — STRICT chỉ ADMIN. Admin module quản trị hệ thống,
    // KHÔNG có "Cuộc thi của tôi" hay "Chấm bài" (không phải BTC/Judge).
    if (user.isAdmin) {
      items.add(_NavItem.section('Người dùng'));
      items.add(_NavItem('users', 'Tài khoản',
          Icons.people_outline, const AdminUsersScreen()));
      items.add(_NavItem('master-data', 'Khoa/Ngành/Lớp',
          Icons.school_outlined, const MasterDataScreen()));
      items.add(_NavItem.section('Hệ thống'));
      items.add(_NavItem('configs', 'Cấu hình',
          Icons.settings_outlined, const ConfigsScreen()));
      // Sprint 14 P2.1 (2026-05-08): tách Backup khỏi Configs theo mockup IA.
      items.add(_NavItem('backup', 'Backup & Restore',
          Icons.backup_outlined, const _BackupRestoreScreen()));
      items.add(_NavItem('audit-log', 'Audit log', Icons.history,
          const AuditLogScreen()));
      // Sprint 6 (2026-05-07): AD-06 anomaly reports.
      items.add(_NavItem('anomaly', 'Bất thường',
          Icons.warning_amber_outlined, const AnomalyReportsScreen()));
      items.add(_NavItem.section('Cộng đồng & Báo cáo'));
      items.add(_NavItem('reviews', 'Bình luận',
          Icons.comment_outlined, const ReviewModerationScreen()));
    }

    // Sprint 8 fix #2: lần đầu build, nếu router truyền initialTab thì align _idx.
    // Dùng cờ _initialApplied để chỉ apply 1 lần (sau đó user có thể tự switch tab
    // bằng sidebar mà không bị reset).
    //
    // Sprint 28 hotfix #2 (2026-05-09): khi initialTab=null (URL `/admin` raw,
    // vd browser back từ `/admin/contests`) → reset về tab Dashboard, không
    // giữ _idx cũ. didUpdateWidget đã reset _initialApplied ở chiều ngược lại.
    if (!_initialApplied) {
      if (widget.initialTab != null) {
        final wantedIdx =
            items.indexWhere((it) => it.slug == widget.initialTab);
        if (wantedIdx >= 0) _idx = wantedIdx;
      } else {
        // /admin raw → Dashboard mặc định.
        final dashIdx = items.indexWhere((it) => it.slug == 'dashboard');
        if (dashIdx >= 0) _idx = dashIdx;
      }
      _initialApplied = true;
    }

    // Sprint 14 (2026-05-08): nếu _idx đang trỏ vào section divider (slug==null),
    // shift sang item tiếp theo có slug. Default state _idx=0 ban đầu trỏ
    // section "Tổng quan" vì items[0] giờ là section.
    if (items[_idx.clamp(0, items.length - 1)].isSection) {
      final firstReal = items.indexWhere((it) => !it.isSection);
      if (firstReal >= 0) _idx = firstReal;
    }

    final activeIdx = _idx.clamp(0, items.length - 1);
    final activeItem = items[activeIdx];

    // Sprint 8 fix #2: callback chung — đổi tab + sync URL. context.go thay đổi
    // URL bar nhưng KHÔNG re-instantiate AdminShell (cùng builder), nhờ vậy
    // không reset state widgets khác.
    void switchTab(int i) {
      setState(() => _idx = i);
      final slug = items[i].slug;
      final target = slug == 'dashboard' ? '/admin' : '/admin/$slug';
      // Chỉ go khi URL khác để tránh push history thừa.
      if (GoRouterState.of(context).uri.path != target) {
        context.go(target);
      }
    }

    // Responsive: <1024px hoặc APK → mobile/tablet layout (drawer). Web wide ≥1024 → sidebar.
    // Sprint 2 fix C4: nâng threshold lên 1024 (Material breakpoint) để 768px tablet
    // collapse vào hamburger drawer, tránh content cramp 528px.
    final width = MediaQuery.of(context).size.width;
    final useMobileLayout = !kIsWeb || width < 1024;

    if (useMobileLayout) {
      return _MobileAdminLayout(
        items: items,
        activeIdx: activeIdx,
        // Sprint 14: activeItem.screen nullable do _NavItem.section() — đã
        // skip section khỏi activeIdx ở trên, nên ! an toàn ở đây.
        activeScreen: activeItem.screen!,
        activeLabel: activeItem.label,
        user: user,
        onSwitchTab: switchTab,
        onLogout: () => _confirmLogout(context, ref),
      );
    }

    return _WideAdminLayout(
      items: items,
      activeIdx: activeIdx,
      activeScreen: activeItem.screen!,
      user: user,
      onSwitchTab: switchTab,
      onLogout: () => _confirmLogout(context, ref),
    );
  }
}

/// Sprint 8 fix #5 (2026-05-07): admin/GV/BCN logout confirm dialog cho
/// đồng bộ với SV (profile_screen.dart). Trước đây icon logout đẩy thẳng
/// về login không hỏi → dễ misclick mất session work-in-progress.
Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Đăng xuất?'),
      content: const Text('Bạn sẽ về lại màn hình đăng nhập.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Đăng xuất'),
        ),
      ],
    ),
  );
  if (confirm == true) {
    await ref.read(authProvider.notifier).logout();
  }
}

// ============== Wide layout (desktop) — sidebar 240px ==============

/// Sprint 19 hotfix #14 (2026-05-08): Pattern B icon-only rail (VS Code/Slack/Sentry).
/// Sidebar 2 width state: expanded 240px (full text+icon) hoặc rail 64px (icon only).
/// SharedPreferences key persist trạng thái.
const String _kSidebarCollapsedKey = 'admin.sidebar_collapsed';
const double _kSidebarExpandedWidth = 240;
const double _kSidebarRailWidth = 64;
const Duration _kSidebarAnim = Duration(milliseconds: 220);

class _WideAdminLayout extends ConsumerStatefulWidget {
  final List<_NavItem> items;
  final int activeIdx;
  final Widget activeScreen;
  final dynamic user;
  final ValueChanged<int> onSwitchTab;
  final VoidCallback onLogout;

  const _WideAdminLayout({
    required this.items,
    required this.activeIdx,
    required this.activeScreen,
    required this.user,
    required this.onSwitchTab,
    required this.onLogout,
  });

  @override
  ConsumerState<_WideAdminLayout> createState() => _WideAdminLayoutState();
}

class _WideAdminLayoutState extends ConsumerState<_WideAdminLayout> {
  bool _collapsed = false;

  @override
  void initState() {
    super.initState();
    _loadCollapsedState();
  }

  Future<void> _loadCollapsedState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => _collapsed = prefs.getBool(_kSidebarCollapsedKey) ?? false);
  }

  void _toggleCollapsed() {
    setState(() => _collapsed = !_collapsed);
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_kSidebarCollapsedKey, _collapsed));
  }

  /// Sprint 19 hotfix #13 (2026-05-08): bỏ hẳn hover-peek pattern. Chỉ
  /// click-driven: click left edge (3px accent line + 32px hit zone) → mở,
  /// click chevron toggle góc phải sidebar → đóng. Loại bỏ toàn bộ race
  /// condition giữa hover ↔ click trigger. Predictable + zero oscillation.
  // Sprint 28 (2026-05-09): _showSidebar getter loại bỏ — duplicate `!_collapsed`,
  // không có ai gọi. Dùng `!_collapsed` trực tiếp.

  @override
  Widget build(BuildContext context) {
    // Sprint 7 (2026-05-07): theme toggle cho GV/BCN/Admin — trước đây chỉ SV
    // có (profile_screen). Resolve effective brightness: nếu mode = system thì
    // đọc từ MediaQuery platform brightness.
    final mode = ref.watch(themeProvider);
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);
    void onToggleTheme() {
      ref.read(themeProvider.notifier).setMode(isDark ? ThemeMode.light : ThemeMode.dark);
    }
    final items = widget.items;
    final activeIdx = widget.activeIdx;
    final user = widget.user;
    final onSwitchTab = widget.onSwitchTab;
    final onLogout = widget.onLogout;
    final activeScreen = widget.activeScreen;

    // Sprint 19 hotfix #14 (2026-05-08): Pattern B icon-only rail.
    // Sidebar có 2 state width: expanded 240 (full text+icon) hoặc rail 64
    // (icon only + tooltip). Brand/section/footer cũng adapt theo state.
    final sidebar = AnimatedContainer(
      duration: _kSidebarAnim,
      curve: Curves.easeOut,
      width: _collapsed ? _kSidebarRailWidth : _kSidebarExpandedWidth,
      decoration: const BoxDecoration(
        color: Color(0xFF1F2937),
        border: Border(right: BorderSide(color: Colors.black12)),
      ),
      child: Column(children: [
        // Brand header — logo "P" + (text PTIT Contest khi expanded) + toggle button
        Container(
          height: 64,
          padding: EdgeInsets.symmetric(
              horizontal: _collapsed ? 16 : 18, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFF374151))),
          ),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: ptitRed,
                  borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: const Center(
                child: Text('P',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ),
            ),
            if (!_collapsed) ...[
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('PTIT Contest',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      Text('Cổng quản lý',
                          style: TextStyle(
                              color: Color(0xFF9CA3AF), fontSize: 10)),
                    ]),
              ),
              // Toggle button góc phải header khi expanded
              _SidebarToggleButton(
                  collapsed: _collapsed, onTap: _toggleCollapsed),
            ],
          ]),
        ),
        // Toggle button khi collapsed — đặt riêng dưới brand cho rail layout
        if (_collapsed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: _SidebarToggleButton(
                  collapsed: _collapsed, onTap: _toggleCollapsed),
            ),
          ),
        // Nav items — full row khi expanded, icon-only centered khi collapsed
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 10),
            children: List.generate(items.length, (i) {
              final isActive = i == activeIdx;
              final item = items[i];
              if (item.isSection) {
                // Section divider — show label khi expanded, divider line khi collapsed
                if (_collapsed) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    child: Container(
                      height: 1,
                      color: const Color(0xFF374151),
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.fromLTRB(18, i == 0 ? 8 : 16, 18, 6),
                  child: Text(
                    item.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              }
              // Nav item clickable
              final navWidget = Semantics(
                label: item.label,
                button: true,
                selected: isActive,
                hint: isActive
                    ? 'Đang ở mục này'
                    : 'Chuyển sang mục ${item.label}',
                child: InkWell(
                  excludeFromSemantics: true,
                  onTap: () => onSwitchTab(i),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: _collapsed ? 0 : 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0x26C8102E) : null,
                      border: Border(
                        left: BorderSide(
                          color: isActive ? ptitRed : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: _collapsed
                        // Rail icon-only — center vertical với badge dot khi có
                        ? Stack(clipBehavior: Clip.none, children: [
                            Center(
                              child: Icon(item.icon,
                                  size: 20,
                                  color: isActive
                                      ? Colors.white
                                      : const Color(0xFFD1D5DB)),
                            ),
                            if ((item.badgeBuilder?.call(ref) ?? 0) > 0)
                              Positioned(
                                right: 14,
                                top: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: ptitRed,
                                      shape: BoxShape.circle),
                                ),
                              ),
                          ])
                        : Row(children: [
                            Icon(item.icon,
                                size: 18,
                                color: isActive
                                    ? Colors.white
                                    : const Color(0xFFD1D5DB)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(item.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isActive
                                        ? Colors.white
                                        : const Color(0xFFD1D5DB),
                                    fontWeight: isActive
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  )),
                            ),
                            // Sprint 24 (2026-05-09): badge count khi BE trả > 0
                            if ((item.badgeBuilder?.call(ref) ?? 0) > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: ptitRed,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text('${item.badgeBuilder!(ref)}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ]),
                  ),
                ),
              );
              // Wrap với Tooltip khi collapsed cho a11y + UX
              return _collapsed
                  ? Tooltip(
                      message: item.label,
                      preferBelow: false,
                      child: navWidget,
                    )
                  : navWidget;
            }),
          ),
        ),
        // Footer — avatar + (name+roles+actions khi expanded, chỉ avatar khi collapsed)
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: _collapsed ? 12 : 14, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: Color(0xFF374151))),
          ),
          child: _collapsed
              // Rail footer — chỉ avatar centered
              ? Center(
                  child: Tooltip(
                    message:
                        '${user.fullName} · ${user.roles.join(',')}',
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: context.ptitRedSoft, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          user.fullName
                              .split(' ')
                              .last
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                              color: ptitRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                )
              // Expanded footer — full layout
              : Row(children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: context.ptitRedSoft, shape: BoxShape.circle),
                    child: Center(
                      child: Text(
                        user.fullName
                            .split(' ')
                            .last
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                            color: ptitRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis),
                          Text(user.roles.join(','),
                              style: const TextStyle(
                                  color: Color(0xFF9CA3AF), fontSize: 10),
                              overflow: TextOverflow.ellipsis),
                        ]),
                  ),
                  IconButton(
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 16,
                      color: const Color(0xFFD1D5DB),
                    ),
                    tooltip: isDark
                        ? 'Chuyển sang chế độ sáng'
                        : 'Chuyển sang chế độ tối',
                    onPressed: onToggleTheme,
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout,
                        size: 16, color: Color(0xFFD1D5DB)),
                    tooltip: 'Đăng xuất',
                    onPressed: onLogout,
                  ),
                ]),
        ),
      ]),
    );

    // Sprint 19 hotfix #14 (2026-05-08): Pattern B — Row layout, sidebar
    // luôn visible (rail 64 hoặc expanded 240). KHÔNG có Stack overlay,
    // KHÔNG có hot zone, KHÔNG có hover. Toggle button nằm trong sidebar.
    return Scaffold(
      body: Row(children: [
        sidebar,
        Expanded(child: activeScreen),
      ]),
    );
  }
}

/// Sprint 19 hotfix #14: Toggle button reusable cho cả expanded + rail mode.
/// Expanded: chevron_left ở góc phải header. Rail: chevron_right centered.
class _SidebarToggleButton extends StatelessWidget {
  final bool collapsed;
  final VoidCallback onTap;

  const _SidebarToggleButton({required this.collapsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: collapsed ? 'Mở rộng sidebar' : 'Thu gọn sidebar',
      preferBelow: false,
      child: Material(
        color: Colors.white.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.tight)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.tight),
          child: SizedBox(
            width: 32,
            height: 32,
            child: Center(
              child: Icon(
                collapsed ? Icons.chevron_right : Icons.chevron_left,
                color: const Color(0xFFD1D5DB),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============== Mobile layout — Drawer + bottom nav 5 items ==============

class _MobileAdminLayout extends ConsumerStatefulWidget {
  final List<_NavItem> items;
  final int activeIdx;
  final Widget activeScreen;
  final String activeLabel;
  final dynamic user;
  final ValueChanged<int> onSwitchTab;
  final VoidCallback onLogout;

  const _MobileAdminLayout({
    required this.items,
    required this.activeIdx,
    required this.activeScreen,
    required this.activeLabel,
    required this.user,
    required this.onSwitchTab,
    required this.onLogout,
  });

  @override
  ConsumerState<_MobileAdminLayout> createState() => _MobileAdminLayoutState();
}

class _MobileAdminLayoutState extends ConsumerState<_MobileAdminLayout> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Sprint 7 (2026-05-07): theme toggle cho GV/BCN/Admin trên mobile/APK.
    final mode = ref.watch(themeProvider);
    final platformDark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark = mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);
    void onToggleTheme() {
      ref.read(themeProvider.notifier).setMode(isDark ? ThemeMode.light : ThemeMode.dark);
    }
    // Sprint 19 fix bottom nav (2026-05-08): filter ra section divider items.
    // Sprint 14 thêm `_NavItem.section()` cho desktop sidebar grouping nhưng
    // mobile bottom nav lúc đó render cả section header thành nav item
    // (vd label "Tổng quan" trùng "Dashboard"). Filter `isSection` + map
    // index gốc cho activeIdx + onSwitchTab.
    //
    // navItems = items thực sự click được (Dashboard, Cuộc thi của tôi...).
    // origIndex[i] = vị trí trong widget.items gốc (cho onSwitchTab callback).
    final navItems = <_NavItem>[];
    final origIndex = <int>[];
    for (var i = 0; i < widget.items.length; i++) {
      if (!widget.items[i].isSection) {
        navItems.add(widget.items[i]);
        origIndex.add(i);
      }
    }
    final bottomItems = navItems.length <= 5 ? navItems : navItems.take(4).toList();
    final hasMore = navItems.length > 5;
    final moreIndex = bottomItems.length;
    // Tìm bottom nav index từ activeIdx (origIndex inverse map)
    final bottomActiveIdx = origIndex.indexOf(widget.activeIdx);

    return Scaffold(
      key: _scaffoldKey,
      // Phase 2 Sprint 2 Step 1d: bỏ FAFAFA hardcoded → để Theme tự apply
      // → dark mode sẽ dùng appBgDark (#1C1815)
      appBar: AppBar(
        title: Text(widget.activeLabel,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, color: context.textPrimary)),
        backgroundColor: context.cardBg,
        foregroundColor: context.textPrimary,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textMuted),
        // Sprint 7 (2026-05-07): theme toggle ở góc phải AppBar (mobile/APK).
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
            ),
            color: context.textMuted,
            tooltip: isDark ? 'Chuyển sang chế độ sáng' : 'Chuyển sang chế độ tối',
            onPressed: onToggleTheme,
          ),
        ],
      ),
      drawer: _AdminDrawer(
        items: widget.items,
        activeIdx: widget.activeIdx,
        user: widget.user,
        onSwitchTab: (i) {
          Navigator.pop(context);
          widget.onSwitchTab(i);
        },
        onLogout: () {
          Navigator.pop(context);
          widget.onLogout();
        },
      ),
      // Sprint 19 hotfix #3 (2026-05-08): bỏ AnimatedSwitcher fade vì khi
      // switch tab admin, AnimatedSwitcher mặc định **stack 2 widget chồng**
      // (Stack-based layout) → 2 screen overlap render → flicker, content
      // jumpy, 2 fetcher cùng fire request. Pattern chuẩn admin dashboard
      // (Linear/Notion/Stripe) là instant switch — fast, predictable, không
      // confused user. Mobile drawer + bottom nav vẫn smooth qua tab indicator.
      body: widget.activeScreen,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // Sprint 19 fix: dùng bottomActiveIdx (đã map qua origIndex) thay
        // widget.activeIdx (có thể trỏ vào section item không render bottom).
        currentIndex: bottomActiveIdx >= 0 && bottomActiveIdx < bottomItems.length
            ? bottomActiveIdx
            : 0,
        selectedItemColor: ptitRed,
        unselectedItemColor: context.textMuted,
        backgroundColor: context.cardBg,
        showUnselectedLabels: true,
        selectedFontSize: 10.5,
        unselectedFontSize: 10.5,
        iconSize: 20,
        onTap: (i) {
          if (hasMore && i == moreIndex) {
            _scaffoldKey.currentState?.openDrawer();
            return;
          }
          // Sprint 19 fix: map bottom nav index → original items index.
          widget.onSwitchTab(origIndex[i]);
        },
        items: [
          for (final item in bottomItems)
            BottomNavigationBarItem(
                icon: Icon(item.icon ?? Icons.circle), label: item.label),
          if (hasMore)
            const BottomNavigationBarItem(
                icon: Icon(Icons.menu), label: 'Thêm'),
        ],
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final List<_NavItem> items;
  final int activeIdx;
  final dynamic user;
  final ValueChanged<int> onSwitchTab;
  final VoidCallback onLogout;

  const _AdminDrawer({
    required this.items,
    required this.activeIdx,
    required this.user,
    required this.onSwitchTab,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(children: [
        // Brand header
        Container(
          padding: const EdgeInsets.fromLTRB(18, 56, 18, 18),
          color: const Color(0xFF1F2937),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ptitRed,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Center(
                child: Text('P',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PTIT Contest',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                    Text('Cổng quản lý',
                        style:
                            TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                  ]),
            ),
          ]),
        ),
        // Menu items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: List.generate(items.length, (i) {
              final isActive = i == activeIdx;
              // Sprint 5 a11y: drawer item Semantics same pattern sidebar wide
              return Semantics(
                label: items[i].label,
                button: !items[i].isSection,
                selected: isActive,
                hint: items[i].isSection
                    ? 'Nhóm chức năng'
                    : (isActive
                        ? 'Đang ở mục này'
                        : 'Chuyển sang mục ${items[i].label}'),
                child: items[i].isSection
                    // Sprint 14: section divider mobile drawer.
                    ? Padding(
                        padding: EdgeInsets.fromLTRB(
                            16, i == 0 ? 4 : 12, 16, 4),
                        child: Text(
                          items[i].label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: context.textFaint,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      )
                    : ListTile(
                        leading: Icon(items[i].icon,
                            color: isActive ? ptitRed : context.textMuted,
                            size: 20),
                        title: Text(items[i].label,
                            style: TextStyle(
                                fontSize: 14,
                                color: isActive
                                    ? ptitRed
                                    : context.textPrimary,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                        tileColor: isActive ? context.ptitRedSoft : null,
                        onTap: () => onSwitchTab(i),
                      ),
              );
            }),
          ),
        ),
        Divider(height: 1, color: context.cardBorder),
        // User footer
        Container(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration:
                  BoxDecoration(color: context.ptitRedSoft, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  user.fullName.split(' ').last.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: ptitRed,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(user.roles.join(','),
                        overflow: TextOverflow.ellipsis,
                        style:
                            TextStyle(color: context.textMuted, fontSize: 11)),
                  ]),
            ),
            IconButton(
              icon: const Icon(Icons.logout, size: 18, color: ptitRed),
              tooltip: 'Đăng xuất',
              onPressed: onLogout,
            ),
          ]),
        ),
      ]),
    );
  }
}

class _NavItem {
  /// Slug dùng cho deep-link URL (vd: 'contests' → /admin/contests).
  /// Sprint 8 fix #2 (2026-05-07).
  ///
  /// Sprint 14 (2026-05-08): nullable cho section divider — khi `slug == null`,
  /// item này là divider header trong sidebar (vd: "Phê duyệt"), không click được.
  final String? slug;
  final String label;
  final IconData? icon;
  final Widget? screen;
  /// True nếu là section divider (label uppercase nhỏ, không tap được).
  final bool isSection;
  /// Sprint 24 (2026-05-09): badge count live builder. Trả 0 = không show badge.
  final int Function(WidgetRef ref)? badgeBuilder;
  _NavItem(this.slug, this.label, this.icon, this.screen,
      {this.badgeBuilder})
      : isSection = false;
  /// Sprint 14 factory: section divider trong sidebar (label hoặc placeholder).
  /// Pattern Linear/Notion: "TỔNG QUAN", "PHÊ DUYỆT", "THEO DÕI".
  _NavItem.section(this.label)
      : slug = null,
        icon = null,
        screen = null,
        isSection = true,
        badgeBuilder = null;
}

/// Sprint 14 P2.2 (2026-05-08): wrapper screen cho sidebar item "Tạo cuộc thi".
/// CTA card centered + workflow note + button mở dialog tạo contest.
/// Sau khi tạo thành công, switch tab về "Cuộc thi của tôi" (slug=contests).
class _NewContestQuickScreen extends ConsumerWidget {
  const _NewContestQuickScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: context.appBg,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.ptitRedSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.add_circle_outline,
                      size: 36, color: ptitRed),
                ),
                const SizedBox(height: 18),
                Text(
                  'Tạo cuộc thi mới',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Workflow: tạo cuộc thi → submit QĐ1 cho BCN → BCN duyệt → '
                  'mở đăng ký → SV đăng ký → ONGOING → judge chấm → FINISHED → '
                  'tính kết quả → submit QĐ2 → BCN duyệt → publish → cấp cert.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: context.textMuted,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Bắt đầu tạo'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(220, 48),
                    backgroundColor: ptitRed,
                  ),
                  onPressed: () async {
                    final created = await showCreateContestDialog(context);
                    if (created == true && context.mounted) {
                      // Sau khi tạo thành công, redirect sang /admin/contests
                      // để xem cuộc thi vừa tạo.
                      context.go('/admin/contests');
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.list_alt_outlined, size: 16),
                  label: const Text('Xem cuộc thi của tôi'),
                  onPressed: () => context.go('/admin/contests'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sprint 14 P2.1 (2026-05-08): tách Backup & Restore khỏi Configs sidebar.
/// Render lại 2 button (tạo backup / khôi phục) — extracted từ ConfigsScreen.
class _BackupRestoreScreen extends ConsumerWidget {
  const _BackupRestoreScreen();

  Future<void> _backup(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo backup?'),
        content: const Text(
          'pg_dump schema ptit_contest. File backup lưu trên server (volume /backups). '
          'Có thể chạy hàng ngày qua cron, hoặc trigger manual.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Tạo backup')),
        ],
      ),
    );
    if (confirm != true) return;
    final api = ref.read(apiClientProvider);
    try {
      final res = await api.dio.post('/admin/backup');
      if (!context.mounted) return;
      AppToast.success(context, 'Đã tạo backup: ${res.data['filename'] ?? '?'}');
    } catch (e) {
      if (!context.mounted) return;
      AppToast.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return ColoredBox(
      color: context.appBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isMobile)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              decoration: BoxDecoration(
                color: context.cardBg,
                border: Border(bottom: BorderSide(color: context.cardBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quản trị',
                      style: TextStyle(
                          color: context.textMuted, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text('Backup & Restore (AD-04)',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimary)),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: MCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.cloud_outlined,
                          size: 18, color: context.textPrimary),
                      const SizedBox(width: 8),
                      Text('Sao lưu / Khôi phục DB',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary)),
                    ]),
                    const SizedBox(height: 8),
                    Text(
                      'pg_dump schema ptit_contest. File backup lưu trên server '
                      '(volume /backups). Restore yêu cầu can thiệp DBA qua CLI.',
                      style: TextStyle(
                          fontSize: 12.5,
                          color: context.textMuted,
                          height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Tạo backup ngay'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: context.successGreen,
                      ),
                      onPressed: () => _backup(context, ref),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      icon: Icon(Icons.history,
                          size: 18, color: ptitRed),
                      label: Text('Khôi phục backup...',
                          style: TextStyle(color: ptitRed)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: BorderSide(color: context.ptitRedSoft),
                      ),
                      onPressed: () {
                        AppToast.info(context, 'Restore yêu cầu can thiệp DBA qua CLI Railway. Liên hệ admin hệ thống.');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Sprint 23 Step 4 (2026-05-09): _ComingSoonScreen đã thay bằng 7 screens
// thật trong gv_extra_screens.dart + bcn_extra_screens.dart.
