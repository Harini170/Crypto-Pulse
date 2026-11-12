import 'package:intl/intl.dart';

import '../../domain/entities/market_options.dart';

/// All number / date formatting in one place.
class Fmt {
  Fmt._();

  static String price(double v) {
    if (v >= 1) return NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(v);
    if (v >= 0.01) return NumberFormat.currency(symbol: '\$', decimalDigits: 4).format(v);
    if (v >= 0.0001) return NumberFormat.currency(symbol: '\$', decimalDigits: 6).format(v);
    return NumberFormat.currency(symbol: '\$', decimalDigits: 8).format(v);
  }

  static String compactUsd(double v) =>
      NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 2).format(v);

  static String compact(double v) => NumberFormat.compact().format(v);

  static String percent(double v, {bool sign = true}) {
    final s = v.toStringAsFixed(2);
    return '${sign && v > 0 ? '+' : ''}$s%';
  }

  static String axisPrice(double v) {
    if (v >= 1000) return NumberFormat.compactCurrency(symbol: '\$', decimalDigits: 1).format(v);
    if (v >= 1) return '\$${v.toStringAsFixed(2)}';
    return '\$${v.toStringAsPrecision(3)}';
  }

  static String chartDate(DateTime d, ChartRange range) {
    switch (range) {
      case ChartRange.d1:
        return DateFormat('HH:mm').format(d);
      case ChartRange.d7:
      case ChartRange.d30:
        return DateFormat('d MMM').format(d);
      case ChartRange.d90:
      case ChartRange.y1:
        return DateFormat('MMM yy').format(d);
    }
  }

  static String tooltipDate(DateTime d, ChartRange range) =>
      range == ChartRange.d1 || range == ChartRange.d7
          ? DateFormat('d MMM, HH:mm').format(d)
          : DateFormat('d MMM yyyy').format(d);
}
