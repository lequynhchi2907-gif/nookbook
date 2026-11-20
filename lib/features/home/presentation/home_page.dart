import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nookbook/app.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/widgets/app_search_bar.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/core/widgets/skeleton.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/books/domain/book_category.dart';
import 'package:nookbook/features/books/presentation/widgets/book_grid.dart';
import 'package:nookbook/features/categories/presentation/category_icons.dart';
import 'package:nookbook/features/favorites/application/favorites_providers.dart';
import 'package:nookbook/features/notifications/application/notification_providers.dart';

/// Màn 01 "Trang chủ" (và màn 40 "Đang tải nội dung" khi dữ liệu chưa về).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final books = ref.watch(booksProvider);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    final favoriteIds = ref.watch(favoritesProvider);
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <BookCategory>[];
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Chào buổi sáng',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                    Text('NookBook', style: theme.textTheme.headlineMedium),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                        onPressed: () => ref
                            .read(themeModeProvider.notifier)
                            .state = isDark ? ThemeMode.light : ThemeMode.dark,
                        icon: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.nightlight_outlined,
                            size: 21)),
                    IconButton(
                      onPressed: () => context.push(AppRoutes.notifications),
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.notifications_none),
                          if (unread > 0)
                            Positioned(
                              right: -1,
                              top: -1,
                              child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle)),
                            ),
                        ],
                      ),
                    ),
                    const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.textPrimary,
                        child:
                            Icon(Icons.person, color: Colors.white, size: 18)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppSearchBar(
              readOnly: true,
              onTap: () => context.push(AppRoutes.search),
            ),
            const SizedBox(height: 20),
            ...books.when<List<Widget>>(
              loading: () => const [_HomeSkeleton()],
              error: (e, _) => [
                ErrorView(
                  message: errorMessage(e),
                  onRetry: () => ref.invalidate(booksProvider),
                ),
              ],
              data: (list) => [
                const _Banner(),
                const SizedBox(height: 20),
                _QuickCategories(categories: categories),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sách được yêu thích',
                        style: theme.textTheme.headlineSmall),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.categoryBooks),
                      child: const Text('Xem tất cả'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BookGrid(books: list.take(4).toList()),
                if (list.any((book) => favoriteIds.contains(book.id))) ...[
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sách yêu thích',
                          style: theme.textTheme.headlineSmall),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.favorites),
                        child: const Text('Xem tất cả'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  BookGrid(
                      books: list
                          .where((book) => favoriteIds.contains(book.id))
                          .take(4)
                          .toList()),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.go(AppRoutes.categoryBooks),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: 180,
          width: double.infinity,
          color: AppColors.primarySoft,
          child: Stack(
            children: [
              // Ảnh banner cắt từ file thiết kế. Thay bằng ảnh gốc chất lượng cao khi có.
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 150,
                child: Image.asset(
                  'assets/images/banner_right.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primarySoft,
                        AppColors.primarySoft,
                        Color(0x00F3E4DA),
                      ],
                      stops: [0, 0.55, 1],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GÓC ĐỌC THÁNG 11',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 190,
                      child: Text(
                        'Chậm một chút, đọc một trang.',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Khám phá ngay →',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickCategories extends StatelessWidget {
  const _QuickCategories({required this.categories});

  final List<BookCategory> categories;

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String, String)>[
      for (final c in categories.take(3))
        (
          categoryIcon(c.name),
          c.name,
          Uri(
            path: AppRoutes.categoryBooks,
            queryParameters: {'id': '${c.id}', 'name': c.name},
          ).toString(),
        ),
      (Icons.grid_view_outlined, 'Tất cả', AppRoutes.categories),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final (icon, label, route) in items)
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.go(route),
            child: SizedBox(
              width: 72,
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: AppColors.primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Màn 40: khung xám nhấp nháy trong lúc chờ dữ liệu.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Skeleton(height: 180, radius: 24),
        const SizedBox(height: 20),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Skeleton(width: 56, height: 56, radius: 18),
            Skeleton(width: 56, height: 56, radius: 18),
            Skeleton(width: 56, height: 56, radius: 18),
            Skeleton(width: 56, height: 56, radius: 18),
          ],
        ),
        const SizedBox(height: 24),
        const Skeleton(width: 160, height: 20, radius: 8),
        const SizedBox(height: 16),
        const Row(
          children: [
            Expanded(child: Skeleton(height: 160, radius: 20)),
            SizedBox(width: 16),
            Expanded(child: Skeleton(height: 160, radius: 20)),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: Skeleton(height: 14, radius: 6)),
            SizedBox(width: 16),
            Expanded(child: Skeleton(height: 14, radius: 6)),
          ],
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Đang mở những trang sách mới...',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
