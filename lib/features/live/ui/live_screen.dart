import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/db/content_db.dart' show CityRow;
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/time/date_format.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../audio/data/audio_controller.dart';
import '../../profile/data/profile_controller.dart';
import '../../profile/ui/messages.dart';
import '../../quiz/ui/quiz_widgets.dart' show cityName;
import '../../simran/data/simran_controller.dart';
import '../data/live_controller.dart';
import '../domain/live_group.dart';
import 'live_cards.dart';
import 'live_scene.dart';

/// A live group's page (15-live-sangat LS5-LS11, designs 127-129): the scene
/// fills the screen, the recording plays at the sangat's second, the people
/// joining show down the left, and the group is a sheet pulled up from the
/// foot. Sit starts a timed sitting with the group's recording (LS10).
class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  late final LiveGroupDef def = liveGroupById(widget.groupId) ?? liveGroups.first;
  late final LiveListener _listener = ref.read(liveListenerProvider.notifier);
  late final SimranController _simran = ref.read(simranSessionProvider.notifier);
  Timer? _refresh;
  bool _sitting = false;

  /// Whether a sitting is open, as last built: read in dispose, where
  /// providers can no longer be read.
  bool _sessionActive = false;
  bool _busy = false;
  int _sleepIndex = 0;
  static const _sleepSteps = [0, 15, 30, 60];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_start());
      unawaited(ref.read(liveStatusProvider.notifier).refresh());
    });
    // The counts are rebuilt by the server at most every two minutes.
    _refresh = Timer.periodic(const Duration(minutes: 2), (_) {
      if (mounted) unawaited(ref.read(liveStatusProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    // LS6: the sound stops when you leave the page, unless a sitting is open.
    if (!_sessionActive) unawaited(_listener.stop());
    super.dispose();
  }

  String get _name => def.nameFor(Localizations.localeOf(context).languageCode);

  Future<void> _start() => _listener.listen(def, title: _name);

  Future<void> _toggleSound() async {
    if (_listener.isPlaying(def.id)) {
      await _listener.pause();
    } else {
      await _start();
    }
    if (mounted) setState(() {});
  }

  void _cycleSleep() {
    final handler = ref.read(audioHandlerProvider);
    setState(() => _sleepIndex = (_sleepIndex + 1) % _sleepSteps.length);
    final m = _sleepSteps[_sleepIndex];
    handler?.setSleepTimer(m == 0 ? null : Duration(minutes: m));
  }

  Future<void> _join(LiveGroupStatus g) async {
    final l = L.of(context);
    if (ref.read(profileControllerProvider) is! ProfileLoaded) {
      _needsProfile();
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(liveStatusProvider.notifier).join(def.id);
    } on Object catch (e) {
      if (mounted) ProfileMessages.snack(context, ProfileMessages.of(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leave() async {
    final l = L.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        content: Text(l.liveLeaveConfirm(_name)),
        actions: [
          TextButton(onPressed: () => Navigator.of(d).pop(false), child: Text(l.actionCancel)),
          TextButton(onPressed: () => Navigator.of(d).pop(true), child: Text(l.sangatLeave)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(liveStatusProvider.notifier).leave(def.id);
    } on Object catch (e) {
      if (mounted) ProfileMessages.snack(context, ProfileMessages.of(l, e));
    }
  }

  void _needsProfile() {
    final l = L.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheet) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.liveJoinNeedsProfile, style: HazriText.body),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l.profileBannerTitle,
              onPressed: () {
                Navigator.of(sheet).pop();
                context.push(Routes.profileSetup);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// LS10: a sitting with the group's recording, counted as Naam Simran.
  Future<void> _sit() async {
    if (_sessionActive) return;
    setState(() => _sitting = true);
    await _simran.start(title: _name, playAudio: _start);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final view = ref.watch(liveStatusProvider);
    final g = view.of(def.id);
    final mine = ref.watch(liveSecondsProvider).value?[def.id];
    final session = ref.watch(simranSessionProvider);
    _sessionActive = session.active;
    ref.watch(playbackStateProvider); // the sound button follows the player
    final playing = _listener.isPlaying(def.id);
    final cities = ref.watch(citiesProvider).value ?? const <CityRow>[];
    final byId = {for (final c in cities) c.id: c};
    final yourCity = byId[ref.watch(profileProvider)?.cityId];
    final ikOnkar = ref.watch(ikOnkarProvider).value ?? '';

    // When the sitting ends, the sangat goes on playing.
    ref.listen(simranSessionProvider, (was, now) {
      if (_sitting && (was?.active ?? false) && !now.active) {
        setState(() => _sitting = false);
        unawaited(_start());
      }
    });
    final sittingNow = _sitting && session.active;
    final waiting = view.offline && view.groups.isEmpty;

    final scene = LiveSceneView(
      scene: def.scene,
      word: switch (def.scene) {
        LiveScene.globe => l.simranWaheguru,
        LiveScene.ikonkar => ikOnkar,
        LiveScene.jot => '',
      },
      dots: [
        for (final id in g.cityIds)
          if (byId[id] != null && id != yourCity?.id) (byId[id]!.lat, byId[id]!.lon),
      ],
      you: yourCity == null ? null : (yourCity.lat, yourCity.lon),
    );

    const white = Colors.white;
    final dim = white.withValues(alpha: 0.72);
    return Scaffold(
      backgroundColor: const Color(0xFF03040F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          scene,
          // A veil at the top and the foot, so the words read over the scene;
          // darker while sitting (design 129).
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.45),
                    Colors.black.withValues(alpha: sittingNow ? 0.35 : 0),
                    Colors.black.withValues(alpha: sittingNow ? 0.55 : 0.6),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                        onPressed: () => context.pop(),
                        icon: const AppIcon(HazriIconData.chevronLeft, size: 24, color: white),
                      ),
                      const LiveTagPill(),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          waiting ? l.liveWaiting : l.liveListening(g.listening),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HazriText.captionStrong.copyWith(color: white),
                        ),
                      ),
                      const Spacer(),
                      if (g.joined)
                        PopupMenuButton<int>(
                          icon: const AppIcon(HazriIconData.dots, size: 22, color: white),
                          onSelected: (_) => _leave(),
                          itemBuilder: (_) => [PopupMenuItem(value: 0, child: Text(l.sangatLeave))],
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (def.kind == LiveKind.jaap ? l.liveKindJaap : l.liveKindMeditation).toUpperCase(),
                          style: HazriText.eyebrow.copyWith(color: const Color(0xFFF2C27A)),
                        ),
                        const SizedBox(height: 2),
                        Text(_name, style: HazriText.display26.copyWith(color: white, fontSize: 30)),
                        const SizedBox(height: 2),
                        Text(
                          waiting ? l.liveWaiting : l.liveCities(g.cities),
                          style: HazriText.bodySmall.copyWith(color: dim),
                        ),
                      ],
                    ),
                  ),
                  if (!sittingNow) ...[
                    const SizedBox(height: 14),
                    for (final j in g.joins.take(3))
                      Padding(
                        padding: const EdgeInsets.only(left: 12, bottom: 6),
                        child: _JoinChip(text: l.liveJoinedFrom(j.name, cityName(ref, j.cityId, lang))),
                      ),
                  ],
                  const Spacer(),
                  if (sittingNow)
                    _Sitting(session: session, listening: g.listening, waiting: waiting)
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: g.joined ? l.liveJoinedListening : l.liveJoin,
                              icon: g.joined ? HazriIconData.check : HazriIconData.plus,
                              background: g.joined ? const Color(0xFF2E7D5B) : const Color(0xFFF2A24E),
                              foreground: g.joined ? white : const Color(0xFF2A1606),
                              onPressed: g.joined ? () {} : (_busy ? null : () => _join(g)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _RoundButton(
                            icon: playing ? HazriIconData.pause : HazriIconData.play,
                            label: playing ? l.liveSound : l.liveSoundOff,
                            onTap: _toggleSound,
                          ),
                          const SizedBox(width: 10),
                          _RoundButton(
                            icon: HazriIconData.moon,
                            label: _sleepSteps[_sleepIndex] == 0
                                ? l.liveSleepOff
                                : l.liveSleepIn(_sleepSteps[_sleepIndex]),
                            badge: _sleepSteps[_sleepIndex] == 0 ? null : '${_sleepSteps[_sleepIndex]}',
                            onTap: _cycleSleep,
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 92),
                ],
              ),
            ),
          ),
          if (!sittingNow)
            _GroupSheet(
              group: g,
              def: def,
              mineToday: (mine?.today ?? 0) ~/ 60,
              mineMonth: (mine?.month ?? 0) ~/ 60,
              sitMinutes: _simran.defaultTotal.inMinutes,
              onSit: _sit,
            ),
        ],
      ),
    );
  }
}

class _JoinChip extends StatelessWidget {
  const _JoinChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HazriText.caption.copyWith(color: Colors.white.withValues(alpha: 0.9)),
        ),
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.label, required this.onTap, this.badge});

  final String icon;
  final String label;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          onTap: onTap,
          radius: 30,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AppIcon(icon, size: 22, color: Colors.white),
                if (badge != null)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: Text(badge!, style: HazriText.caption.copyWith(color: Colors.white, fontSize: 10)),
                  ),
              ],
            ),
          ),
        ),
      );
}

/// Design 129: the countdown under the scene, the group's listeners and the
/// sangat's minutes either side, Pause and End.
class _Sitting extends ConsumerWidget {
  const _Sitting({required this.session, required this.listening, required this.waiting});

  final SimranSession session;
  final int listening;
  final bool waiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final c = ref.read(simranSessionProvider.notifier);
    const white = Colors.white;
    Widget figure(String n, String label, Color colour) => Expanded(
          child: Column(
            children: [
              Text(n, style: SimranText.presence.copyWith(color: colour, fontSize: 22, height: 1)),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HazriText.caption.copyWith(color: white.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
    return Column(
      children: [
        Row(
          children: [
            figure(waiting ? '–' : '$listening', l.liveListeningLabel, const Color(0xFF6EE7A8)),
            Column(
              children: [
                Text(
                  HazriDates.duration(session.remaining),
                  style: SimranText.countdown.copyWith(color: session.paused ? white.withValues(alpha: 0.7) : white),
                ),
                Text(session.paused ? l.simranPaused : l.liveSittingLeft,
                    style: HazriText.caption.copyWith(color: white.withValues(alpha: 0.7))),
              ],
            ),
            figure(HazriDates.duration(session.elapsed), l.liveSatLabel, const Color(0xFF8EC5FF)),
          ],
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  label: session.paused ? l.actionResume : l.actionPause,
                  secondary: true,
                  onPressed: session.paused ? c.resume : c.pause,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: l.simranEnd,
                  onPressed: () => unawaited(c.finish(completed: false)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Design 128: the group as a sheet pulled up from the foot -- minutes
/// listened (LS7a, LS9), Sit (LS10) and the members, A to Z.
class _GroupSheet extends ConsumerWidget {
  const _GroupSheet({
    required this.group,
    required this.def,
    required this.mineToday,
    required this.mineMonth,
    required this.sitMinutes,
    required this.onSit,
  });

  final LiveGroupStatus group;
  final LiveGroupDef def;
  final int mineToday;
  final int mineMonth;
  final int sitMinutes;
  final VoidCallback onSit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    Widget figure(String label, int minutes, {bool large = false}) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.liveMinutesShort(minutes),
                style: (large ? HazriText.display26 : HazriText.display22).copyWith(color: c.ink),
              ),
              Text(label, style: HazriText.caption.copyWith(color: c.ink2)),
            ],
          ),
        );
    return DraggableScrollableSheet(
      initialChildSize: 0.11,
      minChildSize: 0.11,
      maxChildSize: 0.86,
      snap: true,
      builder: (context, scroll) => DecoratedBox(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(HazriSize.gutter, 10, HazriSize.gutter, 24),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: c.rule, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 8),
            Center(child: Text(l.liveSwipeUp, style: HazriText.caption.copyWith(color: c.muted))),
            const SizedBox(height: 14),
            HazriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(l.liveMinutesListened, colour: c.ink2),
                  const SizedBox(height: 10),
                  Row(children: [
                    figure(l.liveSangatToday, group.minutesToday, large: true),
                    figure(l.liveSangatMonth, group.minutesMonth, large: true),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [figure(l.liveYoursToday, mineToday), figure(l.liveYoursMonth, mineMonth)]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(label: l.liveSitFor(sitMinutes), icon: HazriIconData.simranDots, onPressed: onSit),
            const SizedBox(height: 6),
            Text(l.liveSitCounts, style: HazriText.caption.copyWith(color: c.muted)),
            const SizedBox(height: 16),
            Eyebrow(l.liveMembers(group.members), colour: c.ink2),
            const SizedBox(height: 8),
            if (group.memberRows.isEmpty)
              Text(l.liveNoMembers, style: HazriText.bodySmall.copyWith(color: c.muted))
            else
              HazriCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final m in group.memberRows)
                      ListTile(
                        dense: true,
                        title: Text(m.name, style: HazriText.bodyStrong.copyWith(color: c.ink)),
                        subtitle: Text(cityName(ref, m.cityId, lang),
                            style: HazriText.caption.copyWith(color: c.ink2)),
                        trailing: Text(l.liveMinutesShort(m.minutesMonth),
                            style: HazriText.captionStrong.copyWith(color: c.ink2)),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
