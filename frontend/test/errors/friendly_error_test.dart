import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptit_contest/core/errors/friendly_error.dart';

DioException _resp(int status, {dynamic data}) => DioException(
      requestOptions: RequestOptions(path: '/x'),
      response: Response(
        requestOptions: RequestOptions(path: '/x'),
        statusCode: status,
        data: data,
      ),
    );

DioException _type(DioExceptionType t) =>
    DioException(requestOptions: RequestOptions(path: '/x'), type: t);

void main() {
  test('non-Dio error → generic message', () {
    expect(FriendlyError.of(Exception('boom')), 'Có lỗi xảy ra. Vui lòng thử lại.');
  });

  test('timeout / connection map to network messages', () {
    expect(FriendlyError.of(_type(DioExceptionType.connectionTimeout)),
        contains('quá chậm'));
    expect(FriendlyError.of(_type(DioExceptionType.connectionError)),
        contains('Không kết nối được máy chủ'));
  });

  test('status codes map to friendly text', () {
    expect(FriendlyError.of(_resp(401)), contains('hết hạn'));
    expect(FriendlyError.of(_resp(404)), contains('Không tìm thấy'));
    expect(FriendlyError.of(_resp(500)), contains('Máy chủ'));
    expect(FriendlyError.of(_resp(503)), contains('Máy chủ')); // >=500 branch
  });

  test('backend detail string is surfaced for 400/403/409/422', () {
    for (final s in [400, 403, 409, 422]) {
      expect(FriendlyError.of(_resp(s, data: {'detail': 'msg-$s'})), 'msg-$s');
    }
  });

  test('non-string/missing detail falls back to default for 400', () {
    expect(FriendlyError.of(_resp(400, data: {'detail': 42})),
        'Dữ liệu chưa hợp lệ. Kiểm tra lại các trường.');
    expect(FriendlyError.of(_resp(400, data: 'not-a-map')),
        'Dữ liệu chưa hợp lệ. Kiểm tra lại các trường.');
  });
}
