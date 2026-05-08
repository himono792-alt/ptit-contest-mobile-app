import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_shell.dart';
import '../features/admin/contest_admin_detail_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/student/contest_detail_screen.dart';
import '../features/student/leaderboard_screen.dart';
import '../features/student/register_screen.dart';
import '../features/student/student_shell.dart';
import '../features/student/student_shell_scaffold.dart';
import '../features/student/submission_screen.dart';
import '../core/models/contest_detail.dart';
import '../core/models/user.dart';
import 'auth/auth_provider.dart';

/// Role nào có quyền vào /admin (web sidebar shell).
bool _canAccessAdmin(UserModel u) =>
    u.isAdmin || u.isOrganizer || u.isJudge || u.isHod;

/// Mặc định landing page sau khi login dựa theo roles.
String _landingFor(UserModel u) {
  if (_canAccessAdmin(u)) return '/admin';
  return '/'; // Student shell
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.listen<dynamic>(authProvider, (_, __) => notifier.value++);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (auth.isLoading) return null;

      final loc = state.matchedLocation;
      // Sprint 9 Group 1 (2026-05-07): /otp-login + /signup được phép truy cập
      // KHI chưa login (giống /login). Khi đã login mà mò vào → đẩy về landing.
      final isAuthEntry = loc == '/login' || loc == '/otp-login' || loc == '/signup';
      final user = auth.value;

      // Chưa login → chỉ cho phép entry login/signup/otp-login.
      if (user == null) {
        return isAuthEntry ? null : '/login';
      }

      // Đã login mà còn ở entry → đẩy về landing theo role.
      if (isAuthEntry) return _landingFor(user);

      // Role guard: SV thuần (không có quyền admin) mà mò vào /admin → quay về /
      if (loc.startsWith('/admin') && !_canAccessAdmin(user)) {
        return '/';
      }

      // Ngược lại: user chỉ có quyền admin (không phải STUDENT) mà vào / → đẩy /admin
      if ((loc == '/' || loc == '') && !user.isStudent && _canAccessAdmin(user)) {
        return '/admin';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const StudentShell()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminShell()),
      // Sprint 8 fix #2 (2026-05-07): deep-link /admin/<tab> như /admin/contests,
      // /admin/users... Trước đây F5 hoặc share-link 404. Slug whitelist để tránh
      // /admin/<garbage> match nhầm — fallback Dashboard cho UX tốt hơn 404.
      // Pattern 2 segment '/admin/:tab' KHÔNG conflict với 4-segment
      // '/admin/contests/:id/manage' bên dưới (GoRouter match by path-length).
      GoRoute(
        path: '/admin/:tab',
        builder: (_, state) {
          final tab = state.pathParameters['tab'];
          // Sprint 14 (2026-05-08): split approvals → approvals-q1 / approvals-q2.
          // + thêm contests-new (P2.2 GV Tạo cuộc thi sidebar) + backup (P2.1).
          const allowed = {
            'dashboard', 'contests', 'contests-new',
            'approvals-q1', 'approvals-q2',
            'monitor', 'judge',
            'users', 'master-data', 'reviews',
            'configs', 'backup', 'audit-log', 'anomaly',
          };
          final initialTab = allowed.contains(tab) ? tab : null;
          return AdminShell(initialTab: initialTab);
        },
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      // Sprint 9 Group 1 (2026-05-07): OTP passwordless login + self-signup.
      GoRoute(path: '/otp-login', builder: (_, __) => const OtpLoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      // Sprint 2 fix C3+M1 (2026-05-06): wrap 3 sub-routes vào StudentShellScaffold
      // để desktop ≥900px hiện sidebar (consistency với shell chính). Mobile/APK
      // vẫn render child raw (existing back-arrow behavior).
      // activeTabHint: 1=Cuộc thi, 2=Của tôi → highlight tab tương ứng trong sidebar.
      GoRoute(
        path: '/contests/:slug',
        builder: (_, state) => StudentShellScaffold(
          activeTabHint: 1, // Cuộc thi
          child: ContestDetailScreen(slug: state.pathParameters['slug']!),
        ),
      ),
      GoRoute(
        path: '/admin/contests/:id/manage',
        builder: (_, state) => ContestAdminDetailScreen(
          contestId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/contests/:slug/register',
        builder: (_, state) => StudentShellScaffold(
          activeTabHint: 1, // Cuộc thi
          child: RegisterContestScreen(contest: state.extra as ContestDetail),
        ),
      ),
      GoRoute(
        path: '/rounds/:roundId/submit',
        builder: (_, state) => StudentShellScaffold(
          activeTabHint: 2, // Của tôi
          child: SubmissionScreen(
              roundId: int.parse(state.pathParameters['roundId']!)),
        ),
      ),
      // Sprint 16 (2026-05-08): Leaderboard SV.
      // Path /contests/:contestId/leaderboard tránh đụng /:slug.
      // contestId là int — extra: contest title (string) optional.
      GoRoute(
        path: '/contests/:contestId/leaderboard',
        builder: (_, state) => StudentShellScaffold(
          activeTabHint: 1,
          child: LeaderboardScreen(
            contestId: int.parse(state.pathParameters['contestId']!),
            contestTitle: (state.extra as String?) ?? 'Cuộc thi',
          ),
        ),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('Lỗi')),
      body: Center(child: Text('Không tìm thấy: ${state.uri}')),
    ),
  );
});
