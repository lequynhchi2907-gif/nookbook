import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/widgets/app_search_bar.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/categories/presentation/category_icons.dart';

/// Màn 02 "Thể loại".
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);
    final counts = ref.watch(categoryBookCountsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thể loại')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Bạn muốn đọc gì?', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Mỗi sở thích, một thế giới để khám phá.',
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          AppSearchBar(
            readOnly: true,
            onTap: () => context.push(AppRoutes.search),
          ),
          const SizedBox(height: 20),
          categories.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ErrorView(
              message: errorMessage(e),
              onRetry: () => ref.invalidate(categoriesProvider),
            ),
            data: (list) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 130,
              ),
              itemBuilder: (context, i) {
                final c = list[i];
                final count = c.bookCount ?? counts[c.id] ?? 0;
                return Card(
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  // Hai thể loại đầu tô nền nhạt như thiết kế.
                  color: i < 2 ? AppColors.primarySoft : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                        color: i < 2 ? AppColors.primarySoft : AppColors.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.go(
                      Uri(
                        path: AppRoutes.categoryBooks,
                        queryParameters: {'id': '${c.id}', 'name': c.name},
                      ).toString(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(categoryIcon(c.name), color: AppColors.primary),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '$count đầu sách',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
