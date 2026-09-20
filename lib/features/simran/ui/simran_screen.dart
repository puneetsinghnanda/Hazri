import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/surfaces.dart';
import '../../goals/data/goals_controller.dart';
import '../data/simran_controller.dart';
import '../../sangat/data/presence_repository.dart';
import '../../sangat/domain/simran_presence.dart';
import 'simran_globe.dart';
import '../../today/data/today_controller.dart';
import 'package:go_router/go_router.dart';
import '../../../app/menu_sheet.dart';
import '../../../app/router.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';

/// Daily Simran — five quiet minutes (Design 21).
///
/// The session itself lives in [simranSessionProvider], not here: the screen
/// can be built more than once over one sitting (the mini player opens it, a
/// tab switch rebuilds it) and the timer has to be the same timer each time.
class SimranScreen extends ConsumerStatefulWidget {
  const SimranScreen({super.key});

  @override
  ConsumerState<SimranScreen> createState() => _SimranScreenState();
}

class _SimranScreenState extends ConsumerState<SimranScreen> with WidgetsBindingObserver {
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

    // Design 29 is the Simran tab, running or not, joined or not.
    //
    // It has been wrong twice. First it was behind an account, so everybody
    // who had not joined got the Phase 1 screen. Then it was the resting
    // state only, so the redesign vanished at the exact moment somebody
    // began -- which is the moment they are looking at it. One screen, whether
    // or not a sitting is running. The globe was the
    // resting state and the Phase 1 ring took over the moment somebody
    // began, which meant the redesign vanished at exactly the moment the
    // recitation started. The globe stays; what changes under it is the
    // countdown and the button.
    return _Globe(
      presence: presence,
      minutes: minutes,
      doneToday: doneToday,
      session: session,
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

/// Design 29 — the Simran tab.
///
/// A night sky edge to edge with the earth turning in it, who is sitting, and
/// the one control the moment needs. While a sitting runs the globe stays
/// exactly where it is and the headline becomes a countdown, because the
/// recitation playing is the reason somebody is looking at this screen.
class _Globe extends ConsumerWidget {
  const _Globe({
    required this.presence,
    required this.minutes,
    required this.doneToday,
    required this.session,
    required this.onBegin,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
  });

  final SangatPresence presence;
  final int minutes;
  final bool doneToday;
  final SimranSession session;
  final VoidCallback onBegin;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;

  /// The globe's own palette, which is a night sky on both themes.
  static const _sky = Color(0xFF070A1A);
  static const _others = Color(0xFF6FE3A6);
  static const _you = Color(0xFFF2A24E);
  static const _here = Color(0xFF3DBE7B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final white70 = Colors.white.withValues(alpha: 0.66);
    final active = session.active;

    return Scaffold(
      backgroundColor: _sky,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _DarkButton(
                      icon: HazriIconData.menu,
                      tooltip: l.menuTooltip,
                      onTap: () => showMenuSheet(context),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(l.simranTitle,
                              style: HazriText.display22
                                  .copyWith(color: Colors.white, fontSize: 22)),
                          Text(
                            l.simranTurnGlobeShort,
                            textAlign: TextAlign.center,
                            style: HazriText.caption.copyWith(color: white70),
                          ),
                        ],
                      ),
                    ),
                    _DarkButton(
                      icon: HazriIconData.bell,
                      tooltip: l.notifTitle,
                      onTap: () => context.push(Routes.notifications),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, box) => SimranGlobe(
                        presence: presence,
                        // As wide as the screen allows, which is what makes
                        // it a horizon rather than an illustration.
                        size: box.maxWidth.clamp(0.0, box.maxHeight),
                      ),
                    ),
                  ),
                ),
                if (active) ...[
                  // The countdown takes the place of the headline while a
                  // sitting is open: it is the one number that matters then,
                  // and it stays on screen while paused so the time already
                  // sat is never in doubt.
                  Text(
                    HazriDates.duration(session.remaining),
                    style: HazriText.display34.copyWith(
                      color: session.paused ? white70 : _you,
                    ),
                  ),
                  Text(
                    session.paused
                        ? l.simranPaused
                        : l.simranLeftOf(HazriDates.duration(session.total)),
                    style: HazriText.caption.copyWith(color: white70),
                  ),
                ] else if (presence.isQuiet)
                  Text(
                    l.simranGlobeFirst,
                    textAlign: TextAlign.center,
                    style: HazriText.display22
                        .copyWith(color: Colors.white, fontSize: 25, height: 1.3),
                  )
                else
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l.simranYouAndOthers(presence.others),
                          style: HazriText.display22.copyWith(
                              color: _others, fontSize: 25, height: 1.3),
                        ),
                        const TextSpan(text: '\n'),
                        TextSpan(
                          text: l.simranAreHereToday,
                          style: HazriText.display22.copyWith(
                              color: Colors.white, fontSize: 25, height: 1.3),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                if (!active) ...[
                  const SizedBox(height: 7),
                  Text(
                    // Only what is actually known. The design also carries a
                    // month total and a country count; neither is stored, and
                    // a number nobody counted is worse than no number.
                    l.simranCitiesToday(presence.activeCities.length),
                    style: HazriText.caption.copyWith(color: white70),
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 13,
                  runSpacing: 6,
                  children: [
                    _LegendDot(colour: _you, label: l.simranLegendYou),
                    _LegendDot(colour: _here, label: l.simranLegendHere),
                  ],
                ),
                const SizedBox(height: 16),
                // Two controls while a sitting is open, not one. Ending was
                // the only way out, so a knock at the door cost somebody the
                // whole sitting; pausing holds the clock and the recitation
                // together and what was already sat is still logged if they
                // end from there.
                if (active)
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: session.paused ? l.actionResume : l.actionPause,
                          icon: session.paused
                              ? HazriIconData.play
                              : HazriIconData.pause,
                          onPressed: session.paused ? onResume : onPause,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PrimaryButton(
                          label: l.simranEnd,
                          secondary: true,
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
                    onPressed: onBegin,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DarkButton extends StatelessWidget {
  const _DarkButton({required this.icon, required this.tooltip, required this.onTap});

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
