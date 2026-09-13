import 'package:flutter/foundation.dart';

/// One day's line of Gurbani, with its meaning (PRD 1.11).
@immutable
class Vichar {
  const Vichar({
    required this.idx,
    required this.gurmukhi,
    required this.meaningPa,
    required this.meaningEn,
  });

  /// Where this line sits in the cycle.
  final int idx;
  final String gurmukhi;
  final String meaningPa;
  final String meaningEn;

  /// The meaning to show for a UI language.
  ///
  /// Hindi falls back to Punjabi: the dataset carries no Hindi rendering, and
  /// the Punjabi one is far closer for this reader than English would be.
  String meaningIn(String language) => switch (language) {
    'en' => meaningEn.isEmpty ? meaningPa : meaningEn,
    _ => meaningPa,
  };

  /// True when there is an English rendering to show beneath the Punjabi one.
  bool get hasEnglish => meaningEn.isNotEmpty;
}

/// Which line belongs to which day.
abstract final class VicharCycle {
  /// The line for [date], out of [count].
  ///
  /// Round robin on the date itself rather than on a stored cursor: everyone
  /// opening the app on the same day sees the same line, a phone that was off
  /// for a week does not have a backlog to work through, and reinstalling
  /// changes nothing. After [count] days it begins again.
  static int indexFor(DateTime date, int count) {
    if (count <= 0) return 0;
    final days = DateTime.utc(date.year, date.month, date.day)
        .difference(DateTime.utc(1970))
        .inDays;
    return days % count;
  }
}
