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

    // A session that ran its full length may well have finished while this
    // screen was not on top, so the toast follows the state, not the tap.
    ref.listen(simranSessionProvider, (prev, next) {
      if (next.justCompleted && !(prev?.justCompleted ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.simranCompleteToast)),
        );
      }
    });

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: PhoneWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 20, HazriSize.gutter, 20),
              children: [
                Text(l.simranTitle, style: HazriText.display26.copyWith(color: c.ink)),
                Text(l.simranSubtitle, style: HazriText.body.copyWith(color: c.ink2)),
                const SizedBox(height: 16),
                // Design 29. Shown only to somebody who joined the sangat: a
                // globe with nobody on it is not a feature, and showing one
                // to a person who never opted in would be asking them to feel
                // the absence of something they did not ask for.
                if (ref.watch(hasJoinedSangatProvider)) ...[
                  const SimranPresenceCard(),
                  const SizedBox(height: 18),
                ],
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

/// Design 29's hero: the globe, and how many are sitting with you.
///
/// The reader asked what these numbers look like on a new app with few
/// people. The answer is that the screen never shows a zero: with nobody else
/// there it says you are the first today, which is true, is the better thing
/// to be, and stops being said the moment somebody else sits down.
class SimranPresenceCard extends ConsumerWidget {
  const SimranPresenceCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final presence = ref.watch(simranPresenceProvider).value ?? SangatPresence.empty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(HazriRadius.card),
      child: Container(
        color: const Color(0xFF070A1A),
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          children: [
            SimranGlobe(presence: presence, size: 220),
            const SizedBox(height: 14),
            if (presence.isQuiet)
              Text(
                l.simranGlobeFirst,
                textAlign: TextAlign.center,
                style: HazriText.bodyStrong.copyWith(color: Colors.white),
              )
            else ...[
              Text(
                l.simranOthersHere(presence.others),
                style: HazriText.display22.copyWith(color: Colors.white),
              ),
              Text(
                l.simranOthersSub,
                style: HazriText.caption.copyWith(color: Colors.white70),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              l.simranGlobeTurn,
              style: HazriText.caption.copyWith(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}
