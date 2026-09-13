import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
import '../../audio/data/audio_controller.dart';
import '../../today/data/today_controller.dart';
import 'anhad_ring.dart';

/// Daily Simran — five quiet minutes (Design 21).
///
/// The timer is anchored to a start instant rather than a tick count, so
/// locking the phone or leaving the app does not lose time (PRD 1.13).
class SimranScreen extends ConsumerStatefulWidget {
  const SimranScreen({super.key});

  @override
  ConsumerState<SimranScreen> createState() => _SimranScreenState();
}

class _SimranScreenState extends ConsumerState<SimranScreen> with WidgetsBindingObserver {
  DateTime? _startedAt;
  Timer? _ticker;
  int _count = 0;
  Duration _elapsed = Duration.zero;
  bool _logged = false;

  Duration get _total => Duration(minutes: ref.read(settingsProvider).simranMinutes);

  bool get _running => _startedAt != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    if (_running && !_logged) unawaited(_finish(completed: false));
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recompute from the start instant rather than trusting the ticker.
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _start() {
    final track = ref.read(simranTrackProvider).value;
    if (track != null) {
      unawaited(ref.read(playbackControllerProvider)
          .playSimran(track, title: L.of(context).simranTitle));
    }
    setState(() {
      _startedAt = DateTime.now();
      _count = 0;
      _elapsed = Duration.zero;
      _logged = false;
    });
    WakelockPlus.enable();
    _ticker = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    final started = _startedAt;
    if (started == null) return;
    final elapsed = DateTime.now().difference(started);
    if (elapsed >= _total) {
      unawaited(_finish(completed: true));
      return;
    }
    if (mounted) setState(() => _elapsed = elapsed);
  }

  Future<void> _finish({required bool completed}) async {
    if (_logged) return;
    _logged = true;
    _ticker?.cancel();
    final started = _startedAt;
    final elapsed = started == null ? Duration.zero : DateTime.now().difference(started);
    final capped = elapsed > _total ? _total : elapsed;

    await ref.read(userRepositoryProvider).logSimran(
          duration: capped,
          count: _count,
          completed: completed,
        );

    await ref.read(paathPlayerProvider)?.stop();
    if (completed) {
      await HapticFeedback.mediumImpact();
    }
    await WakelockPlus.disable();
    if (!mounted) return;
    setState(() {
      _startedAt = null;
      _elapsed = Duration.zero;
    });
    if (completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.of(context).simranCompleteToast)),
      );
    }
  }

  void _countTap() {
    if (!_running) return;
    HapticFeedback.selectionClick();
    setState(() => _count++);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final settings = ref.watch(settingsProvider);
    final remaining = _total - _elapsed;
    final doneToday = ref.watch(simranDoneTodayProvider).value ?? false;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: _countTap,
          behavior: HitTestBehavior.opaque,
          child: PhoneWidth(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 20, HazriSize.gutter, 20),
              children: [
                Text(l.simranTitle, style: HazriText.display26.copyWith(color: c.ink)),
                Text(l.simranSubtitle, style: HazriText.body.copyWith(color: c.ink2)),
                const SizedBox(height: 24),
                Center(
                  child: ProgressRing(
                    size: 240,
                    strokeWidth: 10,
                    progress: _total.inSeconds == 0
                        ? 0
                        : _elapsed.inMilliseconds / _total.inMilliseconds,
                    child: AnhadRing(
                      elapsed: _elapsed,
                      total: _total,
                      running: _running,
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
                    HazriDates.duration(_running ? remaining : _total),
                    style: HazriText.display34.copyWith(color: c.kesriInk),
                  ),
                ),
                Center(
                  child: Text(
                    l.simranLeftOf(HazriDates.duration(_total)),
                    style: HazriText.caption.copyWith(color: c.muted),
                  ),
                ),
                const SizedBox(height: 20),
                if (_running) ...[
                  Center(
                    child: Column(
                      children: [
                        Text('$_count', style: HazriText.display22.copyWith(color: c.ink)),
                        Text(l.simranCount, style: HazriText.caption.copyWith(color: c.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.simranCountHint,
                    textAlign: TextAlign.center,
                    style: HazriText.caption.copyWith(color: c.muted),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: l.simranEnd,
                    secondary: true,
                    onPressed: () => _finish(completed: false),
                  ),
                ] else
                  PrimaryButton(
                    label: doneToday ? l.simranTileDone : l.simranBegin,
                    onPressed: _start,
                  ),
                const SizedBox(height: 20),
                const SizedBox(height: 16),
                const _RecentCard(),
                const SizedBox(height: 16),
                const _QuoteCard(),
              ],
            ),
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
