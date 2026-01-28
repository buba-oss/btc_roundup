class MonthlySummary {
  final int year;
  final int month;
  final double totalRoundUp;
  final int transactionCount;

  MonthlySummary({
    required this.year,
    required this.month,
    required this.totalRoundUp,
    required this.transactionCount,
  });

  String get monthLabel {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[month - 1]} $year';
  }
}
