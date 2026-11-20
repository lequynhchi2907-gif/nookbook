import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/config/app_config.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/app_sheet.dart';
import 'package:nookbook/core/widgets/app_toast.dart';
import 'package:nookbook/core/widgets/empty_state.dart';
import 'package:nookbook/core/widgets/error_view.dart';
import 'package:nookbook/core/widgets/option_tile.dart';
import 'package:nookbook/features/account/application/profile_providers.dart';
import 'package:nookbook/features/cart/application/cart_providers.dart';
import 'package:nookbook/features/checkout/presentation/shipping_info_sheet.dart';
import 'package:nookbook/features/orders/application/order_providers.dart';
import 'package:nookbook/features/orders/domain/payment_method.dart';
import 'package:nookbook/features/orders/domain/placed_order.dart';

/// Màn 13 "Thanh toán" + màn 14 "Chọn phương thức thanh toán".
class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  PaymentMethod _method = PaymentMethod.cod;
  final _note = TextEditingController();
  bool _placing = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickMethod() async {
    final picked = await showAppSheet<PaymentMethod>(
      context,
      title: 'Phương thức thanh toán',
      builder: (_) => _MethodBody(initial: _method),
    );
    if (picked != null) setState(() => _method = picked);
  }

  Future<void> _place(double fee) async {
    var profile = ref.read(profileProvider);
    if (!profile.hasShippingInfo) {
      final saved = await showShippingInfoSheet(context, profile);
      if (saved == null) return;
      await ref.read(profileProvider.notifier).update(saved);
      profile = saved;
    }
    final subtotal = cartSubtotal(ref.read(cartProvider).valueOrNull ?? const []);
    setState(() => _placing = true);
    try {
      // Ghi chú được nối vào địa chỉ vì backend chưa có trường ghi chú.
      final note = _note.text.trim();
      final address = note.isEmpty
          ? profile.shippingAddress
          : '${profile.shippingAddress} · Ghi chú: $note';
      final order = await ref
          .read(orderRepositoryProvider)
          .placeOrder(shippingAddress: address);
      await ref.read(paymentMethodsProvider.notifier).remember(order.id, _method);
      ref.invalidate(ordersProvider);
      await ref.read(cartProvider.notifier).reload();
      if (!mounted) return;
      final now = DateTime.now();
      final placed = PlacedOrder(
        orderId: order.id,
        total: (order.total > 0 ? order.total : subtotal) + fee,
        method: _method,
        expectedFrom: now.add(const Duration(days: 3)),
        expectedTo: now.add(const Duration(days: 5)),
      );
      if (_method == PaymentMethod.bank) {
        context.go(AppRoutes.bankTransfer, extra: placed);
      } else {
        context.go(AppRoutes.orderSuccess, extra: placed);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, title: 'Chưa thể đặt hàng', message: errorMessage(e));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = ref.watch(cartProvider);
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: errorMessage(e),
          onRetry: () => ref.read(cartProvider.notifier).reload(),
        ),
        data: (lines) {
          if (lines.isEmpty) {
            return EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Chưa có sách để thanh toán',
              message: 'Hãy thêm vài cuốn sách vào giỏ trước nhé.',
              buttonLabel: 'Khám phá sách ngay',
              onPressed: () => context.go(AppRoutes.categoryBooks),
            );
          }
          final subtotal = cartSubtotal(lines);
          final fee = AppConfig.shippingFeeFor(subtotal);
          final total = subtotal + fee;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  children: [
                    _Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text('Địa chỉ nhận hàng',
                                    style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final saved =
                                      await showShippingInfoSheet(context, profile);
                                  if (saved != null) {
                                    await ref
                                        .read(profileProvider.notifier)
                                        .update(saved);
                                  }
                                },
                                child: Text(
                                  profile.hasShippingInfo ? 'Đổi' : 'Thêm',
                                  style: const TextStyle(
                                      color: AppColors.primary, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (profile.hasShippingInfo) ...[
                            Text(
                              [profile.name, profile.phone]
                                  .where((e) => e.isNotEmpty)
                                  .join(' · '),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(profile.address,
                                style: const TextStyle(
                                    color: AppColors.textSecondary, fontSize: 13)),
                          ] else
                            const Text('Chưa có địa chỉ. Bấm "Thêm" để nhập địa chỉ giao hàng.',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Đơn hàng của bạn', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    _Card(
                      child: Column(
                        children: [
                          for (final l in lines)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text('${l.book.title} × ${l.quantity}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: AppColors.textSecondary)),
                                  ),
                                  Text(formatPrice(l.total),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: _pickMethod,
                      child: _Card(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _method == PaymentMethod.cod
                                      ? Icons.payments_outlined
                                      : Icons.account_balance_outlined,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(_method.title)),
                                const Icon(Icons.chevron_right),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('Bạn có thể chọn COD hoặc chuyển khoản.',
                                style: TextStyle(
                                    color: AppColors.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Ghi chú đơn hàng',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _note,
                      decoration: const InputDecoration(
                        hintText: 'Lời nhắn cho NookBook (không bắt buộc)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Card(
                      child: Column(
                        children: [
                          _Row('Tạm tính', formatPrice(subtotal)),
                          const SizedBox(height: 8),
                          _Row('Giao hàng tiêu chuẩn',
                              fee == 0 ? 'Miễn phí' : formatPrice(fee)),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Tổng thanh toán',
                                  style: TextStyle(fontWeight: FontWeight.w700)),
                              Text(formatPrice(total),
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(color: AppColors.primary)),
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
                  onPressed: _placing ? null : () => _place(fee),
                  child: _placing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white),
                        )
                      : Text('Đặt hàng · ${formatPrice(total)}'),
                ),
              ),
            ],
          );
        },
      ),
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

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

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

class _MethodBody extends StatefulWidget {
  const _MethodBody({required this.initial});

  final PaymentMethod initial;

  @override
  State<_MethodBody> createState() => _MethodBodyState();
}

class _MethodBodyState extends State<_MethodBody> {
  late PaymentMethod _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OptionTile(
          icon: Icons.payments_outlined,
          title: PaymentMethod.cod.title,
          subtitle: PaymentMethod.cod.subtitle,
          selected: _selected == PaymentMethod.cod,
          onTap: () => setState(() => _selected = PaymentMethod.cod),
        ),
        const SizedBox(height: 10),
        OptionTile(
          icon: Icons.account_balance_outlined,
          title: PaymentMethod.bank.title,
          subtitle: PaymentMethod.bank.subtitle,
          selected: _selected == PaymentMethod.bank,
          onTap: () => setState(() => _selected = PaymentMethod.bank),
        ),
        const SizedBox(height: 12),
        const Text(
          'Đơn chuyển khoản chỉ được xác nhận sau khi NookBook kiểm tra giao dịch.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Xác nhận phương thức'),
        ),
      ],
    );
  }
}
