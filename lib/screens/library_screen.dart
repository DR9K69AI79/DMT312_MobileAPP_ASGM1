import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/glass_card.dart';
import '../widgets/article_cover_image.dart';
import '../services/data_manager.dart';
import '../services/article_service.dart';
import '../models/article.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DataManager _dataManager = DataManager();
  final ArticleService _articleService = ArticleService();
  List<String> _allTags = [];
  String _selectedTag = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _updateFilters();
    // 监听DataManager变化，以便在文章加载完成后更新筛选器
    _dataManager.addListener(_updateFilters);
  }
  
  @override
  void dispose() {
    _dataManager.removeListener(_updateFilters);
    super.dispose();
  }
  
  /// 从文章中动态提取所有标签（包括分类）
  void _updateFilters() {
    final articles = _dataManager.articles;
    
    // 提取所有tags和categories作为统一的标签
    final tags = <String>{};
    for (final article in articles) {
      // 添加文章的所有标签
      tags.addAll(article.tags);
      // 添加分类作为标签
      tags.add(article.category);
    }
    final sortedTags = tags.toList()..sort();
    setState(() {
      _allTags = ['All', ...sortedTags];
    });
  }

  @override
  Widget build(BuildContext context) {
    // 根据标签和搜索过滤文章
    final filteredArticles = _dataManager.articles.where((article) {
      final matchesTag = _selectedTag == 'All' ||
                        article.tags.contains(_selectedTag) ||
                        article.category == _selectedTag;
      final matchesSearch = _searchQuery.isEmpty ||
                          article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                          article.description?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;
      return matchesTag && matchesSearch;
    }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Resources'),
      ),
      body: Column(
        children: [
          // 标签筛选栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12.0, top: 8.0, bottom: 4.0),
                    child: Text(
                      'Filter by Tags',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _allTags.length,
                      itemBuilder: (context, index) {
                        final tag = _allTags[index];
                        final isSelected = tag == _selectedTag;
                        
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                          child: FilterChip(
                            label: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected ? Colors.white : null,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedTag = selected ? tag : 'All';
                              });
                            },
                            backgroundColor: Colors.grey.withValues(alpha: 0.1),
                            selectedColor: Theme.of(context).primaryColor,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GlassCard(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search Article',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
          ),
          
          // 推荐文章横向滚动
          if (_searchQuery.isEmpty && _selectedTag == 'All') ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommended Articles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 135,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _dataManager.articles.length,
                      itemBuilder: (context, index) {
                        final article = _dataManager.articles[index];
                        return _buildFeaturedArticleCard(article);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // 文章列表
          Expanded(
            child: filteredArticles.isEmpty
              ? const Center(child: Text('No Article Found'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = filteredArticles[index];
                    return _buildArticleCard(article);
                  },
                ),
          ),
        ],
      ),
    );
  }
  
  // 构建推荐文章卡片
  Widget _buildFeaturedArticleCard(Article article) {
    return GestureDetector(
      onTap: () => _showArticleDialog(article),
      child: Card(
        margin: const EdgeInsets.only(right: 16.0),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 300,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 文章封面
              ArticleCoverImage(
                article: article,
                fit: BoxFit.cover,
              ),
              // 渐变阴影和标题
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 0),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          article.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 构建普通文章卡片
  Widget _buildArticleCard(Article article) {
    return GestureDetector(
      onTap: () => _showArticleDialog(article),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [            // 文章封面
            Expanded(
              child: ArticleCoverImage(
                article: article,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
            // 文章信息
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Chip(
                        label: Text(
                          article.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.bookmark_border),
                        onPressed: () {},
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 显示文章详情对话框
  void _showArticleDialog(Article article) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            children: [
              // 文章标题栏
              Container(
                padding: const EdgeInsets.all(16.0),
                color: Theme.of(context).colorScheme.primary,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        article.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // 文章内容
              Expanded(
                child: FutureBuilder<String>(
                  future: _articleService.loadMarkdownContent(article.mdPath),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text('Loading Failed: ${snapshot.error}'),
                          ],
                        ),
                      );
                    }
                      final markdownContent = snapshot.data ?? '';                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Markdown(
                        data: markdownContent,
                        styleSheet: MarkdownStyleSheet(
                          h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          p: const TextStyle(fontSize: 16, height: 1.5),
                          listBullet: const TextStyle(fontSize: 16),
                        ),
                        selectable: true,
                      ),
                    );
                  },
                ),
              ),
              // 底部操作栏
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey[300]!,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.bookmark_border),
                      label: const Text('Collect'),
                      onPressed: () {},
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Share'),
                      onPressed: () {},
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.wb_sunny_outlined),
                      label: const Text('Mode'),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}