import 'package:flutter/foundation.dart';

/// Cấu hình chung của app.
///
/// Chạy với dữ liệu giả (mặc định, không cần backend):
///   flutter run -d chrome
/// Chạy với backend thật:
///   flutter run -d chrome --dart-define=USE_MOCK=false
/// Máy thật / backend ở máy khác (đổi IP cho đúng):
///   flutter run --dart-define=USE_MOCK=false --dart-define=API_BASE_URL=http://192.168.1.10:8088/api
class AppConfig {
  AppConfig._();

  /// true = dùng dữ liệu giả trong code, false = gọi API thật.
  static const bool useMock = bool.fromEnvironment('USE_MOCK', defaultValue: true);

  static const String _overrideBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Địa chỉ backend Spring Boot (có tiền tố /api như trong README của repo).
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) return _overrideBaseUrl;
    if (kIsWeb) return 'http://localhost:8088/api';
    // Android emulator không gọi được "localhost" của máy tính, phải dùng 10.0.2.2.
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8088/api';
    }
    return 'http://localhost:8088/api';
  }

  // ---- Chỉ hiển thị trên giao diện (backend hiện chưa lưu các giá trị này) ----

  /// Phí giao hàng tiêu chuẩn.
  static const double shippingFee = 25000;

  /// Đơn từ mức này trở lên được miễn phí giao hàng.
  static const double freeShippingThreshold = 300000;

  /// Phí giao hàng áp dụng cho một đơn có tạm tính [subtotal].
  static double shippingFeeFor(double subtotal) =>
      (subtotal <= 0 || subtotal >= freeShippingThreshold) ? 0 : shippingFee;

  /// Thông tin tài khoản nhận chuyển khoản (minh họa, đổi thành tài khoản thật).
  static const String bankName = 'Vietcombank';
  static const String bankAccountName = 'NOOKBOOK';
  static const String bankAccountNumber = '102 9988 6688';
}
