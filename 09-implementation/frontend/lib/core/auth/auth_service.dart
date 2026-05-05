import 'package:dio/dio.dart';

import '../api_client.dart';
import '../models/user.dart';
import '../secure_storage.dart';

class AuthService {
  final ApiClient _api;
  final TokenStorage _storage;

  AuthService(this._api, this._storage);

  /// POST /api/auth/login. Returns access token + saves to storage.
  Future<String> login(String email, String password) async {
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final token = res.data['access_token'] as String;
    await _storage.saveToken(token);
    return token;
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
      // ignore — clearing token below sẽ vẫn logout local
    }
    await _storage.clearToken();
  }

  Future<bool> hasToken() async {
    final t = await _storage.readToken();
    return t != null && t.isNotEmpty;
  }
}
