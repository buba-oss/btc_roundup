import 'package:flutter/material.dart';
import 'package:btc_roundup/models/monthly_summary.dart';

class MonthlySummaryCard extends StatelessWidget {
  final MonthlySummary summary;

  const MonthlySummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              summary.monthLabel,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Total round-ups: €${summary.totalRoundUp?.toStringAsFixed(2)}'),
            Text('Transactions: ${summary.transactionCount}'),
          ],
        ),
      ),
    );
  }
}


