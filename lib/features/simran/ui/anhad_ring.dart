import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/hazri_colors.dart';
import '../domain/simran_track.dart';

/// ਅਨਹਦ ਨਾਦ — the unstruck sound, drawn.
///
/// One closed thread standing in the ring as a wave: a circle with a handful
/// of harmonics riding on it. Each Waheguru in the recitation feeds energy
/// into one of those harmonics, and between utterances they decay, so the
/// shape answers to what is being said rather than to a clock. Over the last
/// two minutes of the session the damping wins and the thread comes to rest as
/// a single circle — many, becoming one.
///
/// Nothing here is a figure. Waheguru is nirankar, without form, and the app
/// never depicts the Gurus (PRD §0); light and sound are what Gurbani gives us
/// to draw.
class AnhadRing extends StatefulWidget {
  const AnhadRing({
    super.key,
    required this.elapsed,
    required this.total,
    required this.running,
    this.track,
    this.size = 214,
    this.child,
  });

  /// How far into the session, which is also where the recitation is.
  final Duration elapsed;
  final Duration total;
  final bool running;

  /// Null before content.db has loaded, or in a build with no recitation: the
  /// wave then breathes on its own rather than disappearing.
  final SimranTrack? track;
  final double size;

  /// Sits at the centre of the wave and brightens on each Waheguru — the word
  /// itself answering to the recitation.
  final Widget? child;

  @override
  State<AnhadRing> createState() => _AnhadRingState();
}

/// Harmonics 2..7. Below 2 the shape just drifts off-centre; above 7 it reads
/// as noise at this size.
const _first = 2;
const _last = 7;

/// How far the thread may swell, as a fraction of its resting radius. Six
/// harmonics that happen to peak at the same angle would otherwise throw a
/// spike clear out of the ring, so the sum is bounded rather than each one.
const _maxSwell = 0.42;

class _AnhadRingState extends State<AnhadRing> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _amp = Float64List(_last + 1);
  final _phase = Float64List(_last + 1);

  /// How many utterances have already been fed in, so each one lands once.
  int _fed = 0;
  int _next = _first;
  Duration _lastFrame = Duration.zero;
  double _level = 0;

  /// The word's brightness. Rises with the voice and falls away between
  /// utterances, so it breathes rather than flickering at the frame rate.
  double _glow = 1;

  @override
  void initState() {
    super.initState();
    for (var k = _first; k <= _last; k++) {
      _phase[k] = k * 1.7; // spread, so they do not all start in step
    }
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didUpdateWidget(AnhadRing old) {
    super.didUpdateWidget(old);
    // A new session, or one wound back: start from stillness.
    if (widget.elapsed < old.elapsed) {
      _fed = 0;
      _amp.fillRange(0, _amp.length, 0);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _tick(Duration frame) {
    final dt = _lastFrame == Duration.zero
        ? 0.016
        : ((frame - _lastFrame).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastFrame = frame;

    final track = widget.track;
    if (track != null && widget.running) {
      final due = track.onsetsBefore(widget.elapsed);
      // Cap the catch-up: coming back from a locked screen must not dump two
      // minutes of utterances into the wave at once.
      for (var i = math.max(_fed, due - 4); i < due; i++) {
        _amp[_next] = math.min(0.20, _amp[_next] + 0.075 * (0.5 + track.levelAt(track.onsets[i])));
        _next = _next >= _last ? _first : _next + 1;
      }
      _fed = due;
      _level = track.levelAt(widget.elapsed);
    } else if (track == null && widget.running) {
      // No recitation to follow: a slow breath keeps the thread alive.
      _level = 0.5 + 0.5 * math.sin(frame.inMilliseconds / 1000 * 0.6);
      for (var k = _first; k <= _last; k++) {
        _amp[k] = 0.055 * (0.6 + 0.4 * math.sin(frame.inMilliseconds / 1000 * 0.21 * k));
      }
    }

    _glow = math.max(_glow * math.exp(-dt / 1.1), _level);

    final decay = math.exp(-dt / 3.6);
    for (var k = _first; k <= _last; k++) {
      if (widget.track != null) _amp[k] *= decay;
      _phase[k] += dt * (0.06 + k * 0.013);
    }
    setState(() {});
  }

  /// Scales the harmonics back when together they would overflow the ring.
  double _swellLimit() {
    var total = 0.0;
    for (var k = _first; k <= _last; k++) {
      total += _amp[k];
    }
    return total > _maxSwell ? _maxSwell / total : 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final p = widget.total.inMilliseconds == 0
        ? 0.0
        : (widget.elapsed.inMilliseconds / widget.total.inMilliseconds).clamp(0.0, 1.0);
    // Full strength for most of the session; the resolve is the closing act,
    // not a slow fade nobody notices.
    final damp = p < 0.55 ? 1.0 : math.pow(1 - (p - 0.55) / 0.45, 1.6).toDouble();

    final word = widget.child;
    return SizedBox.square(
      dimension: widget.size,
      child: CustomPaint(
        painter: _AnhadPainter(
          amp: _amp,
          phase: _phase,
          damp: damp * _swellLimit(),
          level: _level,
          field: c.simranField,
          thread: c.simranThread,
          halo: c.teal,
        ),
        child: word == null
            ? null
            : Center(
                child: Opacity(
                  opacity: widget.running ? (0.34 + 0.66 * _glow).clamp(0.0, 1.0) : 1.0,
                  child: word,
                ),
              ),
      ),
    );
  }
}

class _AnhadPainter extends CustomPainter {
  _AnhadPainter({
    required this.amp,
    required this.phase,
    required this.damp,
    required this.level,
    required this.field,
    required this.thread,
    required this.halo,
  });

  final Float64List amp;
  final Float64List phase;
  final double damp;
  final double level;
  final Color field;
  final Color thread;
  final Color halo;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = size.width / 2;

    // The disc keeps its night field in either theme: a luminous thread has
    // nothing to be luminous against on a light ground.
    canvas.drawCircle(centre, r, Paint()..color = field);

    // The circle the wave is always resolving towards.
    canvas.drawCircle(
      centre,
      r * 0.60 * 0.30,
      Paint()
        ..color = halo.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Three ghosts of where the thread just was, then the thread itself.
    for (var ghost = 3; ghost >= 0; ghost--) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = ghost == 0 ? 1.7 : 1.1
        ..strokeJoin = StrokeJoin.round
        ..color = ghost == 0
            ? thread.withValues(alpha: 0.95)
            : halo.withValues(alpha: 0.13 / ghost)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          ghost == 0 ? 1.4 + level * 1.6 : 2.4,
        );
      canvas.drawPath(_thread(centre, r, ghost * 0.09), paint);
    }
    // Again without the blur, so the thread has an edge and not only a glow.
    canvas.drawPath(
      _thread(centre, r, 0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeJoin = StrokeJoin.round
        ..color = thread,
    );
  }

  Path _thread(Offset centre, double r, double lag) {
    const steps = 200;
    final base = r * 0.60;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final th = i / steps * 2 * math.pi;
      var rad = base;
      for (var k = _first; k <= _last; k++) {
        rad += base * amp[k] * damp * math.sin(k * th + phase[k] - lag * k * 0.3);
      }
      rad = math.min(rad, r * 0.94);
      final o = centre + Offset(math.cos(th) * rad, math.sin(th) * rad);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_AnhadPainter old) => true;
}
