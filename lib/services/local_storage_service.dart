import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

/// 本地存储服务实现，使用SharedPreferences和文件系统
class LocalStorageService implements StorageService {
  late SharedPreferences _prefs;
  late Directory _appDir;
  bool _initialized = false;

  @override
  Future<void> init() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _appDir = await getApplicationDocumentsDirectory();
    _initialized = true;
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('LocalStorageService must be initialized before use');
    }
  }

  @override
  Future<void> saveString(String key, String value) async {
    _ensureInitialized();
    await _prefs.setString(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    _ensureInitialized();
    return _prefs.getString(key);
  }

  @override
  Future<void> saveJson(String key, Map<String, dynamic> json) async {
    _ensureInitialized();
    final jsonString = jsonEncode(json);
    await _prefs.setString(key, jsonString);
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    _ensureInitialized();
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveJsonList(String key, List<Map<String, dynamic>> jsonList) async {
    _ensureInitialized();
    final jsonString = jsonEncode(jsonList);
    
    // 对于大量数据，使用文件存储而不是SharedPreferences
    if (jsonString.length > 1024 * 100) { // 大于100KB时使用文件存储
      await _saveToFile(key, jsonString);
    } else {
      await _prefs.setString(key, jsonString);
    }
  }

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    _ensureInitialized();
    
    // 首先尝试从文件读取
    final fileData = await _readFromFile(key);
    if (fileData != null) {
      try {
        final List<dynamic> decoded = jsonDecode(fileData);
        return decoded.cast<Map<String, dynamic>>();
      } catch (e) {
        return null;
      }
    }
    
    // 如果文件不存在，尝试从SharedPreferences读取
    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> remove(String key) async {
    _ensureInitialized();
    await _prefs.remove(key);
    await _deleteFile(key);
  }

  @override
  Future<void> clear() async {
    _ensureInitialized();
    await _prefs.clear();
    await _clearAllFiles();
  }

  @override
  Future<bool> containsKey(String key) async {
    _ensureInitialized();
    return _prefs.containsKey(key) || await _fileExists(key);
  }

  @override
  Future<Set<String>> getKeys() async {
    _ensureInitialized();
    final prefsKeys = _prefs.getKeys();
    final fileKeys = await _getFileKeys();
    return {...prefsKeys, ...fileKeys};
  }

  // 文件操作辅助方法
  Future<void> _saveToFile(String key, String data) async {
    final file = File('${_appDir.path}/$key.json');
    await file.writeAsString(data);
  }

  Future<String?> _readFromFile(String key) async {
    final file = File('${_appDir.path}/$key.json');
    if (await file.exists()) {
      try {
        return await file.readAsString();
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> _deleteFile(String key) async {
    final file = File('${_appDir.path}/$key.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> _fileExists(String key) async {
    final file = File('${_appDir.path}/$key.json');
    return await file.exists();
  }

  Future<void> _clearAllFiles() async {
    final dir = Directory(_appDir.path);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          await entity.delete();
        }
      }
    }
  }

  Future<Set<String>> _getFileKeys() async {
    final keys = <String>{};
    final dir = Directory(_appDir.path);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          final fileName = entity.path.split('/').last;
          final key = fileName.substring(0, fileName.length - 5); // 移除.json后缀
          keys.add(key);
        }
      }
    }
    return keys;
  }

  /// 获取数据目录路径（用于导入导出）
  Future<String> getDataDirectoryPath() async {
    _ensureInitialized();
    return _appDir.path;
  }

  /// 备份所有数据到指定路径
  Future<void> backupToPath(String backupPath) async {
    _ensureInitialized();
    
    final backupData = <String, dynamic>{};
    
    // 备份SharedPreferences数据
    final prefsKeys = _prefs.getKeys();
    for (final key in prefsKeys) {
      final value = _prefs.get(key);
      if (value != null) {
        backupData['prefs_$key'] = value;
      }
    }
    
    // 备份文件数据
    final fileKeys = await _getFileKeys();
    for (final key in fileKeys) {
      final fileData = await _readFromFile(key);
      if (fileData != null) {
        backupData['file_$key'] = fileData;
      }
    }
    
    final backupFile = File(backupPath);
    await backupFile.writeAsString(jsonEncode(backupData));
  }

  /// 从指定路径恢复数据
  Future<void> restoreFromPath(String backupPath) async {
    _ensureInitialized();
    
    final backupFile = File(backupPath);
    if (!await backupFile.exists()) {
      throw FileSystemException('Backup file not found', backupPath);
    }
    
    final backupContent = await backupFile.readAsString();
    final backupData = jsonDecode(backupContent) as Map<String, dynamic>;
    
    // 清空现有数据
    await clear();
    
    // 恢复数据
    for (final entry in backupData.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (key.startsWith('prefs_')) {
        final actualKey = key.substring(6);
        if (value is String) {
          await _prefs.setString(actualKey, value);
        } else if (value is int) {
          await _prefs.setInt(actualKey, value);
        } else if (value is double) {
          await _prefs.setDouble(actualKey, value);
        } else if (value is bool) {
          await _prefs.setBool(actualKey, value);
        } else if (value is List<String>) {
          await _prefs.setStringList(actualKey, value);
        }
      } else if (key.startsWith('file_')) {
        final actualKey = key.substring(5);
        await _saveToFile(actualKey, value as String);
      }
    }
  }
}
