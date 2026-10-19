import 'package:flutter/foundation.dart';

/// What kind of thing an entry is: the eyebrow above every card. Four of
/// them are also the topics the chips filter by ([topics]); `article` is a
/// kind only, kept for an entry that names no topic.
enum EntryKind {
  article,
  gurdwara,
  guru,
  bani,
  day;

  /// The chips, in order. Sikh days comes first and lists every entry,
  /// because every story page is a day in the calendar (owner, 2026-10-19).
  static const topics = [day, gurdwara, guru, bani];

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
    this.tags = const {},
    this.dates = const [],
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

  /// The topics it is listed under. Empty means its [kind] alone.
  final Set<EntryKind> tags;

  /// The calendar days it tells the story of, YYYY-MM-DD, earliest first.
  final List<String> dates;

  /// Whether the chip for [topic] lists this entry. Sikh days lists them all.
  bool listedUnder(EntryKind topic) =>
      topic == EntryKind.day || tags.contains(topic) || kind == topic;

  /// The first of [dates] on or after [today] (YYYY-MM-DD), or null when they
  /// are all past or there are none.
  String? nextDate(String today) =>
      dates.where((d) => d.compareTo(today) >= 0).firstOrNull;

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
      tags: {
        if (data['tags'] case final List<Object?> raw)
          for (final t in raw)
            if (t is String && EntryKind.topics.any((k) => k.name == t))
              EntryKind.parse(t),
      },
      dates: [
        if (data['dates'] case final List<Object?> raw)
          for (final d in raw)
            if (d is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d)) d,
      ]..sort(),
    );
  }


  @override
  bool operator ==(Object other) => other is LibraryEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
