import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thông tin người dùng lưu trong máy.
/// Backend chưa có API "hồ sơ của tôi" và không có số điện thoại, nên app giữ tên,
/// email, SĐT, địa chỉ ở đây để hiển thị Tài khoản và điền sẵn khi Thanh toán.
class UserProfile {
  const UserProfile({
    this.name = '',
    this.email = '',
    this.phone = '',
    this.address = '',
  });

  final String name;
  final String email;
  final String phone;
  final String address;

  String get displayName {
    if (name.isNotEmpty) return name;
    if (email.contains('@')) return email.split('@').first;
    return 'Bạn đọc NookBook';
  }

  bool get hasShippingInfo => name.isNotEmpty && address.isNotEmpty;

  /// Chuỗi gửi lên backend ở trường shippingAddress: "Tên · SĐT · Địa chỉ".
  String get shippingAddress =>
      [name, phone, address].where((e) => e.isNotEmpty).join(' · ');

  UserProfile copyWith({String? name, String? email, String? phone, String? address}) =>
      UserProfile(
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        address: address ?? this.address,
      );
}

class ProfileNotifier extends Notifier<UserProfile> {
  static const _kName = 'profile_name';
  static const _kEmail = 'profile_email';
  static const _kPhone = 'profile_phone';
  static const _kAddress = 'profile_address';

  @override
  UserProfile build() {
    _load();
    return const UserProfile();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    state = UserProfile(
      name: p.getString(_kName) ?? '',
      email: p.getString(_kEmail) ?? '',
      phone: p.getString(_kPhone) ?? '',
      address: p.getString(_kAddress) ?? '',
    );
  }

  Future<void> _save() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kName, state.name);
    await p.setString(_kEmail, state.email);
    await p.setString(_kPhone, state.phone);
    await p.setString(_kAddress, state.address);
  }

  Future<void> update(UserProfile value) async {
    state = value;
    await _save();
  }

  /// Gọi sau khi đăng nhập: nếu là tài khoản khác thì bỏ thông tin của người trước.
  Future<void> onLogin(String email) async {
    if (state.email.toLowerCase() != email.toLowerCase()) {
      state = UserProfile(email: email);
      await _save();
    }
  }

  /// Gọi sau khi đăng ký thành công (Họ + Tên, địa chỉ nhập lúc đăng ký).
  Future<void> onRegister({
    required String lastName,
    required String firstName,
    required String email,
    String? address,
  }) async {
    state = UserProfile(
      name: '$lastName $firstName'.trim(),
      email: email,
      address: address ?? '',
    );
    await _save();
  }

  Future<void> clear() async {
    state = const UserProfile();
    await _save();
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);
