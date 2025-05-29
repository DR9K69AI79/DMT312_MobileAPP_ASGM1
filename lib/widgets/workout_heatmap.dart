import 'package:flutter/material.dart';
import '../services/data_manager.dart';
import '../utils/date_utils.dart';

class WorkoutHeatmap extends StatefulWidget {
  const WorkoutHeatmap({super.key});

  @override
  State<WorkoutHeatmap> createState() => _WorkoutHeatmapState();
}

class _WorkoutHeatmapState extends State<WorkoutHeatmap> {
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    // 延迟滚动到最右侧，等待布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController?.hasClients == true) {
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completion Rate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildHeatmap(),
            const SizedBox(height: 16),
            _buildLegend(),
            const SizedBox(height: 8),
            _buildStatistics(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmap() {
    final dataManager = DataManager();
    final workoutData = dataManager.getWorkoutData(); // 获取所有数据

    // 显示过去12个月的数据
    final endDate = DateTime.now();
    final startDate = DateTime(endDate.year, endDate.month - 11, 1); // 往前12个月的第一天

    final dateList = AppDateUtils.getDateRange(startDate, endDate);

    // 计算每日训练强度
    final Map<String, double> intensityMap = {};
    for (final date in dateList) {
      final dayWorkouts = workoutData[date] ?? [];
      if (dayWorkouts.isEmpty) {
        intensityMap[date] = 0.0;
      } else {
        // 计算当日训练强度：完成的练习数量 / 总练习数量
        final completedCount = dayWorkouts.where((w) => w.isCompleted).length;
        intensityMap[date] = completedCount / dayWorkouts.length;
      }
    }

    return Center(
      child: SizedBox(
        height: 160, // 调整高度适应横向布局
        child: _buildCalendarHeatmap(dateList, intensityMap),
      ),
    );
  }  Widget _buildCalendarHeatmap(List<String> dates, Map<String, double> intensityMap) {
    if (dates.isEmpty) {
      return const Center(
        child: Text(
          'No Data',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 生成连续的周数据，不分月份
    final weekData = _generateWeeklyData(dates);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 星期标签列（固定不滚动）
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // 月份标签位置的占位符
            const SizedBox(height: 24),
            // 星期标签
            ...['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return Container(
                width: 20,
                height: 17,
                alignment: Alignment.centerRight,
                child: Text(
                  day,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              );
            }),
          ],
        ),
        const SizedBox(width: 4),        // 可滚动的月份标签和热力图
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 月份标签行
                _buildMonthLabels(weekData),
                const SizedBox(height: 4),
                // 热力图网格
                _buildHeatmapGrid(weekData, intensityMap),
              ],
            ),
          ),
        ),
      ],
    );  }

  Color _getIntensityColor(double intensity) {
    if (intensity == 0) {
      return Colors.grey[200]!;
    } else if (intensity <= 0.25) {
      return Colors.green[100]!;
    } else if (intensity <= 0.5) {
      return Colors.green[300]!;
    } else if (intensity <= 0.75) {
      return Colors.green[500]!;
    } else {
      return Colors.green[700]!;
    }
  }

  // 生成连续的周数据，不分月份
  List<List<String>> _generateWeeklyData(List<String> dates) {
    if (dates.isEmpty) return [];

    // 排序日期
    final sortedDates = List<String>.from(dates);
    sortedDates.sort((a, b) => AppDateUtils.parseDate(a).compareTo(AppDateUtils.parseDate(b)));

    final firstDate = AppDateUtils.parseDate(sortedDates.first);
    final lastDate = AppDateUtils.parseDate(sortedDates.last);

    // 找到第一周的周一
    final firstMonday = firstDate.subtract(Duration(days: (firstDate.weekday - 1) % 7));
    
    // 计算需要多少周
    final totalDays = lastDate.difference(firstMonday).inDays + 7;
    final totalWeeks = (totalDays / 7).ceil();

    // 初始化周数据
    final weeks = List.generate(totalWeeks, (_) => List<String>.filled(7, ''));

    // 填充实际日期
    for (final dateStr in sortedDates) {
      final date = AppDateUtils.parseDate(dateStr);
      final daysSinceFirstMonday = date.difference(firstMonday).inDays;
      
      if (daysSinceFirstMonday >= 0) {
        final weekIndex = daysSinceFirstMonday ~/ 7;
        final dayIndex = daysSinceFirstMonday % 7;
        
        if (weekIndex < weeks.length) {
          weeks[weekIndex][dayIndex] = dateStr;
        }
      }
    }

    return weeks;
  }

  // 构建月份标签
  Widget _buildMonthLabels(List<List<String>> weekData) {
    final monthLabels = <Widget>[];
    String? currentMonth;
    int currentWeekCount = 0;

    for (int weekIndex = 0; weekIndex < weekData.length; weekIndex++) {
      final week = weekData[weekIndex];
      
      // 找到这一周中第一个非空日期来确定月份
      String? weekMonth;
      for (final dateStr in week) {
        if (dateStr.isNotEmpty) {
          weekMonth = AppDateUtils.formatDisplayMonth(dateStr);
          break;
        }
      }

      if (weekMonth != null && weekMonth != currentMonth) {
        // 添加前一个月的标签（如果有的话）
        if (currentMonth != null && currentWeekCount > 0) {
          monthLabels.add(
            Container(
              width: currentWeekCount * 17.0,
              height: 20,
              alignment: Alignment.centerLeft,
              child: Text(
                currentMonth,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          );
        }
        
        currentMonth = weekMonth;
        currentWeekCount = 1;
      } else {
        currentWeekCount++;
      }
    }

    // 添加最后一个月的标签
    if (currentMonth != null && currentWeekCount > 0) {
      monthLabels.add(
        Container(
          width: currentWeekCount * 17.0,
          height: 20,
          alignment: Alignment.centerLeft,
          child: Text(
            currentMonth,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
      );
    }

    return Row(children: monthLabels);
  }

  // 构建热力图网格
  Widget _buildHeatmapGrid(List<List<String>> weekData, Map<String, double> intensityMap) {
    return Column(
      children: List.generate(7, (weekdayIndex) {
        return Row(
          children: weekData.map((week) {
            if (weekdayIndex < week.length) {
              final dateStr = week[weekdayIndex];

              // 检查日期字符串是否为空
              if (dateStr.isEmpty) {
                return Container(
                  width: 15,
                  height: 15,
                  margin: const EdgeInsets.all(1),
                );
              }

              final intensity = intensityMap[dateStr] ?? 0.0;
              final isToday = AppDateUtils.isToday(dateStr);

              return Container(
                width: 15,
                height: 15,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: _getIntensityColor(intensity),
                  borderRadius: BorderRadius.circular(2),
                  border: isToday ? Border.all(color: Colors.black, width: 1) : null,
                ),
                child: Tooltip(
                  message: '${AppDateUtils.formatDisplayDate(dateStr)}\nCompletion Rate: ${(intensity * 100).toInt()}%',
                  child: const SizedBox(),
                ),
              );
            } else {
              // 空白格子
              return Container(
                width: 15,
                height: 15,
                margin: const EdgeInsets.all(1),
              );
            }
          }).toList(),
        );
      }),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Few',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (index) {
          return Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: BoxDecoration(
              color: _getIntensityColor(index * 0.25),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
        const SizedBox(width: 4),
        const Text(
          'Many',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    final dataManager = DataManager();
    final workoutData = dataManager.getWorkoutData(); // 获取所有数据

    if (workoutData.isEmpty) {
      return const SizedBox.shrink();
    }

    int totalDays = 0;
    int activeDays = 0;
    int totalWorkouts = 0;
    int completedWorkouts = 0;

    for (final entry in workoutData.entries) {
      totalDays++;
      final dayWorkouts = entry.value;

      if (dayWorkouts.isNotEmpty) {
        activeDays++;
        totalWorkouts += dayWorkouts.length;
        completedWorkouts += dayWorkouts.where((w) => w.isCompleted).length;
      }
    }

    final activeRate = totalDays > 0 ? (activeDays / totalDays * 100) : 0;
    final completionRate = totalWorkouts > 0 ? (completedWorkouts / totalWorkouts * 100) : 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Active Days: $activeDays/$totalDays Days',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Active Rate: ${activeRate.toInt()}%',
                style: TextStyle(
                  color: activeRate >= 70 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Training Completed: $completedWorkouts/$totalWorkouts',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                'Completion Rate: ${completionRate.toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: completionRate >= 80 ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
