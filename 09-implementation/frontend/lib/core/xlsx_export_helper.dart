// Sprint 6 (2026-05-07): generic helper xuất xlsx từ endpoint bất kỳ.
//
// Reuse cho GV-07 (`/contests/{id}/report.xlsx`), BCN-05 (`/reports/faculty-summary.xlsx`),
// AD-05 (`/admin/reports/system-summary.xlsx`) — chung cùng pattern: GET binary,
// đọc Content-Disposition để lấy filename, gọi `downloadBytesAsFile` (web) hoặc
// fallback message (mobile).
//
// Pattern giống `_exportXlsx()` trong contest_admin_detail_screen.dart (export kết
// quả contest) — gom về 1 chỗ để các màn admin/HOD chỉ cần gọi 1 hàm.

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'download_helper.dart';

String _msgOf(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['detail'] != null) return d['detail'].toString();
    if (d is String) return d;
    return e.message ?? 'Lỗi mạng';
  }
  return e.toString();
}

/// Tải file xlsx từ một endpoint API (đã authenticated qua Dio interceptor).
///
/// - [dio]: Dio instance đã có baseUrl + Authorization header.
/// - [path]: relative path (vd `/contests/123/report.xlsx`).
/// - [fallbackFilename]: dùng khi server không trả Content-Disposition.
/// - [queryParameters]: optional query (vd `{year: 2026}`).
///
/// Show snackbar tiến trình + lỗi user-friendly. Web sẽ trigger browser download,
/// mobile show "chỉ hỗ trợ trên web" message.
Future<void> exportXlsxFromEndpoint({
  required BuildContext context,
  required Dio dio,
  required String path,
  required String fallbackFilename,
  Map<String, dynamic>? queryParameters,
}) async {
  try {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Đang chuẩn bị file Excel...'),
      duration: Duration(seconds: 1),
    ));
    final res = await dio.get<List<int>>(
      path,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.bytes),
    );
    if (!context.mounted) return;
    final bytes = Uint8List.fromList(res.data!);

    String filename = fallbackFilename;
    final cd = res.headers.value('content-disposition');
    if (cd != null) {
      final m = RegExp(r'filename="?([^"]+)"?').firstMatch(cd);
      if (m != null) filename = m.group(1)!;
    }

    try {
      downloadBytesAsFile(
        bytes,
        filename,
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Đã tải về: $filename'),
        backgroundColor: context.successGreen,
      ));
    } on UnsupportedError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Không hỗ trợ trên platform này')),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Lỗi xuất Excel: ${_msgOf(e)}')),
    );
  }
}
