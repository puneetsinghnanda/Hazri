import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/menu_sheet.dart';
import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../goals/data/goals_controller.dart';
import '../../sangat/data/presence_repository.dart';
import '../../sangat/domain/simran_presence.dart';
import '../../today/data/today_controller.dart';
import '../data/simran_controller.dart';
import '../domain/simran_track.dart';
import 'simran_globe.dart';
import 'simran_naam.dart';

/// Daily Simran.
///
/// The session itself lives in [simranSessionProvider], not here: the screen
/// can be built more than once over one sitting (the mini player opens it, a
/// tab switch rebuilds it) and the timer has to be the same timer each time.
class SimranScreen extends ConsumerStatefulWidget {
  const SimranScreen({super.key});

  @override
  ConsumerState<SimranScreen> createState() => _SimranScreenState();
}

class _SimranScreenState extends ConsumerState<SimranScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recompute from the start instant rather than trusting the ticker.
    if (state == AppLifecycleState.resumed) {
      ref.read(simranSessionProvider.notifier).tick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final settings = ref.watch(settingsProvider);
    final session = ref.watch(simranSessionProvider);
    final controller = ref.read(simranSessionProvider.notifier);
    final doneToday = ref.watch(simranDoneTodayProvider).value ?? false;
    final presence = ref.watch(globePresenceProvider);
    // The recitation's own onsets, so ਵਾਹਿਗੁਰੂ appears when it is said.
    final track = ref.watch(simranTrackProvider).value;

    // A simran goal's length wins over the Settings default, so "11 min" on
    // the goal is what the button offers and what the timer counts.
    final minutes =
        ref.watch(simranGoalMinutesProvider) ?? settings.simranMinutes;

    // A session that ran its full length may well have finished while this
    // screen was not on top, so the toast follows the state, not the tap.
    ref.listen(simranSessionProvider, (prev, next) {
      if (next.justCompleted && !(prev?.justCompleted ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.simranCompleteToast)),
        );
      }
    });

    return _SimranSky(
      presence: presence,
      minutes: minutes,
      doneToday: doneToday,
      session: session,
      track: track,
      onBegin: () => controller.start(
        title: l.simranTitle,
        length: Duration(minutes: minutes),
      ),
      onPause: controller.pause,
      onResume: controller.resume,
      onEnd: () => controller.finish(completed: false),
    );
  }
}

/// The Simran tab, to the reader's mock-up of 2026-09-20.
///
/// It supersedes design 29 for this screen: the globe and the legend are
/// design 29's, the serif headline, the ੴ rule and the verse are the
/// mock-up's, and the presence line moved under the globe so that the
/// countdown and "who is here" can share one place without the screen having
/// two headlines.
///
/// One screen whether or not a sitting is running. It has been wrong twice
/// the other way: first behind an account, so everybody who had not joined
/// got a different screen, then as a resting state only, so the design
/// vanished at the exact moment somebody began.
class _SimranSky extends ConsumerWidget {
  const _SimranSky({
    required this.presence,
    required this.minutes,
    required this.doneToday,
    required this.session,
    required this.track,
    required this.onBegin,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
  });

  final SangatPresence presence;
  final int minutes;
  final bool doneToday;
  final SimranSession session;
  final SimranTrack? track;
  final VoidCallback onBegin;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;

  /// The screen's own palette, which is a night sky on both themes.
  static const _sky = Color(0xFF040819);
  static const _skyLow = Color(0xFF071130);
  static const _you = Color(0xFFF2A24E);
  static const _here = Color(0xFF3DBE7B);
  static const _others = Color(0xFF6FE3A6);

  /// The side margin every block but the globe keeps.
  static Widget _gutter(Widget child) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: child);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final white = Colors.white;
    final white70 = white.withValues(alpha: 0.70);
    final white55 = white.withValues(alpha: 0.55);
    final active = session.active;
    // ੴ comes from content.db, never typed into Dart (CLAUDE.md rule 3).
    final ikOnkar = ref.watch(ikOnkarProvider).value ?? '';

    return Scaffold(
      backgroundColor: _sky,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, 0.15),
            radius: 1.1,
            colors: [_skyLow, _sky],
          ),
        ),
        child: CustomPaint(
          painter: _Starfield(),
          child: SafeArea(
            bottom: false,
            child: PhoneWidth(
              child: Padding(
                // No side padding on the column: the globe takes the whole
                // width and each text block gutters itself, so the earth is
                // as wide as the phone rather than as wide as a paragraph.
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
                child: Column(
                  children: [
                    _gutter(_Header(
                      onMenu: () => showMenuSheet(context),
                      onBell: () => context.push(Routes.notifications),
                    )),
                    const SizedBox(height: 10),
                    _gutter(_Headline(kesri: _you)),
                    const SizedBox(height: 4),
                    _gutter(_OnkarRule(glyph: ikOnkar, colour: _you)),
                    // Tight to the rule above it: ੴ and the verse are one
                    // thought, and the gap read as a break between two. The
                    // remaining space is the leading inside the two line
                    // boxes, so it stays a little closer below than above.
                    const SizedBox(height: 0),
                    _gutter(Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '${l.simranVerseOne}\n${l.simranVerseTwoLead}',
                            style: SimranText.verse.copyWith(color: white70),
                          ),
                          TextSpan(
                            text: l.simranVerseTwoWord,
                            style: SimranText.verse.copyWith(
                              color: _you,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    )),
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, box) {
                            // A little taller than the space it is given, so
                            // the width is what decides the size on a phone
                            // and the glow bleeds into the gaps above and
                            // below rather than the earth being shrunk to
                            // clear them.
                            final size = math.min(
                              box.maxWidth,
                              box.maxHeight * 1.14,
                            );
                            return OverflowBox(
                              maxWidth: size,
                              maxHeight: size,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  SimranGlobe(presence: presence, size: size),
                                  if (session.active)
                                    SimranNaam(
                                      size: size,
                                      word: l.simranWaheguru,
                                      track: track,
                                      elapsed: session.elapsed,
                                      running: session.running,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _gutter(Column(
                      children: [
                    if (active) ...[
                      // The countdown takes the place of the presence line
                      // while a sitting is open: it is the one number that
                      // matters then, and it stays on screen while paused so
                      // the time already sat is never in doubt.
                      Text(
                        HazriDates.duration(session.remaining),
                        style: SimranText.countdown
                            .copyWith(color: session.paused ? white70 : white),
                      ),
                      Text(
                        session.paused
                            ? l.simranPaused
                            : l.simranLeftOf(HazriDates.duration(session.total)),
                        style: HazriText.caption.copyWith(color: white55),
                      ),
                    ] else ...[
                      _Presence(presence: presence, others: _others),
                      // Only what is actually known, and only when there is
                      // something to say: "You are the first here today"
                      // followed by "0 cities today" is the hopeful zero the
                      // line above it exists to avoid. A month total and a
                      // country count are not stored anywhere either.
                      if (presence.activeCities.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          l.simranCitiesToday(presence.activeCities.length),
                          style: HazriText.caption.copyWith(color: white55),
                        ),
                      ],
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 13,
                      runSpacing: 6,
                      children: [
                        _LegendDot(colour: _you, label: l.simranLegendYou),
                        _LegendDot(colour: _here, label: l.simranLegendHere),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Two controls while a sitting is open, not one. Ending
                    // was the only way out, so a knock at the door cost
                    // somebody the whole sitting; pausing holds the clock and
                    // the recitation together and what was already sat is
                    // still logged if they end from there.
                    if (active)
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: session.paused
                                  ? l.actionResume
                                  : l.actionPause,
                              icon: session.paused
                                  ? HazriIconData.play
                                  : HazriIconData.pause,
                              background: _you,
                              foreground: const Color(0xFF1C1206),
                              onPressed: session.paused ? onResume : onPause,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryButton(
                              label: l.simranEnd,
                              background: Colors.white.withValues(alpha: 0.10),
                              foreground: Colors.white,
                              onPressed: onEnd,
                            ),
                          ),
                        ],
                      )
                    else
                      PrimaryButton(
                        label: doneToday
                            ? l.simranTileDone
                            : l.simranBeginMinutes(minutes),
                        // Kesri, not the theme's primary. On a night sky the
                        // light theme's indigo read as a different app.
                        background: _you,
                        foreground: const Color(0xFF1C1206),
                        onPressed: onBegin,
                      ),
                      ],
                    )),
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

class _Header extends StatelessWidget {
  const _Header({required this.onMenu, required this.onBell});

  final VoidCallback onMenu;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Row(
      children: [
        _DarkButton(
          icon: HazriIconData.menu,
          tooltip: l.menuTooltip,
          onTap: onMenu,
        ),
        Expanded(
          child: Column(
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: l.simranBrandDaily,
                      style: SimranText.brand.copyWith(color: Colors.white),
                    ),
                    TextSpan(
                      text: l.simranBrandName,
                      style: SimranText.brand
                          .copyWith(color: const Color(0xFFF2A24E)),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                l.simranKicker,
                textAlign: TextAlign.center,
                style: SimranText.kicker
                    .copyWith(color: Colors.white.withValues(alpha: 0.62)),
              ),
            ],
          ),
        ),
        _DarkButton(
          icon: HazriIconData.bell,
          tooltip: l.notifTitle,
          onTap: onBell,
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.kesri});

  final Color kesri;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${l.simranHeadlineOne}\n${l.simranHeadlineTwoLead}',
            style: SimranText.headline.copyWith(color: Colors.white),
          ),
          TextSpan(
            text: l.simranHeadlineTwoWord,
            style: SimranText.headline.copyWith(
              color: kesri,
              // The word glows rather than sitting flat, which is what makes
              // it read as lit by the earth below it.
              shadows: [
                Shadow(color: kesri.withValues(alpha: 0.55), blurRadius: 22),
              ],
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// A hairline either side of ੴ.
class _OnkarRule extends StatelessWidget {
  const _OnkarRule({required this.glyph, required this.colour});

  final String glyph;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    final rule = Expanded(
      child: Container(
        height: 1,
        constraints: const BoxConstraints(maxWidth: 110),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [colour.withValues(alpha: 0), colour.withValues(alpha: 0.45)],
          ),
        ),
      ),
    );
    return Row(
      children: [
        rule,
        if (glyph.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(glyph, style: SimranText.onkar.copyWith(color: colour)),
          )
        else
          const SizedBox(width: 14),
        // Mirrored, so the fade runs outward from the middle on both sides.
        Expanded(
          child: Transform.flip(
            flipX: true,
            child: Container(
              height: 1,
              constraints: const BoxConstraints(maxWidth: 110),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colour.withValues(alpha: 0),
                    colour.withValues(alpha: 0.45),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Who is sitting, where the countdown goes when nothing is running.
class _Presence extends StatelessWidget {
  const _Presence({required this.presence, required this.others});

  final SangatPresence presence;
  final Color others;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    if (presence.isQuiet) {
      return Text(
        l.simranGlobeFirst,
        textAlign: TextAlign.center,
        style: SimranText.presence.copyWith(color: Colors.white),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${l.simranYouAndOthers(presence.others)} ',
            style: SimranText.presence.copyWith(color: others),
          ),
          TextSpan(
            text: l.simranAreHereToday,
            style: SimranText.presence.copyWith(color: Colors.white),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// A fixed field of stars.
///
/// Seeded, so they are the same stars on every rebuild: a field that
/// re-scattered whenever the countdown ticked would be the opposite of
/// still.
class _Starfield extends CustomPainter {
  static const _count = 90;

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(11);
    final paint = Paint();
    for (var i = 0; i < _count; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = 0.5 + random.nextDouble() * 1.1;
      paint.color =
          Colors.white.withValues(alpha: 0.12 + random.nextDouble() * 0.45);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_Starfield old) => false;
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final String icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Center(child: AppIcon(icon, size: 20, color: Colors.white)),
          ),
        ),
      );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.colour, required this.label});

  final Color colour;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: HazriText.caption
                .copyWith(color: Colors.white.withValues(alpha: 0.72)),
          ),
        ],
      );
}
