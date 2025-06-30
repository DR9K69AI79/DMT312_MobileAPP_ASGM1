class BodyFatEntry {
  final int? id;
  final double value; // 体脂率，百分比
  final DateTime date;
  final DateTime? createdAt;

  BodyFatEntry({
    this.id,
    required this.value,
    required this.date,
    this.createdAt,
  });

  // 从数据库 Map 创建 BodyFatEntry 对象
  factory BodyFatEntry.fromMap(Map<String, dynamic> map) {
    return BodyFatEntry(
      id: map['id'] as int?,
      value: (map['percentage'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  // 转换为数据库 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'percentage': value, // 数据库字段名为percentage
      'date': date.toIso8601String().split('T')[0], // 只存储日期部分
      'created_at': (createdAt ?? DateTime.now()).toIso8601String(),
    };
  }

  // 复制并修改当前对象的方法
  BodyFatEntry copyWith({
    int? id,
    DateTime? date,
    double? value,
    DateTime? createdAt,
  }) {
    return BodyFatEntry(
      id: id ?? this.id,
      date: date ?? this.date,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
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
      value: json['value'].toDouble(),
    );
  }

  @override
  String toString() {
    return 'BodyFatEntry(id: $id, value: $value%, date: $date)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BodyFatEntry &&
        other.id == id &&
        other.value == value &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^ value.hashCode ^ date.hashCode;
  }
}
