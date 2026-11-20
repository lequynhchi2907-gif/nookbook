import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/features/books/domain/book.dart';
import 'package:nookbook/features/books/presentation/widgets/book_card.dart';

/// Lưới 2 cột các BookCard. Đặt được trong ListView (không tự cuộn).
class BookGrid extends StatelessWidget {
  const BookGrid({super.key, required this.books});

  final List<Book> books;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: books.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: 270,
      ),
      itemBuilder: (context, i) => BookCard(
        book: books[i],
        onTap: () => context.push(AppRoutes.bookDetail(books[i].id)),
      ),
    );
  }
}
