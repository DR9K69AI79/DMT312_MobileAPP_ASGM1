// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Article _$ArticleFromJson(Map<String, dynamic> json) => Article(
  title: json['title'] as String,
  coverUrl: json['coverUrl'] as String,
  mdPath: json['mdPath'] as String,
  category: json['category'] as String,
);

Map<String, dynamic> _$ArticleToJson(Article instance) => <String, dynamic>{
  'title': instance.title,
  'coverUrl': instance.coverUrl,
  'mdPath': instance.mdPath,
  'category': instance.category,
};
