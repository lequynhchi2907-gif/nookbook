import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/app_search_bar.dart';
import 'package:nookbook/core/widgets/empty_state.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/core/widgets/pill_chip.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/books/domain/book.dart';
import 'package:nookbook/features/books/presentation/widgets/book_grid.dart';
import 'package:nookbook/features/books/presentation/widgets/book_cover.dart';

enum _Scope { all, title, author }

/// Màn 04 "Kết quả tìm kiếm" + màn 05 "Tìm kiếm không có kết quả".
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  _Scope _scope = _Scope.all;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _run(String q) {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    setState(() => _query = q.trim());
  }

  List<Book> _scoped(List<Book> list) {
    final q = _query.toLowerCase();
    final words =
        q.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    bool matches(Book book, String source) => words.every(source.contains);
    return switch (_scope) {
      _Scope.all => list
          .where((b) => matches(
              b, '${b.title} ${b.author} ${(b.isbn ?? '')}'.toLowerCase()))
          .toList(),
      _Scope.title =>
        list.where((b) => matches(b, b.title.toLowerCase())).toList(),
      _Scope.author =>
        list.where((b) => matches(b, b.author.toLowerCase())).toList(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final results = _query.isEmpty ? null : ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tìm kiếm')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            AppSearchBar(
              controller: _controller,
              autofocus: true,
              onSubmitted: (v) => setState(() => _query = v.trim()),
              onClear: () => setState(() => _query = ''),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: results == null
                  ? const Center(
                      child: Text('Nhập tên sách hoặc tác giả rồi bấm tìm.'))
                  : results.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ErrorView(
                        message: errorMessage(e),
                        onRetry: () => ref.invalidate(booksProvider),
                      ),
                      data: (raw) {
                        final list = _scoped(raw);
                        return list.isEmpty
                            ? _NoResults(onSuggestion: _run)
                            : _Results(
                                query: _query,
                                list: list,
                                scope: _scope,
                                onScope: (s) => setState(() => _scope = s),
                              );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({
    required this.query,
    required this.list,
    required this.scope,
    required this.onScope,
  });

  final String query;
  final List<Book> list;
  final _Scope scope;
  final ValueChanged<_Scope> onScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final all = ref.watch(booksProvider).valueOrNull ?? const <Book>[];
    final ids = list.map((b) => b.id).toSet();
    final suggestions = all.where((b) => !ids.contains(b.id)).take(2).toList();

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Text(
          '${list.length} kết quả cho "$query"',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            PillChip(
                label: 'Tất cả',
                selected: scope == _Scope.all,
                onTap: () => onScope(_Scope.all)),
            const SizedBox(width: 8),
            PillChip(
                label: 'Sách',
                selected: scope == _Scope.title,
                onTap: () => onScope(_Scope.title)),
            const SizedBox(width: 8),
            PillChip(
                label: 'Tác giả',
                selected: scope == _Scope.author,
                onTap: () => onScope(_Scope.author)),
          ],
        ),
        const SizedBox(height: 16),
        for (final b in list) ...[
          _ResultTile(book: b),
          const SizedBox(height: 12),
        ],
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Bạn có thể thích', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 12),
          BookGrid(books: suggestions),
          const SizedBox(height: 12),
          Text(
            'Thử tìm theo tên tác giả hoặc thể loại để khám phá thêm.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _NoResults extends ConsumerWidget {
  const _NoResults({required this.onSuggestion});

  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    final books = ref.watch(booksProvider).valueOrNull ?? const <Book>[];
    return ListView(
      children: [
        EmptyState(
          icon: Icons.search_off,
          title: 'Chưa tìm thấy cuốn sách này',
          message:
              'Thử kiểm tra chính tả, rút ngắn từ khóa hoặc tìm theo tên tác giả nhé.',
          buttonLabel: 'Khám phá tủ sách',
          onPressed: () => context.go(AppRoutes.categoryBooks),
        ),
        if (categories.isNotEmpty || books.isNotEmpty) ...[
          const Text('Gợi ý dành cho bạn',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in categories.take(2))
                PillChip(
                  label: c.name,
                  onTap: () => context.go(
                    Uri(
                      path: AppRoutes.categoryBooks,
                      queryParameters: {'id': '${c.id}', 'name': c.name},
                    ).toString(),
                  ),
                ),
              for (final b in books.take(1))
                PillChip(label: b.title, onTap: () => onSuggestion(b.title)),
            ],
          ),
        ],
      ],
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutes.bookDetail(book.id)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              BookCover(book: book, height: 88),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(book.author,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text(formatPrice(book.price),
                        style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700)),
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
