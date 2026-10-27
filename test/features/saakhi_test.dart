import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_db.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/saakhi/data/saakhi_repository.dart';
import 'package:hazri/features/saakhi/domain/saakhi.dart';

/// 13-saakhi.md against the content.db the pipeline built.
void main() {
  late ContentDb content;
  late UserDb user;
  late SaakhiRepository repo;

  setUpAll(() {
    content = ContentDb(NativeDatabase(File('assets/content/content.db')));
  });
  tearDownAll(() => content.close());

  setUp(() {
    user = UserDb.memory();
    repo = SaakhiRepository(content, user, FixedClock(DateTime(2026, 10, 25, 9)));
  });
  tearDown(() => user.close());

  test('the four saakhis ship, in the order Today shows them', () async {
    final all = await repo.all();
    expect(all.map((s) => s.id), [
      'bhai-lalo-malik-bhago',
      'anand-bhaya-meri-maaye',
      'why-was-the-hut-broken',
      'the-saint-soldier',
    ]);
    for (final s in all) {
      expect(s.pages, hasLength(7), reason: s.id);
      expect(s.pageCount, 8, reason: 'seven pages and the lesson');
      expect(s.title.has('en') && s.title.has('pa'), isTrue, reason: s.id);
      expect(s.narrationIn('en'), isNotNull, reason: s.id);
      // The owner's Punjabi recordings, 2026-10-27 (SK8): a start for every
      // page and the lesson, in order, inside the recording.
      final pa = s.narrationIn('pa');
      expect(pa, isNotNull, reason: s.id);
      expect(pa!.pageStarts, hasLength(8), reason: s.id);
      for (var i = 1; i < pa.pageStarts.length; i++) {
        expect(pa.pageStarts[i], greaterThan(pa.pageStarts[i - 1]), reason: '${s.id} page ${i + 1}');
      }
      expect(pa.pageStarts.last, lessThan(pa.duration), reason: s.id);
    }
  });

  test('SK1: every image and recording a saakhi names is on the phone', () async {
    for (final s in await repo.all()) {
      final files = [s.cover, s.lesson.image, for (final p in s.pages) p.image, for (final n in s.narration.values) n.asset];
      for (final f in files) {
        expect(File(f).existsSync(), isTrue, reason: '${s.id}: $f');
      }
    }
  });

  test('SK3: Gurbani comes from a named source, and an unchecked pankti never ships', () async {
    final all = {for (final s in await repo.all()) s.id: s};
    // Anand Sahib's line, read from content/source/anand-sahib.json.
    final anand = all['anand-bhaya-meri-maaye']!;
    expect(anand.shabad!.ang, 917);
    expect(anand.pages[3].gurbani!.ang, 917, reason: 'page 4 carries the line (SK14)');
    expect(anand.shabad!.meaning.has('en'), isTrue);
    // Ang 105, checked against BaniDB on 2026-10-25.
    final lalo = all['bhai-lalo-malik-bhago']!;
    expect(lalo.shabad!.ang, 105);
    expect(lalo.shabad!.lines, hasLength(2));
    expect(lalo.shabad!.meaning.has('pa'), isFalse, reason: 'no Punjabi meaning: the pankti shows alone');
    expect(lalo.narrationIn('en')!.meaningAt, isNotNull);
    // No shabad, or one with no Ang and meaning yet (SK-15): no row at all.
    expect(all['why-was-the-hut-broken']!.shabad, isNull);
    expect(all['the-saint-soldier']!.shabad, isNull);
  });

  test('Listen from the cover: the pages turn at their times (SK8, scenario 1)', () async {
    final lalo = (await repo.all()).first;
    final n = lalo.narrationIn('en')!;
    int at(int m, int s) => n.pageAt(Duration(minutes: m, seconds: s));
    expect([at(0, 0), at(0, 15), at(0, 27), at(0, 40), at(0, 58), at(1, 15), at(1, 39), at(1, 52)],
        [1, 2, 3, 4, 5, 6, 7, 8]);
    expect(at(2, 10), lalo.lessonPage, reason: 'the lesson stays until the audio ends');
    expect(at(0, 14), 1);
  });

  test('Jump while listening: a page starts the voice at its own time (scenario 2)', () async {
    final n = (await repo.all()).first.narrationIn('en')!;
    expect(n.startOf(4), const Duration(seconds: 40));
    expect(n.startOf(1), Duration.zero);
    expect(n.startOf(0), Duration.zero, reason: 'the cover');
  });

  test('SK4: the Guru\'s own words are marked and the rest is plain', () {
    expect(saakhiRuns('He said, <q>"Come."</q> and went.'), [
      (text: 'He said, ', quoted: false),
      (text: '"Come."', quoted: true),
      (text: ' and went.', quoted: false),
    ]);
    expect(saakhiRuns('No marks'), [(text: 'No marks', quoted: false)]);
    expect(saakhiPlain('a <q>b</q> c'), 'a b c');
  });

  test('SK12: a heart is kept on the phone, and can be taken off', () async {
    expect(await repo.watchFavourites().first, isEmpty);
    await repo.setFavourite('the-saint-soldier', true);
    await repo.setFavourite('the-saint-soldier', true);
    expect(await repo.watchFavourites().first, {'the-saint-soldier'});
    await repo.setFavourite('the-saint-soldier', false);
    expect(await repo.watchFavourites().first, isEmpty);
  });

  test('a language a saakhi does not have falls back to English (SK9)', () {
    const t = SaakhiText({'en': 'Hello', 'pa': 'ਸਤਿ'});
    expect(t.of('hi'), 'Hello');
    expect(t.of('pa'), 'ਸਤਿ');
    expect(t.has('hi'), isFalse);
  });
}
