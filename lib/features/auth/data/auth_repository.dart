import 'package:dio/dio.dart';

abstract class AuthRepository {
  /// Trả về JWT token.
  Future<String> login({required String email, required String password});

  Future<void> register({
    required String email,
    required String password,
    required String repeatPassword,
    required String firstName,
    required String lastName,
    String? shippingAddress,
  });
}

/// Dữ liệu giả: email/mật khẩu nào cũng đăng nhập được.
/// Email bắt đầu bằng "admin" nhận token quản trị (thử đăng nhập quản trị viên).
class MockAuthRepository implements AuthRepository {
  @override
  Future<String> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return email.toLowerCase().startsWith('admin') ? 'mock-admin-token' : 'mock-token';
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String repeatPassword,
    required String firstName,
    required String lastName,
    String? shippingAddress,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
  }
}

/// Gọi backend thật.
/// TODO: mở Swagger để đối chiếu tên field (email hay username, có repeatPassword không...).
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._dio);

  final Dio _dio;

  @override
  Future<String> login({required String email, required String password}) async {
    final res = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    final token = (res.data as Map<String, dynamic>)['token'];
    if (token is! String) {
      throw Exception('Phản hồi đăng nhập không có token');
    }
    return token;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
    required String repeatPassword,
    required String firstName,
    required String lastName,
    String? shippingAddress,
  }) async {
    await _dio.post('/auth/registration', data: {
      'email': email,
      'password': password,
      'repeatPassword': repeatPassword,
      'firstName': firstName,
      'lastName': lastName,
      'shippingAddress': shippingAddress,
    });
  }
}
