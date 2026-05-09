// Sub-route wrapper — Sprint 20++ (2026-05-09):
//   - Render sidebar grouped 3 nhóm + Pattern B collapse 240↔64 đồng bộ với
//     student_shell.dart (cùng SharedPreferences key 'student.sidebar_collapsed')
//   - Click sidebar item → setTab studentTabProvider + go('/') → quay về shell
//
// Dùng cho /contests/:slug, /contests/:slug/register, /rounds/:roundId/submit.
// Mobile/APK: render child raw (existing behavior).

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/auth/auth_provider.dart';
import '../../core/spacing.dart';
import '../../core/theme.dart';
import '../../core/theme_provider.dart';
import 'student_shell.dart'
    show
        studentTabProvider,
        StudentNavItem,
        buildStudentNavGroups;

const String _kSidebarCollapsedKey = 'student.sidebar_collapsed';
const double _kSidebarExpandedWidth = 240;
const double _kSidebarRailWidth = 64;
const Duration _kSidebarAnim = Duration(milliseconds: 220);

class StudentShellScaffold extends ConsumerWidget {
  /// Child screen — full Scaffold của contest detail / register / submission.
  final Widget child;

  /// Hint tab nào active trong sidebar khi user đang ở sub-route.
  /// 1 = "Cuộc thi", 2 = "Đã đăng ký". Null = không highlight.
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

    if (!useWideLayout) {
      return child;
    }

    return _SVSubRouteWideLayout(
      activeTabHint: activeTabHint,
      child: child,
    );
  }
}

class _SVSubRouteWideLayout extends ConsumerStatefulWidget {
  final Widget child;
  final int? activeTabHint;

  const _SVSubRouteWideLayout({
    required this.child,
    required this.activeTabHint,
  });

  @override
  ConsumerState<_SVSubRouteWideLayout> createState() =>
      _SVSubRouteWideLayoutState();
}

class _SVSubRouteWideLayoutState
    extends ConsumerState<_SVSubRouteWideLayout> {
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
        body: Center(child: CircularProgressIndicator(color: ptitRed)),
      );
    }
    final initial = user.fullName.isNotEmpty
        ? user.fullName.split(' ').last.substring(0, 1).toUpperCase()
        : 'S';
    final groups = buildStudentNavGroups();

    void onClickItem(StudentNavItem item) {
      ref.read(studentTabProvider.notifier).state = item.tabIndex;
      context.go('/');
    }

    return Scaffold(
      body: Row(children: [
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
            if (_collapsed)
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.s8),
                child: Center(
                  child: _SidebarToggleButton(
                      collapsed: _collapsed, onTap: _toggleCollapsed),
                ),
              ),
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
                        isActive: item.tabIndex == widget.activeTabHint,
                        collapsed: _collapsed,
                        onTap: () => onClickItem(item),
                      ),
                    const SizedBox(height: AppSpacing.s12),
                  ],
                ],
              ),
            ),
            _SidebarFooter(
              collapsed: _collapsed,
              initial: initial,
              fullName: user.fullName,
              studentCode: _studentCodeFromEmail(user.email),
              onLogout: () => ref.read(authProvider.notifier).logout(),
            ),
          ]),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: widget.child,
            ),
          ),
        ),
      ]),
    );
  }
}

// ============== Reusable widgets (duplicate from student_shell.dart) ==============

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
