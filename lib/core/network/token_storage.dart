import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lưu JWT. Dùng shared_preferences cho đơn giản, chạy được cả web/Android/Windows.
/// (Sản phẩm thật nên chuyển sang flutter_secure_storage.)
class TokenStorage {
  static const _key = 'auth_token';

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
