import 'package:flutter/services.dart';

const int phoneMinLength = 10;
const int phoneMaxLength = 11;

String phoneDigits(String raw) => raw.replaceAll(RegExp(r'\D'), '');

String normalizePhone(String raw) {
  var d = phoneDigits(raw);
  if (d.length == 11 && d[0] == '8') d = '7${d.substring(1)}';
  return d;
}

String _formatWithCode(String d) {
  return '+${d[0]} (${d.substring(1, 4)}) '
      '${d.substring(4, 7)}-${d.substring(7, 9)}-${d.substring(9)}';
}

String _formatPlain(String d) {
  const sizes = <int>[3, 3, 2, 2];

  final buffer = StringBuffer();
  var index = 0;
  var part = 0;

  while (index < d.length) {
    final size = part < sizes.length ? sizes[part] : 2;
    final end = index + size < d.length ? index + size : d.length;

    if (index > 0) buffer.write(part == 1 ? ' ' : '-');
    buffer.write(d.substring(index, end));

    index = end;
    part++;
  }

  return buffer.toString();
}

String formatPhone(String raw) {
  final d = normalizePhone(raw);
  if (d.isEmpty) return '';
  if (d.length == 11 && d[0] == '7') return _formatWithCode(d);
  return _formatPlain(d);
}

String maskPhone(String raw) {
  final d = normalizePhone(raw);

  if (d.length == 11 && d[0] == '7') {
    return '+${d[0]} (${d.substring(1, 4)}) ***-**-${d.substring(9)}';
  }

  if (d.length == 10) {
    return '${d.substring(0, 3)} ***-**-${d.substring(8)}';
  }

  return _formatPlain(d);
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = phoneDigits(newValue.text);

    if (digits.length == 11 && digits[0] == '8') {
      digits = '7${digits.substring(1)}';
    }

    if (digits.length > phoneMaxLength) {
      digits = digits.substring(0, phoneMaxLength);
    }

    final text = formatPhone(digits);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
