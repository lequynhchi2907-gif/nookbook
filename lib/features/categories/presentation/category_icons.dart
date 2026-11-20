import 'package:flutter/material.dart';

/// Chọn icon theo tên thể loại (backend không có trường icon).
IconData categoryIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('phát triển') || n.contains('kỹ năng')) return Icons.eco_outlined;
  if (n.contains('kinh')) return Icons.work_outline;
  if (n.contains('thiếu nhi')) return Icons.auto_awesome_outlined;
  if (n.contains('lịch sử')) return Icons.account_balance_outlined;
  if (n.contains('nghệ thuật')) return Icons.palette_outlined;
  return Icons.menu_book_outlined;
}
