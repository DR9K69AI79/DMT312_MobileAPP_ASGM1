# PyTools 数据生成脚本修改总结

## 修改概述

已成功修改 `generate_demo_data_final.py` 脚本，使其生成的数据完全符合 Flutter 应用的导入要求。

## 主要修改内容

### 1. 营养数据格式修改 (关键修改)

**修改前的问题：**
- 每个 meal 包含多个 foods 项目在一个数组中
- Flutter 导入时无法正确解析为独立的 MealEntry

**修改后的改进：**
- 每个 food 项目生成独立的 meal 记录
- 每个 meal 的 foods 数组只包含一个食物项目
- 完全符合 Flutter MealEntry 的结构要求

**修改的具体代码：**
```python
# 为每个食物创建单独的meal条目，完全符合Flutter MealEntry格式
for food in meal["foods"]:
    # 为每个食物分配合理的热量比例
    food_calories = actual_calories // len(meal["foods"])
    # 如果是最后一个食物，加上剩余的热量
    if food == meal["foods"][-1]:
        food_calories += actual_calories % len(meal["foods"])
    
    # 关键修改：每个food条目生成单独的meal记录
    daily_meals.append({
        "name": meal["name"],  # 餐食类型（早餐、午餐等） -> mealType
        "foods": [food],       # 单个食物数组 -> name (取第一个)
        "calories": food_calories  # 该食物的热量 -> calories
        # amount 和 timestamp 将由导入逻辑自动填充
    })
```

## 生成的数据统计

### 365天完整数据集
- **文件名：** `demo_data_365days_flutter_compatible.json`
- **文件大小：** 652,474 字节 (约 637KB)
- **数据范围：** 2024-07-01 到 2025-06-30
- **数据统计：**
  - 体重记录：365 条
  - 体脂记录：365 条
  - 训练记录：365 天，877 个训练项目
  - 营养记录：365 天，2,515 个餐食记录

### 测试数据集
- **文件名：** `demo_data_7days_test.json`
- **数据范围：** 2025-06-24 到 2025-06-30
- **数据统计：**
  - 体重记录：7 条
  - 体脂记录：7 条
  - 训练记录：7 天，18 个训练项目
  - 营养记录：7 天，61 个餐食记录

## 数据格式验证

创建了专门的验证脚本 `validate_data_format.py`，验证要点包括：

### ✓ 顶级结构验证
- version、exportDate、data 字段完整

### ✓ 各类数据格式验证
- 体重数据：date、weight 字段正确
- 体脂数据：date、bodyFatPercentage 字段正确
- 训练数据：date、name、sets、isCompleted 字段正确
- 用户设置：基本信息字段正确

### ✓ 营养数据格式验证（重点）
- 每个营养记录包含：date、calorieIntake、caloriesBurned、calorieGoal、meals
- 每个 meal 包含：name、foods、calories
- **关键验证：每个 meal 的 foods 数组只包含一个食物项目**
- 完全符合 Flutter MealEntry 导入要求

## Flutter 导入兼容性

### 导入映射关系
```
Python JSON → Flutter MealEntry
{
  "name": "早餐",           → mealType
  "foods": ["鸡蛋"],        → name (取 foods[0])
  "calories": 127           → calories
}
```

### 自动填充字段
- `amount`: 由 Flutter 导入逻辑设置为 "1份"
- `timestamp`: 由 Flutter 导入逻辑从 date 字段解析

## 使用方法

### 生成数据
```bash
# 生成365天数据
python generate_demo_data_final.py --days 365 --output demo_data_365days.json --validate

# 生成英文版本数据
python generate_demo_data_final.py --days 90 --english --output demo_data_90days_en.json

# 自定义初始参数
python generate_demo_data_final.py --days 180 --initial-weight 65.0 --initial-body-fat 15.0
```

### 验证数据格式
```bash
python validate_data_format.py demo_data_365days_flutter_compatible.json
```

## 验证结果

✅ **所有验证通过！**
- 数据格式完全符合 Flutter 应用导入要求
- 营养数据结构与 MealEntry 模型完全兼容
- 可以成功导入到 Flutter 应用中进行演示

## 文件清单

1. `generate_demo_data_final.py` - 修改后的主生成脚本
2. `validate_data_format.py` - 新增的格式验证脚本
3. `demo_data_365days_flutter_compatible.json` - 365天演示数据
4. `demo_data_7days_test.json` - 7天测试数据
5. `demo_data_flutter_compatible.json` - 90天演示数据

所有生成的数据文件都已通过完整的格式验证，确保与 Flutter 应用的导入系统完全兼容。
