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
  // Phase 2 sprint 1 step 4 (2026-05-06): biometric login support
  // - Refresh token TTL 7 ngày, lưu encrypted để biometric unlock dùng
  // - biometric_enabled flag: user toggle trong Profile (default off, opt-in)
  static const _kRefreshToken = 'jwt_refresh_token';
  static const _kBiometricEnabled = 'biometric_enabled';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ---------- Access token ----------

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

  // ---------- Refresh token (Phase 2 step 4) ----------

  Future<void> saveRefreshToken(String token) async {
    if (kIsWeb) {
      webStorage.write(_kRefreshToken, token);
      return;
    }
    return _storage.write(key: _kRefreshToken, value: token);
  }

  Future<String?> readRefreshToken() async {
    if (kIsWeb) {
      return webStorage.read(_kRefreshToken);
    }
    return _storage.read(key: _kRefreshToken);
  }

  Future<void> clearRefreshToken() async {
    if (kIsWeb) {
      webStorage.remove(_kRefreshToken);
      return;
    }
    return _storage.delete(key: _kRefreshToken);
  }

  // ---------- Biometric flag (Phase 2 step 4) ----------

  Future<void> setBiometricEnabled(bool enabled) async {
    final value = enabled ? '1' : '0';
    if (kIsWeb) {
      webStorage.write(_kBiometricEnabled, value);
      return;
    }
    return _storage.write(key: _kBiometricEnabled, value: value);
  }

  Future<bool> isBiometricEnabled() async {
    final v = kIsWeb
        ? webStorage.read(_kBiometricEnabled)
        : await _storage.read(key: _kBiometricEnabled);
    return v == '1';
  }

  /// Logout: clear cả access + refresh + biometric flag.
  Future<void> clearAll() async {
    await clearToken();
    await clearRefreshToken();
    if (kIsWeb) {
      webStorage.remove(_kBiometricEnabled);
    } else {
      await _storage.delete(key: _kBiometricEnabled);
    }
  }
}
