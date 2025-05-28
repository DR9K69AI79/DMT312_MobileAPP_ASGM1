import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/weight_entry.dart';
import '../models/workout_entry.dart';
import '../models/article.dart';
import '../models/nutrition_entry.dart';
import '../models/body_fat_entry.dart';

/// 数据管理器，负责管理所有应用数据的持久化
/// 重构为按日期组织的无限历史数据存储
class DataManager extends ChangeNotifier {
  // 数据键
  static const String _weightDataKey = 'weight_data';
  static const String _bodyFatDataKey = 'body_fat_data';
  static const String _workoutDataKey = 'workout_data';
  static const String _nutritionDataKey = 'nutrition_data';
  static const String _articlesKey = 'articles';
  static const String _userDataKey = 'user_data';

  // 单例模式实现
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  late final SharedPreferences _prefs;
  bool _initialized = false;

  // 按日期组织的数据存储 (格式: "YYYY-MM-DD")
  final Map<String, WeightEntry> _weightData = {};
  final Map<String, BodyFatEntry> _bodyFatData = {};
  final Map<String, List<WorkoutEntry>> _workoutData = {};
  final Map<String, DailyNutritionEntry> _nutritionData = {};
  
  // 其他数据
  List<Article> _articles = [];
  
  // 用户数据
  Map<String, dynamic> _userData = {
    'name': '用户',
    'age': 25,
    'height': 170,
    'gender': 'male',
    'activityLevel': 'moderate',
    'weightGoal': 65.0,
    'bodyFatGoal': 15.0,
  };

  // 初始化
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadAllData();
      await _initializeSampleData();
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing DataManager: $e');
    }
  }

  // 兼容性方法：init方法别名
  Future<void> init() async {
    await initialize();
  }

  // 加载所有数据
  Future<void> _loadAllData() async {
    await _loadWeightData();
    await _loadBodyFatData();
    await _loadWorkoutData();
    await _loadNutritionData();
    await _loadArticles();
    await _loadUserData();
  }

  // 加载体重数据
  Future<void> _loadWeightData() async {
    try {
      final String? dataJson = _prefs.getString(_weightDataKey);
      if (dataJson != null) {
        final Map<String, dynamic> dataMap = json.decode(dataJson);
        _weightData.clear();
        dataMap.forEach((key, value) {
          _weightData[key] = WeightEntry.fromJson(value);
        });
      }
    } catch (e) {
      debugPrint('Error loading weight data: $e');
    }
  }

  // 加载体脂数据
  Future<void> _loadBodyFatData() async {
    try {
      final String? dataJson = _prefs.getString(_bodyFatDataKey);
      if (dataJson != null) {
        final Map<String, dynamic> dataMap = json.decode(dataJson);
        _bodyFatData.clear();
        dataMap.forEach((key, value) {
          _bodyFatData[key] = BodyFatEntry.fromJson(value);
        });
      }
    } catch (e) {
      debugPrint('Error loading body fat data: $e');
    }
  }

  // 加载锻炼数据
  Future<void> _loadWorkoutData() async {
    try {
      final String? dataJson = _prefs.getString(_workoutDataKey);
      if (dataJson != null) {
        final Map<String, dynamic> dataMap = json.decode(dataJson);
        _workoutData.clear();
        dataMap.forEach((key, value) {
          _workoutData[key] = (value as List)
              .map((item) => WorkoutEntry.fromJson(item))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading workout data: $e');
    }
  }

  // 加载营养数据
  Future<void> _loadNutritionData() async {
    try {
      final String? dataJson = _prefs.getString(_nutritionDataKey);
      if (dataJson != null) {
        final Map<String, dynamic> dataMap = json.decode(dataJson);
        _nutritionData.clear();
        dataMap.forEach((key, value) {
          _nutritionData[key] = DailyNutritionEntry.fromJson(value);
        });
      }
    } catch (e) {
      debugPrint('Error loading nutrition data: $e');
    }
  }

  // 加载文章数据
  Future<void> _loadArticles() async {
    try {
      final String? dataJson = _prefs.getString(_articlesKey);
      if (dataJson != null) {
        final List<dynamic> dataList = json.decode(dataJson);
        _articles = dataList.map((item) => Article.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error loading articles: $e');
    }
  }

  // 加载用户数据
  Future<void> _loadUserData() async {
    try {
      final String? dataJson = _prefs.getString(_userDataKey);
      if (dataJson != null) {
        _userData = json.decode(dataJson);
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // 保存体重数据
  Future<void> _saveWeightData() async {
    try {
      final Map<String, dynamic> dataMap = {};
      _weightData.forEach((key, value) {
        dataMap[key] = value.toJson();
      });
      await _prefs.setString(_weightDataKey, json.encode(dataMap));
    } catch (e) {
      debugPrint('Error saving weight data: $e');
    }
  }

  // 保存体脂数据
  Future<void> _saveBodyFatData() async {
    try {
      final Map<String, dynamic> dataMap = {};
      _bodyFatData.forEach((key, value) {
        dataMap[key] = value.toJson();
      });
      await _prefs.setString(_bodyFatDataKey, json.encode(dataMap));
    } catch (e) {
      debugPrint('Error saving body fat data: $e');
    }
  }

  // 保存锻炼数据
  Future<void> _saveWorkoutData() async {
    try {
      final Map<String, dynamic> dataMap = {};
      _workoutData.forEach((key, value) {
        dataMap[key] = value.map((item) => item.toJson()).toList();
      });
      await _prefs.setString(_workoutDataKey, json.encode(dataMap));
    } catch (e) {
      debugPrint('Error saving workout data: $e');
    }
  }

  // 保存营养数据
  Future<void> _saveNutritionData() async {
    try {
      final Map<String, dynamic> dataMap = {};
      _nutritionData.forEach((key, value) {
        dataMap[key] = value.toJson();
      });
      await _prefs.setString(_nutritionDataKey, json.encode(dataMap));
    } catch (e) {
      debugPrint('Error saving nutrition data: $e');
    }
  }

  // 保存文章数据
  Future<void> _saveArticles() async {
    try {
      final List<Map<String, dynamic>> dataList = 
          _articles.map((item) => item.toJson()).toList();
      await _prefs.setString(_articlesKey, json.encode(dataList));
    } catch (e) {
      debugPrint('Error saving articles: $e');
    }
  }

  // 保存用户数据
  Future<void> _saveUserData() async {
    try {
      await _prefs.setString(_userDataKey, json.encode(_userData));
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }
  // 初始化示例数据
  Future<void> _initializeSampleData() async {
    if (_weightData.isEmpty) {
      await _initializeSampleWeightData();
    }
    if (_workoutData.isEmpty) {
      await _initializeSampleWorkoutData();
    }    if (_nutritionData.isEmpty) {
      await _initializeSampleNutritionData();
    }
    if (_articles.isEmpty) {
      await _initializeSampleArticles();
    }
  }

  // 初始化示例体重数据
  Future<void> _initializeSampleWeightData() async {
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      final weight = 70.0 + (i * 0.2) - 1.2; // 模拟体重变化
        _weightData[dateKey] = WeightEntry(
        value: double.parse(weight.toStringAsFixed(1)),
        date: date,
      );
    }
    await _saveWeightData();
  }

  // 初始化示例锻炼数据
  Future<void> _initializeSampleWorkoutData() async {
    final now = DateTime.now();
    final today = _formatDate(now);
      _workoutData[today] = [
      WorkoutEntry(
        name: '俯卧撑',
        sets: 3,
        date: now,
      ),
      WorkoutEntry(
        name: '深蹲',
        sets: 3,
        date: now,
      ),
    ];
    
    // 添加昨天的数据
    final yesterday = _formatDate(now.subtract(const Duration(days: 1)));
    _workoutData[yesterday] = [
      WorkoutEntry(
        name: '跑步',
        sets: 1,
        date: now.subtract(const Duration(days: 1)),
      ),
    ];
    
    await _saveWorkoutData();
  }

  // 初始化示例营养数据
  Future<void> _initializeSampleNutritionData() async {
    final now = DateTime.now();
    final today = _formatDate(now);
      _nutritionData[today] = DailyNutritionEntry(
      date: now,
      calorieIntake: 1800,
      caloriesBurned: 250,
      calorieGoal: 2000,
      meals: [
        MealEntry(
          mealType: '早餐',
          name: '燕麦粥',
          calories: 400,
          amount: '1份',
          timestamp: DateTime(now.year, now.month, now.day, 8, 0),
        ),
        MealEntry(
          mealType: '午餐',
          name: '鸡胸肉沙拉',
          calories: 600,
          amount: '1份',
          timestamp: DateTime(now.year, now.month, now.day, 12, 30),
        ),
        MealEntry(
          mealType: '晚餐',
          name: '蒸蛋羹',
          calories: 500,
          amount: '1份',
          timestamp: DateTime(now.year, now.month, now.day, 18, 30),
        ),
        MealEntry(
          mealType: '加餐',
          name: '水果',
          calories: 300,
          amount: '1份',
          timestamp: DateTime(now.year, now.month, now.day, 15, 0),
        ),
      ],
    );
    
    await _saveNutritionData();
  }
  // 初始化示例文章数据
  Future<void> _initializeSampleArticles() async {
    _articles = [
      Article(
        title: '健康饮食的重要性',
        coverUrl: 'assets/images/article1.jpg',
        mdPath: 'assets/articles/healthy_diet.md',
        category: '营养',
      ),
      Article(
        title: '有效的锻炼计划',
        coverUrl: 'assets/images/article2.jpg',
        mdPath: 'assets/articles/workout_plan.md',
        category: '锻炼',
      ),
    ];
    await _saveArticles();
  }

  // 获取指定天数的体重数据
  Map<String, WeightEntry> getWeightData({int? days}) {
    if (days == null) {
      return Map.from(_weightData);
    }
    
    final now = DateTime.now();
    final Map<String, WeightEntry> result = {};
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      if (_weightData.containsKey(dateKey)) {
        result[dateKey] = _weightData[dateKey]!;
      }
    }
    
    return result;
  }

  // 获取指定天数的体脂数据
  Map<String, BodyFatEntry> getBodyFatData({int? days}) {
    if (days == null) {
      return Map.from(_bodyFatData);
    }
    
    final now = DateTime.now();
    final Map<String, BodyFatEntry> result = {};
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      if (_bodyFatData.containsKey(dateKey)) {
        result[dateKey] = _bodyFatData[dateKey]!;
      }
    }
    
    return result;
  }

  // 获取指定天数的锻炼数据
  Map<String, List<WorkoutEntry>> getWorkoutData({int? days}) {
    if (days == null) {
      return Map.from(_workoutData);
    }
    
    final now = DateTime.now();
    final Map<String, List<WorkoutEntry>> result = {};
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      if (_workoutData.containsKey(dateKey)) {
        result[dateKey] = _workoutData[dateKey]!;
      }
    }
    
    return result;
  }

  // 获取指定天数的营养数据
  Map<String, DailyNutritionEntry> getNutritionData({int? days}) {
    if (days == null) {
      return Map.from(_nutritionData);
    }
    
    final now = DateTime.now();
    final Map<String, DailyNutritionEntry> result = {};
    
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      if (_nutritionData.containsKey(dateKey)) {
        result[dateKey] = _nutritionData[dateKey]!;
      }
    }
    
    return result;
  }

  // 兼容性接口：获取最近7天体重数据
  List<WeightEntry> get weights7d {
    final data = getWeightData(days: 7);
    return data.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  // 兼容性接口：获取当前体重
  double? get currentWeight {
    if (_weightData.isEmpty) return null;
    final sortedEntries = _weightData.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedEntries.first.value;
  }

  // 兼容性接口：获取今天的锻炼数据
  List<WorkoutEntry> get workoutToday {
    final today = _formatDate(DateTime.now());
    return _workoutData[today] ?? [];
  }

  // 兼容性接口：获取今天的营养数据
  DailyNutritionEntry? get nutritionToday {
    final today = _formatDate(DateTime.now());
    return _nutritionData[today];
  }

  // 获取文章列表
  List<Article> get articles => List.from(_articles);
  // 获取用户数据
  Map<String, dynamic> get userData => Map.from(_userData);
  // 兼容性接口：获取当前热量摄入
  int get calorieIntake {
    final today = nutritionToday;
    return today?.calorieIntake ?? 0;
  }

  // 兼容性接口：获取当前热量消耗
  int get caloriesBurned {
    final today = nutritionToday;
    return today?.caloriesBurned ?? 0;
  }
  // 兼容性接口：获取热量目标
  int get calorieGoal {
    final today = nutritionToday;
    return today?.calorieGoal ?? 2000;
  }

  // 兼容性接口：获取热量平衡
  int get calorieBalance => calorieIntake - caloriesBurned;
  // 兼容性方法：更新热量摄入
  Future<void> updateCalorieIntake(int intake, {DateTime? date}) async {
    date ??= DateTime.now();
    final dateKey = _formatDate(date);
    
    if (!_nutritionData.containsKey(dateKey)) {
      _nutritionData[dateKey] = DailyNutritionEntry(
        date: date,
        calorieIntake: intake,
        caloriesBurned: 0,
        calorieGoal: 2000,
        meals: [],
      );
    } else {
      _nutritionData[dateKey] = _nutritionData[dateKey]!.copyWith(
        calorieIntake: intake,
      );
    }
    
    await _saveNutritionData();
    notifyListeners();
  }

  // 兼容性方法：更新热量消耗
  Future<void> updateCaloriesBurned(int burned, {DateTime? date}) async {
    date ??= DateTime.now();
    final dateKey = _formatDate(date);
    
    if (!_nutritionData.containsKey(dateKey)) {
      _nutritionData[dateKey] = DailyNutritionEntry(
        date: date,
        calorieIntake: 0,
        caloriesBurned: burned,
        calorieGoal: 2000,
        meals: [],
      );
    } else {
      _nutritionData[dateKey] = _nutritionData[dateKey]!.copyWith(
        caloriesBurned: burned,
      );
    }
    
    await _saveNutritionData();
    notifyListeners();
  }

  // 兼容性方法：更新热量目标
  Future<void> updateCalorieGoal(int goal, {DateTime? date}) async {
    date ??= DateTime.now();
    final dateKey = _formatDate(date);
    
    if (!_nutritionData.containsKey(dateKey)) {
      _nutritionData[dateKey] = DailyNutritionEntry(
        date: date,
        calorieIntake: 0,
        caloriesBurned: 0,
        calorieGoal: goal,
        meals: [],
      );
    } else {
      _nutritionData[dateKey] = _nutritionData[dateKey]!.copyWith(
        calorieGoal: goal,
      );
    }
    
    await _saveNutritionData();
    notifyListeners();
  }

  // 兼容性方法：更新锻炼完成状态
  Future<void> updateWorkoutCompletion(int index, bool isCompleted, {DateTime? date}) async {
    date ??= DateTime.now();
    final dateKey = _formatDate(date);
    
    if (_workoutData.containsKey(dateKey) && 
        index < _workoutData[dateKey]!.length) {
      final workouts = List<WorkoutEntry>.from(_workoutData[dateKey]!);
      workouts[index] = workouts[index].copyWith(isCompleted: isCompleted);
      _workoutData[dateKey] = workouts;
      
      await _saveWorkoutData();
      notifyListeners();
    }
  }
  // 添加体重记录
  Future<void> addWeight(double weight, {DateTime? date}) async {
    date ??= DateTime.now();
    final dateKey = _formatDate(date);
      _weightData[dateKey] = WeightEntry(
      value: weight,
      date: date,
    );
    
    await _saveWeightData();
    notifyListeners();
  }

  // 添加体脂记录
  Future<void> addBodyFat(double bodyFatPercentage, {DateTime? date}) async {
    date ??= DateTime.now();
    final dateKey = _formatDate(date);
      _bodyFatData[dateKey] = BodyFatEntry(
      value: bodyFatPercentage,
      date: date,
    );
    
    await _saveBodyFatData();
    notifyListeners();
  }

  // 添加锻炼记录
  Future<void> addWorkout(WorkoutEntry workout) async {
    final dateKey = _formatDate(workout.date);
    
    if (!_workoutData.containsKey(dateKey)) {
      _workoutData[dateKey] = [];
    }
    _workoutData[dateKey]!.add(workout);
    
    await _saveWorkoutData();
    notifyListeners();
  }
  // 添加餐食记录
  Future<void> addMeal(MealEntry meal, {DateTime? date}) async {
    date ??= DateTime.now();
    final dateKey = _formatDate(date);
    
    if (!_nutritionData.containsKey(dateKey)) {
      _nutritionData[dateKey] = DailyNutritionEntry(
        date: date,
        calorieIntake: 0,
        caloriesBurned: 0,
        calorieGoal: 2000,
        meals: [],
      );
    }
    
    final currentEntry = _nutritionData[dateKey]!;
    final updatedMeals = List<MealEntry>.from(currentEntry.meals)..add(meal);
    final totalCalories = updatedMeals.fold<int>(0, (sum, m) => sum + m.calories);
    
    _nutritionData[dateKey] = currentEntry.copyWith(
      meals: updatedMeals,
      calorieIntake: totalCalories,
    );
    
    await _saveNutritionData();
    notifyListeners();
  }

  // 删除餐食记录
  Future<void> removeMeal(int mealIndex, {DateTime? date}) async {
    date ??= DateTime.now();
    final dateKey = _formatDate(date);
    
    if (_nutritionData.containsKey(dateKey) && 
        mealIndex < _nutritionData[dateKey]!.meals.length) {
      final currentEntry = _nutritionData[dateKey]!;
      final updatedMeals = List<MealEntry>.from(currentEntry.meals)..removeAt(mealIndex);
      final totalCalories = updatedMeals.fold<int>(0, (sum, m) => sum + m.calories);
      
      _nutritionData[dateKey] = currentEntry.copyWith(
        meals: updatedMeals,
        calorieIntake: totalCalories,
      );
      
      await _saveNutritionData();
      notifyListeners();
    }
  }

  // 更新用户数据
  Future<void> updateUserData(Map<String, dynamic> data) async {
    _userData.addAll(data);
    await _saveUserData();
    notifyListeners();
  }

  // 格式化日期为字符串
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 清除所有数据
  Future<void> clearAllData() async {
    _weightData.clear();
    _bodyFatData.clear();
    _workoutData.clear();
    _nutritionData.clear();
    _articles.clear();
    
    await _prefs.clear();
    notifyListeners();
  }

  // 兼容性方法：获取锻炼完成度百分比
  double get workoutCompletionPercent {
    final today = workoutToday;
    if (today.isEmpty) return 0.0;
    
    final completedCount = today.where((workout) => workout.isCompleted).length;
    return completedCount / today.length;
  }

  // 兼容性方法：切换锻炼完成状态
  Future<void> toggleWorkoutCompleted(int index, {DateTime? date}) async {
    date ??= DateTime.now();
    final dateKey = _formatDate(date);
    
    if (_workoutData.containsKey(dateKey) && 
        index < _workoutData[dateKey]!.length) {
      final workouts = List<WorkoutEntry>.from(_workoutData[dateKey]!);
      workouts[index] = workouts[index].copyWith(
        isCompleted: !workouts[index].isCompleted
      );
      _workoutData[dateKey] = workouts;
      
      await _saveWorkoutData();
      notifyListeners();
    }
  }

  // 兼容性方法：删除锻炼记录
  Future<void> removeWorkout(int index, {DateTime? date}) async {
    date ??= DateTime.now();
    final dateKey = _formatDate(date);
    
    if (_workoutData.containsKey(dateKey) && 
        index < _workoutData[dateKey]!.length) {
      _workoutData[dateKey]!.removeAt(index);
      
      await _saveWorkoutData();
      notifyListeners();
    }
  }

  // 兼容性接口：获取身高
  double get height {
    return (_userData['height'] as num?)?.toDouble() ?? 170.0;
  }

  // 兼容性接口：获取当前体脂率
  double? get currentBodyFat {
    if (_bodyFatData.isEmpty) return null;
    final sortedEntries = _bodyFatData.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedEntries.first.value;
  }

  // 兼容性接口：获取BMI
  double get bmi {
    final weight = currentWeight ?? 0.0;
    final heightInMeters = height / 100;
    if (heightInMeters <= 0) return 0.0;
    return weight / (heightInMeters * heightInMeters);
  }

  // 兼容性方法：更新身高
  Future<void> updateHeight(double newHeight) async {
    _userData['height'] = newHeight;
    await _saveUserData();
    notifyListeners();
  }
}