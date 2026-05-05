/// Runtime config — sửa API_BASE_URL khi deploy.
///
/// Truyền lúc chạy:
///   flutter run --dart-define=API_BASE=http://192.168.1.42:8000
///
/// Hoặc sửa default `_defaultBase` rồi rebuild:
///   - Local web dev:        http://localhost:8000
///   - LAN test (iPhone):    http://<windows-lan-ip>:8000
///   - Android emulator:     http://10.0.2.2:8000
class AppConfig {
  static const String _defaultBase = 'http://localhost:8000';

  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE', defaultValue: _defaultBase);

  static const String apiPrefix = '/api';
  static String get api => '$apiBaseUrl$apiPrefix';
}
