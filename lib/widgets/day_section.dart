import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/round_up_entry.dart';
import '../utils/formatters.dart';

class DaySection extends StatelessWidget {
  final DateTime day;
  final List<RoundUpEntry> entries;
  final bool expanded;
  final VoidCallback onTap;

  const DaySection({
    super.key,
    required this.day,
    required this.entries,
    required this.expanded,
    required this.onTap,
  });
  int get dayTotalSats {
    return entries.fold<int>(
      0,
          (sum, e) => sum + e.amount.round(),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          ListTile(
            title: Text(
              '📅 ${DateFormat('dd MMM yyyy').format(day)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: AnimatedRotation(
              turns: expanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Icon(Icons.expand_more),
            ),
            onTap: onTap,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: entries.map((e) {
                return ListTile(
                  onTap: onTap,
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('dd MMM yyyy').format(day),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        Formatters.formatSats(dayTotalSats),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: dayTotalSats >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  trailing: AnimatedRotation(
                    turns: expanded ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more),
                  ),
                );

              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
