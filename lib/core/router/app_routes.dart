class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const register = '/register';

  // 4 tab chính
  static const home = '/home';
  static const categories = '/categories';
  static const categoryBooks = '/categories/books'; // ?id=..&name=..
  static const cart = '/cart';
  static const account = '/account';

  static const search = '/search';
  static const bookDetailPattern = '/book/:id';
  static String bookDetail(int id) => '/book/$id';

  static const checkout = '/checkout';
  static const bankTransfer = '/checkout/transfer';
  static const orderSuccess = '/order-success';
  static const orders = '/orders';
  static String orderDetail(int id) => '/orders/$id';
  static const favorites = '/favorites';

  static const notifications = '/notifications';
  static String notificationDetail(String id) => '/notifications/$id';

  // Khu quản trị
  static const admin = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminBooks = '/admin/books';
  static const adminBookNew = '/admin/books/new';
  static String adminBookEdit(int id) => '/admin/books/$id/edit';
  static const adminCategories = '/admin/categories';
  static const adminOrders = '/admin/orders';
}
