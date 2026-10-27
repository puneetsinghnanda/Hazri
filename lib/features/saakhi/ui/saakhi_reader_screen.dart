import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/router.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_text.dart';
import '../data/saakhi_repository.dart';
import '../domain/saakhi.dart';
import 'saakhi_share.dart';

/// The reader's own palette: it is always the night page of the approved
/// design (design/saakhi/reader.template.html), whatever the app's theme,
/// because the pictures are what it is about.
abstract final class SaakhiColors {
  static const night = Color(0xFF080B1C);
  static const gold = Color(0xFFF2A24E);
  static const goldInk = Color(0xFFFFC27E);
  static const onGold = Color(0xFF1C1206);
  static const quote = Color(0xFFFFE3BF);
  static const heart = Color(0xFFF26B5B);
}

/// One saakhi, page by page (13-saakhi.md SK6-SK12).
///
/// Pages are numbered from the cover: 0 is the cover, 1 … n the story pages
/// and n + 1 the lesson, which is design D for every saakhi (SK7). Playing
/// the narration turns the pages at their times; turning a page while it
/// plays moves the voice to that page (SK8). Nothing here is counted (SK7).
class SaakhiReaderScreen extends ConsumerStatefulWidget {
  const SaakhiReaderScreen({super.key, required this.id, this.listen = false});

  final String id;

  /// Opened from a "Listen" chip: starts the narration at page 1.
  final bool listen;

  @override
  ConsumerState<SaakhiReaderScreen> createState() => _SaakhiReaderScreenState();
}

class _SaakhiReaderScreenState extends ConsumerState<SaakhiReaderScreen> {
  AudioPlayer? _player;
  String? _loadedAsset;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<PlayerState>? _stateSub;
  Duration _position = Duration.zero;
  bool _playing = false;
  int _page = 0;
  String? _lang;
  bool _gurbaniOpen = false;
  bool _autoStarted = false;

  @override
  void dispose() {
    _positionSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  /// SK9: Punjabi, text and voice, in every app language whenever the saakhi
  /// has it (owner, 2026-10-27); English only for a saakhi without Punjabi.
  /// The switch on the cover still changes it.
  String _defaultLanguage(Saakhi s) => s.title.has('pa') ? 'pa' : 'en';

  Future<AudioPlayer?> _ensurePlayer(SaakhiNarration n) async {
    if (_player != null && _loadedAsset == n.asset) return _player;
    final player = _player ?? AudioPlayer();
    _player = player;
    try {
      await player.setAsset(n.asset);
      _loadedAsset = n.asset;
    } on Object catch (e) {
      debugPrint('Hazri: saakhi narration ${n.asset} did not load ($e)');
      return null;
    }
    _positionSub ??= player.positionStream.listen(_onPosition);
    _stateSub ??= player.playerStateStream.listen((st) {
      if (st.processingState == ProcessingState.completed && mounted) {
        setState(() => _playing = false);
        player.pause();
      }
    });
    return player;
  }

  void _onPosition(Duration position) {
    if (!mounted) return;
    final s = ref.read(saakhiProvider(widget.id)).value;
    final n = s?.narrationIn(_lang ?? 'en');
    setState(() {
      _position = position;
      if (!_playing || n == null || s == null) return;
      final page = n.pageAt(position);
      if (page != _page) {
        _page = page;
        if (page != s.lessonPage) _gurbaniOpen = false;
      }
      // SK8: the Gurbani row opens itself when the voice reaches the meaning.
      if (_page == s.lessonPage && n.meaningAt != null && position >= n.meaningAt! && !_gurbaniOpen) {
        _gurbaniOpen = true;
      }
    });
  }

  Future<void> _setPlaying(Saakhi s, bool on) async {
    final n = s.narrationIn(_lang!);
    if (on && n == null) return;
    if (!on) {
      setState(() => _playing = false);
      await _player?.pause();
      return;
    }
    final player = await _ensurePlayer(n!);
    if (player == null || !mounted) return;
    var page = _page;
    if (page == 0) page = 1;
    // Resume inside the page on screen; otherwise start it from its beginning.
    if (n.pageAt(player.position) != page || player.processingState == ProcessingState.completed) {
      await player.seek(n.startOf(page));
    }
    setState(() {
      _page = page;
      _playing = true;
    });
    unawaited(player.play());
  }

  void _go(Saakhi s, int page) {
    final target = page.clamp(0, s.lessonPage);
    setState(() {
      _page = target;
      if (target != s.lessonPage) _gurbaniOpen = false;
    });
    final n = s.narrationIn(_lang!);
    if (_playing && n != null) {
      if (target == 0) {
        _setPlaying(s, false);
        _player?.seek(Duration.zero);
      } else {
        _player?.seek(n.startOf(target));
      }
    }
  }

  void _setLanguage(Saakhi s, String lang) {
    if (lang == _lang) return;
    if (_playing && s.narrationIn(lang) == null) _setPlaying(s, false);
    setState(() => _lang = lang);
  }

  Future<void> _share(Saakhi s) async {
    if (_playing) await _setPlaying(s, false);
    if (!mounted) return;
    await showSaakhiShareSheet(context, saakhi: s, page: _page, language: _lang!);
  }

  void _close() => context.canPop() ? context.pop() : context.go(Routes.saakhis);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(saakhiProvider(widget.id)).value;
    if (s == null) {
      return const Scaffold(backgroundColor: SaakhiColors.night);
    }
    _lang ??= _defaultLanguage(s);
    if (widget.listen && !_autoStarted && s.narrationIn(_lang!) != null) {
      _autoStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _setPlaying(s, true));
    }
    final l = L.of(context);
    final lang = _lang!;
    final image = _page == 0 ? s.cover : (_page == s.lessonPage ? s.lesson.image : s.pages[_page - 1].image);

    return PopScope(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(Routes.saakhis);
      },
      child: Scaffold(
        backgroundColor: SaakhiColors.night,
        body: GestureDetector(
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v.abs() < 200) return;
            _go(s, _page + (v < 0 ? 1 : -1));
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: Image.asset(
                  image,
                  key: ValueKey(image),
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.2),
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, _, _) => const ColoredBox(color: SaakhiColors.night),
                ),
              ),
              _Shade(
                kind: _page == 0 ? _ShadeKind.cover : (_page == s.lessonPage ? _ShadeKind.lesson : _ShadeKind.story),
              ),
              if (_page > 0) ...[
                // Tap the left third to go back, the rest to go on, as in the design.
                Positioned(
                  left: 0,
                  top: 120,
                  bottom: 260,
                  width: MediaQuery.sizeOf(context).width / 3,
                  child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _go(s, _page - 1)),
                ),
                Positioned(
                  right: 0,
                  top: 120,
                  bottom: 260,
                  width: MediaQuery.sizeOf(context).width * 2 / 3,
                  child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _go(s, _page + 1)),
                ),
              ],
              SafeArea(
                child: Column(
                  children: [
                    if (_page > 0)
                      _TopBar(
                        saakhi: s,
                        page: _page,
                        language: lang,
                        position: _position,
                        playing: _playing,
                        onClose: _close,
                        onLanguage: (v) => _setLanguage(s, v),
                      )
                    else
                      Align(
                        alignment: Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: _GlassButton(icon: Icons.close, label: l.actionClose, onTap: _close),
                        ),
                      ),
                    // A long page (the lesson with its Gurbani open) scrolls
                    // rather than running under the edge; it stays anchored
                    // to the bottom like the design.
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: SingleChildScrollView(
                          reverse: true,
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                          child: switch (_page) {
                            0 => _Cover(
                              saakhi: s,
                              language: lang,
                              onListen: s.narrationIn(lang) == null && s.narrationIn('en') == null
                                  ? null
                                  : () {
                                      if (s.narrationIn(lang) == null) _setLanguage(s, 'en');
                                      _player?.seek(Duration.zero);
                                      _setPlaying(s, true);
                                    },
                              onRead: () => _go(s, 1),
                            ),
                            final p when p == s.lessonPage => _Lesson(
                              saakhi: s,
                              language: lang,
                              playing: _playing,
                              canPlay: s.narrationIn(lang) != null,
                              gurbaniOpen: _gurbaniOpen,
                              meaningLit:
                                  _playing &&
                                  s.narrationIn(lang)?.meaningAt != null &&
                                  _position >= s.narrationIn(lang)!.meaningAt!,
                              hint: _hint(l, s, lang),
                              onPlay: () => _setPlaying(s, !_playing),
                              onGurbani: () => setState(() => _gurbaniOpen = !_gurbaniOpen),
                              onShare: () => _share(s),
                              onAgain: () {
                                _setPlaying(s, false);
                                _player?.seek(Duration.zero);
                                _go(s, 0);
                              },
                            ),
                            final p => _StoryPage(
                              saakhi: s,
                              index: p,
                              language: lang,
                              playing: _playing,
                              canPlay: s.narrationIn(lang) != null,
                              favourite: (ref.watch(saakhiFavouritesProvider).value ?? const {}).contains(s.id),
                              hint: _hint(l, s, lang),
                              onPrev: () => _go(s, p - 1),
                              onNext: () => _go(s, p + 1),
                              onPlay: () => _setPlaying(s, !_playing),
                              onShare: () => _share(s),
                              onFavourite: (on) => ref.read(saakhiRepositoryProvider).setFavourite(s.id, on),
                            ),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The time while it plays, or why there is no voice (SK8).
  String _hint(L l, Saakhi s, String lang) {
    final n = s.narrationIn(lang);
    if (n == null) return lang == 'pa' ? l.saakhiPunjabiNarrationComing : l.saakhiNarrationComing;
    if (!_playing && _position == Duration.zero) return '';
    String fmt(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
    return '${fmt(_position)} / ${fmt(n.duration)}';
  }
}

enum _ShadeKind { cover, story, lesson }

class _Shade extends StatelessWidget {
  const _Shade({required this.kind});

  final _ShadeKind kind;

  @override
  Widget build(BuildContext context) {
    const n = SaakhiColors.night;
    final (stops, alphas) = switch (kind) {
      _ShadeKind.cover => (const [0.0, 0.5, 1.0], const [0.0, 0.0, 0.9]),
      _ShadeKind.story => (const [0.0, 0.18, 0.42, 0.62, 1.0], const [0.55, 0.0, 0.0, 0.78, 0.96]),
      _ShadeKind.lesson => (const [0.0, 0.3, 0.6, 1.0], const [0.6, 0.55, 0.92, 0.98]),
    };
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: stops,
            colors: [for (final a in alphas) n.withValues(alpha: a)],
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Material(
      color: SaakhiColors.night.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox.square(dimension: 44, child: Icon(icon, color: Colors.white, size: 22)),
      ),
    ),
  );
}

/// The progress bars, one per page after the cover, then close, the name
/// and the language switch.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.saakhi,
    required this.page,
    required this.language,
    required this.position,
    required this.playing,
    required this.onClose,
    required this.onLanguage,
  });

  final Saakhi saakhi;
  final int page;
  final String language;
  final Duration position;
  final bool playing;
  final VoidCallback onClose;
  final ValueChanged<String> onLanguage;

  /// The page being read is a full bar, so the lesson fills the last one
  /// (it stayed empty unless the voice was playing, 2026-10-27). While the
  /// narration is part-way through this page, the bar shows how far.
  double _fill(int barPage) {
    if (barPage < page) return 1;
    if (barPage > page) return 0;
    final n = saakhi.narrationIn(language);
    if (n == null) return 1;
    final start = n.startOf(barPage);
    final end = barPage < saakhi.lessonPage ? n.startOf(barPage + 1) : n.duration;
    final span = (end - start).inMilliseconds;
    final within = position > start && position < end;
    if (span <= 0 || !within) return 1;
    return ((position - start).inMilliseconds / span).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        children: [
          Row(
            children: [
              for (var i = 1; i <= saakhi.lessonPage; i++) ...[
                if (i > 1) const SizedBox(width: 4),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: _fill(i),
                      minHeight: 3,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.28),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _GlassButton(icon: Icons.close, label: l.actionClose, onTap: onClose),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  saakhi.title.of(language),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.bodyStrong.copyWith(color: Colors.white.withValues(alpha: 0.9), fontSize: 14),
                ),
              ),
              if (saakhi.title.has('pa'))
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: SaakhiColors.night.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      for (final (code, label) in [('en', l.setupLanguageEnglish), ('pa', l.setupLanguagePunjabi)])
                        Semantics(
                          selected: code == language,
                          button: true,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => onLanguage(code),
                            child: Container(
                              constraints: const BoxConstraints(minHeight: 36),
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: code == language ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                label,
                                style: HazriText.captionStrong.copyWith(
                                  color: code == language ? SaakhiColors.night : Colors.white.withValues(alpha: 0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

TextStyle _body(String lang) => lang == 'pa'
    ? HazriText.body.copyWith(color: Colors.white, fontSize: 20, height: 1.6)
    : HazriText.body.copyWith(color: Colors.white, fontSize: 19, height: 1.5);

TextStyle _eyebrow(String lang) => HazriText.captionStrong.copyWith(
  color: SaakhiColors.goldInk,
  fontSize: lang == 'pa' ? 14 : 12,
  letterSpacing: lang == 'pa' ? 0 : 0.9,
);

class _Cover extends StatelessWidget {
  const _Cover({required this.saakhi, required this.language, required this.onListen, required this.onRead});

  final Saakhi saakhi;
  final String language;
  final VoidCallback? onListen;
  final VoidCallback onRead;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          saakhi.title.of('pa'),
          textAlign: TextAlign.center,
          style: HazriText.display22.copyWith(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
        ),
        Text(
          saakhi.title.of('en'),
          textAlign: TextAlign.center,
          style: HazriText.display34.copyWith(color: Colors.white, fontSize: 32, height: 1.1),
        ),
        const SizedBox(height: 4),
        Text(
          saakhi.subtitle.of(language),
          textAlign: TextAlign.center,
          style: HazriText.body.copyWith(color: Colors.white.withValues(alpha: 0.8), fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 18),
        if (onListen != null) ...[
          _BigButton(label: l.saakhiListen, icon: Icons.play_arrow_rounded, onTap: onListen!),
          const SizedBox(height: 10),
          _BigButton(label: l.saakhiRead, onTap: onRead, outlined: true),
        ] else
          _BigButton(label: l.saakhiRead, icon: Icons.menu_book_outlined, onTap: onRead),
      ],
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({required this.label, required this.onTap, this.icon, this.outlined = false});

  final String label;
  final IconData? icon;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? Colors.white : SaakhiColors.onGold;
    return Material(
      color: outlined ? Colors.transparent : SaakhiColors.gold,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: outlined ? BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: outlined ? 48 : 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, color: fg, size: 20), const SizedBox(width: 8)],
              Text(
                label,
                style: HazriText.bodyStrong.copyWith(color: fg, fontSize: outlined ? 15 : 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round button: the gold play, or a dim one for prev, next and the heart.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 48,
    this.gold = false,
    this.colour,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;
  final bool gold;
  final Color? colour;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: Material(
          color: gold ? SaakhiColors.gold : Colors.white.withValues(alpha: 0.12),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox.square(
              dimension: size,
              child: Icon(icon, size: size * 0.46, color: colour ?? (gold ? SaakhiColors.onGold : Colors.white)),
            ),
          ),
        ),
      ),
    );
  }
}

class _SharePill extends StatelessWidget {
  const _SharePill({required this.onTap, this.gold = false});

  final VoidCallback onTap;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final fg = gold ? SaakhiColors.onGold : SaakhiColors.night;
    return Material(
      color: gold ? SaakhiColors.gold : Colors.white,
      borderRadius: BorderRadius.circular(gold ? 16 : 999),
      child: InkWell(
        borderRadius: BorderRadius.circular(gold ? 16 : 999),
        onTap: onTap,
        child: Container(
          height: gold ? 48 : 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share_outlined, size: 18, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  l.saakhiShare,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HazriText.bodyStrong.copyWith(color: fg, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Story text with the Guru's own words in a warm tint (SK4).
class SaakhiStoryText extends StatelessWidget {
  const SaakhiStoryText({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        for (final r in saakhiRuns(text))
          TextSpan(
            text: r.text,
            style: r.quoted ? style.copyWith(color: SaakhiColors.quote) : style,
          ),
      ],
    ),
    style: style.copyWith(shadows: const [Shadow(blurRadius: 12, color: Color(0x59000000))]),
  );
}

/// A line of Gurbani on a story page: the pankti, its meaning in this
/// language if there is one, and where it is from (SK14, SK3).
class _InlineGurbani extends StatelessWidget {
  const _InlineGurbani({required this.gurbani, required this.language, required this.source});

  final SaakhiGurbani gurbani;
  final String language;
  final SaakhiText source;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final src = source.of(language);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.fromLTRB(14, 6, 0, 6),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: SaakhiColors.gold, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(gurbani.lines.join('\n'), style: HazriText.gurmukhi(21).copyWith(color: SaakhiColors.quote)),
          if (gurbani.meaning.has(language))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                gurbani.meaning.byLanguage[language]!,
                style: HazriText.body.copyWith(color: Colors.white.withValues(alpha: 0.82), fontSize: 15, height: 1.45),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              src.isEmpty ? l.saakhiAng(gurbani.ang) : l.saakhiSourceAng(src, gurbani.ang),
              style: HazriText.caption.copyWith(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: SizedBox(
      height: 16,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: HazriText.caption.copyWith(
          color: Colors.white.withValues(alpha: 0.55),
          fontSize: 12,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
  );
}

class _StoryPage extends StatelessWidget {
  const _StoryPage({
    required this.saakhi,
    required this.index,
    required this.language,
    required this.playing,
    required this.canPlay,
    required this.favourite,
    required this.hint,
    required this.onPrev,
    required this.onNext,
    required this.onPlay,
    required this.onShare,
    required this.onFavourite,
  });

  final Saakhi saakhi;
  final int index;
  final String language;
  final bool playing;
  final bool canPlay;
  final bool favourite;
  final String hint;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPlay;
  final VoidCallback onShare;
  final ValueChanged<bool> onFavourite;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final page = saakhi.pages[index - 1];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('${l.saakhiPageOf(index, saakhi.lessonPage)} · ${page.title.of(language)}', style: _eyebrow(language)),
        const SizedBox(height: 8),
        SaakhiStoryText(text: page.text.of(language), style: _body(language)),
        if (page.gurbani != null)
          _InlineGurbani(
            gurbani: page.gurbani!,
            language: language,
            source: saakhi.shabad?.source ?? page.gurbani!.source,
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Flexible(
              flex: 3,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SharePill(onTap: onShare),
              ),
            ),
            const SizedBox(width: 8),
            _RoundButton(icon: Icons.chevron_left_rounded, label: l.saakhiPreviousPage, onTap: onPrev, size: 44),
            const SizedBox(width: 8),
            _RoundButton(
              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: playing ? l.saakhiPause : l.saakhiPlay,
              onTap: canPlay ? onPlay : null,
              size: 64,
              gold: true,
            ),
            const SizedBox(width: 8),
            _RoundButton(icon: Icons.chevron_right_rounded, label: l.saakhiNextPage, onTap: onNext, size: 44),
            const SizedBox(width: 8),
            const Spacer(flex: 2),
            _RoundButton(
              icon: favourite ? Icons.favorite : Icons.favorite_border,
              label: l.saakhiFavourite,
              onTap: () => onFavourite(!favourite),
              size: 44,
              colour: favourite ? SaakhiColors.heart : Colors.white,
            ),
          ],
        ),
        _Hint(hint),
      ],
    );
  }
}

/// Design D (SK7): the title with a small play, one big line, a question
/// for the family, the Gurbani row if there is a shabad, Share and Read again.
class _Lesson extends ConsumerWidget {
  const _Lesson({
    required this.saakhi,
    required this.language,
    required this.playing,
    required this.canPlay,
    required this.gurbaniOpen,
    required this.meaningLit,
    required this.hint,
    required this.onPlay,
    required this.onGurbani,
    required this.onShare,
    required this.onAgain,
  });

  final Saakhi saakhi;
  final String language;
  final bool playing;
  final bool canPlay;
  final bool gurbaniOpen;
  final bool meaningLit;
  final String hint;
  final VoidCallback onPlay;
  final VoidCallback onGurbani;
  final VoidCallback onShare;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final shabad = saakhi.shabad;
    final ik = ref.watch(ikOnkarProvider).value ?? '';
    final pa = language == 'pa';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('✦ ${saakhi.lesson.title.of(language)}', style: _eyebrow(language))),
            _RoundButton(
              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: playing ? l.saakhiPause : l.saakhiPlay,
              onTap: canPlay ? onPlay : null,
              size: 44,
              gold: true,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          saakhi.lesson.line.of(language),
          style: HazriText.display34.copyWith(color: Colors.white, fontSize: pa ? 28 : 30, height: pa ? 1.3 : 1.15),
        ),
        Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: SaakhiColors.gold.withValues(alpha: 0.14),
            border: Border.all(color: SaakhiColors.gold.withValues(alpha: 0.35)),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: SaakhiColors.goldInk),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      pa ? l.saakhiTalkTogether : l.saakhiTalkTogether.toUpperCase(),
                      style: _eyebrow(language),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                saakhi.lesson.ask.of(language),
                style: HazriText.body.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (shabad != null) ...[
          const SizedBox(height: 16),
          Material(
            color: Colors.white.withValues(alpha: 0.07),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onGurbani,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: SaakhiColors.gold.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Text(ik, style: HazriText.gurmukhi(16).copyWith(color: SaakhiColors.goldInk, height: 1)),
                    ),
                    const SizedBox(width: 10),
                    Text(l.saakhiGurbani, style: HazriText.bodyStrong.copyWith(color: Colors.white, fontSize: 15)),
                    const Spacer(),
                    Text(
                      l.saakhiAng(shabad.ang),
                      style: HazriText.caption.copyWith(color: Colors.white.withValues(alpha: 0.55), fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      gurbaniOpen ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (gurbaniOpen)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shabad.lines.join('\n'),
                    style: HazriText.gurmukhi(18).copyWith(color: SaakhiColors.quote, height: 1.75),
                  ),
                  if (shabad.meaning.has(language))
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        shabad.meaning.byLanguage[language]!,
                        style: HazriText.body.copyWith(
                          color: meaningLit ? SaakhiColors.quote : Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l.saakhiSourceAng(shabad.source.of(language), shabad.ang),
                      style: HazriText.caption.copyWith(color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _SharePill(onTap: onShare, gold: true)),
            const SizedBox(width: 10),
            Expanded(
              child: Material(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onAgain,
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.replay_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            l.saakhiReadAgain,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: HazriText.bodyStrong.copyWith(color: Colors.white, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        _Hint(hint),
      ],
    );
  }
}
