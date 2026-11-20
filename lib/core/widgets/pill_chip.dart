import 'package:flutter/material.dart';
import 'package:nookbook/core/theme/app_colors.dart';

/// Chip bo tròn dùng cho bộ lọc: "Tất cả", "Đang xử lý", tên thể loại...
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.showCheck = false,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  /// Hiện dấu tích khi đang chọn (bộ lọc nhiều lựa chọn).
  final bool showCheck;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySoft : AppColors.cardTint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected && showCheck) ...[
              const Icon(Icons.check, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
