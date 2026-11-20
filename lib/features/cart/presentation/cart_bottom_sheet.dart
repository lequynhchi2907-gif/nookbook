import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nookbook/core/config/app_config.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/features/books/presentation/widgets/book_cover.dart';
import 'package:nookbook/features/cart/application/cart_providers.dart';

class CartBottomSheet extends ConsumerWidget {
  const CartBottomSheet({super.key, required this.onViewCart});

  final VoidCallback onViewCart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: ref.watch(cartProvider).when(
                loading: () => const SizedBox(
                    height: 280,
                    child: Center(child: CircularProgressIndicator())),
                error: (_, __) => const SizedBox(
                    height: 260,
                    child: Center(child: Text('Không thể tải giỏ hàng'))),
                data: (lines) => _body(context, ref, lines),
              ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, List<CartLine> lines) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
            child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(5)))),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Giỏ sách',
              style: TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 24,
                  fontWeight: FontWeight.w700)),
          IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close)),
        ]),
        if (lines.isEmpty) _emptyBody() else _filledBody(ref, lines),
      ],
    );
  }

  Widget _emptyBody() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
            child: Text('Giỏ sách đang trống',
                style: TextStyle(color: AppColors.textSecondary))),
      );

  Widget _filledBody(WidgetRef ref, List<CartLine> lines) {
    final subtotal = cartSubtotal(lines);
    final freeShipping = subtotal >= AppConfig.freeShippingThreshold;
    final missing = AppConfig.freeShippingThreshold - subtotal;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(16)),
          child: Row(children: [
            const Icon(Icons.local_shipping_outlined,
                color: AppColors.success, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    freeShipping
                        ? 'Bạn được miễn phí vận chuyển'
                        : 'Thêm ${formatPrice(missing)} để miễn phí vận chuyển',
                    style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12,
                        fontWeight: FontWeight.w600))),
          ]),
        ),
        const SizedBox(height: 12),
        ...lines.map((line) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _SheetLine(
                line: line,
                onMinus: () => ref
                    .read(cartProvider.notifier)
                    .setQuantity(line, line.quantity - 1),
                onPlus: () => ref
                    .read(cartProvider.notifier)
                    .setQuantity(line, line.quantity + 1),
                onDelete: () => ref.read(cartProvider.notifier).remove(line),
              ),
            )),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border)),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Tạm tính',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(formatPrice(subtotal),
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 10),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed: onViewCart,
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Xem giỏ hàng'),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18)
                        ]))),
          ]),
        ),
      ],
    );
  }
}

class _SheetLine extends StatelessWidget {
  const _SheetLine(
      {required this.line,
      required this.onMinus,
      required this.onPlus,
      required this.onDelete});
  final CartLine line;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border)),
        child: Row(children: [
          BookCover(book: line.book, height: 82),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(line.book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(formatPrice(line.book.price),
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                _QuantityControl(
                    quantity: line.quantity, onMinus: onMinus, onPlus: onPlus),
              ])),
          IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline,
                  size: 19, color: AppColors.textSecondary)),
        ]),
      );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl(
      {required this.quantity, required this.onMinus, required this.onPlus});
  final int quantity;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              onPressed: quantity > 1 ? onMinus : null,
              icon: const Icon(Icons.remove, size: 16),
              visualDensity: VisualDensity.compact),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text('$quantity',
                  style: const TextStyle(fontWeight: FontWeight.w700))),
          IconButton(
              onPressed: onPlus,
              icon: const Icon(Icons.add, size: 16),
              visualDensity: VisualDensity.compact),
        ]),
      );
}
