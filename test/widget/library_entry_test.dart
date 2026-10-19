import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/library/data/library_repository.dart';
import 'package:hazri/features/library/domain/library_entry.dart';
import 'package:hazri/features/library/ui/library_entry_screen.dart';

import '../app_harness.dart';

class _FakeLibrary implements LibraryRepository {
  _FakeLibrary(this.all);
  List<LibraryEntry> all;

  @override
  Future<List<LibraryEntry>> entries() async => all;

  @override
  Future<LibraryEntry?> entry(String id) async => all.where((e) => e.id == id).firstOrNull;
}

const _body = 'The opening paragraph.\n\n## The first step\n\nWhat happened first.\n\n'
    '## The second step\n\nWhat happened next.';

const _entries = [
  LibraryEntry(
    id: 'ram-das',
    kind: EntryKind.guru,
    layout: EntryLayout.calendar,
    label: 'Prakash Purab',
    title: 'Prakash Purab of Sri Guru Ram Das Ji',
    summary: 'The fourth Guru.',
    body: _body,
    dates: ['2026-10-27'],
    facts: {'Kind': 'Prakash Purab'},
  ),
  LibraryEntry(
    id: 'beant',
    kind: EntryKind.day,
    title: 'Shaheedi of Bhai Beant Singh',
    label: 'Shaheedi',
    dates: ['2026-11-01'],
  ),
  LibraryEntry(
    id: 'bangla',
    kind: EntryKind.gurdwara,
    tags: {EntryKind.gurdwara, EntryKind.guru},
    layout: EntryLayout.photo,
    label: 'Joti Jot',
    title: 'Serving the sick in Delhi',
    imageCaption: 'Gurdwara Bangla Sahib, New Delhi',
    body: _body,
    dates: ['2026-11-03'],
  ),
  LibraryEntry(
    id: 'chamkaur',
    kind: EntryKind.day,
    layout: EntryLayout.timeline,
    label: 'Shaheedi',
    title: 'Saka Chamkaur Sahib',
    body: _body,
    dates: ['2026-12-23'],
  ),
];

/// docs/vichar-content.md "Layouts": the source names the layout and every
/// layout shows the same text.
void main() {
  Future<L> pump(WidgetTester tester, String id, {Locale locale = const Locale('en')}) async {
    final app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 10, 19, 9),
      extra: [libraryRepositoryProvider.overrideWithValue(_FakeLibrary(_entries))],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(LibraryEntryScreen(id: id), locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('A: a Gurpurab is a calendar card with its countdown and what comes next', (tester) async {
    final l = await pump(tester, 'ram-das');
    expect(find.text('27'), findsOneWidget);
    expect(find.text('PRAKASH PURAB · ${l.libraryInDays(8).toUpperCase()}'), findsOneWidget);
    expect(find.text('The first step'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Shaheedi of Bhai Beant Singh'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(find.text(l.libraryNextInCalendar.toUpperCase()), findsOneWidget);
  });

  testWidgets('B: a place is photo-led and names the place over its picture', (tester) async {
    final l = await pump(tester, 'bangla');
    expect(find.text('Gurdwara Bangla Sahib, New Delhi'), findsOneWidget);
    expect(find.text('JOTI JOT'), findsOneWidget);
    expect(find.text(l.libraryKindGurdwara.toUpperCase()), findsOneWidget);
    expect(find.text('Serving the sick in Delhi'), findsOneWidget);
  });

  testWidgets('C: a day of history is a timeline of its sections', (tester) async {
    final l = await pump(tester, 'chamkaur');
    expect(find.text('Saka Chamkaur Sahib'), findsOneWidget);
    expect(find.text(l.libraryInTheCalendar.toUpperCase()), findsOneWidget);
    expect(find.text(l.libraryHowItUnfolds.toUpperCase()), findsOneWidget);
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    expect(y('The opening paragraph.'), lessThan(y('The first step')));
    expect(y('The first step'), lessThan(y('What happened first.')));
    expect(y('What happened first.'), lessThan(y('The second step')));
  });

  testWidgets('an entry that names no layout keeps the plain reader', (tester) async {
    await pump(tester, 'beant');
    expect(find.text('Shaheedi of Bhai Beant Singh'), findsOneWidget);
  });

  testWidgets('an open article redraws when a fresh list arrives behind the saved one', (tester) async {
    // The saved copy from before the layouts: no layout, so the plain reader.
    const old = LibraryEntry(id: 'ram-das', kind: EntryKind.guru, title: 'Prakash Purab of Sri Guru Ram Das Ji');
    final library = _FakeLibrary([old]);
    final app = await TestApp.create(
      prefs: {'onboarding_done': true},
      now: DateTime(2026, 10, 19, 9),
      extra: [libraryRepositoryProvider.overrideWithValue(library)],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const LibraryEntryScreen(id: 'ram-das')));
    await settle(tester);
    expect(find.text('27'), findsNothing);

    // What main.dart's onUpdated does when the fresh list arrives.
    library.all = _entries;
    app.container.invalidate(libraryEntriesProvider);
    await settle(tester);
    expect(find.text('27'), findsOneWidget);
  });

  test('the layout is read from the entry, and an unknown one is plain', () {
    LibraryEntry parse(Object? layout) =>
        LibraryEntry.fromJson({'id': 'x', 'title': 'X', 'layout': layout, 'label': 'Shaheedi'})!;
    expect(parse('calendar').layout, EntryLayout.calendar);
    expect(parse('photo').layout, EntryLayout.photo);
    expect(parse('timeline').layout, EntryLayout.timeline);
    expect(parse('carousel').layout, EntryLayout.plain);
    expect(parse(null).label, 'Shaheedi');
  });

  for (final id in ['ram-das', 'bangla', 'chamkaur']) {
    for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
      testWidgets('$id lays out without overflowing in ${locale.languageCode}', (tester) async {
        await pump(tester, id, locale: locale);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
