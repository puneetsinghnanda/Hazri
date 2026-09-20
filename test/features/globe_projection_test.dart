import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/simran/ui/simran_globe.dart';

/// The orthographic projection under the globe, on its own.
///
/// Two rotations: about the polar axis (the spin and the hand's sideways
/// drag) and about the horizontal axis (the tilt). The tilt is the newer of
/// the two — dragging up and down used to do nothing at all — and it is the
/// one that breaks the old closed-form graticule, so it is worth pinning
/// down here rather than only in a widget that draws.
void main() {
  const r = 100.0;

  /// The projector takes sines and cosines so that the outline needs no
  /// trigonometry per frame; tests are easier to read in degrees.
  Offset? at(double lat, double lon, {double rotation = 0, double tilt = 0}) {
    const d = math.pi / 180;
    return GlobePainter.project(
      cosPhi: math.cos(lat * d),
      sinPhi: math.sin(lat * d),
      cosLambda: math.cos(lon * d),
      sinLambda: math.sin(lon * d),
      r: r,
      cosR: math.cos(rotation),
      sinR: math.sin(rotation),
      cosT: math.cos(tilt),
      sinT: math.sin(tilt),
    );
  }

  group('standing upright', () {
    test('0°N 0°E is dead centre', () {
      final p = at(0, 0)!;
      expect(p.dx, closeTo(0, 1e-9));
      expect(p.dy, closeTo(0, 1e-9));
    });

    test('north is up, and the pole is on the rim', () {
      expect(at(90, 0)!.dy, closeTo(-r, 1e-9));
      expect(at(-90, 0)!.dy, closeTo(r, 1e-9));
    });

    test('east is right, west is left', () {
      expect(at(0, 90)!.dx, closeTo(r, 1e-9));
      expect(at(0, -90)!.dx, closeTo(-r, 1e-9));
    });

    test('the far side is dropped rather than drawn on top', () {
      expect(at(0, 180), isNull);
      expect(at(0, 140), isNull);
    });

    test('nothing ever lands outside the disc', () {
      for (var lat = -90; lat <= 90; lat += 5) {
        for (var lon = -180; lon <= 180; lon += 5) {
          final p = at(lat.toDouble(), lon.toDouble());
          if (p == null) continue;
          expect(p.distance, lessThanOrEqualTo(r + 1e-9),
              reason: '$lat, $lon');
        }
      }
    });
  });

  group('turned by the hand', () {
    test('a quarter turn brings 90°W to the middle', () {
      final p = at(0, -90, rotation: math.pi / 2)!;
      expect(p.dx, closeTo(0, 1e-9));
      expect(p.dy, closeTo(0, 1e-9));
    });
  });

  group('tilted', () {
    test('tilting north lifts the equator and brings the pole into view', () {
      // A quarter turn about the horizontal axis puts the north pole where
      // the centre of the disc was.
      final pole = at(90, 0, tilt: math.pi / 2)!;
      expect(pole.dx, closeTo(0, 1e-9));
      expect(pole.dy, closeTo(0, 1e-9));
    });

    test('and sends what was in the middle over the top', () {
      final was = at(0, 0, tilt: math.pi / 2)!;
      expect(was.dy, closeTo(r, 1e-9));
    });

    test('half a turn hides the whole near side', () {
      // Upside down and facing away: every point that faced us now does not.
      expect(at(0, 0, tilt: math.pi), isNull);
      expect(at(30, 20, tilt: math.pi), isNull);
      // And the far side has come round.
      expect(at(0, 180, tilt: math.pi), isNotNull);
    });

    test('a full turn is where it started, so the drag has no seam', () {
      final start = at(31.6, 74.9)!;
      final round = at(31.6, 74.9, tilt: 2 * math.pi)!;
      expect(round.dx, closeTo(start.dx, 1e-6));
      expect(round.dy, closeTo(start.dy, 1e-6));
    });

    test('nothing lands outside the disc at any tilt either', () {
      for (var tilt = 0; tilt < 360; tilt += 15) {
        for (var lat = -90; lat <= 90; lat += 15) {
          for (var lon = -180; lon <= 180; lon += 15) {
            final p = at(
              lat.toDouble(),
              lon.toDouble(),
              tilt: tilt * math.pi / 180,
            );
            if (p == null) continue;
            expect(p.distance, lessThanOrEqualTo(r + 1e-9),
                reason: '$lat, $lon at $tilt');
          }
        }
      }
    });
  });
}
