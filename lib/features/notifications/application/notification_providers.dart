import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nookbook/core/config/app_config.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/status_chip.dart';
import 'package:nookbook/features/notifications/domain/app_notification.dart';
import 'package:nookbook/features/orders/application/order_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thông báo suy ra từ đơn hàng: mỗi đơn một thông báo theo trạng thái hiện tại.
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) async {
  final orders = await ref.watch(ordersProvider.future);
  final list = <AppNotification>[];
  for (final o in orders) {
    final code = orderCode(o.id);
    final time = o.orderDate ?? DateTime.now();
    switch (o.status) {
      case OrderStatus.processing:
        list.add(AppNotification(
          id: 'order-${o.id}-processing',
          kind: NotificationKind.order,
          title: 'Đã tiếp nhận đơn hàng',
          body: 'NookBook đang chuẩn bị ${o.itemCount} cuốn sách trong đơn $code.',
          time: time,
          icon: Icons.inventory_2_outlined,
          orderId: o.id,
        ));
      case OrderStatus.shipping:
        list.add(AppNotification(
          id: 'order-${o.id}-shipping',
          kind: NotificationKind.order,
          title: 'Sách đang trên đường đến bạn',
          body: 'Đơn $code đã được bàn giao cho đơn vị vận chuyển.',
          time: time,
          icon: Icons.local_shipping_outlined,
          orderId: o.id,
        ));
      case OrderStatus.delivered:
        list.add(AppNotification(
          id: 'order-${o.id}-delivered',
          kind: NotificationKind.order,
          title: 'Đơn hàng đã giao',
          body: 'Đơn $code đã được giao thành công. Chúc bạn đọc sách vui!',
          time: time,
          icon: Icons.inventory_outlined,
          orderId: o.id,
        ));
    }
  }
  if (AppConfig.useMock) {
    list.add(AppNotification(
      id: 'promo-reading-corner',
      kind: NotificationKind.promo,
      title: 'Góc đọc tháng 11 đã mở',
      body: 'Những cuốn sách ấm áp cho những ngày cuối năm.',
      time: DateTime(2026, 11, 4),
      icon: Icons.card_giftcard_outlined,
    ));
  }
  list.sort((a, b) => b.time.compareTo(a.time));
  return list;
});

final notificationByIdProvider =
    Provider.family<AppNotification?, String>((ref, id) {
  final list = ref.watch(notificationsProvider).valueOrNull ?? const [];
  for (final n in list) {
    if (n.id == id) return n;
  }
  return null;
});

/// Các thông báo đã đọc (lưu trong máy).
class ReadNotificationsNotifier extends Notifier<Set<String>> {
  static const _key = 'read_notification_ids';

  @override
  Set<String> build() {
    _load();
    return <String>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (prefs.getStringList(_key) ?? const <String>[]).toSet();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }

  Future<void> markRead(String id) async {
    if (state.contains(id)) return;
    state = {...state, id};
    await _save();
  }

  Future<void> markAllRead(Iterable<String> ids) async {
    state = {...state, ...ids};
    await _save();
  }
}

final readNotificationsProvider =
    NotifierProvider<ReadNotificationsNotifier, Set<String>>(
        ReadNotificationsNotifier.new);

/// Số thông báo chưa đọc (hiện chấm đỏ ở chuông trang chủ).
final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).valueOrNull ?? const [];
  final read = ref.watch(readNotificationsProvider);
  return list.where((n) => !read.contains(n.id)).length;
});
