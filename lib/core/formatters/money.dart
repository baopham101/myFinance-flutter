import 'package:intl/intl.dart';

final _vnd = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

String formatVnd(int amount) => _vnd.format(amount);

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
