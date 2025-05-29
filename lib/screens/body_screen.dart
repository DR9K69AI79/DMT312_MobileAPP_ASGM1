import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/weight_chart.dart';
import '../services/data_manager.dart';
import '../widgets/primary_button.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  final DataManager _dataManager = DataManager();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _bodyFatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dataManager.addListener(_updateUI);
    _heightController.text = _dataManager.height.toString();
    _weightController.text = (_dataManager.currentWeight ?? 0.0).toString();
    _bodyFatController.text = (_dataManager.currentBodyFat ?? 0.0).toString();
  }

  @override
  void dispose() {
    _dataManager.removeListener(_updateUI);
    _heightController.dispose();
    _weightController.dispose();
    _bodyFatController.dispose();
    super.dispose();
  }

  void _updateUI() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Body Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 个人资料卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        child: const Icon(Icons.person, size: 40, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Personal Data',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Height: ${_dataManager.height.toStringAsFixed(1)} cm'),
                            Text('Weight: ${(_dataManager.currentWeight ?? 0.0).toStringAsFixed(1)} kg'),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditProfileDialog(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // BMI指数卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BMI Index', 
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _dataManager.bmi.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getBmiColor(_dataManager.bmi),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBmiScale(context),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _getBmiStatusText(_dataManager.bmi),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getBmiColor(_dataManager.bmi),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 体脂率卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Boday Fat Rate',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '${(_dataManager.currentBodyFat ?? 0.0).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getBodyFatColor(_dataManager.currentBodyFat ?? 0.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      _getBodyFatStatusText(_dataManager.currentBodyFat ?? 0.0),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getBodyFatColor(_dataManager.currentBodyFat ?? 0.0),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 体重趋势图卡片 - 替换为增强版图表
            const EnhancedWeightChart(
              showBodyFat: true,
              showTimeSelector: true,
            ),

            const SizedBox(height: 16),

            // 历史体重记录卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildWeightHistory(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "body_fat",
            mini: true,
            child: const Icon(Icons.fitness_center),
            onPressed: () => _showAddBodyFatDialog(context),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: "weight",
            child: const Icon(Icons.add),
            onPressed: () => _showAddWeightDialog(context),
          ),
        ],
      ),
    );
  }

  // 构建BMI等级线
  Widget _buildBmiScale(BuildContext context) {
    return Stack(
      children: [
        // 背景条
        Container(
          height: 10,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.blue, Colors.green, Colors.orange, Colors.red],
            ),
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        // 指示器
        Positioned(
          left: _getBmiPosition(_dataManager.bmi) * MediaQuery.of(context).size.width * 0.8,
          child: const Icon(Icons.arrow_drop_down, size: 30),
        ),
      ],
    );
  }

  // 构建体重历史记录列表
  Widget _buildWeightHistory() {
    if (_dataManager.weights7d.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No Record')),
      );
    }

    // 按日期倒序排列
    final sortedEntries = [..._dataManager.weights7d]
      ..sort((a, b) => b.date.compareTo(a.date));

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        
        // 计算与前一天的差值
        double? change;
        if (index < sortedEntries.length - 1) {
          change = entry.value - sortedEntries[index + 1].value;
        }

        return ListTile(
          title: Text(
            '${entry.date.year}-${entry.date.month}-${entry.date.day}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.value.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 8),
                Text(
                  '${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: change > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // 编辑个人资料对话框
  void _showEditProfileDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  suffixText: 'cm',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  suffixText: 'kg',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            PrimaryButton(
              onPressed: () async {                final height = double.tryParse(_heightController.text);
                final weight = double.tryParse(_weightController.text);
                if (height != null && weight != null) {
                  await _dataManager.updateHeight(height);
                  await _dataManager.addWeight(weight);
                }
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // 添加体重记录对话框
  void _showAddWeightDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _dataManager.currentWeight.toString()
    );
    
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Weight'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              suffixText: 'kg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            PrimaryButton(
              onPressed: () async {
                final weight = double.tryParse(controller.text);
                if (weight != null) {
                  await _dataManager.addWeight(weight);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Weight Record Saved')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // 添加体脂记录对话框
  void _showAddBodyFatDialog(BuildContext context) {
    final controller = TextEditingController();
    
    // 设置初始值
    controller.text = (_dataManager.currentBodyFat ?? 0.0).toString();
    
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Record Body Fat Rate'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Body Fat Rate (%)',
              suffixText: '%',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            PrimaryButton(
              onPressed: () async {
                final bodyFat = double.tryParse(controller.text);
                if (bodyFat != null) {
                  await _dataManager.addBodyFat(bodyFat);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Body Fat Rate Record Saved')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // 根据BMI值获取颜色
  Color _getBmiColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24) return Colors.green;
    if (bmi < 28) return Colors.orange;
    return Colors.red;
  }

  // 计算BMI指示器位置 (0.0-1.0)
  double _getBmiPosition(double bmi) {
    if (bmi < 15) return 0.0;
    if (bmi > 35) return 1.0;
    return (bmi - 15) / 20; // 15-35范围映射到0-1
  }

  // 获取BMI状态文字
  String _getBmiStatusText(double bmi) {
    if (bmi < 18.5) return 'Under Weight';
    if (bmi < 24) return 'Normal Weight';
    if (bmi < 28) return 'Over Weight';
    if (bmi < 35) return 'Obesity';
    return 'Severe Obesity';
  }

  // 获取体脂率颜色
  Color _getBodyFatColor(double bodyFat) {
    if (bodyFat < 10) return Colors.blue; // 过低
    if (bodyFat < 15) return Colors.green; // 理想
    if (bodyFat < 20) return Colors.orange; // 偏高
    return Colors.red; // 过高
  }

  // 获取体脂率状态文字
  String _getBodyFatStatusText(double bodyFat) {
    if (bodyFat < 10) return 'Low Body Fat Rate';
    if (bodyFat < 15) return 'Ideal Body Fat Rate';
    if (bodyFat < 20) return 'High Body Fat Rate';
    return 'Excessive Body Fat Rate';
  }
}
