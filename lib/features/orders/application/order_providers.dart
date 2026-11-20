import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nookbook/core/config/app_config.dart';
import 'package:nookbook/core/network/api_client.dart';
import 'package:nookbook/features/orders/data/order_repository.dart';
import 'package:nookbook/features/orders/domain/order.dart';
import 'package:nookbook/features/orders/domain/payment_method.dart';
import 'package:shared_preferences/shared_preferences.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  if (AppConfig.useMock) return MockOrderRepository();
  return ApiOrderRepository(ref.watch(dioProvider));
});

final ordersProvider = FutureProvider<List<Order>>(
  (ref) => ref.watch(orderRepositoryProvider).getOrders(),
);

final orderByIdProvider = FutureProvider.family<Order?, int>((ref, id) async {
  final list = await ref.watch(ordersProvider.future);
  for (final o in list) {
    if (o.id == id) return o;
  }
  return null;
});

/// Nhớ phương thức thanh toán đã chọn cho từng đơn (backend chưa lưu).
class PaymentMethodsNotifier extends Notifier<Map<int, PaymentMethod>> {
  static const _key = 'order_payment_methods';

  @override
  Map<int, PaymentMethod> build() {
    _load();
    return const {};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return;
    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      state = {
        for (final e in map.entries)
          int.parse(e.key): e.value == 'bank' ? PaymentMethod.bank : PaymentMethod.cod,
      };
    } catch (_) {}
  }

  Future<void> remember(int orderId, PaymentMethod method) async {
    state = {...state, orderId: method};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      json.encode({for (final e in state.entries) '${e.key}': e.value.name}),
    );
  }
}

final paymentMethodsProvider =
    NotifierProvider<PaymentMethodsNotifier, Map<int, PaymentMethod>>(
        PaymentMethodsNotifier.new);
