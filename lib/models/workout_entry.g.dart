// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutEntry _$WorkoutEntryFromJson(Map<String, dynamic> json) => WorkoutEntry(
  date: DateTime.parse(json['date'] as String),
  name: json['name'] as String,
  sets: (json['sets'] as num).toInt(),
  isCompleted: json['isCompleted'] as bool? ?? false,
);

Map<String, dynamic> _$WorkoutEntryToJson(WorkoutEntry instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'name': instance.name,
      'sets': instance.sets,
      'isCompleted': instance.isCompleted,
    };
