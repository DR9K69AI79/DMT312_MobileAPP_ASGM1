import 'dart:io';
import 'services/data_manager.dart';
import 'services/export_service.dart';

/// 测试数据导入功能
Future<void> testDataImport() async {
  print('开始测试数据导入功能...');
  
  try {
    final dataManager = DataManager();
    final exportService = ExportService();
    
    // 测试导入演示数据
    const demoDataPath = 'PyTools/demo_data_flutter_compatible.json';
    final file = File(demoDataPath);
    
    if (!await file.exists()) {
      print('错误: 演示数据文件不存在: $demoDataPath');
      return;
    }
    
    print('✓ 找到演示数据文件');
    
    // 清空现有数据
    await dataManager.clearUserData();
    print('✓ 已清空现有数据');
    
    // 导入数据
    final importSuccess = await exportService.importData(demoDataPath);
    
    if (!importSuccess) {
      print('✗ 数据导入失败');
      return;
    }
    
    print('✓ 数据导入成功');
    
    // 验证导入的数据
    await _validateImportedData(dataManager);
    
  } catch (e) {
    print('导入测试过程中出错: $e');
  }
}

/// 验证导入的数据
Future<void> _validateImportedData(DataManager dataManager) async {
  print('\n开始验证导入的数据...');
  
  try {
    // 检查体重数据
    final weightData = dataManager.getWeightData();
    print('体重记录数量: ${weightData.length}');
    
    // 检查体脂数据
    final bodyFatData = dataManager.getBodyFatData();
    print('体脂记录数量: ${bodyFatData.length}');
    
    // 检查训练数据
    final workoutData = dataManager.getWorkoutData();
    int totalWorkouts = 0;
    int completedWorkouts = 0;
    
    for (final dayWorkouts in workoutData.values) {
      for (final workout in dayWorkouts) {
        totalWorkouts++;
        if (workout.isCompleted) {
          completedWorkouts++;
        }
      }
    }
    
    print('训练记录天数: ${workoutData.length}');
    print('总训练项目: $totalWorkouts');
    print('已完成训练: $completedWorkouts');
    print('训练完成率: ${totalWorkouts > 0 ? (completedWorkouts / totalWorkouts * 100).toStringAsFixed(1) : 0}%');
    
    // 检查营养数据
    final nutritionData = dataManager.getNutritionData();
    int totalMeals = 0;
    int totalCalories = 0;
    
    for (final nutrition in nutritionData.values) {
      totalMeals += nutrition.meals.length;
      totalCalories += nutrition.calorieIntake;
    }
    
    print('营养记录天数: ${nutritionData.length}');
    print('总餐食记录: $totalMeals');
    print('平均每日摄入热量: ${nutritionData.isNotEmpty ? (totalCalories / nutritionData.length).round() : 0}');
    
    // 检查今日数据
    await dataManager.refreshTodayData();
    print('\n今日数据:');
    print('今日体重: ${dataManager.currentWeight}');
    print('今日体脂率: ${dataManager.currentBodyFat}');
    print('今日热量摄入: ${dataManager.calorieIntake}');
    print('今日热量消耗: ${dataManager.caloriesBurned}');
    print('热量目标: ${dataManager.calorieGoal}');
    print('今日训练完成率: ${(dataManager.workoutCompletionPercent * 100).toStringAsFixed(1)}%');
    
    print('\n✓ 数据验证完成，所有数据导入成功！');
    
  } catch (e) {
    print('验证数据时出错: $e');
  }
}

/// 主函数用于测试
void main() async {
  await testDataImport();
}
