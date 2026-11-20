import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/widgets/app_toast.dart';
import 'package:nookbook/core/widgets/confirm_dialog.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/features/admin/presentation/admin_shell.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/books/domain/book_category.dart';
import 'package:nookbook/features/categories/presentation/category_icons.dart';

/// Màn 36 "Danh mục" và màn 37 "Thêm/sửa danh mục".
class AdminCategoriesPage extends ConsumerWidget {
  const AdminCategoriesPage({super.key});

  Future<void> _edit(BuildContext context, WidgetRef ref, BookCategory? c) async {
    final result = await showDialog<({String name, String? description})>(
      context: context,
      builder: (_) => _CategoryDialog(category: c),
    );
    if (result == null || !context.mounted) return;
    try {
      final repo = ref.read(bookRepositoryProvider);
      if (c == null) {
        await repo.createCategory(name: result.name, description: result.description);
      } else {
        await repo.updateCategory(c.id,
            name: result.name, description: result.description);
      }
      refreshCatalog(ref);
      if (context.mounted) {
        AppToast.success(context,
            title: c == null ? 'Đã thêm danh mục' : 'Đã lưu danh mục',
            message: result.name);
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, title: 'Chưa thể lưu danh mục', message: errorMessage(e));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, BookCategory c) async {
    final ok = await showConfirmDialog(
      context,
      icon: Icons.delete_outline,
      title: 'Xóa danh mục này?',
      message: '"${c.name}" sẽ bị xóa. Sách thuộc danh mục vẫn được giữ lại.',
      confirmLabel: 'Xóa danh mục',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(bookRepositoryProvider).deleteCategory(c.id);
      refreshCatalog(ref);
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context, title: 'Chưa thể xóa', message: errorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider);
    final counts = ref.watch(categoryBookCountsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh mục'),
        actions: const [AdminLogoutButton()],
      ),
      body: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: errorMessage(e),
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${list.length} danh mục sách',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                TextButton.icon(
                  onPressed: () => _edit(context, ref, null),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Thêm mới'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final c in list) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(categoryIcon(c.name), color: AppColors.primary),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text('${c.bookCount ?? counts[c.id] ?? 0} đầu sách',
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _edit(context, ref, c),
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: AppColors.primary),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _delete(context, ref, c),
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({required this.category});

  final BookCategory? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late final _description =
      TextEditingController(text: widget.category?.description ?? '');

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.category != null;
    return Dialog(
      backgroundColor: AppColors.background,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.folder_open_outlined, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(editing ? 'Chỉnh sửa danh mục' : 'Thêm danh mục',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text(
                'Cập nhật tên và mô tả để độc giả dễ tìm sách.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Text('Tên danh mục *',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _name,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nhập tên danh mục' : null,
              ),
              const SizedBox(height: 14),
              const Text('Mô tả',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 8),
              TextFormField(controller: _description, maxLines: 3),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  final d = _description.text.trim();
                  Navigator.of(context)
                      .pop((name: _name.text.trim(), description: d.isEmpty ? null : d));
                },
                child: const Text('Lưu danh mục'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Hủy'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
