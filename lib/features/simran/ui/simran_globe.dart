import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../sangat/domain/simran_presence.dart';

/// Design 29's globe: the earth seen from space, with a light where somebody
/// is sitting.
///
/// An orthographic projection, which is what a photograph of a sphere is: a
/// point at latitude φ and longitude λ lands where its 3-D position falls on
/// the picture plane, and is drawn only when it faces the viewer. That one
/// rule gives the horizon, the foreshortening at the edge and the dots
/// disappearing round the back, with no 3-D engine involved.
class SimranGlobe extends StatefulWidget {
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
  State<SimranGlobe> createState() => _SimranGlobeState();
}

class _SimranGlobeState extends State<SimranGlobe> with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    // One turn every two minutes: visible if you watch, invisible if you do
    // not, and cheap either way.
    duration: const Duration(seconds: 120),
  );

  /// Where the hand has turned it to, on top of the spin.
  double _dragged = 0;

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _spin.repeat();
  }

  @override
  void didUpdateWidget(SimranGlobe old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_spin.isAnimating) {
      _spin.repeat();
    } else if (!widget.spinning && _spin.isAnimating) {
      _spin.stop();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion && _spin.isAnimating) _spin.stop();

    return GestureDetector(
      onHorizontalDragUpdate: (d) => setState(() {
        // A drag across the whole globe turns it half way round, which is
        // about what a hand on a real one does.
        _dragged += d.delta.dx / widget.size * math.pi;
      }),
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _GlobePainter(
            cities: widget.presence.cities,
            rotation: _dragged + (reduceMotion ? 0 : _spin.value * 2 * math.pi),
          ),
        ),
      ),
    );
  }
}

class _GlobePainter extends CustomPainter {
  _GlobePainter({required this.cities, required this.rotation});

  final List<PresenceCity> cities;
  final double rotation;

  /// The globe's own palette, not the theme's. It is a night sky on both
  /// themes, the way design 29 draws it, and a light-theme globe would be a
  /// different object rather than the same one repainted.
  static const _sea = Color(0xFF080B1C);
  static const _grid = Color(0xFF2A3A6B);
  static const _light = Color(0xFFE8F4F8);
  static const _halo = Color(0xFF6FC3D3);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final centre = Offset(r, r);

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

    canvas.drawCircle(
      centre,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = _grid,
    );

    for (final city in cities) {
      final point = _project(city, r, rotation);
      if (point == null) continue;
      // Bigger where more people are sitting, but gently: a city of two is
      // not twice the light of a city of one.
      final radius = 1.8 + math.min(3.4, math.log(city.count + 1) * 1.1);
      canvas.drawCircle(
        centre + point,
        radius * 2.6,
        Paint()
          ..color = _halo.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawCircle(centre + point, radius, Paint()..color = _light);
    }
  }

  /// Where a city lands on the picture plane, or null when it is round the
  /// back. z > 0 is the near side; everything else is hidden by the earth
  /// itself, which is what makes this read as a sphere rather than a disc.
  static Offset? _project(PresenceCity city, double r, double rotation) {
    final phi = city.lat * math.pi / 180;
    final lambda = city.lon * math.pi / 180 + rotation;
    final z = math.cos(phi) * math.cos(lambda);
    if (z <= 0) return null;
    return Offset(math.cos(phi) * math.sin(lambda) * r, -math.sin(phi) * r);
  }

  @override
  bool shouldRepaint(_GlobePainter old) =>
      old.rotation != rotation || old.cities != cities;
}
