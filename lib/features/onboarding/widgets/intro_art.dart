import 'package:flutter/material.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../../core/theme/icon_data.dart';
import '../../../core/widgets/app_icon.dart';
import '../../../core/widgets/day_arc.dart';
import '../../../core/widgets/surfaces.dart';

/// Intro art is built from the app's real widgets rather than bitmaps, so it
/// localises and follows the theme (PRD 1.1).

/// The arc art is drawn at 330 where there is room, and shrinks to fit a
/// narrow phone rather than overflowing.
double _artWidth(BuildContext context) {
  final available = MediaQuery.sizeOf(context).width - 2 * 24;
  return available < 330 ? available : 330;
}

/// Intro 1: the day arc with its three slots and the promise chips.
class IntroArtDayArc extends StatelessWidget {
  const IntroArtDayArc({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);
    final base = DateTime(2026, 1, 1, 4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: _artWidth(context),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              DayArc(
                width: _artWidth(context),
                now: base.add(const Duration(hours: 1, minutes: 25)),
                windowStart: base,
                windowEnd: base.add(const Duration(hours: 19)),
                nodes: [
                  DayArcNode(
                    label: l.slotAmritVela,
                    at: base.add(const Duration(minutes: 30)),
                    state: ArcNodeState.active,
                  ),
                  DayArcNode(
                    label: l.slotEvening,
                    at: base.add(const Duration(hours: 16)),
                    state: ArcNodeState.todo,
                  ),
                  DayArcNode(
                    label: l.slotBedtime,
                    at: base.add(const Duration(hours: 18, minutes: 30)),
                    state: ArcNodeState.todo,
                  ),
                ],
              ),
              Positioned(
                top: 62,
                child: Column(
                  children: [
                    AppIcon(HazriIconData.sunArc, size: 22, color: c.kesriInk),
                    const SizedBox(height: 2),
                    Text(
                      'ਜਪੁ ਜੀ ਸਾਹਿਬ',
                      style: HazriText.gurmukhi(22, weight: FontWeight.w600).copyWith(
                        color: c.ink,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      '${l.slotAmritVela} · ${l.minutes(20)}',
                      style: HazriText.captionStrong.copyWith(color: c.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: _artWidth(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SlotLabel(
                  title: l.slotAmritVela,
                  sub: l.introBanisCount(5),
                  colour: c.kesriInk,
                  align: CrossAxisAlignment.start,
                ),
              ),
              Expanded(
                child: _SlotLabel(
                  title: l.diaryStatRehras,
                  sub: l.introAtSunset,
                  colour: c.ink2,
                  align: CrossAxisAlignment.center,
                ),
              ),
              Expanded(
                child: _SlotLabel(
                  title: l.diaryStatSohila,
                  sub: l.introBeforeSleep,
                  colour: c.ink2,
                  align: CrossAxisAlignment.end,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            HazriChip(
              label: l.chipWorksOffline,
              icon: HazriIconData.check,
              background: c.sageSoft,
              foreground: c.sage,
            ),
            HazriChip(label: l.chipNoLogin),
            HazriChip(label: l.chipNoAdsOnGurbani),
          ],
        ),
      ],
    );
  }
}

class _SlotLabel extends StatelessWidget {
  const _SlotLabel({
    required this.title,
    required this.sub,
    required this.colour,
    required this.align,
  });

  final String title;
  final String sub;
  final Color colour;
  final CrossAxisAlignment align;

  TextAlign get _textAlign => switch (align) {
    CrossAxisAlignment.end => TextAlign.end,
    CrossAxisAlignment.center => TextAlign.center,
    _ => TextAlign.start,
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: align,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        textAlign: _textAlign,
        style: HazriText.chip.copyWith(color: colour, fontWeight: FontWeight.w700),
      ),
      Text(
        sub,
        textAlign: _textAlign,
        style: HazriText.caption.copyWith(color: context.colors.muted),
      ),
    ],
  );
}

/// Intro 2: a line lit up as it is recited, and the locked-phone note.
class IntroArtFollowing extends StatelessWidget {
  const IntroArtFollowing({super.key});

  static const _before = 'ਹੈ ਭੀ ਸਚੁ ਨਾਨਕ ਹੋਸੀ ਭੀ ਸਚੁ ॥੧॥';
  static const _currentA = 'ਸੋਚੈ ਸੋਚਿ ਨ ਹੋਵਈ ';
  static const _currentWord = 'ਜੇ';
  static const _currentB = ' ਸੋਚੀ ਲਖ ਵਾਰ ॥';
  static const _after = 'ਚੁਪੈ ਚੁਪ ਨ ਹੋਵਈ ਜੇ ਲਾਇ ਰਹਾ ਲਿਵ ਤਾਰ ॥';

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HazriCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _before,
                style: HazriText.gurmukhi(19).copyWith(color: c.muted),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: c.hl,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text.rich(
                  TextSpan(
                    style: HazriText.gurmukhi(19).copyWith(color: c.ink),
                    children: [
                      const TextSpan(text: _currentA),
                      TextSpan(
                        text: _currentWord,
                        style: TextStyle(
                          color: c.word,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          decorationColor: c.word,
                          decorationThickness: 2,
                        ),
                      ),
                      const TextSpan(text: _currentB),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(_after, style: HazriText.gurmukhi(19).copyWith(color: c.ink2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  AppIcon(HazriIconData.play, size: 18, color: c.kesriInk),
                  const SizedBox(width: 8),
                  Text(
                    l.readerFollowingAudio,
                    style: HazriText.chip.copyWith(color: c.kesriInk),
                  ),
                  const Spacer(),
                  Text('4:12 / 19:04', style: HazriText.caption.copyWith(color: c.muted)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        HazriChip(
          icon: HazriIconData.lock,
          label: '${l.introPhoneLocked} · ${l.introPaathKeepsPlaying}',
          background: c.card2,
          foreground: c.ink2,
          minHeight: 38,
        ),
      ],
    );
  }
}

/// Intro 3: the same line in each of the three scripts.
class IntroArtScripts extends StatelessWidget {
  const IntroArtScripts({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l = L.of(context);

    Widget row(String eyebrow, String text, TextStyle style) => HazriCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(eyebrow),
          const SizedBox(height: 2),
          Text(text, style: style.copyWith(color: c.ink)),
        ],
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        row('ਗੁਰਮੁਖੀ · GURMUKHI', 'ਆਦਿ ਸਚੁ ਜੁਗਾਦਿ ਸਚੁ ॥', HazriText.gurmukhi(21)),
        const SizedBox(height: 10),
        row('हिन्दी · DEVANAGARI', 'आदि सचु जुगादि सचु ॥', HazriText.devanagari(20)),
        const SizedBox(height: 10),
        row('ROMAN', 'aad sach jugaad sach', HazriText.roman(18)),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            HazriChip(label: l.introMeaningsIn),
            HazriChip(
              label: l.elderMode,
              icon: HazriIconData.eye,
              background: c.kesriSoft,
              foreground: c.kesriInk,
            ),
          ],
        ),
      ],
    );
  }
}
