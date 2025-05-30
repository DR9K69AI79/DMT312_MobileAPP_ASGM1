# 健身助手应用数据持久化架构改造指导文档

## 1. 项目概述

### 1.1 当前状态分析
目前健身助手应用采用内存数据存储，所有数据保存在 `MockData` 单例类中。应用关闭后数据会丢失，无法满足用户长期使用的需求。

### 1.2 改造目标
- 实现数据持久化存储，支持离线使用
- 采用可读性强的JSON格式存储，便于数据导出和调试
- 保持现有架构和用户界面不变
- 提供数据导入导出功能
- 确保数据一致性和完整性

### 1.3 技术选型
- **主要存储方案**: `shared_preferences` + JSON文件存储
- **备用存储方案**: SQLite (通过 `sqflite` 包)
- **数据格式**: JSON (具备良好的可读性和可移植性)
- **文件管理**: `path_provider` 获取应用文档目录

## 2. 新增依赖包

### 2.1 pubspec.yaml 新增依赖
```yaml
dependencies:
  flutter:
    sdk: flutter
  fl_chart: ^1.0.0
  # 新增的数据持久化相关依赖
  shared_preferences: ^2.2.2      # 简单键值对存储
  path_provider: ^2.1.1           # 获取文件系统路径
  permission_handler: ^11.0.1     # 处理文件权限（用于导入导出）

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  # 新增的开发时依赖
  json_serializable: ^6.7.1       # JSON序列化代码生成
  build_runner: ^2.4.7            # 代码生成工具
```

## 3. 新增文件结构

### 3.1 目录结构变更
```
lib/
├── main.dart
├── mock_data.dart              # 重构为 data_manager.dart
├── theme.dart
│
├── models/                     # 数据模型类（需要增加序列化支持）
│   ├── article.dart
│   ├── weight_entry.dart
│   ├── workout_entry.dart
│   └── nutrition_entry.dart    # 新增：餐食数据模型
│
├── screens/                    # 页面文件（无需修改）
│   ├── dashboard_screen.dart
│   ├── body_screen.dart
│   ├── workout_screen.dart
│   ├── nutrition_screen.dart
│   └── library_screen.dart
│
├── widgets/                    # UI组件（无需修改）
│   ├── glass_card.dart
│   ├── weight_line_chart.dart
│   ├── ring_progress.dart
│   └── primary_button.dart
│
├── services/                   # 新增：服务层
│   ├── storage_service.dart    # 数据存储服务
│   ├── data_manager.dart       # 数据管理器（替代mock_data.dart）
│   └── export_service.dart     # 数据导入导出服务
│
└── utils/                      # 新增：工具类
    ├── json_utils.dart         # JSON处理工具
    └── file_utils.dart         # 文件操作工具
```

## 4. 数据模型重构

### 4.1 基础数据模型接口
需要为所有数据模型添加JSON序列化支持：

```dart
// lib/models/base_model.dart
abstract class BaseModel {
  Map<String, dynamic> toJson();
  
  // 每个模型需要实现自己的fromJson构造函数
  // T fromJson(Map<String, dynamic> json);
}
```

### 4.2 WeightEntry 模型扩展
```dart
// lib/models/weight_entry.dart
import 'package:json_annotation/json_annotation.dart';
import 'base_model.dart';

part 'weight_entry.g.dart';

@JsonSerializable()
class WeightEntry implements BaseModel {
  final DateTime date;
  final double value;
  final String? note;  // 新增：备注字段

  WeightEntry({
    required this.date,
    required this.value,
    this.note,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) => 
      _$WeightEntryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$WeightEntryToJson(this);

  WeightEntry copyWith({
    DateTime? date,
    double? value,
    String? note,
  }) {
    return WeightEntry(
      date: date ?? this.date,
      value: value ?? this.value,
      note: note ?? this.note,
    );
  }
}
```

### 4.3 WorkoutEntry 模型扩展
```dart
// lib/models/workout_entry.dart
import 'package:json_annotation/json_annotation.dart';
import 'base_model.dart';

part 'workout_entry.g.dart';

@JsonSerializable()
class WorkoutEntry implements BaseModel {
  final DateTime date;
  final String name;
  final int sets;
  final bool isCompleted;
  final int? reps;           // 新增：每组次数
  final double? weight;      // 新增：使用重量
  final String? note;        // 新增：备注

  WorkoutEntry({
    required this.date,
    required this.name,
    required this.sets,
    this.isCompleted = false,
    this.reps,
    this.weight,
    this.note,
  });

  factory WorkoutEntry.fromJson(Map<String, dynamic> json) => 
      _$WorkoutEntryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$WorkoutEntryToJson(this);

  WorkoutEntry copyWith({
    DateTime? date,
    String? name,
    int? sets,
    bool? isCompleted,
    int? reps,
    double? weight,
    String? note,
  }) {
    return WorkoutEntry(
      date: date ?? this.date,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      isCompleted: isCompleted ?? this.isCompleted,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      note: note ?? this.note,
    );
  }
}
```

### 4.4 新增 NutritionEntry 模型
```dart
// lib/models/nutrition_entry.dart
import 'package:json_annotation/json_annotation.dart';
import 'base_model.dart';

part 'nutrition_entry.g.dart';

@JsonSerializable()
class FoodItem implements BaseModel {
  final String name;
  final int calories;
  final String amount;
  final double? protein;    // 蛋白质(g)
  final double? fat;        // 脂肪(g)
  final double? carbs;      // 碳水化合物(g)

  FoodItem({
    required this.name,
    required this.calories,
    required this.amount,
    this.protein,
    this.fat,
    this.carbs,
  });

  factory FoodItem.fromJson(Map<String, dynamic> json) => 
      _$FoodItemFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$FoodItemToJson(this);
}

@JsonSerializable()
class NutritionEntry implements BaseModel {
  final DateTime date;
  final Map<String, List<FoodItem>> meals;  // 餐次名称 -> 食物列表
  final int totalCalories;
  final int targetCalories;

  NutritionEntry({
    required this.date,
    required this.meals,
    required this.totalCalories,
    required this.targetCalories,
  });

  factory NutritionEntry.fromJson(Map<String, dynamic> json) => 
      _$NutritionEntryFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$NutritionEntryToJson(this);

  NutritionEntry copyWith({
    DateTime? date,
    Map<String, List<FoodItem>>? meals,
    int? totalCalories,
    int? targetCalories,
  }) {
    return NutritionEntry(
      date: date ?? this.date,
      meals: meals ?? this.meals,
      totalCalories: totalCalories ?? this.totalCalories,
      targetCalories: targetCalories ?? this.targetCalories,
    );
  }
}
```

### 4.5 Article 模型扩展
```dart
// lib/models/article.dart
import 'package:json_annotation/json_annotation.dart';
import 'base_model.dart';

part 'article.g.dart';

@JsonSerializable()
class Article implements BaseModel {
  final String title;
  final String coverUrl;
  final String mdPath;
  final String category;
  final bool isFavorite;      // 新增：收藏状态
  final DateTime? readAt;     // 新增：最后阅读时间

  Article({
    required this.title,
    required this.coverUrl,
    required this.mdPath,
    required this.category,
    this.isFavorite = false,
    this.readAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) => 
      _$ArticleFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$ArticleToJson(this);

  Article copyWith({
    String? title,
    String? coverUrl,
    String? mdPath,
    String? category,
    bool? isFavorite,
    DateTime? readAt,
  }) {
    return Article(
      title: title ?? this.title,
      coverUrl: coverUrl ?? this.coverUrl,
      mdPath: mdPath ?? this.mdPath,
      category: category ?? this.category,
      isFavorite: isFavorite ?? this.isFavorite,
      readAt: readAt ?? this.readAt,
    );
  }
}
```

## 5. 数据存储服务架构

### 5.1 StorageService 基础接口
```dart
// lib/services/storage_service.dart
abstract class StorageService {
  Future<void> init();
  Future<void> saveData(String key, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> loadData(String key);
  Future<void> deleteData(String key);
  Future<void> clearAll();
  Future<bool> hasData(String key);
}
```

### 5.2 LocalStorageService 实现
```dart
// lib/services/local_storage_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'storage_service.dart';

class LocalStorageService implements StorageService {
  static const String _dataFolderName = 'fitness_data';
  late Directory _dataDirectory;

  @override
  Future<void> init() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    _dataDirectory = Directory('${documentsDirectory.path}/$_dataFolderName');
    
    if (!await _dataDirectory.exists()) {
      await _dataDirectory.create(recursive: true);
    }
  }

  @override
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    final file = File('${_dataDirectory.path}/$key.json');
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString);
  }

  @override
  Future<Map<String, dynamic>?> loadData(String key) async {
    final file = File('${_dataDirectory.path}/$key.json');
    
    if (!await file.exists()) {
      return null;
    }
    
    try {
      final jsonString = await file.readAsString();
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error loading data for key $key: $e');
      return null;
    }
  }

  @override
  Future<void> deleteData(String key) async {
    final file = File('${_dataDirectory.path}/$key.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> clearAll() async {
    if (await _dataDirectory.exists()) {
      await _dataDirectory.delete(recursive: true);
      await _dataDirectory.create();
    }
  }

  @override
  Future<bool> hasData(String key) async {
    final file = File('${_dataDirectory.path}/$key.json');
    return await file.exists();
  }

  // 获取数据目录路径（用于导出功能）
  Future<String> getDataDirectoryPath() async {
    return _dataDirectory.path;
  }
}
```

### 5.3 DataManager 核心数据管理器
```dart
// lib/services/data_manager.dart
import 'package:flutter/foundation.dart';
import '../models/weight_entry.dart';
import '../models/workout_entry.dart';
import '../models/nutrition_entry.dart';
import '../models/article.dart';
import 'storage_service.dart';
import 'local_storage_service.dart';

class DataManager extends ChangeNotifier {
  static final DataManager _instance = DataManager._internal();
  factory DataManager() => _instance;
  DataManager._internal();

  late final StorageService _storageService;
  bool _isInitialized = false;

  // 数据存储键名常量
  static const String _weightsKey = 'weights';
  static const String _workoutsKey = 'workouts';
  static const String _nutritionKey = 'nutrition';
  static const String _articlesKey = 'articles';
  static const String _userProfileKey = 'user_profile';
  static const String _settingsKey = 'settings';

  // 当前数据（内存缓存）
  List<WeightEntry> _weights = [];
  List<WorkoutEntry> _workouts = [];
  List<NutritionEntry> _nutrition = [];
  List<Article> _articles = [];
  
  // 用户基础数据
  double _height = 175.0;
  double _currentWeight = 70.0;
  int _calorieGoal = 2000;
  
  // 当日热量数据
  int _calorieIntake = 0;
  int _caloriesBurned = 0;

  // Getters（保持与原MockData接口兼容）
  List<WeightEntry> get weights7d => _getRecentWeights(7);
  List<WorkoutEntry> get workoutToday => _getTodayWorkouts();
  List<Article> get articles => List.unmodifiable(_articles);
  double get height => _height;
  double get currentWeight => _currentWeight;
  int get calorieIntake => _calorieIntake;
  int get caloriesBurned => _caloriesBurned;
  int get calorieGoal => _calorieGoal;
  int get calorieBalance => _calorieIntake - _caloriesBurned;
  
  double get workoutCompletionPercent {
    final todayWorkouts = workoutToday;
    if (todayWorkouts.isEmpty) return 0.0;
    final completedCount = todayWorkouts.where((w) => w.isCompleted).length;
    return completedCount / todayWorkouts.length;
  }

  // 初始化方法
  Future<void> init() async {
    if (_isInitialized) return;
    
    _storageService = LocalStorageService();
    await _storageService.init();
    await _loadAllData();
    
    // 如果是首次启动，初始化默认数据
    if (_weights.isEmpty && _workouts.isEmpty && _nutrition.isEmpty) {
      await _initDefaultData();
    }
    
    _isInitialized = true;
  }

  // 加载所有数据
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadWeights(),
      _loadWorkouts(),
      _loadNutrition(),
      _loadArticles(),
      _loadUserProfile(),
    ]);
  }

  // 加载体重数据
  Future<void> _loadWeights() async {
    final data = await _storageService.loadData(_weightsKey);
    if (data != null && data['weights'] != null) {
      _weights = (data['weights'] as List)
          .map((item) => WeightEntry.fromJson(item))
          .toList();
      _weights.sort((a, b) => a.date.compareTo(b.date));
      
      if (_weights.isNotEmpty) {
        _currentWeight = _weights.last.value;
      }
    }
  }

  // 加载训练数据
  Future<void> _loadWorkouts() async {
    final data = await _storageService.loadData(_workoutsKey);
    if (data != null && data['workouts'] != null) {
      _workouts = (data['workouts'] as List)
          .map((item) => WorkoutEntry.fromJson(item))
          .toList();
      _workouts.sort((a, b) => b.date.compareTo(a.date));
    }
  }

  // 加载营养数据
  Future<void> _loadNutrition() async {
    final data = await _storageService.loadData(_nutritionKey);
    if (data != null && data['nutrition'] != null) {
      _nutrition = (data['nutrition'] as List)
          .map((item) => NutritionEntry.fromJson(item))
          .toList();
      _nutrition.sort((a, b) => b.date.compareTo(a.date));
      
      // 更新当日热量摄入
      _updateTodayCalorieIntake();
    }
  }

  // 加载文章数据
  Future<void> _loadArticles() async {
    final data = await _storageService.loadData(_articlesKey);
    if (data != null && data['articles'] != null) {
      _articles = (data['articles'] as List)
          .map((item) => Article.fromJson(item))
          .toList();
    } else {
      // 如果没有保存的文章数据，使用默认文章列表
      _initDefaultArticles();
    }
  }

  // 加载用户资料
  Future<void> _loadUserProfile() async {
    final data = await _storageService.loadData(_userProfileKey);
    if (data != null) {
      _height = data['height']?.toDouble() ?? 175.0;
      _calorieGoal = data['calorieGoal'] ?? 2000;
      _caloriesBurned = data['caloriesBurned'] ?? 0;
    }
  }

  // 保存方法
  Future<void> _saveWeights() async {
    final data = {
      'weights': _weights.map((w) => w.toJson()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await _storageService.saveData(_weightsKey, data);
  }

  Future<void> _saveWorkouts() async {
    final data = {
      'workouts': _workouts.map((w) => w.toJson()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await _storageService.saveData(_workoutsKey, data);
  }

  Future<void> _saveNutrition() async {
    final data = {
      'nutrition': _nutrition.map((n) => n.toJson()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await _storageService.saveData(_nutritionKey, data);
  }

  Future<void> _saveArticles() async {
    final data = {
      'articles': _articles.map((a) => a.toJson()).toList(),
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await _storageService.saveData(_articlesKey, data);
  }

  Future<void> _saveUserProfile() async {
    final data = {
      'height': _height,
      'calorieGoal': _calorieGoal,
      'caloriesBurned': _caloriesBurned,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    await _storageService.saveData(_userProfileKey, data);
  }

  // 公共数据操作方法（保持与原MockData兼容）
  Future<void> addWeight(double value) async {
    final entry = WeightEntry(
      date: DateTime.now(),
      value: value,
    );
    
    _weights.add(entry);
    _currentWeight = value;
    
    // 保持只有最近30天的数据
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    _weights.removeWhere((w) => w.date.isBefore(thirtyDaysAgo));
    
    await _saveWeights();
    notifyListeners();
  }

  Future<void> addWorkout(String name, int sets) async {
    final entry = WorkoutEntry(
      date: DateTime.now(),
      name: name,
      sets: sets,
    );
    
    _workouts.add(entry);
    await _saveWorkouts();
    notifyListeners();
  }

  Future<void> toggleWorkoutCompleted(int index) async {
    final todayWorkouts = workoutToday;
    if (index >= 0 && index < todayWorkouts.length) {
      final workout = todayWorkouts[index];
      final updatedWorkout = workout.copyWith(
        isCompleted: !workout.isCompleted,
      );
      
      // 找到在总列表中的索引并更新
      final globalIndex = _workouts.indexOf(workout);
      if (globalIndex != -1) {
        _workouts[globalIndex] = updatedWorkout;
        await _saveWorkouts();
        notifyListeners();
      }
    }
  }

  Future<void> updateCalorieIntake(int calories) async {
    _calorieIntake = calories;
    await _saveUserProfile();
    notifyListeners();
  }

  Future<void> updateCaloriesBurned(int calories) async {
    _caloriesBurned = calories;
    await _saveUserProfile();
    notifyListeners();
  }

  // 营养数据相关方法
  Future<void> addNutritionEntry(NutritionEntry entry) async {
    // 检查是否已有当日记录
    final today = DateTime.now();
    final existingIndex = _nutrition.indexWhere((n) => 
        n.date.year == today.year && 
        n.date.month == today.month && 
        n.date.day == today.day);
    
    if (existingIndex != -1) {
      _nutrition[existingIndex] = entry;
    } else {
      _nutrition.add(entry);
    }
    
    await _saveNutrition();
    _updateTodayCalorieIntake();
    notifyListeners();
  }

  Future<void> updateArticleFavorite(String title, bool isFavorite) async {
    final index = _articles.indexWhere((a) => a.title == title);
    if (index != -1) {
      _articles[index] = _articles[index].copyWith(isFavorite: isFavorite);
      await _saveArticles();
      notifyListeners();
    }
  }

  // 工具方法
  List<WeightEntry> _getRecentWeights(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _weights.where((w) => w.date.isAfter(cutoff)).toList();
  }

  List<WorkoutEntry> _getTodayWorkouts() {
    final today = DateTime.now();
    return _workouts.where((w) => 
        w.date.year == today.year && 
        w.date.month == today.month && 
        w.date.day == today.day).toList();
  }

  void _updateTodayCalorieIntake() {
    final today = DateTime.now();
    final todayNutrition = _nutrition.firstWhere(
      (n) => n.date.year == today.year && 
             n.date.month == today.month && 
             n.date.day == today.day,
      orElse: () => NutritionEntry(
        date: today,
        meals: {},
        totalCalories: 0,
        targetCalories: _calorieGoal,
      ),
    );
    _calorieIntake = todayNutrition.totalCalories;
  }

  // 初始化默认数据
  Future<void> _initDefaultData() async {
    await _initDefaultWeights();
    await _initDefaultWorkouts();
    await _initDefaultArticles();
  }

  Future<void> _initDefaultWeights() async {
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final randomWeight = 70.0 + (i % 3 - 1) * 0.5;
      _weights.add(WeightEntry(date: date, value: randomWeight));
    }
    _currentWeight = _weights.last.value;
    await _saveWeights();
  }

  Future<void> _initDefaultWorkouts() async {
    final now = DateTime.now();
    _workouts.addAll([
      WorkoutEntry(date: now, name: '俯卧撑', sets: 3, isCompleted: true),
      WorkoutEntry(date: now, name: '深蹲', sets: 4, isCompleted: false),
      WorkoutEntry(date: now, name: '平板支撑', sets: 3, isCompleted: false),
    ]);
    await _saveWorkouts();
  }

  void _initDefaultArticles() {
    _articles.addAll([
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
    ]);
  }
}
```

## 6. 数据导入导出服务

### 6.1 ExportService 实现
```dart
// lib/services/export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'data_manager.dart';

class ExportService {
  static const String _exportFileName = 'fitness_data_backup';

  // 导出所有数据到JSON文件
  static Future<String?> exportAllData() async {
    try {
      // 请求存储权限
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw Exception('需要存储权限才能导出数据');
      }

      final dataManager = DataManager();
      
      // 收集所有数据
      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'appVersion': '1.0.0',
        'data': {
          'weights': dataManager.weights7d.map((w) => w.toJson()).toList(),
          'workouts': dataManager.workoutToday.map((w) => w.toJson()).toList(),
          'articles': dataManager.articles.map((a) => a.toJson()).toList(),
          'userProfile': {
            'height': dataManager.height,
            'currentWeight': dataManager.currentWeight,
            'calorieGoal': dataManager.calorieGoal,
            'calorieIntake': dataManager.calorieIntake,
            'caloriesBurned': dataManager.caloriesBurned,
          },
        },
      };

      // 获取下载目录
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        throw Exception('无法访问外部存储');
      }

      final fileName = '${_exportFileName}_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${directory.path}/$fileName');
      
      // 格式化JSON并写入文件
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      await file.writeAsString(jsonString);
      
      return file.path;
    } catch (e) {
      print('导出数据失败: $e');
      return null;
    }
  }

  // 从JSON文件导入数据
  static Future<bool> importData(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      final jsonString = await file.readAsString();
      final data = json.decode(jsonString) as Map<String, dynamic>;
      
      // 验证数据格式
      if (!_validateImportData(data)) {
        throw Exception('数据格式不正确');
      }

      final dataManager = DataManager();
      
      // 清空现有数据（可选）
      // await dataManager.clearAllData();
      
      // 导入数据
      final importData = data['data'] as Map<String, dynamic>;
      
      // 导入体重数据
      if (importData['weights'] != null) {
        for (final weightData in importData['weights']) {
          final weight = WeightEntry.fromJson(weightData);
          await dataManager.addWeight(weight.value);
        }
      }
      
      // 导入训练数据
      if (importData['workouts'] != null) {
        for (final workoutData in importData['workouts']) {
          final workout = WorkoutEntry.fromJson(workoutData);
          await dataManager.addWorkout(workout.name, workout.sets);
        }
      }
      
      // 导入用户资料
      if (importData['userProfile'] != null) {
        final profile = importData['userProfile'];
        await dataManager.updateCalorieIntake(profile['calorieIntake'] ?? 0);
        await dataManager.updateCaloriesBurned(profile['caloriesBurned'] ?? 0);
      }
      
      return true;
    } catch (e) {
      print('导入数据失败: $e');
      return false;
    }
  }

  // 验证导入数据格式
  static bool _validateImportData(Map<String, dynamic> data) {
    return data.containsKey('data') && 
           data.containsKey('exportDate') &&
           data['data'] is Map<String, dynamic>;
  }
}
```

## 7. 页面层改造指导

### 7.1 主要修改点
所有Screen文件需要将 `MockData()` 替换为 `DataManager()`：

```dart
// 原代码
final MockData _mockData = MockData();

// 新代码  
final DataManager _dataManager = DataManager();
```

### 7.2 主应用入口修改
```dart
// lib/main.dart
import 'services/data_manager.dart';

class FitnessMiniApp extends StatelessWidget {
  const FitnessMiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: DataManager().init(),  // 初始化数据管理器
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('数据初始化失败: ${snapshot.error}'),
              ),
            ),
          );
        }
        
        return MaterialApp(
          title: '健身助手',
          theme: buildAppTheme(),
          home: const MainScreen(),
          routes: {
            '/workout': (context) => const WorkoutScreen(),
            '/nutrition': (context) => const NutritionScreen(),
            '/body': (context) => const BodyScreen(),
            '/library': (context) => const LibraryScreen(),
          },
        );
      },
    );
  }
}
```

### 7.3 NutritionScreen 餐食数据持久化
NutritionScreen 中的 `_meals` 数据需要整合到 DataManager 中：

```dart
// 在 DataManager 中添加餐食管理方法
Future<void> addFoodToMeal(String mealType, String foodName, int calories, String amount) async {
  final today = DateTime.now();
  
  // 获取或创建今日营养记录
  NutritionEntry todayEntry = _getTodayNutritionEntry();
  
  // 添加食物到指定餐次
  final updatedMeals = Map<String, List<FoodItem>>.from(todayEntry.meals);
  updatedMeals[mealType] ??= [];
  updatedMeals[mealType]!.add(FoodItem(
    name: foodName,
    calories: calories,
    amount: amount,
  ));
  
  // 重新计算总热量
  int totalCalories = 0;
  for (final foodList in updatedMeals.values) {
    totalCalories += foodList.fold(0, (sum, food) => sum + food.calories);
  }
  
  // 更新营养记录
  final updatedEntry = todayEntry.copyWith(
    meals: updatedMeals,
    totalCalories: totalCalories,
  );
  
  await addNutritionEntry(updatedEntry);
}

Future<void> removeFoodFromMeal(String mealType, int foodIndex) async {
  final todayEntry = _getTodayNutritionEntry();
  
  if (todayEntry.meals[mealType] != null && 
      foodIndex < todayEntry.meals[mealType]!.length) {
    final updatedMeals = Map<String, List<FoodItem>>.from(todayEntry.meals);
    updatedMeals[mealType]!.removeAt(foodIndex);
    
    // 重新计算总热量
    int totalCalories = 0;
    for (final foodList in updatedMeals.values) {
      totalCalories += foodList.fold(0, (sum, food) => sum + food.calories);
    }
    
    final updatedEntry = todayEntry.copyWith(
      meals: updatedMeals,
      totalCalories: totalCalories,
    );
    
    await addNutritionEntry(updatedEntry);
  }
}

NutritionEntry _getTodayNutritionEntry() {
  final today = DateTime.now();
  return _nutrition.firstWhere(
    (n) => n.date.year == today.year && 
           n.date.month == today.month && 
           n.date.day == today.day,
    orElse: () => NutritionEntry(
      date: today,
      meals: {'早餐': [], '午餐': [], '晚餐': []},
      totalCalories: 0,
      targetCalories: _calorieGoal,
    ),
  );
}

// 获取今日餐食数据的getter
Map<String, List<FoodItem>> get todayMeals => _getTodayNutritionEntry().meals;
```

## 8. 开发实施步骤

### 8.1 第一阶段：基础架构建立
1. 添加依赖包到 `pubspec.yaml`
2. 创建 `services/` 和 `utils/` 目录
3. 实现 `StorageService` 接口和 `LocalStorageService`
4. 为所有模型类添加JSON序列化支持
5. 运行代码生成: `flutter packages pub run build_runner build`

### 8.2 第二阶段：数据管理器迁移
1. 创建 `DataManager` 类，逐步迁移 `MockData` 功能
2. 实现数据加载和保存方法
3. 添加初始化和默认数据方法
4. 确保所有原有接口保持兼容

### 8.3 第三阶段：页面层集成
1. 修改 `main.dart` 添加数据初始化
2. 逐个页面替换 `MockData` 为 `DataManager`
3. 特别处理 `NutritionScreen` 的餐食数据持久化
4. 测试所有页面功能正常

### 8.4 第四阶段：导入导出功能
1. 实现 `ExportService`
2. 在设置页面添加导入导出按钮
3. 添加权限处理和错误提示
4. 测试数据导入导出功能

### 8.5 第五阶段：测试和优化
1. 全面测试数据持久化功能
2. 性能优化（异步加载、批量保存等）
3. 错误处理和恢复机制
4. 数据迁移和版本兼容性

## 9. 数据文件示例

### 9.1 weights.json 示例
```json
{
  "weights": [
    {
      "date": "2024-01-01T08:00:00.000Z",
      "value": 70.5,
      "note": "早晨空腹测量"
    },
    {
      "date": "2024-01-02T08:00:00.000Z", 
      "value": 70.3,
      "note": null
    }
  ],
  "lastUpdated": "2024-01-02T08:15:00.000Z"
}
```

### 9.2 nutrition.json 示例
```json
{
  "nutrition": [
    {
      "date": "2024-01-01T00:00:00.000Z",
      "meals": {
        "早餐": [
          {
            "name": "鸡蛋",
            "calories": 150,
            "amount": "2个",
            "protein": 12.0,
            "fat": 10.0,
            "carbs": 1.0
          }
        ],
        "午餐": [],
        "晚餐": []
      },
      "totalCalories": 150,
      "targetCalories": 2000
    }
  ],
  "lastUpdated": "2024-01-01T12:00:00.000Z"
}
```

## 10. 注意事项和最佳实践

### 10.1 数据一致性
- 所有数据修改操作都要通过 DataManager 进行
- 确保内存数据和持久化数据同步
- 在关键操作后立即保存数据

### 10.2 性能考虑
- 使用异步操作避免阻塞UI
- 合理控制数据量（如只保留最近30天体重数据）
- 考虑实现懒加载和分页

### 10.3 错误处理
- 文件读写操作要有完善的异常处理
- 数据格式验证防止损坏的数据
- 提供数据恢复机制

### 10.4 向后兼容
- 保持现有接口不变，确保UI层无需大量修改
- 数据模型扩展时要考虑兼容性
- 提供数据迁移方案

### 10.5 用户体验
- 首次启动时提供加载提示
- 数据导入导出操作要有明确的成功/失败反馈
- 考虑添加数据备份提醒功能

这个改造方案将为健身助手应用提供完整的数据持久化能力，同时保持良好的可读性和可维护性。JSON格式的存储便于用户理解和导出，满足了可读性要求。整个架构设计考虑了扩展性和兼容性，为后续功能开发打下良好基础。
