import 'package:flutter/foundation.dart';

/// What kind of thing an entry is. The chips on design 43, and the eyebrow
/// above every card.
enum EntryKind {
  article,
  gurdwara,
  guru,
  bani,
  day;

  static EntryKind parse(String? v) => EntryKind.values.firstWhere(
        (k) => k.name == v,
        orElse: () => EntryKind.article,
      );
}

/// One thing to read or look up.
///
/// **Nothing in here is written in Dart.** The body of every entry comes from
/// the server, which is the same rule the banis follow for the same reason:
/// what the app says about Gurdwaras, the Guru Sahibans, the banis and the
/// Sikh days is written and reviewed by people, corrected in one place, and
/// never generated. An app with no entries shows none.
@immutable
class LibraryEntry {
  const LibraryEntry({
    required this.id,
    required this.kind,
    required this.title,
    this.summary = '',
    this.body = '',
    this.minutes = 0,
    this.facts = const {},
    this.place = '',
  });

  final String id;
  final EntryKind kind;
  final String title;
  final String summary;

  /// Paragraphs, split on blank lines when shown.
  final String body;

  /// Reading time, as the source states it. Not computed here: a word count
  /// is a poor guess in Gurmukhi and a worse one in a mixed script.
  final int minutes;

  /// The labelled rows on design 45 — Where, Marks, Open, Langar. An ordered
  /// map so the source decides what appears and in what order, rather than
  /// this class deciding for it.
  final Map<String, String> facts;

  /// A city or region, shown under the title of a place.
  final String place;

  /// Whether this entry matches what somebody typed.
  ///
  /// Deliberately plain: title, summary and place, case-folded, substring.
  /// There is no ranking because there are not enough entries for ranking to
  /// beat "it is in there somewhere".
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return title.toLowerCase().contains(q) ||
        summary.toLowerCase().contains(q) ||
        place.toLowerCase().contains(q);
  }

  /// One entry as `GET /api/v1/vichar/entries` returns it: `facts` is an
  /// ordered list of `{label, value}`, so the source decides the order.
  static LibraryEntry? fromJson(Map<String, Object?> data) {
    final id = data['id'] as String?;
    final title = (data['title'] as String?)?.trim();
    if (id == null || title == null || title.isEmpty) return null;
    final facts = <String, String>{};
    final raw = data['facts'];
    if (raw is List) {
      for (final f in raw) {
        if (f is Map && f['label'] is String && f['value'] is String) {
          facts[f['label'] as String] = f['value'] as String;
        }
      }
    }
    return LibraryEntry(
      id: id,
      kind: EntryKind.parse(data['kind'] as String?),
      title: title,
      summary: (data['summary'] as String?) ?? '',
      body: (data['body'] as String?) ?? '',
      minutes: ((data['minutes'] as num?) ?? 0).toInt(),
      place: (data['place'] as String?) ?? '',
      facts: facts,
    );
  }


  @override
  bool operator ==(Object other) => other is LibraryEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
