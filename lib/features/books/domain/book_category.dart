class BookCategory {
  const BookCategory({
    required this.id,
    required this.name,
    this.description,
    this.bookCount,
  });

  final int id;
  final String name;
  final String? description;

  /// Số đầu sách (thiết kế có hiển thị "42 đầu sách"). Backend có thể chưa trả về.
  final int? bookCount;

  factory BookCategory.fromJson(Map<String, dynamic> json) => BookCategory(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        bookCount: (json['bookCount'] as num?)?.toInt(),
      );
}
