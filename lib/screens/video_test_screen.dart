import 'package:flutter/material.dart';
import '../widgets/simple_video_player.dart';

/// 视频测试页面
class VideoTestScreen extends StatelessWidget {
  const VideoTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('视频播放测试'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '视频播放器测试',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('正在测试本地视频文件播放功能...'),
                  const SizedBox(height: 16),
                  SimpleVideoPlayer(
                    videoPath: 'assets/videos/tutorial.mp4',
                    title: '基础训练教程',
                    autoPlay: false,
                    showControls: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '热身运动',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SimpleVideoPlayer(
                    videoPath: 'assets/videos/warmup.mp4',
                    title: '热身运动指导',
                    autoPlay: false,
                    showControls: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '拉伸放松',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SimpleVideoPlayer(
                    videoPath: 'assets/videos/stretching.mp4',
                    title: '拉伸和放松指导',
                    autoPlay: false,
                    showControls: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
