/// Small, dependency-free helpers for normalising and presenting API values.
///
/// SourceArena values are not fully typed: prices and percentages can arrive
/// as numbers or strings, and those strings occasionally contain Persian
/// digits and grouping separators. Keeping the conversion rules here makes the
/// model parser and UI agree on one representation.
const _persianDigits = '۰۱۲۳۴۵۶۷۸۹';
const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';
const _englishDigits = '0123456789';

String toEnglishDigits(Object? value) {
  var result = value?.toString() ?? '';
  for (var index = 0; index < 10; index++) {
    result = result
        .replaceAll(_persianDigits[index], _englishDigits[index])
        .replaceAll(_arabicDigits[index], _englishDigits[index]);
  }
  return result;
}

String toPersianDigits(Object? value) {
  var result = toEnglishDigits(value);
  for (var index = 0; index < 10; index++) {
    result = result.replaceAll(_englishDigits[index], _persianDigits[index]);
  }
  return result;
}

/// Returns a trimmed string or [fallback] for null-like API values.
String cleanText(Object? value, {String fallback = ''}) {
  if (value == null) return fallback;
  final result = value
      .toString()
      .replaceAll(RegExp(r'[\u200e\u200f\ufeff]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (result.isEmpty ||
      const {
        'null',
        'none',
        'undefined',
        '-',
        '--',
      }.contains(result.toLowerCase())) {
    return fallback;
  }
  return result;
}

int? parseFlexibleInt(Object? value) {
  if (value == null || value is bool) return null;
  if (value is int) return value;
  if (value is num) return value.isFinite ? value.round() : null;

  final number = _normaliseNumber(value);
  if (number.isEmpty) return null;
  return int.tryParse(number) ?? double.tryParse(number)?.round();
}

double? parseFlexibleDouble(Object? value) {
  if (value == null || value is bool) return null;
  if (value is num) return value.isFinite ? value.toDouble() : null;

  final number = _normaliseNumber(value);
  if (number.isEmpty) return null;
  final parsed = double.tryParse(number);
  return parsed?.isFinite == true ? parsed : null;
}

bool parseFlexibleBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;

  final normalised = toEnglishDigits(value).trim().toLowerCase();
  if (const {
    '1',
    'true',
    'yes',
    'y',
    'on',
    'بله',
    'بلی',
    'بازار',
  }.contains(normalised)) {
    return true;
  }
  if (const {
    '0',
    'false',
    'no',
    'n',
    'off',
    'خیر',
    'نه',
  }.contains(normalised)) {
    return false;
  }
  return fallback;
}

/// Canonicalises `۱۴۰۴-۷-۳` and similar values to `1404/07/03`.
///
/// Returns null for impossible month/day ranges rather than silently sending
/// a malformed query to the API.
String? normalizeJalaliDate(Object? value) {
  final input = toEnglishDigits(value).trim();
  final match = RegExp(
    r'^(\d{3,4})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{1,2})$',
  ).firstMatch(input);
  if (match == null) return null;

  final year = int.tryParse(match.group(1)!);
  final month = int.tryParse(match.group(2)!);
  final day = int.tryParse(match.group(3)!);
  if (year == null ||
      month == null ||
      day == null ||
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31) {
    return null;
  }
  return '${year.toString().padLeft(4, '0')}/'
      '${month.toString().padLeft(2, '0')}/'
      '${day.toString().padLeft(2, '0')}';
}

String formatToman(int? value, {bool persianDigits = true}) {
  if (value == null) return '—';
  final grouped = _groupThousands(value);
  final text = '$grouped تومان';
  return persianDigits ? toPersianDigits(text) : text;
}

String formatCompactToman(int? value, {bool persianDigits = true}) {
  if (value == null) return '—';
  final absolute = value.abs();
  late final String number;
  late final String unit;
  if (absolute >= 1000000000) {
    number = _oneDecimal(value / 1000000000);
    unit = 'میلیارد تومان';
  } else if (absolute >= 1000000) {
    number = _oneDecimal(value / 1000000);
    unit = 'میلیون تومان';
  } else {
    return formatToman(value, persianDigits: persianDigits);
  }
  var text = '$number $unit';
  if (persianDigits) {
    text = toPersianDigits(text).replaceAll('.', '٫');
  }
  return text;
}

String formatPercent(
  double? value, {
  int fractionDigits = 1,
  bool showPlus = true,
  bool persianDigits = true,
}) {
  if (value == null || !value.isFinite) return '—';
  final prefix = showPlus && value > 0 ? '+' : '';
  var text = '$prefix${value.toStringAsFixed(fractionDigits)}%';
  if (persianDigits) {
    text = toPersianDigits(text).replaceAll('.', '٫').replaceAll('%', '٪');
  }
  return text;
}

String _normaliseNumber(Object value) {
  var result = toEnglishDigits(value).trim();
  final isWrappedNegative = result.startsWith('(') && result.endsWith(')');
  result = result
      .replaceAll('−', '-')
      .replaceAll('–', '-')
      .replaceAll('٫', '.')
      .replaceAll(RegExp(r'[,،٬_\s\u00a0\u202f]'), '')
      .replaceAll(RegExp(r'[^0-9eE+\-.]'), '');
  if (isWrappedNegative && !result.startsWith('-')) result = '-$result';
  return result;
}

String _groupThousands(int value) {
  final negative = value < 0;
  final digits = value.abs().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('٬');
    buffer.write(digits[index]);
  }
  return '${negative ? '-' : ''}$buffer';
}

String _oneDecimal(double value) {
  final fixed = value.toStringAsFixed(1);
  return fixed.endsWith('.0') ? fixed.substring(0, fixed.length - 2) : fixed;
}
