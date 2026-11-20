import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nookbook/core/config/app_config.dart';
import 'package:nookbook/core/network/api_client.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/books/domain/book.dart';
import 'package:nookbook/features/cart/data/cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  if (AppConfig.useMock) return MockCartRepository();
  return ApiCartRepository(ref.watch(dioProvider));
});

/// Một dòng giỏ hàng đã ghép với thông tin sách (ảnh bìa, tác giả, giá).
class CartLine {
  const CartLine({
    required this.itemId,
    required this.book,
    required this.quantity,
  });

  final int itemId;
  final Book book;
  final int quantity;

  double get total => book.price * quantity;
}

class CartNotifier extends AsyncNotifier<List<CartLine>> {
  @override
  Future<List<CartLine>> build() => _load();

  Future<List<CartLine>> _load() async {
    final items = await ref.read(cartRepositoryProvider).getItems();
    final bookRepo = ref.read(bookRepositoryProvider);
    return Future.wait<CartLine>(items.map((i) async {
      Book book;
      try {
        book = await bookRepo.getBook(i.bookId);
      } catch (_) {
        book = Book(id: i.bookId, title: i.bookTitle, author: '', price: 0);
      }
      return CartLine(itemId: i.id, book: book, quantity: i.quantity);
    }));
  }

  /// Ném lỗi nếu thất bại để màn hình hiện toast lỗi.
  Future<void> add(Book book, {int quantity = 1}) async {
    await ref.read(cartRepositoryProvider).add(book.id, quantity);
    state = AsyncData(await _load());
  }

  Future<void> setQuantity(CartLine line, int quantity) async {
    if (quantity < 1) return;
    await ref.read(cartRepositoryProvider).updateQuantity(line.itemId, quantity);
    state = AsyncData(await _load());
  }

  Future<void> remove(CartLine line) async {
    await ref.read(cartRepositoryProvider).remove(line.itemId);
    state = AsyncData(await _load());
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }
}

final cartProvider =
    AsyncNotifierProvider<CartNotifier, List<CartLine>>(CartNotifier.new);

/// Tạm tính của giỏ hiện tại.
double cartSubtotal(List<CartLine> lines) =>
    lines.fold<double>(0, (sum, l) => sum + l.total);
