import 'package:nookbook/features/orders/domain/payment_method.dart';

/// Kết quả vừa đặt hàng, truyền sang trang chuyển khoản / đặt hàng thành công.
class PlacedOrder {
  const PlacedOrder({
    required this.orderId,
    required this.total,
    required this.method,
    required this.expectedFrom,
    required this.expectedTo,
  });

  final int orderId;

  /// Đã gồm phí giao hàng.
  final double total;
  final PaymentMethod method;
  final DateTime expectedFrom;
  final DateTime expectedTo;
}
