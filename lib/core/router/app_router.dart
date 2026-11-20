import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nookbook/core/router/app_routes.dart';
import 'package:nookbook/core/widgets/main_shell.dart';
import 'package:nookbook/features/account/presentation/account_page.dart';
import 'package:nookbook/features/admin/presentation/admin_book_form_page.dart';
import 'package:nookbook/features/admin/presentation/admin_books_page.dart';
import 'package:nookbook/features/admin/presentation/admin_categories_page.dart';
import 'package:nookbook/features/admin/presentation/admin_dashboard_page.dart';
import 'package:nookbook/features/admin/presentation/admin_orders_page.dart';
import 'package:nookbook/features/admin/presentation/admin_shell.dart';
import 'package:nookbook/features/auth/application/auth_providers.dart';
import 'package:nookbook/features/auth/presentation/login_page.dart';
import 'package:nookbook/features/auth/presentation/register_page.dart';
import 'package:nookbook/features/books/presentation/book_detail_page.dart';
import 'package:nookbook/features/books/presentation/book_list_page.dart';
import 'package:nookbook/features/cart/presentation/cart_page.dart';
import 'package:nookbook/features/categories/presentation/categories_page.dart';
import 'package:nookbook/features/checkout/presentation/bank_transfer_page.dart';
import 'package:nookbook/features/checkout/presentation/checkout_page.dart';
import 'package:nookbook/features/checkout/presentation/order_success_page.dart';
import 'package:nookbook/features/favorites/presentation/favorites_page.dart';
import 'package:nookbook/features/home/presentation/home_page.dart';
import 'package:nookbook/features/notifications/presentation/notification_detail_page.dart';
import 'package:nookbook/features/notifications/presentation/notifications_page.dart';
import 'package:nookbook/features/orders/domain/placed_order.dart';
import 'package:nookbook/features/orders/presentation/order_detail_page.dart';
import 'package:nookbook/features/orders/presentation/orders_page.dart';
import 'package:nookbook/features/search/presentation/search_page.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Các trang bắt buộc đăng nhập.
const _protectedPrefixes = [
  AppRoutes.cart,
  AppRoutes.account,
  AppRoutes.checkout,
  AppRoutes.orders,
  AppRoutes.orderSuccess,
  AppRoutes.favorites,
  AppRoutes.notifications,
  AppRoutes.admin,
];

final routerProvider = Provider<GoRouter>((ref) {
  // Mỗi khi trạng thái đăng nhập đổi thì router chạy lại hàm redirect.
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      if (!auth.initialized) return null; // đang đọc token đã lưu
      final loc = state.matchedLocation;
      final isAdminRoute = loc.startsWith(AppRoutes.admin);
      final needLogin = _protectedPrefixes.any(loc.startsWith);
      final isAuthPage = loc == AppRoutes.login || loc == AppRoutes.register;

      if (!auth.isLoggedIn && needLogin) return AppRoutes.login;
      if (auth.isLoggedIn && isAuthPage) {
        return auth.isAdmin ? AppRoutes.adminDashboard : AppRoutes.home;
      }
      // Tài khoản quản trị chỉ dùng khu quản trị, người thường không vào được khu đó.
      if (auth.isLoggedIn && auth.isAdmin && !isAdminRoute) {
        return AppRoutes.adminDashboard;
      }
      if (auth.isLoggedIn && !auth.isAdmin && isAdminRoute)
        return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginPage()),
      GoRoute(
          path: AppRoutes.register, builder: (_, __) => const RegisterPage()),
      GoRoute(path: AppRoutes.search, builder: (_, __) => const SearchPage()),
      GoRoute(
        path: AppRoutes.bookDetailPattern,
        builder: (_, state) => BookDetailPage(
          bookId: int.parse(state.pathParameters['id']!),
        ),
      ),
      GoRoute(
          path: AppRoutes.favorites, builder: (_, __) => const FavoritesPage()),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (_, __) => const CheckoutPage(),
        routes: [
          GoRoute(
            path: 'transfer',
            builder: (_, state) =>
                BankTransferPage(order: state.extra as PlacedOrder?),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.orderSuccess,
        builder: (_, state) =>
            OrderSuccessPage(order: state.extra as PlacedOrder?),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) => NotificationDetailPage(
                notificationId: state.pathParameters['id']!),
          ),
        ],
      ),

      // Biểu mẫu sách của quản trị viên (không có thanh tab dưới đáy).
      GoRoute(
        path: AppRoutes.adminBookNew,
        builder: (_, __) => const AdminBookFormPage(),
      ),
      GoRoute(
        path: '/admin/books/:id/edit',
        builder: (_, state) => AdminBookFormPage(
          bookId: int.parse(state.pathParameters['id']!),
        ),
      ),

      // 4 tab của người dùng có thanh điều hướng dưới đáy.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.home, builder: (_, __) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.categories,
              builder: (_, __) => const CategoriesPage(),
              routes: [
                GoRoute(
                  path: 'books',
                  builder: (_, state) => BookListPage(
                    categoryId:
                        int.tryParse(state.uri.queryParameters['id'] ?? ''),
                    title:
                        state.uri.queryParameters['name'] ?? 'Tủ sách chọn lọc',
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: AppRoutes.cart, builder: (_, __) => const CartPage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.orders,
              builder: (_, __) => const OrdersPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  builder: (_, state) => OrderDetailPage(
                    orderId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
                path: AppRoutes.account,
                builder: (_, __) => const AccountPage()),
          ]),
        ],
      ),

      // 4 tab của quản trị viên.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AdminShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminDashboard,
              builder: (_, __) => const AdminDashboardPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminBooks,
              builder: (_, __) => const AdminBooksPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminCategories,
              builder: (_, __) => const AdminCategoriesPage(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminOrders,
              builder: (_, __) => const AdminOrdersPage(),
            ),
          ]),
        ],
      ),
    ],
  );
});
