import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/m_bottom_nav.dart';
import '../../core/widgets/mobile_frame.dart';
import 'contest_list_screen.dart';
import 'home_screen.dart';
import 'my_registrations_screen.dart';
import 'my_results_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class StudentShell extends ConsumerStatefulWidget {
  const StudentShell({super.key});
  @override
  ConsumerState<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends ConsumerState<StudentShell> {
  int _idx = 0;

  void _switchTab(int i) => setState(() => _idx = i);

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      HomeScreen(onSwitchTab: _switchTab),
      const ContestListScreen(),
      const MyRegistrationsScreen(),
      const MyResultsScreen(),
      const NotificationsScreen(),
      const ProfileScreen(),
    ];

    // Badge unread count cho tab Thông báo
    final asyncNotifs = ref.watch(notificationsProvider);
    final unread = asyncNotifs.maybeWhen(
      data: (d) => d['unread_count'] as int? ?? 0,
      orElse: () => 0,
    );

    return MobileFrame(
      child: Scaffold(
        body: IndexedStack(index: _idx, children: tabs),
        bottomNavigationBar: MBottomNav(
          selectedIndex: _idx,
          onChanged: (i) => setState(() => _idx = i),
          items: [
            const MBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Trang chủ'),
            const MBottomNavItem(icon: Icons.emoji_events_outlined, activeIcon: Icons.emoji_events, label: 'Cuộc thi'),
            const MBottomNavItem(icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt, label: 'Của tôi'),
            const MBottomNavItem(icon: Icons.workspace_premium_outlined, activeIcon: Icons.workspace_premium, label: 'Kết quả'),
            MBottomNavItem(
                icon: Icons.notifications_outlined,
                activeIcon: Icons.notifications,
                label: 'Thông báo',
                badge: unread),
            const MBottomNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Tôi'),
          ],
        ),
      ),
    );
  }
}
