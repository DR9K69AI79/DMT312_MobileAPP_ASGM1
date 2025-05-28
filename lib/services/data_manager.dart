import 'package:flutter/foundation.dart';
import '../models/weight_entry.dart';
import '../models/workout_entry.dart';
import '../models/article.dart';
import '../models/nutrition_entry.dart';
import 'storage_service.dart';
import 'local_storage_service.dart';

/// 数据管理器，负责管理所有应用数据的持久化
class DataManager extends ChangeNotifier {
  static const String _weightEntriesKey = 'weight_entries';
  static const String _workoutEntriesKey = 'workout_entries';
  static const String _articlesKey = 'articles';
  static const String _nutritionEntriesKey = 'nutrition_entries';
  static const String _userDataKey = 'user_data';

  // 单例模式实现
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  late final StorageService _storage;
  bool _initialized = false;

  // 数据缓存
  List<WeightEntry> _weights7d = [];
  List<WorkoutEntry> _workoutToday = [];
  List<Article> _articles = [];
  List<NutritionEntry> _nutritionEntries = [];

  // 用户数据
  int _calorieIntake = 1800;
  int _caloriesBurned = 2200;
  int _calorieGoal = 2000;
  double _height = 175.0;
  double _currentWeight = 70.0;

  // Getters
  List<WeightEntry> get weights7d => List.unmodifiable(_weights7d);
  List<WorkoutEntry> get workoutToday => List.unmodifiable(_workoutToday);
  List<Article> get articles => List.unmodifiable(_articles);
  List<NutritionEntry> get nutritionEntries => List.unmodifiable(_nutritionEntries);
  
  int get calorieIntake => _calorieIntake;
  int get caloriesBurned => _caloriesBurned;
  int get calorieGoal => _calorieGoal;
  double get height => _height;
  double get currentWeight => _currentWeight;

  // 计算属性
  int get calorieBalance => _calorieIntake - _caloriesBurned;
  
  double get workoutCompletionPercent {
    if (_workoutToday.isEmpty) return 0.0;
    final completedCount = _workoutToday.where((w) => w.isCompleted).length;
    return completedCount / _workoutToday.length;
  }
  
  double get bmi {
    final heightInMeters = _height / 100;
    return _currentWeight / (heightInMeters * heightInMeters);
  }

  /// 初始化数据管理器
  Future<void> init({StorageService? storageService}) async {
    if (_initialized) return;

    _storage = storageService ?? LocalStorageService();
    await _storage.init();
    
    await _loadAllData();
    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('DataManager must be initialized before use');
    }
  }

  /// 加载所有数据
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadWeightEntries(),
      _loadWorkoutEntries(),
      _loadArticles(),
      _loadNutritionEntries(),
      _loadUserData(),
    ]);
    
    // 如果没有数据，初始化默认数据
    if (_weights7d.isEmpty && _workoutToday.isEmpty && _articles.isEmpty) {
      await _initDefaultData();
    }
  }

  /// 加载体重记录
  Future<void> _loadWeightEntries() async {
    final jsonList = await _storage.getJsonList(_weightEntriesKey);
    if (jsonList != null) {
      _weights7d = jsonList.map((json) => WeightEntry.fromJson(json)).toList();
      // 保持只有最近7天的数据
      _weights7d.sort((a, b) => a.date.compareTo(b.date));
      if (_weights7d.length > 7) {
        _weights7d = _weights7d.sublist(_weights7d.length - 7);
      }
    }
  }

  /// 保存体重记录
  Future<void> _saveWeightEntries() async {
    final jsonList = _weights7d.map((entry) => entry.toJson()).toList();
    await _storage.saveJsonList(_weightEntriesKey, jsonList);
  }

  /// 加载训练记录
  Future<void> _loadWorkoutEntries() async {
    final jsonList = await _storage.getJsonList(_workoutEntriesKey);
    if (jsonList != null) {
      final allWorkouts = jsonList.map((json) => WorkoutEntry.fromJson(json)).toList();
      // 筛选今日训练
      final today = DateTime.now();
      _workoutToday = allWorkouts.where((workout) {
        return workout.date.year == today.year &&
               workout.date.month == today.month &&
               workout.date.day == today.day;
      }).toList();
    }
  }

  /// 保存训练记录
  Future<void> _saveWorkoutEntries() async {
    // 加载所有历史训练记录
    final jsonList = await _storage.getJsonList(_workoutEntriesKey);
    final allWorkouts = jsonList?.map((json) => WorkoutEntry.fromJson(json)).toList() ?? <WorkoutEntry>[];
    
    // 移除今日的旧记录
    final today = DateTime.now();
    allWorkouts.removeWhere((workout) {
      return workout.date.year == today.year &&
             workout.date.month == today.month &&
             workout.date.day == today.day;
    });
    
    // 添加今日新记录
    allWorkouts.addAll(_workoutToday);
    
    // 保存所有记录
    final jsonListToSave = allWorkouts.map((entry) => entry.toJson()).toList();
    await _storage.saveJsonList(_workoutEntriesKey, jsonListToSave);
  }

  /// 加载文章
  Future<void> _loadArticles() async {
    final jsonList = await _storage.getJsonList(_articlesKey);
    if (jsonList != null) {
      _articles = jsonList.map((json) => Article.fromJson(json)).toList();
    }
  }

  /// 保存文章
  Future<void> _saveArticles() async {
    final jsonList = _articles.map((entry) => entry.toJson()).toList();
    await _storage.saveJsonList(_articlesKey, jsonList);
  }

  /// 加载营养记录
  Future<void> _loadNutritionEntries() async {
    final jsonList = await _storage.getJsonList(_nutritionEntriesKey);
    if (jsonList != null) {
      _nutritionEntries = jsonList.map((json) => NutritionEntry.fromJson(json)).toList();
    }
  }

  /// 保存营养记录
  Future<void> _saveNutritionEntries() async {
    final jsonList = _nutritionEntries.map((entry) => entry.toJson()).toList();
    await _storage.saveJsonList(_nutritionEntriesKey, jsonList);
  }

  /// 加载用户数据
  Future<void> _loadUserData() async {
    final userData = await _storage.getJson(_userDataKey);
    if (userData != null) {
      _calorieIntake = userData['calorieIntake'] ?? 1800;
      _caloriesBurned = userData['caloriesBurned'] ?? 2200;
      _calorieGoal = userData['calorieGoal'] ?? 2000;
      _height = userData['height']?.toDouble() ?? 175.0;
      _currentWeight = userData['currentWeight']?.toDouble() ?? 70.0;
    }
  }

  /// 保存用户数据
  Future<void> _saveUserData() async {
    final userData = {
      'calorieIntake': _calorieIntake,
      'caloriesBurned': _caloriesBurned,
      'calorieGoal': _calorieGoal,
      'height': _height,
      'currentWeight': _currentWeight,
    };
    await _storage.saveJson(_userDataKey, userData);
  }

  /// 初始化默认数据
  Future<void> _initDefaultData() async {
    // 生成近7天的体重数据
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final randomWeight = 70.0 + (i % 3 - 1) * 0.5;
      _weights7d.add(WeightEntry(date: date, value: randomWeight));
    }

    // 初始化今日训练计划
    _workoutToday = [
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
    _articles = [
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

    // 保存初始数据
    await Future.wait([
      _saveWeightEntries(),
      _saveWorkoutEntries(),
      _saveArticles(),
      _saveUserData(),
    ]);
  }

  // 公共方法

  /// 添加体重记录
  Future<void> addWeight(double value) async {
    _ensureInitialized();
    
    _weights7d.add(WeightEntry(date: DateTime.now(), value: value));
    _currentWeight = value;
    
    // 保持只有7天的数据
    if (_weights7d.length > 7) {
      _weights7d.removeAt(0);
    }
    
    await Future.wait([
      _saveWeightEntries(),
      _saveUserData(),
    ]);
    
    notifyListeners();
  }

  /// 添加训练记录
  Future<void> addWorkout(String name, int sets) async {
    _ensureInitialized();
    
    _workoutToday.add(
      WorkoutEntry(
        date: DateTime.now(),
        name: name,
        sets: sets,
      ),
    );
    
    await _saveWorkoutEntries();
    notifyListeners();
  }
  /// 切换训练完成状态
  Future<void> toggleWorkoutCompleted(int index) async {
    _ensureInitialized();
    
    if (index >= 0 && index < _workoutToday.length) {
      final workout = _workoutToday[index];
      _workoutToday[index] = workout.copyWith(
        isCompleted: !workout.isCompleted,
      );
      
      await _saveWorkoutEntries();
      notifyListeners();
    }
  }

  /// 删除训练记录
  Future<void> removeWorkout(int index) async {
    _ensureInitialized();
    
    if (index >= 0 && index < _workoutToday.length) {
      _workoutToday.removeAt(index);
      await _saveWorkoutEntries();
      notifyListeners();
    }
  }

  /// 更新热量摄入
  Future<void> updateCalorieIntake(int calories) async {
    _ensureInitialized();
    
    _calorieIntake = calories;
    await _saveUserData();
    notifyListeners();
  }

  /// 更新热量消耗
  Future<void> updateCaloriesBurned(int calories) async {
    _ensureInitialized();
    
    _caloriesBurned = calories;
    await _saveUserData();
    notifyListeners();
  }

  /// 更新热量目标
  Future<void> updateCalorieGoal(int calories) async {
    _ensureInitialized();
    
    _calorieGoal = calories;
    await _saveUserData();
    notifyListeners();
  }

  /// 更新身高
  Future<void> updateHeight(double height) async {
    _ensureInitialized();
    
    _height = height;
    await _saveUserData();
    notifyListeners();
  }

  /// 添加营养记录
  Future<void> addNutritionEntry(NutritionEntry entry) async {
    _ensureInitialized();
    
    _nutritionEntries.add(entry);
    await _saveNutritionEntries();
    notifyListeners();
  }

  /// 获取今日营养记录
  List<NutritionEntry> getTodayNutrition() {
    final today = DateTime.now();
    return _nutritionEntries.where((entry) {
      return entry.date.year == today.year &&
             entry.date.month == today.month &&
             entry.date.day == today.day;
    }).toList();
  }

  /// 获取指定日期的营养记录
  List<NutritionEntry> getNutritionByDate(DateTime date) {
    return _nutritionEntries.where((entry) {
      return entry.date.year == date.year &&
             entry.date.month == date.month &&
             entry.date.day == date.day;
    }).toList();
  }

  /// 计算今日总热量摄入
  int getTodayTotalCalories() {
    final todayNutrition = getTodayNutrition();
    return todayNutrition.fold(0, (total, entry) => total + entry.calories);
  }

  /// 清空所有数据
  Future<void> clearAllData() async {
    _ensureInitialized();
    
    _weights7d.clear();
    _workoutToday.clear();
    _articles.clear();
    _nutritionEntries.clear();
    
    await _storage.clear();
    await _initDefaultData();
    
    notifyListeners();
  }

  /// 刷新今日训练数据
  Future<void> refreshTodayWorkouts() async {
    _ensureInitialized();
    await _loadWorkoutEntries();
    notifyListeners();
  }
}
