// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrition_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NutritionEntry _$NutritionEntryFromJson(Map<String, dynamic> json) =>
    NutritionEntry(
      date: DateTime.parse(json['date'] as String),
      name: json['name'] as String,
      calories: (json['calories'] as num).toInt(),
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      mealType: json['mealType'] as String,
    );

Map<String, dynamic> _$NutritionEntryToJson(NutritionEntry instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'name': instance.name,
      'calories': instance.calories,
      'protein': instance.protein,
      'carbs': instance.carbs,
      'fat': instance.fat,
      'mealType': instance.mealType,
    };
