/// Token storage — works on web (localStorage, kể cả non-HTTPS context như LAN IP)
/// + mobile (Keychain/Keystore qua flutter_secure_storage).
///
/// Note: Trên Flutter web qua IP LAN (không HTTPS), Service Worker bị disable nên
/// flutter_secure_storage không hoạt động. Fallback localStorage (kém bảo mật hơn,
/// nhưng đủ cho dev / demo).
///
/// Conditional import: `dart:html` chỉ load trên web để APK build không crash.
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'local_storage_stub.dart' if (dart.library.html) 'local_storage_web.dart';

class TokenStorage {
  static const _kAccessToken = 'jwt_access_token';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      webStorage.write(_kAccessToken, token);
      return;
    }
    return _storage.write(key: _kAccessToken, value: token);
  }

  Future<String?> readToken() async {
    if (kIsWeb) {
      return webStorage.read(_kAccessToken);
    }
    return _storage.read(key: _kAccessToken);
  }

  Future<void> clearToken() async {
    if (kIsWeb) {
      webStorage.remove(_kAccessToken);
      return;
    }
    return _storage.delete(key: _kAccessToken);
  }
}
