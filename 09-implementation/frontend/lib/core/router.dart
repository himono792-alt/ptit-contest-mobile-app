import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_shell.dart';
import '../features/admin/contest_admin_detail_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
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
      final loc = state.matchedLocation;

      // Sprint 19 fix flicker (2026-05-08): trong khi auth chưa resolve,
      // redirect tất cả route → /splash để tránh flicker StudentShell brief
      // trên Android. Khi auth resolve, splash sẽ tự bị redirect đi.
      if (auth.isLoading) {
        return loc == '/splash' ? null : '/splash';
      }
      // Auth đã resolve nhưng còn ở /splash → redirect đi (login hoặc landing)
      if (loc == '/splash') {
        final user = auth.value;
        if (user == null) {
          return onboardingCompletedFlag.value ? '/login' : '/onboarding';
        }
        return _landingFor(user);
      }
      // Sprint 9 Group 1 (2026-05-07): /otp-login + /signup được phép truy cập
      // KHI chưa login (giống /login). Khi đã login mà mò vào → đẩy về landing.
      // Sprint 19 (2026-05-08) S19-3: thêm /onboarding vào auth entry list.
      final isAuthEntry = loc == '/login' ||
          loc == '/otp-login' ||
          loc == '/signup' ||
          loc == '/onboarding';
      final user = auth.value;

      // Chưa login → check onboarding trước, sau đó cho phép auth entries.
      if (user == null) {
        // Sprint 19: lần đầu mở app + chưa onboarding → redirect /onboarding.
        // Trừ khi user đang ở /onboarding rồi (tránh loop).
        if (!onboardingCompletedFlag.value && loc != '/onboarding') {
          return '/onboarding';
        }
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
      // Sprint 19 hotfix #4 (2026-05-08): NoTransitionPage cho /admin + /admin/:tab.
      // Khi user click tab sidebar/bottom nav, switchTab() gọi context.go() update URL.
      // Nếu dùng builder mặc định, GoRouter push MaterialPage mới với slide animation
      // → "cửa sổ chèn lên" khi chuyển tab. NoTransitionPage giữ shell instance,
      // chỉ swap activeScreen sub-tree, instant switch như Linear/Notion.
      GoRoute(
        path: '/admin',
        pageBuilder: (_, __) =>
            const NoTransitionPage(child: AdminShell()),
      ),
      // Sprint 8 fix #2 (2026-05-07): deep-link /admin/<tab> như /admin/contests,
      // /admin/users... Trước đây F5 hoặc share-link 404. Slug whitelist để tránh
      // /admin/<garbage> match nhầm — fallback Dashboard cho UX tốt hơn 404.
      // Pattern 2 segment '/admin/:tab' KHÔNG conflict với 4-segment
      // '/admin/contests/:id/manage' bên dưới (GoRouter match by path-length).
      GoRoute(
        path: '/admin/:tab',
        pageBuilder: (_, state) {
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
          return NoTransitionPage(child: AdminShell(initialTab: initialTab));
        },
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      // Sprint 9 Group 1 (2026-05-07): OTP passwordless login + self-signup.
      GoRoute(path: '/otp-login', builder: (_, __) => const OtpLoginScreen()),
      GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
      // Sprint 19 (2026-05-08) S19-3: mobile onboarding 3 slides.
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
      // Sprint 19 fix flicker (2026-05-08): splash trung gian khi auth boot.
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
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
