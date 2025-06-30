#!/usr/bin/env python3
import json
import random
import datetime
import argparse
from typing import Dict, List, Any

# 健身数据生成器
class FitnessDataGenerator:
    def __init__(self, days: int, start_date: datetime.datetime = None, 
                 initial_weight: float = 70.0, weight_fluctuation: float = 0.5,
                 initial_body_fat: float = 18.0, body_fat_fluctuation: float = 0.3,
                 english_names: bool = False):
        """
        初始化生成器
        
        Args:
            days: 要生成的天数
            start_date: 开始日期(默认为今天)
            initial_weight: 初始体重(kg)
            weight_fluctuation: 体重波动范围(kg)
            initial_body_fat: 初始体脂率(%)
            body_fat_fluctuation: 体脂率波动范围(%)
            english_names: 是否使用英文名称(默认为False)
        """
        self.days = days
        self.start_date = start_date or datetime.datetime.now()
        self.initial_weight = initial_weight
        self.weight_fluctuation = weight_fluctuation
        self.initial_body_fat = initial_body_fat
        self.body_fat_fluctuation = body_fat_fluctuation
        self.english_names = english_names
        
        # 预设的训练项目（中文版）
        self.workout_templates_cn = [
            {"name": "俯卧撑", "sets": 4},
            {"name": "深蹲", "sets": 4},
            {"name": "平板支撑", "sets": 3},
            {"name": "引体向上", "sets": 3},
            {"name": "卷腹", "sets": 4},
            {"name": "二头弯举", "sets": 3},
            {"name": "三头下压", "sets": 3},
            {"name": "哑铃划船", "sets": 4},
            {"name": "箭步蹲", "sets": 4},
            {"name": "负重深蹲", "sets": 4},
            {"name": "颈前推举", "sets": 3},
            {"name": "侧平举", "sets": 3},
            {"name": "腿举", "sets": 4}
        ]
        
        # 预设的训练项目（英文版）
        self.workout_templates_en = [
            {"name": "Push-ups", "sets": 4},
            {"name": "Squats", "sets": 4},
            {"name": "Plank", "sets": 3},
            {"name": "Pull-ups", "sets": 3},
            {"name": "Crunches", "sets": 4},
            {"name": "Bicep Curls", "sets": 3},
            {"name": "Tricep Dips", "sets": 3},
            {"name": "Dumbbell Rows", "sets": 4},
            {"name": "Lunges", "sets": 4},
            {"name": "Weighted Squats", "sets": 4},
            {"name": "Overhead Press", "sets": 3},
            {"name": "Lateral Raises", "sets": 3},
            {"name": "Leg Press", "sets": 4}
        ]
        
        # 预设的食物项目和卡路里（中文版）
        self.meal_templates_cn = [
            {"name": "早餐", "foods": ["鸡蛋", "牛奶", "面包"], "calories": 400},
            {"name": "午餐", "foods": ["米饭", "蔬菜", "鸡胸肉"], "calories": 650},
            {"name": "晚餐", "foods": ["面条", "沙拉", "牛肉"], "calories": 550},
            {"name": "加餐", "foods": ["水果", "坚果"], "calories": 200}
        ]
        
        # 预设的食物项目和卡路里（英文版）
        self.meal_templates_en = [
            {"name": "Breakfast", "foods": ["Eggs", "Milk", "Bread"], "calories": 400},
            {"name": "Lunch", "foods": ["Rice", "Vegetables", "Chicken Breast"], "calories": 650},
            {"name": "Dinner", "foods": ["Pasta", "Salad", "Beef"], "calories": 550},
            {"name": "Snack", "foods": ["Fruits", "Nuts"], "calories": 200}
        ]
        
        # 根据语言选择对应的模板
        self.workout_templates = self.workout_templates_en if english_names else self.workout_templates_cn
        self.meal_templates = self.meal_templates_en if english_names else self.meal_templates_cn

    def _format_date(self, date: datetime.datetime) -> str:
        """格式化日期为YYYY-MM-DD格式"""
        return date.strftime("%Y-%m-%d")
    
    def _format_date_time(self, date: datetime.datetime) -> str:
        """格式化日期时间为ISO格式"""
        return date.isoformat()
    
    def generate_weight_data(self) -> List[Dict[str, Any]]:
        """生成体重数据"""
        weights = []
        current_weight = self.initial_weight
        
        for i in range(self.days):
            # 从今天往前推算日期，i=0时是今天，i=days-1时是最早的日期
            date = datetime.datetime.now() - datetime.timedelta(days=self.days-i-1)
            # 添加一些随机波动，但保持总体趋势
            trend_factor = -0.05 if random.random() > 0.6 else 0.02  # 60%概率减重，40%概率增重
            current_weight += trend_factor + random.uniform(-self.weight_fluctuation, self.weight_fluctuation)
            current_weight = round(max(50, min(100, current_weight)), 1)  # 确保体重在合理范围内
            
            # 并非每天都有记录
            if random.random() > 0:  # 100%概率有记录
                weights.append({
                    "date": self._format_date(date),
                    "weight": current_weight
                })
        
        return weights
    
    def generate_body_fat_data(self) -> List[Dict[str, Any]]:
        """生成体脂数据"""
        body_fat_records = []
        current_body_fat = self.initial_body_fat
        
        for i in range(self.days):
            # 从今天往前推算日期，i=0时是今天，i=days-1时是最早的日期
            date = datetime.datetime.now() - datetime.timedelta(days=self.days-i-1)
            # 添加随机波动，体脂率通常变化比体重更小
            trend_factor = -0.03 if random.random() > 0.6 else 0.01  # 60%概率减脂，40%概率增脂
            current_body_fat += trend_factor + random.uniform(-self.body_fat_fluctuation, self.body_fat_fluctuation)
            current_body_fat = round(max(5, min(35, current_body_fat)), 1)  # 确保体脂率在合理范围内
            
            # 体脂率测量通常不是每天进行的
            if random.random() > 0:  # 100%概率有记录
                body_fat_records.append({
                    "date": self._format_date(date),
                    "bodyFatPercentage": current_body_fat
                })
        
        return body_fat_records
    
    def generate_workout_data(self) -> Dict[str, List[Dict[str, Any]]]:
        """生成训练数据"""
        workout_data = {}
        
        for i in range(self.days):
            # 从今天往前推算日期，i=0时是今天，i=days-1时是最早的日期
            date = datetime.datetime.now() - datetime.timedelta(days=self.days-i-1)
            date_key = self._format_date(date)
            
            # 一周中某些天可能没有训练
            if random.random() > 0:  # 100%概率有训练
                # 每天1-4个训练项目
                daily_workouts = []
                workout_count = random.randint(1, 4)
                selected_workouts = random.sample(self.workout_templates, workout_count)
                
                for workout in selected_workouts:
                    # 根据日期和名称创建一个稳定的随机种子，以确保同一天的同一练习具有相同的完成状态
                    random.seed(f"{date_key}_{workout['name']}")
                    is_completed = random.random() > 0.4  # 60%概率已完成
                    random.seed()  # 重置随机种子
                    
                    daily_workouts.append({
                        "date": self._format_date_time(date),
                        "name": workout["name"],
                        "sets": workout["sets"],
                        "isCompleted": is_completed
                    })
                
                if daily_workouts:
                    workout_data[date_key] = daily_workouts
        
        return workout_data
    
    def generate_nutrition_data(self) -> List[Dict[str, Any]]:
        """生成营养数据 - 完全符合Flutter应用MealEntry导入要求的格式"""
        nutrition_data = []
        
        for i in range(self.days):
            # 从今天往前推算日期，i=0时是今天，i=days-1时是最早的日期
            date = datetime.datetime.now() - datetime.timedelta(days=self.days-i-1)
            
            # 决定每天记录的餐食数量（1-4，确保每天至少有一些数据）
            meal_count = random.randint(1, len(self.meal_templates))
            
            daily_meals = []
            total_calories = 0
            
            # 选择餐食并添加一些随机性
            selected_meals = random.sample(self.meal_templates, meal_count)
            for meal in selected_meals:
                # 为每餐添加一些随机变化（±20%）
                calories_variation = random.uniform(0.8, 1.2)
                actual_calories = int(meal["calories"] * calories_variation)
                
                # 为每个食物创建单独的meal条目，完全符合Flutter MealEntry格式
                # Flutter导入时会为每个foods项目创建一个独立的MealEntry
                for food in meal["foods"]:
                    # 为每个食物分配合理的热量比例
                    food_calories = actual_calories // len(meal["foods"])
                    # 如果是最后一个食物，加上剩余的热量
                    if food == meal["foods"][-1]:
                        food_calories += actual_calories % len(meal["foods"])
                    
                    # 关键修改：每个food条目生成单独的meal记录
                    # Flutter导入逻辑会为每个foods列表项创建一个MealEntry
                    daily_meals.append({
                        "name": meal["name"],  # 餐食类型（早餐、午餐等） -> mealType
                        "foods": [food],       # 单个食物数组 -> name (取第一个)
                        "calories": food_calories  # 该食物的热量 -> calories
                        # amount 和 timestamp 将由导入逻辑自动填充
                    })
                    total_calories += food_calories
            
            # 生成合理的卡路里消耗和目标
            calorie_burned = random.randint(300, 600)  # 更合理的消耗范围
            calorie_goal = random.randint(1800, 2200)
            
            nutrition_entry = {
                "date": self._format_date(date),
                "calorieIntake": total_calories,
                "caloriesBurned": calorie_burned,
                "calorieGoal": calorie_goal,
                "meals": daily_meals
            }
            
            nutrition_data.append(nutrition_entry)
        
        return nutrition_data
    
    def validate_export_data(self, export_data: Dict[str, Any]) -> bool:
        """验证导出数据的格式是否正确"""
        try:
            # 检查必要的顶级字段
            if not all(key in export_data for key in ['version', 'exportDate', 'data']):
                print("错误: 缺少必要的顶级字段")
                return False
            
            data = export_data['data']
            if not isinstance(data, dict):
                print("错误: data字段必须是字典")
                return False
            
            # 检查数据部分的必要字段
            required_fields = ['weights', 'bodyFat', 'workouts', 'nutrition', 'userSettings']
            if not all(field in data for field in required_fields):
                print(f"错误: data部分缺少必要字段: {required_fields}")
                return False
            
            # 验证体重数据
            weights = data['weights']
            if not isinstance(weights, list):
                print("错误: weights必须是列表")
                return False
            
            for weight in weights:
                if not all(key in weight for key in ['date', 'weight']):
                    print("错误: weight记录缺少必要字段")
                    return False
                if not isinstance(weight['weight'], (int, float)):
                    print("错误: weight值必须是数字")
                    return False
            
            # 验证体脂数据
            body_fat = data['bodyFat']
            if not isinstance(body_fat, list):
                print("错误: bodyFat必须是列表")
                return False
            
            for bf in body_fat:
                if not all(key in bf for key in ['date', 'bodyFatPercentage']):
                    print("错误: bodyFat记录缺少必要字段")
                    return False
                if not isinstance(bf['bodyFatPercentage'], (int, float)):
                    print("错误: bodyFatPercentage值必须是数字")
                    return False
            
            # 验证训练数据
            workouts = data['workouts']
            if not isinstance(workouts, dict):
                print("错误: workouts必须是字典")
                return False
            
            for date_key, daily_workouts in workouts.items():
                if not isinstance(daily_workouts, list):
                    print(f"错误: {date_key}的训练记录必须是列表")
                    return False
                
                for workout in daily_workouts:
                    required_workout_fields = ['date', 'name', 'sets', 'isCompleted']
                    if not all(key in workout for key in required_workout_fields):
                        print(f"错误: 训练记录缺少必要字段: {required_workout_fields}")
                        return False
                    if not isinstance(workout['sets'], int):
                        print("错误: sets值必须是整数")
                        return False
                    if not isinstance(workout['isCompleted'], bool):
                        print("错误: isCompleted值必须是布尔值")
                        return False
            
            # 验证营养数据
            nutrition = data['nutrition']
            if not isinstance(nutrition, list):
                print("错误: nutrition必须是列表")
                return False
            
            for entry in nutrition:
                required_nutrition_fields = ['date', 'calorieIntake', 'caloriesBurned', 'calorieGoal', 'meals']
                if not all(key in entry for key in required_nutrition_fields):
                    print(f"错误: 营养记录缺少必要字段: {required_nutrition_fields}")
                    return False
                
                for field in ['calorieIntake', 'caloriesBurned', 'calorieGoal']:
                    if not isinstance(entry[field], (int, float)):
                        print(f"错误: {field}值必须是数字")
                        return False
                
                if not isinstance(entry['meals'], list):
                    print("错误: meals必须是列表")
                    return False
                
                for meal in entry['meals']:
                    required_meal_fields = ['name', 'foods', 'calories']
                    if not all(key in meal for key in required_meal_fields):
                        print(f"错误: meal记录缺少必要字段: {required_meal_fields}")
                        return False
                    if not isinstance(meal['foods'], list):
                        print("错误: foods必须是列表")
                        return False
                    if not isinstance(meal['calories'], (int, float)):
                        print("错误: calories值必须是数字")
                        return False
            
            # 验证用户设置
            user_settings = data['userSettings']
            if not isinstance(user_settings, dict):
                print("错误: userSettings必须是字典")
                return False
            
            print("✓ 数据验证通过")
            return True
            
        except Exception as e:
            print(f"验证过程中出错: {e}")
            return False
    
    def generate_demo_data(self) -> Dict[str, Any]:
        """生成完整的演示数据"""
        # 生成各类数据
        weights = self.generate_weight_data()
        body_fat = self.generate_body_fat_data()
        workouts = self.generate_workout_data()
        nutrition = self.generate_nutrition_data()
        
        # 用户设置（基本信息）
        if self.english_names:
            user_settings = {
                "name": "Demo User",
                "age": 25,
                "height": 175,
                "gender": "male",
                "activityLevel": "moderate",
                "fitnessGoal": "lose_weight"
            }
        else:
            user_settings = {
                "name": "演示用户",
                "age": 25,
                "height": 175,
                "gender": "male",
                "activityLevel": "moderate",
                "fitnessGoal": "lose_weight"
            }
        
        # 组装完整的导出数据结构
        export_data = {
            "version": "1.0",
            "exportDate": datetime.datetime.now().isoformat(),
            "data": {
                "weights": weights,
                "bodyFat": body_fat,
                "workouts": workouts,
                "nutrition": nutrition,
                "userSettings": user_settings
            }
        }
        
        return export_data

def main():
    parser = argparse.ArgumentParser(description='生成健身应用演示数据')
    parser.add_argument('--days', type=int, default=90, help='生成数据的天数 (默认: 90)')
    parser.add_argument('--output', type=str, default='fitness_demo_data.json', help='输出文件名 (默认: fitness_demo_data.json)')
    parser.add_argument('--initial-weight', type=float, default=70.0, help='初始体重 (kg, 默认: 70.0)')
    parser.add_argument('--initial-body-fat', type=float, default=18.0, help='初始体脂率 (%, 默认: 18.0)')
    parser.add_argument('--validate', action='store_true', help='验证生成的数据格式')
    parser.add_argument('--english', action='store_true', help='使用英文名称生成数据')
    
    args = parser.parse_args()
    
    language_info = "英文" if args.english else "中文"
    print(f"正在生成 {args.days} 天的健身演示数据（{language_info}版本）...")
    print(f"初始体重: {args.initial_weight} kg")
    print(f"初始体脂率: {args.initial_body_fat}%")
    
    # 创建生成器并生成数据
    generator = FitnessDataGenerator(
        days=args.days,
        initial_weight=args.initial_weight,
        initial_body_fat=args.initial_body_fat,
        english_names=args.english
    )
    
    demo_data = generator.generate_demo_data()
    
    # 保存到文件
    with open(args.output, 'w', encoding='utf-8') as f:
        json.dump(demo_data, f, indent=2, ensure_ascii=False)
    
    print(f"✓ 数据已保存到 {args.output}")
    
    # 数据统计
    data = demo_data['data']
    print(f"\n数据统计:")
    print(f"- 体重记录: {len(data['weights'])} 条")
    print(f"- 体脂记录: {len(data['bodyFat'])} 条")
    print(f"- 训练记录: {len(data['workouts'])} 天")
    print(f"- 营养记录: {len(data['nutrition'])} 天")
    
    # 显示日期范围
    if data['weights']:
        dates = [w['date'] for w in data['weights']]
        dates.sort()
        print(f"- 数据日期范围: {dates[0]} 到 {dates[-1]}")
    
    # 验证数据格式
    if args.validate:
        print(f"\n正在验证数据格式...")
        is_valid = generator.validate_export_data(demo_data)
        if is_valid:
            print("✓ 数据格式验证通过，可以导入应用")
        else:
            print("✗ 数据格式验证失败")
            return 1
    
    print(f"\n演示数据生成完成！")
    print(f"可以使用 '{args.output}' 文件在应用中测试数据导入功能。")
    
    return 0

if __name__ == '__main__':
    exit(main())
