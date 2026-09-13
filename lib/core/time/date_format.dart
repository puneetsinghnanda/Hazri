import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date and time formatting that follows the app language and the device's
/// 12/24-hour setting (PRD §11).
class HazriDates {
  const HazriDates(this.locale, this.use24Hour);

  factory HazriDates.of(BuildContext context) => HazriDates(
    Localizations.localeOf(context).toString(),
    MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? false,
  );

  final String locale;
  final bool use24Hour;

  /// The `intl` locale to use. Punjabi and Hindi date names come from the
  /// Indian forms.
  String get _intlLocale => switch (locale.split('_').first) {
    'pa' => 'pa_IN',
    'hi' => 'hi_IN',
    _ => 'en',
  };

  /// "Friday, 11 September"
  String longDate(DateTime d) => DateFormat('EEEE, d MMMM', _intlLocale).format(d);

  /// "Friday, 11 September 2026"
  String longDateWithYear(DateTime d) => DateFormat('EEEE, d MMMM y', _intlLocale).format(d);

  /// "Fri, 11 Sep"
  String shortDate(DateTime d) => DateFormat('EEE, d MMM', _intlLocale).format(d);

  /// "Sep 2026"
  String monthYear(DateTime d) => DateFormat('MMM y', _intlLocale).format(d);

  /// "SEP"
  String monthAbbrUpper(DateTime d) =>
      DateFormat('MMM', _intlLocale).format(d).toUpperCase();

  /// "Fri"
  String weekdayAbbr(DateTime d) => DateFormat('EEE', _intlLocale).format(d);

  /// "8:00 PM" or "20:00".
  String time(DateTime d) =>
      DateFormat(use24Hour ? 'HH:mm' : 'h:mm a', _intlLocale).format(d);

  /// "8 PM" or "20:00" — the compact form used on the day arc.
  String timeCompact(DateTime d) {
    if (use24Hour) return DateFormat('HH:mm', _intlLocale).format(d);
    return d.minute == 0
        ? DateFormat('h a', _intlLocale).format(d)
        : DateFormat('h:mm a', _intlLocale).format(d);
  }

  /// "2:04" or "1:02:04" — an elapsed duration.
  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final mm = h > 0 ? m.toString().padLeft(2, '0') : m.toString();
    return h > 0
        ? '$h:$mm:${s.toString().padLeft(2, '0')}'
        : '$mm:${s.toString().padLeft(2, '0')}';
  }
}
