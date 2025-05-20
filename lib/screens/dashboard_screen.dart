import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/weight_line_chart.dart';
import '../widgets/ring_progress.dart';
import '../mock_data.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _mockData = MockData();

  @override
  void initState() {
    super.initState();
    // 监听数据变化，更新UI
    _mockData.addListener(_updateUI);
  }

  @override
  void dispose() {
    // 移除监听器
    _mockData.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('健身助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 打开设置页面
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日体重卡片
            GlassCard(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('今日体重', style: TextStyle(fontSize: 18)),
                      Text(
                        '${_mockData.currentWeight.toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  WeightLineChart(data: _mockData.weights7d),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 训练完成度卡片
            GlassCard(
              child: Column(
                children: [
                  const Text('训练完成度', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  Center(
                    child: RingProgress(
                      percent: _mockData.workoutCompletionPercent,
                      label: "已完成",
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildWorkoutList(),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 热量盈亏卡片
            GlassCard(
              child: Column(
                children: [
                  const Text('热量盈亏', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    '${_mockData.calorieBalance} kcal',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: _mockData.calorieBalance > 0
                          ? Colors.red
                          : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCalorieProgress(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('摄入: ${_mockData.calorieIntake} kcal'),
                      Text('消耗: ${_mockData.caloriesBurned} kcal'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _FabMenu(mockData: _mockData),
    );
  }
  
  // 构建训练列表
  Widget _buildWorkoutList() {
    final workouts = _mockData.workoutToday;
    if (workouts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('今日暂无训练计划')),
      );
    }
    
    return Column(
      children: workouts.asMap().entries.map((entry) {
        final workout = entry.value;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(workout.name),
          subtitle: Text('${workout.sets} 组'),
          trailing: workout.isCompleted
            ? const Icon(Icons.check_circle, color: Colors.green)
            : const Icon(Icons.circle_outlined),
          onTap: () => _mockData.toggleWorkoutCompleted(entry.key),
        );
      }).toList(),
    );
  }
  
  // 构建热量进度条
  Widget _buildCalorieProgress() {
    final caloriePercent = _mockData.calorieIntake / _mockData.calorieGoal;
    return Stack(
      children: [
        // 背景条
        Container(
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        // 填充条
        FractionallySizedBox(
          widthFactor: caloriePercent.clamp(0.0, 1.0),
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: caloriePercent > 1.0 ? Colors.red : Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

// 浮动操作按钮菜单，内部组件
class _FabMenu extends StatefulWidget {
  final MockData mockData;
  
  const _FabMenu({required this.mockData});
  
  @override
  State<_FabMenu> createState() => _FabMenuState();
}

class _FabMenuState extends State<_FabMenu> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isOpen = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggle() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 体重记录按钮
        ScaleTransition(
          scale: _animationController,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton.small(
              heroTag: 'weight',
              child: const Icon(Icons.monitor_weight),
              onPressed: () {
                _showAddWeightDialog(context);
                _toggle();
              },
            ),
          ),
        ),
        // 训练记录按钮
        ScaleTransition(
          scale: _animationController,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton.small(
              heroTag: 'workout',
              child: const Icon(Icons.fitness_center),
              onPressed: () {
                // 跳转到训练页面
                Navigator.pushNamed(context, '/workout');
                _toggle();
              },
            ),
          ),
        ),
        // 饮食记录按钮
        ScaleTransition(
          scale: _animationController,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton.small(
              heroTag: 'diet',
              child: const Icon(Icons.restaurant_menu),
              onPressed: () {
                // 跳转到饮食页面
                Navigator.pushNamed(context, '/nutrition');
                _toggle();
              },
            ),
          ),
        ),
        // 主按钮
        FloatingActionButton(
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _animationController,
          ),
          onPressed: _toggle,
        ),
      ],
    );
  }
  
  // 体重录入对话框
  void _showAddWeightDialog(BuildContext context) {
    final controller = TextEditingController(
      text: widget.mockData.currentWeight.toString()
    );
    
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('记录体重'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '体重 (kg)',
              suffixText: 'kg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null) {
                  widget.mockData.addWeight(value);
                }
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }
}
