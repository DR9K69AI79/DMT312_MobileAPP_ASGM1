#!/usr/bin/env python3
"""
数据格式验证脚本
验证生成的JSON数据是否完全符合Flutter应用的导入要求
"""

import json
import sys
from typing import Dict, Any, List

def validate_flutter_import_format(file_path: str) -> bool:
    """验证JSON文件是否符合Flutter导入格式要求"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"验证文件: {file_path}")
        print("=" * 50)
        
        # 1. 验证顶级结构
        if not _validate_top_level_structure(data):
            return False
        
        # 2. 验证体重数据格式
        if not _validate_weight_data(data['data']['weights']):
            return False
        
        # 3. 验证体脂数据格式  
        if not _validate_body_fat_data(data['data']['bodyFat']):
            return False
        
        # 4. 验证训练数据格式
        if not _validate_workout_data(data['data']['workouts']):
            return False
        
        # 5. 验证营养数据格式 (重点)
        if not _validate_nutrition_data(data['data']['nutrition']):
            return False
        
        # 6. 验证用户设置
        if not _validate_user_settings(data['data']['userSettings']):
            return False
        
        print("\n✓ 所有验证通过！数据格式完全符合Flutter应用导入要求")
        return True
        
    except Exception as e:
        print(f"✗ 验证过程中出错: {e}")
        return False

def _validate_top_level_structure(data: Dict[str, Any]) -> bool:
    """验证顶级数据结构"""
    required_fields = ['version', 'exportDate', 'data']
    for field in required_fields:
        if field not in data:
            print(f"✗ 缺少顶级字段: {field}")
            return False
    
    data_section = data['data']
    required_data_fields = ['weights', 'bodyFat', 'workouts', 'nutrition', 'userSettings']
    for field in required_data_fields:
        if field not in data_section:
            print(f"✗ 缺少数据字段: {field}")
            return False
    
    print("✓ 顶级结构验证通过")
    return True

def _validate_weight_data(weights: List[Dict[str, Any]]) -> bool:
    """验证体重数据格式"""
    if not isinstance(weights, list):
        print("✗ weights必须是列表")
        return False
    
    for i, weight in enumerate(weights):
        if not all(field in weight for field in ['date', 'weight']):
            print(f"✗ 体重记录{i}缺少必要字段")
            return False
        
        if not isinstance(weight['weight'], (int, float)):
            print(f"✗ 体重记录{i}的weight值不是数字")
            return False
    
    print(f"✓ 体重数据验证通过 ({len(weights)}条记录)")
    return True

def _validate_body_fat_data(body_fat: List[Dict[str, Any]]) -> bool:
    """验证体脂数据格式"""
    if not isinstance(body_fat, list):
        print("✗ bodyFat必须是列表")
        return False
    
    for i, bf in enumerate(body_fat):
        if not all(field in bf for field in ['date', 'bodyFatPercentage']):
            print(f"✗ 体脂记录{i}缺少必要字段")
            return False
        
        if not isinstance(bf['bodyFatPercentage'], (int, float)):
            print(f"✗ 体脂记录{i}的bodyFatPercentage值不是数字")
            return False
    
    print(f"✓ 体脂数据验证通过 ({len(body_fat)}条记录)")
    return True

def _validate_workout_data(workouts: Dict[str, Any]) -> bool:
    """验证训练数据格式"""
    if not isinstance(workouts, dict):
        print("✗ workouts必须是字典")
        return False
    
    total_workouts = 0
    for date_key, daily_workouts in workouts.items():
        if not isinstance(daily_workouts, list):
            print(f"✗ {date_key}的训练记录必须是列表")
            return False
        
        for workout in daily_workouts:
            required_fields = ['date', 'name', 'sets', 'isCompleted']
            if not all(field in workout for field in required_fields):
                print(f"✗ 训练记录缺少必要字段: {required_fields}")
                return False
            
            if not isinstance(workout['sets'], int):
                print("✗ sets值必须是整数")
                return False
            
            if not isinstance(workout['isCompleted'], bool):
                print("✗ isCompleted值必须是布尔值")
                return False
            
            total_workouts += 1
    
    print(f"✓ 训练数据验证通过 ({len(workouts)}天, {total_workouts}个训练项目)")
    return True

def _validate_nutrition_data(nutrition: List[Dict[str, Any]]) -> bool:
    """验证营养数据格式 - 关键验证点"""
    if not isinstance(nutrition, list):
        print("✗ nutrition必须是列表")
        return False
    
    total_meals = 0
    for i, entry in enumerate(nutrition):
        # 验证每日营养记录的必要字段
        required_fields = ['date', 'calorieIntake', 'caloriesBurned', 'calorieGoal', 'meals']
        if not all(field in entry for field in required_fields):
            print(f"✗ 营养记录{i}缺少必要字段: {required_fields}")
            return False
        
        # 验证热量字段
        for field in ['calorieIntake', 'caloriesBurned', 'calorieGoal']:
            if not isinstance(entry[field], (int, float)):
                print(f"✗ 营养记录{i}的{field}值必须是数字")
                return False
        
        # 验证meals数据结构 - 这是关键部分
        meals = entry['meals']
        if not isinstance(meals, list):
            print(f"✗ 营养记录{i}的meals必须是列表")
            return False
        
        for j, meal in enumerate(meals):
            # 验证每个meal的结构
            required_meal_fields = ['name', 'foods', 'calories']
            if not all(field in meal for field in required_meal_fields):
                print(f"✗ 营养记录{i}的meal{j}缺少必要字段: {required_meal_fields}")
                return False
            
            # 验证foods是列表且只包含一个食物项目
            if not isinstance(meal['foods'], list):
                print(f"✗ meal{j}的foods必须是列表")
                return False
            
            if len(meal['foods']) != 1:
                print(f"✗ meal{j}的foods必须只包含一个食物项目，实际包含{len(meal['foods'])}个")
                return False
            
            # 验证calories是数字
            if not isinstance(meal['calories'], (int, float)):
                print(f"✗ meal{j}的calories值必须是数字")
                return False
            
            total_meals += 1
    
    print(f"✓ 营养数据验证通过 ({len(nutrition)}天, {total_meals}个餐食记录)")
    print("  - 每个meal包含正确的name、foods（单个食物）、calories字段")
    print("  - 完全符合Flutter MealEntry导入要求")
    return True

def _validate_user_settings(settings: Dict[str, Any]) -> bool:
    """验证用户设置格式"""
    if not isinstance(settings, dict):
        print("✗ userSettings必须是字典")
        return False
    
    print("✓ 用户设置验证通过")
    return True

def main():
    if len(sys.argv) != 2:
        print("用法: python validate_data_format.py <json_file_path>")
        sys.exit(1)
    
    file_path = sys.argv[1]
    success = validate_flutter_import_format(file_path)
    
    if success:
        print("\n🎉 数据格式验证完全通过！")
        print("该JSON文件可以成功导入到Flutter应用中。")
        sys.exit(0)
    else:
        print("\n❌ 数据格式验证失败！")
        print("请检查并修复上述问题后重新验证。")
        sys.exit(1)

if __name__ == '__main__':
    main()
