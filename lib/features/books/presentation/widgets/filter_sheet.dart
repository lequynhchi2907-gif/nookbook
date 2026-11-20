import 'package:flutter/material.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/app_sheet.dart';
import 'package:nookbook/core/widgets/pill_chip.dart';
import 'package:nookbook/features/books/domain/book.dart';
import 'package:nookbook/features/books/domain/book_category.dart';
import 'package:nookbook/features/books/domain/book_filter.dart';

/// Màn 06 "Bộ lọc sách". Trả về bộ lọc mới khi bấm "Xem N sách", null nếu đóng sheet.
Future<BookFilter?> showBookFilterSheet(
  BuildContext context, {
  required List<Book> books,
  required List<BookCategory> categories,
  required BookFilter current,
}) {
  return showAppSheet<BookFilter>(
    context,
    title: 'Lọc sách',
    builder: (_) => _FilterBody(books: books, categories: categories, current: current),
  );
}

class _FilterBody extends StatefulWidget {
  const _FilterBody({
    required this.books,
    required this.categories,
    required this.current,
  });

  final List<Book> books;
  final List<BookCategory> categories;
  final BookFilter current;

  @override
  State<_FilterBody> createState() => _FilterBodyState();
}

class _FilterBodyState extends State<_FilterBody> {
  late Set<int> _categoryIds = {...widget.current.categoryIds};
  late double _max = _priceCeiling();
  late RangeValues _range = RangeValues(
    widget.current.minPrice ?? 0,
    widget.current.maxPrice ?? _priceCeiling(),
  );

  double _priceCeiling() {
    var m = 0.0;
    for (final b in widget.books) {
      if (b.price > m) m = b.price;
    }
    // Làm tròn lên bội của 10.000 để thanh trượt chia đều.
    final rounded = (m / 10000).ceil() * 10000.0;
    return rounded < 10000 ? 10000 : rounded;
  }

  BookFilter get _filter => BookFilter(
        categoryIds: _categoryIds,
        minPrice: _range.start <= 0 ? null : _range.start,
        maxPrice: _range.end >= _max ? null : _range.end,
      );

  @override
  Widget build(BuildContext context) {
    final count = widget.books.where(_filter.matches).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thể loại', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillChip(
              label: 'Tất cả',
              selected: _categoryIds.isEmpty,
              onTap: () => setState(() => _categoryIds = {}),
            ),
            for (final c in widget.categories)
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
        const SizedBox(height: 20),
        const Text('Khoảng giá', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Từ ${formatPrice(_range.start)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text('Đến ${formatPrice(_range.end)}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
        RangeSlider(
          values: _range,
          min: 0,
          max: _max,
          divisions: (_max / 10000).round(),
          activeColor: AppColors.primary,
          inactiveColor: AppColors.border,
          onChanged: (v) => setState(() => _range = v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _categoryIds = {};
                  _range = RangeValues(0, _max);
                }),
                child: const Text('Đặt lại'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_filter),
                child: Text('Xem $count sách'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
