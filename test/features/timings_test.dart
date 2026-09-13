import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/audio/domain/timings.dart';

/// The lookup that drives the reader's highlight (PRD 1.6), and a check on the
/// timing file that actually ships.
void main() {
  BaniTimings build(List<(int, int, int)> spans) => BaniTimings.fromJson({
    'track': 't',
    'durationMs': spans.isEmpty ? 0 : spans.last.$3,
    'lines': [
      for (final (line, s, e) in spans) {'line': line, 's': s, 'e': e},
    ],
  });

  group('indexAt', () {
    final t = build([(0, 0, 1000), (1, 1200, 2000), (2, 2500, 4000)]);

    test('finds the line being recited', () {
      expect(t.lineAt(const Duration(milliseconds: 500))!.line, 0);
      expect(t.lineAt(const Duration(milliseconds: 1500))!.line, 1);
      expect(t.lineAt(const Duration(milliseconds: 3000))!.line, 2);
    });

    test('is inclusive of a line start and exclusive of its end', () {
      expect(t.lineAt(Duration.zero)!.line, 0);
      expect(t.lineAt(const Duration(milliseconds: 999))!.line, 0);
      expect(t.lineAt(const Duration(milliseconds: 1200))!.line, 1);
    });

    test('holds the last line through a pause rather than dropping out', () {
      // 1100ms falls in the gap between line 0 and line 1.
      expect(t.lineAt(const Duration(milliseconds: 1100))!.line, 0);
      expect(t.lineAt(const Duration(milliseconds: 2200))!.line, 1);
    });

    test('before the first line there is nothing to highlight', () {
      final late = build([(0, 500, 1000)]);
      expect(late.lineAt(const Duration(milliseconds: 100)), isNull);
    });

    test('past the end it holds the closing line', () {
      expect(t.lineAt(const Duration(seconds: 30))!.line, 2);
    });

    test('an empty timing file highlights nothing', () {
      final empty = build([]);
      expect(empty.isEmpty, isTrue);
      expect(empty.lineAt(Duration.zero), isNull);
    });
  });

  group('word lookup', () {
    final t = BaniTimings.fromJson({
      'track': 't',
      'durationMs': 3000,
      'lines': [
        {
          'line': 0,
          's': 0,
          'e': 3000,
          'w': [
            [0, 1000],
            [1000, 2000],
            [2000, 3000],
          ],
        },
      ],
    });

    test('finds the word being recited', () {
      final line = t.lines.first;
      expect(t.wordIndexAt(line, const Duration(milliseconds: 500)), 0);
      expect(t.wordIndexAt(line, const Duration(milliseconds: 1500)), 1);
      expect(t.wordIndexAt(line, const Duration(milliseconds: 2999)), 2);
    });

    test('reports none outside the line', () {
      expect(t.wordIndexAt(t.lines.first, const Duration(seconds: 9)), -1);
    });

    test('a line with no word spans highlights as a whole', () {
      final plain = build([(0, 0, 1000)]);
      expect(plain.lines.first.words, isEmpty);
      expect(plain.wordIndexAt(plain.lines.first, Duration.zero), -1);
    });
  });

  group('startOfLine', () {
    test('gives the seek target for tap-to-jump', () {
      final t = build([(0, 0, 1000), (7, 4000, 5000)]);
      expect(t.startOfLine(7), const Duration(seconds: 4));
      expect(t.startOfLine(99), isNull);
    });
  });

  group('the shipped Japji timing file', () {
    late BaniTimings timings;

    setUpAll(() {
      final file = File('content/source/timings/japji-sahib.json');
      expect(file.existsSync(), isTrue, reason: 'run align_timings.py first');
      timings = BaniTimings.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
      );
    });

    test('covers all 385 lines', () {
      expect(timings.lines.length, 385);
      for (var i = 0; i < timings.lines.length; i++) {
        expect(timings.lines[i].line, i);
      }
    });

    test('spans run forward and never overlap', () {
      for (var i = 0; i < timings.lines.length; i++) {
        final line = timings.lines[i];
        expect(line.end > line.start, isTrue, reason: 'line $i has no duration');
        if (i > 0) {
          expect(
            line.start >= timings.lines[i - 1].end,
            isTrue,
            reason: 'line $i starts before line ${i - 1} ends',
          );
        }
      }
    });

    test('stays inside the recording', () {
      expect(timings.duration.inSeconds, closeTo(1139, 2));
      expect(timings.lines.last.end <= timings.duration, isTrue);
      expect(timings.lines.first.start >= Duration.zero, isTrue);
    });

    test('every line has word spans that tile its own span', () {
      for (final line in timings.lines) {
        expect(line.words, isNotEmpty, reason: 'line ${line.line}');
        expect(line.words.first.$1, line.start, reason: 'line ${line.line} first word');
        expect(line.words.last.$2, line.end, reason: 'line ${line.line} last word');
        for (var w = 1; w < line.words.length; w++) {
          expect(
            line.words[w].$1,
            line.words[w - 1].$2,
            reason: 'gap between words on line ${line.line}',
          );
        }
      }
    });

    test('no line is implausibly short or long for a recitation', () {
      for (final line in timings.lines) {
        final ms = (line.end - line.start).inMilliseconds;
        expect(ms, greaterThan(300), reason: 'line ${line.line} is ${ms}ms');
        expect(ms, lessThan(25000), reason: 'line ${line.line} is ${ms}ms');
      }
    });

    test('a lookup at every second lands on a line', () {
      for (var s = 1; s < timings.duration.inSeconds; s++) {
        expect(
          timings.lineAt(Duration(seconds: s)),
          isNotNull,
          reason: 'nothing highlighted at ${s}s',
        );
      }
    });

    test('is marked unverified until a human has checked it', () {
      // The PRD requires human verification of line timings before release
      // (PRD §8). The flag is how the app and the team can tell.
      expect(timings.verified, isFalse);
    });
  });
}
