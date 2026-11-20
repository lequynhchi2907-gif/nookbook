import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/features/account/application/profile_providers.dart';
import 'package:nookbook/features/notifications/application/notification_providers.dart';
import 'package:nookbook/features/orders/application/order_providers.dart';
import 'package:nookbook/features/orders/domain/order.dart';

/// Màn 26 "Chi tiết thông báo".
class NotificationDetailPage extends ConsumerWidget {
  const NotificationDetailPage({super.key, required this.notificationId});

  final String notificationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final n = ref.watch(notificationByIdProvider(notificationId));
    final name = ref.watch(profileProvider).displayName;
    // Nếu mở thẳng link mà danh sách chưa tải, ép tải để tra được thông báo.
    ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết thông báo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.notifications),
        ),
      ),
      body: n == null
          ? const ErrorView(message: 'Không tìm thấy thông báo này.')
          : Consumer(
              builder: (context, ref, _) {
                final order = n.orderId == null
                    ? null
                    : ref.watch(orderByIdProvider(n.orderId!)).valueOrNull;
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(n.kindLabel,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(n.icon, color: AppColors.primary, size: 30),
                    ),
                    const SizedBox(height: 16),
                    Text(n.title, style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(formatDateTime(n.time),
                        style: const TextStyle(color: AppColors.textSecondary)),
                    const Divider(height: 32),
                    Text('Chào $name,', style: const TextStyle(height: 1.5)),
                    const SizedBox(height: 8),
                    Text(n.body,
                        style: const TextStyle(
                            color: AppColors.textSecondary, height: 1.5)),
                    if (order != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            _Row('Mã đơn', orderCode(order.id)),
                            const SizedBox(height: 8),
                            _Row('Số lượng', '${order.itemCount} cuốn'),
                            const SizedBox(height: 8),
                            _Row('Tổng tiền',
                                formatPrice(order.total + orderShippingFee(order.total))),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    if (n.orderId != null)
                      ElevatedButton(
                        onPressed: () => context.push(AppRoutes.orderDetail(n.orderId!)),
                        child: const Text('Xem chi tiết đơn hàng'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () => context.go(AppRoutes.categoryBooks),
                        child: const Text('Khám phá sách'),
                      ),
                  ],
                );
              },
            ),
    );
  }
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
