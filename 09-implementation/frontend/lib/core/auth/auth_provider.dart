import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_client.dart';
import '../models/user.dart';
import '../secure_storage.dart';
import 'auth_service.dart';

// Service singletons
final tokenStorageProvider = Provider<TokenStorage>((_) => TokenStorage());
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(apiClientProvider), ref.watch(tokenStorageProvider));
});

/// Auth state — null = anonymous, UserModel = logged in.
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    final svc = ref.read(authServiceProvider);
    if (!await svc.hasToken()) return null;
    try {
      return await svc.me();
    } on DioException {
      // Token invalid/expired → cleared by interceptor
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final svc = ref.read(authServiceProvider);
      await svc.login(email, password);
      return await svc.me();
    });
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logout();
    state = const AsyncData(null);
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
