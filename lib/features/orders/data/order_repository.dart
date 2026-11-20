import 'package:dio/dio.dart';
import 'package:nookbook/core/network/json_utils.dart';
import 'package:nookbook/core/widgets/status_chip.dart';
import 'package:nookbook/features/books/data/book_repository.dart';
import 'package:nookbook/features/cart/data/cart_repository.dart';
import 'package:nookbook/features/orders/domain/order.dart';

abstract class OrderRepository {
  /// GET /orders
  Future<List<Order>> getOrders();

  /// POST /orders (backend lấy các món trong giỏ để tạo đơn)
  Future<Order> placeOrder({required String shippingAddress});

  /// PATCH /orders/{id} (chỉ quản trị viên)
  Future<void> updateStatus(int orderId, OrderStatus status);
}

class MockOrderRepository implements OrderRepository {
  static final List<Order> _orders = [
    Order(
      id: 241108,
      status: OrderStatus.processing,
      total: 239000,
      orderDate: DateTime(2026, 11, 6, 9, 41),
      shippingAddress:
          'Nguyễn Minh Anh · 090 123 4567 · 28 Nguyễn Trãi, phường Bến Thành, TP. Hồ Chí Minh',
      items: const [
        OrderItem(id: 1, bookId: 1, quantity: 1),
        OrderItem(id: 2, bookId: 2, quantity: 1),
      ],
    ),
    Order(
      id: 241102,
      status: OrderStatus.shipping,
      total: 239000,
      orderDate: DateTime(2026, 11, 2, 9, 41),
      shippingAddress:
          'Nguyễn Minh Anh · 090 123 4567 · 28 Nguyễn Trãi, phường Bến Thành, TP. Hồ Chí Minh',
      items: const [
        OrderItem(id: 3, bookId: 1, quantity: 1),
        OrderItem(id: 4, bookId: 2, quantity: 1),
      ],
    ),
    Order(
      id: 241020,
      status: OrderStatus.delivered,
      total: 239000,
      orderDate: DateTime(2026, 10, 20, 15, 10),
      shippingAddress:
          'Nguyễn Minh Anh · 090 123 4567 · 28 Nguyễn Trãi, phường Bến Thành, TP. Hồ Chí Minh',
      items: const [
        OrderItem(id: 5, bookId: 1, quantity: 1),
        OrderItem(id: 6, bookId: 2, quantity: 1),
      ],
    ),
  ];

  Future<T> _delay<T>(T value) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return value;
  }

  @override
  Future<List<Order>> getOrders() => _delay(List<Order>.of(_orders));

  @override
  Future<Order> placeOrder({required String shippingAddress}) async {
    final cart = MockCartRepository.items;
    if (cart.isEmpty) throw Exception('Giỏ hàng trống');
    var total = 0.0;
    final items = <OrderItem>[];
    for (final c in cart) {
      final book = MockBookRepository.byId(c.bookId);
      total += (book?.price ?? 0) * c.quantity;
      items.add(OrderItem(id: items.length + 1, bookId: c.bookId, quantity: c.quantity));
    }
    var nextId = 241109;
    for (final o in _orders) {
      if (o.id >= nextId) nextId = o.id + 1;
    }
    final order = Order(
      id: nextId,
      status: OrderStatus.processing,
      total: total,
      orderDate: DateTime.now(),
      shippingAddress: shippingAddress,
      items: items,
    );
    _orders.insert(0, order);
    cart.clear();
    return _delay(order);
  }

  @override
  Future<void> updateStatus(int orderId, OrderStatus status) async {
    final i = _orders.indexWhere((o) => o.id == orderId);
    if (i >= 0) _orders[i] = _orders[i].copyWith(status: status);
    await _delay(null);
  }
}

class ApiOrderRepository implements OrderRepository {
  ApiOrderRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Order>> getOrders() async {
    final res = await _dio.get('/orders');
    final orders = extractList(res.data)
        .map((e) => Order.fromJson(e as Map<String, dynamic>))
        .toList();
    orders.sort((a, b) {
      final da = a.orderDate;
      final db = b.orderDate;
      if (da != null && db != null) return db.compareTo(da);
      return b.id.compareTo(a.id);
    });
    return orders;
  }

  @override
  Future<Order> placeOrder({required String shippingAddress}) async {
    final res = await _dio.post('/orders', data: {'shippingAddress': shippingAddress});
    return Order.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> updateStatus(int orderId, OrderStatus status) async {
    await _dio.patch('/orders/$orderId', data: {'status': orderStatusApiValues[status]});
  }
}
