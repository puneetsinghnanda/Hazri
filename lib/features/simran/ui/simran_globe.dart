import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/simran_presence.dart';
import '../domain/world_outline.dart';

/// The globe: the earth seen from space, with a light where somebody is
/// sitting.
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

  /// A quarter of a degree, which at this size is under a pixel at the
  /// equator.
  ///
  /// The globe turns once every two minutes, so a frame moves it about a
  /// twentieth of a degree -- far less than it takes to see. Re-projecting
  /// five and a half thousand points sixty times a second for that is what
  /// made the countdown beside it stutter. Rounding the angle means
  /// `shouldRepaint` says no on most frames and the work happens about a
  /// dozen times a second instead.
  static const _rotationStep = 0.25 * math.pi / 180;

  static double _step(double value, double step) =>
      (value / step).roundToDouble() * step;

  /// Where the hand has turned it to, on top of the spin.
  double _dragged = 0;

  /// And how far it has been tilted, north or south.
  ///
  /// Unclamped, so it goes all the way over and round: a hand on a real globe
  /// is not stopped at the pole, and dragging up used to do nothing at all.
  double _tilt = 0;

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
      // A pan, not a horizontal drag: the globe turns under the hand in both
      // directions, and a full turn either way is a drag of about twice its
      // width.
      //
      // Both axes *add*. The vertical one used to subtract, which inverted
      // it: the point under the centre of the disc lands at screen y of
      // `sin(tilt) * r`, and screen y counts downward, so a positive tilt is
      // what moves the surface down under a downward finger. Dragging down
      // sent the earth up instead, and the north pole away rather than
      // toward you.
      onPanUpdate: (d) => setState(() {
        _dragged += d.delta.dx / widget.size * math.pi;
        _tilt = (_tilt + d.delta.dy / widget.size * math.pi) % (2 * math.pi);
      }),
      child: AnimatedBuilder(
        animation: Listenable.merge([_spin, _pulse]),
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: GlobePainter(
            cities: widget.presence.cities,
            yourCityId: widget.presence.yourCityId,
            outline: outline,
            rotation: _step(
              _dragged + (reduceMotion ? 0 : _spin.value * 2 * math.pi),
              _rotationStep,
            ),
            tilt: _step(_tilt, _rotationStep),
            // Half way through the breath when nothing is animating, so a
            // still frame is never the smallest the halo gets.
            breath: reduceMotion
                ? 0.5
                : _step(Curves.easeInOut.transform(_pulse.value), 1 / 24),
          ),
        ),
      ),
    );
  }
}

/// Draws the earth. Public so a test can project a known city and check where
/// it lands.
class GlobePainter extends CustomPainter {
  GlobePainter({
    required this.cities,
    required this.outline,
    required this.rotation,
    required this.breath,
    this.tilt = 0,
    this.yourCityId,
  });

  final List<PresenceCity> cities;
  final WorldOutline outline;

  /// About the polar axis — the spin, plus whatever the hand has added.
  final double rotation;

  /// About the horizontal axis — north or south under the hand.
  final double tilt;

  /// 0 to 1 and back, four seconds each way.
  final double breath;

  /// Lit differently, because the legend says which dot is yours.
  final String? yourCityId;

  /// The globe's own palette, not the theme's. It is a night sky on both
  /// themes, and a light-theme globe would be a different object rather than
  /// the same one repainted.
  static const _sea = Color(0xFF071232);
  static const _seaEdge = Color(0xFF0A1F52);
  static const _grid = Color(0xFF2F4E96);
  static const _coast = Color(0xFF8FD4FF);
  static const _rim = Color(0xFF7FC4FF);
  static const _light = Color(0xFFE8F4F8);
  static const _halo = Color(0xFF6FC3D3);
  static const _you = Color(0xFFF2A24E);

  /// Parallels every 30°, meridians every 30°, as points rather than as the
  /// closed-form ellipses they used to be.
  ///
  /// An ellipse only works while the globe stands upright. Once it can be
  /// tilted there is no closed form, so the grid goes through the same
  /// projector as the coastlines and is right at any angle.
  static final _graticule = _buildGraticule();

  static List<List<double>> _buildGraticule() {
    const d = math.pi / 180;
    final lines = <List<double>>[];
    for (var lat = -60; lat <= 60; lat += 30) {
      final line = <double>[];
      for (var lon = -180; lon <= 180; lon += 5) {
        line.addAll([lat * d, lon * d]);
      }
      lines.add(line);
    }
    for (var lon = -180; lon < 180; lon += 30) {
      final line = <double>[];
      for (var lat = -90; lat <= 90; lat += 5) {
        line.addAll([lat * d, lon * d]);
      }
      lines.add(line);
    }
    return lines;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centre = Offset(r, r);
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);
    final cosT = math.cos(tilt);
    final sinT = math.sin(tilt);

    _drawGlow(canvas, centre, r);

    // The sea, lit from the limb inwards so the sphere reads as lit from
    // outside rather than as a flat disc.
    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: const [_sea, _sea, _seaEdge],
          stops: const [0, 0.72, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: r)),
    );

    _strokeLines(
      canvas,
      _graticule,
      centre,
      r,
      cosR,
      sinR,
      cosT,
      sinT,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = _grid.withValues(alpha: 0.6),
    );

    _drawOutline(canvas, centre, r, cosR, sinR, cosT, sinT);
    _drawCities(canvas, centre, r, cosR, sinR, cosT, sinT);

    // The bright edge last, over everything, which is what makes it a rim
    // light rather than an outline.
    canvas.drawCircle(
      centre,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = _rim.withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  /// The light around the globe.
  ///
  /// A radial gradient rather than blurred circles. Three `MaskFilter.blur`
  /// passes at a sigma of ninety, on every frame, cost more than everything
  /// else on this screen put together; a gradient is one draw with no
  /// filter and reads the same.
  void _drawGlow(Canvas canvas, Offset centre, double r) {
    final outer = r * 1.34;
    canvas.drawCircle(
      centre,
      outer,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _rim.withValues(alpha: 0),
            _rim.withValues(alpha: 0.30),
            _rim.withValues(alpha: 0.55),
            _rim.withValues(alpha: 0.22),
            _rim.withValues(alpha: 0),
          ],
          stops: const [0.52, 0.68, 0.746, 0.85, 1],
        ).createShader(Rect.fromCircle(center: centre, radius: outer)),
    );
  }

  /// Coastlines and land borders, all of them in one path.
  ///
  /// One `drawPath` rather than six hundred: the arcs are re-projected on
  /// every frame of the spin, and six hundred canvas calls a frame is the
  /// difference between a globe that turns and one that stutters.
  void _drawOutline(
    Canvas canvas,
    Offset centre,
    double r,
    double cosR,
    double sinR,
    double cosT,
    double sinT,
  ) {
    if (outline.arcCount == 0) return;
    final trig = outline.trig;
    final starts = outline.starts;
    final path = Path();

    for (var a = 0; a < outline.arcCount; a++) {
      var drawing = false;
      for (var p = starts[a]; p < starts[a + 1]; p++) {
        final i = p * 4;
        final at = project(
          cosPhi: trig[i],
          sinPhi: trig[i + 1],
          cosLambda: trig[i + 2],
          sinLambda: trig[i + 3],
          r: r,
          cosR: cosR,
          sinR: sinR,
          cosT: cosT,
          sinT: sinT,
        );
        if (at == null) {
          drawing = false;
          continue;
        }
        if (drawing) {
          path.lineTo(centre.dx + at.dx, centre.dy + at.dy);
        } else {
          path.moveTo(centre.dx + at.dx, centre.dy + at.dy);
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
        ..color = _coast.withValues(alpha: 0.85),
    );
  }

  /// Polylines given as flat (φ, λ) radian pairs.
  void _strokeLines(
    Canvas canvas,
    List<List<double>> lines,
    Offset centre,
    double r,
    double cosR,
    double sinR,
    double cosT,
    double sinT,
    Paint paint,
  ) {
    final path = Path();
    for (final line in lines) {
      var drawing = false;
      for (var i = 0; i < line.length; i += 2) {
        final phi = line[i];
        final lambda = line[i + 1];
        final at = project(
          cosPhi: math.cos(phi),
          sinPhi: math.sin(phi),
          cosLambda: math.cos(lambda),
          sinLambda: math.sin(lambda),
          r: r,
          cosR: cosR,
          sinR: sinR,
          cosT: cosT,
          sinT: sinT,
        );
        if (at == null) {
          drawing = false;
          continue;
        }
        if (drawing) {
          path.lineTo(centre.dx + at.dx, centre.dy + at.dy);
        } else {
          path.moveTo(centre.dx + at.dx, centre.dy + at.dy);
          drawing = true;
        }
      }
    }
    canvas.drawPath(path, paint);
  }

  void _drawCities(
    Canvas canvas,
    Offset centre,
    double r,
    double cosR,
    double sinR,
    double cosT,
    double sinT,
  ) {
    const toRadians = math.pi / 180;
    for (final city in cities) {
      final phi = city.lat * toRadians;
      final lambda = city.lon * toRadians;
      final at = project(
        cosPhi: math.cos(phi),
        sinPhi: math.sin(phi),
        cosLambda: math.cos(lambda),
        sinLambda: math.sin(lambda),
        r: r,
        cosR: cosR,
        sinR: sinR,
        cosT: cosT,
        sinT: sinT,
      );
      if (at == null) continue;
      final mine = city.id == yourCityId;
      // Bigger where more people are sitting, but gently: a city of two is
      // not twice the light of a city of one.
      final radius = 1.8 + math.min(3.4, math.log(city.count + 1) * 1.1);
      if (mine) {
        // Two haloes round your own dot, breathing. The outer one moves most,
        // so the edge of the glow drifts rather than the dot appearing to
        // change size.
        canvas.drawCircle(
          centre + at,
          (radius + 8) * (0.88 + 0.24 * breath),
          Paint()..color = _you.withValues(alpha: 0.10 + 0.10 * breath),
        );
        canvas.drawCircle(
          centre + at,
          (radius + 3) * (0.94 + 0.12 * breath),
          Paint()..color = _you.withValues(alpha: 0.24 + 0.10 * breath),
        );
      } else {
        canvas.drawCircle(
          centre + at,
          radius * 2.6,
          Paint()
            ..color = _halo.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
      }
      canvas.drawCircle(
        centre + at,
        mine ? radius + 1 : radius,
        Paint()..color = mine ? _you : _light,
      );
    }
  }

  /// Where a point lands relative to the centre, or null when it is round the
  /// back. Public so the projection can be tested on its own.
  ///
  /// Two rotations: about the polar axis by the spin, then about the
  /// horizontal axis by the tilt. z > 0 is the near side; everything else is
  /// hidden by the earth itself, which is what makes this read as a sphere
  /// rather than a disc. The caller passes sines and cosines rather than
  /// angles so the outline, which is re-projected point by point on every
  /// frame, needs no trigonometry of its own.
  static Offset? project({
    required double cosPhi,
    required double sinPhi,
    required double cosLambda,
    required double sinLambda,
    required double r,
    required double cosR,
    required double sinR,
    required double cosT,
    required double sinT,
  }) {
    // cos(λ + rotation) and sin(λ + rotation), without the trigonometry.
    final cosRot = cosLambda * cosR - sinLambda * sinR;
    final sinRot = sinLambda * cosR + cosLambda * sinR;
    final x = cosPhi * sinRot;
    final y = sinPhi;
    final z = cosPhi * cosRot;
    // And the tilt, about the horizontal axis.
    final zt = y * sinT + z * cosT;
    if (zt <= 0) return null;
    final yt = y * cosT - z * sinT;
    return Offset(x * r, -yt * r);
  }

  @override
  bool shouldRepaint(GlobePainter old) =>
      old.rotation != rotation ||
      old.tilt != tilt ||
      old.breath != breath ||
      old.cities != cities ||
      old.outline != outline ||
      old.yourCityId != yourCityId;
}
