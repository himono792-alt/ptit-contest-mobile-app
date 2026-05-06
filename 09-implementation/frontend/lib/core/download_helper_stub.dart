// Stub cho mobile/APK — KHÔNG triển khai download (Excel chỉ dùng trên web admin).
// Web build sẽ thay thế bằng download_helper_web.dart qua conditional import.

import 'dart:typed_data';

/// Trigger browser download file. Web only — mobile sẽ throw UnsupportedError.
/// Caller tự catch và show user-friendly message.
void downloadBytesAsFile(Uint8List bytes, String filename, String mimeType) {
  throw UnsupportedError(
    'Download file chỉ hỗ trợ trên web. Trên APK Android, hãy mở trang admin '
    'qua trình duyệt để tải file Excel.',
  );
}
