import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// 环形进度指示器组件
class RingProgress extends StatelessWidget {
  final double percent; // 进度百分比 0.0-1.0
  final String label; // 中间显示的文字

  const RingProgress({
    super.key, 
    required this.percent,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SizedBox(
      height: 150,
      width: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 饼图作为环形进度
          PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 50,
              sections: [
                // 已完成部分
                PieChartSectionData(
                  color: colorScheme.primary, 
                  value: percent * 100,
                  title: '',
                  radius: 20,
                ),
                // 未完成部分
                PieChartSectionData(
                  color: Colors.grey.shade300,
                  value: (1 - percent) * 100,
                  title: '',
                  radius: 20,
                )
              ],
            ),
          ),
          // 中心的文字
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(percent * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
