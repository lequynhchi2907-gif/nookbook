import 'package:nookbook/core/config/app_config.dart';
import 'package:nookbook/core/widgets/status_chip.dart';

/// Phí giao hàng hiển thị cho đơn có tạm tính [subtotal] (chỉ trên giao diện).
double orderShippingFee(double subtotal) => AppConfig.shippingFeeFor(subtotal);

/// Backend lưu trạng thái đơn dưới dạng chuỗi (enum). Gom về 3 trạng thái của thiết kế.
OrderStatus parseOrderStatus(String? raw) {
  final s = (raw ?? '').toUpperCase();
  if (s.contains('DELIVERED') || s.contains('COMPLETE')) return OrderStatus.delivered;
  if (s.contains('SHIP') || s.contains('TRANSIT') || s.contains('DELIVERING')) {
    return OrderStatus.shipping;
  }
  return OrderStatus.processing;
}

/// Giá trị gửi lên khi quản trị viên đổi trạng thái (PATCH /orders/{id}).
/// TODO: đối chiếu với enum Status của backend (Swagger) rồi sửa 3 chuỗi này cho đúng.
const Map<OrderStatus, String> orderStatusApiValues = {
  OrderStatus.processing: 'PENDING',
  OrderStatus.shipping: 'SHIPPED',
  OrderStatus.delivered: 'DELIVERED',
};

class OrderItem {
  const OrderItem({required this.id, required this.bookId, required this.quantity});

  final int id;
  final int bookId;
  final int quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: (json['id'] as num?)?.toInt() ?? 0,
        bookId: (json['bookId'] as num).toInt(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.total,
    required this.shippingAddress,
    required this.items,
    this.userId,
    this.orderDate,
  });

  final int id;
  final int? userId;
  final OrderStatus status;

  /// Tổng tiền hàng backend tính (chưa gồm phí giao hàng hiển thị trên giao diện).
  final double total;
  final DateTime? orderDate;
  final String shippingAddress;
  final List<OrderItem> items;

  int get itemCount => items.fold<int>(0, (s, i) => s + i.quantity);

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: (json['id'] as num).toInt(),
        userId: (json['userId'] as num?)?.toInt(),
        status: parseOrderStatus(json['status']?.toString()),
        total: double.tryParse('${json['total']}') ?? 0,
        orderDate: DateTime.tryParse('${json['orderDate']}'),
        shippingAddress: json['shippingAddress'] as String? ?? '',
        items: ((json['orderItems'] as List?) ?? const [])
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Order copyWith({OrderStatus? status}) => Order(
        id: id,
        userId: userId,
        status: status ?? this.status,
        total: total,
        shippingAddress: shippingAddress,
        items: items,
        orderDate: orderDate,
      );

  /// shippingAddress được app ghép dạng "Tên · SĐT · Địa chỉ". Tách ra để hiển thị.
  ({String name, String phone, String address}) get addressParts {
    final parts = shippingAddress.split(' · ');
    if (parts.length >= 3) {
      return (
        name: parts[0],
        phone: parts[1],
        address: parts.sublist(2).join(' · '),
      );
    }
    return (name: '', phone: '', address: shippingAddress);
  }
}
