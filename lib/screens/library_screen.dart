import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../services/data_manager.dart';
import '../models/article.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final DataManager _dataManager = DataManager();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Training', 'Nutrition', 'Recovery'];
  String _searchQuery = '';
  
  @override
  Widget build(BuildContext context) {
    // 根据分类和搜索过滤文章
    final filteredArticles = _dataManager.articles.where((article) {
      final matchesCategory = _selectedCategory == 'All' || 
                             article.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
                          article.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learning Resources'),
      ),
      body: Column(
        children: [
          // 分类标签栏
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassCard(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;
                    
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
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
          if (_searchQuery.isEmpty && _selectedCategory == 'All') ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recommanded Articles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,                    child: ListView.builder(
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
              Image.network(
                article.coverUrl,
                fit: BoxFit.cover,
                errorBuilder: (ctx, obj, st) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
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
                        Colors.black.withOpacity(0.8),
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
          children: [
            // 文章封面
            Expanded(
              child: Image.network(
                article.coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (ctx, obj, st) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, size: 50),
                ),
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
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        article.coverUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, obj, st) => Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 文章内容（示例）
                      const Text(
                        'Here is an example of the content of the article. In practical applications, content loaded from Markdown files or article details obtained from the internet will be displayed here.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Example article paragraph：Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nullam in dui mauris. Vivamus hendrerit arcu sed erat molestie vehicula. Sed auctor neque eu tellus rhoncus ut eleifend nibh porttitor. Ut in nulla enim. Phasellus molestie magna non est bibendum non venenatis nisl tempor. Suspendisse dictum feugiat nisl ut dapibus. Mauris iaculis porttitor.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Example article paragraph：Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
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
                      label: const Text('Favorite'),
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
