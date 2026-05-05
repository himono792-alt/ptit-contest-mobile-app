// Web implementation — dùng dart:html để window.open URL render cert HTML trong tab mới.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool openCertUrl(String url) {
  try {
    html.window.open(url, '_blank');
    return true;
  } catch (_) {
    return false;
  }
}
