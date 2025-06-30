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
        title: const Text('Settings'),
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
                    'Data Manage',
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
                                Text('Exporting...'),
                              ],
                            )
                          : const Text('Export Data'),
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
                                Text('Importing...'),
                              ],
                            )
                          : const Text('Import Data'),
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
                      child: const Text('Clear All Data'),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  const Text(
                    'Data export format：JSON\nData includes：Weight Records、Training Plans、Nutrition Records、User Settings',
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
                    'User Setting',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 个人资料入口
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('个人资料'),
                    subtitle: Text(_dataManager.isLoggedIn ? _dataManager.userName : '未登录'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  
                  const Divider(),
                  
                  // 帮助与支持入口
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('帮助与支持'),
                    subtitle: const Text('使用指南、常见问题'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.pushNamed(context, '/help');
                    },
                  ),
                  
                  const Divider(),
                  
                  // 身高设置
                  ListTile(
                    title: const Text('Height'),
                    subtitle: Text('${_dataManager.height.toStringAsFixed(1)} cm'),
                    trailing: const Icon(Icons.edit),
                    onTap: () => _showHeightDialog(),
                  ),
                  
                  const Divider(),
                  
                  // 热量目标设置
                  ListTile(
                    title: const Text('Daily Calorie Goal'),
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
                    'About Application',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  const ListTile(
                    title: Text('Application Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  
                  const Divider(),
                  
                  const ListTile(
                    title: Text('Developer'),
                    subtitle: Text('Flutter Fitness App'),
                  ),
                  
                  const Divider(),
                  
                  ListTile(
                    title: const Text('Data store explanation'),
                    subtitle: const Text('Data is saved on local devices to ensure privacy and security'),
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
              content: Text('Data exports successfully！\nSave Path：${filePath}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Export Cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Failed：$e'),
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
            content: Text('Data imports successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import Failed：$e'),
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
        title: const Text('Confirm clearing data'),
        content: const Text('This operation will delete all data, including weight records, training plans, nutrition records, etc. This operation is irrevocable.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _dataManager.clearAllData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Data is cleared')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm to clear'),
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
        title: const Text('Set Height'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Height (cm)',
            suffixText: 'cm',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Confirm'),
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
        title: const Text('Set Calorie Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Daily Calorie Goal (kcal)',
            suffixText: 'kcal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
            child: const Text('Confirm'),
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
            Text('• 所有数据安全存储在本地设备'),
            Text('• 使用 SQLite 数据库确保数据完整性'),
            Text('• 支持用户账户系统和数据隔离'),
            Text('• 绝不上传到任何外部服务器'),
            Text('• 保障用户隐私和数据安全'),
            SizedBox(height: 16),
            Text('支持的数据类型：'),
            SizedBox(height: 8),
            Text('• 用户资料和认证信息'),
            Text('• 体重记录和身体数据'),
            Text('• 训练计划和运动记录'),
            Text('• 营养摄入和饮食记录'),
            Text('• 应用设置和个人偏好'),
            Text('• 媒体文件和学习资源'),
            SizedBox(height: 16),
            Text('数据安全特性：'),
            SizedBox(height: 8),
            Text('• 本地加密存储'),
            Text('• 支持数据导入导出'),
            Text('• 自动备份机制'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('了解了'),
          ),
        ],
      ),
    );
  }
}
