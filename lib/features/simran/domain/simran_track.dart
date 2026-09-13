import 'dart:convert';

import 'package:flutter/foundation.dart';

/// The Naam Simran recitation, and the shape of it.
///
/// Android gives no way to read audio as it plays, so the loudness and the
/// moment each Waheguru begins are measured when the app is built
/// (`tools/audio_pipeline/simran_envelope.py`) and shipped in content.db. That
/// is what lets the ring answer to the recitation rather than to a timer.
@immutable
class SimranTrack {
  const SimranTrack({
    required this.id,
    required this.file,
    required this.duration,
    required this.rateHz,
    required this.envelope,
    required this.onsets,
  });

  factory SimranTrack.fromJson(
    Map<String, dynamic> json, {
    required String id,
    required String file,
  }) {
    final onsets = <Duration>[
      for (final ms in (json['onsets'] as List<dynamic>? ?? const []))
        Duration(milliseconds: ms as int),
    ];
    return SimranTrack(
      id: id,
      file: file,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
      rateHz: json['rateHz'] as int? ?? 25,
      envelope: base64Decode(json['envelope'] as String? ?? ''),
      onsets: onsets,
    );
  }

  final String id;

  /// File name inside `assets/audio/`.
  final String file;
  final Duration duration;

  /// Envelope samples per second.
  final int rateHz;

  /// Loudness 0-255, [rateHz] samples a second.
  final Uint8List envelope;

  /// Where each Waheguru begins, in order.
  final List<Duration> onsets;

  String get assetPath => 'assets/audio/$file';

  bool get isEmpty => envelope.isEmpty;

  /// How loud the recitation is at [at], 0 to 1.
  double levelAt(Duration at) {
    if (envelope.isEmpty) return 0;
    final i = (at.inMilliseconds * rateHz / 1000).round();
    if (i < 0 || i >= envelope.length) return 0;
    return envelope[i] / 255.0;
  }

  /// How many utterances have begun by [at].
  ///
  /// A binary search, so the ring can ask on every frame. Counting rather than
  /// returning the utterance itself is what a caller wants: the difference
  /// between two frames is how many to feed into the wave.
  int onsetsBefore(Duration at) {
    var lo = 0;
    var hi = onsets.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (onsets[mid] <= at) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }
}
