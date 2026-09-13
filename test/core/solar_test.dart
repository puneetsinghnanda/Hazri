import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/time/solar.dart';

/// Reference sunrise/sunset times from the NOAA solar calculator.
///
/// The PRD allows +/- 2 minutes (§1.10 AC).
void main() {
  const tolerance = Duration(minutes: 2);

  ({DateTime? rise, DateTime? set}) local(
    DateTime date,
    double lat,
    double lon,
    int offsetMinutes,
  ) {
    final e = SolarService.events(date: date, latitude: lat, longitude: lon);
    DateTime? shift(DateTime? t) => t?.add(Duration(minutes: offsetMinutes));
    return (rise: shift(e.sunrise), set: shift(e.sunset));
  }

  void expectNear(DateTime? actual, String expected, {required DateTime on}) {
    expect(actual, isNotNull);
    final parts = expected.split(':');
    final want = DateTime.utc(
      on.year,
      on.month,
      on.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
    final diff = actual!.difference(want).abs();
    expect(
      diff <= tolerance,
      isTrue,
      reason: 'expected ~$expected, got '
          '${actual.hour.toString().padLeft(2, '0')}:'
          '${actual.minute.toString().padLeft(2, '0')} (off by ${diff.inMinutes} min)',
    );
  }

  group('New Delhi (28.6139N, 77.2090E, UTC+5:30)', () {
    test('equinox-ish day matches the design copy (sunrise 6:04)', () {
      final date = DateTime(2026, 9, 12);
      final t = local(date, 28.6139, 77.2090, 330);
      expectNear(t.rise, '06:04', on: date);
      expectNear(t.set, '18:30', on: date);
    });

    test('June solstice', () {
      final date = DateTime(2026, 6, 21);
      final t = local(date, 28.6139, 77.2090, 330);
      expectNear(t.rise, '05:23', on: date);
      expectNear(t.set, '19:21', on: date);
    });

    test('December solstice', () {
      final date = DateTime(2026, 12, 21);
      final t = local(date, 28.6139, 77.2090, 330);
      expectNear(t.rise, '07:09', on: date);
      expectNear(t.set, '17:28', on: date);
    });
  });

  group('London (51.5074N, 0.1278W)', () {
    test('June solstice, BST', () {
      final date = DateTime(2026, 6, 21);
      final t = local(date, 51.5074, -0.1278, 60);
      expectNear(t.rise, '04:43', on: date);
      expectNear(t.set, '21:21', on: date);
    });

    test('December solstice, GMT', () {
      final date = DateTime(2026, 12, 21);
      final t = local(date, 51.5074, -0.1278, 0);
      expectNear(t.rise, '08:03', on: date);
      expectNear(t.set, '15:53', on: date);
    });

    test('the day the clocks go forward still resolves', () {
      final date = DateTime(2026, 3, 29);
      final t = local(date, 51.5074, -0.1278, 60);
      expect(t.rise, isNotNull);
      expect(t.set, isNotNull);
    });
  });

  group('Vancouver (49.2827N, 123.1207W)', () {
    test('June solstice, PDT', () {
      final date = DateTime(2026, 6, 21);
      final t = local(date, 49.2827, -123.1207, -420);
      expectNear(t.rise, '05:06', on: date);
      expectNear(t.set, '21:21', on: date);
    });

    test('December solstice, PST', () {
      final date = DateTime(2026, 12, 21);
      final t = local(date, 49.2827, -123.1207, -480);
      expectNear(t.rise, '08:05', on: date);
      expectNear(t.set, '16:15', on: date);
    });
  });

  test('inside the Arctic circle in midsummer, the sun does not set', () {
    final e = SolarService.events(
      date: DateTime(2026, 6, 21),
      latitude: 78.22,
      longitude: 15.65,
    );
    expect(e.sunrise, isNull);
    expect(e.sunset, isNull);
    expect(e.solarNoon, isNotNull);
  });

  group('roundToNearestMinutes', () {
    test('rounds down below the halfway point', () {
      final t = roundToNearestMinutes(DateTime(2026, 9, 12, 6, 4), 5);
      expect(t.hour, 6);
      expect(t.minute, 5);
    });

    test('rounds to the nearest five minutes', () {
      expect(roundToNearestMinutes(DateTime(2026, 9, 12, 6, 2), 5).minute, 0);
      expect(roundToNearestMinutes(DateTime(2026, 9, 12, 6, 3), 5).minute, 5);
      expect(roundToNearestMinutes(DateTime(2026, 9, 12, 6, 58), 5).hour, 7);
    });
  });
}
