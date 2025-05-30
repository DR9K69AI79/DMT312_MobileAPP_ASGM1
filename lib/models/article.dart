/// 文章模型类，用于表示学习资源库中的文章
/// 注意：此类不参与数据导入导出功能，因此不需要JSON序列化
class Article {
  final String title;         // 文章标题
  final String category;      // 文章分类
  final String coverUrl;      // 封面图片URL或本地资源路径
  final String mdPath;        // Markdown文件路径
  final String? author;       // 作者
  final String? publishDate;  // 发布日期
  final List<String> tags;    // 标签列表
  final String? description;  // 文章描述

  const Article({
    required this.title,
    required this.category,
    required this.coverUrl,
    required this.mdPath,
    this.author,
    this.publishDate,
    this.tags = const [],
    this.description,
  });

  /// 判断封面图片是否为本地资源
  bool get isLocalCover => coverUrl.startsWith('assets/');

  /// 判断封面图片是否为网络URL
  bool get isNetworkCover => coverUrl.startsWith('http://') || coverUrl.startsWith('https://');

  /// 从Front Matter创建Article实例
  factory Article.fromFrontMatter({
    required Map<String, dynamic> frontMatter,
    required String mdPath,
  }) {
    return Article(
      title: frontMatter['title'] ?? 'Untitled',
      category: frontMatter['category'] ?? 'General',
      coverUrl: frontMatter['coverUrl'] ?? 'https://picsum.photos/200/300',
      mdPath: mdPath,
      author: frontMatter['author'],
      publishDate: frontMatter['publishDate'],
      tags: frontMatter['tags'] != null 
          ? List<String>.from(frontMatter['tags']) 
          : [],
      description: frontMatter['description'],
    );
  }
}
