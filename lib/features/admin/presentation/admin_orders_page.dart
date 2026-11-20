import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/app_search_bar.dart';
import 'package:nookbook/core/widgets/app_sheet.dart';
import 'package:nookbook/core/widgets/app_toast.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/core/widgets/option_tile.dart';
import 'package:nookbook/core/widgets/pill_chip.dart';
import 'package:nookbook/core/widgets/status_chip.dart';
import 'package:nookbook/features/admin/presentation/admin_shell.dart';
import 'package:nookbook/features/orders/application/order_providers.dart';
import 'package:nookbook/features/orders/domain/order.dart';
import 'package:nookbook/features/orders/presentation/widgets/order_summary_row.dart';

/// Màn 38 "Quản lý đơn hàng" và màn 39 "Đổi trạng thái đơn".
/// Lưu ý: dùng GET /orders. Nếu backend chỉ trả đơn của tài khoản đang đăng nhập thì
/// quản trị viên chỉ thấy đơn của mình; cần một API "tất cả đơn" ở backend.
class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  final _search = TextEditingController();
  String _query = '';
  OrderStatus? _filter;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _changeStatus(Order o) async {
    final picked = await showAppSheet<OrderStatus>(
      context,
      title: 'Cập nhật đơn hàng',
      subtitle: '${orderCode(o.id)}${o.addressParts.name.isEmpty ? '' : ' · ${o.addressParts.name}'}',
      builder: (_) => _StatusBody(initial: o.status),
    );
    if (picked == null || picked == o.status || !mounted) return;
    try {
      await ref.read(orderRepositoryProvider).updateStatus(o.id, picked);
      ref.invalidate(ordersProvider);
      if (mounted) {
        AppToast.success(context,
            title: 'Đã cập nhật trạng thái', message: '${orderCode(o.id)} · ${picked.label}');
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context,
            title: 'Chưa thể cập nhật', message: errorMessage(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = ref.watch(ordersProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý đơn hàng'),
        actions: const [AdminLogoutButton()],
      ),
      body: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: errorMessage(e),
          onRetry: () => ref.invalidate(ordersProvider),
        ),
        data: (all) {
          final q = _query.toLowerCase();
          var list = _filter == null ? all : all.where((o) => o.status == _filter).toList();
          if (q.isNotEmpty) {
            list = list
                .where((o) =>
                    orderCode(o.id).toLowerCase().contains(q) ||
                    o.shippingAddress.toLowerCase().contains(q))
                .toList();
          }
          int count(OrderStatus s) => all.where((o) => o.status == s).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              AppSearchBar(
                controller: _search,
                hint: 'Tìm mã đơn, tên khách hàng',
                onChanged: (v) => setState(() => _query = v.trim()),
                onClear: () => setState(() => _query = ''),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    PillChip(
                      label: 'Tất cả · ${all.length}',
                      selected: _filter == null,
                      onTap: () => setState(() => _filter = null),
                    ),
                    for (final s in OrderStatus.values) ...[
                      const SizedBox(width: 8),
                      PillChip(
                        label: '${s.label} · ${count(s)}',
                        selected: _filter == s,
                        onTap: () => setState(() => _filter = s),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: Text('Không có đơn hàng phù hợp.')),
                ),
              for (final o in list) ...[
                _AdminOrderCard(order: o, onChangeStatus: () => _changeStatus(o)),
                const SizedBox(height: 12),
              ],
              if (list.isNotEmpty)
                Center(
                  child: Text('Hiển thị ${list.length}/${all.length} đơn hàng',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order, required this.onChangeStatus});

  final Order order;
  final VoidCallback onChangeStatus;

  @override
  Widget build(BuildContext context) {
    final name = order.addressParts.name;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(orderCode(order.id),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              StatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              name.isEmpty ? 'Khách hàng' : name,
              if (order.orderDate != null) formatDate(order.orderDate!),
            ].join(' · '),
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          OrderSummaryRow(order: order),
          const Divider(height: 24),
          InkWell(
            onTap: onChangeStatus,
            child: Row(
              children: [
                const Icon(Icons.sync, size: 20),
                const SizedBox(width: 10),
                const Expanded(child: Text('Cập nhật trạng thái')),
                Text(order.status.label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                const Icon(Icons.chevron_right, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBody extends StatefulWidget {
  const _StatusBody({required this.initial});

  final OrderStatus initial;

  @override
  State<_StatusBody> createState() => _StatusBodyState();
}

class _StatusBodyState extends State<_StatusBody> {
  late OrderStatus _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final s in OrderStatus.values) ...[
          OptionTile(
            icon: s.icon,
            title: s.label,
            subtitle: s.description,
            selected: _selected == s,
            onTap: () => setState(() => _selected = s),
          ),
          const SizedBox(height: 10),
        ],
        const Text(
          'Khách hàng sẽ nhận thông báo sau khi trạng thái được cập nhật.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Lưu trạng thái'),
        ),
      ],
    );
  }
}
