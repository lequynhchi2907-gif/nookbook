/// Model sách.
/// TODO: mở Swagger (/api/swagger-ui/index.html) xem BookDto thật gồm field nào rồi đối chiếu fromJson.
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    this.isbn,
    this.description,
    this.coverImage,
    this.categoryIds = const [],
    this.rating,
    this.ratingCount,
  });

  final int id;
  final String title;
  final String author;
  final double price;
  final String? isbn;
  final String? description;

  /// URL (http...) hoặc đường dẫn asset (assets/images/xxx.png). Null = hiện ô giữ chỗ.
  final String? coverImage;

  /// Các thể loại sách thuộc về (backend: categoryIds).
  final List<int> categoryIds;

  /// Backend hiện chưa có đánh giá sao: để null, màn hình sẽ tự ẩn.
  final double? rating;
  final int? ratingCount;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: (json['id'] as num).toInt(),
        title: json['title'] as String? ?? '',
        author: json['author'] as String? ?? '',
        price: double.tryParse('${json['price']}') ?? 0,
        isbn: json['isbn'] as String?,
        description: json['description'] as String?,
        coverImage: json['coverImage'] as String?,
        categoryIds: ((json['categoryIds'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
      );

  /// Body gửi lên khi tạo / sửa sách (POST, PUT /books).
  Map<String, dynamic> toRequestJson() => {
        'title': title,
        'author': author,
        'isbn': isbn,
        'price': price,
        'description': description,
        'coverImage': coverImage,
        'categoryIds': categoryIds,
      };

  Book copyWith({
    String? title,
    String? author,
    double? price,
    String? isbn,
    String? description,
    String? coverImage,
    List<int>? categoryIds,
  }) =>
      Book(
        id: id,
        title: title ?? this.title,
        author: author ?? this.author,
        price: price ?? this.price,
        isbn: isbn ?? this.isbn,
        description: description ?? this.description,
        coverImage: coverImage ?? this.coverImage,
        categoryIds: categoryIds ?? this.categoryIds,
        rating: rating,
        ratingCount: ratingCount,
      );
}
