import 'package:dio/dio.dart';

import 'config.dart';
import 'secure_storage.dart';

/// Dio singleton với interceptor tự attach JWT + handle 401.
class ApiClient {
  final TokenStorage _storage;
  late final Dio dio;

  ApiClient(this._storage) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.api,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (err, handler) async {
        if (err.response?.statusCode == 401) {
          await _storage.clearToken();
        }
        handler.next(err);
      },
    ));
  }
}
