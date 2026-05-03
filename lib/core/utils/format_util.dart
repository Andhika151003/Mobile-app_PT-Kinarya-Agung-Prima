import 'package:intl/intl.dart';

class FormatUtil {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  static String formatCurrency(num value) {
    return _currencyFormat.format(value);
  }

  static String formatCompact(num value, {bool isCurrency = false}) {
    if (value >= 1000000000) {
      double result = value / 1000000000;
      return '${isCurrency ? 'Rp ' : ''}${_removeTrailingZeros(result)} M';
    } else if (value >= 1000000) {
      double result = value / 1000000;
      return '${isCurrency ? 'Rp ' : ''}${_removeTrailingZeros(result)} Jt';
    } else if (value >= 1000 && !isCurrency) {
      double result = value / 1000;
      return '${_removeTrailingZeros(result)} Rb';
    }
    
    return isCurrency ? formatCurrency(value) : value.toString();
  }

  static String _removeTrailingZeros(double n) {
    return n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 1).replaceAll('.', ',');
  }
}
