import 'package:flutter/material.dart';
import 'package:nookbook/core/theme/app_colors.dart';

enum OrderStatus { processing, shipping, delivered }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.processing => 'Đang xử lý',
        OrderStatus.shipping => 'Đang giao',
        OrderStatus.delivered => 'Đã giao',
      };

  String get description => switch (this) {
        OrderStatus.processing => 'Đơn hàng đang được chuẩn bị',
        OrderStatus.shipping => 'Đã bàn giao cho đơn vị vận chuyển',
        OrderStatus.delivered => 'Khách hàng đã nhận được sách',
      };

  IconData get icon => switch (this) {
        OrderStatus.processing => Icons.inventory_2_outlined,
        OrderStatus.shipping => Icons.local_shipping_outlined,
        OrderStatus.delivered => Icons.inventory_outlined,
      };
}

/// Nhãn trạng thái đơn hàng (Đang xử lý / Đang giao / Đã giao).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final delivered = status == OrderStatus.delivered;
    final fg = delivered ? AppColors.success : AppColors.primary;
    final bg = delivered ? AppColors.successSoft : AppColors.primarySoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
