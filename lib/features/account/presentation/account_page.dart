import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/core/utils/formatters.dart';
import 'package:nookbook/core/widgets/confirm_dialog.dart';
import 'package:nookbook/features/account/application/profile_providers.dart';
import 'package:nookbook/features/auth/application/auth_providers.dart';
import 'package:nookbook/features/checkout/presentation/shipping_info_sheet.dart';
import 'package:nookbook/features/favorites/application/favorites_providers.dart';
import 'package:nookbook/features/orders/application/order_providers.dart';

/// Màn 19 "Tài khoản" + màn 24 "Xác nhận đăng xuất".
class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  void _soon(BuildContext context, String what) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$what sẽ sớm có mặt ở phiên bản sau.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final orders = ref.watch(ordersProvider).valueOrNull;
    final favorites = ref.watch(favoritesProvider);

    Future<void> editInfo() async {
      final saved = await showShippingInfoSheet(context, profile);
      if (saved != null) await ref.read(profileProvider.notifier).update(saved);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          _Group(children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      initials(profile.displayName),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        if (profile.email.isNotEmpty)
                          Text(profile.email,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                        const Text('Thành viên yêu sách',
                            style: TextStyle(color: AppColors.primary, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _Group(children: [
            _Item(
              icon: Icons.inventory_2_outlined,
              label: 'Đơn hàng của tôi',
              trailing: orders == null ? null : '${orders.length}',
              onTap: () => context.push(AppRoutes.orders),
            ),
            _Item(
              icon: Icons.favorite_border,
              label: 'Sách yêu thích',
              trailing: '${favorites.length}',
              onTap: () => context.push(AppRoutes.favorites),
            ),
            _Item(
              icon: Icons.location_on_outlined,
              label: 'Địa chỉ nhận hàng',
              onTap: editInfo,
            ),
          ]),
          const SizedBox(height: 16),
          _Group(children: [
            _Item(
              icon: Icons.person_outline,
              label: 'Thông tin cá nhân',
              onTap: editInfo,
            ),
            _Item(
              icon: Icons.notifications_none,
              label: 'Thông báo',
              onTap: () => context.push(AppRoutes.notifications),
            ),
            _Item(
              icon: Icons.help_outline,
              label: 'Trợ giúp & liên hệ',
              onTap: () => _soon(context, 'Trợ giúp & liên hệ'),
            ),
            _Item(
              icon: Icons.shield_outlined,
              label: 'Chính sách bảo mật',
              onTap: () => _soon(context, 'Chính sách bảo mật'),
            ),
          ]),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () async {
              final ok = await showConfirmDialog(
                context,
                icon: Icons.logout,
                title: 'Bạn muốn đăng xuất?',
                message:
                    'Danh sách yêu thích và đơn hàng của bạn vẫn được lưu. Hẹn gặp bạn ở những trang sách tiếp theo.',
                confirmLabel: 'Đăng xuất',
                destructive: false,
              );
              if (ok) await ref.read(authProvider.notifier).logout();
            },
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppColors.primary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Đăng xuất',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                  Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: children),
      );
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.label, required this.onTap, this.trailing});

  final IconData icon;
  final String label;
  final String? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: AppColors.textPrimary),
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null)
              Text(trailing!,
                  style: const TextStyle(color: AppColors.textSecondary)),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
        onTap: onTap,
      );
}
