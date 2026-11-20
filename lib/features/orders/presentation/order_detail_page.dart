import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/core/widgets/status_chip.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/orders/application/order_providers.dart';
import 'package:nookbook/features/orders/domain/order.dart';
import 'package:nookbook/features/orders/domain/payment_method.dart';

/// Màn 18 "Chi tiết đơn hàng".
class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderByIdProvider(orderId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết đơn hàng'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.orders),
        ),
      ),
      body: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: errorMessage(e),
          onRetry: () => ref.invalidate(ordersProvider),
        ),
        data: (o) => o == null
            ? const ErrorView(message: 'Không tìm thấy đơn hàng này.')
            : _Body(order: o),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final method = ref.watch(paymentMethodsProvider)[order.id];
    final parts = order.addressParts;
    final fee = orderShippingFee(order.total);
    final total = order.total + fee;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(orderCode(order.id), style: const TextStyle(fontWeight: FontWeight.w700)),
            StatusChip(status: order.status),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          [
            if (order.orderDate != null) 'Đặt ngày ${formatDate(order.orderDate!)}',
            if (method != null) method.title,
          ].join(' · '),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hành trình đơn hàng', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              _TimelineStep(
                label: OrderStatus.processing.label,
                note: 'Đã xác nhận',
                done: true,
                last: false,
              ),
              _TimelineStep(
                label: OrderStatus.shipping.label,
                note: 'Đang vận chuyển',
                done: order.status != OrderStatus.processing,
                last: false,
              ),
              _TimelineStep(
                label: OrderStatus.delivered.label,
                note: order.status == OrderStatus.delivered
                    ? 'Đã giao thành công'
                    : 'Dự kiến trong vài ngày tới',
                done: order.status == OrderStatus.delivered,
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Địa chỉ nhận hàng',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 10),
              if (parts.name.isNotEmpty)
                Text(
                  [parts.name, parts.phone].where((e) => e.isNotEmpty).join(' · '),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              const SizedBox(height: 4),
              Text(parts.address,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sách trong đơn', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              for (final item in order.items)
                _ItemLine(bookId: item.bookId, quantity: item.quantity),
              const Divider(height: 24),
              _Line('Phí giao hàng', fee == 0 ? 'Miễn phí' : formatPrice(fee)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(formatPrice(total),
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(color: AppColors.primary)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (method != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method == PaymentMethod.cod
                      ? 'Thanh toán khi nhận hàng (COD)'
                      : 'Chuyển khoản ngân hàng',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  method == PaymentMethod.cod
                      ? 'Vui lòng chuẩn bị ${formatPrice(total)} khi nhận sách.'
                      : 'NookBook sẽ xác nhận sau khi kiểm tra giao dịch.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Hỗ trợ: liên hệ cửa hàng NookBook để được giúp đỡ.')),
          ),
          icon: const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Liên hệ hỗ trợ'),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);

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

class _ItemLine extends ConsumerWidget {
  const _ItemLine({required this.bookId, required this.quantity});

  final int bookId;
  final int quantity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final book = ref.watch(bookOrNullProvider(bookId)).valueOrNull;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text('${book?.title ?? 'Sách #$bookId'} × $quantity',
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Text(book == null ? '' : formatPrice(book.price * quantity),
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.label,
    required this.note,
    required this.done,
    required this.last,
  });

  final String label;
  final String note;
  final bool done;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                done ? Icons.check_circle_outline : Icons.circle_outlined,
                color: done ? AppColors.success : AppColors.textSecondary,
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    color: done ? AppColors.success : AppColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: done ? AppColors.textPrimary : AppColors.textSecondary,
                      )),
                  Text(note,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
