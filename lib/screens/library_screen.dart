import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../widgets/glass_card.dart';
import '../widgets/article_cover_image.dart';
import '../widgets/smart_video_player.dart';
import '../services/data_manager.dart';
import '../services/article_service.dart';
import '../models/article.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with TickerProviderStateMixin {
  final DataManager _dataManager = DataManager();
  final ArticleService _articleService = ArticleService();
  final ScrollController _scrollController = ScrollController();
  List<String> _allTags = [];
  String _selectedTag = 'All';
  String _searchQuery = '';
  bool _isRecommendedVisible = true;
  late AnimationController _animationController;
  late Animation<double> _heightAnimation;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化标签页控制器
    _tabController = TabController(length: 2, vsync: this);
    
    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _heightAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // 添加滚动监听器
    _scrollController.addListener(_onScroll);
    
    _updateFilters();
    // 监听DataManager变化，以便在文章加载完成后更新筛选器
    _dataManager.addListener(_updateFilters);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    _dataManager.removeListener(_updateFilters);
    super.dispose();
  }
  
  // 滚动监听方法
  void _onScroll() {
    const double threshold = 100.0; // 滚动阈值
    
    if (_scrollController.offset > threshold && _isRecommendedVisible) {
      setState(() {
        _isRecommendedVisible = false;
      });
      _animationController.forward();
    } else if (_scrollController.offset <= threshold && !_isRecommendedVisible) {
      setState(() {
        _isRecommendedVisible = true;
      });
      _animationController.reverse();
    }
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: const Color.fromARGB(255, 255, 255, 255),
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: 'Articles'),
            Tab(text: 'Videos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              // 始终置顶的搜索和筛选栏
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  child: Column(
                    children: [
                      // 搜索框
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search Article',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                      const Divider(height: 1),
                      // 标签筛选
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                        child: Row(
                          children: [
                            const Text(
                              'Tags:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 32,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _allTags.length,
                                  itemBuilder: (context, index) {
                                    final tag = _allTags[index];
                                    final isSelected = tag == _selectedTag;
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: FilterChip(
                                        label: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 10,
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
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // 可滚动的内容区域
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // 推荐文章横向滚动（带动画折叠效果）
                    if (_searchQuery.isEmpty && _selectedTag == 'All')
                      SliverToBoxAdapter(
                        child: AnimatedBuilder(
                          animation: _heightAnimation,
                          builder: (context, child) {
                            return SizeTransition(
                              sizeFactor: _heightAnimation,
                              axisAlignment: -1.0,
                              child: Opacity(
                                opacity: _heightAnimation.value,
                                child: Padding(
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
                              ),
                            );
                          },
                        ),
                      ),
                    
                    // 文章网格列表
                    filteredArticles.isEmpty
                      ? const SliverFillRemaining(
                          child: Center(child: Text('No Article Found')),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.all(16.0),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final article = filteredArticles[index];
                                return _buildArticleCard(article);
                              },
                              childCount: filteredArticles.length,
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
          
          // 视频标签页内容
          _buildVideoTab(),
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
          children: [
            // 文章封面
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
                    
                    final markdownContent = snapshot.data ?? '';
                    return Padding(
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

  // 添加视频相关方法
  Widget _buildVideoTab() {
    final videos = [
      {
        'title': '基础训练教程',
        'description': '适合初学者的基础健身动作教学',
        'thumbnail': 'assets/images/muscle_building_cover.png',
        'path': 'assets/videos/tutorial.mp4',
        'duration': '10:30',
      },
      {
        'title': '热身运动',
        'description': '训练前必做的热身动作指导',
        'thumbnail': 'assets/images/injury_prevention_cover.png',
        'path': 'assets/videos/warmup.mp4',
        'duration': '5:15',
      },
      {
        'title': '拉伸放松',
        'description': '训练后的拉伸和放松指导',
        'thumbnail': 'assets/images/outdoor_cover.png',
        'path': 'assets/videos/stretching.mp4',
        'duration': '8:20',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = videos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _openVideoPlayer(
              video['path']!,
              video['title']!,
              video['description']!,
            ),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // 视频缩略图
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      video['thumbnail']!,
                      width: 80,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 60,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.play_circle_outline,
                            size: 32,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 视频信息
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video['title']!,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          video['description']!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              video['duration']!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 播放按钮
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openVideoPlayer(String videoPath, String title, String description) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(title),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SmartVideoPlayer(
                  videoPath: videoPath,
                  title: '',
                  description: description,
                  autoPlay: true,
                  showControls: true,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
