import 'package:flutter/material.dart';

enum NotificationKind { order, promo }

/// Thông báo hiển thị trong Trung tâm thông báo.
/// Backend chưa có API thông báo nên app tự suy ra từ danh sách đơn hàng.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    this.orderId,
  });

  final String id;
  final NotificationKind kind;
  final String title;
  final String body;
  final DateTime time;
  final IconData icon;

  /// Có giá trị với thông báo đơn hàng, để mở "Chi tiết đơn hàng".
  final int? orderId;

  String get kindLabel => kind == NotificationKind.order ? 'Đơn hàng' : 'Sách & ưu đãi';
}
