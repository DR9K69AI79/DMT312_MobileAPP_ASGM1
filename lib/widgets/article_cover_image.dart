import 'package:flutter/material.dart';
import '../models/article.dart';

/// 文章封面图片组件，支持本地资源和网络图片
class ArticleCoverImage extends StatelessWidget {
  final Article article;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ArticleCoverImage({
    super.key,
    required this.article,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // 默认的错误显示组件
    final defaultErrorWidget = errorWidget ?? Container(
      color: Colors.grey[300],
      child: const Icon(Icons.broken_image, size: 50),
    );

    // 默认的占位符组件
    final defaultPlaceholder = placeholder ?? Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 50, color: Colors.grey),
    );

    // 根据图片类型返回相应的组件
    if (article.isLocalCover) {
      // 本地资源图片
      return Image.asset(
        article.coverUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Failed to load local image: ${article.coverUrl}');
          return defaultErrorWidget;
        },
      );
    } else if (article.isNetworkCover) {
      // 网络图片
      return Image.network(
        article.coverUrl,
        fit: fit,
        width: width,
        height: height,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return defaultPlaceholder;
        },
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Failed to load network image: ${article.coverUrl}');
          return defaultErrorWidget;
        },
      );
    } else {
      // 无效的图片路径
      return defaultErrorWidget;
    }
  }
}
