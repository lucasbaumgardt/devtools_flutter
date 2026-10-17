import 'package:devtools_flutter/core/result.dart';
import 'package:devtools_flutter/tools/timestamp/timestamp_converter.dart';
import 'package:flutter_test/flutter_test.dart';

// Fixed values only use UTC, so the tests pass in any time zone.
const midnightUtc = 1729123200; // 2024-10-17 00:00:00 UTC

T valueOf<T>(Result<T, String> result) => switch (result) {
  Ok(:final value) => value,
  Err(:final error) => throw StateError(error),
};

bool isError<T>(Result<T, String> result) => result is Err<T, String>;

void main() {
  group('timestamp → date', () {
    test('converts seconds', () {
      final parsed = valueOf(parseTimestamp('$midnightUtc'));
      expect(parsed.unit, TimestampUnit.seconds);
      expect(
        formatDateTime(parsed.milliseconds, Zone.utc),
        '2024-10-17 00:00:00',
      );
      expect(formatIsoUtc(parsed.milliseconds), '2024-10-17T00:00:00.000Z');
    });

    test(
      'converts the example from the spec (it is 13:20 UTC, not midnight)',
      () {
        final parsed = valueOf(parseTimestamp('1729171200'));
        expect(
          formatDateTime(parsed.milliseconds, Zone.utc),
          '2024-10-17 13:20:00',
        );
      },
    );

    test('detects and converts milliseconds', () {
      final parsed = valueOf(parseTimestamp('${midnightUtc}000'));
      expect(parsed.unit, TimestampUnit.milliseconds);
      expect(
        formatDateTime(parsed.milliseconds, Zone.utc),
        '2024-10-17 00:00:00',
      );
    });

    test('respects an explicit unit', () {
      final parsed = valueOf(
        parseTimestamp('$midnightUtc', UnitChoice.milliseconds),
      );
      expect(parsed.milliseconds, midnightUtc);
      expect(parsed.unit, TimestampUnit.milliseconds);
    });

    test('shows milliseconds only when there are any', () {
      final parsed = valueOf(parseTimestamp('$midnightUtc.25'));
      expect(
        formatDateTime(parsed.milliseconds, Zone.utc),
        '2024-10-17 00:00:00.250',
      );
    });

    test('supports dates before 1970', () {
      final parsed = valueOf(parseTimestamp('-86400'));
      expect(
        formatDateTime(parsed.milliseconds, Zone.utc),
        '1969-12-31 00:00:00',
      );
    });

    test('uses 10^11 as the seconds/milliseconds boundary', () {
      expect(detectUnit(99999999999), TimestampUnit.seconds);
      expect(detectUnit(100000000000), TimestampUnit.milliseconds);
    });

    test('rejects invalid and out-of-range input', () {
      for (final input in [
        '',
        'abc',
        '12a',
        '1e9',
        '1,5',
        '99999999999999999999',
      ]) {
        expect(isError(parseTimestamp(input)), isTrue, reason: input);
      }
    });
  });

  group('date → timestamp', () {
    int ms(String text, Zone zone) =>
        valueOf(parseDateTime(text, zone)).milliseconds;

    test('reads date-times in UTC', () {
      expect(ms('2024-10-17 00:00:00', Zone.utc), midnightUtc * 1000);
      expect(ms('2024-10-17', Zone.utc), midnightUtc * 1000);
      expect(ms('2024-10-17T00:00', Zone.utc), midnightUtc * 1000);
      expect(ms('2024-10-17 00:00:00.5', Zone.utc), midnightUtc * 1000 + 500);
    });

    test('reads local date-times consistently with the local formatting', () {
      final local = formatDateTime(midnightUtc * 1000, Zone.local);
      expect(ms(local, Zone.local), midnightUtc * 1000);
    });

    test('uses the offset written in ISO 8601 text', () {
      final parsed = valueOf(parseDateTime('2024-10-17T00:00:00Z', Zone.local));
      expect(parsed.milliseconds, midnightUtc * 1000);
      expect(parsed.explicitZone, isTrue);

      final threeHoursEarlier = (midnightUtc - 3 * 3600) * 1000;
      expect(ms('2024-10-17T00:00:00+03:00', Zone.utc), threeHoursEarlier);
      expect(ms('2024-10-17T00:00:00+0300', Zone.utc), threeHoursEarlier);
    });

    test('keeps years 0–99 literal', () {
      expect(
        formatDateTime(ms('0050-01-01', Zone.utc), Zone.utc),
        '0050-01-01 00:00:00',
      );
    });

    test('rejects dates that do not exist and out-of-range fields', () {
      expect(
        parseDateTime('2024-02-30', Zone.utc),
        isA<Err<ParsedDateTime, String>>().having(
          (e) => e.error,
          'error',
          'Esta data não existe no calendário (ex.: 30 de fevereiro).',
        ),
      );
      expect(isError(parseDateTime('2023-02-29', Zone.utc)), isTrue);
      expect(isError(parseDateTime('2024-02-29', Zone.utc)), isFalse);
      expect(isError(parseDateTime('2024-13-01', Zone.utc)), isTrue);
      expect(isError(parseDateTime('2024-10-17 24:00', Zone.utc)), isTrue);
    });

    test('rejects ambiguous locale formats', () {
      expect(isError(parseDateTime('10/11/2024', Zone.utc)), isTrue);
    });
  });

  group('relative time', () {
    final now = DateTime.utc(2024, 10, 17);
    String relative(Duration offset) =>
        formatRelative(now.add(offset).millisecondsSinceEpoch, now: now);

    test('describes past and future in Portuguese', () {
      expect(relative(Duration.zero), 'agora');
      expect(relative(const Duration(seconds: 30)), 'em 30 segundos');
      expect(relative(const Duration(hours: 2)), 'em 2 horas');
      expect(relative(const Duration(days: -3)), 'há 3 dias');
      expect(relative(const Duration(days: -2 * 365)), 'há 2 anos');
    });

    test('rounds to the natural unit', () {
      expect(relative(const Duration(minutes: 50)), 'em 1 hora');
      expect(relative(const Duration(minutes: 59, seconds: 50)), 'em 1 hora');
      expect(relative(const Duration(days: -400)), 'há 1 ano');
    });
  });

  test('formats the local UTC offset', () {
    expect(
      formatUtcOffset(midnightUtc * 1000),
      matches(r'^UTC[+−]\d{2}:\d{2}$'),
    );
  });
}
