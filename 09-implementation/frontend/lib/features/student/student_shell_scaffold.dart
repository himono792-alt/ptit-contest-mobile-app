// Sprint 2 fix C3+M1 (2026-05-06): wrap sub-routes /contests/:slug,
// /contests/:slug/register, /rounds/:roundId/submit vào StudentShell sidebar
// trên desktop ≥900px. Mobile vẫn render child raw (existing behavior với
// back arrow trong AppBar của child screen).
//
// Tại sao tách file riêng (KHÔNG sửa student_shell.dart):
// - student_shell.dart dùng IndexedStack 6 tabs hardcoded → refactor lớn risk cao
// - File này tạo wrapper riêng, accept 1 child Widget → sub-route compose dễ
// - Sidebar code duplicate ~100 LOC chấp nhận để giảm risk break shell chính
//
// Khi click sidebar item từ sub-route → set studentTabProvider + go('/') để
// quay về tab tương ứng trong shell chính.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/theme.dart';
import 'notifications_screen.dart' show notificationsProvider;
import 'student_shell.dart' show studentTabProvider;

class StudentShellScaffold extends ConsumerWidget {
  /// Child screen — full Scaffold của contest detail / register / submission.
  /// Wrapper sẽ render sidebar bên trái (desktop) hoặc trả raw (mobile).
  final Widget child;

  /// Hint tab nào active trong sidebar khi user đang ở sub-route.
  /// 1 = "Cuộc thi" (cho contest detail + register), 2 = "Của tôi" (cho submission).
  /// Null = không highlight tab nào.
  final int? activeTabHint;

  const StudentShellScaffold({
    super.key,
    required this.child,
    this.activeTabHint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final useWideLayout = kIsWeb && width >= 900;

    // Mobile / APK / web narrow: child render full screen (existing behavior).
    // Child screen tự có AppBar với back arrow nên không cần thêm chrome.
    if (!useWideLayout) {
      return child;
    }

    // Desktop ≥900px: sidebar 240px + main = child.
    return _SVSubRouteWideLayout(
      child: child,
      activeTabHint: activeTabHint,
    );
  }
}

class _SVSubRouteWideLayout extends ConsumerWidget {
  final Widget child;
  final int? activeTabHint;

  const _SVSubRouteWideLayout({
    required this.child,
    required this.activeTabHint,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: ptitRed)),
      );
    }
    final initial = user.fullName.isNotEmpty
        ? user.fullName.split(' ').last.substring(0, 1).toUpperCase()
        : 'S';

    final asyncNotifs = ref.watch(notificationsProvider);
    final unread = asyncNotifs.maybeWhen(
      data: (d) => d['unread_count'] as int? ?? 0,
      orElse: () => 0,
    );

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

    // Click sidebar item từ sub-route: set tab provider + quay về '/' shell.
    void onSwitchTab(int i) {
      ref.read(studentTabProvider.notifier).state = i;
      context.go('/');
    }

    return Scaffold(
      body: Row(children: [
        // ============== Sidebar 240px ==============
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(children: [
            // Brand header
            Container(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: context.cardBorder)),
              ),
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
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PTIT Contest',
                            style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w800)),
                        Text('Sinh viên',
                            style: TextStyle(color: context.textMuted, fontSize: 10)),
                      ]),
                ),
              ]),
            ),
            // Nav items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: List.generate(tabLabels.length, (i) {
                  final isActive = i == activeTabHint;
                  final showBadge = i == 4 && unread > 0;
                  // Sprint 3 a11y (2026-05-07): wrap sidebar item bằng Semantics.
                  final badgeText = showBadge ? ', $unread thông báo chưa đọc' : '';
                  return Semantics(
                    label: '${tabLabels[i]}$badgeText',
                    button: true,
                    selected: isActive,
                    hint: isActive ? 'Đang ở mục này' : 'Chuyển sang mục ${tabLabels[i]}',
                    child: InkWell(
                    excludeFromSemantics: true,
                    onTap: () => onSwitchTab(i),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive ? context.ptitRedSoft : null,
                        border: Border(
                          left: BorderSide(
                            color: isActive ? ptitRed : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                      child: Row(children: [
                        Icon(isActive ? tabActiveIcons[i] : tabIcons[i],
                            size: 18, color: isActive ? ptitRed : context.textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(tabLabels[i],
                              style: TextStyle(
                                fontSize: 13,
                                color: isActive ? ptitRed : context.textPrimary,
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
                  ),
                  );
                }),
              ),
            ),
            // Footer user
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.cardBorder)),
              ),
              child: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                      color: context.ptitRedSoft, shape: BoxShape.circle),
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
                            style: TextStyle(
                                color: context.textPrimary,
                                fontSize: 12, fontWeight: FontWeight.w700)),
                        Text(user.email,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: context.textMuted, fontSize: 10)),
                      ]),
                ),
                IconButton(
                  icon: Icon(Icons.logout, size: 16, color: context.textMuted),
                  tooltip: 'Đăng xuất',
                  onPressed: () => ref.read(authProvider.notifier).logout(),
                ),
              ]),
            ),
          ]),
        ),
        // ============== Main content = child screen ==============
        // Center align với max-width để không quá rộng (sub-route content
        // thường là form/detail panel, không cần full-width).
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: child,
            ),
          ),
        ),
      ]),
    );
  }
}
