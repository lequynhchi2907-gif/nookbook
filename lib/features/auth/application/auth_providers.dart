import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nookbook/core/config/app_config.dart';
import 'package:nookbook/core/network/api_client.dart';
import 'package:nookbook/core/network/api_error.dart';
import 'package:nookbook/core/network/token_storage.dart';
import 'package:nookbook/core/utils/jwt_utils.dart';
import 'package:nookbook/features/account/application/profile_providers.dart';
import 'package:nookbook/features/auth/data/auth_repository.dart';
import 'package:nookbook/features/cart/application/cart_providers.dart';
import 'package:nookbook/features/orders/application/order_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMock) return MockAuthRepository();
  return ApiAuthRepository(ref.watch(dioProvider));
});

class AuthState {
  const AuthState({
    required this.initialized,
    required this.isLoggedIn,
    this.isAdmin = false,
  });

  /// false = đang đọc token đã lưu trong máy.
  final bool initialized;
  final bool isLoggedIn;

  /// Đăng nhập bằng tab "Quản trị viên". Chỉ để chọn giao diện; quyền thật do backend kiểm tra.
  final bool isAdmin;
}

class AuthNotifier extends Notifier<AuthState> {
  static const _adminKey = 'is_admin_session';

  @override
  AuthState build() {
    _restore();
    return const AuthState(initialized: false, isLoggedIn: false);
  }

  Future<void> _restore() async {
    final token = await ref.read(tokenStorageProvider).read();
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = token != null && token.isNotEmpty;
    state = AuthState(
      initialized: true,
      isLoggedIn: loggedIn,
      isAdmin: loggedIn && (prefs.getBool(_adminKey) ?? false),
    );
  }

  /// Ném lỗi nếu đăng nhập thất bại (trang Login sẽ bắt và hiện lên).
  Future<void> login(String email, String password, {bool asAdmin = false}) async {
    final token = await ref
        .read(authRepositoryProvider)
        .login(email: email, password: password);

    // Nếu token cho biết quyền, chặn người thường vào khu quản trị.
    final roles = readRoles(token);
    if (asAdmin && roles != null && !hasAdminRole(roles)) {
      throw const AppException('Tài khoản này không có quyền quản trị.');
    }

    await ref.read(tokenStorageProvider).save(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adminKey, asAdmin);
    await ref.read(profileProvider.notifier).onLogin(email);
    state = AuthState(initialized: true, isLoggedIn: true, isAdmin: asAdmin);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminKey);
    ref.invalidate(cartProvider);
    ref.invalidate(ordersProvider);
    state = const AuthState(initialized: true, isLoggedIn: false);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
