import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_db.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/settings/app_settings.dart';
import 'package:hazri/features/nitnem/domain/bani.dart';

/// Checks the database `tools/content_pipeline` produced, so a bad build of the
/// content is caught here rather than on a phone.
void main() {
  late ContentDb db;
  late ContentRepository repo;

  setUpAll(() {
    final file = File('assets/content/content.db');
    expect(
      file.existsSync(),
      isTrue,
      reason: 'run tools/content_pipeline/build_content_db.py first',
    );
    db = ContentDb(NativeDatabase(file));
    repo = ContentRepository(db);
  });

  tearDownAll(() => db.close());

  test('the bundled content version matches what the app expects', () async {
    expect(await repo.meta('content_version'), '${ContentDb.expectedVersion}');
  });

  test('all nine Phase 1 banis are listed, in slot order', () async {
    final banis = await repo.banis();
    expect(banis.length, 9);
    expect(banis.first.slug, 'japji-sahib');
    expect(
      banis.where((b) => b.defaultSlot == BaniSlot.morning).length,
      5,
      reason: 'Japji, Jaap, Tav Prasad Savaiye, Chaupai, Anand',
    );
    expect(banis.where((b) => b.defaultSlot == BaniSlot.evening).single.slug, 'rehras-sahib');
    expect(banis.where((b) => b.defaultSlot == BaniSlot.bedtime).single.slug, 'kirtan-sohila');
  });

  test('every bani has its text', () async {
    final banis = await repo.banis();
    final without = banis.where((b) => !b.hasText).map((b) => b.slug).toList();
    expect(without, isEmpty);
  });

  test('every bani has a version with as many lines as the table holds',
      () async {
    for (final bani in await repo.banis()) {
      expect(bani.versionId, isNotNull, reason: bani.slug);
      final lines = await repo.lines(bani.versionId!);
      expect(lines, isNotEmpty, reason: bani.slug);
      expect(lines.length, bani.lineCount, reason: bani.slug);
      for (var i = 0; i < lines.length; i++) {
        expect(lines[i].idx, i, reason: bani.slug);
      }
    }
  });

  test('the minutes a bani claims are the minutes it plays for', () async {
    // est_minutes used to be a hand-set guess. Now that every recitation
    // ships it is measured from the recording, so the number on the Nitnem
    // row is the number of minutes the player will actually run.
    for (final bani in await repo.banis()) {
      expect(bani.estMinutes, greaterThan(0), reason: bani.slug);
      final track = await repo.audioTrack(bani.versionId!);
      final ms = track?.durationMs;
      if (ms == null) continue;
      expect(bani.estMinutes, (ms / 60000).ceil(), reason: bani.slug);
    }
  });

  group('Japji Sahib', () {
    late List<GurbaniLine> lines;

    setUpAll(() async {
      final japji = await repo.baniBySlug('japji-sahib');
      expect(japji, isNotNull);
      expect(japji!.versionId, isNotNull);
      lines = await repo.lines(japji.versionId!);
    });

    test('has all 385 lines, in order', () {
      expect(lines.length, 385);
      for (var i = 0; i < lines.length; i++) {
        expect(lines[i].idx, i);
      }
    });

    test('opens with the Mool Mantar and closes with the salok', () {
      expect(lines.first.gurmukhi, startsWith('ੴ'));
      expect(lines.first.kind, LineKind.mangal);
      expect(lines.last.gurmukhi, isNotEmpty);
    });

    test('every line carries all three scripts', () {
      for (final line in lines) {
        expect(line.gurmukhi, isNotEmpty, reason: 'line ${line.idx}');
        expect(line.devanagari, isNotEmpty, reason: 'line ${line.idx}');
        expect(line.roman, isNotEmpty, reason: 'line ${line.idx}');
      }
    });

    test('no pause punctuation leaked into the displayed text', () {
      // ';', '.' and ',' encode vishraam in the source and must be stripped,
      // with the marks stored as word indices instead.
      for (final line in lines) {
        expect(line.gurmukhi, isNot(contains(';')), reason: 'line ${line.idx}');
        expect(line.gurmukhi, isNot(contains('.')), reason: 'line ${line.idx}');
      }
    });

    test('vishraam marks point at real words', () {
      var withMarks = 0;
      for (final line in lines) {
        if (line.visraam.isEmpty) continue;
        withMarks++;
        for (final v in line.visraam) {
          expect(v.wordIndex, greaterThanOrEqualTo(0), reason: 'line ${line.idx}');
          expect(v.wordIndex, lessThan(line.wordCount), reason: 'line ${line.idx}');
        }
      }
      expect(withMarks, greaterThan(300), reason: 'most lines carry a pause mark');
    });

    test('word alignment holds for all but the Mool Mantar', () {
      final misaligned = lines.where((l) => !l.wordAlign).map((l) => l.idx).toList();
      // Line 0 is the Mool Mantar, where "ੴ" is one Gurmukhi word but two
      // Roman ones ("ik oankaar"); it falls back to line-only highlighting.
      expect(misaligned, [0]);
    });

    test('aligned lines split into the same number of words in every script', () {
      for (final line in lines) {
        if (!line.wordAlign) continue;
        final g = line.gurmukhi.split(' ').where((w) => w.isNotEmpty).length;
        final d = line.devanagari.split(' ').where((w) => w.isNotEmpty).length;
        final r = line.roman.split(' ').where((w) => w.isNotEmpty).length;
        expect(d, g, reason: 'devanagari, line ${line.idx}');
        expect(r, g, reason: 'roman, line ${line.idx}');
        expect(line.wordCount, g, reason: 'stored word count, line ${line.idx}');
      }
    });

    test('every line has an English and a Punjabi meaning', () {
      for (final line in lines) {
        expect(
          line.meaningIn(MeaningLanguage.en),
          isNotNull,
          reason: 'english, line ${line.idx}',
        );
        expect(
          line.meaningIn(MeaningLanguage.pa),
          isNotNull,
          reason: 'punjabi, line ${line.idx}',
        );
      }
    });

    test('the Hindi entry is marked as commentary, not a translation', () {
      final withHindi = lines.where((l) => l.meaningIn(MeaningLanguage.hi) != null);
      // Line 379 is the bare heading "ਸਲੋਕੁ ॥" and has no teeka entry.
      expect(withHindi.length, 384);
      for (final line in withHindi) {
        expect(line.meaningIn(MeaningLanguage.hi)!.isCommentary, isTrue);
      }
    });

    test('the primary meaning wins over the alternative', () async {
      final first = lines.first;
      expect(first.meaningIn(MeaningLanguage.en)!.sourceId, 'SBMS');
      expect(first.meaningIn(MeaningLanguage.pa)!.sourceId, 'PSST');
    });

    test('section labels run from the Mool Mantar through 38 pauris', () {
      expect(lines.first.sectionLabelEn, 'Mool Mantar');
      final pauriLabels =
          lines.map((l) => l.sectionLabelEn).whereType<String>().toSet();
      expect(pauriLabels.contains('Pauri 1 of 38'), isTrue);
      expect(pauriLabels.contains('Pauri 38 of 38'), isTrue);
    });
  });

  test('every text and meaning source is credited', () async {
    final sources = await repo.sources();
    final ids = sources.map((s) => s.id).toSet();
    for (final needed in ['SHABADOS', 'GURMUKHIUTILS', 'SBMS', 'PSST', 'NKFT', 'SGPCCAL']) {
      expect(ids, contains(needed));
    }
  });

  test('the city list covers India and the diaspora', () async {
    final cities = await repo.cities();
    expect(cities.length, greaterThan(80));
    expect(cities.map((c) => c.id), contains('amritsar'));
    expect(cities.map((c) => c.id), contains('new_delhi'));
    expect(cities.map((c) => c.countryCode).toSet().length, greaterThan(10));
    for (final c in cities) {
      expect(c.lat, inInclusiveRange(-90, 90));
      expect(c.lon, inInclusiveRange(-180, 180));
      expect(c.tz, contains('/'));
    }
  });

  group('Nanakshahi calendar', () {
    test('resolves a date the bundled jantri covers', () async {
      final calendar = await repo.nanakshahiCalendar();
      final ns = calendar.dateFor(DateTime(2026, 9, 12));
      expect(ns, isNotNull);
      expect(ns!.label('en'), '27 Bhadon');
      expect(ns.year, 558);
    });

    test('returns null outside the bundled months rather than guessing', () async {
      final calendar = await repo.nanakshahiCalendar();
      expect(calendar.dateFor(DateTime(2026, 1, 1)), isNull);
      expect(calendar.dateFor(DateTime(2027, 6, 1)), isNull);
      expect(calendar.coveredFrom, isNotNull);
      expect(calendar.coveredToInclusive, isNotNull);
    });

    test('agrees with every event label in the shipped calendar', () async {
      final calendar = await repo.nanakshahiCalendar();
      final events = await repo.calendarEvents();
      expect(events, isNotEmpty);
      for (final e in events) {
        final ns = calendar.dateFor(DateTime.parse(e.date));
        expect(ns, isNotNull, reason: e.date);
        expect('${ns!.label('en')} ${ns.year}', e.nsLabel, reason: e.date);
      }
    });
  });

  test('the Simran quote comes from content, not from app code', () async {
    final quote = await repo.quote('simran_1');
    expect(quote, isNotNull);
    expect(quote!.gurmukhi, isNotEmpty);
    expect(quote.devanagari, isNotEmpty);
    expect(quote.attributionEn, 'Sukhmani Sahib');
  });
}
