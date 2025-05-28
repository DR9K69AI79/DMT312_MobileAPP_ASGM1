/// 存储服务接口，定义数据持久化的基本操作
abstract class StorageService {
  /// 初始化存储服务
  Future<void> init();

  /// 保存字符串数据
  Future<void> saveString(String key, String value);

  /// 读取字符串数据
  Future<String?> getString(String key);

  /// 保存JSON数据
  Future<void> saveJson(String key, Map<String, dynamic> json);

  /// 读取JSON数据
  Future<Map<String, dynamic>?> getJson(String key);

  /// 保存JSON列表数据
  Future<void> saveJsonList(String key, List<Map<String, dynamic>> jsonList);

  /// 读取JSON列表数据
  Future<List<Map<String, dynamic>>?> getJsonList(String key);

  /// 删除指定键的数据
  Future<void> remove(String key);

  /// 清空所有数据
  Future<void> clear();

  /// 检查指定键是否存在
  Future<bool> containsKey(String key);

  /// 获取所有键
  Future<Set<String>> getKeys();
}
