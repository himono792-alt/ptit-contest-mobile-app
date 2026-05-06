// SV shell — responsive theo screen width:
//   - Mobile (<900px hoặc native APK): MobileFrame 400px + bottom nav 6 tabs (UX mobile gốc)
//   - Web wide (≥900px PC): sidebar trái 240px + main content rộng, không MobileFrame
//
// Cùng 1 set screens, chỉ thay đổi layout shell.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/widgets/m_bottom_nav.dart';
import '../../core/widgets/mobile_frame.dart';
import 'contest_list_screen.dart';
import 'home_screen.dart';
import 'my_registrations_screen.dart';
import 'my_results_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

/// Phase 2 sprint 1 step 1 (2026-05-06): tab index global state.
/// Cho phép notification deep-link switch tab từ ngoài StudentShell.
/// Notification onTap với target_route='/me/entries' → set state=2 → tab 'Của tôi'.
final studentTabProvider = StateProvider<int>((ref) => 0);

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
    // Phase 2 sprint 1 step 1: tab index từ global provider, cho phép
    // notification deep-link switch tab từ NotificationsScreen sang tab khác.
    final idx = ref.watch(studentTabProvider);
    // Clamp để chống index out-of-range nếu provider có giá trị lỗi
    final safeIdx = (idx >= 0 && idx < 6) ? idx : 0;

    final tabs = <Widget>[
      HomeScreen(onSwitchTab: _switchTab),
      const ContestListScreen(),
      const MyRegistrationsScreen(),
      const MyResultsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];
    final tabLabels = ['Trang chủ', 'Cuộc thi', 'Của tôi', 'Kết quả', 'Thông báo', 'Tôi'];
    final tabIcons = [
      Icons.home_outlined,
      Icons.emoji_events_outlined,
      Icons.list_alt_outlined,
      Icons.workspace_premium_outlined,
      Icons.notifications_outlined,
      Icons.person_outline,
    ];
    final tabActiveIcons = [
      Icons.home,
      Icons.emoji_events,
      Icons.list_alt,
      Icons.workspace_premium,
      Icons.notifications,
      Icons.person,
    ];

    final asyncNotifs = ref.watch(notificationsProvider);
    final unread = asyncNotifs.maybeWhen(
      data: (d) => d['unread_count'] as int? ?? 0,
      orElse: () => 0,
    );

    // Responsive: web wide ≥900px → sidebar layout. Else (mobile / APK) → bottom nav.
    final width = MediaQuery.of(context).size.width;
    final useWideLayout = kIsWeb && width >= 900;

    if (useWideLayout) {
      return _SVWideLayout(
        tabs: tabs,
        tabLabels: tabLabels,
        tabIcons: tabIcons,
        tabActiveIcons: tabActiveIcons,
        unread: unread,
        activeIdx: safeIdx,
        onSwitchTab: _switchTab,
      );
    }

    // Mobile layout (default — APK + web mobile)
    return MobileFrame(
      child: Scaffold(
        body: IndexedStack(index: safeIdx, children: tabs),
        bottomNavigationBar: MBottomNav(
          selectedIndex: safeIdx,
          onChanged: _switchTab,
          items: List.generate(tabLabels.length, (i) => MBottomNavItem(
                icon: tabIcons[i],
                activeIcon: tabActiveIcons[i],
                label: tabLabels[i],
                badge: i == 4 ? unread : 0,
              )),
        ),
      ),
    );
  }
}

// ============== Wide layout: sidebar 240px + main content ==============

class _SVWideLayout extends ConsumerWidget {
  final List<Widget> tabs;
  final List<String> tabLabels;
  final List<IconData> tabIcons;
  final List<IconData> tabActiveIcons;
  final int unread;
  final int activeIdx;
  final ValueChanged<int> onSwitchTab;

  const _SVWideLayout({
    required this.tabs,
    required this.tabLabels,
    required this.tabIcons,
    required this.tabActiveIcons,
    required this.unread,
    required this.activeIdx,
    required this.onSwitchTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: ptitRed)));
    }
    final initial = user.fullName.isNotEmpty
        ? user.fullName.split(' ').last.substring(0, 1).toUpperCase()
        : 'S';

    return Scaffold(
      backgroundColor: appBg,
      body: Row(children: [
        // Sidebar 240px
        Container(
          width: 240,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: cardBorder)),
          ),
          child: Column(children: [
            // Brand
            Container(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: cardBorder)),
              ),
              child: Row(children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: ptitRed,
                    borderRadius: BorderRadius.circular(8),
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
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        Text('Sinh viên',
                            style: TextStyle(color: textMuted, fontSize: 10)),
                      ]),
                ),
              ]),
            ),
            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: List.generate(tabLabels.length, (i) {
                  final isActive = i == activeIdx;
                  final showBadge = i == 4 && unread > 0;
                  return InkWell(
                    onTap: () => onSwitchTab(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? ptitRedSoft : null,
                        border: Border(
                          left: BorderSide(
                            color: isActive ? ptitRed : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(children: [
                        Icon(isActive ? tabActiveIcons[i] : tabIcons[i],
                            size: 18, color: isActive ? ptitRed : textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(tabLabels[i],
                              style: TextStyle(
                                fontSize: 13,
                                color: isActive ? ptitRed : textPrimary,
                                fontWeight: isActive
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              )),
                        ),
                        if (showBadge)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: ptitRed,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text('$unread',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                      ]),
                    ),
                  );
                }),
              ),
            ),
            // Footer user
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: cardBorder)),
              ),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                      color: ptitRedSoft, shape: BoxShape.circle),
                  child: Center(
                    child: Text(initial,
                        style: const TextStyle(
                            color: ptitRed,
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
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
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(user.email,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: textMuted, fontSize: 10)),
                      ]),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, size: 16, color: textMuted),
                  tooltip: 'Đăng xuất',
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
              ]),
            ),
          ]),
        ),
        // Main content — center align with max-width để không quá rộng
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: IndexedStack(index: activeIdx, children: tabs),
            ),
          ),
        ),
      ]),
    );
  }
}
