/// 129000 -> "129.000 ₫"
String formatPrice(num value) {
  final s = value.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write('.');
  }
  return '${buf.toString()} ₫';
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 06/11/2026
String formatDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// 06/11/2026 · 09:31
String formatDateTime(DateTime d) =>
    '${formatDate(d)} · ${_two(d.hour)}:${_two(d.minute)}';

/// 241108 -> "#NB241108"
String orderCode(int id) => '#NB${id.toString().padLeft(6, '0')}';

/// "Nguyễn Minh Anh" -> "NA" (chữ cái đầu của họ + chữ cuối của tên).
String initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return 'NB';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}

/// "10 phút trước", "1 giờ trước", "Hôm qua", hoặc ngày.
String relativeTime(DateTime t, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = n.difference(t);
  if (diff.inMinutes < 1) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays == 1) return 'Hôm qua';
  return formatDate(t);
}
