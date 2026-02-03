import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/monthly_summary.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MonthlySummary> summaries;
  final void Function(int year, int month)? onMonthSelected;

  const MonthlyBarChart({
    super.key,
    required this.summaries,
    this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Line 24 - Remove ?? 0 if totalSats is non-nullable
    // If totalSats CAN be null, keep the null check but fix the logic
    final maxY = summaries
        .map((e) => e.totalSats.toDouble())  // Remove ?? 0 if non-nullable
        .fold<double>(0, (prev, curr) => prev > curr ? prev : curr) * 1.2;

    final safeMaxY = maxY <= 0 ? 100.0 : maxY;

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: safeMaxY,
          barTouchData: BarTouchData(
            enabled: onMonthSelected != null,
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              if (!event.isInterestedForInteractions ||
                  response?.spot == null ||
                  onMonthSelected == null) {
                return;
              }

              final index = response!.spot!.touchedBarGroupIndex;
              if (index < 0 || index >= summaries.length) return;

              final summary = summaries[index];
              // Line 50 - Remove ?? if year/month are non-nullable
              onMonthSelected!(summary.year, summary.month);
            },
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value >= 1000000) {
                    return Text('${(value / 1000000).toStringAsFixed(1)}M');
                  } else if (value >= 1000) {
                    return Text('${(value / 1000).toStringAsFixed(1)}K');
                  }
                  return Text(value.toInt().toString());
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= summaries.length) {
                    return const SizedBox.shrink();
                  }
                  final s = summaries[index];
                  // Line 85 - Remove ?? if non-nullable
                  final monthStr = s.month.toString().padLeft(2, '0');
                  final yearStr = s.year % 100;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '$monthStr/$yearStr',
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          barGroups: List.generate(summaries.length, (index) {
            final summary = summaries[index];
            // Line 102 - Remove ?? if non-nullable
            final value = summary.totalSats.toDouble();
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.orange,
                  // Line 114 - Fix deprecated withOpacity
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: safeMaxY,
                    color: Colors.orange.withAlpha((0.1 * 255).round()), // Replace withOpacity
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}