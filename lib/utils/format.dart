import 'package:intl/intl.dart';

/// Shared display helpers.

final NumberFormat _thousands = NumberFormat('#,##0.##', 'en');

/// Formats a number with thousands separators, e.g. 5000000 -> "5,000,000"
/// and 656859.5 -> "656,859.5". Trailing ".00" is dropped.
String formatAmount(num value) => _thousands.format(value);

/// Same as [formatAmount] but takes a raw string (e.g. an API field or a
/// `toStringAsFixed` result). Returns the input unchanged if it isn't numeric.
String formatAmountString(String? raw) {
  if (raw == null) return '';
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final n = num.tryParse(trimmed.replaceAll(',', ''));
  if (n == null) return raw;
  return _thousands.format(n);
}
