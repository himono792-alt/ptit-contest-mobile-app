import 'package:dio/dio.dart';

/// Map lỗi kỹ thuật → tiếng Việt thân thiện, có gợi ý hành động.
/// Help users recognize and recover from errors (Nielsen H9, H2).
class FriendlyError {
  FriendlyError._();

  static String of(Object error) {
    if (error is DioException) return _dio(error);
    return 'Có lỗi xảy ra. Vui lòng thử lại.';
  }

  static String _dio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Kết nối quá chậm. Kiểm tra mạng rồi thử lại.';
      case DioExceptionType.connectionError:
        return 'Không kết nối được máy chủ. Kiểm tra mạng hoặc thử lại sau.';
      default:
        break;
    }
    final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
    final status = e.response?.statusCode ?? 0;
    return switch (status) {
      400 => detail is String ? detail : 'Dữ liệu chưa hợp lệ. Kiểm tra lại các trường.',
      401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      403 => detail is String ? detail : 'Bạn không có quyền thực hiện thao tác này.',
      404 => 'Không tìm thấy nội dung. Có thể đã bị xóa hoặc di chuyển.',
      409 => detail is String ? detail : 'Thao tác bị trùng hoặc xung đột trạng thái.',
      422 => detail is String ? detail : 'Dữ liệu chưa đúng định dạng yêu cầu.',
      >= 500 => 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau ít phút.',
      _ => detail is String ? detail : 'Có lỗi xảy ra. Vui lòng thử lại.',
    };
  }
}
