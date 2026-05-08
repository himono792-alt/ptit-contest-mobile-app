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
import '../../core/widgets/m_card.dart';
import 'admin_contests_screen.dart';
import 'admin_dashboard_screen.dart';
import 'anomaly_reports_screen.dart';
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
    // GV/BTC scope — chỉ ORGANIZER (KHÔNG check ADMIN). Admin có riêng module.
    if (user.isOrganizer) {
      items.add(_NavItem.section('Cuộc thi'));
      items.add(_NavItem('contests', 'Cuộc thi của tôi',
          Icons.emoji_events_outlined, const AdminContestsScreen()));
      items.add(_NavItem('contests-new', 'Tạo cuộc thi',
          Icons.add_circle_outline, const _NewContestQuickScreen()));
    }
    // BCN scope — chỉ HOD.
    if (user.isHod) {
      items.add(_NavItem.section('Phê duyệt'));
      items.add(_NavItem('approvals-q1', 'Đề xuất cuộc thi (QĐ1)',
          Icons.fact_check_outlined,
          const ApprovalQueueScreen(lockedType: 'CONTEST_PROPOSAL')));
      items.add(_NavItem('approvals-q2', 'Kết quả cuộc thi (QĐ2)',
          Icons.emoji_events_outlined,
          const ApprovalQueueScreen(lockedType: 'CONTEST_RESULT')));
      items.add(_NavItem.section('Theo dõi'));
      items.add(_NavItem('monitor', 'Giám sát',
          Icons.visibility_outlined, const MonitorScreen()));
    }
    // Judge scope — chỉ JUDGE (thường gắn với GV/BTC).
    if (user.isJudge) {
      // Section "Chấm điểm" chỉ thêm nếu CHƯA có "Cuộc thi" section ở trên
      // (tức user là JUDGE thuần, không Organizer). Pure judge sẽ rất hiếm.
      if (!user.isOrganizer) {
        items.add(_NavItem.section('Chấm điểm'));
      }
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
    if (!_initialApplied && widget.initialTab != null) {
      final wantedIdx = items.indexWhere((it) => it.slug == widget.initialTab);
      if (wantedIdx >= 0) _idx = wantedIdx;
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

/// Sprint 19 hotfix #5 (2026-05-08): collapsible sidebar với hover peek pattern.
/// SharedPreferences key persist trạng thái thu/mở.
const String _kSidebarCollapsedKey = 'admin.sidebar_collapsed';
const double _kSidebarWidth = 240;
const Duration _kSidebarAnim = Duration(milliseconds: 200);

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
  bool _hovering = false;

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
    setState(() {
      _collapsed = !_collapsed;
      _hovering = false; // Reset hover khi user toggle thủ công
    });
    SharedPreferences.getInstance()
        .then((p) => p.setBool(_kSidebarCollapsedKey, _collapsed));
  }

  /// Sidebar visible khi: KHÔNG collapsed HOẶC đang hover (peek).
  bool get _showSidebar => !_collapsed || _hovering;

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

    final sidebar = Container(
          width: _kSidebarWidth,
          decoration: const BoxDecoration(
            color: Color(0xFF1F2937),
            border: Border(right: BorderSide(color: Colors.black12)),
          ),
          child: Column(children: [
            // Brand
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF374151))),
              ),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: ptitRed, borderRadius: BorderRadius.circular(AppRadius.sm)),
                  child: const Center(
                    child: Text('P',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14)),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text('Cổng quản lý',
                            style:
                                TextStyle(color: Color(0xFF9CA3AF), fontSize: 10)),
                      ]),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: List.generate(items.length, (i) {
                  final isActive = i == activeIdx;
                  // Sprint 5 a11y: wrap admin sidebar item Semantics — pattern giống
                  // Sprint 3 student_shell sidebar.
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
                        // Sprint 14 (2026-05-08): section divider header.
                        // Linear/Notion pattern — uppercase nhỏ, mờ, top spacing.
                        ? Padding(
                            padding: EdgeInsets.fromLTRB(
                                18, i == 0 ? 8 : 16, 18, 6),
                            child: Text(
                              items[i].label.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                          )
                        : InkWell(
                            excludeFromSemantics: true,
                            onTap: () => onSwitchTab(i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 9),
                              decoration: BoxDecoration(
                                color:
                                    isActive ? const Color(0x26C8102E) : null,
                                border: Border(
                                  left: BorderSide(
                                    color: isActive
                                        ? ptitRed
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                              ),
                              child: Row(children: [
                                Icon(items[i].icon,
                                    size: 18,
                                    color: isActive
                                        ? Colors.white
                                        : const Color(0xFFD1D5DB)),
                                const SizedBox(width: 10),
                                Text(items[i].label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isActive
                                          ? Colors.white
                                          : const Color(0xFFD1D5DB),
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    )),
                              ]),
                            ),
                          ),
                  );
                }),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFF374151))),
              ),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: context.ptitRedSoft, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      user.fullName.split(' ').last.substring(0, 1).toUpperCase(),
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
                // Sprint 7 (2026-05-07): theme toggle nằm cạnh logout. Sidebar
                // wide hardcode dark slate-800 nên icon dùng màu sáng cố định
                // (không theo context.textPrimary) cho consistent.
                IconButton(
                  icon: Icon(
                    isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                    size: 16,
                    color: const Color(0xFFD1D5DB),
                  ),
                  tooltip: isDark ? 'Chuyển sang chế độ sáng' : 'Chuyển sang chế độ tối',
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

    // Sprint 19 hotfix #8 (2026-05-08): redesign theo Sentry pattern.
    // - Toggle button NẰM TRONG sidebar header (top-right, chevron icon)
    // - Khi đóng: sidebar slide -240 hoàn toàn → content fill 100% width
    // - Hover left edge 12px → peek overlay sidebar (toggle button visible
    //   trong peek, click để pin permanent)
    // - Visual handle 3px ptitRed gradient ở left edge khi closed → cue
    //   discoverability cho user biết hover được
    return Scaffold(
      body: Stack(children: [
        // Layer 1: content fill full width khi collapsed (no rail reservation)
        AnimatedPadding(
          duration: _kSidebarAnim,
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
              left: _collapsed ? 0 : _kSidebarWidth),
          child: activeScreen,
        ),
        // Layer 2: sidebar — slide in/out + Material elevation khi peek
        AnimatedPositioned(
          duration: _kSidebarAnim,
          curve: Curves.easeOut,
          left: _showSidebar ? 0 : -_kSidebarWidth,
          top: 0,
          bottom: 0,
          width: _kSidebarWidth,
          child: MouseRegion(
            onEnter: (_) {
              if (_collapsed && !_hovering) {
                setState(() => _hovering = true);
              }
            },
            onExit: (_) {
              if (_collapsed && _hovering) {
                setState(() => _hovering = false);
              }
            },
            child: Material(
              elevation: _collapsed && _hovering ? 12 : 0,
              color: Colors.transparent,
              child: sidebar,
            ),
          ),
        ),
        // Layer 3: hot zone left edge KHI closed — ALWAYS rendered (không
        // conditional theo _hovering) để tránh widget disposed mid-click.
        // - Click anywhere trong 32px hot zone → toggle pin permanent
        // - Hover trigger peek (qua onEnter)
        // - Visual handle ptitRed visible khi !_hovering, fade out khi peek
        // Z-order: rendered AFTER sidebar trong Stack → click events ưu tiên
        // hot zone (left 32px) hơn sidebar khi peek overlay.
        if (_collapsed)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 32,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) {
                if (!_hovering) setState(() => _hovering = true);
              },
              child: GestureDetector(
                onTap: _toggleCollapsed,
                behavior: HitTestBehavior.opaque,
                // AnimatedOpacity fade handle visual khi peek (sidebar che lên)
                child: AnimatedOpacity(
                  duration: _kSidebarAnim,
                  opacity: _hovering ? 0 : 1,
                  child: Stack(children: [
                    // 4px accent line ptitRed gradient — visual cue
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              ptitRed.withValues(alpha: 0.5),
                              ptitRed.withValues(alpha: 0.15),
                              ptitRed.withValues(alpha: 0.5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Chevron handle centered — affordance "click để mở"
                    Center(
                      child: Container(
                        width: 22,
                        height: 28,
                        decoration: BoxDecoration(
                          color: ptitRed.withValues(alpha: 0.85),
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        // Layer 4: Toggle button NẰM TRONG sidebar header — slide cùng sidebar.
        // Khi sidebar visible (mở/peek): button ở top-right sidebar (x=196).
        // Khi sidebar hidden: button trượt ngoài viewport (-44) cùng sidebar.
        AnimatedPositioned(
          duration: _kSidebarAnim,
          curve: Curves.easeOut,
          top: 14,
          left: _showSidebar
              ? _kSidebarWidth - 44
              : -44, // out of viewport
          width: 36,
          height: 36,
          child: Material(
            color: Colors.white.withValues(alpha: 0.08),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.tight)),
            child: InkWell(
              onTap: _toggleCollapsed,
              borderRadius: BorderRadius.circular(AppRadius.tight),
              child: Center(
                child: Icon(
                  _collapsed
                      ? Icons.chevron_right // peek mode: pin sidebar permanent
                      : Icons.chevron_left, // open mode: collapse
                  color: const Color(0xFFD1D5DB),
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ]),
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
  _NavItem(this.slug, this.label, this.icon, this.screen)
      : isSection = false;
  /// Sprint 14 factory: section divider trong sidebar (label hoặc placeholder).
  /// Pattern Linear/Notion: "TỔNG QUAN", "PHÊ DUYỆT", "THEO DÕI".
  _NavItem.section(this.label)
      : slug = null,
        icon = null,
        screen = null,
        isSection = true;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tạo backup: ${res.data['filename'] ?? '?'}')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi backup: $e')),
      );
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Restore yêu cầu can thiệp DBA qua CLI Railway. '
                                  'Liên hệ admin hệ thống.')),
                        );
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
