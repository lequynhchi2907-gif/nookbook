import 'dart:convert';

/// Đọc danh sách quyền (role) trong JWT.
/// Trả về null nếu token không đọc được hoặc không chứa claim quyền nào
/// (khi đó giao diện không thể tự kiểm tra, backend vẫn là nơi chặn quyền thật).
Set<String>? readRoles(String token) {
  if (token == 'mock-admin-token') return {'ROLE_ADMIN'};
  if (token == 'mock-token') return {'ROLE_USER'};
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final map = json.decode(payload);
    if (map is! Map) return null;
    final roles = <String>{};
    for (final key in ['roles', 'authorities', 'role', 'scope', 'scopes']) {
      final v = map[key];
      if (v is List) {
        for (final e in v) {
          roles.add(e is Map ? '${e['authority'] ?? e['name']}' : '$e');
        }
      } else if (v is String) {
        roles.addAll(v.split(RegExp(r'[\s,]+')).where((e) => e.isNotEmpty));
      }
    }
    if (roles.isEmpty) return null;
    return roles.map((e) => e.toUpperCase()).toSet();
  } catch (_) {
    return null;
  }
}

bool hasAdminRole(Set<String> roles) => roles.any((r) => r.contains('ADMIN'));
