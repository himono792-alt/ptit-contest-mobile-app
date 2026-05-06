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

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import 'admin_contests_screen.dart';
import 'admin_dashboard_screen.dart';
import 'approval_queue_screen.dart';
import 'admin_users_screen.dart';
import 'audit_log_screen.dart';
import 'configs_screen.dart';
import 'judge_screen.dart';
import 'master_data_screen.dart';
import 'monitor_screen.dart';
import 'review_moderation_screen.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});
  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _idx = 0;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Build menu based on roles (dùng chung cho cả 2 layout)
    final items = <_NavItem>[
      _NavItem('Dashboard', Icons.dashboard_outlined, const AdminDashboardScreen()),
    ];
    if (user.isOrganizer || user.isAdmin) {
      items.add(_NavItem(
          'Cuộc thi', Icons.emoji_events_outlined, const AdminContestsScreen()));
    }
    if (user.isHod || user.isAdmin) {
      items.add(_NavItem(
          'Phê duyệt', Icons.fact_check_outlined, const ApprovalQueueScreen()));
      items.add(_NavItem(
          'Giám sát', Icons.visibility_outlined, const MonitorScreen()));
    }
    if (user.isJudge || user.isAdmin) {
      items.add(
          _NavItem('Chấm bài', Icons.rate_review_outlined, const JudgeScreen()));
    }
    if (user.isAdmin) {
      items.add(_NavItem(
          'Quản lý user', Icons.people_outline, const AdminUsersScreen()));
      items.add(
          _NavItem('Khoa/Ngành', Icons.school_outlined, const MasterDataScreen()));
      items.add(_NavItem('Bình luận', Icons.comment_outlined,
          const ReviewModerationScreen()));
      items.add(
          _NavItem('Cấu hình', Icons.settings_outlined, const ConfigsScreen()));
      items.add(_NavItem('Audit log', Icons.history, const AuditLogScreen()));
    }

    final activeIdx = _idx.clamp(0, items.length - 1);
    final activeItem = items[activeIdx];

    // Responsive: <1024px hoặc APK → mobile/tablet layout (drawer). Web wide ≥1024 → sidebar.
    // Sprint 2 fix C4: nâng threshold lên 1024 (Material breakpoint) để 768px tablet
    // collapse vào hamburger drawer, tránh content cramp 528px.
    final width = MediaQuery.of(context).size.width;
    final useMobileLayout = !kIsWeb || width < 1024;

    if (useMobileLayout) {
      return _MobileAdminLayout(
        items: items,
        activeIdx: activeIdx,
        activeScreen: activeItem.screen,
        activeLabel: activeItem.label,
        user: user,
        onSwitchTab: (i) => setState(() => _idx = i),
        onLogout: () => ref.read(authProvider.notifier).logout(),
      );
    }

    return _WideAdminLayout(
      items: items,
      activeIdx: activeIdx,
      activeScreen: activeItem.screen,
      user: user,
      onSwitchTab: (i) => setState(() => _idx = i),
      onLogout: () => ref.read(authProvider.notifier).logout(),
    );
  }
}

// ============== Wide layout (desktop) — sidebar 240px ==============

class _WideAdminLayout extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(children: [
        Container(
          width: 240,
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
                  return InkWell(
                    onTap: () => onSwitchTab(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: isActive ? const Color(0x26C8102E) : null,
                        border: Border(
                          left: BorderSide(
                            color: isActive ? ptitRed : Colors.transparent,
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
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.normal,
                            )),
                      ]),
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
                IconButton(
                  icon: const Icon(Icons.logout,
                      size: 16, color: Color(0xFFD1D5DB)),
                  tooltip: 'Đăng xuất',
                  onPressed: onLogout,
                ),
              ]),
            ),
          ]),
        ),
        Expanded(child: activeScreen),
      ]),
    );
  }
}

// ============== Mobile layout — Drawer + bottom nav 5 items ==============

class _MobileAdminLayout extends StatefulWidget {
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
  State<_MobileAdminLayout> createState() => _MobileAdminLayoutState();
}

class _MobileAdminLayoutState extends State<_MobileAdminLayout> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // Bottom nav lấy 4 items đầu (Dashboard + role-specific) + nút "Thêm" mở drawer
    final bottomItems = widget.items.length <= 5
        ? widget.items
        : widget.items.take(4).toList();
    final hasMore = widget.items.length > 5;
    // Index của tab "Thêm" = bottomItems.length (sau cùng) — đặc biệt
    final moreIndex = bottomItems.length;

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
      body: widget.activeScreen,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: widget.activeIdx < bottomItems.length ? widget.activeIdx : 0,
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
          widget.onSwitchTab(i);
        },
        items: [
          for (final item in bottomItems)
            BottomNavigationBarItem(icon: Icon(item.icon), label: item.label),
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
              return ListTile(
                leading: Icon(items[i].icon,
                    color: isActive ? ptitRed : context.textMuted, size: 20),
                title: Text(items[i].label,
                    style: TextStyle(
                        fontSize: 14,
                        color: isActive ? ptitRed : context.textPrimary,
                        fontWeight:
                            isActive ? FontWeight.w700 : FontWeight.w500)),
                tileColor: isActive ? context.ptitRedSoft : null,
                onTap: () => onSwitchTab(i),
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
  final String label;
  final IconData icon;
  final Widget screen;
  _NavItem(this.label, this.icon, this.screen);
}
