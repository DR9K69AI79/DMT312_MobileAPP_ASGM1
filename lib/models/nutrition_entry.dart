/// 每日营养记录
class DailyNutritionEntry {
  final DateTime date;
  final int calorieIntake;
  final int caloriesBurned;
  final int calorieGoal;
  final List<MealEntry> meals;

  DailyNutritionEntry({
    required this.date,
    required this.calorieIntake,
    required this.caloriesBurned,
    required this.calorieGoal,
    required this.meals,
  });

  // 计算热量盈亏
  int get calorieBalance => calorieIntake - caloriesBurned;

  // 复制并修改当前对象的方法
  DailyNutritionEntry copyWith({
    DateTime? date,
    int? calorieIntake,
    int? caloriesBurned,
    int? calorieGoal,
    List<MealEntry>? meals,
  }) {
    return DailyNutritionEntry(
      date: date ?? this.date,
      calorieIntake: calorieIntake ?? this.calorieIntake,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      meals: meals ?? this.meals,
    );
  }

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'calorieIntake': calorieIntake,
      'caloriesBurned': caloriesBurned,
      'calorieGoal': calorieGoal,
      'meals': meals.map((meal) => meal.toJson()).toList(),
    };
  }

  // JSON反序列化
  factory DailyNutritionEntry.fromJson(Map<String, dynamic> json) {
    return DailyNutritionEntry(
      date: DateTime.parse(json['date']),
      calorieIntake: json['calorieIntake'] ?? 0,
      caloriesBurned: json['caloriesBurned'] ?? 0,
      calorieGoal: json['calorieGoal'] ?? 2000,
      meals: (json['meals'] as List<dynamic>?)
          ?.map((meal) => MealEntry.fromJson(meal))
          .toList() ?? [],
    );
  }
}

/// 单个食物记录
class MealEntry {
  final String mealType; // 早餐、午餐、晚餐、加餐
  final String name;
  final int calories;
  final String amount;
  final DateTime timestamp;

  MealEntry({
    required this.mealType,
    required this.name,
    required this.calories,
    required this.amount,
    required this.timestamp,
  });

  // 复制并修改当前对象的方法
  MealEntry copyWith({
    String? mealType,
    String? name,
    int? calories,
    String? amount,
    DateTime? timestamp,
  }) {
    return MealEntry(
      mealType: mealType ?? this.mealType,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'mealType': mealType,
      'name': name,
      'calories': calories,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // JSON反序列化
  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      mealType: json['mealType'] ?? '',
      name: json['name'] ?? '',
      calories: json['calories'] ?? 0,
      amount: json['amount'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
