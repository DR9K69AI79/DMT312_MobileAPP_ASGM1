import 'package:json_annotation/json_annotation.dart';

part 'weight_entry.g.dart';

@JsonSerializable()
class WeightEntry {
  final DateTime date;
  final double value;

  WeightEntry({
    required this.date,
    required this.value,
  });

  // 复制并修改当前对象的方法
  WeightEntry copyWith({
    DateTime? date,
    double? value,
  }) {
    return WeightEntry(
      date: date ?? this.date,
      value: value ?? this.value,
    );
  }

  // JSON 序列化方法
  factory WeightEntry.fromJson(Map<String, dynamic> json) => _$WeightEntryFromJson(json);
  Map<String, dynamic> toJson() => _$WeightEntryToJson(this);
}
