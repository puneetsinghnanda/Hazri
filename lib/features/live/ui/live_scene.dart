import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../simran/domain/world_outline.dart';
import '../domain/live_group.dart';

/// A live group's scene (15-live-sangat LS12-LS14), ported from
/// `tools/design/live_scenes.js`: drawn, not played as video, looping every
/// 30 seconds and breathing every 6. With reduced motion it is the still at
/// 8 seconds. No person is drawn (LS14).
///
/// [word] is the word the scene carries: ਵਾਹਿਗੁਰੂ from the ARB files for the
/// globe, ੴ from content.db for the stars (LS13); the jot carries none.
class LiveSceneView extends ConsumerStatefulWidget {
  const LiveSceneView({
    super.key,
    required this.scene,
    this.word = '',
    this.dots = const [],
    this.you,
    this.compact = false,
    this.animate = true,
  });

  final LiveScene scene;
  final String word;

  /// Cities with a listener, as (latitude, longitude) in degrees.
  final List<(double, double)> dots;

  /// Your own city, drawn orange.
  final (double, double)? you;

  /// A card rather than the full page: the globe sits lower and the word smaller.
  final bool compact;
  final bool animate;

  @override
  ConsumerState<LiveSceneView> createState() => _LiveSceneViewState();
}

class _LiveSceneViewState extends ConsumerState<LiveSceneView> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 30));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _run();
  }

  @override
  void didUpdateWidget(LiveSceneView old) {
    super.didUpdateWidget(old);
    _run();
  }

  void _run() {
    final still = !widget.animate || MediaQuery.disableAnimationsOf(context);
    if (still) {
      _c
        ..stop()
        ..value = 8 / 30;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outline = widget.scene == LiveScene.globe
        ? ref.watch(worldOutlineProvider).value ?? WorldOutline.empty
        : WorldOutline.empty;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) => CustomPaint(
          size: Size.infinite,
          painter: LiveScenePainter(
            scene: widget.scene,
            t: _c.value * 30,
            word: widget.word,
            dots: widget.dots,
            you: widget.you,
            compact: widget.compact,
            outline: outline,
          ),
        ),
      ),
    );
  }
}

const _tau = math.pi * 2;
const _d2r = math.pi / 180;

double _wrap(double v, double m) => ((v % m) + m) % m;

/// A small seeded generator, the same as the design's, so the stars sit
/// where they sit in designs 125-129.
class _Rng {
  _Rng(this._seed);
  double _seed;
  double call() {
    _seed = (_seed * 1664525 + 1013904223) % 4294967296;
    return _seed / 4294967296;
  }
}

class LiveScenePainter extends CustomPainter {
  LiveScenePainter({
    required this.scene,
    required this.t,
    required this.word,
    required this.dots,
    required this.you,
    required this.compact,
    required this.outline,
  });

  final LiveScene scene;
  final double t;
  final String word;
  final List<(double, double)> dots;
  final (double, double)? you;
  final bool compact;
  final WorldOutline outline;

  double get _p => t / 30;
  double get _b => 0.5 - 0.5 * math.cos(_tau * t / 6);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    switch (scene) {
      case LiveScene.globe:
        _globe(canvas, size);
      case LiveScene.ikonkar:
        _ikonkar(canvas, size);
      case LiveScene.jot:
        _jot(canvas, size);
    }
    canvas.restore();
  }

  void _glow(Canvas c, Offset at, double r, Color inner, Color outer, {double from = 0}) {
    if (r <= 0) return;
    c.drawCircle(
      at,
      r,
      Paint()
        ..blendMode = BlendMode.plus
        ..shader = ui.Gradient.radial(at, r, [inner, outer], [from, 1]),
    );
  }

  void _background(Canvas c, Size s, Offset centre, double radius, List<Color> colours) {
    c.drawRect(
      Offset.zero & s,
      Paint()..shader = ui.Gradient.radial(centre, radius, colours, const [0, 0.5, 1]),
    );
  }

  void _stars(Canvas c, Size s, int seed, double per, Color colour) {
    final r = _Rng(seed.toDouble());
    final n = (s.width * s.height / per).floor();
    final paint = Paint();
    for (var i = 0; i < n; i++) {
      final x = r() * s.width, y = r() * s.height, f = 1 + (r() * 3).floor(), ph = r();
      final a = (0.3 + 0.7 * (0.5 + 0.5 * math.sin(_tau * (_p * f + ph)))) * (0.35 + r() * 0.65);
      c.drawCircle(Offset(x, y), 0.4 + r(), paint..color = colour.withValues(alpha: a.clamp(0, 1)));
    }
  }

  /// The word in gold with a light sweeping across it once a breath.
  void _word(Canvas c, Offset at, double size, double alpha) {
    if (word.isEmpty) return;
    final sweep = (_wrap(t / 6, 1) * 1.4 - 0.2).clamp(0.13, 0.87);
    final w = size * 2.2;
    final shader = ui.Gradient.linear(
      Offset(at.dx - w, 0),
      Offset(at.dx + w, 0),
      const [Color(0xFFB8741F), Color(0xFFE7A94A), Color(0xFFFFF3D0), Color(0xFFE7A94A), Color(0xFFB8741F)],
      [0, sweep - 0.12, sweep, sweep + 0.12, 1],
    );
    final tp = TextPainter(
      text: TextSpan(
        text: word,
        style: TextStyle(
          fontFamily: 'NotoSerifGurmukhi',
          fontWeight: FontWeight.w700,
          fontSize: size,
          height: 1.2,
          foreground: Paint()..shader = shader,
          shadows: [Shadow(color: const Color(0xFFFFBE5A).withValues(alpha: 0.9 * alpha), blurRadius: size * 0.6)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    c.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: alpha.clamp(0, 1)));
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
    c.restore();
  }

  // ---------------------------------------------------------------- globe

  void _globe(Canvas c, Size s) {
    final w = s.width, h = s.height;
    // On the page the word sits under the names that join and above the
    // globe; on a card, near the top.
    final cx = w / 2, cy = h * (compact ? 0.48 : 0.66), r = w * (compact ? 0.36 : 0.4);
    final lx = w / 2, ly = h * (compact ? 0.18 : 0.35), ws = compact ? w * 0.09 : w * 0.085;
    _background(c, s, Offset(cx, cy), math.max(w, h),
        const [Color(0xFF1C2366), Color(0xFF0C1038), Color(0xFF03040F)]);
    _stars(c, s, 23, 900, const Color(0xFFDDE6FF));

    final rot = -_tau * _p + 0.4;
    const tilt = 0.38;
    final cosR = math.cos(rot), sinR = math.sin(rot);
    final cosT = math.cos(tilt), sinT = math.sin(tilt);
    // (x, y, depth) on screen for a point given by its cos and sin.
    (double, double, double) proj(double cp, double sp, double cl, double sl) {
      final slo = sl * cosR + cl * sinR, clo = cl * cosR - sl * sinR;
      final x = cp * slo, z0 = cp * clo, y0 = sp;
      return (cx + r * x, cy - r * (y0 * cosT - z0 * sinT), y0 * sinT + z0 * cosT);
    }

    (double, double, double) projDeg(double lat, double lon) =>
        proj(math.cos(lat * _d2r), math.sin(lat * _d2r), math.cos(lon * _d2r), math.sin(lon * _d2r));

    _glow(c, Offset(cx, cy), r * 1.3, const Color(0x52_6EA0FF), const Color(0x003C5ADC), from: 0.76);
    c.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = ui.Gradient.radial(Offset(cx - r * 0.35, cy - r * 0.45), r * 1.2,
            const [Color(0xFF24439A), Color(0xFF0A1440)]),
    );

    if (outline.arcCount > 0) {
      final path = Path();
      final trig = outline.trig, starts = outline.starts;
      for (var a = 0; a < outline.arcCount; a++) {
        var pen = false;
        for (var p = starts[a]; p < starts[a + 1]; p++) {
          final i = p * 4;
          final (x, y, z) = proj(trig[i], trig[i + 1], trig[i + 2], trig[i + 3]);
          if (z < 0) {
            pen = false;
            continue;
          }
          pen ? path.lineTo(x, y) : path.moveTo(x, y);
          pen = true;
        }
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.5, r / 170)
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xBFAACDFF),
      );
    }
    c.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x8096BEFF),
    );

    final b = _b;
    _glow(c, Offset(lx, ly), ws * 2.6 + 18 * b, const Color(0xB3FFE6AA), const Color(0x00FFA03C));
    final all = [if (you != null) you!, ...dots];
    for (var i = 0; i < all.length; i++) {
      final (lat, lon) = all[i];
      final (x, y, z) = projDeg(lat, lon);
      if (z < 0.08) continue;
      final vis = math.min(1.0, z * 2.4);
      final c1 = Offset(x + (x - cx) * 0.25, (y + ly) / 2 - 20), c2 = Offset(lx, ly + ws * 1.6);
      Offset at(double u) {
        final a = math.pow(1 - u, 3).toDouble(), bb = 3 * (1 - u) * (1 - u) * u, cc = 3 * (1 - u) * u * u, d = u * u * u;
        return Offset(a * x + bb * c1.dx + cc * c2.dx + d * lx, a * y + bb * c1.dy + cc * c2.dy + d * ly);
      }

      c.drawPath(
        Path()
          ..moveTo(x, y)
          ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, lx, ly),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = Color.fromRGBO(255, 200, 120, 0.13 * vis),
      );
      final u = _wrap(t / 6 + i * 0.137, 1);
      _glow(c, at(u), 4.5, Color.fromRGBO(255, 232, 185, vis * math.sin(math.pi * u)), const Color(0x00FFB450));
      if (you != null && i == 0) {
        final k = 0.5 + 0.5 * math.sin(_tau * t / 1.6);
        _glow(c, Offset(x, y), 8 + 4 * k, Color.fromRGBO(255, 190, 90, vis), const Color(0x00F2A24E));
      } else {
        _glow(c, Offset(x, y), 4 + 2 * b, Color.fromRGBO(110, 255, 170, 0.95 * vis), const Color(0x0028C878));
      }
    }
    _word(c, Offset(lx, ly), ws, 0.78 + 0.22 * b);
  }

  // ---------------------------------------------------------------- ikonkar

  void _ikonkar(Canvas c, Size s) {
    final w = s.width, h = s.height, b = _b;
    final cx = w / 2, cy = h * (compact ? 0.4 : 0.42), m = math.min(w, h) * (compact ? 0.32 : 0.34);
    _background(c, s, Offset(cx, cy), math.max(w, h) * 0.8,
        const [Color(0xFF2A2052), Color(0xFF0D0C2A), Color(0xFF05040F)]);
    _stars(c, s, 77, 600, const Color(0xFFFFF0D7));
    const n = 13;
    final joined = math.sin(math.pi * _p) * n;
    final pts = [
      for (var i = 0; i < n; i++)
        Offset(cx + math.cos(-math.pi / 2 + _tau * i / n) * m * (1 + 0.04 * b),
            cy + math.sin(-math.pi / 2 + _tau * i / n) * m * (1 + 0.04 * b)),
    ];
    final line = Paint()
      ..color = const Color(0x73FFD696)
      ..blendMode = BlendMode.plus;
    for (var i = 0; i < n; i++) {
      final f = (joined - i).clamp(0.0, 1.0);
      if (f == 0) continue;
      final a = pts[i], z = pts[(i + 1) % n];
      c.drawLine(a, Offset.lerp(a, z, f)!, line);
    }
    for (var i = 0; i < n; i++) {
      _glow(c, pts[i], 5 + 2 * b, Color.fromRGBO(255, 232, 190, i < joined ? 1 : 0.6), const Color(0x00FFAA50));
    }
    _glow(c, Offset(cx, cy), m * 0.9, Color.fromRGBO(255, 200, 110, 0.25 + 0.15 * b), const Color(0x00FF8C28));
    _word(c, Offset(cx, cy + m * 0.05), m * 0.95, 0.85 + 0.15 * b);
  }

  // ---------------------------------------------------------------- jot

  void _jot(Canvas c, Size s) {
    final w = s.width, h = s.height, b = _b, p = _p;
    final cx = w / 2, by = h * (compact ? 0.55 : 0.62);
    _background(c, s, Offset(cx, by), math.max(w, h),
        const [Color(0xFF3A1606), Color(0xFF170A12), Color(0xFF07050E)]);
    final r = math.min(w * 0.42, h * (compact ? 0.3 : 0.4));
    _glow(c, Offset(cx, by - r * 0.25), r * 1.2, const Color(0x52FFAA46), const Color(0x00FF781E));
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.plus;
    for (var k = 0; k < 9; k++) {
      final ph = _wrap(k / 9 + p, 1), sx = math.cos(_tau * ph) * r;
      if (math.sin(_tau * ph) < 0) continue;
      stroke.color = Color.fromRGBO(255, 214, 140, 0.08 + 0.3 * math.sin(_tau * ph));
      c.drawArc(Rect.fromCenter(center: Offset(cx, by), width: sx.abs() * 2, height: r * 2), math.pi, math.pi, false, stroke);
    }
    for (var k = 1; k < 4; k++) {
      final rr = r * math.cos(k * 0.38), yy = by - r * math.sin(k * 0.38);
      stroke.color = const Color(0x24FFD68C);
      c.drawOval(Rect.fromCenter(center: Offset(cx, yy), width: rr * 2, height: rr * 0.32), stroke);
    }
    c.drawArc(
      Rect.fromCircle(center: Offset(cx, by), radius: r),
      math.pi,
      math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..blendMode = BlendMode.plus
        ..color = Color.fromRGBO(255, 224, 160, 0.45 + 0.3 * b),
    );
    final rng = _Rng(8);
    final spark = Paint()..blendMode = BlendMode.plus;
    for (var i = 0; i < 40; i++) {
      final x = cx + (rng() - 0.5) * r * 1.2;
      final y = by - _wrap(rng() + p * (1 + (rng() * 2).floor()), 1) * r;
      spark.color = Color.fromRGBO(255, 200, 120, 0.25 + rng() * 0.5);
      c.drawCircle(Offset(x, y), 0.6 + rng(), spark);
    }
    final fl = 1 + 0.06 * math.sin(_tau * t * 1.7) + 0.04 * math.sin(_tau * t * 2.9);
    final fh = r * 0.42 * fl * (0.92 + 0.12 * b), fw = r * 0.12;
    _glow(c, Offset(cx, by - fh * 0.55), fh * 1.1, const Color(0xBFFFDC8C), const Color(0x00FF8C28));
    final tip = cx + math.sin(_tau * t * 1.3) * 2;
    c.drawPath(
      Path()
        ..moveTo(tip, by - fh - 8)
        ..cubicTo(cx + fw * 1.3, by - fh * 0.45, cx + fw, by - 6, cx, by - 6)
        ..cubicTo(cx - fw, by - 6, cx - fw * 1.3, by - fh * 0.45, tip, by - fh - 8),
      Paint()
        ..shader = ui.Gradient.linear(Offset(0, by - fh - 10), Offset(0, by - 6),
            const [Color(0xFFFFF6D8), Color(0xFFFFC860), Color(0xFFE8652A)], const [0, 0.5, 1]),
    );
    final bowl = Rect.fromCenter(center: Offset(cx, by), width: r * 0.72, height: r * 0.22);
    c.drawArc(bowl, 0, math.pi, true, Paint()..color = const Color(0xFF9C5A1E));
    c.drawOval(Rect.fromCenter(center: Offset(cx, by), width: r * 0.72, height: r * 0.1),
        Paint()..color = const Color(0xFFD99A3E));
  }

  @override
  bool shouldRepaint(LiveScenePainter old) =>
      old.t != t || old.word != word || old.dots != dots || old.you != you || old.outline != outline;
}
