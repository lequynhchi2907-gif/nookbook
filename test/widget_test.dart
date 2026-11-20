import 'package:flutter_test/flutter_test.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/utils/jwt_utils.dart';
import 'package:nookbook/core/widgets/status_chip.dart';
import 'package:nookbook/features/books/domain/book.dart';
import 'package:nookbook/features/books/domain/book_filter.dart';
import 'package:nookbook/features/orders/domain/order.dart';

void main() {
  test('formatPrice thêm dấu chấm ngăn cách hàng nghìn', () {
    expect(formatPrice(129000), '129.000 ₫');
    expect(formatPrice(98000), '98.000 ₫');
    expect(formatPrice(0), '0 ₫');
  });

  test('orderCode và initials', () {
    expect(orderCode(241108), '#NB241108');
    expect(initials('Nguyễn Minh Anh'), 'NA');
  });

  test('parseOrderStatus gom trạng thái backend về 3 nhóm', () {
    expect(parseOrderStatus('PENDING'), OrderStatus.processing);
    expect(parseOrderStatus('SHIPPED'), OrderStatus.shipping);
    expect(parseOrderStatus('DELIVERED'), OrderStatus.delivered);
    expect(parseOrderStatus('COMPLETED'), OrderStatus.delivered);
  });

  test('readRoles với token giả', () {
    expect(hasAdminRole(readRoles('mock-admin-token')!), isTrue);
    expect(hasAdminRole(readRoles('mock-token')!), isFalse);
    expect(readRoles('khong-phai-jwt'), isNull);
  });

  test('lọc và sắp xếp sách', () {
    const books = [
      Book(id: 1, title: 'A', author: 'x', price: 100000, categoryIds: [1]),
      Book(id: 2, title: 'B', author: 'y', price: 50000, categoryIds: [2]),
      Book(id: 3, title: 'C', author: 'z', price: 150000, categoryIds: [1]),
    ];
    final byCat = applyBookFilter(
        books, const BookFilter(categoryIds: {1}), BookSort.priceAsc);
    expect(byCat.map((b) => b.id), [1, 3]);
    final capped = applyBookFilter(
        books, const BookFilter(maxPrice: 100000), BookSort.priceDesc);
    expect(capped.map((b) => b.id), [1, 2]);
  });
}
