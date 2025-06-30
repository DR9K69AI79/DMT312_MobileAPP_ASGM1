import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'fallback_video_player.dart';

/// 智能视频播放器 - 根据平台选择合适的播放器
class SmartVideoPlayer extends StatefulWidget {
  final String videoPath;
  final String title;
  final String? description;
  final bool autoPlay;
  final bool showControls;

  const SmartVideoPlayer({
    super.key,
    required this.videoPath,
    required this.title,
    this.description,
    this.autoPlay = false,
    this.showControls = true,
  });

  @override
  State<SmartVideoPlayer> createState() => _SmartVideoPlayerState();
}

class _SmartVideoPlayerState extends State<SmartVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _showFallback = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  /// 检查当前平台是否支持视频播放
  bool get _isPlatformSupported {
    // Android 和 iOS 支持较好
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return true;
    }
    
    // Web 平台有限支持
    if (kIsWeb) {
      return true;
    }
    
    // 桌面平台支持有限
    return false;
  }

  Future<void> _initializeVideoPlayer() async {
    // 如果平台不支持，直接显示备用播放器
    if (!_isPlatformSupported) {
      debugPrint('SmartVideoPlayer: 当前平台不支持视频播放，使用备用显示');
      setState(() {
        _isLoading = false;
        _showFallback = true;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = null;
      });

      debugPrint('SmartVideoPlayer: 初始化视频播放器: ${widget.videoPath}');
      debugPrint('SmartVideoPlayer: 当前平台: ${defaultTargetPlatform.name}');

      // 创建视频控制器
      _controller = VideoPlayerController.asset(widget.videoPath);

      // 监听视频状态变化
      _controller!.addListener(_videoListener);

      // 初始化视频播放器
      await _controller!.initialize();

      debugPrint('SmartVideoPlayer: 视频初始化成功');
      debugPrint('SmartVideoPlayer: 视频时长: ${_controller!.value.duration}');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = false;
        });

        // 自动播放
        if (widget.autoPlay) {
          await _controller!.play();
        }
      }
    } catch (e) {
      debugPrint('SmartVideoPlayer: 视频初始化失败: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
          
          // 如果初始化失败，使用备用播放器
          _showFallback = true;
        });
      }
    }
  }

  void _videoListener() {
    if (_controller != null && mounted) {
      setState(() {
        _isPlaying = _controller!.value.isPlaying;
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_controller == null) return;

    try {
      if (_controller!.value.isPlaying) {
        await _controller!.pause();
      } else {
        await _controller!.play();
      }
    } catch (e) {
      debugPrint('SmartVideoPlayer: 播放控制失败: $e');
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 如果需要显示备用播放器
    if (_showFallback) {
      return FallbackVideoPlayer(
        videoPath: widget.videoPath,
        title: widget.title,
        description: widget.description,
      );
    }

    // 加载中状态
    if (_isLoading) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 16),
                Text(
                  '正在加载视频...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 成功加载视频
    if (_controller != null && _controller!.value.isInitialized) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 视频标题
          if (widget.title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                widget.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          
          // 视频播放器
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Stack(
                  children: [
                    // 视频画面
                    VideoPlayer(_controller!),
                    
                    // 控制层
                    if (widget.showControls)
                      Positioned.fill(
                        child: _buildVideoControls(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // 视频信息
          if (widget.description != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.description!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      );
    }

    // 错误状态 - 显示备用播放器
    return FallbackVideoPlayer(
      videoPath: widget.videoPath,
      title: widget.title,
      description: _errorMessage ?? widget.description,
    );
  }

  Widget _buildVideoControls() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.3),
            Colors.black.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: GestureDetector(
            onTap: _togglePlayPause,
            child: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
      ),
    );
  }
}
