import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../services/data_manager.dart';
import '../widgets/primary_button.dart';
import '../models/nutrition_entry.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final DataManager _dataManager = DataManager();
  
  @override
  void initState() {
    super.initState();
    _dataManager.addListener(_updateUI);
  }
  
  @override
  void dispose() {
    _dataManager.removeListener(_updateUI);
    super.dispose();
  }
  
  void _updateUI() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('饮食记录'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日热量摘要卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '今日热量摘要',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,                    children: [
                      _buildCalorieItem('摄入', _dataManager.calorieIntake, Colors.blue),
                      _buildCalorieItem('消耗', _dataManager.caloriesBurned, Colors.green),
                      _buildCalorieItem(
                        '剩余',
                        _dataManager.calorieBalance,
                        _dataManager.calorieBalance > 0 ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildCalorieProgress(),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 快速录入卡片
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '快速录入',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildQuickAddButton('+100', 100),
                      _buildQuickAddButton('+250', 250),
                      _buildQuickAddButton('+500', 500),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text('常见食物'),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: _buildCommonFoodsList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 食物搜索卡片
            GlassCard(
              child: Column(
                children: [
                  const TextField(
                    decoration: InputDecoration(
                      labelText: '搜索食物',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Icon(Icons.qr_code_scanner),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 餐次记录卡片
            ..._buildMealSections(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showAddFoodDialog(context),
      ),
    );
  }
  
  // 构建热量项目
  Widget _buildCalorieItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: color,
              ),
            ),
            const Text(
              ' kcal',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
    // 构建热量进度条
  Widget _buildCalorieProgress() {
    final caloriePercent = _dataManager.calorieIntake / _dataManager.calorieGoal;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '每日目标: ${_dataManager.calorieGoal} kcal',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // 背景条
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // 填充条
            FractionallySizedBox(
              widthFactor: caloriePercent.clamp(0.0, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: caloriePercent > 1.0 ? Colors.red : Colors.blue,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
    // 构建快速添加按钮
  Widget _buildQuickAddButton(String label, int calories) {
    return ElevatedButton(
      onPressed: () {
        _dataManager.updateCalorieIntake(_dataManager.calorieIntake + calories);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已添加 $calories kcal')),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
  
  // 构建常见食物列表
  Widget _buildCommonFoodsList() {
    final commonFoods = [
      {'name': '鸡蛋', 'calories': 75, 'icon': Icons.egg},
      {'name': '香蕉', 'calories': 100, 'icon': Icons.spa},
      {'name': '面包', 'calories': 200, 'icon': Icons.breakfast_dining},
      {'name': '牛奶', 'calories': 150, 'icon': Icons.local_cafe},
      {'name': '苹果', 'calories': 80, 'icon': Icons.apple},
      {'name': '米饭', 'calories': 250, 'icon': Icons.rice_bowl},
    ];
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: commonFoods.length,
      itemBuilder: (context, index) {
        final food = commonFoods[index];
        return Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [              InkWell(
                onTap: () {
                  _dataManager.updateCalorieIntake(
                    _dataManager.calorieIntake + (food['calories'] as int)
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('已添加 ${food['name']} (${food['calories']} kcal)')),
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    food['icon'] as IconData,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(food['name'] as String),
            ],
          ),
        );
      },
    );  }
  
  // 构建餐次卡片
  List<Widget> _buildMealSections() {
    final result = <Widget>[];
    final todayNutrition = _dataManager.nutritionToday;
    
    // 按餐次分组
    final mealGroups = <String, List<MealEntry>>{};
    if (todayNutrition != null && todayNutrition.meals.isNotEmpty) {
      for (final meal in todayNutrition.meals) {
        if (!mealGroups.containsKey(meal.mealType)) {
          mealGroups[meal.mealType] = [];
        }
        mealGroups[meal.mealType]!.add(meal);
      }
    }
    
    // 确保所有餐次都有显示，即使是空的
    final allMealTypes = ['早餐', '午餐', '晚餐', '加餐'];
    for (final mealType in allMealTypes) {
      if (!mealGroups.containsKey(mealType)) {
        mealGroups[mealType] = [];
      }
    }
    
    mealGroups.forEach((mealName, foodItems) {
      // 计算当前餐次的总卡路里
      int totalCalories = 0;
      for (final food in foodItems) {
        totalCalories += food.calories;
      }
      
      result.add(
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    mealName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$totalCalories kcal',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),              const SizedBox(height: 8),
              const Divider(),
              ...foodItems.asMap().entries.map((entry) {
                final index = entry.key;
                final food = entry.value;
                return _buildFoodItem(food, mealName, index);
              }).toList(),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text('添加到$mealName'),
                  onPressed: () => _showAddFoodDialog(context, mealType: mealName),
                ),
              ),
            ],
          ),
        ),
      );
      
      result.add(const SizedBox(height: 16));
    });
    
    return result;
  }
  // 构建单个食物项
  Widget _buildFoodItem(MealEntry meal, String mealType, int index) {
    return Dismissible(
      key: Key('${meal.name}_${meal.calories}_${meal.timestamp.millisecondsSinceEpoch}'),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        await _dataManager.removeMeal(index);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已从$mealType移除 ${meal.name}')),
        );
      },
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(meal.name),
        subtitle: Text(meal.amount),
        trailing: Text(
          '${meal.calories} kcal',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  // 添加食物对话框
  void _showAddFoodDialog(BuildContext context, {String? mealType}) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final caloriesController = TextEditingController();
    String selectedMealType = mealType ?? '早餐';
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.0,
                right: 16.0,
                top: 16.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '添加食物',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),                  // 选择餐次
                  DropdownButton<String>(
                    value: selectedMealType,
                    isExpanded: true,
                    items: ['早餐', '午餐', '晚餐', '加餐'].map((String mealType) {
                      return DropdownMenuItem<String>(
                        value: mealType,
                        child: Text(mealType),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setModalState(() {
                          selectedMealType = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '食物名称',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: '分量 (如: 1碗, 100g)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '热量 (kcal)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 16),                      PrimaryButton(
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final amount = amountController.text.trim();
                          final calories = int.tryParse(caloriesController.text) ?? 0;
                            if (name.isNotEmpty && amount.isNotEmpty && calories > 0) {
                            final meal = MealEntry(
                              mealType: selectedMealType,
                              name: name,
                              calories: calories,
                              amount: amount,
                              timestamp: DateTime.now(),
                            );
                            await _dataManager.addMeal(meal);
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('添加'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
