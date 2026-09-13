import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/hazri_colors.dart';

/// How far through a bani's slot the day has got.
enum ArcNodeState { done, active, todo }

/// One labelled point on the day arc.
@immutable
class DayArcNode {
  const DayArcNode({required this.label, required this.at, required this.state});

  /// Short label under the arc, e.g. "Rehras · 8 PM".
  final String label;

  /// The slot's time today.
  final DateTime at;

  final ArcNodeState state;
}

/// The day arc: a semicircular track with a node per Nitnem slot and a sun dot
/// marking now (PRD 1.3).
///
/// The arc spans from half an hour before Amrit Vela to half an hour after
/// Kirtan Sohila, so the whole Nitnem day fits between the two ends.
class DayArc extends StatelessWidget {
  const DayArc({
    super.key,
    required this.nodes,
    required this.now,
    required this.windowStart,
    required this.windowEnd,
    this.centre,
    this.width = 272,
  });

  final List<DayArcNode> nodes;
  final DateTime now;
  final DateTime windowStart;
  final DateTime windowEnd;

  /// The "n of 5" block drawn inside the arc.
  final Widget? centre;

  final double width;

  /// Maps a time onto 0..1 along the arc.
  ///
  /// `t = clamp((now - (amritVela - 30min)) / ((sohila + 30min) - (amritVela - 30min)), 0, 1)`
  static double fractionFor(DateTime at, DateTime start, DateTime end) {
    final span = end.difference(start).inSeconds;
    if (span <= 0) return 0;
    return (at.difference(start).inSeconds / span).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final height = width * (143 / 272);
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _DayArcPainter(
                colors: c,
                sunAt: fractionFor(now, windowStart, windowEnd),
                nodes: [
                  for (final n in nodes)
                    (fractionFor(n.at, windowStart, windowEnd), n.state),
                ],
              ),
            ),
          ),
          if (centre != null)
            Positioned(left: 0, right: 0, bottom: height * 0.07, child: Center(child: centre!)),
        ],
      ),
    );
  }
}

class _DayArcPainter extends CustomPainter {
  _DayArcPainter({required this.colors, required this.sunAt, required this.nodes});

  final HazriColors colors;
  final double sunAt;
  final List<(double, ArcNodeState)> nodes;

  /// Nodes are kept off the arc's round caps so they stay fully legible.
  static const double _inset = 0.03;

  @override
  void paint(Canvas canvas, Size size) {
    // Authored on the design's 320x168 viewBox.
    final s = size.width / 320;
    canvas.scale(s);
    const centre = Offset(160, 150);
    const r = 128.0;
    final rect = Rect.fromCircle(center: centre, radius: r);

    Offset at(double t) {
      final a = math.pi * t.clamp(0.0, 1.0);
      return Offset(centre.dx - r * math.cos(a), centre.dy - r * math.sin(a));
    }

    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = colors.rule
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );

    if (sunAt > 0.001) {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * sunAt,
        false,
        Paint()
          ..color = colors.kesri
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final (t, state) in nodes) {
      final p = at(_inset + t * (1 - 2 * _inset));
      switch (state) {
        case ArcNodeState.done:
          canvas.drawCircle(p, 9, Paint()..color = colors.sage);
          final tick = Path()
            ..moveTo(p.dx - 4, p.dy)
            ..lineTo(p.dx - 1.2, p.dy + 3)
            ..lineTo(p.dx + 4.2, p.dy - 3.2);
          canvas.drawPath(
            tick,
            Paint()
              ..color = colors.card
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
        case ArcNodeState.active:
          canvas.drawCircle(p, 9, Paint()..color = colors.card);
          canvas.drawCircle(
            p,
            9,
            Paint()
              ..color = colors.kesri
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3,
          );
        case ArcNodeState.todo:
          canvas.drawCircle(p, 7, Paint()..color = colors.card);
          canvas.drawCircle(
            p,
            7,
            Paint()
              ..color = colors.muted
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
      }
    }

    // The sun marking now, with its glow.
    final sun = at(sunAt);
    canvas.drawCircle(sun, 13, Paint()..color = colors.kesri.withValues(alpha: 0.18));
    canvas.drawCircle(sun, 6, Paint()..color = colors.kesri);
  }

  @override
  bool shouldRepaint(_DayArcPainter old) =>
      old.sunAt != sunAt || old.nodes != nodes || old.colors != colors;
}
