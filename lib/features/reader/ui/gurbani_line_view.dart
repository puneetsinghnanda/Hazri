import 'package:flutter/material.dart';

import '../../../core/settings/app_settings.dart';
import '../../../core/theme/hazri_colors.dart';
import '../../../core/theme/hazri_text.dart';
import '../../nitnem/domain/bani.dart';

/// How a line is drawn right now.
enum LineHighlight { past, current, upcoming }

/// One line of Gurbani, with its optional Roman line and meaning.
///
/// Words are laid out as separate spans even in Larivaar, so the word being
/// recited can still be marked once audio arrives.
class GurbaniLineView extends StatelessWidget {
  const GurbaniLineView({
    super.key,
    required this.line,
    required this.settings,
    this.highlight = LineHighlight.upcoming,
    this.currentWord,
    this.onTap,
    this.showCommentaryExpanded = false,
    this.onToggleCommentary,
    this.commentaryLabel,
    this.commentaryNote,
  });

  final GurbaniLine line;
  final AppSettings settings;
  final LineHighlight highlight;

  /// Index of the word being recited, when audio is following.
  final int? currentWord;
  final VoidCallback? onTap;
  final bool showCommentaryExpanded;
  final VoidCallback? onToggleCommentary;
  final String? commentaryLabel;
  final String? commentaryNote;

  /// Vishraam marks are recorded against Gurmukhi word indices, so they are
  /// only applied to another script when that script splits into the same
  /// number of words.
  bool get _canShowVishraam =>
      settings.visraamOn &&
      line.visraam.isNotEmpty &&
      (settings.script == GurbaniScript.gurmukhi || line.wordAlign);

  TextStyle _baseStyle(HazriColors c) {
    final size = settings.effectiveReaderFontSize;
    final style = switch (settings.script) {
      GurbaniScript.gurmukhi => HazriText.gurmukhi(size),
      GurbaniScript.devanagari => HazriText.devanagari(size - 1),
      GurbaniScript.roman => HazriText.roman(size - 4),
    };
    return style.copyWith(
      height: 1.75,
      color: highlight == LineHighlight.past ? c.muted : c.ink,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final base = _baseStyle(c);
    final isCurrent = highlight == LineHighlight.current;

    final body = Column(
      crossAxisAlignment: line.isHeading ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text.rich(
          _buildSpans(c, base),
          textAlign: line.isHeading ? TextAlign.center : TextAlign.start,
        ),
        if (settings.showRomanUnderGurmukhi &&
            settings.script != GurbaniScript.roman &&
            line.roman.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            line.roman,
            textAlign: line.isHeading ? TextAlign.center : TextAlign.start,
            style: HazriText.roman(13).copyWith(
              color: c.muted,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
        if (settings.meaningsOn) _meaning(context, c),
      ],
    );

    final padded = isCurrent
        ? Container(
            decoration: BoxDecoration(
              color: c.hl,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(horizontal: -14),
            child: body,
          )
        : body;

    return Semantics(
      label: line.textFor(settings.script),
      // The current line changing must not be announced: it would interrupt
      // the paath (PRD §11).
      liveRegion: false,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: padded,
        ),
      ),
    );
  }

  Widget _meaning(BuildContext context, HazriColors c) {
    final meaning = line.meaningIn(settings.meaningsLang);
    if (meaning == null) return const SizedBox.shrink();

    final style = HazriText.body.copyWith(fontSize: 14.5, height: 1.45, color: c.ink2);

    // The Faridkot teeka explains rather than translates and can run many times
    // the length of the line, so it sits behind a disclosure instead of
    // breaking the flow of the paath (owner's decision).
    if (!meaning.isCommentary) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(meaning.text, style: style),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggleCommentary,
            borderRadius: BorderRadius.circular(HazriRadius.chip),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    showCommentaryExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: c.kesriInk,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    commentaryLabel ?? '',
                    style: HazriText.chip.copyWith(color: c.kesriInk),
                  ),
                ],
              ),
            ),
          ),
          if (showCommentaryExpanded) ...[
            Text(meaning.text, style: style),
            if (commentaryNote != null) ...[
              const SizedBox(height: 6),
              Text(
                commentaryNote!,
                style: HazriText.caption.copyWith(color: c.muted, fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ],
      ),
    );
  }

  TextSpan _buildSpans(HazriColors c, TextStyle base) {
    final text = line.textFor(settings.script);
    final words = text.split(' ').where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return TextSpan(text: text, style: base);

    final vishraamFor = <int, bool>{
      if (_canShowVishraam)
        for (final v in line.visraam) v.wordIndex: v.isLong,
    };

    final spans = <InlineSpan>[];
    for (var i = 0; i < words.length; i++) {
      var style = base;

      final isLong = vishraamFor[i];
      if (isLong != null) {
        style = style.copyWith(color: isLong ? c.kesriInk : c.teal);
      }

      // The word being recited wins over a pause mark on the same word.
      if (currentWord == i && line.wordAlign) {
        style = style.copyWith(
          color: c.word,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: c.kesri,
          decorationThickness: 3,
        );
      }

      spans.add(TextSpan(text: words[i], style: style));
      // Larivaar joins the words visually while keeping them separate spans.
      if (i != words.length - 1) {
        spans.add(TextSpan(text: settings.larivaarOn ? '' : ' ', style: base));
      }
    }
    return TextSpan(children: spans);
  }
}
