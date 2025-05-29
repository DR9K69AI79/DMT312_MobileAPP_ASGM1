import 'package:flutter/foundation.dart';
import 'models/weight_entry.dart';
import 'models/workout_entry.dart';
import 'models/article.dart';

/// 内存假数据单例类，同时实现ChangeNotifier以便Widget能够响应数据变化
class MockData extends ChangeNotifier {
  // 单例模式实现
  static final MockData _instance = MockData._internal();
  factory MockData() => _instance;
  MockData._internal() {
    _initData();
  }

  // 近7天的体重记录
  List<WeightEntry> weights7d = [];
  
  // 当前热量数据
  int calorieIntake = 1800; // 摄入热量
  int caloriesBurned = 2200; // 消耗热量
  int calorieGoal = 2000; // 热量目标
  
  // 今日训练计划
  List<WorkoutEntry> workoutToday = [];
  
  // 健身文章列表
  List<Article> articles = [];

  // 基础身体数据
  double height = 175.0; // 身高，单位cm
  double currentWeight = 70.0; // 当前体重，单位kg

  // 初始化模拟数据
  void _initData() {
    // 生成近7天的体重数据
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // 模拟一些随机波动的体重数据：基础值70kg，随机上下波动0.5kg
      final randomWeight = 70.0 + (i % 3 - 1) * 0.5;
      weights7d.add(WeightEntry(date: date, value: randomWeight));
    }

    // 初始化今日训练计划
    workoutToday = [
      WorkoutEntry(
        date: now,
        name: '俯卧撑',
        sets: 3,
        isCompleted: true,
      ),
      WorkoutEntry(
        date: now,
        name: '深蹲', 
        sets: 4,
        isCompleted: false,
      ),
      WorkoutEntry(
        date: now,
        name: '平板支撑', 
        sets: 3,
        isCompleted: false,
      ),
    ];

    // 初始化文章数据
    articles = [
      Article(
        title: '如何科学增肌',
        coverUrl: 'https://picsum.photos/id/237/200/300',
        mdPath: 'assets/articles/muscle_gain.md',
        category: '训练',
      ),
      Article(
        title: '高效燃脂训练计划',
        coverUrl: 'https://picsum.photos/id/238/200/300',
        mdPath: 'assets/articles/fat_burn.md',
        category: '训练',
      ),
      Article(
        title: '运动员饮食指南',
        coverUrl: 'https://picsum.photos/id/239/200/300',
        mdPath: 'assets/articles/diet.md',
        category: '饮食',
      ),
      Article(
        title: '拉伸与恢复的重要性',
        coverUrl: 'https://picsum.photos/id/240/200/300',
        mdPath: 'assets/articles/recovery.md',
        category: '康复',
      ),
    ];
  }

  // 添加体重记录
  void addWeight(double value) {
    weights7d.add(WeightEntry(date: DateTime.now(), value: value));
    currentWeight = value;
    
    // 保持只有7天的数据
    if (weights7d.length > 7) {
      weights7d.removeAt(0);
    }
    
    notifyListeners();
  }

  // 添加训练记录
  void addWorkout(String name, int sets) {
    workoutToday.add(
      WorkoutEntry(
        date: DateTime.now(),
        name: name,
        sets: sets,
      ),
    );
    notifyListeners();
  }

  // 切换训练完成状态
  void toggleWorkoutCompleted(int index) {
    if (index >= 0 && index < workoutToday.length) {
      final workout = workoutToday[index];
      workoutToday[index] = workout.copyWith(
        isCompleted: !workout.isCompleted,
      );
      notifyListeners();
    }
  }

  // 更新热量摄入
  void updateCalorieIntake(int calories) {
    calorieIntake = calories;
    notifyListeners();
  }

  // 更新热量消耗
  void updateCaloriesBurned(int calories) {
    caloriesBurned = calories;
    notifyListeners();
  }

  // 计算热量盈亏
  int get calorieBalance => calorieIntake - caloriesBurned;

  // 计算训练完成百分比
  double get workoutCompletionPercent {
    if (workoutToday.isEmpty) return 0.0;
    final completedCount = workoutToday.where((w) => w.isCompleted).length;
    return completedCount / workoutToday.length;
  }

  // 获取当前BMI指数
  double get bmi {
    final heightInMeters = height / 100;
    return currentWeight / (heightInMeters * heightInMeters);
  }
}
