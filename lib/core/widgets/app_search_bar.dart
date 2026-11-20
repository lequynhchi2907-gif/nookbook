import 'package:flutter/material.dart';

/// Ô tìm kiếm. Ở Trang chủ / Tủ sách dùng readOnly + onTap để mở trang Tìm kiếm.
/// Khi có controller và đã nhập chữ, hiện nút X để xóa (màn 04, 05).
class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.readOnly = false,
    this.autofocus = false,
    this.onTap,
    this.onSubmitted,
    this.onChanged,
    this.onClear,
    this.onFilterTap,
    this.hint = 'Tìm sách, tác giả...',
  });

  final TextEditingController? controller;
  final bool readOnly;
  final bool autofocus;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onFilterTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null) return _field(null);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: c,
      builder: (_, value, __) => _field(value.text),
    );
  }

  Widget _field(String? text) {
    Widget? suffix;
    if (!readOnly && text != null && text.isNotEmpty) {
      suffix = IconButton(
        onPressed: () {
          controller?.clear();
          onChanged?.call('');
          onClear?.call();
        },
        icon: const Icon(Icons.close),
      );
    } else if (onFilterTap != null) {
      suffix = IconButton(onPressed: onFilterTap, icon: const Icon(Icons.tune));
    }
    return TextField(
      controller: controller,
      readOnly: readOnly,
      autofocus: autofocus,
      onTap: onTap,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: suffix,
      ),
    );
  }
}
