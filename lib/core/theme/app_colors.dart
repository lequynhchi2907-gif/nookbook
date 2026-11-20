import 'package:flutter/material.dart';

/// Bảng màu ước lượng từ ảnh thiết kế.
/// TODO: dùng công cụ chấm màu (color picker) trên ảnh để chỉnh lại mã cho chuẩn.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFAF6F0); // nền kem
  static const primary =
      Color(0xFFA13E22); // cam đất đậm (nút, giá, tab đang chọn)
  static const primarySoft = Color(0xFFF3E4DA); // nền chip / icon tròn
  static const surface = Colors.white;
  static const cardTint = Color(0xFFF1EBE3); // nền khung ảnh bìa sách
  static const textPrimary = Color(0xFF2B2320);
  static const textSecondary = Color(0xFF7A6F69);
  static const border = Color(0xFFEDE5DC);
  static const success = Color(0xFF4F7A5A);
  static const successSoft = Color(0xFFE6EEE4);
  static const danger = Color(0xFFB8403A);
  static const dangerSoft = Color(0xFFF8E3E0);
  static const skeleton = Color(0xFFEDE5DA);
}
