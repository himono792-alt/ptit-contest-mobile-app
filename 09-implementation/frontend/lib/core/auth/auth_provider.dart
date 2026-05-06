import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_client.dart';
import '../models/user.dart';
import '../secure_storage.dart';
import 'auth_service.dart';
import 'biometric_service.dart';

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

  /// Phase 2 sprint 1 step 4 (2026-05-06): unlock app bằng biometric.
  /// Flow: prompt FaceID/TouchID → success → call /auth/refresh → set state user.
  ///
  /// Trả true nếu login thành công (caller redirect vào app), false nếu:
  /// - Biometric không available trên device
  /// - User cancel biometric prompt
  /// - Refresh token hết hạn / invalid
  ///
  /// Caller (LoginScreen / main startup) fallback login form khi trả false.
  Future<bool> tryBiometricLogin() async {
    final storage = ref.read(tokenStorageProvider);

    // Pre-check: biometric phải enabled + có refresh token + device support
    if (!await storage.isBiometricEnabled()) return false;
    final refresh = await storage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;
    if (!await BiometricService.instance.isAvailable()) return false;

    // Prompt biometric
    final ok = await BiometricService.instance.authenticate(
      reason: 'Mở khóa PTIT Contest',
    );
    if (!ok) return false;

    // Authenticated → exchange refresh → access token + load user
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final svc = ref.read(authServiceProvider);
      final refreshed = await svc.loginWithRefresh();
      if (!refreshed) {
        throw const _BiometricRefreshFailedException();
      }
      return await svc.me();
    });
    return state.hasValue && state.value != null;
  }
}

class _BiometricRefreshFailedException implements Exception {
  const _BiometricRefreshFailedException();
  @override
  String toString() => 'Refresh token đã hết hạn, vui lòng đăng nhập lại.';
}

final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);
