import 'package:btc_roundup/models/monthly_summary.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static List<MonthlySummary> buildMonthlySummaries(
      List<Map<String, dynamic>> transactions,
      ) {
    final Map<String, MonthlySummary> map = {};

    for (final tx in transactions) {
      final Timestamp timestamp = tx['createdAt'] as Timestamp;
      final DateTime date = timestamp.toDate();
      final double roundUp = (tx['roundUp'] as num?)?.toDouble() ?? 0;
      final int sats = (tx['sats'] as int?) ?? 0;

      final key = '${date.year}-${date.month}';

      if (!map.containsKey(key)) {
        map[key] = MonthlySummary(
          year: date.year,
          month: date.month,
          totalRoundUp: roundUp,
          transactionCount: 1,
          totalSats: sats,
        );
      } else {
        final current = map[key]!;

        map[key] = MonthlySummary(
          year: current.year,
          month: current.month,
          totalRoundUp: (current.totalRoundUp ?? 0) + roundUp,
          transactionCount: (current.transactionCount ?? 0) + 1,
          totalSats: (current.totalSats) + sats,
        );
      }
    }

    final list = map.values.toList();

    // newest month first
    list.sort((a, b) {
      if ((a.year) != (b.year)) return (b.year).compareTo(a.year);
      return b.month.compareTo(a.month);
    });

    return list;
  }
}