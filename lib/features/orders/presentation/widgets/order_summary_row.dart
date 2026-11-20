import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/books/presentation/widgets/book_cover.dart';
import 'package:nookbook/features/orders/domain/order.dart';

/// Ảnh bìa nhỏ + "Nhà giả kim và 1 cuốn khác" + tổng tiền. Dùng trong danh sách đơn
/// của người dùng (màn 17) và của quản trị viên (màn 38).
class OrderSummaryRow extends ConsumerWidget {
  const OrderSummaryRow({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final first = order.items.isEmpty ? null : order.items.first;
    final book = first == null ? null : ref.watch(bookOrNullProvider(first.bookId)).valueOrNull;
    final others = order.items.length - 1;
    final title = book?.title ?? 'Đơn ${order.itemCount} cuốn sách';

    return Row(
      children: [
        if (book != null)
          SizedBox(width: 40, child: BookCover(book: book, height: 56))
        else
          const SizedBox(width: 40, height: 56),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                book != null && others > 0 ? '$title và $others cuốn khác' : title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                formatPrice(order.total + _fee(order.total)),
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static double _fee(double subtotal) => orderShippingFee(subtotal);
}
