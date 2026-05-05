/// Token storage — works on web (localStorage, kể cả non-HTTPS context như LAN IP)
/// + mobile (Keychain/Keystore qua flutter_secure_storage).
///
/// Note: Trên Flutter web qua IP LAN (không HTTPS), Service Worker bị disable nên
/// flutter_secure_storage không hoạt động. Fallback localStorage (kém bảo mật hơn,
/// nhưng đủ cho dev / demo).
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class TokenStorage {
  static const _kAccessToken = 'jwt_access_token';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> saveToken(String token) async {
    if (kIsWeb) {
      html.window.localStorage[_kAccessToken] = token;
      return;
    }
    return _storage.write(key: _kAccessToken, value: token);
  }

  Future<String?> readToken() async {
    if (kIsWeb) {
      return html.window.localStorage[_kAccessToken];
    }
    return _storage.read(key: _kAccessToken);
  }

  Future<void> clearToken() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_kAccessToken);
      return;
    }
    return _storage.delete(key: _kAccessToken);
  }
}
