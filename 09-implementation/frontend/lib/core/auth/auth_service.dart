import 'package:dio/dio.dart';

import '../api_client.dart';
import '../models/user.dart';
import '../secure_storage.dart';

class AuthService {
  final ApiClient _api;
  final TokenStorage _storage;

  AuthService(this._api, this._storage);

  /// POST /api/auth/login. Save cả access token + refresh token vào storage.
  /// Phase 2 step 4 (2026-05-06): refresh token dùng cho biometric unlock lần sau.
  Future<String> login(String email, String password) async {
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final accessToken = res.data['access_token'] as String;
    final refreshToken = res.data['refresh_token'] as String?;
    await _storage.saveToken(accessToken);
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.saveRefreshToken(refreshToken);
    }
    return accessToken;
  }

  /// Phase 2 step 4 (2026-05-06): biometric unlock flow.
  /// Đọc refresh token từ secure storage → POST /auth/refresh → lấy access mới.
  /// Trả true nếu refresh thành công (user vào app); false nếu refresh fail
  /// (token hết hạn 7 ngày hoặc invalid) → caller fallback login form.
  Future<bool> loginWithRefresh() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final res = await _api.dio.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
      final newAccess = res.data['access_token'] as String;
      final newRefresh = res.data['refresh_token'] as String?;
      await _storage.saveToken(newAccess);
      if (newRefresh != null && newRefresh.isNotEmpty) {
        // Sliding window: BE rotate refresh token mỗi lần dùng
        await _storage.saveRefreshToken(newRefresh);
      }
      return true;
    } on DioException {
      // Refresh fail (token expire / revoked) → clear local + caller fallback
      await _storage.clearRefreshToken();
      return false;
    }
  }

  /// GET /api/auth/me — load current user.
  Future<UserModel> me() async {
    final res = await _api.dio.get('/auth/me');
    return UserModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    try {
      await _api.dio.post('/auth/logout');
    } on DioException {
      // ignore — clearing tokens below sẽ vẫn logout local
    }
    // Phase 2 step 4: clear cả refresh token + biometric flag để re-login mới
    await _storage.clearAll();
  }

  Future<bool> hasToken() async {
    final t = await _storage.readToken();
    return t != null && t.isNotEmpty;
  }
}
