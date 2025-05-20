import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weight_entry.dart';

class WeightLineChart extends StatelessWidget {
  const WeightLineChart({super.key, required this.data});
  final List<WeightEntry> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('没有体重数据'));
    }

    // 筛选x轴和y轴的最大最小值，以便图表缩放
    final minY = data.map((e) => e.value).reduce((a, b) => a < b ? a : b) - 1;
    final maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b) + 1;
    
    // 转换为毫秒时间戳和体重值的点
    final spots = data.asMap().entries.map((entry) {
      // 使用索引作为x轴，使点均匀分布
      return FlSpot(entry.key.toDouble(), entry.value.value);
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
          ],
          minY: minY,
          maxY: maxY,
          gridData: const FlGridData(
            drawVerticalLine: false,
            drawHorizontalLine: true,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  // 只在数据点处显示日期
                  if (value >= 0 && value < data.length) {
                    final date = data[value.toInt()].date;
                    return Text('${date.month}/${date.day}', 
                      style: const TextStyle(fontSize: 10),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 22,
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 10),
                  );
                },
                reservedSize: 30,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
