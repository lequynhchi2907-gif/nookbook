import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/status_chip.dart';
import 'package:nookbook/features/orders/domain/payment_method.dart';
import 'package:nookbook/features/orders/domain/placed_order.dart';

/// Màn 16 "Đặt hàng thành công".
class OrderSuccessPage extends StatelessWidget {
  const OrderSuccessPage({super.key, required this.order});

  final PlacedOrder? order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = order;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đặt hàng thành công'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.successSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 44, color: AppColors.success),
            ),
          ),
          const SizedBox(height: 24),
          Text('Cảm ơn bạn đã chọn NookBook!',
              textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Đơn hàng đã được tiếp nhận. Những trang sách mới sắp đến tay bạn.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Center(child: StatusChip(status: OrderStatus.processing)),
          const SizedBox(height: 20),
          if (o != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  _Row('Mã đơn hàng', orderCode(o.orderId)),
                  const SizedBox(height: 8),
                  _Row('Thanh toán', o.method.shortLabel),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tổng thanh toán',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(formatPrice(o.total),
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dự kiến giao: ${_short(o.expectedFrom)}–${formatDate(o.expectedTo)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Chúng tôi sẽ gửi thông báo khi đơn hàng được bàn giao cho đơn vị vận chuyển.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => o == null
                ? context.go(AppRoutes.orders)
                : context.go(AppRoutes.orderDetail(o.orderId)),
            child: const Text('Theo dõi đơn hàng'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Tiếp tục chọn sách'),
          ),
        ],
      ),
    );
  }

  /// 09/11 (bỏ năm để ghép với ngày kết thúc: "09–11/11/2026").
  String _short(DateTime d) => d.day.toString().padLeft(2, '0');
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}
