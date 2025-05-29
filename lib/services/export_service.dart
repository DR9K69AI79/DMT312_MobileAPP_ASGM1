import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'data_manager.dart';
import '../models/workout_entry.dart';
import '../models/nutrition_entry.dart';

/// 数据导入导出服务
class ExportService {  /// 导出数据到用户选择的位置
  Future<String?> exportDataWithFilePicker() async {
    final dataManager = DataManager();
    
    // 准备导出的数据（排除文章数据）
    final exportData = {
      'version': '2.0',
      'exportDate': DateTime.now().toIso8601String(),
      'data': {
        'weights': _convertWeightData(dataManager.getWeightData()),
        'bodyFat': _convertBodyFatData(dataManager.getBodyFatData()),
        'workouts': _convertWorkoutData(dataManager.getWorkoutData()),
        'nutrition': _convertNutritionData(dataManager.getNutritionData()),
        'userSettings': {
          'height': dataManager.height,
          'currentWeight': dataManager.currentWeight,
          'currentBodyFat': dataManager.currentBodyFat,
        }
      }
    };

    // 让用户选择保存位置
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: '选择保存位置',
      fileName: 'fitness_backup_${DateTime.now().millisecondsSinceEpoch}.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (outputFile == null) {
      // 用户取消了选择
      return null;
    }
    
    // 写入数据
    final file = File(outputFile);
    await file.writeAsString(jsonEncode(exportData));
    
    return file.path;
  }

  /// 导出所有数据到文件（兼容旧方法）
  Future<String> exportData() async {
    final dataManager = DataManager();
    
    // 准备导出的数据（排除文章数据）
    final exportData = {
      'version': '2.0',
      'exportDate': DateTime.now().toIso8601String(),
      'data': {
        'weights': _convertWeightData(dataManager.getWeightData()),
        'bodyFat': _convertBodyFatData(dataManager.getBodyFatData()),
        'workouts': _convertWorkoutData(dataManager.getWorkoutData()),
        'nutrition': _convertNutritionData(dataManager.getNutritionData()),
        'userSettings': {
          'height': dataManager.height,
          'currentWeight': dataManager.currentWeight,
          'currentBodyFat': dataManager.currentBodyFat,
        }
      }
    };

    // 获取导出目录
    Directory exportDir;
    if (Platform.isAndroid) {
      // Android: 使用外部存储的下载目录
      exportDir = Directory('/storage/emulated/0/Download');
      if (!await exportDir.exists()) {
        exportDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      }
    } else {
      // iOS: 使用应用文档目录
      exportDir = await getApplicationDocumentsDirectory();
    }

    // 创建导出文件
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'fitness_backup_$timestamp.json';
    final exportFile = File('${exportDir.path}/$fileName');
    
    // 写入数据
    await exportFile.writeAsString(jsonEncode(exportData));
    
    return exportFile.path;
  }

  /// 导出所有数据（为设置页面提供的方法）
  Future<String> exportAllData(DataManager dataManager) async {
    return await exportData();
  }
  /// 使用文件选择器导入数据
  Future<bool> importDataWithFilePicker() async {
    try {
      // 让用户选择要导入的文件
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择要导入的备份文件',
      );

      if (result == null || result.files.isEmpty) {
        // 用户取消了选择
        return false;
      }

      final file = result.files.first;
      if (file.path == null) {
        return false;
      }

      // 导入选择的文件
      return await importData(file.path!);
    } catch (e) {
      return false;
    }
  }
  /// 导入所有数据（为设置页面提供的方法，使用文件选择器）
  Future<void> importAllDataWithFilePicker(DataManager dataManager) async {
    final success = await importDataWithFilePicker();
    
    if (!success) {
      throw Exception('导入数据失败，请检查文件格式是否正确');
    }
  }

  /// 导入所有数据（为设置页面提供的方法）
  Future<void> importAllData(DataManager dataManager) async {
    // 获取可用的备份文件
    final backups = await getAvailableBackups();
    if (backups.isEmpty) {
      throw Exception('没有找到备份文件');
    }
    
    // 使用最新的备份文件
    final latestBackup = backups.first as File;
    final success = await importData(latestBackup.path);
    
    if (!success) {
      throw Exception('导入数据失败');
    }
  }

  /// 从文件导入数据
  Future<bool> importData(String filePath) async {
    try {
      final importFile = File(filePath);
      if (!await importFile.exists()) {
        throw FileSystemException('Import file not found', filePath);
      }

      // 读取文件内容
      final content = await importFile.readAsString();
      final importData = jsonDecode(content) as Map<String, dynamic>;

      // 验证数据格式
      if (!_validateImportData(importData)) {
        throw FormatException('Invalid backup file format');
      }

      final data = importData['data'] as Map<String, dynamic>;
      final dataManager = DataManager();

      // 清空现有数据
      await dataManager.clearAllData();      // 导入体重数据
      if (data['weights'] != null) {
        final weightsList = data['weights'] as List;
        for (final weightJson in weightsList) {
          final weight = weightJson['weight']?.toDouble() ?? 0.0;
          final dateStr = weightJson['date'] as String?;
          
          if (dateStr != null) {
            // 使用导入数据中的日期
            final date = DateTime.parse(dateStr);
            await dataManager.addWeight(weight, date: date);
          } else {
            // 如果没有日期信息，使用当前日期（向后兼容）
            await dataManager.addWeight(weight);
          }
        }
      }      // 导入体脂数据
      if (data['bodyFat'] != null) {
        final bodyFatList = data['bodyFat'] as List;
        for (final bodyFatJson in bodyFatList) {
          final bodyFatPercentage = bodyFatJson['bodyFatPercentage']?.toDouble();
          final dateStr = bodyFatJson['date'] as String?;
          
          if (bodyFatPercentage != null && dateStr != null) {
            // 使用导入数据中的日期
            final date = DateTime.parse(dateStr);
            await dataManager.addBodyFat(bodyFatPercentage, date: date);
          }
        }
      }// 导入训练数据
      if (data['workouts'] != null) {
        final workoutsMap = data['workouts'] as Map<String, dynamic>;
        for (final dateEntry in workoutsMap.entries) {
          final workoutsList = dateEntry.value as List;
          for (final workoutJson in workoutsList) {
            final name = workoutJson['name'] as String? ?? '';
            final sets = workoutJson['sets'] as int? ?? 0;
            final date = workoutJson['date'] != null 
                ? DateTime.parse(workoutJson['date'] as String)
                : DateTime.now();
            final isCompleted = workoutJson['isCompleted'] as bool? ?? false;
            
            final workout = WorkoutEntry(
              name: name,
              sets: sets,
              date: date,
              isCompleted: isCompleted,
            );
            await dataManager.addWorkout(workout);
          }
        }
      }      // 导入营养数据
      if (data['nutrition'] != null) {
        final nutritionList = data['nutrition'] as List;
        for (final nutritionJson in nutritionList) {
          final date = nutritionJson['date'] != null 
              ? DateTime.parse(nutritionJson['date'] as String)
              : DateTime.now();
          final calorieIntake = nutritionJson['calorieIntake'] as int? ?? 0;
          final caloriesBurned = nutritionJson['caloriesBurned'] as int? ?? 0;
          final calorieGoal = nutritionJson['calorieGoal'] as int? ?? 2000;
          
          // 设置基础热量数据
          await dataManager.updateCalorieIntake(calorieIntake, date: date);
          await dataManager.updateCaloriesBurned(caloriesBurned, date: date);
          await dataManager.updateCalorieGoal(calorieGoal, date: date);
          
          // 处理meals数据：从Python格式转换为应用格式
          if (nutritionJson['meals'] != null) {
            final mealsData = nutritionJson['meals'] as List;
            for (final mealData in mealsData) {
              final mealName = mealData['name'] as String? ?? '';
              final mealCalories = mealData['calories'] as int? ?? 0;
              final foods = mealData['foods'] as List<dynamic>? ?? [];
              
              // 将Python格式的meal转换为多个MealEntry
              // 如果有具体食物列表，为每个食物创建一个MealEntry
              if (foods.isNotEmpty) {
                final averageCalories = (mealCalories / foods.length).round();
                for (final food in foods) {
                  final meal = MealEntry(
                    mealType: mealName,
                    name: food.toString(),
                    calories: averageCalories,
                    amount: '1份',
                    timestamp: date,
                  );
                  await dataManager.addMeal(meal, date: date);
                }
              } else if (mealCalories > 0) {
                // 如果没有具体食物但有热量，创建一个通用的MealEntry
                final meal = MealEntry(
                  mealType: mealName,
                  name: '$mealName餐',
                  calories: mealCalories,
                  amount: '1份',
                  timestamp: date,
                );
                await dataManager.addMeal(meal, date: date);
              }
            }
          }
        }
      }

      // 导入用户设置
      if (data['userSettings'] != null) {
        final settings = data['userSettings'] as Map<String, dynamic>;
        
        if (settings['calorieIntake'] != null) {
          await dataManager.updateCalorieIntake(settings['calorieIntake'] as int);
        }
        if (settings['caloriesBurned'] != null) {
          await dataManager.updateCaloriesBurned(settings['caloriesBurned'] as int);
        }
        if (settings['calorieGoal'] != null) {
          await dataManager.updateCalorieGoal(settings['calorieGoal'] as int);
        }
        if (settings['height'] != null) {
          await dataManager.updateHeight((settings['height'] as num).toDouble());
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 验证导入数据的格式
  bool _validateImportData(Map<String, dynamic> data) {
    // 检查必要的字段
    if (!data.containsKey('version') || !data.containsKey('data')) {
      return false;
    }

    final dataSection = data['data'];
    if (dataSection is! Map<String, dynamic>) {
      return false;
    }

    return true;
  }

  /// 获取可用的备份文件列表
  Future<List<FileSystemEntity>> getAvailableBackups() async {
    try {
      Directory searchDir;
      if (Platform.isAndroid) {
        searchDir = Directory('/storage/emulated/0/Download');
        if (!await searchDir.exists()) {
          searchDir = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        }
      } else {
        searchDir = await getApplicationDocumentsDirectory();
      }

      if (!await searchDir.exists()) {
        return [];
      }

      final files = <FileSystemEntity>[];
      await for (final entity in searchDir.list()) {
        if (entity is File && entity.path.contains('fitness_backup_')) {
          files.add(entity);
        }
      }

      // 按修改时间排序（最新的在前）
      files.sort((a, b) {
        final aStat = (a as File).lastModifiedSync();
        final bStat = (b as File).lastModifiedSync();
        return bStat.compareTo(aStat);
      });

      return files;
    } catch (e) {
      return [];
    }
  }

  /// 删除指定的备份文件
  Future<bool> deleteBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// 获取备份文件信息
  Future<Map<String, dynamic>?> getBackupInfo(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return null;
      }

      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      
      final stat = await file.stat();
      final fileName = file.path.split('/').last;
      
      return {
        'fileName': fileName,
        'filePath': filePath,
        'fileSize': stat.size,
        'modifiedDate': stat.modified,
        'version': data['version'],
        'exportDate': data['exportDate'],
      };    } catch (e) {
      return null;
    }
  }
  /// 转换体重数据格式
  List<Map<String, dynamic>> _convertWeightData(Map<String, dynamic> weightData) {
    return weightData.entries.map((entry) {
      return {
        'date': entry.key,
        'weight': entry.value.value,
      };
    }).toList();
  }
  /// 转换体脂数据格式
  List<Map<String, dynamic>> _convertBodyFatData(Map<String, dynamic> bodyFatData) {
    return bodyFatData.entries.map((entry) {
      return {
        'date': entry.key,
        'bodyFatPercentage': entry.value.value,
      };
    }).toList();
  }

  /// 转换训练数据格式
  Map<String, dynamic> _convertWorkoutData(Map<String, List<dynamic>> workoutData) {
    final converted = <String, dynamic>{};
    for (final entry in workoutData.entries) {
      converted[entry.key] = entry.value.map((workout) => workout.toJson()).toList();
    }
    return converted;
  }
  /// 转换营养数据格式
  List<Map<String, dynamic>> _convertNutritionData(Map<String, dynamic> nutritionData) {
    return nutritionData.entries.map((entry) {
      final entryData = entry.value.toJson() as Map<String, dynamic>;
      return {
        'date': entry.key,
        ...entryData,
      };
    }).toList();
  }
}
