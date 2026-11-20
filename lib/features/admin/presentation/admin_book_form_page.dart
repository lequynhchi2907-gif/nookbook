import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/widgets/app_toast.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/core/widgets/pill_chip.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/books/domain/book.dart';
import 'package:nookbook/features/books/presentation/widgets/book_cover.dart';

/// Màn 33 "Thêm sách" và màn 34 "Chỉnh sửa sách".
/// Backend chưa có số lượng tồn kho / trạng thái hiển thị nên các ô đó không có trong form.
class AdminBookFormPage extends ConsumerWidget {
  const AdminBookFormPage({super.key, this.bookId});

  final int? bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookId == null) return const _Form(book: null);
    final book = ref.watch(bookDetailProvider(bookId!));
    return book.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa sách')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Chỉnh sửa sách')),
        body: ErrorView(
          message: errorMessage(e),
          onRetry: () => ref.invalidate(bookDetailProvider(bookId!)),
        ),
      ),
      data: (b) => _Form(book: b),
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.book});

  final Book? book;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.book?.title ?? '');
  late final _author = TextEditingController(text: widget.book?.author ?? '');
  late final _isbn = TextEditingController(text: widget.book?.isbn ?? '');
  late final _price = TextEditingController(
      text: widget.book == null ? '' : widget.book!.price.round().toString());
  late final _description =
      TextEditingController(text: widget.book?.description ?? '');
  late final _cover = TextEditingController(text: widget.book?.coverImage ?? '');
  late Set<int> _categoryIds = {...?widget.book?.categoryIds};
  bool _saving = false;

  bool get _editing => widget.book != null;

  @override
  void dispose() {
    for (final c in [_title, _author, _isbn, _price, _description, _cover]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final price = double.parse(_price.text.replaceAll(RegExp(r'[.,\s]'), ''));
      final draft = Book(
        id: widget.book?.id ?? 0,
        title: _title.text.trim(),
        author: _author.text.trim(),
        isbn: _isbn.text.trim(),
        price: price,
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        coverImage: _cover.text.trim(),
        categoryIds: _categoryIds.toList(),
      );
      final repo = ref.read(bookRepositoryProvider);
      if (_editing) {
        await repo.updateBook(draft);
      } else {
        await repo.createBook(draft);
      }
      refreshCatalog(ref);
      if (!mounted) return;
      AppToast.success(context,
          title: _editing ? 'Đã lưu thay đổi' : 'Đã thêm sách mới',
          message: draft.title);
      context.canPop() ? context.pop() : context.go(AppRoutes.adminBooks);
    } catch (e) {
      if (mounted) {
        AppToast.error(context, title: 'Chưa thể lưu sách', message: errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v, String msg) =>
      (v == null || v.trim().isEmpty) ? msg : null;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Chỉnh sửa sách' : 'Thêm sách'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.adminBooks),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: PillChip(
                label: _editing ? 'Đang chỉnh sửa · NB${widget.book!.id.toString().padLeft(3, '0')}' : 'Đầu sách mới',
                selected: true,
              ),
            ),
            const SizedBox(height: 16),
            _Labeled(
              'Tên sách *',
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(hintText: 'Nhập tên sách'),
                validator: (v) => _required(v, 'Nhập tên sách'),
              ),
            ),
            _Labeled(
              'Tác giả *',
              TextFormField(
                controller: _author,
                decoration: const InputDecoration(hintText: 'Tên tác giả'),
                validator: (v) => _required(v, 'Nhập tên tác giả'),
              ),
            ),
            _Labeled(
              'ISBN *',
              TextFormField(
                controller: _isbn,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Mã ISBN gồm 13 chữ số'),
                validator: (v) {
                  final t = (v ?? '').replaceAll('-', '').trim();
                  return RegExp(r'^\d{10}(\d{3})?$').hasMatch(t)
                      ? null
                      : 'ISBN gồm 10 hoặc 13 chữ số';
                },
              ),
            ),
            _Labeled(
              'Giá bán (₫) *',
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: '0'),
                validator: (v) {
                  final n = double.tryParse((v ?? '').replaceAll(RegExp(r'[.,\s]'), ''));
                  return (n == null || n <= 0) ? 'Nhập giá lớn hơn 0' : null;
                },
              ),
            ),
            _Labeled(
              'Mô tả sách',
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(
                    hintText: 'Giới thiệu nội dung, điểm nổi bật của sách...'),
              ),
            ),
            _Labeled(
              'Đường dẫn ảnh bìa *',
              TextFormField(
                controller: _cover,
                keyboardType: TextInputType.url,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'https://.../bia-sach.jpg'),
                validator: (v) => _required(v, 'Nhập đường dẫn ảnh bìa'),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: BookCover(
                      book: Book(
                        id: 0,
                        title: _title.text,
                        author: '',
                        price: 0,
                        coverImage: _cover.text.trim(),
                      ),
                      height: 78,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Xem trước bìa sách',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('Tỉ lệ khuyến nghị 2:3. Ảnh rõ nét, tối đa 5 MB.',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Danh mục * · Có thể chọn nhiều',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categories)
                  PillChip(
                    label: c.name,
                    selected: _categoryIds.contains(c.id),
                    showCheck: true,
                    onTap: () => setState(() {
                      final next = {..._categoryIds};
                      if (!next.remove(c.id)) next.add(c.id);
                      _categoryIds = next;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(_editing ? 'Lưu thay đổi' : 'Thêm sách'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.adminBooks),
              child: const Text('Hủy và quay lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled(this.label, this.field);

  final String label;
  final Widget field;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            field,
          ],
        ),
      );
}
