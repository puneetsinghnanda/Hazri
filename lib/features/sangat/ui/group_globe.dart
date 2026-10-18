import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../simran/data/presence_repository.dart';
import '../../simran/domain/simran_presence.dart';
import '../../simran/ui/simran_globe.dart';
import '../data/group_globe_controller.dart';
import '../domain/group_globe.dart';
import 'sangat_widgets.dart';

/// Design option C (08-sangat GG1): the goal ring wraps the group's globe,
/// the arrivals run into the ring's leading edge (GG4).
class GroupGlobeRing extends ConsumerWidget {
  const GroupGlobeRing({super.key, required this.groupId, required this.progress, required this.colour});

  final String groupId;

  /// The goal's share done, 0 to 1: where the ring's leading edge is.
  final double progress;
  final Color colour;

  /// The design's measures: a 214 dp ring of 9 dp round a 190 dp globe.
  static const ringSize = 214.0;
  static const ringStroke = 9.0;
  static const globeSize = 190.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final drawing = ref.watch(groupGlobeDrawingProvider(groupId));
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final positions = ref.watch(cityPositionsProvider);
    return SizedBox.square(
      dimension: ringSize,
      child: Center(
        child: RepaintBoundary(
          child: SimranGlobe(
            dots: drawing.dots,
            threads: drawing.threads,
            arcs: drawing.arcs,
            youLive: drawing.viewer?.today ?? false,
            cityNames: ref.watch(cityNamesProvider(Localizations.localeOf(context).languageCode)),
            size: globeSize,
            liveTip: l.sangatGlobeTipToday,
            hereTip: l.sangatGlobeTipNotYet,
            overlay: (context, project) => OverflowBox(
              maxWidth: ringSize,
              maxHeight: ringSize,
              child: SizedBox.square(
                dimension: ringSize,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ProgressRing(
                      size: ringSize,
                      strokeWidth: ringStroke,
                      progress: progress,
                      colour: colour,
                      trackColour: Colors.white.withValues(alpha: 0.16),
                    ),
                    Positioned.fill(
                      child: GroupTethers(dots: drawing.dots, project: project, progress: progress),
                    ),
                    Positioned.fill(
                      child: GroupArrivals(
                        arrivals: drawing.arrivals,
                        positions: positions,
                        project: project,
                        progress: progress,
                        enabled: !reduceMotion,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// GG1's key under the ring: You · {today} today · {notYet} not yet ·
/// {cities} cities, each of the first three with its dot. Read out whole.
/// Without you on the globe (no profile, GG3) the "You" entry is left out.
class GroupGlobeKey extends StatelessWidget {
  const GroupGlobeKey({super.key, required this.counts, required this.withYou});

  final ({int today, int notYet, int cities}) counts;
  final bool withYou;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final lang = l.localeName;
    final text = l.sangatGlobeKey(
      formatCount(lang, counts.today),
      formatCount(lang, counts.notYet),
      formatCount(lang, counts.cities),
    );
    final parts = text.split(' · ');
    final style = HazriText.captionStrong.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5);
    final entries = <Widget>[];
    final shown = <String>[];
    if (parts.length == 4) {
      const colours = [GlobePainter.you, GlobePainter.live, GlobePainter.here];
      for (var i = withYou ? 0 : 1; i < 3; i++) {
        shown.add(parts[i]);
        entries.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: colours[i], shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(parts[i], style: style),
            ],
          ),
        );
      }
      shown.add(parts[3]);
      entries.add(Text('· ${parts[3]}', style: style));
    } else {
      // A translation that does not split into four: the line as written.
      shown.add(text);
      entries.add(Text(text, style: style, textAlign: TextAlign.center));
    }
    return Semantics(
      label: shown.join(' · '),
      container: true,
      child: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 2,
          children: entries,
        ),
      ),
    );
  }
}

/// GG5: the line just below the band, over its edge as in design C. Hidden
/// at 0 and for an ended goal, which has no arrivals (GG9).
class GroupArrivalsLine extends ConsumerWidget {
  const GroupArrivalsLine({super.key, required this.groupId, required this.simran});

  final String groupId;
  final bool simran;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final c = context.colors;
    final amount = arrivalsAmount(ref.watch(groupGlobeDrawingProvider(groupId)).arrivals);
    if (amount <= 0) return const SizedBox.shrink();
    final n = formatCount(l.localeName, amount);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(color: Color(0x0F1B1D3A), blurRadius: 2, offset: Offset(0, 1)),
              BoxShadow(color: Color(0x1F1B1D3A), blurRadius: 28, offset: Offset(0, 10)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: GlobePainter.you,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: c.kesriSoft, spreadRadius: 4)],
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  simran ? l.sangatArrivalsMinutes(n) : l.sangatArrivals(n),
                  style: HazriText.captionStrong.copyWith(color: c.ink, fontSize: 13.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// GG4: paath arriving as light, from the member's city (or the globe's rim,
/// without one) into the ring's leading edge, which glows as it lands. On
/// opening, the last hour's, oldest first, one every 0.8 s; then only the new
/// ones, by when they arrived. None with reduced motion.
class GroupArrivals extends StatefulWidget {
  const GroupArrivals({
    super.key,
    required this.arrivals,
    required this.positions,
    required this.project,
    required this.progress,
    this.enabled = true,
  });

  /// Oldest first.
  final List<GroupArrival> arrivals;
  final Map<String, ({double lat, double lon})> positions;

  /// The globe's projector, in the globe's square, which sits centred in
  /// this one ([GroupGlobeRing.ringSize] across).
  final GlobeProjector project;
  final double progress;
  final bool enabled;

  /// From the city to the ring, and the glow after it lands.
  static const flight = Duration(milliseconds: 1200);
  static const glow = Duration(milliseconds: 600);

  @override
  State<GroupArrivals> createState() => GroupArrivalsState();
}

class GroupArrivalsState extends State<GroupArrivals> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_tick);
  Duration _now = Duration.zero;
  final _flights = <({GroupArrival arrival, Duration start})>[];

  /// The newest arrival already played or passed over.
  DateTime? _playedUpTo;

  /// Every arrival queued since the screen opened, for a test to read.
  @visibleForTesting
  final List<GroupArrival> queued = [];

  /// When each queued flight starts, relative to the first.
  @visibleForTesting
  List<Duration> get starts => [for (final f in _flights) f.start];

  @override
  void initState() {
    super.initState();
    _take(widget.arrivals);
  }

  @override
  void didUpdateWidget(GroupArrivals oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuilt with every turn of the globe; only a new list is news.
    if (!identical(oldWidget.arrivals, widget.arrivals)) _take(widget.arrivals);
  }

  void _take(List<GroupArrival> arrivals) {
    final fresh = arrivalsToPlay(arrivals, _playedUpTo);
    if (fresh.isEmpty) return;
    _playedUpTo = fresh.last.at;
    if (!widget.enabled) return;
    var next = _flights.isEmpty ? _now : _flights.last.start + groupArrivalSpacing;
    if (next < _now) next = _now;
    for (final a in fresh) {
      _flights.add((arrival: a, start: next));
      queued.add(a);
      next += groupArrivalSpacing;
    }
    if (!_ticker.isActive) _ticker.start();
  }

  void _tick(Duration elapsed) {
    // The ticker counts from its own start; keep one clock across restarts.
    setState(() => _now = _base + elapsed);
    final end = _flights.isEmpty ? Duration.zero : _flights.last.start + GroupArrivals.flight + GroupArrivals.glow;
    if (_now >= end) {
      _ticker.stop();
      _base = _now;
      _flights.clear();
    }
  }

  Duration _base = Duration.zero;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_flights.isEmpty || !widget.enabled) return const SizedBox.expand();
    return CustomPaint(
      size: Size.infinite,
      painter: _ArrivalsPainter(
        lights: [
          for (final f in _flights)
            if (_now >= f.start)
              (start: _from(f.arrival), t: (_now - f.start).inMicroseconds / GroupArrivals.flight.inMicroseconds),
        ],
        progress: widget.progress,
      ),
    );
  }

  /// Where a light sets off, in this square: the city's point, the rim
  /// nearest it when it is round the back, or a point of the rim across from
  /// the leading edge for a paath with no city.
  Offset _from(GroupArrival a) {
    const inset = (GroupGlobeRing.ringSize - GroupGlobeRing.globeSize) / 2;
    final at = a.cityId == null ? null : widget.positions[a.cityId];
    if (at != null) return widget.project(at.lat, at.lon).at + const Offset(inset, inset);
    const centre = Offset(GroupGlobeRing.ringSize / 2, GroupGlobeRing.ringSize / 2);
    final jitter = ((a.at.millisecondsSinceEpoch ~/ 1000) % 61 - 30) * math.pi / 180;
    final angle = _leadingAngle(widget.progress) + math.pi + jitter;
    return centre + Offset(math.cos(angle), math.sin(angle)) * (GroupGlobeRing.globeSize / 2);
  }
}

/// GG4a: every dot on the near side of the globe is tied to the ring's
/// leading edge by a dashed line in its own colour, the path its paath
/// travels when it arrives (design 104). Drawn with the globe as it turns.
class GroupTethers extends StatelessWidget {
  const GroupTethers({super.key, required this.dots, required this.project, required this.progress});

  final List<GlobeDot> dots;

  /// As [GroupArrivals.project]: in the globe's square, centred in this one.
  final GlobeProjector project;
  final double progress;

  /// Where each line starts, in this square: the dot's own centre, after
  /// the side-by-side shift of DR3. Dots round the back have no line.
  @visibleForTesting
  List<({Offset start, DotKind kind})> starts() {
    const inset = Offset(
      (GroupGlobeRing.ringSize - GroupGlobeRing.globeSize) / 2,
      (GroupGlobeRing.ringSize - GroupGlobeRing.globeSize) / 2,
    );
    return [
      for (final d in dots)
        if (project(d.lat, d.lon) case (at: final at, front: true))
          (start: at + Offset(GlobePainter.shiftOf(d), 0) + inset, kind: d.kind),
    ];
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.infinite,
    painter: _TethersPainter(lines: starts(), progress: progress),
  );
}

class _TethersPainter extends CustomPainter {
  _TethersPainter({required this.lines, required this.progress});

  final List<({Offset start, DotKind kind})> lines;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final end = _leadingEdge(size, progress);
    for (final l in lines) {
      final colour = switch (l.kind) {
        DotKind.you => GlobePainter.you,
        DotKind.live => GlobePainter.live,
        DotKind.here => GlobePainter.here,
      };
      final paint = Paint()
        ..color = colour.withValues(alpha: 0.6)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final control = _bow(l.start, end, centre);
      // Dashes of 4 dp with gaps of 5, measured along the curve.
      const steps = 48;
      var prev = l.start;
      var run = 0.0;
      for (var i = 1; i <= steps; i++) {
        final t = i / steps;
        final u = 1 - t;
        final p = l.start * (u * u) + control * (2 * u * t) + end * (t * t);
        if (run % 9 < 4) canvas.drawLine(prev, p, paint);
        run += (p - prev).distance;
        prev = p;
      }
    }
  }

  @override
  bool shouldRepaint(_TethersPainter old) => true; // rebuilt with every turn of the globe
}

/// The ring's leading edge, in a square of [size], on the ring's centre line.
Offset _leadingEdge(Size size, double progress) {
  final centre = size.center(Offset.zero);
  final radius = (size.width - GroupGlobeRing.ringStroke) / 2;
  final angle = _leadingAngle(progress);
  return centre + Offset(math.cos(angle), math.sin(angle)) * radius;
}

/// The control point of a gentle arc from [start] to [end], bowed away from
/// the centre so it reads as travelling. Arrivals fly along the same curve
/// as the dashed lines.
Offset _bow(Offset start, Offset end, Offset centre) {
  final mid = (start + end) / 2;
  final away = mid - centre;
  final bow = away.distance < 1 ? Offset(-(end - start).dy, (end - start).dx) : away;
  return mid + bow / (bow.distance == 0 ? 1 : bow.distance) * ((end - start).distance * 0.25);
}

/// The ring's leading edge, as an angle on screen: the ring starts at the
/// top and runs clockwise.
double _leadingAngle(double progress) => -math.pi / 2 + 2 * math.pi * progress.clamp(0.0, 1.0);

class _ArrivalsPainter extends CustomPainter {
  _ArrivalsPainter({required this.lights, required this.progress});

  /// Each light's start and how far along it is: 0 to 1 in flight, past 1
  /// landed and glowing.
  final List<({Offset start, double t})> lights;
  final double progress;

  static const _light = Color(0xFFFFD7A3);

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final end = _leadingEdge(size, progress);
    final glowFor = GroupArrivals.glow.inMicroseconds / GroupArrivals.flight.inMicroseconds;
    for (final l in lights) {
      if (l.t >= 1) {
        // Landed: the leading edge glows, and fades.
        final f = ((l.t - 1) / glowFor).clamp(0.0, 1.0);
        final a = math.sin(math.pi * (0.5 + 0.5 * f));
        canvas.drawCircle(
          end,
          9 + 5 * f,
          Paint()
            ..color = _light.withValues(alpha: 0.9 * a)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        continue;
      }
      final control = _bow(l.start, end, centre);
      Offset at(double t) {
        final u = 1 - t;
        return l.start * (u * u) + control * (2 * u * t) + end * (t * t);
      }

      final t = Curves.easeIn.transform(l.t.clamp(0.0, 1.0));
      for (var k = 4; k >= 0; k--) {
        final tk = (t - k * 0.035).clamp(0.0, 1.0);
        canvas.drawCircle(at(tk), 3.2 - k * 0.45, Paint()..color = _light.withValues(alpha: 0.95 * (1 - k / 5)));
      }
      canvas.drawCircle(
        at(t),
        7,
        Paint()
          ..color = _light.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_ArrivalsPainter old) => true;
}
