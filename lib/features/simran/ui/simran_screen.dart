import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/time/clock.dart';
import '../../../core/time/date_format.dart';
import '../../../core/widgets/progress_ring.dart';
import '../../../core/widgets/surfaces.dart';
import '../data/simran_controller.dart';
import '../../sangat/data/account_repository.dart';
import '../../sangat/data/presence_repository.dart';
import '../../sangat/domain/simran_presence.dart';
import 'simran_globe.dart';
import '../../today/data/today_controller.dart';
import 'anhad_ring.dart';
import 'package:go_router/go_router.dart';
import '../../../app/menu_sheet.dart';
import '../../../app/router.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/tab_header.dart';

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
    final c = context.colors;
    final l = L.of(context);
    final settings = ref.watch(settingsProvider);
    final session = ref.watch(simranSessionProvider);
    final controller = ref.read(simranSessionProvider.notifier);
    final total = controller.total;
    final remaining = total - session.elapsed;
    final doneToday = ref.watch(simranDoneTodayProvider).value ?? false;
    final joined = ref.watch(hasJoinedSangatProvider);
    final presence = ref.watch(simranPresenceProvider).value ?? SangatPresence.empty;

    // A session that ran its full length may well have finished while this
    // screen was not on top, so the toast follows the state, not the tap.
    ref.listen(simranSessionProvider, (prev, next) {
      if (next.justCompleted && !(prev?.justCompleted ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.simranCompleteToast)),
        );
      }
    });

    // Design 29 is the screen at rest: the night sky, the globe, and who is
    // sitting. The moment a session starts it becomes the Phase 1 screen --
    // the ring, the countdown and the anhad wave -- because that is what
    // somebody sitting with their eyes half closed needs, and a spinning
    // globe is the opposite of it.
    if (!session.running && joined) {
      return _GlobeAtRest(
        presence: presence,
        minutes: settings.simranMinutes,
        doneToday: doneToday,
        onBegin: () => controller.start(title: l.simranTitle),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 0, HazriSize.gutter, 20),
            children: [
              TabHeader(
                title: l.simranTitle,
                subtitle: l.simranSubtitle,
                onMenu: () => showMenuSheet(context),
              ),
              const SizedBox(height: 14),
              Center(
                child: ProgressRing(
                  size: 240,
                  strokeWidth: 10,
                  progress: total.inSeconds == 0
                      ? 0
                      : session.elapsed.inMilliseconds / total.inMilliseconds,
                  child: AnhadRing(
                    elapsed: session.elapsed,
                    total: total,
                    running: session.running,
                    track: ref.watch(simranTrackProvider).value,
                    child: Text(
                      _waheguru(settings.script),
                      style: _waheguruStyle(settings.script)
                          .copyWith(color: c.simranThread),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // The countdown sits under the circle so nothing competes with
              // the wave inside it.
              Center(
                child: Text(
                  HazriDates.duration(session.running ? remaining : total),
                  style: HazriText.display34.copyWith(color: c.kesriInk),
                ),
              ),
              Center(
                child: Text(
                  l.simranLeftOf(HazriDates.duration(total)),
                  style: HazriText.caption.copyWith(color: c.muted),
                ),
              ),
              const SizedBox(height: 20),
              if (session.running)
                PrimaryButton(
                  label: l.simranEnd,
                  secondary: true,
                  onPressed: () => controller.finish(completed: false),
                )
              else
                PrimaryButton(
                  label: doneToday ? l.simranTileDone : l.simranBegin,
                  onPressed: () => controller.start(title: l.simranTitle),
                ),
              const SizedBox(height: 20),
              const _RecentCard(),
              const SizedBox(height: 16),
              const _QuoteCard(),
            ],
          ),
        ),
      ),
    );
  }

  static String _waheguru(GurbaniScript script) => switch (script) {
    GurbaniScript.gurmukhi => 'ਵਾਹਿਗੁਰੂ',
    GurbaniScript.devanagari => 'वाहिगुरू',
    GurbaniScript.roman => 'Waheguru',
  };

  static TextStyle _waheguruStyle(GurbaniScript script) => switch (script) {
    GurbaniScript.gurmukhi => HazriText.gurmukhi(26, weight: FontWeight.w600),
    GurbaniScript.devanagari => HazriText.devanagari(24, weight: FontWeight.w600),
    GurbaniScript.roman => HazriText.roman(22, weight: FontWeight.w600),
  };
}

class _RecentCard extends ConsumerWidget {
  const _RecentCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final clock = ref.watch(clockProvider);
    final sessions = ref.watch(userRepositoryProvider).watchSimranSessions();

    return StreamBuilder(
      stream: sessions,
      builder: (context, snapshot) {
        final rows = snapshot.data ?? const [];
        final today = clock.today();
        final recent = {
          for (var i = 0; i < 10; i++) localDateKey(today.subtract(Duration(days: i))),
        };
        final done = rows
            .where((s) => s.completed && recent.contains(s.localDate))
            .map((s) => s.localDate)
            .toSet()
            .length;

        return HazriCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.simranRecent(done, 10),
                style: HazriText.bodyStrong.copyWith(color: c.ink),
              ),
              Text(
                l.simranLoggedInDiary,
                style: HazriText.caption.copyWith(color: c.muted),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A line of Gurbani for the Simran screen, read from content.db rather than
/// written into app code.
class _QuoteCard extends ConsumerWidget {
  const _QuoteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final lang = Localizations.localeOf(context).languageCode;
    final script = ref.watch(settingsProvider.select((s) => s.script));

    return FutureBuilder<QuoteRow?>(
      future: ref.watch(contentRepositoryProvider).quote('simran_1'),
      builder: (context, snapshot) {
        final quote = snapshot.data;
        if (quote == null) return const SizedBox.shrink();
        final (text, style) = switch (script) {
          GurbaniScript.gurmukhi => (quote.gurmukhi, HazriText.gurmukhi(19)),
          GurbaniScript.devanagari => (quote.devanagari, HazriText.devanagari(18)),
          GurbaniScript.roman => (quote.roman, HazriText.roman(17)),
        };
        final attribution = switch (lang) {
          'pa' => quote.attributionPa,
          'hi' => quote.attributionHi,
          _ => quote.attributionEn,
        };

        return HazriCard(
          colour: c.card2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text, style: style.copyWith(color: c.ink)),
              if (attribution != null) ...[
                const SizedBox(height: 6),
                Text('— $attribution', style: HazriText.caption.copyWith(color: c.muted)),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Design 29 — the Simran tab before anybody starts.
///
/// A night sky edge to edge, the earth turning in it, and the plain fact of
/// how many are sitting. It replaces the card-on-a-light-page version, which
/// put the globe in a box on a screen about something else.
class _GlobeAtRest extends ConsumerWidget {
  const _GlobeAtRest({
    required this.presence,
    required this.minutes,
    required this.doneToday,
    required this.onBegin,
  });

  final SangatPresence presence;
  final int minutes;
  final bool doneToday;
  final VoidCallback onBegin;

  /// The globe's own palette, which is a night sky on both themes.
  static const _sky = Color(0xFF070A1A);
  static const _others = Color(0xFF6FE3A6);
  static const _you = Color(0xFFF2A24E);
  static const _here = Color(0xFF3DBE7B);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final white70 = Colors.white.withValues(alpha: 0.66);

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
                if (presence.isQuiet)
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
                const SizedBox(height: 7),
                Text(
                  // Only what is actually known. The design also carries a
                  // month total and a country count; neither is stored, and
                  // a number nobody counted is worse than no number.
                  l.simranCitiesToday(presence.cities.length),
                  style: HazriText.caption.copyWith(color: white70),
                ),
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
