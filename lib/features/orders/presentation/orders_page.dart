import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/empty_state.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/core/widgets/status_chip.dart';
import 'package:nookbook/features/orders/application/order_providers.dart';
import 'package:nookbook/features/orders/domain/order.dart';

/// Lịch sử đơn hàng theo bố cục thẻ và tiến trình trong thiết kế.
class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    return Scaffold(
      body: SafeArea(
        child: orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
              message: errorMessage(e),
              onRetry: () => ref.invalidate(ordersProvider)),
          data: (list) => list.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Chưa có đơn hàng',
                  message: 'Các đơn bạn đặt sẽ xuất hiện tại đây.',
                  buttonLabel: 'Khám phá sách ngay',
                  onPressed: () => context.go(AppRoutes.categoryBooks),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  children: [
                    const Text('TÀI KHOẢN CỦA TÔI',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    const Text('Lịch sử đơn hàng',
                        style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: 30,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    const Text(
                        'Theo dõi hành trình những cuốn sách đến với bạn.',
                        style: TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 22),
                    for (final order in list) ...[
                      _OrderCard(order: order),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  const _OrderCard({required this.order});
  final Order order;

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  late bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => expanded = !expanded),
      child: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
              child: Row(
                children: [
                  Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: AppColors.cardTint,
                          borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.inventory_2_outlined,
                          color: AppColors.primary)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(orderCode(order.id),
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                            order.orderDate == null
                                ? ''
                                : formatDate(order.orderDate!),
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 11))
                      ])),
                  _StatusPill(status: order.status),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(58, 0, 16, 14),
              child: Row(children: [
                Text(formatPrice(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20)
              ]),
            ),
            if (expanded) ...[
              const Divider(height: 1),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  child: _OrderProgress(status: order.status)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final delivered = status == OrderStatus.delivered;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: delivered ? AppColors.successSoft : const Color(0xFFE3EEFC),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: TextStyle(
              color: delivered ? AppColors.success : const Color(0xFF3E76B8),
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _OrderProgress extends StatelessWidget {
  const _OrderProgress({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final delivered = status == OrderStatus.delivered;
    final shipping = status == OrderStatus.shipping;
    return Row(
      children: [
        _Step(icon: Icons.check, label: 'Đã xác nhận', active: true),
        _Line(active: shipping || delivered),
        _Step(
            icon: Icons.local_shipping_outlined,
            label: 'Đang vận chuyển',
            active: shipping || delivered),
        _Line(active: delivered),
        _Step(
            icon: Icons.home_outlined,
            label: 'Đã giao hàng',
            active: delivered),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.icon, required this.label, required this.active});
  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
          child: Column(children: [
        Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: active ? AppColors.primary : AppColors.cardTint,
                shape: BoxShape.circle),
            child: Icon(icon,
                color: active ? Colors.white : AppColors.textSecondary,
                size: 17)),
        const SizedBox(height: 7),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary))
      ]));
}

class _Line extends StatelessWidget {
  const _Line({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
      child: Container(
          height: 2, color: active ? AppColors.primary : AppColors.border));
}
