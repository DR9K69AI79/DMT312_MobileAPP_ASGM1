import 'package:json_annotation/json_annotation.dart';

part 'article.g.dart';

@JsonSerializable()
class Article {
  final String title;
  final String coverUrl;
  final String mdPath;
  final String category;

  Article({
    required this.title,
    required this.coverUrl,
    required this.mdPath,
    required this.category,
  });

  // JSON 序列化方法
  factory Article.fromJson(Map<String, dynamic> json) => _$ArticleFromJson(json);
  Map<String, dynamic> toJson() => _$ArticleToJson(this);
}
