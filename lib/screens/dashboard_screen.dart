import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/weight_chart.dart';
import '../widgets/ring_progress.dart';
import '../widgets/time_range_selector.dart';
import '../services/data_manager.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _dataManager = DataManager();

  @override
  void initState() {
    super.initState();
    // 监听数据变化，更新UI
    _dataManager.addListener(_updateUI);
    // 确保数据管理器已初始化
    _ensureDataManagerInitialized();
  }

  @override
  void dispose() {
    // 移除监听器
    _dataManager.removeListener(_updateUI);
    super.dispose();
  }

  void _updateUI() {
    if (mounted) {
      setState(() {});
    }
  }

  // 确保DataManager已经初始化
  Future<void> _ensureDataManagerInitialized() async {
    await _dataManager.initialize();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(        title: const Text('Fitness Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
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
                    children: [                      const Text('Today Weight', style: TextStyle(fontSize: 18)),
                      Text(
                        '${(_dataManager.currentWeight ?? 0.0).toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),                  const EnhancedWeightChart(
                    showBodyFat: false,
                    showTimeSelector: false,
                    defaultTimeRange: TimeRange.month1, // Dashboard显示30天数据
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 训练完成度卡片
            GlassCard(
              child: Column(
                children: [
                  const Text('Training Completion Rate', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  Center(
                    child: RingProgress(
                      percent: _dataManager.workoutCompletionPercent,
                      label: "Completed",
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
                  const Text('Calorie Surplus & Deficit', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${_dataManager.calorieBalance > 0 ? '+' : ''}',
                        style: TextStyle(
                          fontSize: 24,
                          color: _dataManager.calorieBalance > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      Text(
                        '${_dataManager.calorieBalance} kcal',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _dataManager.calorieBalance > 0
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalorieProgress(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text('Intake: ${_dataManager.calorieIntake} kcal'),
                      Text('Burn: ${_dataManager.caloriesBurned} kcal'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _FabMenu(dataManager: _dataManager),
    );
  }
  
  // 构建训练列表
  Widget _buildWorkoutList() {
    final workouts = _dataManager.workoutToday;
    
    if (workouts.isEmpty) {
      return const Text('No Training Plans For Today');
    }
    
    return Column(
      children: workouts.asMap().entries.map((entry) {
        final workout = entry.value;
        return ListTile(
          title: Text(workout.name),
          subtitle: Text('${workout.sets} Groups'),
          trailing: workout.isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : const Icon(Icons.circle_outlined),
          onTap: () => _dataManager.toggleWorkoutCompleted(entry.key),
        );
      }).toList(),
    );
  }
  
  // 构建热量进度条
  Widget _buildCalorieProgress() {
    final caloriePercent = _dataManager.calorieIntake / _dataManager.calorieGoal;
    
    return Column(
      children: [
        LinearProgressIndicator(
          value: caloriePercent.clamp(0.0, 1.0),
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(
            caloriePercent > 1.0 ? Colors.red : Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Text('Goal: ${_dataManager.calorieGoal} kcal'),
      ],
    );
  }
}

// FAB 菜单组件
class _FabMenu extends StatefulWidget {
  final DataManager dataManager;
  
  const _FabMenu({required this.dataManager});
  
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
              heroTag: "weight",
              onPressed: () => _showAddWeightDialog(context),
              child: const Icon(Icons.monitor_weight),
            ),
          ),
        ),
        // 训练按钮
        ScaleTransition(
          scale: _animationController,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton.small(
              heroTag: "workout",
              onPressed: () => Navigator.pushNamed(context, '/workout'),
              child: const Icon(Icons.fitness_center),
            ),
          ),
        ),
        // 饮食按钮
        ScaleTransition(
          scale: _animationController,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: FloatingActionButton.small(
              heroTag: "nutrition",
              onPressed: () => Navigator.pushNamed(context, '/nutrition'),
              child: const Icon(Icons.restaurant_menu),
            ),
          ),
        ),
        // 主FAB
        FloatingActionButton(
          onPressed: _toggle,
          child: AnimatedRotation(
            turns: _isOpen ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
  
  // 显示添加体重对话框
  void _showAddWeightDialog(BuildContext context) {
    final weightController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Record Weight'),
          content: TextField(
            controller: weightController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              suffixText: 'kg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final weight = double.tryParse(weightController.text);
                if (weight != null) {
                  await widget.dataManager.addWeightValue(weight);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Weight Record Saved')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
