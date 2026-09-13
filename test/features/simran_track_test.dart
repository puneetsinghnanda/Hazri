import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/simran/domain/simran_track.dart';

/// The ring answers to the recitation rather than to a clock, which only works
/// if the shape measured at build time lines up with the audio that plays.
void main() {
  SimranTrack build({List<int> onsets = const [], String envelope = ''}) =>
      SimranTrack.fromJson(
        {'durationMs': 4000, 'rateHz': 25, 'envelope': envelope, 'onsets': onsets},
        id: 't',
        file: 't.m4a',
      );

  group('reading the shape', () {
    test('counts the utterances that have begun', () {
      final t = build(onsets: [500, 1500, 2500]);
      expect(t.onsetsBefore(Duration.zero), 0);
      expect(t.onsetsBefore(const Duration(milliseconds: 499)), 0);
      expect(t.onsetsBefore(const Duration(milliseconds: 500)), 1);
      expect(t.onsetsBefore(const Duration(milliseconds: 2000)), 2);
      expect(t.onsetsBefore(const Duration(hours: 1)), 3);
    });

    test('reads the loudness at a moment', () {
      // Four samples at 25 Hz: 0 ms, 40 ms, 80 ms, 120 ms.
      final t = build(envelope: base64Encode([0, 128, 255, 0]));
      expect(t.levelAt(Duration.zero), 0);
      expect(t.levelAt(const Duration(milliseconds: 40)), closeTo(0.5, 0.01));
      expect(t.levelAt(const Duration(milliseconds: 80)), 1);
    });

    test('is quiet rather than crashing past the end of the recording', () {
      final t = build(envelope: base64Encode([255]));
      expect(t.levelAt(const Duration(minutes: 9)), 0);
      expect(t.levelAt(const Duration(seconds: -5)), 0);
    });

    test('a build with no recitation reports itself empty', () {
      expect(build().isEmpty, isTrue);
    });
  });

  group('the shipped recitation', () {
    late SimranTrack track;

    setUpAll(() {
      final file = File('content/source/simran/naam-simran.json');
      expect(file.existsSync(), isTrue,
          reason: 'run simran_envelope.py first');
      track = SimranTrack.fromJson(
        jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
        id: 'naam-simran',
        file: 'naam-simran.m4a',
      );
    });

    test('covers the whole five-minute session', () {
      // The session is five minutes; the recording runs a little past it so
      // the ring is never following silence at the end.
      expect(track.duration.inSeconds, greaterThanOrEqualTo(300));
      expect(track.envelope.length,
          closeTo(track.duration.inSeconds * track.rateHz, track.rateHz * 2));
    });

    test('the utterances run in order and at a human pace', () {
      expect(track.onsets, isNotEmpty);
      for (var i = 1; i < track.onsets.length; i++) {
        expect(track.onsets[i] > track.onsets[i - 1], isTrue,
            reason: 'onset $i is not after the one before it');
      }
      final perMinute = track.onsets.length / (track.duration.inSeconds / 60);
      expect(perMinute, inInclusiveRange(20, 140));
    });

    test('every utterance falls inside the recording', () {
      expect(track.onsets.last, lessThanOrEqualTo(track.duration));
    });
  });
}
