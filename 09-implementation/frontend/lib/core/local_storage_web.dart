// Web implementation cho localStorage fallback.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class LocalWebStorage {
  String? read(String key) => html.window.localStorage[key];
  void write(String key, String value) {
    html.window.localStorage[key] = value;
  }
  void remove(String key) {
    html.window.localStorage.remove(key);
  }
}

LocalWebStorage get webStorage => LocalWebStorage();
