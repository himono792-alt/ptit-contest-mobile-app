// Conditional export — web build dùng download_helper_web, mobile dùng stub.
//
// Phase 2 sprint 1 step 3 (2026-05-06): util download bytes (xlsx, pdf...) cho
// Excel export. Pattern giống secure_storage.dart đã có sẵn project.

export 'download_helper_stub.dart'
    if (dart.library.html) 'download_helper_web.dart';
