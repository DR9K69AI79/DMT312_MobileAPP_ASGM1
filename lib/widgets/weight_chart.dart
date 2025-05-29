import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../models/body_fat_entry.dart';
import '../services/data_manager.dart';
import '../utils/date_utils.dart';
import 'time_range_selector.dart';

class EnhancedWeightChart extends StatefulWidget {
  final bool showBodyFat;
  final bool showTimeSelector;
  final TimeRange? defaultTimeRange;

  const EnhancedWeightChart({
    super.key,
    this.showBodyFat = true,
    this.showTimeSelector = true,
    this.defaultTimeRange,
  });

  @override
  State<EnhancedWeightChart> createState() => _EnhancedWeightChartState();
}

class _EnhancedWeightChartState extends State<EnhancedWeightChart> {
  TimeRange _selectedRange = TimeRange.week7;
  bool _showBodyFat = true;
  ScrollController? _scrollController;
  
  @override
  void initState() {
    super.initState();
    _showBodyFat = widget.showBodyFat;
    // 如果提供了默认时间范围，使用它，否则使用week7
    _selectedRange = widget.defaultTimeRange ?? TimeRange.week7;
    _scrollController = ScrollController();
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
            Row(
              children: [
                const Text(
                  'Weight Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (widget.showBodyFat)
                  IconButton(
                    icon: Icon(
                      _showBodyFat ? Icons.visibility : Icons.visibility_off,
                      color: Colors.orange,
                    ),
                    onPressed: () {
                      setState(() {
                        _showBodyFat = !_showBodyFat;
                      });
                    },
                    tooltip: _showBodyFat ? 'Hish Body Fat Rate' : 'Show Body Fat Rate',
                  ),
              ],
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
              child: _buildScrollableChart(),
            ),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ),
      ),
    );
  }
  Widget _buildScrollableChart() {
    final dataManager = DataManager();
    final weightData = dataManager.getWeightData(
      days: _selectedRange.days == -1 ? null : _selectedRange.days,
    );

    debugPrint('WeightChart: Getting weight data - entries: ${weightData.length}');
    debugPrint('WeightChart: Weight data keys: ${weightData.keys.toList()}');

    if (weightData.isEmpty) {
      return const Center(
        child: Text(
          'No Data',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // 计算合适的宽度：确保有足够的空间显示所有数据点
    final minWidth = MediaQuery.of(context).size.width - 64;
    final dataWidth = weightData.length * 50.0; // 给每个数据点更多空间
    final chartWidth = math.max(minWidth, dataWidth);

    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      reverse: true, // 这样最新数据会在右侧
      child: SizedBox(
        width: chartWidth,
        height: 250,
        child: _buildChart(),
      ),
    );
  }

  Widget _buildChart() {
    final dataManager = DataManager();
    final weightData = dataManager.getWeightData(
      days: _selectedRange.days == -1 ? null : _selectedRange.days,
    );
    final bodyFatData = widget.showBodyFat && _showBodyFat
        ? dataManager.getBodyFatData(
            days: _selectedRange.days == -1 ? null : _selectedRange.days,
          )
        : <String, BodyFatEntry>{};

    if (weightData.isEmpty) {
      return const Center(
        child: Text(
          'No Data',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      );
    }

    // 准备数据点
    final weightSpots = <FlSpot>[];
    final bodyFatSpots = <FlSpot>[];
    final dates = weightData.keys.toList()..sort();

    double minWeight = double.infinity;
    double maxWeight = double.negativeInfinity;
    double minBodyFat = double.infinity;
    double maxBodyFat = double.negativeInfinity;

    // 首先计算体重范围
    for (int i = 0; i < dates.length; i++) {
      final date = dates[i];
      final weightEntry = weightData[date];
      if (weightEntry != null) {
        weightSpots.add(FlSpot(i.toDouble(), weightEntry.value));
        minWeight = math.min(minWeight, weightEntry.value);
        maxWeight = math.max(maxWeight, weightEntry.value);
      }
    }

    // 确保有有效的体重范围
    if (minWeight == double.infinity || maxWeight == double.negativeInfinity) {
      minWeight = 60.0;
      maxWeight = 80.0;
    } else if (minWeight == maxWeight) {
      // 如果只有一个数据点，创建一个小范围
      minWeight -= 5;
      maxWeight += 5;
    }

    // 然后处理体脂率数据
    if (_showBodyFat && bodyFatData.isNotEmpty) {
      for (int i = 0; i < dates.length; i++) {
        final date = dates[i];
        if (bodyFatData.containsKey(date)) {
          final bodyFatEntry = bodyFatData[date];
          if (bodyFatEntry != null) {
            // 将体脂率数据按比例映射到体重范围
            final scaledBodyFat = minWeight + (bodyFatEntry.value / 100) * (maxWeight - minWeight);
            bodyFatSpots.add(FlSpot(i.toDouble(), scaledBodyFat));
            minBodyFat = math.min(minBodyFat, bodyFatEntry.value);
            maxBodyFat = math.max(maxBodyFat, bodyFatEntry.value);
          }
        }
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: _showBodyFat && bodyFatSpots.isNotEmpty
              ? AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 5,
                    getTitlesWidget: (value, meta) {
                      // 将体重范围值映射回体脂率百分比
                      final bodyFatValue = ((value - minWeight) / (maxWeight - minWeight)) * 100;
                      if (bodyFatValue >= 0 && bodyFatValue <= 100) {
                        return Text(
                          '${bodyFatValue.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                          ),
                        );
                      }
                      return const Text('');
                    },
                  ),
                )
              : const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: dates.length > 10 ? (dates.length / 5).ceil().toDouble() : 1,
              getTitlesWidget: (double value, TitleMeta meta) {
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
              interval: 5,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '${value.toInt()}kg',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        minX: 0,
        maxX: (dates.length - 1).toDouble(),
        minY: minWeight - 2,
        maxY: maxWeight + 2,
        lineBarsData: [
          // 体重线
          LineChartBarData(
            spots: weightSpots,
            isCurved: true,
            gradient: const LinearGradient(
              colors: [Colors.blueAccent, Colors.blue],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blue,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.3),
                  Colors.blue.withOpacity(0.1),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // 体脂率线
          if (_showBodyFat && bodyFatSpots.isNotEmpty)
            LineChartBarData(
              spots: bodyFatSpots,
              isCurved: true,
              gradient: const LinearGradient(
                colors: [Colors.orangeAccent, Colors.orange],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.orange,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(Colors.blue, 'Weight (kg)'),
        if (_showBodyFat)
          _buildLegendItem(Colors.orange, 'Body Fat Rate (%)'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
