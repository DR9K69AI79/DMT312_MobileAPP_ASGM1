class BodyFatEntry {
  final DateTime date;
  final double value; // 体脂率，百分比

  BodyFatEntry({
    required this.date,
    required this.value,
  });

  // 复制并修改当前对象的方法
  BodyFatEntry copyWith({
    DateTime? date,
    double? value,
  }) {
    return BodyFatEntry(
      date: date ?? this.date,
      value: value ?? this.value,
    );
  }

  // JSON序列化
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'value': value,
    };
  }

  // JSON反序列化
  factory BodyFatEntry.fromJson(Map<String, dynamic> json) {
    return BodyFatEntry(
      date: DateTime.parse(json['date']),
      value: json['value']?.toDouble() ?? 0.0,
    );
  }
}
