import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/empty_state.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/books/presentation/widgets/book_cover.dart';
import 'package:nookbook/features/favorites/application/favorites_providers.dart';

/// Màn 09 "Sách yêu thích". (Backend chưa có API yêu thích: dữ liệu lưu trong máy.)
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesProvider).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sách yêu thích'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.account),
        ),
      ),
      body: ids.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border,
              title: 'Chưa có sách yêu thích',
              message: 'Bấm biểu tượng trái tim ở trang chi tiết để lưu sách bạn thích.',
              buttonLabel: 'Khám phá sách ngay',
              onPressed: () => context.go(AppRoutes.categoryBooks),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Những cuốn sách dành riêng cho bạn',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${ids.length} cuốn',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final id in ids) ...[
                  _FavoriteTile(bookId: id),
                  const SizedBox(height: 12),
                ],
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.categoryBooks),
                  child: const Text('Tiếp tục khám phá'),
                ),
              ],
            ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.bookId});

  final int bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(bookOrNullProvider(bookId)).valueOrNull;
    if (book == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push(AppRoutes.bookDetail(book.id)),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            BookCover(book: book, height: 80),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(book.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  Text(book.author,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Text(formatPrice(book.price),
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.primary, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            IconButton(
              onPressed: () => ref.read(favoritesProvider.notifier).toggle(book.id),
              icon: const Icon(Icons.favorite, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
