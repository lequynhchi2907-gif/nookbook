import 'package:dio/dio.dart';
import 'package:nookbook/core/network/json_utils.dart';
import 'package:nookbook/features/books/domain/book.dart';
import 'package:nookbook/features/books/domain/book_category.dart';

/// Giao diện (UI) chỉ biết lớp này, không biết dữ liệu đến từ mock hay API.
abstract class BookRepository {
  Future<List<Book>> getBooks();
  Future<Book> getBook(int id);
  Future<List<Book>> search(String query);
  Future<List<BookCategory>> getCategories();
  Future<List<Book>> getBooksByCategory(int categoryId);

  // --- Quản trị viên ---
  Future<Book> createBook(Book book);
  Future<Book> updateBook(Book book);
  Future<void> deleteBook(int id);
  Future<BookCategory> createCategory(
      {required String name, String? description});
  Future<BookCategory> updateCategory(int id,
      {required String name, String? description});
  Future<void> deleteCategory(int id);
}

bool _matches(Book b, String query) {
  final words = query
      .toLowerCase()
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return true;
  final haystack = '${b.title} ${b.author} ${b.isbn ?? ''}'.toLowerCase();
  return words.every(haystack.contains);
}

/// ---------------- DỮ LIỆU GIẢ (theo ảnh thiết kế) ----------------
/// Dữ liệu lưu trong biến static nên thêm/sửa/xóa còn nguyên khi chuyển màn hình
/// (mất khi tắt app).
class MockBookRepository implements BookRepository {
  static final List<Book> _books = [
    const Book(
      id: 1,
      title: 'Nhà giả kim',
      author: 'Paulo Coelho',
      price: 129000,
      isbn: '9786045888947',
      description:
          'Theo chân chàng chăn cừu Santiago trên hành trình tìm kho báu — và học cách lắng nghe tiếng nói của trái tim mình.',
      coverImage: 'assets/images/nha_gia_kim.png',
      categoryIds: [1, 2],
      rating: 4.9,
      ratingCount: 128,
    ),
    const Book(
      id: 2,
      title: 'Cây cam ngọt của tôi',
      author: 'José Mauro de Vasconcelos',
      price: 110000,
      isbn: '9786045893456',
      description: 'Câu chuyện về cậu bé Zezé và cây cam ngọt trong vườn nhà.',
      coverImage: 'assets/images/cay_cam_ngot.png',
      categoryIds: [1, 4],
    ),
    const Book(
      id: 3,
      title: '1984',
      author: 'George Orwell',
      price: 170000,
      isbn: '9786045811122',
      description: 'Tiểu thuyết kinh điển về xã hội bị giám sát toàn diện.',
      coverImage: 'assets/images/1984.png',
      categoryIds: [1, 5],
    ),
    const Book(
      id: 4,
      title: 'Hoàng tử bé',
      author: 'Antoine de Saint-Exupéry',
      price: 98000,
      isbn: '9786045877731',
      description: 'Câu chuyện nhỏ về một hoàng tử đến từ tiểu hành tinh B612.',
      coverImage: 'assets/images/hoang_tu_be.png',
      categoryIds: [1, 4],
    ),
  ];

  static final List<BookCategory> _categories = [
    const BookCategory(
        id: 1,
        name: 'Văn học',
        description: 'Những câu chuyện nuôi dưỡng tâm hồn.'),
    const BookCategory(id: 2, name: 'Phát triển bản thân'),
    const BookCategory(id: 3, name: 'Kinh tế'),
    const BookCategory(id: 4, name: 'Thiếu nhi'),
    const BookCategory(id: 5, name: 'Lịch sử'),
    const BookCategory(id: 6, name: 'Nghệ thuật'),
  ];

  static int _nextBookId = 5;
  static int _nextCategoryId = 7;

  /// Cho các repository giả khác tra cứu sách theo id.
  static Book? byId(int id) {
    for (final b in _books) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<T> _delay<T>(T value) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return value;
  }

  @override
  Future<List<Book>> getBooks() => _delay(List<Book>.of(_books));

  @override
  Future<Book> getBook(int id) {
    final b = byId(id);
    if (b == null) throw Exception('Không tìm thấy sách');
    return _delay(b);
  }

  @override
  Future<List<Book>> search(String query) =>
      _delay(_books.where((b) => _matches(b, query)).toList());

  @override
  Future<List<BookCategory>> getCategories() =>
      _delay(List<BookCategory>.of(_categories));

  @override
  Future<List<Book>> getBooksByCategory(int categoryId) =>
      _delay(_books.where((b) => b.categoryIds.contains(categoryId)).toList());

  @override
  Future<Book> createBook(Book book) async {
    final created = Book(
      id: _nextBookId++,
      title: book.title,
      author: book.author,
      price: book.price,
      isbn: book.isbn,
      description: book.description,
      coverImage: book.coverImage,
      categoryIds: book.categoryIds,
    );
    _books.add(created);
    return _delay(created);
  }

  @override
  Future<Book> updateBook(Book book) async {
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i >= 0) _books[i] = book;
    return _delay(book);
  }

  @override
  Future<void> deleteBook(int id) async {
    _books.removeWhere((b) => b.id == id);
    await _delay(null);
  }

  @override
  Future<BookCategory> createCategory(
      {required String name, String? description}) async {
    final c = BookCategory(
        id: _nextCategoryId++, name: name, description: description);
    _categories.add(c);
    return _delay(c);
  }

  @override
  Future<BookCategory> updateCategory(int id,
      {required String name, String? description}) async {
    final c = BookCategory(id: id, name: name, description: description);
    final i = _categories.indexWhere((e) => e.id == id);
    if (i >= 0) _categories[i] = c;
    return _delay(c);
  }

  @override
  Future<void> deleteCategory(int id) async {
    _categories.removeWhere((c) => c.id == id);
    await _delay(null);
  }
}

/// ---------------- GỌI BACKEND THẬT ----------------
class ApiBookRepository implements BookRepository {
  ApiBookRepository(this._dio);

  final Dio _dio;

  List<Book> _parseBooks(dynamic data) => extractList(data)
      .map((e) => Book.fromJson(e as Map<String, dynamic>))
      .toList();

  @override
  Future<List<Book>> getBooks() async {
    final res = await _dio.get('/books');
    return _parseBooks(res.data);
  }

  @override
  Future<Book> getBook(int id) async {
    final res = await _dio.get('/books/$id');
    return Book.fromJson(res.data as Map<String, dynamic>);
  }

  /// TODO: mở Swagger xem /books/search nhận tham số tên gì. Ở đây thử "titles" rồi
  /// "authors"; nếu backend bỏ qua tham số lạ thì phía app vẫn lọc lại theo từ khóa.
  @override
  Future<List<Book>> search(String query) async {
    final found = <int, Book>{};
    Object? lastError;
    var succeeded = 0;
    for (final param in const ['titles', 'authors']) {
      try {
        final res =
            await _dio.get('/books/search', queryParameters: {param: query});
        for (final b in _parseBooks(res.data)) {
          found[b.id] = b;
        }
        succeeded++;
      } on DioException catch (e) {
        lastError = e;
      }
    }
    if (succeeded == 0) {
      // Cả hai kiểu tham số đều bị từ chối: lấy toàn bộ rồi lọc tại app.
      final all = await getBooks();
      return all.where((b) => _matches(b, query)).toList();
    }
    if (lastError != null && found.isEmpty) {
      return const [];
    }
    return found.values.where((b) => _matches(b, query)).toList();
  }

  @override
  Future<List<BookCategory>> getCategories() async {
    final res = await _dio.get('/categories');
    return extractList(res.data)
        .map((e) => BookCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<Book>> getBooksByCategory(int categoryId) async {
    final res = await _dio.get('/categories/$categoryId/books');
    return _parseBooks(res.data);
  }

  @override
  Future<Book> createBook(Book book) async {
    final res = await _dio.post('/books', data: book.toRequestJson());
    return Book.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<Book> updateBook(Book book) async {
    final res = await _dio.put('/books/${book.id}', data: book.toRequestJson());
    return Book.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteBook(int id) async {
    await _dio.delete('/books/$id');
  }

  @override
  Future<BookCategory> createCategory(
      {required String name, String? description}) async {
    final res = await _dio
        .post('/categories', data: {'name': name, 'description': description});
    return BookCategory.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<BookCategory> updateCategory(int id,
      {required String name, String? description}) async {
    final res = await _dio.put('/categories/$id',
        data: {'name': name, 'description': description});
    return BookCategory.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> deleteCategory(int id) async {
    await _dio.delete('/categories/$id');
  }
}
