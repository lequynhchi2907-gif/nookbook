import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/app_toast.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/features/auth/application/auth_providers.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/books/domain/book.dart';
import 'package:nookbook/features/books/presentation/widgets/book_cover.dart';
import 'package:nookbook/features/books/presentation/widgets/book_grid.dart';
import 'package:nookbook/features/cart/application/cart_providers.dart';
import 'package:nookbook/features/favorites/application/favorites_providers.dart';

/// Màn 08 "Chi tiết sách" + toast màn 28 (thêm giỏ thành công) và màn 29 (lỗi).
class BookDetailPage extends ConsumerStatefulWidget {
  const BookDetailPage({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends ConsumerState<BookDetailPage> {
  int _qty = 1;
  bool _busy = false;

  Future<void> _addToCart(Book b, {bool buyNow = false}) async {
    if (!ref.read(authProvider).isLoggedIn) {
      AppToast.error(
        context,
        title: 'Bạn cần đăng nhập',
        message: 'Đăng nhập để thêm sách vào giỏ hàng.',
        actionLabel: 'Đăng nhập',
        onAction: () => context.push(AppRoutes.login),
      );
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(cartProvider.notifier).add(b, quantity: _qty);
      if (!mounted) return;
      if (buyNow) {
        context.push(AppRoutes.checkout);
      } else {
        AppToast.success(
          context,
          title: 'Đã thêm vào giỏ hàng',
          message: '${b.title} · Số lượng $_qty',
          actionLabel: 'Xem giỏ',
          onAction: () => context.go(AppRoutes.cart),
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.error(
        context,
        title: 'Chưa thể thêm vào giỏ',
        message: errorMessage(e),
        actionLabel: 'Thử lại',
        onAction: () => _addToCart(b, buyNow: buyNow),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = ref.watch(bookDetailProvider(widget.bookId));
    final favorites = ref.watch(favoritesProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sách')),
      body: book.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: errorMessage(e),
          onRetry: () => ref.invalidate(bookDetailProvider(widget.bookId)),
        ),
        data: (b) {
          final isFav = favorites.contains(b.id);
          final names = [
            for (final c in categories)
              if (b.categoryIds.contains(c.id)) c.name
          ];
          final related = ref.watch(relatedBooksProvider(b.id)).valueOrNull ?? const <Book>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Stack(
                children: [
                  Container(
                    height: 240,
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: BookCover(book: b, height: 208),
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: InkWell(
                      onTap: () => ref.read(favoritesProvider.notifier).toggle(b.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (names.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      names.join(' · '),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Text(b.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                b.author,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatPrice(b.price),
                    style: theme.textTheme.headlineSmall?.copyWith(color: AppColors.primary),
                  ),
                  // Backend chưa có đánh giá sao: chỉ hiện khi có dữ liệu.
                  if (b.rating != null)
                    Text(
                      '★ ${b.rating.toString().replaceAll('.', ',')} · ${b.ratingCount ?? 0} đánh giá',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _QtyStepper(
                value: _qty,
                onChanged: (v) => setState(() => _qty = v),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _addToCart(b),
                      icon: const Icon(Icons.shopping_bag_outlined),
                      label: const Text('Thêm vào giỏ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _busy ? null : () => _addToCart(b, buyNow: true),
                      child: const Text('Mua ngay'),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text('Về cuốn sách', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                b.description ?? 'Chưa có mô tả.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              if ((b.isbn ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('ISBN: ${b.isbn}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              ],
              if (related.isNotEmpty) ...[
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Có thể bạn cũng thích', style: theme.textTheme.headlineSmall),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.categoryBooks),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BookGrid(books: related.take(2).toList()),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove, size: 18),
            ),
            Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
