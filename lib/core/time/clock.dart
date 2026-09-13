import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps "now" so time-dependent screens can be driven by a fake clock in
/// tests (PRD §6.3).
abstract class Clock {
  DateTime now();

  /// Today as a local calendar date with no time part.
  DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();

  @override
  DateTime today() {
    final n = now();
    return DateTime(n.year, n.month, n.day);
  }
}

/// A clock that stays where it is put.
class FixedClock implements Clock {
  FixedClock(this._now);

  DateTime _now;

  set instant(DateTime value) => _now = value;

  @override
  DateTime now() => _now;

  @override
  DateTime today() => DateTime(_now.year, _now.month, _now.day);
}

final clockProvider = Provider<Clock>((ref) => const SystemClock());

/// `2026-09-12` — the key completions, goals and diary rows are stored under.
String localDateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

DateTime parseLocalDateKey(String key) {
  final parts = key.split('-');
  return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
}

/// `2026-09` — the key grace days are counted per.
String monthKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';
