import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The coastlines and land borders drawn on design 29's globe.
///
/// Built by `tools/geo/build_world_outline.py` from Natural Earth's 1:110m
/// countries, as TopoJSON *arcs*: an arc shared by two countries is stored
/// once, so every coastline and every frontier is one stroke and a shared
/// border is never drawn twice down the middle.
///
/// The points are held ready for projection rather than as degrees. An
/// orthographic projection needs sin and cos of the latitude and of the
/// rotated longitude; the rotation changes every frame and the point does
/// not, so the four values that depend only on the point are worked out once
/// here and the painter finishes each frame with the angle-addition identity
/// and no trigonometry at all.
@immutable
class WorldOutline {
  const WorldOutline({required this.starts, required this.trig});

  /// Where each arc begins, counted in points. There is one extra entry at
  /// the end holding the total, so arc *i* runs from `starts[i]` up to
  /// `starts[i + 1]`.
  final Int32List starts;

  /// Four floats per point: cos φ, sin φ, cos λ, sin λ.
  final Float32List trig;

  int get arcCount => starts.isEmpty ? 0 : starts.length - 1;

  int get pointCount => trig.length ~/ 4;

  /// Nothing to draw — the state the globe is in until the asset has loaded.
  static final empty = WorldOutline(starts: Int32List(0), trig: Float32List(0));

  /// Reads the format the builder writes: "HZGEO1", a uint16 arc count, then
  /// per arc a uint16 point count followed by that many int16 pairs of
  /// hundredths of a degree, longitude first.
  static WorldOutline parse(ByteData data) {
    for (var i = 0; i < _magic.length; i++) {
      if (data.getUint8(i) != _magic.codeUnitAt(i)) {
        throw const FormatException('Not a Hazri world outline');
      }
    }
    var at = _magic.length;
    final arcs = data.getUint16(at, Endian.little);
    at += 2;

    // The header does not carry a grand total, so the arc lengths are read
    // first and the one big buffer allocated once, rather than growing a
    // list of four and a half thousand doubles.
    final starts = Int32List(arcs + 1);
    final header = at;
    var total = 0;
    for (var a = 0; a < arcs; a++) {
      starts[a] = total;
      final count = data.getUint16(at, Endian.little);
      at += 2 + count * 4;
      total += count;
    }
    starts[arcs] = total;

    final trig = Float32List(total * 4);
    at = header;
    var out = 0;
    for (var a = 0; a < arcs; a++) {
      final count = data.getUint16(at, Endian.little);
      at += 2;
      for (var p = 0; p < count; p++) {
        final lon = data.getInt16(at, Endian.little) / 100 * _toRadians;
        final lat = data.getInt16(at + 2, Endian.little) / 100 * _toRadians;
        at += 4;
        trig[out++] = math.cos(lat);
        trig[out++] = math.sin(lat);
        trig[out++] = math.cos(lon);
        trig[out++] = math.sin(lon);
      }
    }
    return WorldOutline(starts: starts, trig: trig);
  }

  static const _magic = 'HZGEO1';
  static const _toRadians = math.pi / 180;
}

/// The outline, loaded once for the life of the app.
///
/// It is 19 KiB and parses in a few milliseconds. The globe draws without it
/// meanwhile and picks it up when it arrives, so a slow read never holds the
/// screen up and a missing asset costs the sea and the dots nothing.
final worldOutlineProvider = FutureProvider<WorldOutline>((ref) async {
  final data = await rootBundle.load('assets/geo/world.bin');
  return WorldOutline.parse(data);
});
