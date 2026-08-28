String currencySymbol(String currency) {
  switch (currency.toUpperCase()) {
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    default:
      return '₸';
  }
}

String formatNumber(double value, {bool withCents = true}) {
  final negative = value < 0;
  final abs = value.abs();
  final text = abs.toStringAsFixed(2);
  final parts = text.split('.');
  final digits = parts[0];

  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }

  final result = withCents ? '${buffer.toString()},${parts[1]}' : buffer.toString();
  return negative ? '-$result' : result;
}

String formatMoney(double value, String currency, {bool withCents = true}) {
  return '${formatNumber(value, withCents: withCents)} ${currencySymbol(currency)}';
}

String formatCardNumber(String number) {
  final digits = number.replaceAll(RegExp(r'\D'), '');
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && i % 4 == 0) buffer.write(' ');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

String maskCardNumber(String number) {
  final digits = number.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return digits;
  return '•••• ${digits.substring(digits.length - 4)}';
}

String formatDateTime(String raw) {
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final h = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$d.$m.${date.year}, $h:$min';
}

String dayLabel(String raw) {
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(date.year, date.month, date.day);
  final diff = today.difference(that).inDays;
  if (diff == 0) return 'Сегодня';
  if (diff == 1) return 'Вчера';
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d.$m.${date.year}';
}
