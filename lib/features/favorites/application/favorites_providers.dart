import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sách yêu thích. Backend CHƯA có API này nên tạm lưu id sách trong máy.
/// Khi backend bổ sung, chỉ cần đổi lớp này sang gọi API.
class FavoritesNotifier extends Notifier<Set<int>> {
  static const _key = 'favorite_book_ids';

  @override
  Set<int> build() {
    _load();
    return <int>{};
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList(_key) ?? const <String>[];
    state = ids.map(int.tryParse).whereType<int>().toSet();
  }

  Future<void> toggle(int bookId) async {
    final next = {...state};
    if (!next.remove(bookId)) next.add(bookId);
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, next.map((e) => '$e').toList());
  }
}

final favoritesProvider =
    NotifierProvider<FavoritesNotifier, Set<int>>(FavoritesNotifier.new);
