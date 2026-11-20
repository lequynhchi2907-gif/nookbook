import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nookbook/core/config/app_config.dart';
import 'package:nookbook/core/network/api_client.dart';
import 'package:nookbook/features/books/data/book_repository.dart';
import 'package:nookbook/features/books/domain/book.dart';
import 'package:nookbook/features/books/domain/book_category.dart';

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  if (AppConfig.useMock) return MockBookRepository();
  return ApiBookRepository(ref.watch(dioProvider));
});

final booksProvider = FutureProvider<List<Book>>(
  (ref) => ref.watch(bookRepositoryProvider).getBooks(),
);

final categoriesProvider = FutureProvider<List<BookCategory>>(
  (ref) => ref.watch(bookRepositoryProvider).getCategories(),
);

final bookDetailProvider = FutureProvider.family<Book, int>(
  (ref, id) => ref.watch(bookRepositoryProvider).getBook(id),
);

/// Giống [bookDetailProvider] nhưng trả null thay vì ném lỗi (dùng trong danh sách
/// đơn hàng / yêu thích, nơi một cuốn sách bị xóa không được làm hỏng cả màn).
final bookOrNullProvider = FutureProvider.family<Book?, int>((ref, id) async {
  try {
    return await ref.watch(bookRepositoryProvider).getBook(id);
  } catch (_) {
    return null;
  }
});

/// categoryId = null -> tất cả sách.
final booksByCategoryProvider = FutureProvider.family<List<Book>, int?>(
  (ref, categoryId) {
    final repo = ref.watch(bookRepositoryProvider);
    return categoryId == null ? repo.getBooks() : repo.getBooksByCategory(categoryId);
  },
);

final searchResultsProvider = FutureProvider.family<List<Book>, String>(
  (ref, query) => ref.watch(bookRepositoryProvider).search(query),
);

/// Số đầu sách theo từng thể loại, đếm từ danh sách sách đã tải
/// (backend chưa trả sẵn bookCount).
final categoryBookCountsProvider = Provider<Map<int, int>>((ref) {
  final books = ref.watch(booksProvider).valueOrNull ?? const <Book>[];
  final counts = <int, int>{};
  for (final b in books) {
    for (final id in b.categoryIds) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  return counts;
});

/// "Có thể bạn cũng thích": ưu tiên sách cùng thể loại.
final relatedBooksProvider =
    FutureProvider.family<List<Book>, int>((ref, bookId) async {
  final all = await ref.watch(booksProvider.future);
  Book? current;
  for (final b in all) {
    if (b.id == bookId) current = b;
  }
  final ids = current?.categoryIds ?? const <int>[];
  final others = all.where((b) => b.id != bookId).toList();
  int rank(Book b) => b.categoryIds.any(ids.contains) ? 0 : 1;
  others.sort((a, b) => rank(a).compareTo(rank(b)));
  return others.take(4).toList();
});

/// Làm mới mọi dữ liệu sách sau khi quản trị viên thêm / sửa / xóa.
void refreshCatalog(WidgetRef ref) {
  ref.invalidate(booksProvider);
  ref.invalidate(categoriesProvider);
  ref.invalidate(booksByCategoryProvider);
  ref.invalidate(bookDetailProvider);
  ref.invalidate(bookOrNullProvider);
  ref.invalidate(searchResultsProvider);
  ref.invalidate(relatedBooksProvider);
}
