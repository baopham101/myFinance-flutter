import 'package:intl/intl.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

String formatVnd(int amount) => _vnd.format(amount);

/// Compact VND label for tight chart axes, e.g. `10k`, `1,5tr`.
String compactVnd(num value) {
  if (value == 0) return '0';
  final abs = value.abs();
  if (abs >= 1000000) return '${_trim(value / 1000000)}tr';
  if (abs >= 1000) return '${_trim(value / 1000)}k';
  return value.round().toString();
}

String _trim(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

int parseVnd(String input, {bool allowZero = false}) {
  final normalized = input.trim().replaceAll(RegExp(r'[,.\s₫]'), '');
  if (!RegExp(r'^\d+$').hasMatch(normalized)) {
    throw const FormatException('Nhập số tiền nguyên bằng VND.');
  }
  final amount = int.parse(normalized);
  if (amount > 9007199254740991 || (!allowZero && amount <= 0)) {
    throw const FormatException('Số tiền không hợp lệ.');
  }
  return amount;
}
