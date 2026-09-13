import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/db/content_db.dart';
import '../../../core/settings/app_settings.dart';

/// A bani as the app deals with it, with its names in all three languages.
@immutable
class Bani {
  const Bani({
    required this.id,
    required this.slug,
    required this.nameEn,
    required this.namePa,
    required this.nameHi,
    required this.category,
    required this.defaultSlot,
    required this.sort,
    required this.estMinutes,
    required this.hasText,
    this.authorEn,
    this.versionId,
    this.lineCount = 0,
  });

  factory Bani.fromRow(BaniRow r, {String? versionId, int lineCount = 0}) => Bani(
    id: r.id,
    slug: r.slug,
    nameEn: r.nameEn,
    namePa: r.namePa,
    nameHi: r.nameHi,
    category: r.category,
    defaultSlot: BaniSlot.values.firstWhere(
      (s) => s.name == r.defaultSlot,
      orElse: () => BaniSlot.none,
    ),
    sort: r.sort,
    estMinutes: r.estMinutes,
    hasText: r.hasText,
    authorEn: r.authorEn,
    versionId: versionId,
    lineCount: lineCount,
  );

  final String id;
  final String slug;
  final String nameEn;
  final String namePa;
  final String nameHi;
  final String category;
  final BaniSlot defaultSlot;
  final int sort;
  final int estMinutes;

  /// False for a bani whose reviewed text has not shipped yet.
  final bool hasText;
  final String? authorEn;
  final String? versionId;
  final int lineCount;

  /// The name in the app language.
  String name(String languageCode) => switch (languageCode) {
    'pa' => namePa,
    'hi' => nameHi,
    _ => nameEn,
  };

  /// The Gurmukhi name, shown as a subline next to the English one.
  String get nativeName => namePa;
}

/// One pause mark: the index of the word it follows and how long it is.
@immutable
class Visraam {
  const Visraam(this.wordIndex, this.isLong);

  final int wordIndex;
  final bool isLong;
}

/// A meaning or teeka entry for one line.
@immutable
class LineMeaning {
  const LineMeaning({
    required this.text,
    required this.lang,
    required this.isCommentary,
    this.sourceId,
    this.note,
  });

  final String text;
  final MeaningLanguage lang;

  /// True for the Faridkot teeka, which explains rather than translates and so
  /// is shown collapsed.
  final bool isCommentary;
  final String? sourceId;
  final String? note;
}

/// One line of Gurbani in all three scripts, with its pause marks and meaning.
@immutable
class GurbaniLine {
  const GurbaniLine({
    required this.id,
    required this.idx,
    required this.kind,
    required this.gurmukhi,
    required this.devanagari,
    required this.roman,
    required this.wordCount,
    required this.wordAlign,
    this.visraam = const [],
    this.sectionLabelEn,
    this.sectionLabelPa,
    this.sectionLabelHi,
    this.pauri,
    this.meanings = const [],
    this.sourceRef,
  });

  factory GurbaniLine.fromRow(LineRow r, List<LineMeaning> meanings) {
    final marks = <Visraam>[];
    if (r.visraamJson != null) {
      for (final m in jsonDecode(r.visraamJson!) as List<dynamic>) {
        final map = m as Map<String, dynamic>;
        marks.add(Visraam(map['w'] as int, map['t'] == 'long'));
      }
    }
    return GurbaniLine(
      id: r.id,
      idx: r.idx,
      kind: LineKind.values.firstWhere(
        (k) => k.name == r.kind,
        orElse: () => LineKind.verse,
      ),
      gurmukhi: r.gurmukhi,
      devanagari: r.devanagari,
      roman: r.roman,
      wordCount: r.wordCount,
      wordAlign: r.wordAlign,
      visraam: marks,
      sectionLabelEn: r.sectionLabelEn,
      sectionLabelPa: r.sectionLabelPa,
      sectionLabelHi: r.sectionLabelHi,
      pauri: r.pauri,
      meanings: meanings,
      sourceRef: r.sourceRef,
    );
  }

  final int id;
  final int idx;
  final LineKind kind;
  final String gurmukhi;
  final String devanagari;
  final String roman;
  final int wordCount;

  /// False when the scripts do not split into the same number of words, so the
  /// reader highlights the whole line rather than a word.
  final bool wordAlign;
  final List<Visraam> visraam;
  final String? sectionLabelEn;
  final String? sectionLabelPa;
  final String? sectionLabelHi;
  final int? pauri;
  final List<LineMeaning> meanings;
  final String? sourceRef;

  bool get isHeading => kind == LineKind.heading || kind == LineKind.mangal;

  String textFor(GurbaniScript script) => switch (script) {
    GurbaniScript.gurmukhi => gurmukhi,
    GurbaniScript.devanagari => devanagari,
    GurbaniScript.roman => roman,
  };

  String? sectionLabel(String languageCode) => switch (languageCode) {
    'pa' => sectionLabelPa,
    'hi' => sectionLabelHi,
    _ => sectionLabelEn,
  };

  /// The translation for [lang], preferring a plain translation over a
  /// commentary.
  LineMeaning? meaningIn(MeaningLanguage lang) {
    LineMeaning? commentary;
    for (final m in meanings) {
      if (m.lang != lang) continue;
      if (!m.isCommentary) return m;
      commentary ??= m;
    }
    return commentary;
  }
}
