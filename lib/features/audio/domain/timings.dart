import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Where one line sits in a recitation.
@immutable
class LineTiming {
  const LineTiming({required this.line, required this.start, required this.end, this.words = const []});

  /// The line's `idx` in content.db.
  final int line;
  final Duration start;
  final Duration end;

  /// Word spans in Gurmukhi word order. Empty when the line has none, in which
  /// case the reader highlights the whole line.
  final List<(Duration, Duration)> words;

  bool contains(Duration at) => at >= start && at < end;
}

/// The timing file for one audio track (PRD §7.3).
@immutable
class BaniTimings {
  const BaniTimings({
    required this.track,
    required this.duration,
    required this.lines,
    this.verified = false,
  });

  factory BaniTimings.fromJson(Map<String, dynamic> json) {
    final lines = <LineTiming>[
      for (final raw in (json['lines'] as List<dynamic>? ?? const []))
        () {
          final m = raw as Map<String, dynamic>;
          return LineTiming(
            line: m['line'] as int,
            start: Duration(milliseconds: m['s'] as int),
            end: Duration(milliseconds: m['e'] as int),
            words: [
              for (final w in (m['w'] as List<dynamic>? ?? const []))
                (
                  Duration(milliseconds: (w as List<dynamic>)[0] as int),
                  Duration(milliseconds: w[1] as int),
                ),
            ],
          );
        }(),
    ];
    return BaniTimings(
      track: json['track'] as String? ?? '',
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      lines: lines,
      verified: json['verified'] as bool? ?? false,
    );
  }

  static BaniTimings? tryDecode(String payload) {
    try {
      return BaniTimings.fromJson(jsonDecode(payload) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  final String track;
  final Duration duration;

  /// Ordered by line index, which is also time order.
  final List<LineTiming> lines;

  /// False until a human has checked the line timings (PRD §8).
  final bool verified;

  bool get isEmpty => lines.isEmpty;

  /// The index into [lines] of the line being recited at [at], or -1.
  ///
  /// A binary search, so this is cheap enough to run on every position tick
  /// (PRD 1.6).
  int indexAt(Duration at) {
    var lo = 0;
    var hi = lines.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final line = lines[mid];
      if (at < line.start) {
        hi = mid - 1;
      } else if (at >= line.end) {
        lo = mid + 1;
      } else {
        return mid;
      }
    }
    // Between two lines -- the paathi is pausing. Hold the line just finished
    // rather than dropping the highlight, which would flicker at every gap.
    final held = lo - 1;
    return held >= 0 && held < lines.length ? held : -1;
  }

  LineTiming? lineAt(Duration at) {
    final i = indexAt(at);
    return i < 0 ? null : lines[i];
  }

  /// The word index within [line] being recited at [at], or -1.
  ///
  /// Words have gaps between them -- the breath a reciter takes mid-line -- so
  /// as with [indexAt] the word just finished is held rather than dropped,
  /// which would blink the highlight off between every pair of words.
  int wordIndexAt(LineTiming line, Duration at) {
    var held = -1;
    for (var i = 0; i < line.words.length; i++) {
      final (s, e) = line.words[i];
      if (at < s) break;
      if (at < e) return i;
      held = i;
    }
    return held;
  }

  /// Where a line starts, for tap-to-seek.
  Duration? startOfLine(int lineIdx) {
    for (final l in lines) {
      if (l.line == lineIdx) return l.start;
    }
    return null;
  }
}
