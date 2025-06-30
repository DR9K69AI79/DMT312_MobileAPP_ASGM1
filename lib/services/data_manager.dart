import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/weight_entry.dart';
import '../models/workout_entry.dart';
import '../models/article.dart';
import '../models/nutrition_entry.dart';
import '../models/user.dart';
import '../models/body_fat_entry.dart';
import 'article_service.dart';
import 'database_service.dart';

/// 数据管理器，重构为使用SQLite数据库存储
/// 负责管理用户认证和全局状态
class DataManager extends ChangeNotifier {
  // 单例模式实现
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  late final SharedPreferences _prefs;
  late final DatabaseService _dbService;
  bool _initialized = false;

  // 当前登录用户
  User? _currentUser;
  
  // 其他数据
  List<Article> _articles = [];
  
  // 用户设置缓存
  int _calorieGoal = 2000;
  Map<String, int> _dailyCalorieIntake = {};
  Map<String, int> _dailyCaloriesBurned = {};
  
  // 临时缓存数据 (为了性能优化)
  Map<String, WeightEntry> _weightCache = {};
  Map<String, List<WorkoutEntry>> _workoutCache = {};
  Map<String, List<MealEntry>> _mealCache = {};
  Map<String, BodyFatEntry> _bodyFatCache = {};

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  List<Article> get articles => _articles;

  // 用户相关的属性（从当前用户获取）
  double get height => _currentUser?.height ?? 170.0;
  String get userName => _currentUser?.name ?? '未登录用户';
  String get userEmail => _currentUser?.email ?? '';

  // 初始化
  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      _prefs = await SharedPreferences.getInstance();
      _dbService = DatabaseService.instance;
      
      // 初始化数据库
      await _dbService.initDatabase();
      
      // 创建示例用户（如果数据库为空）
      await _createDefaultUserIfNeeded();
      
      // 尝试恢复用户登录状态
      await _restoreUserSession();
      
      // 加载文章数据
      final articleService = ArticleService();
      _articles = await articleService.loadAllArticles();
      
      _initialized = true;
      debugPrint('DataManager: 初始化完成');
    } catch (e) {
      debugPrint('DataManager: 初始化失败: $e');
    }
  }

  // 如果需要，创建默认用户
  Future<void> _createDefaultUserIfNeeded() async {
    try {
      // 检查是否已有用户
      final existingUser = await _dbService.getUser('demo@fitlog.com', 'demo123');
      if (existingUser == null) {
        // 创建示例用户
        final demoUser = User(
          name: '示例用户',
          email: 'demo@fitlog.com',
          password: 'demo123',
          height: 170.0,
          createdAt: DateTime.now(),
        );
        
        await _dbService.createUser(demoUser);
        debugPrint('DataManager: 创建示例用户完成 - 邮箱: demo@fitlog.com, 密码: demo123');
      } else {
        debugPrint('DataManager: 示例用户已存在');
      }
    } catch (e) {
      debugPrint('DataManager: 创建示例用户失败: $e');
    }
  }

  // 恢复用户会话
  Future<void> _restoreUserSession() async {
    final userId = _prefs.getInt('current_user_id');
    if (userId != null) {
      try {
        _currentUser = await _dbService.getUserById(userId);
        if (_currentUser != null) {
          // 加载用户设置
          await _loadUserSettings();
          debugPrint('DataManager: 恢复用户会话: ${_currentUser!.name}');
          notifyListeners();
        }
      } catch (e) {
        debugPrint('DataManager: 恢复用户会话失败: $e');
      }
    }
  }

  // 保存用户会话
  Future<void> _saveUserSession() async {
    if (_currentUser?.id != null) {
      await _prefs.setInt('current_user_id', _currentUser!.id!);
    } else {
      await _prefs.remove('current_user_id');
    }
  }

  // === 用户认证相关方法 ===

  /// 用户注册
  Future<bool> register(User newUser) async {
    try {
      // 检查邮箱是否已存在
      if (await _dbService.isEmailExists(newUser.email)) {
        debugPrint('DataManager: 注册失败 - 邮箱已存在');
        return false;
      }

      // 创建用户
      final userId = await _dbService.createUser(newUser.copyWith(
        createdAt: DateTime.now(),
      ));

      // 获取完整的用户信息（包含生成的ID）
      _currentUser = await _dbService.getUserById(userId);
      await _saveUserSession();

      debugPrint('DataManager: 用户注册成功: ${_currentUser!.name}');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('DataManager: 注册失败: $e');
      return false;
    }
  }

  /// 用户登录
  Future<bool> login(String email, String password) async {
    try {
      _currentUser = await _dbService.getUser(email, password);
      if (_currentUser != null) {
        await _saveUserSession();
        
        // 清空缓存，准备加载新用户数据
        _clearCache();
        
        // 加载用户设置
        await _loadUserSettings();
        
        // 预加载用户数据
        await _preloadUserData();
        
        // 预加载用户数据
        await _preloadUserData();
        
        debugPrint('DataManager: 用户登录成功: ${_currentUser!.name}');
        notifyListeners();
        return true;
      } else {
        debugPrint('DataManager: 登录失败 - 用户名或密码错误');
        return false;
      }
    } catch (e) {
      debugPrint('DataManager: 登录失败: $e');
      return false;
    }
  }

  /// 用户登出
  Future<void> logout() async {
    _currentUser = null;
    await _saveUserSession();
    _clearCache();
    debugPrint('DataManager: 用户已登出');
    notifyListeners();
  }

  /// 更新用户资料
  Future<bool> updateProfile(User updatedUser) async {
    if (_currentUser == null) return false;

    try {
      await _dbService.updateUser(updatedUser);
      _currentUser = updatedUser;
      debugPrint('DataManager: 用户资料更新成功');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('DataManager: 更新用户资料失败: $e');
      return false;
    }
  }

  // 清空缓存
  void _clearCache() {
    _weightCache.clear();
    _workoutCache.clear();
    _mealCache.clear();
    _bodyFatCache.clear();
    _dailyCalorieIntake.clear();
    _dailyCaloriesBurned.clear();
    _calorieGoal = 2000; // 重置为默认值
  }

  // === 体重记录相关方法 ===

  /// 添加体重记录
  Future<void> addWeight(WeightEntry entry) async {
    if (_currentUser == null) return;

    try {
      await _dbService.addWeight(entry, _currentUser!.id!);
      _weightCache[_formatDate(entry.date)] = entry;
      debugPrint('DataManager: 体重记录添加成功');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 添加体重记录失败: $e');
    }
  }

  /// 获取体重记录列表
  Future<List<WeightEntry>> getWeightEntries() async {
    if (_currentUser == null) return [];

    try {
      final entries = await _dbService.getWeights(_currentUser!.id!);
      
      // 更新缓存
      _weightCache.clear();
      for (final entry in entries) {
        _weightCache[_formatDate(entry.date)] = entry;
      }
      
      return entries;
    } catch (e) {
      debugPrint('DataManager: 获取体重记录失败: $e');
      return [];
    }
  }

  /// 获取当前体重
  double? get currentWeight {
    if (_weightCache.isEmpty) return null;
    final sortedEntries = _weightCache.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedEntries.first.value;
  }

  /// 删除体重记录
  Future<void> deleteWeight(int id) async {
    try {
      await _dbService.deleteWeight(id);
      // 清除缓存，强制重新加载
      _weightCache.clear();
      debugPrint('DataManager: 体重记录删除成功');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 删除体重记录失败: $e');
    }
  }

  // === 训练记录相关方法 ===

  /// 添加训练记录
  Future<void> addWorkout(WorkoutEntry entry) async {
    if (_currentUser == null) return;

    try {
      await _dbService.addWorkout(entry, _currentUser!.id!);
      
      // 更新缓存
      final dateKey = _formatDate(entry.date);
      if (!_workoutCache.containsKey(dateKey)) {
        _workoutCache[dateKey] = [];
      }
      _workoutCache[dateKey]!.add(entry);
      
      debugPrint('DataManager: 训练记录添加成功');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 添加训练记录失败: $e');
    }
  }

  /// 获取特定日期的训练记录
  Future<List<WorkoutEntry>> getWorkoutsForDate(DateTime date) async {
    if (_currentUser == null) return [];

    final dateKey = _formatDate(date);
    
    // 检查缓存
    if (_workoutCache.containsKey(dateKey)) {
      return _workoutCache[dateKey]!;
    }

    try {
      final entries = await _dbService.getWorkoutsByDate(
        _currentUser!.id!, 
        dateKey
      );
      _workoutCache[dateKey] = entries;
      return entries;
    } catch (e) {
      debugPrint('DataManager: 获取训练记录失败: $e');
      return [];
    }
  }

  /// 更新训练记录完成状态
  Future<void> toggleWorkoutCompletion(WorkoutEntry workout) async {
    if (_currentUser == null) return;

    try {
      final updatedWorkout = workout.copyWith(
        isCompleted: !workout.isCompleted
      );
      
      await _dbService.updateWorkout(updatedWorkout, _currentUser!.id!);
      
      // 更新缓存
      final dateKey = _formatDate(workout.date);
      if (_workoutCache.containsKey(dateKey)) {
        final index = _workoutCache[dateKey]!.indexWhere(
          (w) => w.name == workout.name && w.date == workout.date
        );
        if (index != -1) {
          _workoutCache[dateKey]![index] = updatedWorkout;
        }
      }
      
      debugPrint('DataManager: 训练状态更新成功');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 更新训练状态失败: $e');
    }
  }

  /// 删除训练记录
  Future<void> deleteWorkout(int id) async {
    try {
      await _dbService.deleteWorkout(id);
      // 清除缓存
      _workoutCache.clear();
      debugPrint('DataManager: 训练记录删除成功');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 删除训练记录失败: $e');
    }
  }

  // === 饮食记录相关方法 ===

  /// 添加饮食记录
  Future<void> addMeal(MealEntry entry) async {
    if (_currentUser == null) return;

    try {
      await _dbService.addMeal(entry, _currentUser!.id!);
      
      // 更新缓存
      final dateKey = _formatDate(entry.timestamp);
      if (!_mealCache.containsKey(dateKey)) {
        _mealCache[dateKey] = [];
      }
      _mealCache[dateKey]!.add(entry);
      
      debugPrint('DataManager: 饮食记录添加成功');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 添加饮食记录失败: $e');
    }
  }

  /// 获取特定日期的饮食记录
  Future<List<MealEntry>> getMealsForDate(DateTime date) async {
    if (_currentUser == null) return [];

    final dateKey = _formatDate(date);
    
    // 检查缓存
    if (_mealCache.containsKey(dateKey)) {
      return _mealCache[dateKey]!;
    }

    try {
      final entries = await _dbService.getMealsByDate(
        _currentUser!.id!, 
        dateKey
      );
      _mealCache[dateKey] = entries;
      return entries;
    } catch (e) {
      debugPrint('DataManager: 获取饮食记录失败: $e');
      return [];
    }
  }

  /// 删除饮食记录
  Future<void> deleteMeal(int id) async {
    try {
      await _dbService.deleteMeal(id);
      // 清除缓存
      _mealCache.clear();
      debugPrint('DataManager: 饮食记录删除成功');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 删除饮食记录失败: $e');
    }
  }

  // === 体脂率记录相关方法 ===

  /// 添加体脂率记录
  Future<void> addBodyFatEntry(BodyFatEntry entry) async {
    if (_currentUser == null) return;

    try {
      await _dbService.addBodyFat(entry, _currentUser!.id!);
      _bodyFatCache[_formatDate(entry.date)] = entry;
      debugPrint('DataManager: 体脂率记录添加成功');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 添加体脂率记录失败: $e');
    }
  }

  /// 获取体脂率记录列表
  Future<List<BodyFatEntry>> getBodyFatEntries() async {
    if (_currentUser == null) return [];

    try {
      final entries = await _dbService.getBodyFats(_currentUser!.id!);
      
      // 更新缓存
      _bodyFatCache.clear();
      for (final entry in entries) {
        _bodyFatCache[_formatDate(entry.date)] = entry;
      }
      
      return entries;
    } catch (e) {
      debugPrint('DataManager: 获取体脂率记录失败: $e');
      return [];
    }
  }

  /// 删除体脂率记录
  Future<void> deleteBodyFat(int id) async {
    try {
      await _dbService.deleteBodyFat(id);
      // 清除缓存，强制重新加载
      _bodyFatCache.clear();
      debugPrint('DataManager: 体脂率记录删除成功');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 删除体脂率记录失败: $e');
    }
  }

  // === 兼容性方法和属性 ===

  /// 获取BMI
  double get bmi {
    final weight = currentWeight ?? 0.0;
    final heightInMeters = height / 100;
    if (heightInMeters <= 0) return 0.0;
    return weight / (heightInMeters * heightInMeters);
  }

  /// 兼容性：当前体脂率
  double? get currentBodyFat {
    if (_bodyFatCache.isEmpty) return null;
    final sortedEntries = _bodyFatCache.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sortedEntries.first.value;
  }

  /// 兼容性：7天体重数据
  List<WeightEntry> get weights7d {
    if (_weightCache.isEmpty) return [];
    
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 7));
    
    return _weightCache.values
        .where((entry) => entry.date.isAfter(cutoffDate))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// 兼容性：训练完成率
  double get workoutCompletionPercent {
    final today = DateTime.now();
    final todayKey = _formatDate(today);
    final todayWorkouts = _workoutCache[todayKey] ?? [];
    
    if (todayWorkouts.isEmpty) return 0.0;
    
    final completedCount = todayWorkouts.where((w) => w.isCompleted).length;
    return (completedCount / todayWorkouts.length) * 100;
  }

  /// 兼容性：今日训练
  List<WorkoutEntry> get workoutToday {
    final today = DateTime.now();
    final todayKey = _formatDate(today);
    return _workoutCache[todayKey] ?? [];
  }

  /// 兼容性：热量摄入
  int get calorieIntake {
    final today = _formatDate(DateTime.now());
    return _dailyCalorieIntake[today] ?? 0;
  }

  /// 兼容性：热量消耗
  int get caloriesBurned {
    final today = _formatDate(DateTime.now());
    return _dailyCaloriesBurned[today] ?? 0;
  }

  /// 兼容性：热量平衡
  int get calorieBalance => calorieIntake - caloriesBurned;

  /// 兼容性：热量目标
  int get calorieGoal => _calorieGoal;

  /// 兼容性：今日营养
  DailyNutritionEntry? get nutritionToday {
    final today = _formatDate(DateTime.now());
    final todayMeals = _mealCache[today] ?? [];
    
    // 从饮食记录计算热量摄入
    final totalCalorieIntake = todayMeals.fold(0, (sum, meal) => sum + meal.calories);
    
    // 从训练记录计算热量消耗（简化计算）
    final todayWorkouts = _workoutCache[today] ?? [];
    final completedWorkouts = todayWorkouts.where((w) => w.isCompleted);
    final totalCaloriesBurned = completedWorkouts.fold(0, (sum, workout) {
      // 简化的热量消耗计算：每组训练消耗约30卡路里
      return sum + (workout.sets * 30);
    });
    
    // 更新缓存
    _dailyCalorieIntake[today] = totalCalorieIntake;
    _dailyCaloriesBurned[today] = totalCaloriesBurned;
    
    return DailyNutritionEntry(
      date: DateTime.now(),
      calorieIntake: totalCalorieIntake,
      caloriesBurned: totalCaloriesBurned,
      calorieGoal: _calorieGoal,
      meals: todayMeals,
    );
  }

  /// 兼容性方法：切换训练完成状态
  Future<void> toggleWorkoutCompleted(int index) async {
    if (_currentUser == null) return;
    
    final today = DateTime.now();
    final todayKey = _formatDate(today);
    final todayWorkouts = _workoutCache[todayKey] ?? [];
    
    if (index < 0 || index >= todayWorkouts.length) {
      debugPrint('DataManager: 无效的训练索引: $index');
      return;
    }
    
    final workout = todayWorkouts[index];
    await toggleWorkoutCompletion(workout);
  }

  /// 兼容性方法：更新身高
  Future<void> updateHeight(double newHeight) async {
    if (_currentUser != null) {
      final updatedUser = _currentUser!.copyWith(height: newHeight);
      await updateProfile(updatedUser);
    }
  }

  /// 兼容性方法：添加体脂记录
  Future<void> addBodyFat(double value) async {
    if (_currentUser == null) return;

    try {
      final entry = BodyFatEntry(
        value: value,
        date: DateTime.now(),
      );
      
      await _dbService.addBodyFat(entry, _currentUser!.id!);
      _bodyFatCache[_formatDate(entry.date)] = entry;
      
      debugPrint('DataManager: 体脂率记录添加成功');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 添加体脂率记录失败: $e');
    }
  }

  /// 兼容性方法：更新热量摄入
  Future<void> updateCalorieIntake(int calories, {DateTime? date}) async {
    if (_currentUser == null) return;

    try {
      final targetDate = date ?? DateTime.now();
      final dateKey = _formatDate(targetDate);
      
      // 更新缓存
      _dailyCalorieIntake[dateKey] = calories;
      
      // 保存到数据库（用户设置表）
      await _dbService.setUserSetting(_currentUser!.id!, 'calorie_intake_$dateKey', calories.toString());
      
      debugPrint('DataManager: 热量摄入更新成功: $calories');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 更新热量摄入失败: $e');
    }
  }

  /// 兼容性方法：更新热量消耗
  Future<void> updateCaloriesBurned(int calories, {DateTime? date}) async {
    if (_currentUser == null) return;

    try {
      final targetDate = date ?? DateTime.now();
      final dateKey = _formatDate(targetDate);
      
      // 更新缓存
      _dailyCaloriesBurned[dateKey] = calories;
      
      // 保存到数据库（用户设置表）
      await _dbService.setUserSetting(_currentUser!.id!, 'calories_burned_$dateKey', calories.toString());
      
      debugPrint('DataManager: 热量消耗更新成功: $calories');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 更新热量消耗失败: $e');
    }
  }

  /// 兼容性方法：更新热量目标
  Future<void> updateCalorieGoal(int goal, {DateTime? date}) async {
    if (_currentUser == null) return;

    try {
      _calorieGoal = goal;
      
      // 保存到数据库（用户设置表）
      await _dbService.setUserSetting(_currentUser!.id!, 'calorie_goal', goal.toString());
      
      debugPrint('DataManager: 热量目标更新成功: $goal');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 更新热量目标失败: $e');
    }
  }

  /// 兼容性方法：移除训练记录
  Future<void> removeWorkout(int index) async {
    if (_currentUser == null) return;
    
    final today = DateTime.now();
    final todayKey = _formatDate(today);
    final todayWorkouts = _workoutCache[todayKey] ?? [];
    
    if (index < 0 || index >= todayWorkouts.length) {
      debugPrint('DataManager: 无效的训练索引: $index');
      return;
    }
    
    try {
      // 由于模型中没有ID，暂时从缓存中移除
      // TODO: 需要数据库支持按详细信息删除的方法
      todayWorkouts.removeAt(index);
      _workoutCache[todayKey] = todayWorkouts;
      
      debugPrint('DataManager: 训练记录删除成功（从缓存）');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 删除训练记录失败: $e');
    }
  }

  /// 兼容性方法：移除饮食记录
  Future<void> removeMeal(int index) async {
    if (_currentUser == null) return;
    
    final today = DateTime.now();
    final todayKey = _formatDate(today);
    final todayMeals = _mealCache[todayKey] ?? [];
    
    if (index < 0 || index >= todayMeals.length) {
      debugPrint('DataManager: 无效的饮食索引: $index');
      return;
    }
    
    try {
      // 由于模型中没有ID，暂时从缓存中移除
      // TODO: 需要数据库支持按详细信息删除的方法
      todayMeals.removeAt(index);
      _mealCache[todayKey] = todayMeals;
      
      debugPrint('DataManager: 饮食记录删除成功（从缓存）');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 删除饮食记录失败: $e');
    }
  }

  /// 兼容性方法：清空所有数据
  Future<void> clearAllData() async {
    if (_currentUser != null) {
      await _dbService.clearUserData(_currentUser!.id!);
      _clearCache();
      notifyListeners();
    }
  }

  /// 兼容性方法：获取体重数据
  Map<String, WeightEntry> getWeightData({int? days}) {
    if (days == null) {
      return _weightCache;
    }
    
    // 如果指定了天数，过滤数据
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final filteredData = <String, WeightEntry>{};
    
    for (final entry in _weightCache.entries) {
      if (entry.value.date.isAfter(cutoffDate)) {
        filteredData[entry.key] = entry.value;
      }
    }
    
    return filteredData;
  }

  /// 兼容性方法：获取体脂数据
  Map<String, dynamic> getBodyFatData({int? days}) {
    final result = <String, dynamic>{};
    
    if (days == null) {
      // 返回所有体脂率数据
      for (final entry in _bodyFatCache.entries) {
        result[entry.key] = entry.value.value; // 返回体脂率数值
      }
    } else {
      // 返回指定天数的数据
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      for (final entry in _bodyFatCache.entries) {
        if (entry.value.date.isAfter(cutoffDate)) {
          result[entry.key] = entry.value.value;
        }
      }
    }
    
    return result;
  }

  /// 兼容性方法：获取训练数据
  Map<String, List<WorkoutEntry>> getWorkoutData() {
    return _workoutCache;
  }

  /// 兼容性方法：获取营养数据
  Map<String, DailyNutritionEntry> getNutritionData({int? days}) {
    final result = <String, DailyNutritionEntry>{};
    
    if (days == null) {
      // 返回所有数据
      for (final entry in _mealCache.entries) {
        final dateKey = entry.key;
        final meals = entry.value;
        
        if (meals.isNotEmpty) {
          final totalCalories = meals.fold(0, (sum, meal) => sum + meal.calories);
          
          // 计算当日训练消耗的热量
          final dayWorkouts = _workoutCache[dateKey] ?? [];
          final completedWorkouts = dayWorkouts.where((w) => w.isCompleted);
          final caloriesBurned = completedWorkouts.fold(0, (sum, workout) {
            return sum + (workout.sets * 30); // 简化计算
          });
          
          result[dateKey] = DailyNutritionEntry(
            date: meals.first.timestamp,
            calorieIntake: totalCalories,
            caloriesBurned: caloriesBurned,
            calorieGoal: _calorieGoal,
            meals: meals,
          );
        }
      }
    } else {
      // 返回指定天数的数据
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      for (final entry in _mealCache.entries) {
        final dateKey = entry.key;
        final meals = entry.value.where((meal) => meal.timestamp.isAfter(cutoffDate)).toList();
        
        if (meals.isNotEmpty) {
          final totalCalories = meals.fold(0, (sum, meal) => sum + meal.calories);
          
          // 计算当日训练消耗的热量
          final dayWorkouts = _workoutCache[dateKey] ?? [];
          final completedWorkouts = dayWorkouts.where((w) => w.isCompleted);
          final caloriesBurned = completedWorkouts.fold(0, (sum, workout) {
            return sum + (workout.sets * 30);
          });
          
          result[dateKey] = DailyNutritionEntry(
            date: meals.first.timestamp,
            calorieIntake: totalCalories,
            caloriesBurned: caloriesBurned,
            calorieGoal: _calorieGoal,
            meals: meals,
          );
        }
      }
    }
    
    return result;
  }

  /// 兼容性方法：重新加载文章（空实现）
  Future<void> reloadArticles() async {
    // 空实现，文章通过 ArticleService 管理
  }

  // === 数据迁移和初始化方法 ===

  /// 从旧系统迁移数据到数据库
  Future<void> migrateOldData() async {
    if (_currentUser == null) return;

    // 这里可以实现从SharedPreferences迁移到SQLite的逻辑
    // 目前暂时留空，如果需要可以后续实现
    debugPrint('DataManager: 数据迁移功能待实现');
  }

  /// 创建示例数据（用于新用户）
  Future<void> createSampleData() async {
    if (_currentUser == null) return;

    try {
      final now = DateTime.now();
      
      // 创建一些示例体重数据
      for (int i = 30; i >= 0; i--) {
        final date = now.subtract(Duration(days: i));
        final weight = 70.0 + (i * 0.1) + (i % 3) * 0.2; // 模拟体重变化
        
        await addWeight(WeightEntry(
          date: date,
          value: weight,
        ));
      }

      // 创建今日训练计划
      final todayWorkouts = [
        WorkoutEntry(
          date: now,
          name: 'Push-up',
          sets: 3,
          isCompleted: false,
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

      for (final workout in todayWorkouts) {
        await addWorkout(workout);
      }

      debugPrint('DataManager: 示例数据创建完成');
    } catch (e) {
      debugPrint('DataManager: 创建示例数据失败: $e');
    }
  }

  /// 强制刷新今日数据（用于解决"No Data"问题）
  Future<void> refreshTodayData() async {
    if (_currentUser == null) return;

    final today = DateTime.now();
    
    try {
      // 强制刷新今日训练数据
      await getWorkoutsForDate(today);
      
      // 强制刷新今日饮食数据
      await getMealsForDate(today);
      
      debugPrint('DataManager: 今日数据刷新完成');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 刷新今日数据失败: $e');
    }
  }

  /// 获取数据摘要（用于调试）
  void printDataSummary() {
    debugPrint('=== DataManager 数据摘要 ===');
    debugPrint('当前用户: ${_currentUser?.name ?? "未登录"}');
    debugPrint('体重记录数: ${_weightCache.length}');
    debugPrint('体脂率记录数: ${_bodyFatCache.length}');
    debugPrint('训练记录数: ${_workoutCache.length}');
    debugPrint('饮食记录数: ${_mealCache.length}');
    debugPrint('热量目标: $_calorieGoal');
    debugPrint('今日热量摄入: ${calorieIntake}');
    debugPrint('今日热量消耗: ${caloriesBurned}');
    debugPrint('今日训练完成率: ${workoutCompletionPercent.toStringAsFixed(1)}%');
    debugPrint('=======================');
  }

  // 日期格式化辅助方法
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 加载用户设置
  Future<void> _loadUserSettings() async {
    if (_currentUser == null) return;

    try {
      final settings = await _dbService.getAllUserSettings(_currentUser!.id!);
      
      // 加载热量目标
      final calorieGoalStr = settings['calorie_goal'];
      if (calorieGoalStr != null) {
        _calorieGoal = int.tryParse(calorieGoalStr) ?? 2000;
      }
      
      // 加载每日热量摄入记录
      _dailyCalorieIntake.clear();
      _dailyCaloriesBurned.clear();
      
      for (final entry in settings.entries) {
        if (entry.key.startsWith('calorie_intake_')) {
          final dateKey = entry.key.substring('calorie_intake_'.length);
          _dailyCalorieIntake[dateKey] = int.tryParse(entry.value) ?? 0;
        } else if (entry.key.startsWith('calories_burned_')) {
          final dateKey = entry.key.substring('calories_burned_'.length);
          _dailyCaloriesBurned[dateKey] = int.tryParse(entry.value) ?? 0;
        }
      }
      
      debugPrint('DataManager: 用户设置加载完成');
    } catch (e) {
      debugPrint('DataManager: 加载用户设置失败: $e');
    }
  }

  // 预加载用户数据
  Future<void> _preloadUserData() async {
    if (_currentUser == null) return;

    try {
      debugPrint('DataManager: 开始预加载用户数据...');
      
      // 预加载体重数据
      await getWeightEntries();
      
      // 预加载体脂率数据
      await getBodyFatEntries();
      
      // 预加载最近7天的训练数据
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        await getWorkoutsForDate(date);
      }
      
      // 预加载最近7天的饮食数据
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        await getMealsForDate(date);
      }
      
      debugPrint('DataManager: 用户数据预加载完成');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 预加载用户数据失败: $e');
    }
  }

  /// 初始化方法 - 兼容旧版本
  Future<void> init() async {
    await initialize();
    debugPrint('DataManager: 已初始化');
  }

  /// 清除用户数据方法 - 兼容导出服务
  Future<void> clearUserData() async {
    if (_currentUser == null) return;
    
    try {
      // 清除数据库中的用户数据
      await _dbService.clearUserData(_currentUser!.id!);
      
      // 清除缓存
      _weightCache.clear();
      _workoutCache.clear();
      _mealCache.clear();
      
      debugPrint('DataManager: 用户数据已清除');
      notifyListeners();
    } catch (e) {
      debugPrint('DataManager: 清除用户数据失败: $e');
    }
  }

  /// 兼容性方法：添加体重记录（支持原有的 double + date 参数格式）
  Future<void> addWeightValue(double weight, {DateTime? date}) async {
    if (_currentUser == null) return;
    
    final entry = WeightEntry(
      value: weight,
      date: date ?? DateTime.now(),
    );
    
    await addWeight(entry);
  }

  /// 兼容性方法：添加体脂记录
  Future<void> addBodyFatValue(double bodyFat, {DateTime? date}) async {
    if (_currentUser == null) return;
    
    final entry = BodyFatEntry(
      value: bodyFat,
      date: date ?? DateTime.now(),
    );
    
    await addBodyFatEntry(entry);
  }

  /// 兼容性方法：添加训练记录
  Future<void> addWorkoutData(String type, int duration, int calories, {DateTime? date}) async {
    if (_currentUser == null) return;
    
    final entry = WorkoutEntry(
      name: type,
      sets: duration, // 将 duration 映射到 sets
      date: date ?? DateTime.now(),
      isCompleted: true,
    );
    
    await addWorkout(entry);
  }

  /// 兼容性方法：添加饮食记录
  Future<void> addMealData(String type, String food, int calories, {DateTime? date}) async {
    if (_currentUser == null) return;
    
    final entry = MealEntry(
      mealType: type,
      name: food,
      calories: calories,
      amount: '1份',
      timestamp: date ?? DateTime.now(),
    );
    
    await addMeal(entry);
  }
}
