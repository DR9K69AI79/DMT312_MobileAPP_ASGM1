import 'package:intl/intl.dart';

class AppDateUtils {
  // 获取今天的日期字符串（YYYY-MM-DD格式）
  static String getTodayString() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // 获取指定日期的字符串格式
  static String getDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // 解析日期字符串为DateTime对象
  static DateTime parseDate(String dateString) {
    return DateFormat('yyyy-MM-dd').parse(dateString);
  }

  // 获取过去指定天数的日期列表
  static List<String> getPastDates(int days) {
    final today = DateTime.now();
    final dates = <String>[];
    
    for (int i = 0; i < days; i++) {
      final date = today.subtract(Duration(days: i));
      dates.add(getDateString(date));
    }
    
    return dates.reversed.toList(); // 返回正序（最早到最晚）
  }

  // 获取两个日期之间的所有日期
  static List<String> getDateRange(DateTime start, DateTime end) {
    final dates = <String>[];
    var current = start;
    
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      dates.add(getDateString(current));
      current = current.add(const Duration(days: 1));
    }
    
    return dates;
  }

  // 获取指定周数的所有周一日期
  static List<String> getWeekStarts(int weeks) {
    final today = DateTime.now();
    final dates = <String>[];
    
    // 找到本周一
    var monday = today.subtract(Duration(days: today.weekday - 1));
    
    for (int i = 0; i < weeks; i++) {
      dates.add(getDateString(monday.subtract(Duration(days: i * 7))));
    }
    
    return dates.reversed.toList();
  }

  // 格式化显示日期
  static String formatDisplayDate(String dateString) {
    final date = parseDate(dateString);
    return DateFormat('MM/dd').format(date);
  }

  // 格式化显示月份
  static String formatDisplayMonth(String dateString) {
    final date = parseDate(dateString);
    return DateFormat('MM月').format(date);
  }

  // 检查日期是否是今天
  static bool isToday(String dateString) {
    return dateString == getTodayString();
  }

  // 检查日期是否是本周
  static bool isThisWeek(String dateString) {
    final date = parseDate(dateString);
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  // 获取时间范围的显示标签
  static String getTimeRangeLabel(int days) {
    switch (days) {
      case 7:
        return '7 Days';
      case 30:
        return '30 Days';
      case 90:
        return '90 Days';
      case 365:
        return '1 Year';
      default:
        return 'All';
    }
  }
}
