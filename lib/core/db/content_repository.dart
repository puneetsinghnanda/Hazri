import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/nitnem/domain/bani.dart';
import '../settings/app_settings.dart';
import '../time/nanakshahi.dart';
import 'content_db.dart';

/// Set during bootstrap in `main.dart`.
final contentDbProvider = Provider<ContentDb>(
  (ref) => throw UnimplementedError('ContentDb must be overridden at startup'),
);

final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepository(ref.watch(contentDbProvider)),
);

/// Every read of the bundled content database.
class ContentRepository {
  ContentRepository(this._db);

  final ContentDb _db;

  /// All banis in display order, each carrying its default version.
  Future<List<Bani>> banis() async {
    final rows = await (_db.select(_db.banis)
          ..orderBy([(t) => OrderingTerm(expression: t.sort)]))
        .get();
    final versions = await (_db.select(_db.baniVersions)
          ..where((v) => v.isDefault.equals(true)))
        .get();
    final byBani = {for (final v in versions) v.baniId: v};
    return [
      for (final r in rows)
        Bani.fromRow(
          r,
          versionId: byBani[r.id]?.id,
          lineCount: byBani[r.id]?.lineCount ?? 0,
        ),
    ];
  }

  Future<Bani?> baniBySlug(String slug) async {
    final row = await (_db.select(_db.banis)..where((b) => b.slug.equals(slug)))
        .getSingleOrNull();
    if (row == null) return null;
    final version = await (_db.select(_db.baniVersions)
          ..where((v) => v.baniId.equals(row.id) & v.isDefault.equals(true)))
        .getSingleOrNull();
    return Bani.fromRow(row, versionId: version?.id, lineCount: version?.lineCount ?? 0);
  }

  Future<Bani?> baniById(String id) async {
    final row = await (_db.select(_db.banis)..where((b) => b.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    final version = await (_db.select(_db.baniVersions)
          ..where((v) => v.baniId.equals(row.id) & v.isDefault.equals(true)))
        .getSingleOrNull();
    return Bani.fromRow(row, versionId: version?.id, lineCount: version?.lineCount ?? 0);
  }

  /// Every line of a bani version, with its meanings attached.
  ///
  /// Japji is 385 lines, so this is one query for the lines and one for all
  /// their meanings rather than a query per line.
  Future<List<GurbaniLine>> lines(String baniVersionId) async {
    final lineRows = await (_db.select(_db.lines)
          ..where((l) => l.baniVersionId.equals(baniVersionId))
          ..orderBy([(l) => OrderingTerm(expression: l.idx)]))
        .get();
    if (lineRows.isEmpty) return const [];

    final ids = lineRows.map((l) => l.id).toList();
    final meaningRows =
        await (_db.select(_db.meanings)..where((m) => m.lineId.isIn(ids))).get();

    final byLine = <int, List<LineMeaning>>{};
    for (final m in meaningRows) {
      final lang = switch (m.lang) {
        'pa' => MeaningLanguage.pa,
        'hi' => MeaningLanguage.hi,
        _ => MeaningLanguage.en,
      };
      // The primary entry comes first so `meaningIn` finds it without sorting.
      final list = byLine.putIfAbsent(m.lineId, () => []);
      final entry = LineMeaning(
        text: m.body,
        lang: lang,
        isCommentary: m.kind == 'commentary',
        sourceId: m.sourceId,
        note: m.note,
      );
      if (m.isAlt) {
        list.add(entry);
      } else {
        list.insert(0, entry);
      }
    }

    return [for (final r in lineRows) GurbaniLine.fromRow(r, byLine[r.id] ?? const [])];
  }

  Future<List<SourceRow>> sources() =>
      (_db.select(_db.sources)..orderBy([(s) => OrderingTerm(expression: s.kind)])).get();

  Future<List<CityRow>> cities() =>
      (_db.select(_db.cities)..orderBy([(c) => OrderingTerm(expression: c.nameEn)])).get();

  Future<CityRow?> city(String id) =>
      (_db.select(_db.cities)..where((c) => c.id.equals(id))).getSingleOrNull();

  /// The first city whose time zone matches [tz], used to pick a sensible
  /// default during setup.
  Future<CityRow?> cityForTimeZone(String tz) =>
      (_db.select(_db.cities)..where((c) => c.tz.equals(tz))).getSingleOrNull();

  Future<List<CalendarEventRow>> calendarEvents() =>
      (_db.select(_db.calendarEvents)..orderBy([(e) => OrderingTerm(expression: e.date)])).get();

  Future<NanakshahiCalendar> nanakshahiCalendar() async {
    final rows = await (_db.select(_db.nanakshahiMonths)
          ..orderBy([(m) => OrderingTerm(expression: m.startDate)]))
        .get();
    return NanakshahiCalendar([
      for (final r in rows)
        NanakshahiMonth(
          year: r.nsYear,
          idx: r.idx,
          nameEn: r.nameEn,
          namePa: r.namePa,
          nameHi: r.nameHi,
          start: DateTime.parse(r.startDate),
          days: r.days,
        ),
    ]);
  }

  Future<QuoteRow?> quote(String id) =>
      (_db.select(_db.quotes)..where((q) => q.id.equals(id))).getSingleOrNull();

  Future<String?> meta(String key) async {
    final row = await (_db.select(_db.metas)..where((m) => m.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }
}

/// All banis, loaded once.
final banisProvider = FutureProvider<List<Bani>>(
  (ref) => ref.watch(contentRepositoryProvider).banis(),
);

final baniBySlugProvider = FutureProvider.family<Bani?, String>(
  (ref, slug) => ref.watch(contentRepositoryProvider).baniBySlug(slug),
);

final baniLinesProvider = FutureProvider.family<List<GurbaniLine>, String>(
  (ref, versionId) => ref.watch(contentRepositoryProvider).lines(versionId),
);

final citiesProvider = FutureProvider<List<CityRow>>(
  (ref) => ref.watch(contentRepositoryProvider).cities(),
);

final nanakshahiCalendarProvider = FutureProvider<NanakshahiCalendar>(
  (ref) => ref.watch(contentRepositoryProvider).nanakshahiCalendar(),
);

final calendarEventsProvider = FutureProvider<List<CalendarEventRow>>(
  (ref) => ref.watch(contentRepositoryProvider).calendarEvents(),
);

final contentSourcesProvider = FutureProvider<List<SourceRow>>(
  (ref) => ref.watch(contentRepositoryProvider).sources(),
);
