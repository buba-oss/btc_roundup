import 'package:btc_roundup/models/monthly_summary.dart';


class AnalyticsService {
  static List<MonthlySummary> buildMonthlySummaries(
      List<Map<String, dynamic>> transactions,
      ) {
    final Map<String, MonthlySummary> map = {};

    for (final tx in transactions) {
      final DateTime date = tx['createdAt'];
      final double roundUp = (tx['roundUp'] as num).toDouble();

      final key = '${date.year}-${date.month}';

      if (!map.containsKey(key)) {
        map[key] = MonthlySummary(
          year: date.year,
          month: date.month,
          totalRoundUp: roundUp,
          transactionCount: 1,
        );
      } else {
        final current = map[key]!;
        map[key] = MonthlySummary(
          year: current.year,
          month: current.month,
          totalRoundUp: current.totalRoundUp + roundUp,
          transactionCount: current.transactionCount + 1,
        );
      }
    }

    final list = map.values.toList();

    // newest month first
    list.sort((a, b) {
      if (a.year != b.year) return b.year.compareTo(a.year);
      return b.month.compareTo(a.month);
    });

    return list;
  }
}
