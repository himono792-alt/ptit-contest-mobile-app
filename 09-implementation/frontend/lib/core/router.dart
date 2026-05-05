import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/admin_shell.dart';
import '../features/auth/login_screen.dart';
import '../features/student/contest_detail_screen.dart';
import '../features/student/register_screen.dart';
import '../features/student/student_shell.dart';
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
      final loggingIn = loc == '/login';
      final user = auth.value;

      // Chưa login → bắt buộc /login
      if (user == null) {
        return loggingIn ? null : '/login';
      }

      // Đã login mà còn ở /login → đẩy về landing theo role
      if (loggingIn) return _landingFor(user);

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
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/contests/:slug',
        builder: (_, state) =>
            ContestDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/contests/:slug/register',
        builder: (_, state) =>
            RegisterContestScreen(contest: state.extra as ContestDetail),
      ),
      GoRoute(
        path: '/rounds/:roundId/submit',
        builder: (_, state) => SubmissionScreen(
            roundId: int.parse(state.pathParameters['roundId']!)),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      appBar: AppBar(title: const Text('Lỗi')),
      body: Center(child: Text('Không tìm thấy: ${state.uri}')),
    ),
  );
});
