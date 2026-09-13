import 'package:flutter/foundation.dart';

/// A date on the Nanakshahi calendar.
@immutable
class NanakshahiDate {
  const NanakshahiDate({
    required this.year,
    required this.monthIdx,
    required this.day,
    required this.monthEn,
    required this.monthPa,
    required this.monthHi,
  });

  final int year;
  final int monthIdx;
  final int day;
  final String monthEn;
  final String monthPa;
  final String monthHi;

  String monthName(String languageCode) => switch (languageCode) {
    'pa' => monthPa,
    'hi' => monthHi,
    _ => monthEn,
  };

  /// "26 Bhadon" — the short label used on rows.
  String label(String languageCode) => '$day ${monthName(languageCode)}';

  /// "26 Bhadon, 558" — the header form.
  String labelWithYear(String languageCode) => '${label(languageCode)}, $year';
}

/// One Sangrand row from the bundled jantri.
@immutable
class NanakshahiMonth {
  const NanakshahiMonth({
    required this.year,
    required this.idx,
    required this.nameEn,
    required this.namePa,
    required this.nameHi,
    required this.start,
    required this.days,
  });

  final int year;
  final int idx;
  final String nameEn;
  final String namePa;
  final String nameHi;
  final DateTime start;
  final int days;

  DateTime get endExclusive => start.add(Duration(days: days));
}

/// Converts Gregorian dates to Nanakshahi ones using only the Sangrand rows
/// that shipped with the app.
///
/// Nothing is extrapolated: a date outside the bundled months returns null so
/// the UI can say the calendar has not been shipped that far rather than show
/// an invented date (PRD 1.14, open decision D8).
class NanakshahiCalendar {
  const NanakshahiCalendar(this.months);

  final List<NanakshahiMonth> months;

  bool get isEmpty => months.isEmpty;

  DateTime? get coveredFrom => months.isEmpty ? null : months.first.start;

  DateTime? get coveredToInclusive => months.isEmpty
      ? null
      : months.last.endExclusive.subtract(const Duration(days: 1));

  NanakshahiDate? dateFor(DateTime gregorian) {
    final d = DateTime(gregorian.year, gregorian.month, gregorian.day);
    for (final m in months) {
      if (!d.isBefore(m.start) && d.isBefore(m.endExclusive)) {
        return NanakshahiDate(
          year: m.year,
          monthIdx: m.idx,
          day: d.difference(m.start).inDays + 1,
          monthEn: m.nameEn,
          monthPa: m.namePa,
          monthHi: m.nameHi,
        );
      }
    }
    return null;
  }

  bool covers(DateTime gregorian) => dateFor(gregorian) != null;
}
