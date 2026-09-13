import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/hazri_colors.dart';

/// The ring used on Nitnem rows, goal cards and the Simran timer.
///
/// `progress` of 1.0 with [done] set draws the filled sage tick instead of a
/// ring, which is how the design marks a bani finished today.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 34,
    this.strokeWidth = 3,
    this.done = false,
    this.colour,
    this.trackColour,
    this.child,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final bool done;
  final Color? colour;
  final Color? trackColour;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: done ? 1 : progress.clamp(0.0, 1.0),
          stroke: strokeWidth,
          colour: colour ?? (done ? c.sage : c.kesri),
          track: trackColour ?? c.rule,
          fill: done ? c.sage : null,
          tick: done ? c.card : null,
        ),
        child: child == null ? null : Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.stroke,
    required this.colour,
    required this.track,
    this.fill,
    this.tick,
  });

  final double progress;
  final double stroke;
  final Color colour;
  final Color track;
  final Color? fill;
  final Color? tick;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    if (fill != null) {
      canvas.drawCircle(centre, size.width / 2, Paint()..color = fill!);
      final r = size.width;
      final path = Path()
        ..moveTo(centre.dx - r * 0.17, centre.dy + r * 0.01)
        ..lineTo(centre.dx - r * 0.045, centre.dy + r * 0.13)
        ..lineTo(centre.dx + r * 0.18, centre.dy - r * 0.12);
      canvas.drawPath(
        path,
        Paint()
          ..color = tick!
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(2, r * 0.075)
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
      return;
    }

    canvas.drawCircle(
      centre,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = colour
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.colour != colour || old.fill != fill;
}
