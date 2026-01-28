import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/monthly_summary.dart';

class MonthlyBarChart extends StatelessWidget {
  final List<MonthlySummary> summaries;

  const MonthlyBarChart({super.key, required this.summaries});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: summaries
              .map((e) => e.totalRoundUp)
              .reduce((a, b) => a > b ? a : b) *
              1.2,
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= summaries.length) {
                    return const SizedBox.shrink();
                  }
                  final s = summaries[index];
                  return Text('${s.month}/${s.year % 100}');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(summaries.length, (index) {
            final summary = summaries[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: summary.totalRoundUp,
                  width: 18,
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.orange,
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
