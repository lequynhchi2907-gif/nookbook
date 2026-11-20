import 'package:dio/dio.dart';
import 'package:nookbook/features/books/data/book_repository.dart';

/// Một dòng trong giỏ hàng, đúng như backend trả về (CartItemDto).
/// TODO: đối chiếu Swagger: id, bookId, bookTitle, quantity.
class CartItem {
  const CartItem({
    required this.id,
    required this.bookId,
    required this.bookTitle,
    required this.quantity,
  });

  final int id;
  final int bookId;
  final String bookTitle;
  final int quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: (json['id'] as num).toInt(),
        bookId: (json['bookId'] as num).toInt(),
        bookTitle: json['bookTitle'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      );
}

abstract class CartRepository {
  /// GET /cart
  Future<List<CartItem>> getItems();

  /// POST /cart
  Future<void> add(int bookId, int quantity);

  /// PUT /cart/items/{id}
  Future<void> updateQuantity(int itemId, int quantity);

  /// DELETE /cart/items/{id}
  Future<void> remove(int itemId);
}

/// Giỏ hàng giả, giữ trong bộ nhớ (biến static).
class MockCartRepository implements CartRepository {
  static final List<CartItem> items = [];
  static int _nextId = 1;

  Future<T> _delay<T>(T value) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return value;
  }

  @override
  Future<List<CartItem>> getItems() => _delay(List<CartItem>.of(items));

  @override
  Future<void> add(int bookId, int quantity) async {
    final i = items.indexWhere((e) => e.bookId == bookId);
    if (i >= 0) {
      final old = items[i];
      items[i] = CartItem(
        id: old.id,
        bookId: old.bookId,
        bookTitle: old.bookTitle,
        quantity: old.quantity + quantity,
      );
    } else {
      final book = MockBookRepository.byId(bookId);
      items.add(CartItem(
        id: _nextId++,
        bookId: bookId,
        bookTitle: book?.title ?? 'Sách #$bookId',
        quantity: quantity,
      ));
    }
    await _delay(null);
  }

  @override
  Future<void> updateQuantity(int itemId, int quantity) async {
    final i = items.indexWhere((e) => e.id == itemId);
    if (i >= 0) {
      final old = items[i];
      items[i] = CartItem(
        id: old.id,
        bookId: old.bookId,
        bookTitle: old.bookTitle,
        quantity: quantity,
      );
    }
    await _delay(null);
  }

  @override
  Future<void> remove(int itemId) async {
    items.removeWhere((e) => e.id == itemId);
    await _delay(null);
  }
}

class ApiCartRepository implements CartRepository {
  ApiCartRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<CartItem>> getItems() async {
    final res = await _dio.get('/cart');
    final data = res.data;
    final raw = data is Map ? (data['cartItems'] ?? data['items']) : null;
    if (raw is! List) return const [];
    return raw.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> add(int bookId, int quantity) async {
    await _dio.post('/cart', data: {'bookId': bookId, 'quantity': quantity});
  }

  @override
  Future<void> updateQuantity(int itemId, int quantity) async {
    await _dio.put('/cart/items/$itemId', data: {'quantity': quantity});
  }

  @override
  Future<void> remove(int itemId) async {
    await _dio.delete('/cart/items/$itemId');
  }
}
