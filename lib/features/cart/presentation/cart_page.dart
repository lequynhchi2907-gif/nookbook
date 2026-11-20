import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/config/app_config.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/app_toast.dart';
import 'package:nookbook/core/widgets/confirm_dialog.dart';
import 'package:nookbook/core/widgets/empty_state.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/features/books/presentation/widgets/book_cover.dart';
import 'package:nookbook/features/cart/application/cart_providers.dart';

/// Màn 10 "Giỏ hàng có sách", 11 "Giỏ hàng trống", 12 "Xác nhận xóa sách".
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  Future<void> _remove(
      BuildContext context, WidgetRef ref, CartLine line) async {
    final ok = await showConfirmDialog(
      context,
      icon: Icons.delete_outline,
      title: 'Bỏ cuốn sách này?',
      message:
          '"${line.book.title}" sẽ được xóa khỏi giỏ hàng. Bạn vẫn có thể thêm lại bất cứ lúc nào.',
      confirmLabel: 'Xóa khỏi giỏ',
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(cartProvider.notifier).remove(line);
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context,
            title: 'Chưa thể xóa', message: errorMessage(e));
      }
    }
  }

  Future<void> _setQty(
      BuildContext context, WidgetRef ref, CartLine line, int qty) async {
    try {
      await ref.read(cartProvider.notifier).setQuantity(line, qty);
    } catch (e) {
      if (context.mounted) {
        AppToast.error(context,
            title: 'Chưa thể cập nhật', message: errorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Giỏ hàng')),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: errorMessage(e),
          onRetry: () => ref.read(cartProvider.notifier).reload(),
        ),
        data: (lines) {
          if (lines.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 24),
                EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Giỏ sách đang chờ bạn',
                  message:
                      'Có những câu chuyện hay đang chờ được mang về. Cùng tìm cuốn sách tiếp theo nhé.',
                  buttonLabel: 'Khám phá sách ngay',
                  onPressed: () => context.go(AppRoutes.categoryBooks),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mỗi đơn hàng đều được nâng niu',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text(
                          'Sách chính hãng, đóng gói cẩn thận và giao tận tay bạn trên toàn quốc.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          final subtotal = cartSubtotal(lines);
          final fee = AppConfig.shippingFeeFor(subtotal);
          final missing = AppConfig.freeShippingThreshold - subtotal;
          final totalQty = lines.fold<int>(0, (s, l) => s + l.quantity);

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${lines.length} cuốn sách trong giỏ',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$totalQty sản phẩm',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (final line in lines) ...[
                      _CartTile(
                        line: line,
                        onMinus: () =>
                            _setQty(context, ref, line, line.quantity - 1),
                        onPlus: () =>
                            _setQty(context, ref, line, line.quantity + 1),
                        onDelete: () => _remove(context, ref, line),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_shipping_outlined,
                              color: AppColors.success),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              missing > 0
                                  ? 'Thêm ${formatPrice(missing)} để được miễn phí giao hàng.'
                                  : 'Bạn được miễn phí giao hàng.',
                              style: const TextStyle(
                                  color: AppColors.success, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      decoration: BoxDecoration(
                        color: AppColors.cardTint,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tóm tắt đơn hàng',
                              style: TextStyle(
                                  fontFamily: 'Playfair Display',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _SumRow('Tạm tính', formatPrice(subtotal)),
                          const SizedBox(height: 8),
                          _SumRow('Phí giao hàng',
                              fee == 0 ? 'Miễn phí' : formatPrice(fee)),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng cộng',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                formatPrice(subtotal + fee),
                                style: theme.textTheme.headlineSmall
                                    ?.copyWith(color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: ElevatedButton(
                  onPressed: () => context.push(AppRoutes.checkout),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Tiến hành thanh toán'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  const _SumRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      );
}

class _CartTile extends StatelessWidget {
  const _CartTile({
    required this.line,
    required this.onMinus,
    required this.onPlus,
    required this.onDelete,
  });

  final CartLine line;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
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
          BookCover(book: line.book, height: 88),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(line.book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Text(line.book.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(formatPrice(line.book.price),
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: line.quantity > 1 ? onMinus : null,
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.remove,
                              size: 16,
                              color: line.quantity > 1
                                  ? AppColors.textPrimary
                                  : AppColors.border),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text('${line.quantity}',
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                      InkWell(
                        onTap: onPlus,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.add, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline,
                color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
