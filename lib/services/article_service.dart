import 'package:flutter/services.dart';
import 'dart:convert';
import '../models/article.dart';
import '../utils/front_matter_parser.dart';

/// 文章服务类，负责处理Markdown文件的加载和管理
class ArticleService {
  static final ArticleService _instance = ArticleService._internal();
  factory ArticleService() => _instance;
  ArticleService._internal();
  /// 文章目录路径
  static const String _articlesPath = 'assets/articles/';

  /// 动态获取所有文章文件
  Future<List<String>> _getArticleFiles() async {
    try {
      // 读取AssetManifest.json来获取所有资源文件
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // 筛选出articles目录下的.md文件
      final List<String> articleFiles = [];
      for (String key in manifestMap.keys) {
        if (key.startsWith(_articlesPath) && key.endsWith('.md')) {
          // 提取文件名（去掉路径前缀）
          final fileName = key.substring(_articlesPath.length);
          articleFiles.add(fileName);
        }
      }
      
      return articleFiles;
    } catch (e) {
      print('Error reading asset manifest: $e');
      // 如果读取失败，返回空列表
      return [];
    }
  }

  /// 加载所有文章
  Future<List<Article>> loadAllArticles() async {
    final List<Article> articles = [];
    
    // 动态获取文章文件列表
    final articleFiles = await _getArticleFiles();
    print('Found ${articleFiles.length} article files: $articleFiles');
    
    for (String fileName in articleFiles) {
      try {
        final article = await loadArticle(fileName);
        if (article != null) {
          articles.add(article);
          print('Successfully loaded article: $fileName');
        }
      } catch (e) {
        print('Error loading article $fileName: $e');
        // 继续加载其他文章
      }
    }
    
    print('Total articles loaded: ${articles.length}');
    return articles;
  }

  /// 加载单个文章
  Future<Article?> loadArticle(String fileName) async {
    try {
      final assetPath = '$_articlesPath$fileName';
      final content = await rootBundle.loadString(assetPath);
      
      // 解析Front Matter
      final parsed = FrontMatterParser.parse(content);
      
      // 从Front Matter创建Article对象
      final article = Article.fromFrontMatter(
        frontMatter: parsed.frontMatter,
        mdPath: assetPath,
      );
      
      return article;
    } catch (e) {
      print('Failed to load article $fileName: $e');
      return null;
    }
  }

  /// 从assets目录加载markdown文件内容
  Future<String> loadMarkdownContent(String assetPath) async {
    try {
      final content = await rootBundle.loadString(assetPath);
      // 解析并返回不包含Front Matter的内容
      final parsed = FrontMatterParser.parse(content);
      return parsed.content;
    } catch (e) {
      // 如果加载失败，返回错误信息或空字符串
      return 'Error loading content';
    }
  }

  /// 检查文件是否存在
  Future<bool> fileExists(String assetPath) async {
    try {
      await rootBundle.loadString(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }

//   /// 获取默认内容（当markdown文件不存在时）
//   String _getDefaultContent(String assetPath) {
//     final fileName = assetPath.split('/').last.replaceAll('.md', '');
    
//     switch (fileName) {
//       case 'muscle_gain':
//         return '''# 科学增肌指南

// ## 概述
// 科学的增肌需要结合合理的训练、营养和休息。本指南将为您提供系统性的增肌方案。

// ## 训练原则

// ### 1. 渐进超负荷原则
// - 逐步增加训练重量
// - 增加训练次数或组数
// - 缩短组间休息时间

// ### 2. 复合动作优先
// - 深蹲 (Squat)
// - 硬拉 (Deadlift)
// - 卧推 (Bench Press)
// - 引体向上 (Pull-up)

// ## 营养建议

// ### 蛋白质摄入
// - 每公斤体重1.6-2.2克蛋白质
// - 优质蛋白质来源：鸡胸肉、鱼类、蛋类、豆制品

// ### 碳水化合物
// - 训练前后补充优质碳水
// - 推荐：燕麦、糙米、红薯

// ### 脂肪
// - 占总热量的20-30%
// - 优质脂肪：坚果、橄榄油、鱼油

// ## 休息与恢复
// - 充足睡眠：每天7-9小时
// - 肌肉群训练间隔48-72小时
// - 适当的拉伸和按摩

// 记住，增肌是一个需要耐心和坚持的过程。''';

//       case 'fat_burn':
//         return '''# 高效燃脂训练计划

// ## 燃脂原理
// 有效的脂肪燃烧需要创造热量缺口，结合有氧训练和力量训练。

// ## HIIT训练计划

// ### 基础HIIT方案
// - 高强度间歇：30秒
// - 低强度恢复：90秒
// - 重复8-12轮

// ### 推荐动作
// 1. 跳跃深蹲 (Jump Squat)
// 2. 波比跳 (Burpee)
// 3. 高抬腿跑 (High Knees)
// 4. 登山者 (Mountain Climbers)

// ## 力量训练

// ### 上肢训练
// - 俯卧撑 3组 x 12-15次
// - 哑铃飞鸟 3组 x 10-12次
// - 三头肌屈伸 3组 x 12-15次

// ### 下肢训练
// - 深蹲 4组 x 15-20次
// - 弓步蹲 3组 x 12次每侧
// - 臀桥 3组 x 15-20次

// ## 饮食建议

// ### 热量控制
// - 创造每日300-500卡路里缺口
// - 优先选择高蛋白、低GI食物

// ### 推荐食物
// - 瘦肉：鸡胸肉、鱼类
// - 蔬菜：绿叶菜、西兰花
// - 水果：苹果、浆果类
// - 全谷物：燕麦、糙米

// ## 注意事项
// - 循序渐进，避免过度训练
// - 保持水分充足
// - 监测心率，确保安全训练

// 坚持是成功的关键！''';

//       default:
//         return '''# 健身指南

// 欢迎来到健身知识库！这里包含了丰富的健身知识和训练指导。

// ## 基础原则
// - 科学训练
// - 合理营养
// - 充分休息

// ## 开始您的健身之旅
// 选择适合自己的训练计划，坚持不懈地执行，您一定能够达到理想的健身目标。

// 记住：健身是一种生活方式，不是短期的挑战。''';
//     }
//   }
}
