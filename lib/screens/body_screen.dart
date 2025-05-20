import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/weight_line_chart.dart';
import '../mock_data.dart';
import '../widgets/primary_button.dart';

class BodyScreen extends StatefulWidget {
  const BodyScreen({super.key});

  @override
  State<BodyScreen> createState() => _BodyScreenState();
}

class _BodyScreenState extends State<BodyScreen> {
  final MockData _mockData = MockData();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mockData.addListener(_updateUI);
    _heightController.text = _mockData.height.toString();
    _weightController.text = _mockData.currentWeight.toString();
  }

  @override
  void dispose() {
    _mockData.removeListener(_updateUI);
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _updateUI() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('身体数据'),
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
                              '个人资料',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('身高: ${_mockData.height.toStringAsFixed(1)} cm'),
                            Text('当前体重: ${_mockData.currentWeight.toStringAsFixed(1)} kg'),
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
                    'BMI指数', 
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      _mockData.bmi.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: _getBmiColor(_mockData.bmi),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildBmiScale(context),
                  const SizedBox(height: 8),
                  Text(
                    _getBmiStatusText(_mockData.bmi),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _getBmiColor(_mockData.bmi),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 体重趋势图卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '体重趋势', 
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  WeightLineChart(data: _mockData.weights7d),
                  const SizedBox(height: 16),
                  _buildWeightStats(),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 历史体重记录卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '历史记录', 
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
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddWeightDialog(context),
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
          left: _getBmiPosition(_mockData.bmi) * MediaQuery.of(context).size.width * 0.8,
          child: const Icon(Icons.arrow_drop_down, size: 30),
        ),
      ],
    );
  }

  // 构建体重统计信息
  Widget _buildWeightStats() {
    if (_mockData.weights7d.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    final weights = _mockData.weights7d.map((e) => e.value).toList();
    final avgWeight = weights.reduce((a, b) => a + b) / weights.length;
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('平均', avgWeight.toStringAsFixed(1)),
        _buildStatItem('最低', minWeight.toStringAsFixed(1)),
        _buildStatItem('最高', maxWeight.toStringAsFixed(1)),
      ],
    );
  }

  // 构建单个统计项
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  // 构建体重历史记录列表
  Widget _buildWeightHistory() {
    if (_mockData.weights7d.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('暂无记录')),
      );
    }

    // 按日期倒序排列
    final sortedEntries = [..._mockData.weights7d]
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
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (change != null) ...[
                const SizedBox(width: 8),
                Text(
                  change > 0 ? '+${change.toStringAsFixed(1)}' : '${change.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: change > 0 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
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
          title: const Text('编辑个人资料'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '身高 (cm)',
                  suffixText: 'cm',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '当前体重 (kg)',
                  suffixText: 'kg',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            PrimaryButton(
              onPressed: () {
                final height = double.tryParse(_heightController.text);
                final weight = double.tryParse(_weightController.text);
                
                if (height != null && weight != null) {
                  _mockData.height = height;
                  _mockData.addWeight(weight); // 这会更新currentWeight并通知监听器
                }
                
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  // 添加体重记录对话框
  void _showAddWeightDialog(BuildContext context) {
    final controller = TextEditingController(
      text: _mockData.currentWeight.toString()
    );
    
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('记录体重'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '体重 (kg)',
              suffixText: 'kg',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            PrimaryButton(
              onPressed: () {
                final value = double.tryParse(controller.text);
                if (value != null) {
                  _mockData.addWeight(value);
                }
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
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
    if (bmi < 18.5) return '体重过轻';
    if (bmi < 24) return '体重正常';
    if (bmi < 28) return '超重';
    if (bmi < 35) return '肥胖';
    return '严重肥胖';
  }
}
