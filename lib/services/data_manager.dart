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
  };  // 初始化
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      debugPrint('DataManager: Starting initialization...');
      _prefs = await SharedPreferences.getInstance();
      await _loadAllData();
      
      debugPrint('DataManager: Loaded data - Weight entries: ${_weightData.length}');
      
      // 检查是否需要重新初始化数据
      // 如果数据少于15条（不足30天的一半），重新初始化
      if (_weightData.length < 15) {
        debugPrint('DataManager: Insufficient data (${_weightData.length} entries), reinitializing with 30 days...');
        await clearAllData(); // 清除现有数据
        await _initializeDefaultData();
        debugPrint('DataManager: Reinitialized with ${_weightData.length} entries');
      }
      
      _initialized = true;
      notifyListeners();
      debugPrint('DataManager: Initialization completed successfully');
    } catch (e) {
      debugPrint('Error initializing DataManager: $e');
    }
  }// 初始化默认数据
  Future<void> _initializeDefaultData() async {
    debugPrint('DataManager: Initializing default data...');
    
    // 初始化默认体重数据（近30天，以满足dashboard需求）
    final now = DateTime.now();
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      // 模拟体重数据，在70kg左右波动，创建一个有趋势的数据
      final baseWeight = 72.0; // 起始体重
      final trendWeight = baseWeight - (i / 29.0) * 2.0; // 逐渐减重2kg的趋势
      final randomFluctuation = (i % 3 - 1) * 0.3; // 小幅随机波动
      final weight = trendWeight + randomFluctuation;
      _weightData[dateKey] = WeightEntry(
        date: date,
        value: weight,
      );
      debugPrint('DataManager: Added weight entry for $dateKey: ${weight.toStringAsFixed(1)}kg');
    }
    
    // 初始化默认体脂数据（近30天）
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _formatDate(date);
      // 模拟体脂数据，在16%左右波动，也有减少趋势
      final baseBodyFat = 18.0; // 起始体脂率
      final trendBodyFat = baseBodyFat - (i / 29.0) * 3.0; // 逐渐减少3%的趋势
      final randomFluctuation = (i % 2) * 0.2; // 小幅随机波动
      final bodyFat = trendBodyFat + randomFluctuation;
      _bodyFatData[dateKey] = BodyFatEntry(
        date: date,
        value: bodyFat,
      );
      debugPrint('DataManager: Added body fat entry for $dateKey: ${bodyFat.toStringAsFixed(1)}%');
    }
    
    // 初始化今日训练数据
    final todayKey = _formatDate(now);
    _workoutData[todayKey] = [
      WorkoutEntry(
        date: now,
        name: 'Push-up',
        sets: 3,
        isCompleted: true,
      ),
      WorkoutEntry(
        date: now,
        name: 'Squat',
        sets: 4,
        isCompleted: false,
      ),
      WorkoutEntry(
        date: now,
        name: 'Plank',
        sets: 3,
        isCompleted: false,
      ),
    ];
    
    // 初始化默认文章
    _articles = [
      Article(
        title: 'How to scientifically increase muscle mass',
        coverUrl: 'https://picsum.photos/id/237/200/300',
        mdPath: 'assets/articles/muscle_gain.md',
        category: 'Training',
      ),
      Article(
        title: 'Efficient fat burning training program',
        coverUrl: 'https://picsum.photos/id/238/200/300',
        mdPath: 'assets/articles/fat_burn.md',
        category: 'Trainging',
      ),
      Article(
        title: 'Dietary guidelines for athletes',
        coverUrl: 'https://picsum.photos/id/239/200/300',
        mdPath: 'assets/articles/diet.md',
        category: 'Nutrition',
      ),
      Article(
        title: '拉伸与恢复的重要性',
        coverUrl: 'https://picsum.photos/id/240/200/300',
        mdPath: 'assets/articles/recovery.md',
        category: '康复',
      ),
    ];
    
    // 保存默认数据并等待完成
    debugPrint('DataManager: Saving default data...');
    await _saveWeightData();
    await _saveBodyFatData();
    await _saveWorkoutData();
    
    debugPrint('DataManager: Default data initialized and saved successfully');
    debugPrint('DataManager: Total weight entries: ${_weightData.length}');
    debugPrint('DataManager: Current weight: ${currentWeight}');
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
  // 保存用户数据
  Future<void> _saveUserData() async {
    try {
      await _prefs.setString(_userDataKey, json.encode(_userData));
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }// 获取指定天数的体重数据
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