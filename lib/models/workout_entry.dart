import 'package:json_annotation/json_annotation.dart';

part 'workout_entry.g.dart';

@JsonSerializable()
class WorkoutEntry {
  final DateTime date;
  final String name;
  final int sets;
  final bool isCompleted;

  WorkoutEntry({
    required this.date,
    required this.name,
    required this.sets,
    this.isCompleted = false,
  });

  // 复制并修改当前对象的方法
  WorkoutEntry copyWith({
    DateTime? date,
    String? name,
    int? sets,
    bool? isCompleted,
  }) {
    return WorkoutEntry(
      date: date ?? this.date,
      name: name ?? this.name,
      sets: sets ?? this.sets,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // JSON 序列化方法
  factory WorkoutEntry.fromJson(Map<String, dynamic> json) => _$WorkoutEntryFromJson(json);
  Map<String, dynamic> toJson() => _$WorkoutEntryToJson(this);
}
