import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/weight_entry.dart';
import '../models/workout_entry.dart';
import '../models/nutrition_entry.dart';
import '../models/body_fat_entry.dart';

// 根据平台选择合适的 SQLite 实现
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseService {
  // 单例模式
  static final DatabaseService instance = DatabaseService._internal();
  Database? _db;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDatabase();
    return _db!;
  }

  // 平台适配的初始化数据库
  Future<Database> initDatabase() async {
    // 根据平台初始化数据库工厂
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // 桌面平台使用 FFI
      databaseFactory = databaseFactoryFfi;
      debugPrint('DatabaseService: 使用桌面模式 (SQLite FFI)');
    } else if (!kIsWeb) {
      // 移动端使用默认的 sqflite
      debugPrint('DatabaseService: 使用移动端模式 (SQLite)');
    } else {
      // Web 平台暂不支持
      throw UnsupportedError('Web 平台暂不支持 SQLite 数据库');
    }

    return await _initSQLiteDatabase();
  }

  // SQLite 数据库初始化
  Future<Database> _initSQLiteDatabase() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = join(docsDir.path, 'fitness_app.db');

    return openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // 创建用户表
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            height REAL,
            created_at TEXT
          )
        ''');

        // 创建体重记录表
        await db.execute('''
          CREATE TABLE weights (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            date TEXT NOT NULL,
            value REAL NOT NULL,
            created_at TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
          )
        ''');

        // 创建训练记录表
        await db.execute('''
          CREATE TABLE workouts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            date TEXT NOT NULL,
            name TEXT NOT NULL,
            sets INTEGER NOT NULL,
            is_completed INTEGER NOT NULL DEFAULT 0,
            created_at TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
          )
        ''');

        // 创建饮食记录表
        await db.execute('''
          CREATE TABLE nutrition (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            date TEXT NOT NULL,
            meal_type TEXT NOT NULL,
            name TEXT NOT NULL,
            calories INTEGER NOT NULL,
            amount TEXT,
            created_at TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
          )
        ''');

        // 创建体脂率记录表
        await db.execute('''
          CREATE TABLE body_fat (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            date TEXT NOT NULL,
            percentage REAL NOT NULL,
            created_at TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id)
          )
        ''');

        // 创建用户设置表
        await db.execute('''
          CREATE TABLE user_settings (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            setting_key TEXT NOT NULL,
            setting_value TEXT NOT NULL,
            updated_at TEXT,
            FOREIGN KEY(user_id) REFERENCES users(id),
            UNIQUE(user_id, setting_key)
          )
        ''');

        // 创建音视频记录表
        await db.execute('''
          CREATE TABLE media (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            type TEXT NOT NULL,
            path TEXT NOT NULL,
            description TEXT,
            created_at TEXT
          )
        ''');
      },
    );
  }

  // === 用户相关操作 ===

  /// 创建新用户
  Future<int> createUser(User user) async {
    final db = await database;
    try {
      return await db.insert('users', user.toMap());
    } catch (e) {
      throw Exception('创建用户失败: $e');
    }
  }

  /// 根据邮箱和密码获取用户
  Future<User?> getUser(String email, String password) async {
    final db = await database;
    try {
      final results = await db.query(
        'users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
      );

      if (results.isNotEmpty) {
        return User.fromMap(results.first);
      }
      return null;
    } catch (e) {
      throw Exception('获取用户失败: $e');
    }
  }

  /// 根据ID获取用户
  Future<User?> getUserById(int id) async {
    final db = await database;
    try {
      final results = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      return results.isNotEmpty ? User.fromMap(results.first) : null;
    } catch (e) {
      throw Exception('获取用户失败: $e');
    }
  }

  /// 更新用户信息
  Future<int> updateUser(User user) async {
    final db = await database;
    try {
      return await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      throw Exception('更新用户失败: $e');
    }
  }

  /// 检查邮箱是否已存在
  Future<bool> isEmailExists(String email) async {
    final db = await database;
    try {
      final results = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );
      return results.isNotEmpty;
    } catch (e) {
      throw Exception('检查邮箱失败: $e');
    }
  }

  // === 体重记录相关操作 ===

  /// 添加体重记录
  Future<int> addWeight(WeightEntry entry, int userId) async {
    final db = await database;
    try {
      final map = entry.toJson();
      map['user_id'] = userId;
      map['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('weights', map);
    } catch (e) {
      throw Exception('添加体重记录失败: $e');
    }
  }

  /// 获取用户的体重记录
  Future<List<WeightEntry>> getWeights(int userId) async {
    final db = await database;
    try {
      final results = await db.query(
        'weights',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );

      return results.map((map) => WeightEntry.fromJson(map)).toList();
    } catch (e) {
      throw Exception('获取体重记录失败: $e');
    }
  }

  /// 删除体重记录
  Future<int> deleteWeight(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'weights',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('删除体重记录失败: $e');
    }
  }

  /// 更新体重记录
  Future<int> updateWeight(WeightEntry entry, int userId) async {
    final db = await database;
    try {
      final map = entry.toJson();
      map['user_id'] = userId;
      return await db.update(
        'weights',
        map,
        where: 'id = ?',
        whereArgs: [map['id']],
      );
    } catch (e) {
      throw Exception('更新体重记录失败: $e');
    }
  }

  // === 训练记录相关操作 ===

  /// 添加训练记录
  Future<int> addWorkout(WorkoutEntry entry, int userId) async {
    final db = await database;
    try {
      final map = entry.toJson();
      map['user_id'] = userId;
      map['created_at'] = DateTime.now().toIso8601String();
      map['is_completed'] = entry.isCompleted ? 1 : 0;
      return await db.insert('workouts', map);
    } catch (e) {
      throw Exception('添加训练记录失败: $e');
    }
  }

  /// 获取用户的训练记录
  Future<List<WorkoutEntry>> getWorkouts(int userId) async {
    final db = await database;
    try {
      final results = await db.query(
        'workouts',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );

      return results.map((map) {
        final workoutMap = Map<String, dynamic>.from(map);
        workoutMap['isCompleted'] = (map['is_completed'] as int) == 1;
        return WorkoutEntry.fromJson(workoutMap);
      }).toList();
    } catch (e) {
      throw Exception('获取训练记录失败: $e');
    }
  }

  /// 根据日期获取训练记录
  Future<List<WorkoutEntry>> getWorkoutsByDate(int userId, String date) async {
    final db = await database;
    try {
      final results = await db.query(
        'workouts',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, date],
      );

      return results.map((map) {
        final workoutMap = Map<String, dynamic>.from(map);
        workoutMap['isCompleted'] = (map['is_completed'] as int) == 1;
        return WorkoutEntry.fromJson(workoutMap);
      }).toList();
    } catch (e) {
      throw Exception('获取训练记录失败: $e');
    }
  }

  /// 更新训练记录
  Future<int> updateWorkout(WorkoutEntry entry, int userId) async {
    final db = await database;
    try {
      final map = entry.toJson();
      map['user_id'] = userId;
      map['is_completed'] = entry.isCompleted ? 1 : 0;
      return await db.update(
        'workouts',
        map,
        where: 'id = ?',
        whereArgs: [map['id']],
      );
    } catch (e) {
      throw Exception('更新训练记录失败: $e');
    }
  }

  /// 删除训练记录
  Future<int> deleteWorkout(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'workouts',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('删除训练记录失败: $e');
    }
  }

  // === 饮食记录相关操作 ===

  /// 添加饮食记录
  Future<int> addMeal(MealEntry entry, int userId) async {
    final db = await database;
    try {
      final map = entry.toJson();
      map['user_id'] = userId;
      map['created_at'] = DateTime.now().toIso8601String();
      return await db.insert('nutrition', map);
    } catch (e) {
      throw Exception('添加饮食记录失败: $e');
    }
  }

  /// 获取用户的饮食记录
  Future<List<MealEntry>> getMeals(int userId) async {
    final db = await database;
    try {
      final results = await db.query(
        'nutrition',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );

      return results.map((map) => MealEntry.fromJson(map)).toList();
    } catch (e) {
      throw Exception('获取饮食记录失败: $e');
    }
  }

  /// 根据日期获取饮食记录
  Future<List<MealEntry>> getMealsByDate(int userId, String date) async {
    final db = await database;
    try {
      final results = await db.query(
        'nutrition',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, date],
      );

      return results.map((map) => MealEntry.fromJson(map)).toList();
    } catch (e) {
      throw Exception('获取饮食记录失败: $e');
    }
  }

  /// 删除饮食记录
  Future<int> deleteMeal(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'nutrition',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('删除饮食记录失败: $e');
    }
  }

  // === 体脂率记录相关操作 ===

  /// 添加体脂率记录
  Future<int> addBodyFat(BodyFatEntry entry, int userId) async {
    final db = await database;
    try {
      final data = entry.toMap();
      data['user_id'] = userId;
      return await db.insert('body_fat', data);
    } catch (e) {
      throw Exception('添加体脂率记录失败: $e');
    }
  }

  /// 获取用户的所有体脂率记录
  Future<List<BodyFatEntry>> getBodyFats(int userId) async {
    final db = await database;
    try {
      final results = await db.query(
        'body_fat',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'date DESC',
      );
      return results.map((map) => BodyFatEntry.fromMap(map)).toList();
    } catch (e) {
      throw Exception('获取体脂率记录失败: $e');
    }
  }

  /// 根据日期获取体脂率记录
  Future<List<BodyFatEntry>> getBodyFatsByDate(int userId, String date) async {
    final db = await database;
    try {
      final results = await db.query(
        'body_fat',
        where: 'user_id = ? AND date = ?',
        whereArgs: [userId, date],
        orderBy: 'created_at DESC',
      );
      return results.map((map) => BodyFatEntry.fromMap(map)).toList();
    } catch (e) {
      throw Exception('获取体脂率记录失败: $e');
    }
  }

  /// 更新体脂率记录
  Future<int> updateBodyFat(BodyFatEntry entry, int userId) async {
    final db = await database;
    try {
      final data = entry.toMap();
      data['user_id'] = userId;
      return await db.update(
        'body_fat',
        data,
        where: 'id = ? AND user_id = ?',
        whereArgs: [entry.id, userId],
      );
    } catch (e) {
      throw Exception('更新体脂率记录失败: $e');
    }
  }

  /// 删除体脂率记录
  Future<int> deleteBodyFat(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'body_fat',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('删除体脂率记录失败: $e');
    }
  }

  // === 用户设置相关操作 ===

  /// 设置用户配置
  Future<void> setUserSetting(int userId, String key, String value) async {
    final db = await database;
    try {
      await db.insert(
        'user_settings',
        {
          'user_id': userId,
          'setting_key': key,
          'setting_value': value,
          'updated_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw Exception('设置用户配置失败: $e');
    }
  }

  /// 获取用户配置
  Future<String?> getUserSetting(int userId, String key) async {
    final db = await database;
    try {
      final results = await db.query(
        'user_settings',
        columns: ['setting_value'],
        where: 'user_id = ? AND setting_key = ?',
        whereArgs: [userId, key],
      );
      return results.isNotEmpty ? results.first['setting_value'] as String : null;
    } catch (e) {
      throw Exception('获取用户配置失败: $e');
    }
  }

  /// 获取用户所有配置
  Future<Map<String, String>> getAllUserSettings(int userId) async {
    final db = await database;
    try {
      final results = await db.query(
        'user_settings',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      
      final settings = <String, String>{};
      for (final row in results) {
        settings[row['setting_key'] as String] = row['setting_value'] as String;
      }
      return settings;
    } catch (e) {
      throw Exception('获取用户配置失败: $e');
    }
  }

  // === 媒体文件相关操作 ===

  /// 添加媒体记录
  Future<int> addMedia(String title, String type, String path, {String? description}) async {
    final db = await database;
    try {
      return await db.insert('media', {
        'title': title,
        'type': type,
        'path': path,
        'description': description,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('添加媒体记录失败: $e');
    }
  }

  /// 获取所有媒体记录
  Future<List<Map<String, dynamic>>> getMedia() async {
    final db = await database;
    try {
      return await db.query('media', orderBy: 'created_at DESC');
    } catch (e) {
      throw Exception('获取媒体记录失败: $e');
    }
  }

  /// 根据类型获取媒体记录
  Future<List<Map<String, dynamic>>> getMediaByType(String type) async {
    final db = await database;
    try {
      return await db.query(
        'media',
        where: 'type = ?',
        whereArgs: [type],
        orderBy: 'created_at DESC',
      );
    } catch (e) {
      throw Exception('获取媒体记录失败: $e');
    }
  }

  // === 数据库维护 ===

  /// 关闭数据库连接
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }

  /// 清空所有用户数据
  Future<void> clearUserData(int userId) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        await txn.delete('weights', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('workouts', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('nutrition', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('body_fat', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('user_settings', where: 'user_id = ?', whereArgs: [userId]);
      });
    } catch (e) {
      throw Exception('清空用户数据失败: $e');
    }
  }

  /// 删除用户及其所有数据
  Future<void> deleteUser(int userId) async {
    final db = await database;
    try {
      await db.transaction((txn) async {
        await txn.delete('weights', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('workouts', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('nutrition', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('body_fat', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('user_settings', where: 'user_id = ?', whereArgs: [userId]);
        await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
      });
    } catch (e) {
      throw Exception('删除用户失败: $e');
    }
  }
}
