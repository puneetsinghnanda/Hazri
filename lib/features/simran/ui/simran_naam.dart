import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/theme/hazri_text.dart';
import '../domain/simran_track.dart';

/// ਵਾਹਿਗੁਰੂ drifting off the globe, one for each utterance.
///
/// A word appears when the reciter says one and not on a timer of its own:
/// `SimranTrack.onsets` records where every Waheguru begins, measured off the
/// recording when the app was built, so this follows the voice rather than
/// decorating it. With no recitation there are no words — an invented rhythm
/// would be the screen saying something it does not know.
///
/// The word itself is passed in, never composed here.
class SimranNaam extends StatefulWidget {
  const SimranNaam({
    super.key,
    required this.size,
    required this.word,
    required this.track,
    required this.elapsed,
    required this.running,
  });

  /// The globe's diameter. Words start near its rim and drift outward.
  final double size;
  final String word;
  final SimranTrack? track;
  final Duration elapsed;

  /// Spawning stops when a sitting is paused; what is already in the air
  /// finishes fading rather than vanishing.
  final bool running;

  @override
  State<SimranNaam> createState() => _SimranNaamState();
}

class _SimranNaamState extends State<SimranNaam>
    with SingleTickerProviderStateMixin {
  /// Started in [initState], not in the field itself: a `late final` field
  /// is only built when something reads it, and nothing read this one until
  /// `dispose`, so the ticker was never created and no word ever appeared.
  late final Ticker _ticker;

  final _words = <_Naam>[];

  /// How many utterances have already been put in the air.
  int _fed = 0;
  double _now = 0;

  /// Seconds from a word appearing to it being gone.
  static const _life = 3.6;

  /// Spread successive words around the globe by the golden angle, so three
  /// in a row never land on top of each other and the ring never repeats.
  static const _goldenAngle = 2.39996322972865332;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onFrame)..start();
  }

  @override
  void didUpdateWidget(SimranNaam old) {
    super.didUpdateWidget(old);
    // A new sitting, or one wound back: start from silence.
    if (widget.elapsed < old.elapsed) {
      _fed = 0;
      _words.clear();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onFrame(Duration frame) {
    _now = frame.inMicroseconds / 1e6;
    final track = widget.track;
    if (track != null && widget.running) {
      final due = track.onsetsBefore(widget.elapsed);
      // Cap the catch-up. Coming back from a locked screen must not throw two
      // minutes of utterances into the air at once.
      for (var i = math.max(_fed, due - 3); i < due; i++) {
        _words.add(
          _Naam(
            born: _now,
            angle: i * _goldenAngle,
            // Louder utterances start a little further out and a little
            // larger, so the drift answers the voice rather than a counter.
            loudness: track.levelAt(track.onsets[i]),
          ),
        );
      }
      _fed = due;
    }
    _words.removeWhere((w) => _now - w.born > _life);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Motion is the whole of this, so there is nothing to show standing
    // still. It is decoration, and the screen is complete without it.
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: CustomPaint(
        // Room for a word to leave the globe before it is gone.
        size: Size.square(widget.size * 1.5),
        painter: _NaamPainter(
          words: List.of(_words),
          now: _now,
          life: _life,
          radius: widget.size / 2,
          text: widget.word,
        ),
      ),
    );
  }
}

class _Naam {
  _Naam({required this.born, required this.angle, required this.loudness});

  final double born;
  final double angle;
  final double loudness;
}

class _NaamPainter extends CustomPainter {
  _NaamPainter({
    required this.words,
    required this.now,
    required this.life,
    required this.radius,
    required this.text,
  });

  final List<_Naam> words;
  final double now;
  final double life;

  /// The globe's radius, which is where a word sets out from.
  final double radius;
  final String text;

  static const _colour = Color(0xFFFFE6C2);

  @override
  void paint(Canvas canvas, Size size) {
    if (words.isEmpty) return;
    final centre = Offset(size.width / 2, size.height / 2);

    for (final w in words) {
      final t = ((now - w.born) / life).clamp(0.0, 1.0);
      final opacity = _opacityAt(t);
      if (opacity <= 0.01) continue;

      // Out from the rim, slowing as it goes: eased so a word leaves quickly
      // and then hangs, rather than sliding at a constant speed.
      final eased = 1 - math.pow(1 - t, 2.2).toDouble();
      final from = radius * (0.74 + 0.10 * w.loudness);
      final distance = from + radius * (0.42 + 0.10 * w.loudness) * eased;
      // And a little way round the globe as it rises, so the whole field
      // turns with it.
      final angle = w.angle + 0.22 * eased;
      final at = centre +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance);

      final scale = 0.88 + 0.16 * eased + 0.08 * w.loudness;
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: SimranText.naam.copyWith(
            color: _colour.withValues(alpha: opacity),
            shadows: [
              Shadow(
                color: const Color(0xFFF2A24E).withValues(alpha: opacity * 0.6),
                blurRadius: 12,
              ),
            ],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(at.dx, at.dy);
      canvas.scale(scale);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    }
  }

  /// Up fast, held bright, then away.
  ///
  /// It holds near full for more than half its life: a word that starts
  /// fading the moment it appears reads as a smudge, and the point is to be
  /// able to read it.
  static double _opacityAt(double t) {
    if (t < 0.12) return t / 0.12 * 0.95;
    if (t < 0.62) return 0.95;
    return 0.95 * (1 - (t - 0.62) / 0.38);
  }

  @override
  bool shouldRepaint(_NaamPainter old) => true;
}
