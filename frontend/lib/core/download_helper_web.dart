// Web implementation cho download bytes (xlsx, pdf, csv...).
// Pattern giống cert_open_web.dart — dùng dart:html chỉ load trên web build.

// ignore_for_file: avoid_web_libraries_in_flutter
// Lý do: file này chỉ load qua conditional import khi platform là web.
import 'dart:html' as html;
import 'dart:typed_data';

/// Trigger browser download file qua Blob + AnchorElement.click().
/// Phase 2 sprint 1 step 3 (2026-05-06): dùng cho Export Excel results.
void downloadBytesAsFile(Uint8List bytes, String filename, String mimeType) {
  final blob = html.Blob(<dynamic>[bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  // Cleanup blob URL sau ~100ms để browser kịp trigger download
  Future.delayed(const Duration(milliseconds: 100), () {
    html.Url.revokeObjectUrl(url);
  });
}
