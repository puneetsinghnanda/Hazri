import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../sangat/domain/simran_presence.dart';
import '../domain/world_outline.dart';

/// Design 29's globe: the earth seen from space, with a light where somebody
/// is sitting.
///
/// An orthographic projection, which is what a photograph of a sphere is: a
/// point at latitude φ and longitude λ lands where its 3-D position falls on
/// the picture plane, and is drawn only when it faces the viewer. That one
/// rule gives the horizon, the foreshortening at the edge, the coastlines
/// bending away and the dots disappearing round the back, with no 3-D engine
/// involved.
class SimranGlobe extends ConsumerStatefulWidget {
  const SimranGlobe({
    super.key,
    required this.presence,
    this.size = 260,
    this.spinning = true,
  });

  final SangatPresence presence;
  final double size;

  /// Turns slowly on its own. Off in tests and when the system asks for
  /// reduced motion.
  final bool spinning;

  @override
  ConsumerState<SimranGlobe> createState() => _SimranGlobeState();
}

class _SimranGlobeState extends ConsumerState<SimranGlobe>
    with TickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    // One turn every two minutes: visible if you watch, invisible if you do
    // not, and cheap either way.
    duration: const Duration(seconds: 120),
  );

  /// The slow breath under your own dot.
  ///
  /// Four seconds out and four back, and it moves the halo rather than the
  /// dot: a light that blinks off says something went wrong, and anything
  /// quick is the last thing somebody about to sit still for eleven minutes
  /// needs. The dot itself never dims and never changes size — what drifts
  /// is the glow around it.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  /// Where the hand has turned it to, on top of the spin.
  double _dragged = 0;

  @override
  void initState() {
    super.initState();
    if (widget.spinning) {
      _spin.repeat();
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(SimranGlobe old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_spin.isAnimating) {
      _spin.repeat();
      _pulse.repeat(reverse: true);
    } else if (!widget.spinning && _spin.isAnimating) {
      _spin.stop();
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _spin.isAnimating) {
      _spin.stop();
      _pulse.stop();
    }
    final outline = ref.watch(worldOutlineProvider).value ?? WorldOutline.empty;

    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(() {
        // A drag across the whole globe turns it half way round, which is
        // about what a hand on a real one does.
        _dragged += d.delta.dx / widget.size * math.pi;
      }),
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _pulse]),
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _GlobePainter(
            cities: widget.presence.cities,
            yourCityId: widget.presence.yourCityId,
            outline: outline,
            rotation: _dragged + (reduceMotion ? 0 : _spin.value * 2 * math.pi),
            // Half way through the breath when nothing is animating, so a
            // still frame is never the smallest the halo gets.
            breath: reduceMotion ? 0.5 : Curves.easeInOut.transform(_pulse.value),
          ),
        ),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  _GlobePainter({
    required this.cities,
    required this.outline,
    required this.rotation,
    required this.breath,
    this.yourCityId,
  });

  final List<PresenceCity> cities;
  final WorldOutline outline;
  final double rotation;

  /// 0 to 1 and back, four seconds each way.
  final double breath;

  /// Lit differently, because design 29's legend says which dot is yours.
  final String? yourCityId;

  /// The globe's own palette, not the theme's. It is a night sky on both
  /// themes, the way design 29 draws it, and a light-theme globe would be a
  /// different object rather than the same one repainted.
  static const _sea = Color(0xFF080B1C);
  static const _grid = Color(0xFF2A3A6B);
  static const _coast = Color(0xFF41609E);
  static const _light = Color(0xFFE8F4F8);
  static const _halo = Color(0xFF6FC3D3);
  static const _you = Color(0xFFF2A24E);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centre = Offset(r, r);
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);

    canvas.drawCircle(centre, r, Paint()..color = _sea);

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = _grid.withValues(alpha: 0.55);

    // Parallels: a circle of latitude is an ellipse under this projection,
    // squashed by sin of the latitude and offset by its cosine.
    for (var lat = -60; lat <= 60; lat += 30) {
      final phi = lat * math.pi / 180;
      final y = -math.sin(phi) * r;
      final rx = math.cos(phi) * r;
      canvas.drawOval(
        Rect.fromCenter(
          center: centre + Offset(0, y),
          width: rx * 2,
          height: rx * 2 * 0.28,
        ),
        grid,
      );
    }

    // Meridians: half an ellipse each, its width following how far round the
    // globe it has turned.
    for (var i = 0; i < 6; i++) {
      final lon = rotation + i * math.pi / 6;
      final width = math.cos(lon).abs() * r * 2;
      canvas.drawOval(
        Rect.fromCenter(center: centre, width: width, height: r * 2),
        grid,
      );
    }

    _drawOutline(canvas, centre, r, cosR, sinR);

    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _grid,
    );

    for (final city in cities) {
      final point = _project(city, r, cosR, sinR);
      if (point == null) continue;
      final mine = city.id == yourCityId;
      // Bigger where more people are sitting, but gently: a city of two is
      // not twice the light of a city of one.
      final radius = 1.8 + math.min(3.4, math.log(city.count + 1) * 1.1);
      if (mine) {
        // Design 29's two haloes round your own dot, breathing. The outer one
        // moves most, so the edge of the glow drifts rather than the dot
        // appearing to change size.
        canvas.drawCircle(
          centre + point,
          (radius + 8) * (0.88 + 0.24 * breath),
          Paint()..color = _you.withValues(alpha: 0.10 + 0.10 * breath),
        );
        canvas.drawCircle(
          centre + point,
          (radius + 3) * (0.94 + 0.12 * breath),
          Paint()..color = _you.withValues(alpha: 0.24 + 0.10 * breath),
        );
      } else {
        canvas.drawCircle(
          centre + point,
          radius * 2.6,
          Paint()
            ..color = _halo.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      canvas.drawCircle(
        centre + point,
        mine ? radius + 1 : radius,
        Paint()..color = mine ? _you : _light,
      );
    }
  }

  /// Coastlines and land borders, all of them in one path.
  ///
  /// One `drawPath` rather than six hundred: the arcs are re-projected on
  /// every frame of the spin, and six hundred canvas calls a frame is the
  /// difference between a globe that turns and one that stutters. An arc is
  /// broken wherever it passes behind the horizon and taken up again on the
  /// other side.
  void _drawOutline(Canvas canvas, Offset centre, double r, double cosR, double sinR) {
    if (outline.arcCount == 0) return;
    final trig = outline.trig;
    final starts = outline.starts;
    final path = Path();

    for (var a = 0; a < outline.arcCount; a++) {
      var drawing = false;
      for (var p = starts[a]; p < starts[a + 1]; p++) {
        final i = p * 4;
        final cosPhi = trig[i];
        final sinPhi = trig[i + 1];
        final cosLambda = trig[i + 2];
        final sinLambda = trig[i + 3];
        // cos(λ + rotation) and sin(λ + rotation), without the trigonometry.
        final cosRot = cosLambda * cosR - sinLambda * sinR;
        final z = cosPhi * cosRot;
        if (z <= 0) {
          drawing = false;
          continue;
        }
        final sinRot = sinLambda * cosR + cosLambda * sinR;
        final x = centre.dx + cosPhi * sinRot * r;
        final y = centre.dy - sinPhi * r;
        if (drawing) {
          path.lineTo(x, y);
        } else {
          path.moveTo(x, y);
          drawing = true;
        }
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..color = _coast,
    );
  }

  /// Where a city lands on the picture plane, or null when it is round the
  /// back. z > 0 is the near side; everything else is hidden by the earth
  /// itself, which is what makes this read as a sphere rather than a disc.
  static Offset? _project(PresenceCity city, double r, double cosR, double sinR) {
    final phi = city.lat * math.pi / 180;
    final lambda = city.lon * math.pi / 180;
    final cosPhi = math.cos(phi);
    final cosRot = math.cos(lambda) * cosR - math.sin(lambda) * sinR;
    final z = cosPhi * cosRot;
    if (z <= 0) return null;
    final sinRot = math.sin(lambda) * cosR + math.cos(lambda) * sinR;
    return Offset(cosPhi * sinRot * r, -math.sin(phi) * r);
  }

  @override
  bool shouldRepaint(_GlobePainter old) =>
      old.rotation != rotation ||
      old.breath != breath ||
      old.cities != cities ||
      old.outline != outline ||
      old.yourCityId != yourCityId;
}
