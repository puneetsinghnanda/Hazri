import 'package:flutter/foundation.dart';

/// Text a saakhi carries in each of its languages. Asked for a language it
/// does not have, it answers in English (SK9: a saakhi ships in the
/// languages it has, and the reader falls back to one it can show).
@immutable
class SaakhiText {
  const SaakhiText(this.byLanguage);

  final Map<String, String> byLanguage;

  bool has(String language) => (byLanguage[language] ?? '').isNotEmpty;

  String of(String language) =>
      has(language) ? byLanguage[language]! : (byLanguage['en'] ?? byLanguage.values.firstOrNull ?? '');

  static SaakhiText parse(Object? raw) => SaakhiText({
    if (raw is Map)
      for (final e in raw.entries)
        if (e.key is String && e.value is String) e.key as String: e.value as String,
  });
}

/// A run of story text, and whether it is the Guru's own words (SK4: marked
/// `<q>` in the source file and shown in a warm tint).
typedef SaakhiRun = ({String text, bool quoted});

/// Splits text on its `<q>` … `</q>` marks.
List<SaakhiRun> saakhiRuns(String text) {
  final runs = <SaakhiRun>[];
  var rest = text;
  while (rest.isNotEmpty) {
    final open = rest.indexOf('<q>');
    if (open < 0) {
      runs.add((text: rest, quoted: false));
      break;
    }
    if (open > 0) runs.add((text: rest.substring(0, open), quoted: false));
    final close = rest.indexOf('</q>', open + 3);
    final end = close < 0 ? rest.length : close;
    runs.add((text: rest.substring(open + 3, end), quoted: true));
    rest = close < 0 ? '' : rest.substring(close + 4);
  }
  return runs;
}

/// The words without their marks, for a share's plain text.
String saakhiPlain(String text) => text.replaceAll('<q>', '').replaceAll('</q>', '');

/// A line of Gurbani on a saakhi (SK3, SK14): read by the content pipeline
/// from a named source file, with its Ang. A language with no meaning shows
/// the pankti alone.
@immutable
class SaakhiGurbani {
  const SaakhiGurbani({required this.lines, required this.ang, required this.meaning, required this.source});

  final List<String> lines;
  final int ang;
  final SaakhiText meaning;
  final SaakhiText source;

  static SaakhiGurbani? parse(Object? raw) {
    if (raw is! Map) return null;
    final lines = [
      for (final l in (raw['lines'] as List? ?? const []))
        if (l is String) l,
    ];
    if (lines.isEmpty) return null;
    return SaakhiGurbani(
      lines: lines,
      ang: (raw['ang'] as num?)?.toInt() ?? 0,
      meaning: SaakhiText.parse(raw['meaning']),
      source: SaakhiText.parse(raw['source']),
    );
  }
}

@immutable
class SaakhiPage {
  const SaakhiPage({required this.title, required this.text, required this.image, this.gurbani});

  final SaakhiText title;
  final SaakhiText text;
  final String image;
  final SaakhiGurbani? gurbani;
}

@immutable
class SaakhiLesson {
  const SaakhiLesson({required this.title, required this.line, required this.ask, required this.image});

  final SaakhiText title;
  final SaakhiText line;
  final SaakhiText ask;
  final String image;
}

/// One recording and the time each page starts (SK8).
///
/// The reader's pages are numbered from the cover: 0 is the cover, 1 … n the
/// story pages and n + 1 the lesson. `pageStarts[i]` is when reader page
/// i + 1 begins.
@immutable
class SaakhiNarration {
  const SaakhiNarration({required this.asset, required this.duration, required this.pageStarts, this.meaningAt});

  final String asset;
  final Duration duration;
  final List<Duration> pageStarts;

  /// When the voice reaches the meaning of the pankti: the Gurbani row opens.
  final Duration? meaningAt;

  /// The reader page the voice is on at [position].
  int pageAt(Duration position) {
    var page = 1;
    for (var i = 0; i < pageStarts.length; i++) {
      if (pageStarts[i] <= position) page = i + 1;
    }
    return page;
  }

  /// Where the voice starts reader page [page]; the cover starts at 0.
  Duration startOf(int page) => page <= 1 ? Duration.zero : pageStarts[(page - 1).clamp(0, pageStarts.length - 1)];

  static Duration _seconds(num s) => Duration(milliseconds: (s * 1000).round());

  static SaakhiNarration? parse(Object? raw) {
    if (raw is! Map || raw['asset'] is! String) return null;
    return SaakhiNarration(
      asset: raw['asset'] as String,
      duration: _seconds((raw['duration'] as num?) ?? 0),
      pageStarts: [
        for (final s in (raw['pageStarts'] as List? ?? const []))
          if (s is num) _seconds(s),
      ],
      meaningAt: raw['meaningAt'] is num ? _seconds(raw['meaningAt'] as num) : null,
    );
  }
}

/// A saakhi as the content pipeline resolved it (13-saakhi.md).
@immutable
class Saakhi {
  const Saakhi({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.blurb,
    required this.cover,
    required this.coverTitleInImage,
    required this.pages,
    required this.lesson,
    required this.narration,
    this.shabad,
  });

  final String id;
  final SaakhiText title;
  final SaakhiText subtitle;
  final SaakhiText blurb;
  final String cover;

  /// The cover painting already carries the title, so the reader draws none.
  final bool coverTitleInImage;
  final List<SaakhiPage> pages;
  final SaakhiLesson lesson;
  final SaakhiGurbani? shabad;
  final Map<String, SaakhiNarration> narration;

  /// Story pages and the lesson: what the library counts as "8 pages".
  int get pageCount => pages.length + 1;

  /// The reader's last page, the lesson.
  int get lessonPage => pages.length + 1;

  /// The recording in [language], or null when there is none yet.
  SaakhiNarration? narrationIn(String language) => narration[language];

  /// Whole minutes, rounded, of the longest recording: the "2 min" chip.
  int get minutes {
    final longest = narration.values.fold(Duration.zero, (a, n) => n.duration > a ? n.duration : a);
    return longest == Duration.zero ? 0 : (longest.inSeconds / 60).round().clamp(1, 999);
  }

  static Map<String, SaakhiNarration> _narrations(Object? raw) {
    final out = <String, SaakhiNarration>{};
    if (raw is Map) {
      for (final e in raw.entries) {
        final n = SaakhiNarration.parse(e.value);
        if (e.key is String && n != null) out[e.key as String] = n;
      }
    }
    return out;
  }

  static Saakhi? fromJson(Map<String, Object?> data) {
    final id = data['id'];
    if (id is! String) return null;
    final lesson = data['lesson'] as Map? ?? const {};
    final cover = data['cover'] as Map? ?? const {};
    return Saakhi(
      id: id,
      title: SaakhiText.parse(data['title']),
      subtitle: SaakhiText.parse(data['subtitle']),
      blurb: SaakhiText.parse(data['blurb']),
      cover: cover['image'] as String? ?? '',
      coverTitleInImage: cover['titleInImage'] == true,
      pages: [
        for (final p in (data['pages'] as List? ?? const []))
          if (p is Map)
            SaakhiPage(
              title: SaakhiText.parse(p['title']),
              text: SaakhiText.parse(p['text']),
              image: p['image'] as String? ?? '',
              gurbani: SaakhiGurbani.parse(p['gurbani']),
            ),
      ],
      lesson: SaakhiLesson(
        title: SaakhiText.parse(lesson['title']),
        line: SaakhiText.parse(lesson['line']),
        ask: SaakhiText.parse(lesson['ask']),
        image: lesson['image'] as String? ?? '',
      ),
      shabad: SaakhiGurbani.parse(data['shabad']),
      narration: _narrations(data['narration']),
    );
  }
}
