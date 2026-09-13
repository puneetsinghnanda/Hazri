import 'package:flutter/material.dart';

import '../theme/hazri_colors.dart';

/// The brand mark: the day arc with the sun on the horizon.
///
/// It is the app icon, the splash and the header logo, so it is drawn rather
/// than shipped as a bitmap and picks up the theme colours.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 30, this.arcColor, this.sunColor});

  final double size;
  final Color? arcColor;
  final Color? sunColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _AppMarkPainter(arcColor ?? c.primary, sunColor ?? c.kesri),
      ),
    );
  }
}

class _AppMarkPainter extends CustomPainter {
  const _AppMarkPainter(this.arc, this.sun);

  final Color arc;
  final Color sun;

  @override
  void paint(Canvas canvas, Size size) {
    // Authored on the design's 40x40 grid, then scaled to fit.
    final s = size.width / 40;
    canvas.scale(s);

    final stroke = Paint()
      ..color = arc
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    // The sky arc: a semicircle of radius 16 centred at (20, 27).
    canvas.drawArc(Rect.fromCircle(center: const Offset(20, 27), radius: 16), 3.14159, 3.14159,
        false, stroke);
    // The horizon.
    canvas.drawLine(const Offset(6, 31.5), const Offset(34, 31.5), stroke);
    // The sun: a half-disc of radius 8 sitting on the horizon.
    canvas.drawPath(
      Path()
        ..moveTo(12, 27)
        ..arcToPoint(const Offset(28, 27), radius: const Radius.circular(8))
        ..close(),
      Paint()..color = sun,
    );
  }

  @override
  bool shouldRepaint(_AppMarkPainter old) => old.arc != arc || old.sun != sun;
}
