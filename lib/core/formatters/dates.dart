import 'package:intl/intl.dart';

final _display = DateFormat('dd/MM/yyyy');

/// Formats an ISO `yyyy-MM-dd` (or full ISO timestamp) date for display,
/// e.g. `2026-11-22` -> `22/11/2026`. Data is only reformatted here; the
/// original ISO value stays untouched for API calls.
String formatDate(String? isoDate) {
  if (isoDate == null || isoDate.isEmpty) return '';
  final raw = isoDate.length > 10 ? isoDate.substring(0, 10) : isoDate;
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return isoDate;
  return _display.format(parsed);
}

/// Short month label used on chart axes, e.g. `T11`.
String formatMonthLabel(DateTime date) => 'T${date.month}';
