import 'package:json_annotation/json_annotation.dart';

part 'nutrition_entry.g.dart';

@JsonSerializable()
class NutritionEntry {
  final DateTime date;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String mealType; // 'breakfast', 'lunch', 'dinner', 'snack'

  NutritionEntry({
    required this.date,
    required this.name,
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    required this.mealType,
  });

  // 复制并修改当前对象的方法
  NutritionEntry copyWith({
    DateTime? date,
    String? name,
    int? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? mealType,
  }) {
    return NutritionEntry(
      date: date ?? this.date,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      mealType: mealType ?? this.mealType,
    );
  }

  // JSON 序列化方法
  factory NutritionEntry.fromJson(Map<String, dynamic> json) => _$NutritionEntryFromJson(json);
  Map<String, dynamic> toJson() => _$NutritionEntryToJson(this);
}
