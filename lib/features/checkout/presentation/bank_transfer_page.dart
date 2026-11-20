import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/config/app_config.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/features/orders/domain/placed_order.dart';

/// Màn 15 "Chuyển khoản ngân hàng". Mã QR chỉ để minh họa, chưa dùng để chuyển tiền thật.
class BankTransferPage extends StatelessWidget {
  const BankTransferPage({super.key, required this.order});

  final PlacedOrder? order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final o = order;
    if (o == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chuyển khoản ngân hàng')),
        body: Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.orders),
            child: const Text('Xem đơn hàng của tôi'),
          ),
        ),
      );
    }
    final code = orderCode(o.orderId);
    final content = 'NOOKBOOK NB${o.orderId}';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chuyển khoản ngân hàng'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Chờ xác nhận thanh toán',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Đơn $code · Vui lòng chuyển đúng số tiền và nội dung để được đối soát.',
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Center(child: _FakeQr(seed: o.orderId)),
          const SizedBox(height: 6),
          const Center(
            child: Text('QR minh họa · Không dùng để chuyển tiền',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(formatPrice(o.total),
                style: theme.textTheme.headlineMedium?.copyWith(color: AppColors.primary)),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _InfoRow('Ngân hàng', AppConfig.bankName),
                const SizedBox(height: 8),
                _InfoRow('Chủ tài khoản', AppConfig.bankAccountName),
                const SizedBox(height: 8),
                _CopyRow(value: AppConfig.bankAccountNumber, label: 'số tài khoản'),
                const Divider(height: 24),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Nội dung chuyển khoản',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
                const SizedBox(height: 4),
                _CopyRow(value: content, label: 'nội dung chuyển khoản'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Thông tin tài khoản minh họa. Thanh toán chưa được xác nhận; NookBook sẽ thông báo sau khi kiểm tra giao dịch.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.orderDetail(o.orderId)),
            child: const Text('Xem trạng thái đơn hàng'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

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

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: value));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã sao chép $label')),
                );
              }
            },
            icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.primary),
          ),
        ],
      );
}

/// Ô vuông giống mã QR, sinh theo mã đơn (chỉ minh họa).
class _FakeQr extends StatelessWidget {
  const _FakeQr({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) => Container(
        width: 170,
        height: 170,
        padding: const EdgeInsets.all(10),
        color: Colors.white,
        child: CustomPaint(painter: _QrPainter(seed)),
      );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.seed);

  final int seed;
  static const _n = 25;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(seed);
    final cell = size.width / _n;
    final paint = Paint()..color = Colors.black;

    bool inFinder(int x, int y) =>
        (x < 8 && y < 8) || (x >= _n - 8 && y < 8) || (x < 8 && y >= _n - 8);

    for (var y = 0; y < _n; y++) {
      for (var x = 0; x < _n; x++) {
        if (inFinder(x, y)) continue;
        if (rnd.nextBool()) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
    void finder(int ox, int oy) {
      canvas.drawRect(Rect.fromLTWH(ox * cell, oy * cell, 7 * cell, 7 * cell), paint);
      canvas.drawRect(
        Rect.fromLTWH((ox + 1) * cell, (oy + 1) * cell, 5 * cell, 5 * cell),
        Paint()..color = Colors.white,
      );
      canvas.drawRect(
        Rect.fromLTWH((ox + 2) * cell, (oy + 2) * cell, 3 * cell, 3 * cell),
        paint,
      );
    }

    finder(0, 0);
    finder(_n - 7, 0);
    finder(0, _n - 7);
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) => old.seed != seed;
}
