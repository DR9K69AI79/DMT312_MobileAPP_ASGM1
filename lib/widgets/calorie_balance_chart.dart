import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/data_manager.dart';
import '../utils/date_utils.dart';
import 'time_range_selector.dart';

class CalorieBalanceChart extends StatefulWidget {
  final bool showTimeSelector;

  const CalorieBalanceChart({
    super.key,
    this.showTimeSelector = true,
  });

  @override
  State<CalorieBalanceChart> createState() => _CalorieBalanceChartState();
}

class _CalorieBalanceChartState extends State<CalorieBalanceChart> {
  TimeRange _selectedRange = TimeRange.week7;

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
              '热量盈亏',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.showTimeSelector) ...[
              const SizedBox(height: 8),
              TimeRangeSelector(
                selectedRange: _selectedRange,
                onSelectionChanged: (range) {
                  setState(() {
                    _selectedRange = range;
                  });
                },
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: _buildChart(),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
            const SizedBox(height: 8),
            _buildSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    final dataManager = DataManager();
    final nutritionData = dataManager.getNutritionData(
      days: _selectedRange.days == -1 ? null : _selectedRange.days,
    );

    if (nutritionData.isEmpty) {
      return const Center(
        child: Text(
          '暂无数据',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    final dates = nutritionData.keys.toList()..sort();
    final bars = <BarChartGroupData>[];
    
    double maxValue = 0;
    double minValue = 0;

    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final entry = nutritionData[date];
      
      if (entry != null) {        final intake = entry.calorieIntake.toDouble();
        final burned = entry.caloriesBurned.toDouble();
        final target = entry.calorieGoal.toDouble();
        final balance = intake - burned; // 正值表示盈余，负值表示亏损
        final targetBalance = target - burned; // 目标盈亏

        maxValue = [maxValue, intake, burned, balance, targetBalance].reduce((a, b) => a > b ? a : b);
        minValue = [minValue, balance, targetBalance].reduce((a, b) => a < b ? a : b);

        bars.add(
          BarChartGroupData(
            x: i,
            barRods: [
              // 摄入热量
              BarChartRodData(
                toY: intake,
                color: Colors.green,
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              // 消耗热量（负值显示）
              BarChartRodData(
                toY: -burned,
                color: Colors.red,
                width: 8,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
              ),
              // 净盈亏
              BarChartRodData(
                toY: balance,
                color: balance >= 0 ? Colors.orange : Colors.purple,
                width: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        );
      }
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue + 200,
        minY: minValue - 200,
        groupsSpace: 12,
        barGroups: bars,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 500,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: value == 0 ? Colors.black54 : Colors.grey[300]!,
              strokeWidth: value == 0 ? 2 : 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index >= 0 && index < dates.length) {
                  return Text(
                    AppDateUtils.formatDisplayDate(dates[index]),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 500,
              reservedSize: 50,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = dates[group.x];
              final entry = nutritionData[date];
              if (entry == null) return null;

              String label;
              String value;
                switch (rodIndex) {
                case 0:
                  label = '摄入';
                  value = '${entry.calorieIntake.toInt()} kcal';
                  break;
                case 1:
                  label = '消耗';
                  value = '${entry.caloriesBurned.toInt()} kcal';
                  break;
                case 2:
                  label = '净盈亏';
                  final balance = entry.calorieIntake - entry.caloriesBurned;
                  value = '${balance > 0 ? '+' : ''}${balance.toInt()} kcal';
                  break;
                default:
                  return null;
              }

              return BarTooltipItem(
                '$label\n$value',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(Colors.green, '摄入'),
        _buildLegendItem(Colors.red, '消耗'),
        _buildLegendItem(Colors.orange, '盈余'),
        _buildLegendItem(Colors.purple, '亏损'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSummary() {
    final dataManager = DataManager();
    final nutritionData = dataManager.getNutritionData(
      days: _selectedRange.days == -1 ? null : _selectedRange.days,
    );

    if (nutritionData.isEmpty) {
      return const SizedBox.shrink();
    }

    double totalIntake = 0;
    double totalBurned = 0;
    int daysWithData = 0;    for (final entry in nutritionData.values) {
      totalIntake += entry.calorieIntake;
      totalBurned += entry.caloriesBurned;
      daysWithData++;
    }

    final totalBalance = totalIntake - totalBurned;
    final avgIntake = totalIntake / daysWithData;
    final avgBurned = totalBurned / daysWithData;

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
                '总盈亏: ${totalBalance > 0 ? '+' : ''}${totalBalance.toInt()} kcal',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: totalBalance >= 0 ? Colors.orange : Colors.purple,
                ),
              ),
              Text(
                '记录天数: $daysWithData 天',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '平均摄入: ${avgIntake.toInt()} kcal/天',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
              Text(
                '平均消耗: ${avgBurned.toInt()} kcal/天',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
