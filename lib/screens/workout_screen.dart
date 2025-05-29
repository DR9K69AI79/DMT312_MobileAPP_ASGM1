import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/ring_progress.dart';
import '../widgets/workout_heatmap.dart';
import '../services/data_manager.dart';
import '../widgets/primary_button.dart';
import '../models/workout_entry.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final DataManager _dataManager = DataManager();
  
  @override
  void initState() {
    super.initState();
    _dataManager.addListener(_updateUI);
  }
  
  @override
  void dispose() {
    _dataManager.removeListener(_updateUI);
    super.dispose();
  }
  
  void _updateUI() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Training Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日训练状态卡片
            GlassCard(
              child: Column(
                children: [
                  const Text(
                    'Today Training Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),                  Center(
                    child: RingProgress(
                      percent: _dataManager.workoutCompletionPercent,
                      label: 'Completed',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_dataManager.workoutToday.where((w) => w.isCompleted).length} / ${_dataManager.workoutToday.length} Completed',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 训练计划卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Training Plans',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        onPressed: () {
                          // TODO: 实现训练计划编辑功能
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildWorkoutList(),
                ],
              ),            ),
              const SizedBox(height: 16),            // 训练完成度热力图
            const WorkoutHeatmap(),
            
            const SizedBox(height: 16),
            
            // 快速添加训练卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Add Training',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: _buildQuickAddWorkouts(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddWorkoutDialog(context),
      ),
    );
  }
    // 构建训练列表
  Widget _buildWorkoutList() {
    final workouts = _dataManager.workoutToday;
    
    if (workouts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32.0),
        child: Center(child: Text('There are no training plans for today')),
      );
    }
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: workouts.length,
      itemBuilder: (context, index) {
        final workout = workouts[index];
        return Dismissible(
          key: Key(workout.name + index.toString()),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          direction: DismissDirection.endToStart,          onDismissed: (direction) async {
            await _dataManager.removeWorkout(index);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${workout.name} Deleted')),
            );
          },
          child: ListTile(
            title: Text(workout.name),
            subtitle: Text('${workout.sets} Group'),
            trailing: IconButton(
              icon: workout.isCompleted
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.circle_outlined),
              onPressed: () => _dataManager.toggleWorkoutCompleted(index),
            ),
          ),
        );
      },
    );
  }
  
  // 构建快速添加训练列表
  Widget _buildQuickAddWorkouts() {
    final workoutTypes = [
      {'name': 'Push-up', 'icon': Icons.fitness_center},
      {'name': 'Squat', 'icon': Icons.accessibility_new},
      {'name': 'Plank', 'icon': Icons.timer},
      {'name': 'Crunch', 'icon': Icons.line_style},
      {'name': 'Pull-up', 'icon': Icons.vertical_align_top},
      {'name': 'Running', 'icon': Icons.directions_run},
    ];
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: workoutTypes.length,
      itemBuilder: (context, index) {
        final workout = workoutTypes[index];
        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () => _quickAddWorkout(workout['name'] as String, 3),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    workout['icon'] as IconData,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(workout['name'] as String),
            ],
          ),
        );
      },
    );
  }
  // 快速添加训练
  void _quickAddWorkout(String name, int sets) {
    final workout = WorkoutEntry(
      name: name,
      sets: sets,
      date: DateTime.now(),
    );
    _dataManager.addWorkout(workout);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name Added')),
    );
  }
  
  // 添加训练对话框
  void _showAddWorkoutDialog(BuildContext context) {
    final nameController = TextEditingController();
    final setsController = TextEditingController(text: '3');
    
    showModalBottomSheet<void>(
      isScrollControlled: true,
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16.0,
            right: 16.0,
            top: 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add Training',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Training Name',
                  prefixIcon: Icon(Icons.fitness_center),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Number of groups',
                  prefixIcon: Icon(Icons.repeat),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 16),
                  PrimaryButton(
                    onPressed: () {                      final name = nameController.text.trim();
                      final sets = int.tryParse(setsController.text) ?? 3;
                        if (name.isNotEmpty) {
                        final workout = WorkoutEntry(
                          name: name,
                          sets: sets,
                          date: DateTime.now(),
                        );
                        _dataManager.addWorkout(workout);
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
