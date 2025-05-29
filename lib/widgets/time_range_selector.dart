import 'package:flutter/material.dart';

enum TimeRange {
  week7(7, '7 Days'),
  month1(30, '30 Days'),
  month3(90, '90 Days'),
  all(-1, 'All');

  const TimeRange(this.days, this.label);
  final int days;
  final String label;
}

class TimeRangeSelector extends StatelessWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onSelectionChanged;

  const TimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: TimeRange.values.map((range) {
          final isSelected = range == selectedRange;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Material(
                color: isSelected 
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => onSelectionChanged(range),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      range.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// 简化版的时间范围选择器（用于较小的空间）
class CompactTimeRangeSelector extends StatelessWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onSelectionChanged;

  const CompactTimeRangeSelector({
    super.key,
    required this.selectedRange,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimeRange>(
          value: selectedRange,
          onChanged: (TimeRange? newValue) {
            if (newValue != null) {
              onSelectionChanged(newValue);
            }
          },
          items: TimeRange.values.map<DropdownMenuItem<TimeRange>>((TimeRange range) {
            return DropdownMenuItem<TimeRange>(
              value: range,
              child: Text(
                range.label,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[600]),
        ),
      ),
    );
  }
}
