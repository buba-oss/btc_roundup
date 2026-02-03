import 'package:intl/intl.dart';

class Formatters {
  final euroFormat = NumberFormat.currency(locale: 'de_DE', symbol: '€');
  final satsFormat = NumberFormat.decimalPattern('de_DE');
  // 🇪🇺 Euro formatter (e.g. 1.234,56 €)
  static final NumberFormat _euroFormatter =
  NumberFormat.currency(
    locale: 'de_DE',
    symbol: '€',
    decimalDigits: 2,
  );

  // ₿ Sats formatter (e.g. 12.345 sats)
  static final NumberFormat _satsFormatter =
  NumberFormat.decimalPattern('de_DE');

  static String formatEuro(double value) {
    return _euroFormatter.format(value);
  }

  static String formatSats(int sats) {
    return '${_satsFormatter.format(sats)} sats';
  }
}