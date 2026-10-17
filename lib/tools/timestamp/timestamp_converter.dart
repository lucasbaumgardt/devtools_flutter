import '../../core/result.dart';

enum Zone { local, utc }

enum TimestampUnit {
  seconds('segundos'),
  milliseconds('milissegundos');

  const TimestampUnit(this.label);

  final String label;
}

enum UnitChoice { auto, seconds, milliseconds }

/// Largest distance from the epoch a DateTime can represent.
const _maxMilliseconds = 8.64e15;

/// In "auto" mode, values from 100 billion up are read as milliseconds: as
/// seconds they would be past the year 5000, as milliseconds they are 1973+.
const millisecondsThreshold = 1e11;

TimestampUnit detectUnit(num value) => value.abs() >= millisecondsThreshold
    ? TimestampUnit.milliseconds
    : TimestampUnit.seconds;

class ParsedTimestamp {
  const ParsedTimestamp(this.milliseconds, this.unit);

  /// Milliseconds since the Unix epoch.
  final int milliseconds;
  final TimestampUnit unit;
}

final _numberPattern = RegExp(r'^-?\d+(\.\d+)?$');

Result<ParsedTimestamp, String> parseTimestamp(
  String input, [
  UnitChoice choice = UnitChoice.auto,
]) {
  final text = input.trim();
  if (!_numberPattern.hasMatch(text)) {
    return const Err(
      'Use apenas números, como 1729171200 (segundos) ou 1729171200000 (milissegundos).',
    );
  }
  final value = num.parse(text);
  final unit = switch (choice) {
    UnitChoice.auto => detectUnit(value),
    UnitChoice.seconds => TimestampUnit.seconds,
    UnitChoice.milliseconds => TimestampUnit.milliseconds,
  };
  final asMilliseconds = unit == TimestampUnit.seconds
      ? value.toDouble() * 1000
      : value.toDouble();
  if (!asMilliseconds.isFinite || asMilliseconds.abs() > _maxMilliseconds) {
    return const Err(
      'Fora do intervalo de datas suportado (até ±275 mil anos a partir de 1970).',
    );
  }
  return Ok(ParsedTimestamp(asMilliseconds.round(), unit));
}

DateTime _dateOf(int milliseconds, Zone zone) =>
    DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: zone == Zone.utc);

String _pad(int value, [int width = 2]) => value.toString().padLeft(width, '0');

/// "YYYY-MM-DD HH:mm:ss", plus ".SSS" when there are milliseconds.
String formatDateTime(int milliseconds, Zone zone) {
  final d = _dateOf(milliseconds, zone);
  final year = d.year >= 0 && d.year <= 9999 ? _pad(d.year, 4) : '${d.year}';
  final time = '${_pad(d.hour)}:${_pad(d.minute)}:${_pad(d.second)}';
  final fraction = d.millisecond == 0 ? '' : '.${_pad(d.millisecond, 3)}';
  return '$year-${_pad(d.month)}-${_pad(d.day)} $time$fraction';
}

String formatIsoUtc(int milliseconds) =>
    _dateOf(milliseconds, Zone.utc).toIso8601String();

int toUnixSeconds(int milliseconds) => (milliseconds / 1000).floor();

/// Offset of the device time zone at that instant, e.g. "UTC−03:00".
String formatUtcOffset(int milliseconds) {
  final offset = _dateOf(milliseconds, Zone.local).timeZoneOffset.inMinutes;
  final sign = offset < 0 ? '−' : '+';
  final minutes = offset.abs();
  return 'UTC$sign${_pad(minutes ~/ 60)}:${_pad(minutes % 60)}';
}

const _second = 1000;
const _minute = 60 * _second;
const _hour = 60 * _minute;
const _day = 24 * _hour;

// (singular, plural, unit size, use it below this distance). The thresholds
// round naturally: 50 minutes reads "em 1 hora", not "em 50 minutos".
const _relativeSteps = [
  ('segundo', 'segundos', _second, 45 * _second),
  ('minuto', 'minutos', _minute, 45 * _minute),
  ('hora', 'horas', _hour, 22 * _hour),
  ('dia', 'dias', _day, 26 * _day),
  ('mês', 'meses', 30 * _day, 320 * _day),
  ('ano', 'anos', 365 * _day, double.infinity),
];

/// "há 2 anos", "em 3 horas", "agora"…
String formatRelative(int milliseconds, {DateTime? now}) {
  final diff = milliseconds - (now ?? DateTime.now()).millisecondsSinceEpoch;
  final (singular, plural, size, _) = _relativeSteps.firstWhere(
    (step) => diff.abs() < step.$4,
  );
  final count = (diff / size).round();
  if (count == 0) return 'agora';
  final amount = '${count.abs()} ${count.abs() == 1 ? singular : plural}';
  return count < 0 ? 'há $amount' : 'em $amount';
}

final _plainDateTime = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2})(?:\.(\d{1,3}))?)?)?$',
);
final _isoWithZone = RegExp(
  r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2}(?:\.\d{1,6})?)?(?:Z|[+-]\d{2}:?\d{2})$',
  caseSensitive: false,
);

class ParsedDateTime {
  const ParsedDateTime(this.milliseconds, {required this.explicitZone});

  final int milliseconds;

  /// The text carried its own offset (Z, +03:00…), so the zone choice was ignored.
  final bool explicitZone;
}

/// Accepts "YYYY-MM-DD", "YYYY-MM-DD HH:mm[:ss[.SSS]]" (read in the chosen
/// zone) and ISO 8601 with an explicit offset. Locale formats such as
/// 10/11/2024 are rejected on purpose: they mean different dates in Brazil
/// and in the US.
Result<ParsedDateTime, String> parseDateTime(String input, Zone zone) {
  final text = input.trim();

  final match = _plainDateTime.firstMatch(text);
  if (match != null) return _parsePlainDateTime(match, zone);

  if (_isoWithZone.hasMatch(text)) {
    final date = DateTime.tryParse(text);
    if (date != null) {
      return Ok(
        ParsedDateTime(date.millisecondsSinceEpoch, explicitZone: true),
      );
    }
  }
  return const Err(
    'Formato não reconhecido. Use AAAA-MM-DD HH:mm:ss ou ISO 8601 (2024-10-17T00:00:00Z).',
  );
}

Result<ParsedDateTime, String> _parsePlainDateTime(
  RegExpMatch match,
  Zone zone,
) {
  int field(int group) => int.parse(match.group(group) ?? '0');
  final year = field(1);
  final month = field(2);
  final day = field(3);
  final hour = field(4);
  final minute = field(5);
  final second = field(6);
  final millisecond = int.parse((match.group(7) ?? '0').padRight(3, '0'));

  final outOfRange =
      month < 1 ||
      month > 12 ||
      day < 1 ||
      day > 31 ||
      hour > 23 ||
      minute > 59 ||
      second > 59;
  if (outOfRange) {
    return const Err(
      'Valor fora do intervalo: mês 1–12, dia 1–31, hora 0–23, minuto e segundo 0–59.',
    );
  }

  final date = zone == Zone.utc
      ? DateTime.utc(year, month, day, hour, minute, second, millisecond)
      : DateTime(year, month, day, hour, minute, second, millisecond);

  // DateTime silently rolls invalid values over (Feb 30 → Mar 1); detect it.
  if (date.month != month || date.day != day) {
    return const Err(
      'Esta data não existe no calendário (ex.: 30 de fevereiro).',
    );
  }
  if (date.hour != hour || date.minute != minute) {
    return const Err(
      'Este horário não existe no fuso local (início do horário de verão).',
    );
  }
  return Ok(ParsedDateTime(date.millisecondsSinceEpoch, explicitZone: false));
}
