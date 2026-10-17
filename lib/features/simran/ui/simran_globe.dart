import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../domain/simran_presence.dart';
import '../domain/world_outline.dart';

/// Where a point of the earth is on the globe's square right now: [at] in the
/// widget's own coordinates, and [front] false when it is round the back, in
/// which case [at] is the nearest point of the rim.
typedef GlobeProjector = ({Offset at, bool front}) Function(double lat, double lon);

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
    required this.dots,
    this.threads = const [],
    this.arcs = const [],
    this.cityNames = const {},
    this.youLive = false,
    this.size = 260,
    this.spinning = true,
    this.liveTip,
    this.hereTip,
    this.overlay,
  });

  /// You, Live and Here today (07-simran §2.1).
  final List<GlobeDot> dots;

  /// DR6, DR7: which dots are joined, and the 3-D samples of each (DR8).
  final List<GlobeThread> threads;
  final List<List<double>> arcs;

  /// For the tap on a dot (TT1), in the app's language.
  final Map<String, String> cityNames;

  /// Your own attendance is marked today, so you count as live in your city.
  final bool youLive;
  final double size;

  /// Turns slowly on its own. Off in tests and when the system asks for
  /// reduced motion.
  final bool spinning;

  /// The tap card's lines for the green and the blue (TT1). Null is the
  /// Simran tab's `globeTipLive` and `globeTipHere`; a group's globe says
  /// "today" and "not yet" (08-sangat GG3).
  final String Function(int count)? liveTip;
  final String Function(int count)? hereTip;

  /// Drawn over the earth and under the tap card, rebuilt as the globe turns,
  /// with a [GlobeProjector] for where any place is at this moment. It may
  /// reach outside the square; it takes no taps. The group screen's ring and
  /// its arrivals (08-sangat GG1, GG4).
  final Widget Function(BuildContext context, GlobeProjector project)? overlay;

  /// ZM1: how far a pinch can bring the earth in.
  static const maxZoom = 8.0;

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

  /// Your dot's blink: `YOU_BLINK_PERIOD_MS` = 1600, out and back (DR1).
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );

  /// The light running along the threads (DR8): one lap every six seconds.
  late final AnimationController _flow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
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

  /// ZM1: 1 is the whole earth; a pinch brings it in to [SimranGlobe.maxZoom].
  double _zoom = 1;
  double _zoomAtStart = 1;

  /// TT1: the city whose card is showing, and where its dot is.
  String? _tipCity;
  Offset? _tipAt;
  Timer? _tipTimer;
  ({Offset at, DateTime when})? _lastTap;

  bool get _zoomed => _zoom > 1.05;

  void _run(bool on) {
    for (final c in [_pulse, _flow]) {
      if (on && !c.isAnimating) {
        c == _pulse ? c.repeat(reverse: true) : c.repeat();
      } else if (!on && c.isAnimating) {
        c.stop();
      }
    }
    // ZM3: zoomed in, the earth holds still under the hand.
    if (on && !_zoomed && !_spin.isAnimating) _spin.repeat();
    if ((!on || _zoomed) && _spin.isAnimating) _spin.stop();
  }

  @override
  void initState() {
    super.initState();
    _run(widget.spinning);
  }

  @override
  void didUpdateWidget(SimranGlobe old) {
    super.didUpdateWidget(old);
    _run(widget.spinning);
  }

  @override
  void dispose() {
    _tipTimer?.cancel();
    _spin.dispose();
    _pulse.dispose();
    _flow.dispose();
    super.dispose();
  }

  double get _rotation => _dragged + _spin.value * 2 * math.pi;

  void _setZoom(double z) {
    final was = _zoomed;
    _zoom = z.clamp(1.0, SimranGlobe.maxZoom);
    if (_zoomed && !was) {
      // Fold the spin into the hand's turn, so stopping it moves nothing.
      _dragged = _rotation;
      _spin.value = 0;
    }
    _run(widget.spinning && !MediaQuery.disableAnimationsOf(context));
  }

  /// TT1: the dot under a tap, by where the painter puts it.
  void _tap(Offset local) {
    final hit = GlobePainter.dotAt(
      dots: widget.dots,
      at: local,
      size: widget.size,
      zoom: _zoom,
      rotation: _step(_rotation, _rotationStep),
      tilt: _step(_tilt, _rotationStep),
    );
    _tipTimer?.cancel();
    setState(() {
      _tipCity = hit?.cityId;
      _tipAt = hit?.at;
    });
    if (hit != null) {
      _tipTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _tipCity = null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) _run(false);
    final outline = ref.watch(worldOutlineProvider).value ?? WorldOutline.empty;

    return GestureDetector(
      // One finger turns the earth under the hand in both directions; two
      // pinch it nearer (ZM1). A full turn is a drag of about twice its
      // width, and less once zoomed, so the ground keeps pace with the finger.
      //
      // Both axes *add*. The vertical one used to subtract, which inverted
      // it: the point under the centre of the disc lands at screen y of
      // `sin(tilt) * r`, and screen y counts downward, so a positive tilt is
      // what moves the surface down under a downward finger. Dragging down
      // sent the earth up instead, and the north pole away rather than
      // toward you.
      onScaleStart: (_) => _zoomAtStart = _zoom,
      onScaleUpdate: (d) => setState(() {
        if (d.pointerCount > 1) _setZoom(_zoomAtStart * d.scale);
        final k = math.pi / (widget.size * _zoom);
        _dragged += d.focalPointDelta.dx * k;
        _tilt = (_tilt + d.focalPointDelta.dy * k) % (2 * math.pi);
        _tipCity = null;
      }),
      // ZM2: a second tap close behind the first brings it in, and from all
      // the way in, back out. Told apart here rather than by a double-tap
      // recogniser, which would hold every single tap back to wait for one.
      onTapUp: (d) {
        final now = DateTime.now();
        final last = _lastTap;
        _lastTap = (at: d.localPosition, when: now);
        if (last != null &&
            now.difference(last.when) < const Duration(milliseconds: 300) &&
            (last.at - d.localPosition).distance < 40) {
          _lastTap = null;
          _tipTimer?.cancel();
          setState(() {
            _setZoom(_zoom >= SimranGlobe.maxZoom - 0.01 ? 1 : math.min(SimranGlobe.maxZoom, _zoom * 2.5));
            _tipCity = null;
          });
          return;
        }
        _tap(d.localPosition);
      },
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedBuilder(
              animation: Listenable.merge([_spin, _pulse, _flow]),
              builder: (context, _) => CustomPaint(
                size: Size.square(widget.size),
                painter: GlobePainter(
                  dots: widget.dots,
                  threads: widget.threads,
                  arcs: widget.arcs,
                  outline: outline,
                  zoom: _zoom,
                  rotation: _step(_rotation, _rotationStep),
                  tilt: _step(_tilt, _rotationStep),
                  // Half way through the breath when nothing is animating, so a
                  // still frame is never the smallest the halo gets.
                  // G-16: reduced motion, no blink.
                  breath: reduceMotion
                      ? 1
                      : _step(Curves.easeInOut.transform(_pulse.value), 1 / 24),
                  flow: reduceMotion ? -1 : _step(_flow.value, 1 / 180),
                ),
              ),
            ),
            if (widget.overlay != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _spin,
                    builder: (context, _) {
                      final rotation = _step(_rotation, _rotationStep);
                      final tilt = _step(_tilt, _rotationStep);
                      return widget.overlay!(
                        context,
                        (lat, lon) => GlobePainter.locate(
                          lat: lat,
                          lon: lon,
                          size: widget.size,
                          zoom: _zoom,
                          rotation: rotation,
                          tilt: tilt,
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (_tipCity != null && _tipAt != null)
              _CityTip(
                at: _tipAt!,
                bounds: widget.size,
                name: widget.cityNames[_tipCity] ?? _tipCity!,
                dots: [for (final d in widget.dots) if (d.cityId == _tipCity) d],
                youLive: widget.youLive,
                liveTip: widget.liveTip,
                hereTip: widget.hereTip,
              ),
          ],
        ),
      ),
    );
  }
}

/// TT1–TT3: the card for one city. Your city counts you where you are: live
/// once your attendance is marked, here today until then.
class _CityTip extends StatelessWidget {
  const _CityTip({
    required this.at,
    required this.bounds,
    required this.name,
    required this.dots,
    required this.youLive,
    this.liveTip,
    this.hereTip,
  });

  final Offset at;
  final double bounds;
  final String name;
  final List<GlobeDot> dots;
  final bool youLive;
  final String Function(int count)? liveTip;
  final String Function(int count)? hereTip;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final mine = dots.any((d) => d.kind == DotKind.you);
    int count(DotKind k) => dots.where((d) => d.kind == k).fold(0, (n, d) => n + d.count);
    final live = count(DotKind.live) + (mine && youLive ? 1 : 0);
    final here = count(DotKind.here) + (mine && !youLive ? 1 : 0);
    const width = 180.0;
    final left = (at.dx - width / 2).clamp(4.0, math.max(4.0, bounds - width - 4)).toDouble();
    final above = at.dy > 96;
    Widget row(Color c, String t) => Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Flexible(child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.25))),
          ]),
        );
    return Positioned(
      left: left,
      top: above ? null : at.dy + 18,
      bottom: above ? bounds - at.dy + 18 : null,
      width: width,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: const Color(0xEE0C0F24),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: GlobePainter.you.withValues(alpha: 0.55)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              if (mine) row(GlobePainter.you, l.globeTipYou),
              if (live > 0) row(GlobePainter.live, (liveTip ?? l.globeTipLive)(live)),
              if (here > 0) row(GlobePainter.here, (hereTip ?? l.globeTipHere)(here)),
            ],
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
    required this.dots,
    required this.outline,
    required this.rotation,
    required this.breath,
    this.tilt = 0,
    this.zoom = 1,
    this.threads = const [],
    this.arcs = const [],
    this.flow = -1,
  });

  final List<GlobeDot> dots;
  final List<GlobeThread> threads;
  final List<List<double>> arcs;
  final WorldOutline outline;

  /// ZM1: the earth's radius over the widget's half-width.
  final double zoom;

  /// 0 to 1 round the lap of the light on the threads; negative draws none.
  final double flow;

  /// About the polar axis — the spin, plus whatever the hand has added.
  final double rotation;

  /// About the horizontal axis — north or south under the hand.
  final double tilt;

  /// 0 to 1 and back, four seconds each way.
  final double breath;


  /// The globe's own palette, not the theme's. It is a night sky on both
  /// themes, and a light-theme globe would be a different object rather than
  /// the same one repainted.
  static const _sea = Color(0xFF071232);
  static const _seaEdge = Color(0xFF0A1F52);
  static const _grid = Color(0xFF2F4E96);
  static const _coast = Color(0xFF8FD4FF);
  static const _rim = Color(0xFF7FC4FF);
  static const _you = Color(0xFFF2A24E);

  /// DR4's legend colours: Live green, Here today blue.
  static const live = Color(0xFF6FE3A6);
  static const here = Color(0xFF5AA9FF);
  static const you = _you;

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
    final centre = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 * zoom;
    // Zoomed in, the earth is bigger than its box and stays inside it.
    if (zoom > 1) canvas.clipRect(Offset.zero & size);
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
    Offset? at(GlobeDot d) => project(
          cosPhi: math.cos(d.lat * toRadians),
          sinPhi: math.sin(d.lat * toRadians),
          cosLambda: math.cos(d.lon * toRadians),
          sinLambda: math.sin(d.lon * toRadians),
          r: r,
          cosR: cosR,
          sinR: sinR,
          cosT: cosT,
          sinT: sinT,
        );
    final points = [for (final d in dots) at(d)];

    // DR6–DR8: threads under the dots, arcing over the earth. A sample is
    // drawn while it faces the viewer or stands clear of the disc, so an arc
    // to the far side climbs over the horizon and goes behind it (SZ2).
    final mine = Path(), web = Path();
    final lights = <(Offset, bool)>[];
    for (var i = 0; i < threads.length && i < arcs.length; i++) {
      final pts = arcs[i];
      if (pts.isEmpty) continue;
      final path = threads[i].mine ? mine : web;
      var drawing = false;
      for (var k = 0; k < pts.length; k += 3) {
        final q = projectVec(pts[k], pts[k + 1], pts[k + 2], r: r, cosR: cosR, sinR: sinR, cosT: cosT, sinT: sinT);
        if (q == null) {
          drawing = false;
          continue;
        }
        final c = centre + q;
        if (drawing) {
          path.lineTo(c.dx, c.dy);
        } else {
          path.moveTo(c.dx, c.dy);
          drawing = true;
        }
      }
      if (flow >= 0) {
        // Each thread's light runs at its own pace from its own start.
        final seed = (i * 0.6180339887) % 1;
        final u = (seed + flow * (1 + (i % 5) * 0.25)) % 1;
        final k = (u * arcSamples).floor() * 3;
        final q = projectVec(pts[k], pts[k + 1], pts[k + 2], r: r, cosR: cosR, sinR: sinR, cosT: cosT, sinT: sinT);
        if (q != null) lights.add((centre + q, threads[i].mine));
      }
    }
    canvas.drawPath(web, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = const Color(0xFFAACDFF).withValues(alpha: 0.30));
    canvas.drawPath(mine, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = _you.withValues(alpha: 0.55));
    for (final (c, isMine) in lights) {
      canvas.drawCircle(c, isMine ? 2.4 : 1.8,
          Paint()..color = (isMine ? const Color(0xFFFFC480) : const Color(0xFFD2E6FF)).withValues(alpha: 0.95));
    }

    // DR3: Here today 1.5 radii west, Live 1.5 radii east, You on the point,
    // drawn last.
    for (final pass in [DotKind.here, DotKind.live, DotKind.you]) {
      for (var i = 0; i < dots.length; i++) {
        final dot = dots[i];
        final p = points[i];
        if (dot.kind != pass || p == null) continue;
        final c = centre + p + Offset(shiftOf(dot), 0);
        if (dot.kind == DotKind.you) {
          canvas.drawCircle(c, dot.radius + 6, Paint()..color = _you.withValues(alpha: 0.12 + 0.22 * breath));
          canvas.drawCircle(c, dot.radius, Paint()..color = _you.withValues(alpha: 0.45 + 0.55 * breath));
          continue;
        }
        final colour = dot.kind == DotKind.live ? live : here;
        canvas.drawCircle(
          c,
          dot.radius * 1.8,
          Paint()
            ..color = colour.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(c, dot.radius, Paint()..color = colour.withValues(alpha: 0.9));
      }
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

  /// [project] for a point given as a 3-D vector, which need not be on the
  /// surface: an arc's samples stand above it (DR8). Visible while it faces
  /// the viewer or, lifted, stands clear of the disc.
  static Offset? projectVec(
    double vx,
    double vy,
    double vz, {
    required double r,
    required double cosR,
    required double sinR,
    required double cosT,
    required double sinT,
  }) {
    final x = vy * cosR + vx * sinR;
    final z = vx * cosR - vy * sinR;
    final zt = vz * sinT + z * cosT;
    final yt = vz * cosT - z * sinT;
    if (zt <= 0 && x * x + yt * yt <= 1) return null;
    return Offset(x * r, -yt * r);
  }

  /// Where [lat], [lon] is in a globe of [size] (see [GlobeProjector]): the
  /// point itself on the near side, the nearest point of the rim when it is
  /// round the back.
  static ({Offset at, bool front}) locate({
    required double lat,
    required double lon,
    required double size,
    required double zoom,
    required double rotation,
    required double tilt,
  }) {
    const toRadians = math.pi / 180;
    final centre = Offset(size / 2, size / 2);
    final r = size / 2 * zoom;
    final phi = lat * toRadians, lambda = lon * toRadians;
    final cosR = math.cos(rotation), sinR = math.sin(rotation);
    final cosT = math.cos(tilt), sinT = math.sin(tilt);
    final p = project(
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
    if (p != null) return (at: centre + p, front: true);
    // The same rotations as [project], kept for the far side.
    final cosRot = math.cos(lambda) * cosR - math.sin(lambda) * sinR;
    final sinRot = math.sin(lambda) * cosR + math.cos(lambda) * sinR;
    final x = math.cos(phi) * sinRot;
    final y = math.sin(phi), z = math.cos(phi) * cosRot;
    final yt = y * cosT - z * sinT;
    final len = math.sqrt(x * x + yt * yt);
    final dir = len < 1e-9 ? const Offset(0, -1) : Offset(x / len, -yt / len);
    return (at: centre + dir * r, front: false);
  }

  /// TT1: the dot under [at] in a globe of [size], placed as [paint] places
  /// it (DR3), with a margin for a fingertip. Your dot wins a tie.
  static ({String cityId, Offset at})? dotAt({
    required List<GlobeDot> dots,
    required Offset at,
    required double size,
    required double zoom,
    required double rotation,
    required double tilt,
  }) {
    const toRadians = math.pi / 180;
    final centre = Offset(size / 2, size / 2);
    final r = size / 2 * zoom;
    final cosR = math.cos(rotation), sinR = math.sin(rotation);
    final cosT = math.cos(tilt), sinT = math.sin(tilt);
    ({String cityId, Offset at})? best;
    var bestD = double.infinity;
    for (final d in dots) {
      final p = project(
        cosPhi: math.cos(d.lat * toRadians),
        sinPhi: math.sin(d.lat * toRadians),
        cosLambda: math.cos(d.lon * toRadians),
        sinLambda: math.sin(d.lon * toRadians),
        r: r,
        cosR: cosR,
        sinR: sinR,
        cosT: cosT,
        sinT: sinT,
      );
      if (p == null) continue;
      final c = centre + p + Offset(shiftOf(d), 0);
      final dist = (c - at).distance - (d.kind == DotKind.you ? 2 : 0);
      if (dist <= math.max(d.radius, 10) + 8 && dist < bestD) {
        bestD = dist;
        best = (cityId: d.cityId, at: c);
      }
    }
    return best;
  }

  /// DR3: Here today 1.5 radii west, Live 1.5 radii east, You on the point.
  static double shiftOf(GlobeDot d) => switch (d.kind) {
        DotKind.here => -1.5 * d.radius,
        DotKind.live => 1.5 * d.radius,
        DotKind.you => 0.0,
      };

  @override
  bool shouldRepaint(GlobePainter old) =>
      old.zoom != zoom ||
      old.flow != flow ||
      old.arcs != arcs ||
      old.rotation != rotation ||
      old.tilt != tilt ||
      old.breath != breath ||
      old.dots != dots ||
      old.threads != threads ||
      old.outline != outline;
}
