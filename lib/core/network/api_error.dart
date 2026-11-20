import 'package:dio/dio.dart';

/// Lỗi do app tự tạo, đã có sẵn câu tiếng Việt để hiện cho người dùng.
class AppException implements Exception {
  const AppException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Đổi lỗi kỹ thuật thành câu tiếng Việt để hiện cho người dùng.
String errorMessage(Object error) {
  if (error is AppException) return error.message;
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    if (data is Map && data['errors'] is List) {
      return (data['errors'] as List).join('\n');
    }
    final status = error.response?.statusCode;
    if (status == 401) return 'Bạn chưa đăng nhập hoặc phiên đã hết hạn.';
    if (status == 403) return 'Bạn không có quyền thực hiện thao tác này.';
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return 'Không kết nối được máy chủ. Hãy kiểm tra backend và địa chỉ API.';
    }
  }
  return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
}
