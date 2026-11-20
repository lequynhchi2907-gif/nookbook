import 'package:flutter/material.dart';
import 'package:nookbook/core/theme/app_colors.dart';

/// Thông báo nổi ở đầu màn hình (màn 28 "Đã thêm vào giỏ", màn 29 "Chưa thể thêm vào giỏ").
class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  static void success(
    BuildContext context, {
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(context, title, message, actionLabel, onAction, AppColors.success,
          Icons.check_circle_outline);

  static void error(
    BuildContext context, {
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) =>
      _show(context, title, message, actionLabel, onAction, AppColors.danger,
          Icons.error_outline);

  static void _show(
    BuildContext context,
    String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    Color color,
    IconData icon,
  ) {
    final overlay = Overlay.of(context);
    _current?.remove();
    _current = null;

    late OverlayEntry entry;
    void close() {
      if (_current == entry) {
        entry.remove();
        _current = null;
      }
    }

    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        top: MediaQuery.of(ctx).padding.top + kToolbarHeight,
        left: 16,
        right: 16,
        child: _ToastBody(
          title: title,
          message: message,
          actionLabel: actionLabel,
          color: color,
          icon: icon,
          onAction: () {
            close();
            onAction?.call();
          },
          onTimeout: close,
        ),
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _ToastBody extends StatefulWidget {
  const _ToastBody({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.color,
    required this.icon,
    required this.onAction,
    required this.onTimeout,
  });

  final String title;
  final String? message;
  final String? actionLabel;
  final Color color;
  final IconData icon;
  final VoidCallback onAction;
  final VoidCallback onTimeout;

  @override
  State<_ToastBody> createState() => _ToastBodyState();
}

class _ToastBodyState extends State<_ToastBody> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onTimeout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.color,
      borderRadius: BorderRadius.circular(16),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(widget.icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  if (widget.message != null)
                    Text(
                      widget.message!,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                ],
              ),
            ),
            if (widget.actionLabel != null)
              TextButton(
                onPressed: widget.onAction,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(
                  widget.actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
