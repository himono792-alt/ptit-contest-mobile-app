// Web implementation cho storage fallback.
// Sprint 28 hotfix #6 (2026-05-10): support cả localStorage (persistent qua
// browser restart) lẫn sessionStorage (mất khi đóng tab) để honor "Ghi nhớ tôi".
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class LocalWebStorage {
  /// Đọc key — ưu tiên sessionStorage (login session hiện tại) trước khi
  /// fallback localStorage (login persistent từ session trước). Nhờ vậy nếu
  /// user logout + login lại với "Ghi nhớ tôi" off → token mới ở session,
  /// token cũ persistent đã clear khi write opposite.
  String? read(String key) {
    final s = html.window.sessionStorage[key];
    if (s != null) return s;
    return html.window.localStorage[key];
  }

  /// Ghi key.
  /// - `persistent: true` → localStorage (mặc định) → giữ qua browser restart.
  /// - `persistent: false` → sessionStorage → mất khi đóng tab.
  /// Luôn clear opposite storage để tránh stale token leak ngược.
  void write(String key, String value, {bool persistent = true}) {
    if (persistent) {
      html.window.localStorage[key] = value;
      html.window.sessionStorage.remove(key);
    } else {
      html.window.sessionStorage[key] = value;
      html.window.localStorage.remove(key);
    }
  }

  /// Xóa key khỏi cả 2 storage.
  void remove(String key) {
    html.window.localStorage.remove(key);
    html.window.sessionStorage.remove(key);
  }
}

LocalWebStorage get webStorage => LocalWebStorage();
