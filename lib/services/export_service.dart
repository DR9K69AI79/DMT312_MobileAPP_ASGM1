import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'data_manager.dart';

/// 数据导入导出服务
class ExportService {
  static const String _exportFileName = 'fitness_app_backup.json';

  /// 检查并请求存储权限
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        final result = await Permission.storage.request();
        return result == PermissionStatus.granted;
      }
      return true;
    }
    return true; // iOS 不需要特殊权限
  }
  /// 导出所有数据到文件
  Future<String> exportData() async {
    final dataManager = DataManager();
    
    // 准备导出的数据
    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'data': {
        'weights': dataManager.weights7d.map((e) => e.toJson()).toList(),
        'workouts': dataManager.workoutToday.map((e) => e.toJson()).toList(),
        'articles': dataManager.articles.map((e) => e.toJson()).toList(),
        'nutrition': dataManager.nutritionEntries.map((e) => e.toJson()).toList(),
        'userSettings': {
          'calorieIntake': dataManager.calorieIntake,
          'caloriesBurned': dataManager.caloriesBurned,
          'calorieGoal': dataManager.calorieGoal,
          'height': dataManager.height,
          'currentWeight': dataManager.currentWeight,
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
      await dataManager.clearAllData();

      // 导入体重数据
      if (data['weights'] != null) {
        final weightsList = data['weights'] as List;
        for (final weightJson in weightsList) {
          final weight = weightJson['value']?.toDouble() ?? 0.0;
          await dataManager.addWeight(weight);
        }
      }

      // 导入训练数据
      if (data['workouts'] != null) {
        final workoutsList = data['workouts'] as List;
        for (final workoutJson in workoutsList) {
          final name = workoutJson['name'] as String? ?? '';
          final sets = workoutJson['sets'] as int? ?? 0;
          await dataManager.addWorkout(name, sets);
        }
      }

      // 导入营养数据
      if (data['nutrition'] != null) {
        final nutritionList = data['nutrition'] as List;
        for (final nutritionJson in nutritionList) {
          // 这里需要根据实际的NutritionEntry结构来实现
          // 暂时跳过，因为还没有相关的添加方法
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
      };
    } catch (e) {
      return null;
    }
  }
}
