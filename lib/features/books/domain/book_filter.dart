import 'package:nookbook/features/books/domain/book.dart';

enum BookSort { recommended, newest, priceAsc, priceDesc }

extension BookSortX on BookSort {
  String get label => switch (this) {
        BookSort.recommended => 'Đề xuất cho bạn',
        BookSort.newest => 'Mới nhất',
        BookSort.priceAsc => 'Giá: Thấp đến cao',
        BookSort.priceDesc => 'Giá: Cao đến thấp',
      };

  /// Nhãn ngắn trên nút sắp xếp.
  String get shortLabel => this == BookSort.recommended ? 'Đề xuất' : label;
}

/// Bộ lọc của màn "Tủ sách chọn lọc" (thể loại + khoảng giá).
class BookFilter {
  const BookFilter({this.categoryIds = const {}, this.minPrice, this.maxPrice});

  final Set<int> categoryIds;
  final double? minPrice;
  final double? maxPrice;

  bool get isActive =>
      categoryIds.isNotEmpty || minPrice != null || maxPrice != null;

  bool matches(Book b) {
    if (categoryIds.isNotEmpty && !b.categoryIds.any(categoryIds.contains)) {
      return false;
    }
    if (minPrice != null && b.price < minPrice!) return false;
    if (maxPrice != null && b.price > maxPrice!) return false;
    return true;
  }
}

/// Lọc rồi sắp xếp danh sách sách ngay trên app.
/// ("Mới nhất" dựa vào id lớn hơn = thêm sau; backend chưa có ngày thêm / lượt bán.)
List<Book> applyBookFilter(List<Book> books, BookFilter filter, BookSort sort) {
  final list = books.where(filter.matches).toList();
  switch (sort) {
    case BookSort.recommended:
      break;
    case BookSort.newest:
      list.sort((a, b) => b.id.compareTo(a.id));
    case BookSort.priceAsc:
      list.sort((a, b) => a.price.compareTo(b.price));
    case BookSort.priceDesc:
      list.sort((a, b) => b.price.compareTo(a.price));
  }
  return list;
}
