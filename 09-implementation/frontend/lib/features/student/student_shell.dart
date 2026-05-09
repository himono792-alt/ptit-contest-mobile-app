// SV shell — Sprint 20++ (2026-05-09):
//   - 8 tabs trong IndexedStack: 0 Trang chủ / 1 Cuộc thi / 2 Đã đăng ký /
//     3 Kết quả / 4 Thông báo / 5 Cài đặt / 6 Lịch của tôi / 7 Chứng nhận
//   - Sidebar grouped 3 nhóm + Pattern B collapse 240↔64 (admin-style)
//     SharedPreferences key 'student.sidebar_collapsed' persist trạng thái
//   - Mobile bottom nav 6 tabs đầu (idx 0-5), 2 tabs mới idx 6+7 web only
//
// Responsive:
//   - Mobile (<900 hoặc native APK): MobileFrame + bottom nav 6 tabs
//   - Web wide (≥900): sidebar grouped với toggle collapse + main content

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/spacing.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import '../../core/widgets/m_bottom_nav.dart';
import '../../core/widgets/mobile_frame.dart';
import 'contest_list_screen.dart';
import 'home_screen.dart';
import 'my_calendar_screen.dart';
import 'my_certificates_screen.dart';
import 'my_registrations_screen.dart';
import 'my_results_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Tab index global state — mở rộng tới 8 tab Sprint 20++.
/// Cho phép notification deep-link switch tab từ ngoài StudentShell.
final studentTabProvider = StateProvider<int>((ref) => 0);

/// SharedPreferences key persist trạng thái sidebar collapse.
const String _kSidebarCollapsedKey = 'student.sidebar_collapsed';
const double _kSidebarExpandedWidth = 240;
const double _kSidebarRailWidth = 64;
const Duration _kSidebarAnim = Duration(milliseconds: 220);

/// Số tab tổng = 8.
const int _kTabCount = 8;
/// Số tab hiển thị trên mobile bottom nav (6 đầu).
const int _kMobileTabCount = 6;

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});
  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  void _switchTab(int i) =>
      ref.read(studentTabProvider.notifier).state = i;

  @override
  Widget build(BuildContext context) {
    final idx = ref.watch(studentTabProvider);
    final safeIdx = (idx >= 0 && idx < _kTabCount) ? idx : 0;

    final tabs = <Widget>[
      HomeScreen(onSwitchTab: _switchTab),
      const ContestListScreen(),
      const MyRegistrationsScreen(),
      const MyResultsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
      const MyCalendarScreen(),
      const MyCertificatesScreen(),
    ];

    // Mobile bottom nav meta: 6 tab đầu giữ nguyên format (Trang chủ ... Cài đặt).
    final mobileTabLabels = const [
      'Trang chủ',
      'Cuộc thi',
      'Đã đăng ký',
      'Kết quả',
      'Thông báo',
      'Cài đặt',
    ];
    final mobileTabIcons = const [
      Icons.home_outlined,
      Icons.emoji_events_outlined,
      Icons.assignment_outlined,
      Icons.workspace_premium_outlined,
      Icons.notifications_outlined,
      Icons.settings_outlined,
    ];
    final mobileTabActiveIcons = const [
      Icons.home,
      Icons.emoji_events,
      Icons.assignment,
      Icons.workspace_premium,
      Icons.notifications,
      Icons.settings,
    ];

    final asyncNotifs = ref.watch(notificationsProvider);
    final unread = asyncNotifs.maybeWhen(
      data: (d) => d['unread_count'] as int? ?? 0,
      orElse: () => 0,
    );

    final width = MediaQuery.of(context).size.width;
    final useWideLayout = kIsWeb && width >= 900;

    if (useWideLayout) {
      return _SVWideLayout(
        tabs: tabs,
        activeIdx: safeIdx,
        onSwitchTab: _switchTab,
      );
    }

    // Mobile layout: chỉ render 6 tab đầu trong bottom nav.
    // Nếu safeIdx >= 6 (tab 7/8 web only) → fallback hiển thị tab 0 trên mobile.
    final mobileSafeIdx = safeIdx < _kMobileTabCount ? safeIdx : 0;
    return MobileFrame(
      child: Scaffold(
        body: IndexedStack(index: mobileSafeIdx, children: tabs.take(_kMobileTabCount).toList()),
        bottomNavigationBar: MBottomNav(
          selectedIndex: mobileSafeIdx,
          onChanged: _switchTab,
          items: List.generate(_kMobileTabCount, (i) => MBottomNavItem(
                icon: mobileTabIcons[i],
                activeIcon: mobileTabActiveIcons[i],
                label: mobileTabLabels[i],
                badge: i == 4 ? unread : 0,
              )),
        ),
      ),
    );
  }
}

// ============== Sprint 20: Sidebar grouped data ==============

/// Item trong sidebar — chỉ tabIndex (Sprint 20++ bỏ routeBuilder để giữ
/// sidebar khi user vào Lịch/Chứng nhận, các tab này nằm trong IndexedStack).
class StudentNavItem {
  final int tabIndex;
  final String label;
  final IconData icon;
  final IconData activeIcon;
  /// Hàm trả về badge count (null = không show), gọi mỗi build để live update.
  final int Function(WidgetRef ref)? badgeBuilder;
  const StudentNavItem({
    required this.tabIndex,
    required this.label,
    required this.icon,
    required this.activeIcon,
    this.badgeBuilder,
  });
}

/// Group label + items list.
class StudentNavGroup {
  final String label;
  final List<StudentNavItem> items;
  const StudentNavGroup({required this.label, required this.items});
}

/// Sprint 20++ sidebar groups — 3 nhóm × 2-3 items = 8 tabs total.
List<StudentNavGroup> buildStudentNavGroups() => [
      StudentNavGroup(label: 'KHÁM PHÁ', items: [
        const StudentNavItem(
          tabIndex: 0,
          label: 'Trang chủ',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
        ),
        StudentNavItem(
          tabIndex: 1,
          label: 'Cuộc thi',
          icon: Icons.emoji_events_outlined,
          activeIcon: Icons.emoji_events,
          badgeBuilder: (ref) {
            final list = ref.watch(contestListProvider);
            return list.maybeWhen(
                data: (d) => d.items.length, orElse: () => 0);
          },
        ),
        const StudentNavItem(
          tabIndex: 6,
          label: 'Lịch của tôi',
          icon: Icons.calendar_month_outlined,
          activeIcon: Icons.calendar_month,
        ),
      ]),
      StudentNavGroup(label: 'CỦA TÔI', items: [
        StudentNavItem(
          tabIndex: 2,
          label: 'Đã đăng ký',
          icon: Icons.assignment_outlined,
          activeIcon: Icons.assignment,
          badgeBuilder: (ref) {
            final list = ref.watch(myEntriesProvider);
            return list.maybeWhen(data: (d) => d.length, orElse: () => 0);
          },
        ),
        const StudentNavItem(
          tabIndex: 3,
          label: 'Kết quả',
          icon: Icons.workspace_premium_outlined,
          activeIcon: Icons.workspace_premium,
        ),
        StudentNavItem(
          tabIndex: 7,
          label: 'Chứng nhận',
          icon: Icons.verified_outlined,
          activeIcon: Icons.verified,
          badgeBuilder: (ref) {
            final results = ref.watch(myResultsProvider);
            return results.maybeWhen(
                data: (r) =>
                    r.where((x) => (x.awardTitle ?? '').isNotEmpty).length,
                orElse: () => 0);
          },
        ),
      ]),
      StudentNavGroup(label: 'KHÁC', items: [
        StudentNavItem(
          tabIndex: 4,
          label: 'Thông báo',
          icon: Icons.notifications_outlined,
          activeIcon: Icons.notifications,
          badgeBuilder: (ref) {
            final n = ref.watch(notificationsProvider);
            return n.maybeWhen(
                data: (d) => d['unread_count'] as int? ?? 0,
                orElse: () => 0);
          },
        ),
        const StudentNavItem(
          tabIndex: 5,
          label: 'Cài đặt',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
        ),
      ]),
    ];

// ============== Wide layout với Pattern B collapse ==============

class _SVWideLayout extends ConsumerStatefulWidget {
  final List<Widget> tabs;
  final int activeIdx;
  final ValueChanged<int> onSwitchTab;

  const _SVWideLayout({
    required this.tabs,
    required this.activeIdx,
    required this.onSwitchTab,
  });

  @override
  ConsumerState<_SVWideLayout> createState() => _SVWideLayoutState();
}

class _SVWideLayoutState extends ConsumerState<_SVWideLayout> {
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

  /// Parse mã SV từ email PTIT (vd `b22dccn001@stu.ptit.edu.vn` → `B22DCCN001`).
  String _studentCodeFromEmail(String email) {
    final localPart = email.split('@').first;
    final match = RegExp(r'^[bB]\d{2}[a-zA-Z]+\d+$').hasMatch(localPart);
    return match ? localPart.toUpperCase() : email;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    if (user == null) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: ptitRed)));
    }
    final initial = user.fullName.isNotEmpty
        ? user.fullName.split(' ').last.substring(0, 1).toUpperCase()
        : 'S';
    final groups = buildStudentNavGroups();

    return Scaffold(
      body: Row(children: [
        // ============== Sidebar AnimatedContainer 240↔64 ==============
        AnimatedContainer(
          duration: _kSidebarAnim,
          curve: Curves.easeOut,
          width: _collapsed ? _kSidebarRailWidth : _kSidebarExpandedWidth,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(children: [
            // Brand header
            Container(
              height: 64,
              padding: EdgeInsets.symmetric(
                  horizontal: _collapsed ? AppSpacing.s12 : AppSpacing.s16,
                  vertical: AppSpacing.s12),
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
                if (!_collapsed) ...[
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('PTIT Contest',
                              style: TextStyle(
                                  color: context.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.2)),
                          Text('SINH VIÊN',
                              style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2)),
                        ]),
                  ),
                  _SidebarToggleButton(
                      collapsed: _collapsed, onTap: _toggleCollapsed),
                ],
              ]),
            ),
            // Toggle khi collapsed (đặt riêng dưới brand)
            if (_collapsed)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                child: Center(
                  child: _SidebarToggleButton(
                      collapsed: _collapsed, onTap: _toggleCollapsed),
                ),
              ),
            // Nav groups
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                children: [
                  for (final g in groups) ...[
                    if (!_collapsed)
                      _GroupLabel(label: g.label)
                    else
                      _GroupDividerCollapsed(),
                    for (final item in g.items)
                      _SidebarItem(
                        item: item,
                        isActive: item.tabIndex == widget.activeIdx,
                        collapsed: _collapsed,
                        onTap: () => widget.onSwitchTab(item.tabIndex),
                      ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                ],
              ),
            ),
            // Footer user — adapt theo collapse state
            _SidebarFooter(
              collapsed: _collapsed,
              initial: initial,
              fullName: user.fullName,
              studentCode: _studentCodeFromEmail(user.email),
              onLogout: () => ref.read(authProvider.notifier).logout(),
            ),
          ]),
        ),
        // Main content
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: IndexedStack(index: widget.activeIdx, children: widget.tabs),
            ),
          ),
        ),
      ]),
    );
  }
}

// ============== Group label widget ==============

class _GroupLabel extends StatelessWidget {
  final String label;
  const _GroupLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, AppSpacing.s4),
      child: Text(label,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          )),
    );
  }
}

/// Khi rail collapsed — thay GroupLabel bằng đường divider mảnh.
class _GroupDividerCollapsed extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
      child: Container(
        height: 1,
        color: context.cardBorder.withValues(alpha: 0.6),
      ),
    );
  }
}

// ============== Sidebar item widget ==============

class _SidebarItem extends ConsumerWidget {
  final StudentNavItem item;
  final bool isActive;
  final bool collapsed;
  final VoidCallback onTap;
  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.collapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badge = item.badgeBuilder?.call(ref) ?? 0;
    final showBadge = badge > 0;
    final isNotif = item.tabIndex == 4;
    final badgeText = showBadge
        ? ', $badge ${isNotif ? "thông báo chưa đọc" : "mục"}'
        : '';

    final inkContent = InkWell(
      excludeFromSemantics: true,
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : AppSpacing.s16,
            vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: isActive ? context.ptitRedSoft : null,
          border: Border(
            left: BorderSide(
              color: isActive ? ptitRed : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: collapsed
            ? Center(
                child: Stack(clipBehavior: Clip.none, children: [
                  Icon(isActive ? item.activeIcon : item.icon,
                      size: 19, color: isActive ? ptitRed : context.textMuted),
                  if (showBadge)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isNotif ? ptitRed : context.cardBorder,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                              color: Theme.of(context).cardColor, width: 1.5),
                        ),
                        constraints: const BoxConstraints(minWidth: 14),
                        child: Text('$badge',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isNotif
                                  ? Colors.white
                                  : context.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            )),
                      ),
                    ),
                ]),
              )
            : Row(children: [
                Icon(isActive ? item.activeIcon : item.icon,
                    size: 17, color: isActive ? ptitRed : context.textMuted),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Text(item.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive ? ptitRed : context.textPrimary,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: -0.1,
                      )),
                ),
                if (showBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: isNotif
                          ? ptitRed
                          : context.cardBorder.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text('$badge',
                        style: TextStyle(
                          color: isNotif ? Colors.white : context.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
              ]),
      ),
    );

    final wrapped = collapsed
        ? Tooltip(
            message: item.label + (showBadge ? ' ($badge)' : ''),
            preferBelow: false,
            child: inkContent,
          )
        : inkContent;

    return Semantics(
      label: '${item.label}$badgeText',
      button: true,
      selected: isActive,
      hint: isActive ? 'Đang ở mục này' : 'Chuyển sang mục ${item.label}',
      child: wrapped,
    );
  }
}

// ============== Sidebar footer widget ==============

class _SidebarFooter extends ConsumerWidget {
  final bool collapsed;
  final String initial;
  final String fullName;
  final String studentCode;
  final VoidCallback onLogout;

  const _SidebarFooter({
    required this.collapsed,
    required this.initial,
    required this.fullName,
    required this.studentCode,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sprint 21 (2026-05-09): theme toggle nhanh giống admin/GV.
    // Resolve effective dark: nếu mode = system → đọc platform brightness.
    final mode = ref.watch(themeProvider);
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark =
        mode == ThemeMode.dark || (mode == ThemeMode.system && platformDark);
    void toggleTheme() {
      ref
          .read(themeProvider.notifier)
          .setMode(isDark ? ThemeMode.light : ThemeMode.dark);
    }

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: collapsed ? AppSpacing.s8 : AppSpacing.s12,
          vertical: AppSpacing.s12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.cardBorder)),
      ),
      child: collapsed
          ? Column(children: [
              Tooltip(
                message: '$fullName · $studentCode',
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: context.ptitRedSoft, shape: BoxShape.circle),
                  child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                            color: ptitRed,
                            fontWeight: FontWeight.w800,
                            fontSize: 13)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Tooltip(
                message: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                child: IconButton(
                  icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 16,
                      color: context.textMuted),
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: toggleTheme,
                ),
              ),
              Tooltip(
                message: 'Đăng xuất',
                child: IconButton(
                  icon: Icon(Icons.power_settings_new,
                      size: 16, color: context.textMuted),
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onLogout,
                ),
              ),
            ])
          : Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: context.ptitRedSoft, shape: BoxShape.circle),
                child: Center(
                  child: Text(initial,
                      style: const TextStyle(
                          color: ptitRed,
                          fontWeight: FontWeight.w800,
                          fontSize: 13)),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fullName,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2)),
                      const SizedBox(height: 1),
                      Text(studentCode,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.2)),
                    ]),
              ),
              IconButton(
                icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 16,
                    color: context.textMuted),
                tooltip: isDark ? 'Chế độ sáng' : 'Chế độ tối',
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: toggleTheme,
              ),
              IconButton(
                icon: Icon(Icons.power_settings_new,
                    size: 16, color: context.textMuted),
                tooltip: 'Đăng xuất',
                visualDensity: VisualDensity.compact,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                onPressed: onLogout,
              ),
            ]),
    );
  }
}

// ============== Toggle button reusable ==============

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
        color: context.cardBorder.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.tight)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.tight),
          child: SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: Icon(
                collapsed ? Icons.chevron_right : Icons.chevron_left,
                color: context.textMuted,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
