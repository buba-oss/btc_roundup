// lib/screens/stats/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Stats'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF8F9FA),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Monthly Chart
            _buildChartCard(),

            const SizedBox(height: 24),

            // Stats Grid
            _buildStatsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Savings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const months = ['J', 'F', 'M', 'A', 'M', 'J'];
                        return Text(months[value.toInt()]);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: [
                  _makeBar(0, 45000),
                  _makeBar(1, 62000),
                  _makeBar(2, 38000),
                  _makeBar(3, 75000),
                  _makeBar(4, 54000),
                  _makeBar(5, 89000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBar(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: const Color(0xFFF7931A),
          width: 16,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Lifetime Sats',
                value: '1.2M',
                subtext: '+12% this month',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Total Round-ups',
                value: '342',
                subtext: 'Since Jan 2024',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Daily Average',
                value: '3,642',
                subtext: 'sats/day',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'Monthly Average',
                value: '54K',
                subtext: 'sats/month',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtext;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: Color(0xFFF7931A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtext,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}