import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/widgets/confirm_dialog.dart';
import 'package:nookbook/features/auth/application/auth_providers.dart';

/// Khung 4 tab của quản trị viên: Tổng quan / Sách / Danh mục / Đơn hàng.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Tổng quan'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Sách'),
          BottomNavigationBarItem(
              icon: Icon(Icons.layers_outlined),
              activeIcon: Icon(Icons.layers),
              label: 'Danh mục'),
          BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: 'Đơn hàng'),
        ],
      ),
    );
  }
}

/// Nút đăng xuất ở góc phải thanh tiêu đề của các màn quản trị.
class AdminLogoutButton extends ConsumerWidget {
  const AdminLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Đăng xuất',
      icon: const Icon(Icons.logout),
      color: Theme.of(context).colorScheme.primary,
      onPressed: () async {
        final ok = await showConfirmDialog(
          context,
          icon: Icons.logout,
          title: 'Bạn muốn đăng xuất?',
          message: 'Phiên quản trị sẽ kết thúc trên thiết bị này.',
          confirmLabel: 'Đăng xuất',
          destructive: false,
        );
        if (ok) await ref.read(authProvider.notifier).logout();
      },
    );
  }
}
