import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/features/simran/domain/world_outline.dart';

/// The coastlines and borders under design 29's globe.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WorldOutline outline;

  setUpAll(() async {
    outline = WorldOutline.parse(
      await rootBundle.load('assets/geo/world.bin'),
    );
  });

  test('the shipped asset parses, and is the size the builder reported', () {
    expect(outline.arcCount, greaterThan(500));
    expect(outline.pointCount, greaterThan(4000));
    // Four floats a point, and one extra start entry holding the total.
    expect(outline.trig.length, outline.pointCount * 4);
    expect(outline.starts.length, outline.arcCount + 1);
    expect(outline.starts.last, outline.pointCount);
  });

  test('every arc has at least two points, or it draws nothing', () {
    for (var a = 0; a < outline.arcCount; a++) {
      expect(outline.starts[a + 1] - outline.starts[a], greaterThanOrEqualTo(2),
          reason: 'arc $a');
    }
  });

  test('the stored trigonometry is of real angles', () {
    for (var p = 0; p < outline.pointCount; p++) {
      final i = p * 4;
      final cosPhi = outline.trig[i];
      final sinPhi = outline.trig[i + 1];
      final cosLambda = outline.trig[i + 2];
      final sinLambda = outline.trig[i + 3];
      expect(cosPhi * cosPhi + sinPhi * sinPhi, closeTo(1, 1e-4));
      expect(cosLambda * cosLambda + sinLambda * sinLambda, closeTo(1, 1e-4));
      // Natural Earth clips at about 85 degrees, and a latitude past 90 would
      // fold the globe inside out.
      expect(cosPhi, greaterThan(0));
    }
  });

  test('a known coastline lands where it should', () {
    // Somewhere in the outline there is a point in the Indian subcontinent.
    // Not a specific arc -- the builder is free to simplify -- but the data
    // has to be the real world and not a transform of it.
    var nearAmritsar = false;
    for (var p = 0; p < outline.pointCount; p++) {
      final i = p * 4;
      final lat = math.atan2(outline.trig[i + 1], outline.trig[i]) * 180 / math.pi;
      final lon =
          math.atan2(outline.trig[i + 3], outline.trig[i + 2]) * 180 / math.pi;
      if ((lat - 31.6).abs() < 4 && (lon - 74.9).abs() < 4) nearAmritsar = true;
    }
    expect(nearAmritsar, isTrue);
  });

  test('a file that is not an outline is refused rather than drawn', () {
    final junk = ByteData.view(Uint8List.fromList(List.filled(64, 7)).buffer);
    expect(() => WorldOutline.parse(junk), throwsA(isA<FormatException>()));
  });

  test('nothing loaded draws nothing', () {
    expect(WorldOutline.empty.arcCount, 0);
    expect(WorldOutline.empty.pointCount, 0);
  });
}
