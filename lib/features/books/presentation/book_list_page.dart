import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/widgets/app_search_bar.dart';
import 'package:nookbook/core/widgets/empty_state.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/core/widgets/pill_chip.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/books/domain/book_category.dart';
import 'package:nookbook/features/books/domain/book_filter.dart';
import 'package:nookbook/features/books/presentation/widgets/book_grid.dart';
import 'package:nookbook/features/books/presentation/widgets/filter_sheet.dart';

/// Màn 03 "Tủ sách chọn lọc" (và danh sách sách theo thể loại),
/// kèm màn 06 "Bộ lọc sách" và màn 07 "Menu sắp xếp".
class BookListPage extends ConsumerStatefulWidget {
  const BookListPage({super.key, this.categoryId, required this.title});

  final int? categoryId;
  final String title;

  @override
  ConsumerState<BookListPage> createState() => _BookListPageState();
}

class _BookListPageState extends ConsumerState<BookListPage> {
  BookFilter _filter = const BookFilter();
  BookSort _sort = BookSort.recommended;

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(booksByCategoryProvider(widget.categoryId));
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <BookCategory>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.categories),
        ),
      ),
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: errorMessage(e),
          onRetry: () => ref.invalidate(booksByCategoryProvider(widget.categoryId)),
        ),
        data: (all) {
          final list = applyBookFilter(all, _filter, _sort);
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              AppSearchBar(
                readOnly: true,
                onTap: () => context.push(AppRoutes.search),
                onFilterTap: () async {
                  final result = await showBookFilterSheet(
                    context,
                    books: all,
                    categories: categories,
                    current: _filter,
                  );
                  if (result != null) setState(() => _filter = result);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  PillChip(
                    label: widget.categoryId == null ? 'Tất cả sách' : widget.title,
                    selected: true,
                  ),
                  if (_filter.isActive) ...[
                    const SizedBox(width: 8),
                    PillChip(
                      label: 'Đang lọc · Xóa',
                      onTap: () => setState(() => _filter = const BookFilter()),
                    ),
                  ],
                  const Spacer(),
                  _SortButton(
                    value: _sort,
                    onChanged: (v) => setState(() => _sort = v),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Khám phá ${list.length} cuốn sách dành cho bạn',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'Chưa có cuốn sách phù hợp',
                  message: 'Thử nới bộ lọc hoặc chọn thể loại khác nhé.',
                )
              else
                BookGrid(books: list),
            ],
          );
        },
      ),
    );
  }
}

/// Nút "Đề xuất ▾" mở menu sắp xếp (màn 07).
class _SortButton extends StatelessWidget {
  const _SortButton({required this.value, required this.onChanged});

  final BookSort value;
  final ValueChanged<BookSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<BookSort>(
      onSelected: onChanged,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        for (final s in BookSort.values)
          PopupMenuItem<BookSort>(
            value: s,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    s.label,
                    style: TextStyle(
                      fontWeight: s == value ? FontWeight.w700 : FontWeight.w500,
                      color: s == value ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                ),
                if (s == value)
                  const Icon(Icons.check, size: 18, color: AppColors.primary),
              ],
            ),
          ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.tune, size: 18),
          const SizedBox(width: 6),
          Text(value.shortLabel,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const Icon(Icons.expand_more, size: 18),
        ],
      ),
    );
  }
}
