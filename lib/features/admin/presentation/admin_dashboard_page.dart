import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/core/widgets/status_chip.dart';
import 'package:nookbook/features/admin/presentation/admin_shell.dart';
import 'package:nookbook/features/books/application/book_providers.dart';
import 'package:nookbook/features/orders/application/order_providers.dart';
import 'package:nookbook/features/orders/domain/order.dart';

/// Màn 30 "Quản trị · Tổng quan".
/// Số liệu được tính từ danh sách sách / danh mục / đơn mà API hiện có
/// (backend chưa có API thống kê, tồn kho).
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  bool _isToday(DateTime? d) {
    if (d == null) return false;
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final books = ref.watch(booksProvider);
    final categories = ref.watch(categoriesProvider);
    final orders = ref.watch(ordersProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan'),
        actions: const [AdminLogoutButton()],
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: errorMessage(e),
          onRetry: () {
            ref.invalidate(ordersProvider);
            ref.invalidate(booksProvider);
          },
        ),
        data: (list) {
          final today = list.where((o) => _isToday(o.orderDate)).toList();
          final revenue = today.fold<double>(0, (s, o) => s + o.total);
          int count(OrderStatus s) => list.where((o) => o.status == s).length;
          final bookCount = books.valueOrNull?.length;
          final catCount = categories.valueOrNull?.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text('Xin chào, quản trị viên',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cửa hàng hôm nay', style: theme.textTheme.headlineSmall),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      color: AppColors.primarySoft,
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Doanh thu hôm nay',
                      value: formatPrice(revenue),
                      note: '${today.length} đơn trong ngày',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      color: Colors.white,
                      icon: Icons.inventory_2_outlined,
                      label: 'Đơn hàng mới',
                      value: '${today.length}',
                      note: '${count(OrderStatus.processing)} đơn đang xử lý',
                    ),
                  ),
                ],
              ),
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
                    _Line('Đầu sách', bookCount == null ? '—' : '$bookCount'),
                    const SizedBox(height: 10),
                    _Line('Danh mục', catCount == null ? '—' : '$catCount'),
                    const SizedBox(height: 10),
                    _Line('Đơn đang giao', '${count(OrderStatus.shipping)}'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Cần bạn xử lý', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: const Text('Đơn hàng chờ xử lý'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${count(OrderStatus.processing)}',
                              style:
                                  const TextStyle(color: AppColors.textSecondary)),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => context.go(AppRoutes.adminOrders),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.menu_book_outlined),
                      title: const Text('Thêm đầu sách mới'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.adminBookNew),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.note,
  });

  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color == Colors.white ? AppColors.border : color),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            ),
            const SizedBox(height: 4),
            Text(note,
                style: const TextStyle(color: AppColors.success, fontSize: 11)),
          ],
        ),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      );
}
