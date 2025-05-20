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
}
