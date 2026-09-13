import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/settings/app_settings.dart';

/// One line of a Hukamnama.
@immutable
class HukamnamaLine {
  const HukamnamaLine({
    required this.gurmukhi,
    required this.devanagari,
    required this.roman,
    this.meanings = const {},
    this.isRahao = false,
  });

  factory HukamnamaLine.fromJson(Map<String, dynamic> json) => HukamnamaLine(
    gurmukhi: json['gurmukhi'] as String? ?? '',
    devanagari: json['devanagari'] as String? ?? '',
    roman: json['roman'] as String? ?? '',
    isRahao: json['rahao'] as bool? ?? false,
    meanings: {
      for (final lang in MeaningLanguage.values)
        if ((json['meanings'] as Map<String, dynamic>?)?[lang.name] is String)
          lang: (json['meanings'] as Map<String, dynamic>)[lang.name] as String,
    },
  );

  final String gurmukhi;
  final String devanagari;
  final String roman;
  final Map<MeaningLanguage, String> meanings;
  final bool isRahao;

  String textFor(GurbaniScript script) => switch (script) {
    GurbaniScript.gurmukhi => gurmukhi,
    GurbaniScript.devanagari => devanagari,
    GurbaniScript.roman => roman,
  };

  Map<String, dynamic> toJson() => {
    'gurmukhi': gurmukhi,
    'devanagari': devanagari,
    'roman': roman,
    'rahao': isRahao,
    'meanings': {for (final e in meanings.entries) e.key.name: e.value},
  };
}

/// One day's Hukamnama from Sri Darbar Sahib.
@immutable
class Hukamnama {
  const Hukamnama({
    required this.date,
    required this.lines,
    this.ang,
    this.raag,
    this.writer,
    this.fetchedAt,
    this.sourceName,
  });

  factory Hukamnama.fromJson(Map<String, dynamic> json) => Hukamnama(
    date: DateTime.parse(json['date'] as String),
    ang: json['ang'] as int?,
    raag: json['raag'] as String?,
    writer: json['writer'] as String?,
    sourceName: json['source'] as String?,
    fetchedAt: json['fetchedAt'] == null
        ? null
        : DateTime.parse(json['fetchedAt'] as String),
    lines: [
      for (final l in (json['lines'] as List<dynamic>? ?? []))
        HukamnamaLine.fromJson(l as Map<String, dynamic>),
    ],
  );

  static Hukamnama? tryDecode(String payload) {
    try {
      return Hukamnama.fromJson(jsonDecode(payload) as Map<String, dynamic>);
    } on FormatException {
      return null;
    }
  }

  final DateTime date;
  final List<HukamnamaLine> lines;
  final int? ang;
  final String? raag;
  final String? writer;
  final DateTime? fetchedAt;
  final String? sourceName;

  String toJsonString() => jsonEncode({
    'date': date.toIso8601String(),
    'ang': ang,
    'raag': raag,
    'writer': writer,
    'source': sourceName,
    'fetchedAt': fetchedAt?.toIso8601String(),
    'lines': [for (final l in lines) l.toJson()],
  });
}

/// Where the daily Hukamnama comes from.
///
/// Phase 1 ships no implementation that reaches the network: the provider and
/// its terms are still an open decision (PRD §18, D4), and this build makes no
/// network requests at all. The interface is here so adding a permitted source
/// later is one class, with the screen, cache and share card already built.
abstract interface class HukamnamaSource {
  /// False when no source is configured, which the UI explains rather than
  /// showing an error.
  bool get isConfigured;

  /// The human-readable name shown in About, or null when unconfigured.
  String? get name;

  /// Fetches the Hukamnama for [date], or null if it is not available.
  Future<Hukamnama?> fetch(DateTime date);
}

/// The Phase 1 source: none.
class UnconfiguredHukamnamaSource implements HukamnamaSource {
  const UnconfiguredHukamnamaSource();

  @override
  bool get isConfigured => false;

  @override
  String? get name => null;

  @override
  Future<Hukamnama?> fetch(DateTime date) async => null;
}
