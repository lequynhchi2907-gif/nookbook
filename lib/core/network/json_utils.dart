/// Backend Spring có thể trả về List thẳng, hoặc Page { "content": [...] }.
/// Hàm này xử lý cả hai kiểu.
List<dynamic> extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map && data['content'] is List) return data['content'] as List;
  return const [];
}
