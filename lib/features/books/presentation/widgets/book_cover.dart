import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nookbook/core/theme/app_colors.dart';
import 'package:nookbook/features/books/domain/book.dart';

/// Ảnh bìa: hỗ trợ URL mạng, asset trong máy, hoặc ô giữ chỗ khi chưa có ảnh.
class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, this.height = 136});

  final Book book;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = book.coverImage;
    final placeholder = _CoverPlaceholder(title: book.title);

    Widget image;
    if (url == null || url.isEmpty) {
      image = placeholder;
    } else if (url.startsWith('assets/')) {
      image = Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => placeholder,
      );
    } else {
      image = CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (_, __, ___) => placeholder,
      );
    }
    return SizedBox(height: height, child: image);
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.68,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
