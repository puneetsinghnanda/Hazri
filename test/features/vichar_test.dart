import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/vichar/domain/vichar.dart';

/// One line a day, the same line for everyone, decided by the date alone.
void main() {
  group('the cycle', () {
    test('advances by one each day and wraps at the end', () {
      final start = DateTime(2026, 9, 13);
      final first = VicharCycle.indexFor(start, 200);
      expect(VicharCycle.indexFor(start.add(const Duration(days: 1)), 200),
          (first + 1) % 200);
      expect(VicharCycle.indexFor(start.add(const Duration(days: 200)), 200), first);
    });

    test('the time of day does not change the line', () {
      final morning = DateTime(2026, 9, 13, 4, 30);
      final night = DateTime(2026, 9, 13, 23, 59);
      expect(VicharCycle.indexFor(morning, 200), VicharCycle.indexFor(night, 200));
    });

    test('every index is inside the collection', () {
      for (var d = 0; d < 500; d++) {
        final i = VicharCycle.indexFor(DateTime(2026).add(Duration(days: d)), 200);
        expect(i, inInclusiveRange(0, 199));
      }
    });

    test('an empty collection does not divide by zero', () {
      expect(VicharCycle.indexFor(DateTime(2026, 9, 13), 0), 0);
    });

    test('a phone that was off for a week has no backlog to work through', () {
      // The point of keying on the date rather than a stored cursor: coming
      // back after a gap lands on today's line, not on a queue of missed ones.
      final away = DateTime(2026, 9, 13);
      final back = away.add(const Duration(days: 7));
      expect(VicharCycle.indexFor(back, 200),
          (VicharCycle.indexFor(away, 200) + 7) % 200);
    });
  });

  group('which meaning is shown', () {
    const v = Vichar(
      idx: 0,
      gurmukhi: 'ਗੁਰ ਕਾ ਸਬਦੁ ਮਨਿ ਵਸੈ ॥',
      meaningPa: 'ਪੰਜਾਬੀ ਅਰਥ',
      meaningEn: 'English meaning',
    );

    test('English readers get the English one', () {
      expect(v.meaningIn('en'), 'English meaning');
    });

    test('Punjabi readers get the Punjabi one', () {
      expect(v.meaningIn('pa'), 'ਪੰਜਾਬੀ ਅਰਥ');
    });

    test('Hindi falls back to Punjabi, not to English', () {
      // The dataset carries no Hindi rendering, and Punjabi is far closer for
      // this reader than English would be.
      expect(v.meaningIn('hi'), 'ਪੰਜਾਬੀ ਅਰਥ');
    });

    test('an entry with no English shows the Punjabi to an English reader', () {
      const bare = Vichar(idx: 1, gurmukhi: 'ਲਾਈਨ', meaningPa: 'ਅਰਥ', meaningEn: '');
      expect(bare.meaningIn('en'), 'ਅਰਥ');
      expect(bare.hasEnglish, isFalse);
    });
  });
}
