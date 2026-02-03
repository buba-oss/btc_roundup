class MonthlySummary {
  final int month;               // 1-12, non-nullable
  final int totalSats;           // non-nullable
  final int year;                // FIX: Made non-nullable (or remove required if nullable)
  final double? totalRoundUp;    // nullable
  final int? transactionCount;   // nullable

  MonthlySummary({
    required this.year,          // Keep required since year should always exist
    required this.totalSats,
    required this.month,
    this.totalRoundUp,           // FIX: Remove required for nullable
    this.transactionCount,       // FIX: Remove required for nullable
  }) : assert(month >= 1 && month <= 12, 'Month must be 1-12');

  String get monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[month - 1]} $year';
  }
}
