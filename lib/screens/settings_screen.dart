import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../services/data_manager.dart';
import '../services/export_service.dart';
import '../widgets/primary_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DataManager _dataManager = DataManager();
  final ExportService _exportService = ExportService();
  bool _isExporting = false;
  bool _isImporting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 数据管理卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '数据管理',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),                  // 导出数据按钮
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      onPressed: _isExporting ? null : () {
                        _exportData();
                      },
                      child: _isExporting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('导出中...'),
                              ],
                            )
                          : const Text('导出数据'),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 导入数据按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isImporting ? null : () {
                        _importData();
                      },
                      child: _isImporting
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('导入中...'),
                              ],
                            )
                          : const Text('导入数据'),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 清空数据按钮
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _showClearDataDialog,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      child: const Text('清空所有数据'),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text(
                    '数据导出格式：JSON\n数据包含：体重记录、训练计划、营养记录、用户设置',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 用户设置卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '用户设置',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 身高设置
                  ListTile(
                    title: const Text('身高'),
                    subtitle: Text('${_dataManager.height.toStringAsFixed(1)} cm'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showHeightDialog(),
                  ),
                  
                  const Divider(),
                  
                  // 热量目标设置
                  ListTile(
                    title: const Text('每日热量目标'),
                    subtitle: Text('${_dataManager.calorieGoal} kcal'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showCalorieGoalDialog(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 关于应用卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '关于应用',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const ListTile(
                    title: Text('应用版本'),
                    subtitle: Text('1.0.0'),
                  ),
                  
                  const Divider(),
                  
                  const ListTile(
                    title: Text('开发者'),
                    subtitle: Text('Flutter 健身应用'),
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    title: const Text('数据存储说明'),
                    subtitle: const Text('数据保存在本地设备，确保隐私安全'),
                    onTap: () => _showDataStorageDialog(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // 导出数据
  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      final filePath = await _exportService.exportDataWithFilePicker();
      
      if (mounted) {
        if (filePath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('数据导出成功！\n保存位置：${filePath}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('导出已取消'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
  // 导入数据
  Future<void> _importData() async {
    setState(() => _isImporting = true);
    
    try {
      await _exportService.importAllDataWithFilePicker(_dataManager);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据导入成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败：$e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  // 显示清空数据确认对话框
  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空数据'),
        content: const Text('此操作将删除所有数据，包括体重记录、训练计划、营养记录等。此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dataManager.clearAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据已清空')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  // 显示身高设置对话框
  void _showHeightDialog() {
    final controller = TextEditingController(
      text: _dataManager.height.toStringAsFixed(1),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置身高'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '身高 (cm)',
            suffixText: 'cm',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final height = double.tryParse(controller.text);
              if (height != null && height > 0 && height < 300) {
                await _dataManager.updateHeight(height);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 显示热量目标设置对话框
  void _showCalorieGoalDialog() {
    final controller = TextEditingController(
      text: _dataManager.calorieGoal.toString(),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置热量目标'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '每日热量目标 (kcal)',
            suffixText: 'kcal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final goal = int.tryParse(controller.text);
              if (goal != null && goal > 0 && goal < 10000) {
                await _dataManager.updateCalorieGoal(goal);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 显示数据存储说明对话框
  void _showDataStorageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据存储说明'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('数据存储方式：'),
            SizedBox(height: 8),
            Text('• 所有数据保存在设备本地存储'),
            Text('• 使用JSON格式进行持久化'),
            Text('• 不会上传到任何服务器'),
            Text('• 确保用户隐私安全'),
            SizedBox(height: 16),
            Text('支持的数据类型：'),
            SizedBox(height: 8),
            Text('• 体重记录'),
            Text('• 训练计划'),
            Text('• 营养记录'),
            Text('• 用户设置'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
