import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart' show CompletionSource;
import '../../../core/db/user_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/app_settings.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/surfaces.dart';
import '../../audio/data/audio_controller.dart';
import '../../audio/data/notification_access.dart';
import '../../audio/domain/paath_player.dart';
import '../../audio/domain/timings.dart';
import '../../audio/ui/player_bar.dart';
import '../../nitnem/data/complete_bani.dart';
import '../../nitnem/domain/bani.dart';
import 'gurbani_line_view.dart';
import 'text_settings_sheet.dart';
import '../../hazri/data/hazri_controller.dart';
import '../../goals/data/goals_controller.dart';
import '../../../core/time/date_format.dart';

/// The reader (Design 13-16).
///
/// No ads, no promos, no badges on this screen, ever (PRD 1.5).
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({
    super.key,
    required this.slug,
    this.initialLine,
    this.autoplay = false,
  });

  final String slug;
  final int? initialLine;
  final bool autoplay;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final _itemPositions = ItemPositionsListener.create();
  final _scroller = ItemScrollController();

  Timer? _saveTimer;
  int _topLine = 0;
  int _lastSavedLine = -1;
  int _lastSavedAudioMs = 0;
  bool _jumped = false;
  bool _completionLogged = false;
  final _expandedCommentary = <int>{};

  /// Captured at startup: `dispose` still has to write the resume point, and
  /// `ref` is no longer usable by then.
  late final UserRepository _repo;

  /// The one completion path, and this opening of the bani on it (CR2).
  late final CompletionPath _completion;
  late final int _opening;

  /// Captured alongside the repository: `dispose` writes the audio position
  /// too, and `ref` is gone by then.
  PaathPlayer? _player;

  /// The version being read, once the bani has resolved.
  String? _versionId;

  /// Follow state: which line the paathi is on, and whether the page is still
  /// tracking it (PRD 1.6).
  int _followLine = -1;
  int _followWord = -1;
  bool _attached = true;
  bool _autoScrolling = false;

  /// The recitation is loaded once per visit to this screen.
  bool _prepared = false;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(userRepositoryProvider);
    _player = ref.read(paathPlayerProvider);
    _completion = ref.read(completionPathProvider);
    _opening = _completion.opened(widget.slug);
    if (widget.autoplay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAudio());
    }
    _itemPositions.itemPositions.addListener(_onScroll);
    // Progress is written every five seconds while reading, and again on exit,
    // so a process death loses at most a few lines (PRD 1.5).
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());
  }

  @override
  void dispose() {
    _completion.closed(widget.slug, _opening);
    _itemPositions.itemPositions.removeListener(_onScroll);
    _saveTimer?.cancel();
    _saveProgress();
    WakelockPlus.disable();
    super.dispose();
  }

  /// Starts this bani playing, used by the `autoplay=1` deep link from a
  /// reminder notification.
  Future<void> _startAudio() async {
    final bani = ref.read(baniBySlugProvider(widget.slug)).value;
    if (bani == null || !mounted) return;
    await ref.read(playbackControllerProvider).playBani(
      bani,
      language: L.of(context).localeName,
    );
  }

  /// Moves the highlight, and scrolls if the page is still attached.
  void _applyFollow(BaniTimings timings, Duration position) {
    final index = timings.indexAt(position);
    if (index < 0) return;
    final timing = timings.lines[index];
    final word = timings.wordIndexAt(timing, position);
    if (timing.line == _followLine && word == _followWord) return;

    final lineChanged = timing.line != _followLine;
    setState(() {
      _followLine = timing.line;
      _followWord = word;
    });
    if (lineChanged && _attached) _scrollToCurrent();
  }

  /// Puts the current line about a third of the way down, unless it is already
  /// comfortably on screen (PRD 1.6).
  void _scrollToCurrent({bool force = false}) {
    if (_followLine < 0 || !_scroller.isAttached) return;
    if (!force) {
      final visible = _itemPositions.itemPositions.value
          .where((p) => p.index == _followLine);
      if (visible.isNotEmpty) {
        final edge = visible.first.itemLeadingEdge;
        if (edge >= 0.15 && edge <= 0.60) return;
      }
    }
    _autoScrolling = true;
    _scroller
        .scrollTo(
          index: _followLine,
          alignment: 0.3,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        )
        .whenComplete(() => _autoScrolling = false);
  }

  /// Any drag by hand detaches the page; the highlight keeps moving.
  void _detach() {
    if (_autoScrolling || !_attached || _followLine < 0) return;
    setState(() => _attached = false);
  }

  void _backToPaath() {
    setState(() => _attached = true);
    _scrollToCurrent(force: true);
  }

  /// Tapping a line seeks the recitation there and re-attaches, leaving the
  /// play/pause state alone (PRD 1.6).
  Future<void> _seekToLine(BaniTimings timings, int lineIdx) async {
    final at = timings.startOfLine(lineIdx);
    if (at == null) return;
    final handler = ref.read(audioHandlerProvider);
    if (handler == null) return;
    if (ref.read(playingSlugProvider) != widget.slug) {
      final bani = ref.read(baniBySlugProvider(widget.slug)).value;
      if (bani == null) return;
      await ref.read(playbackControllerProvider).playBani(
        bani,
        at: at,
        language: L.of(context).localeName,
      );
    } else {
      await handler.seek(at);
    }
    setState(() {
      _attached = true;
      _followLine = lineIdx;
    });
    _scrollToCurrent(force: true);
  }

  void _onScroll() {
    final positions = _itemPositions.itemPositions.value;
    if (positions.isEmpty) return;
    final top = positions
        .where((p) => p.itemTrailingEdge > 0)
        .fold<int>(1 << 30, (min, p) => p.index < min ? p.index : min);
    if (top != _topLine && top < (1 << 30)) {
      setState(() => _topLine = top);
    }

    // Reaching the last line is one of the ways a bani counts as complete.
    final last = positions.map((p) => p.index).fold<int>(0, (a, b) => a > b ? a : b);
    _maybeLogCompletion(last, positions.length);
  }

  Future<void> _maybeLogCompletion(int lastVisible, int visibleCount) async {
    if (_completionLogged || !mounted) return;
    final bani = ref.read(baniBySlugProvider(widget.slug)).value;
    final lines = bani?.versionId == null
        ? null
        : ref.read(baniLinesProvider(bani!.versionId!)).value;
    if (bani == null || lines == null || lines.isEmpty) return;
    if (lastVisible < lines.length - 1) return;

    _completionLogged = true;
    // The reader must stay on the last line for five seconds before it counts
    // (PRD 1.9 completion rules).
    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    final stillAtEnd = _itemPositions.itemPositions.value
        .any((p) => p.index >= lines.length - 1);
    if (!stillAtEnd) {
      _completionLogged = false;
      return;
    }
    await _completion.completeBani(bani, CompletionSource.reader);
  }

  void _saveProgress() {
    final versionId = _versionId;
    if (versionId == null) return;
    // The audio position moves even when the page does not, so progress is
    // written whenever either has changed.
    final player = _player;
    final audioMs = player != null && player.currentSlug == widget.slug
        ? player.position.inMilliseconds
        : _lastSavedAudioMs;
    if (_topLine == _lastSavedLine && audioMs == _lastSavedAudioMs) return;
    _lastSavedLine = _topLine;
    _lastSavedAudioMs = audioMs;
    unawaited(_repo.saveProgress(versionId, _topLine, audioPosMs: audioMs));
  }

  /// Jumps to the resume point, or the line a deep link asked for.
  Future<void> _jumpToStart(String versionId) async {
    if (_jumped) return;
    _jumped = true;
    var target = widget.initialLine;
    target ??= (await _repo.progressFor(versionId))?.lineIdx;
    if (target == null || target <= 0 || !mounted) return;
    if (!_scroller.isAttached) return;
    _scroller.jumpTo(index: target, alignment: 0.3);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final settings = ref.watch(settingsProvider);
    final baniAsync = ref.watch(baniBySlugProvider(widget.slug));

    WakelockPlus.toggle(enable: settings.keepScreenOn);

    final bani = baniAsync.value;
    if (bani == null) {
      return Scaffold(
        backgroundColor: c.bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!bani.hasText || bani.versionId == null) {
      return _MissingTextScreen(bani: bani);
    }
    _versionId = bani.versionId;

    final linesAsync = ref.watch(baniLinesProvider(bani.versionId!));
    final tracks = ref.watch(audioTracksProvider).value ?? const {};
    final track = tracks[bani.id];
    final hasAudio = ref.watch(audioHandlerProvider) != null && track != null;
    final timings = track == null
        ? null
        : ref.watch(baniTimingsProvider(track.id)).value;
    final isPlayingThisBani = ref.watch(playingSlugProvider) == bani.slug;

    // Load the recitation as soon as the reader opens, so the scrubber shows a
    // real duration and the play button has something to start.
    if (hasAudio && !_prepared) {
      _prepared = true;
      // The language is read before the await, so no BuildContext is used
      // across the gap.
      final language = L.of(context).localeName;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final saved = await _repo.progressFor(bani.versionId!);
        if (!mounted) return;
        await ref.read(playbackControllerProvider).prepare(
          bani,
          at: saved != null && saved.audioPosMs > 0
              ? Duration(milliseconds: saved.audioPosMs)
              : null,
          language: language,
        );
      });
    }

    // The highlight only moves while this bani is the one being recited and
    // the user has follow turned on.
    if (hasAudio && timings != null && isPlayingThisBani && settings.followAudio) {
      ref.listen<AsyncValue<Duration>>(positionProvider, (_, next) {
        final position = next.value;
        if (position != null && mounted) _applyFollow(timings, position);
      });
    } else if (_followLine != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _followLine = -1);
      });
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: PhoneWidth(
          child: Column(
            children: [
              _ReaderTopBar(
                bani: bani,
                sectionLabel: linesAsync.value != null && linesAsync.value!.isNotEmpty
                    ? linesAsync.value![_topLine.clamp(0, linesAsync.value!.length - 1)]
                        .sectionLabel(l.localeName)
                    : null,
              ),
              if (settings.visraamOn || settings.meaningsOn) const _LegendRow(),
              Expanded(
                child: linesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l.errorContentDb,
                        textAlign: TextAlign.center,
                        style: HazriText.body.copyWith(color: c.ink2),
                      ),
                    ),
                  ),
                  data: (lines) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _jumpToStart(bani.versionId!),
                    );
                    return NotificationListener<UserScrollNotification>(
                      onNotification: (n) {
                        if (n.direction != ScrollDirection.idle) _detach();
                        return false;
                      },
                      child: ScrollablePositionedList.builder(
                        itemScrollController: _scroller,
                        itemPositionsListener: _itemPositions,
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 40),
                        itemCount: lines.length + 1,
                        itemBuilder: (context, i) {
                          if (i == lines.length) {
                            return _EndOfBaniCard(bani: bani);
                          }
                          final line = lines[i];
                          final isCurrent = line.idx == _followLine;
                          return GurbaniLineView(
                            line: line,
                            settings: settings,
                            highlight: _followLine < 0
                                ? LineHighlight.upcoming
                                : isCurrent
                                    ? LineHighlight.current
                                    : line.idx < _followLine
                                        ? LineHighlight.past
                                        : LineHighlight.upcoming,
                            currentWord: isCurrent ? _followWord : null,
                            onTap: timings == null
                                ? null
                                : () => _seekToLine(timings, line.idx),
                            commentaryLabel: l.readerCommentaryExpand(
                              line.meaningIn(settings.meaningsLang)?.sourceId ?? '',
                            ),
                            commentaryNote: l.readerCommentaryNote,
                            showCommentaryExpanded: _expandedCommentary.contains(line.id),
                            onToggleCommentary: () => setState(() {
                              _expandedCommentary.contains(line.id)
                                  ? _expandedCommentary.remove(line.id)
                                  : _expandedCommentary.add(line.id);
                            }),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              if (hasAudio && ref.watch(notificationsAllowedProvider).value == false)
                const _LockScreenControlsBanner(),
              if (hasAudio)
                PlayerBar(
                  bani: bani,
                  following: isPlayingThisBani && _attached && _followLine >= 0,
                  onBackToPaath: _followLine >= 0 && !_attached ? _backToPaath : null,
                )
              else
                const _AudioUnavailableBar(),
            ],
          ),
        ),
      ),
      floatingActionButton: (_followLine >= 0 && !_attached)
          ? _BackToPaathPill(line: _followLine + 1, onTap: _backToPaath)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// The pill that appears once the page has been scrolled away from the paath
/// (Design 15).
class _BackToPaathPill extends StatelessWidget {
  const _BackToPaathPill({required this.line, required this.onTap});

  final int line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(HazriRadius.chip),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HazriRadius.chip),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(HazriIconData.arrowUp, size: 18, color: c.onPrimary),
              const SizedBox(width: 8),
              Text(
                L.of(context).readerBackToPaath(line),
                style: HazriText.chip.copyWith(color: c.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderTopBar extends ConsumerWidget {
  const _ReaderTopBar({required this.bani, required this.sectionLabel});

  final Bani bani;
  final String? sectionLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final script = ref.watch(settingsProvider.select((s) => s.script));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          CardIconButton(
            icon: HazriIconData.chevronLeft,
            tooltip: l.actionBack,
            background: Colors.transparent,
            onPressed: () => context.canPop() ? context.pop() : context.go(Routes.nitnem),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bani.name(l.localeName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.sectionTitle.copyWith(color: c.ink, height: 1.2),
                ),
                Text(
                  [bani.nativeName, if (sectionLabel != null) sectionLabel!].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.gurmukhi(12, weight: FontWeight.w400)
                      .copyWith(color: c.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const _ScriptSwitch(),
          const SizedBox(width: 2),
          InkWell(
            borderRadius: BorderRadius.circular(HazriRadius.iconButton),
            onTap: () => showTextSettingsSheet(context),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  'Aa',
                  style: HazriText.bodyStrong.copyWith(fontSize: 16, color: c.ink),
                ),
              ),
            ),
          ),
          if (script == GurbaniScript.roman) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _ScriptSwitch extends ConsumerWidget {
  const _ScriptSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final current = ref.watch(settingsProvider.select((s) => s.script));

    final options = <(GurbaniScript, String, TextStyle)>[
      (GurbaniScript.gurmukhi, 'ਅ', HazriText.gurmukhi(16, weight: FontWeight.w600)),
      (GurbaniScript.devanagari, 'अ', HazriText.devanagari(16, weight: FontWeight.w600)),
      (GurbaniScript.roman, 'A', HazriText.bodyStrong.copyWith(fontSize: 16)),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.card2,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (script, label, style) in options)
            Semantics(
              button: true,
              selected: current == script,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => ref.read(settingsProvider.notifier).setScript(script),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: current == script ? c.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: current == script ? c.shadows : null,
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: style.copyWith(
                        color: current == script ? c.ink : c.muted,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends ConsumerWidget {
  const _LegendRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final s = ref.watch(settingsProvider);

    Widget dot(Color colour) => Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(28, 2, 28, 10),
      child: Row(
        children: [
          if (s.visraamOn)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(HazriRadius.chip),
                boxShadow: c.shadows,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  dot(c.teal),
                  const SizedBox(width: 6),
                  Text(l.readerShortPause, style: HazriText.chip.copyWith(color: c.ink2)),
                  const SizedBox(width: 12),
                  dot(c.kesri),
                  const SizedBox(width: 6),
                  Text(l.readerLongPause, style: HazriText.chip.copyWith(color: c.ink2)),
                ],
              ),
            ),
          if (s.meaningsOn)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(HazriRadius.chip),
                boxShadow: c.shadows,
              ),
              child: Text(
                l.readerMeaningLabel(switch (s.meaningsLang) {
                  MeaningLanguage.pa => l.langPunjabi,
                  MeaningLanguage.hi => l.langHindi,
                  MeaningLanguage.en => l.langEnglish,
                }),
                style: HazriText.chip.copyWith(color: c.ink2),
              ),
            ),
        ],
      ),
    );
  }
}

/// Design 48 — the closing card at the end of a bani.
///
/// Three things, in the order somebody wants them: that the bani is finished
/// and in the diary, that it marked the day's hazri if it was the first thing
/// finished, and where to go next. The hazri line appears only when this
/// paath is what actually marked the day — saying it under the third bani of
/// the morning would be flattering somebody with a fact about breakfast.
class _EndOfBaniCard extends ConsumerWidget {
  const _EndOfBaniCard({required this.bani});

  final Bani bani;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    final banis = ref.watch(banisProvider).value ?? const <Bani>[];
    final next = banis
        .where((b) => b.defaultSlot == bani.defaultSlot && b.sort > bani.sort)
        .firstOrNull;
    final hazri = ref.watch(hazriTodayProvider);
    // PRD §4.5: the time of *this* completion, the latest of this bani today,
    // not the time hazri was first marked.
    final mine = (ref.watch(todayRowsProvider).value?.completions ?? const [])
        .where((c) => c.baniId == bani.id)
        .map((c) => c.completedAt.toLocal())
        .fold<DateTime?>(null, (a, b) => a == null || b.isAfter(a) ? b : a);
    // "When this was what marked today's hazri": the first thing today was
    // this very paath.
    final markedByThis = hazri.isMarked && hazri.baniId == bani.id && mine != null && hazri.markedAt == mine;

    return Padding(
      // 14 in from the list's own 14, where the lines' text starts.
      padding: const EdgeInsets.fromLTRB(14, 24, 14, 8),
      child: HazriCard(
        border: Border.all(color: c.sage, width: 1.5),
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration:
                      BoxDecoration(color: c.sageSoft, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: AppIcon(HazriIconData.check, size: 24, color: c.sage),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.readerCompleteTitle(bani.name(l.localeName)),
                        style: HazriText.bodyStrong.copyWith(color: c.ink),
                      ),
                      if (mine != null)
                        Text(
                          l.readerLoggedInDiary(HazriDates.of(context).time(mine)),
                          style: HazriText.caption.copyWith(color: c.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (markedByThis) ...[
              const SizedBox(height: 13),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c.kesriSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child:
                        AppIcon(HazriIconData.sunArc, size: 17, color: c.kesriInk),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.hazriMarked,
                            style:
                                HazriText.captionStrong.copyWith(color: c.kesriInk)),
                        Text(l.readerThisMarkedHazri,
                            style: HazriText.caption.copyWith(color: c.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                // Design 48: Start again is the main action.
                Expanded(
                  child: PrimaryButton(
                    label: l.readerStartAgain,
                    icon: HazriIconData.chevronLeft,
                    onPressed: () async {
                      // From the first line, with where it was left cleared;
                      // otherwise the reader reopens at the end it just reached.
                      await ref.read(userRepositoryProvider).clearProgress(bani.versionId!);
                      if (context.mounted) {
                        context.pushReplacement(Routes.reader(bani.slug, line: 0));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: next != null
                      ? PrimaryButton(
                          label: l.readerNextBani,
                          secondary: true,
                          onPressed: () =>
                              context.pushReplacement(Routes.reader(next.slug)),
                        )
                      : PrimaryButton(
                          label: l.readerCompleteBackToNitnem,
                          secondary: true,
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go(Routes.nitnem),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l.readerStartAgainNote,
              textAlign: TextAlign.center,
              style: HazriText.caption.copyWith(color: c.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Offers the way back when notifications are blocked.
///
/// audio_service publishes the media session through the playback service's
/// foreground notification, so a denied POST_NOTIFICATIONS means the paath
/// plays with nothing in the shade and no controls on the lock screen.
class _LockScreenControlsBanner extends ConsumerWidget {
  const _LockScreenControlsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final l = L.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.card,
        // The player bar below carries the same rounded top on the same
        // surface, so the two read as one panel with a rule between them.
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: c.rule),
          bottom: BorderSide(color: c.rule),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: AppIcon(HazriIconData.lock, size: 18, color: c.muted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.readerLockControlsOff,
                  style: HazriText.caption.copyWith(color: c.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  l.readerLockControlsOffSub,
                  style: HazriText.caption.copyWith(color: c.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: () =>
                ref.read(notificationsAllowedProvider.notifier).allow(),
            child: Text(l.actionAllow),
          ),
        ],
      ),
    );
  }
}

/// Stands in for the player bar until audio ships.
class _AudioUnavailableBar extends StatelessWidget {
  const _AudioUnavailableBar();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 10, 18, 10 + MediaQuery.viewPaddingOf(context).bottom),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: c.rule)),
      ),
      child: Row(
        children: [
          AppIcon(HazriIconData.headphones, size: 18, color: c.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l.audioNotInBuild,
              style: HazriText.caption.copyWith(color: c.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown for a bani whose reviewed text has not shipped yet.
class _MissingTextScreen extends StatelessWidget {
  const _MissingTextScreen({required this.bani});

  final Bani bani;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: PhoneWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                child: Row(
                  children: [
                    CardIconButton(
                      icon: HazriIconData.chevronLeft,
                      tooltip: l.actionBack,
                      background: Colors.transparent,
                      onPressed: () =>
                          context.canPop() ? context.pop() : context.go(Routes.nitnem),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        bani.name(l.localeName),
                        style: HazriText.sectionTitle.copyWith(color: c.ink),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          bani.nativeName,
                          style: HazriText.gurmukhi(26).copyWith(color: c.ink),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          l.baniNotInBuild,
                          textAlign: TextAlign.center,
                          style: HazriText.bodyStrong.copyWith(color: c.ink),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l.baniNotInBuildBody,
                          textAlign: TextAlign.center,
                          style: HazriText.bodySmall.copyWith(color: c.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
