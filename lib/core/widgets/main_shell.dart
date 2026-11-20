import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/features/cart/application/cart_providers.dart';
import 'package:nookbook/features/cart/presentation/cart_bottom_sheet.dart';

/// Khung chứa 5 tab: Trang chủ / Khám phá / Giỏ hàng / Đơn hàng / Tài khoản.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartCount = ref.watch(cartProvider).valueOrNull?.fold<int>(
              0,
              (total, line) => total + line.quantity,
            ) ??
        0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 72,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Trang chủ',
                  selected: navigationShell.currentIndex == 0,
                  onTap: () => _go(context, 0)),
              _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore,
                  label: 'Khám phá',
                  selected: navigationShell.currentIndex == 1,
                  onTap: () => _go(context, 1)),
              _CartNavItem(
                  count: cartCount,
                  selected: navigationShell.currentIndex == 2,
                  onTap: () => _go(context, 2)),
              _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'Đơn hàng',
                  selected: navigationShell.currentIndex == 3,
                  onTap: () => _go(context, 3)),
              _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Tài khoản',
                  selected: navigationShell.currentIndex == 4,
                  onTap: () => _go(context, 4)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _go(BuildContext context, int index) async {
    if (index == 2) {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CartBottomSheet(
          onViewCart: () {
            Navigator.of(context).pop();
            context.go(AppRoutes.cart);
          },
        ),
      );
      return;
    }
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem(
      {required this.icon,
      required this.activeIcon,
      required this.label,
      required this.selected,
      required this.onTap});
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? activeIcon : icon,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                  size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary)),
            ],
          ),
        ),
      );
}

class _CartNavItem extends StatelessWidget {
  const _CartNavItem(
      {required this.count, required this.selected, required this.onTap});
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 68,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary
                            : AppColors.primarySoft,
                        shape: BoxShape.circle),
                    child: Icon(
                        selected
                            ? Icons.shopping_bag
                            : Icons.shopping_bag_outlined,
                        color: selected ? Colors.white : AppColors.primary),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -3,
                      top: -5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        constraints:
                            const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: const BoxDecoration(
                            color: AppColors.textPrimary,
                            shape: BoxShape.circle),
                        child: Text('$count',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 1),
              Text('Giỏ hàng',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected
                          ? AppColors.primary
                          : AppColors.textSecondary)),
            ],
          ),
        ),
      );
}
