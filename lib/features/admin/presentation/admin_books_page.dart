import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/app_search_bar.dart';
import 'package:nookbook/core/widgets/app_toast.dart';
import 'package:nookbook/core/widgets/confirm_dialog.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/features/admin/presentation/admin_shell.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/books/domain/book.dart';
import 'package:nookbook/features/books/presentation/widgets/book_cover.dart';

/// Màn 31 "Quản lý sách", 32 "Tìm kiếm sách", 35 "Xác nhận xóa sách".
class AdminBooksPage extends ConsumerStatefulWidget {
  const AdminBooksPage({super.key});

  @override
  ConsumerState<AdminBooksPage> createState() => _AdminBooksPageState();
}

class _AdminBooksPageState extends ConsumerState<AdminBooksPage> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _delete(Book b) async {
    final ok = await showConfirmDialog(
      context,
      icon: Icons.delete_outline,
      title: 'Xóa đầu sách này?',
      message:
          '"${b.title}" sẽ bị gỡ khỏi cửa hàng. Các đơn hàng đã đặt vẫn được giữ nguyên. Thao tác này không thể hoàn tác.',
      confirmLabel: 'Xóa sách',
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(bookRepositoryProvider).deleteBook(b.id);
      refreshCatalog(ref);
      if (mounted) AppToast.success(context, title: 'Đã xóa "${b.title}"');
    } catch (e) {
      if (mounted) {
        AppToast.error(context, title: 'Chưa thể xóa sách', message: errorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final books = ref.watch(booksProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý sách'),
        actions: const [AdminLogoutButton()],
      ),
      body: books.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: errorMessage(e),
          onRetry: () => ref.invalidate(booksProvider),
        ),
        data: (all) {
          final q = _query.toLowerCase();
          final list = q.isEmpty
              ? all
              : all
                  .where((b) =>
                      b.title.toLowerCase().contains(q) ||
                      b.author.toLowerCase().contains(q) ||
                      (b.isbn ?? '').toLowerCase().contains(q))
                  .toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    q.isEmpty
                        ? '${all.length} đầu sách'
                        : '${list.length} kết quả phù hợp',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.adminBookNew),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Thêm sách'),
                  ),
                ],
              ),
              AppSearchBar(
                controller: _search,
                hint: 'Tìm tên sách, tác giả, ISBN',
                onChanged: (v) => setState(() => _query = v.trim()),
                onClear: () => setState(() => _query = ''),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Không có đầu sách nào phù hợp.')),
                ),
              for (final b in list) ...[
                _AdminBookTile(
                  book: b,
                  onEdit: () => context.push(AppRoutes.adminBookEdit(b.id)),
                  onDelete: () => _delete(b),
                ),
                const SizedBox(height: 12),
              ],
              if (q.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    'Tìm theo tên sách, tác giả hoặc mã ISBN. Chọn "Sửa" để cập nhật thông tin đầu sách.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminBookTile extends StatelessWidget {
  const _AdminBookTile({required this.book, required this.onEdit, required this.onDelete});

  final Book book;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          BookCover(book: book, height: 84),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(formatPrice(book.price),
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Sửa'),
                    ),
                    const Spacer(),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
