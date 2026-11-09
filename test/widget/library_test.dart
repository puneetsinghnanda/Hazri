import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/widgets/surfaces.dart';
import 'package:hazri/features/library/data/library_repository.dart';
import 'package:hazri/features/library/domain/library_entry.dart';
import 'package:hazri/features/library/ui/library_screen.dart';

import '../app_harness.dart';

class _FakeLibrary implements LibraryRepository {
  _FakeLibrary(this.all);
  final List<LibraryEntry> all;

  @override
  Future<List<LibraryEntry>> entries() async => all;

  @override
  Future<LibraryEntry?> entry(String id) async =>
      all.where((e) => e.id == id).firstOrNull;
}

const _entries = [
  LibraryEntry(
    id: 'bangla',
    kind: EntryKind.gurdwara,
    title: 'Gurdwara Bangla Sahib, Delhi',
    place: 'New Delhi, India',
    minutes: 4,
  ),
  LibraryEntry(
    id: 'rehras',
    kind: EntryKind.bani,
    title: 'Why Rehras Sahib is read at sunset',
    summary: 'The evening bani, and the hour it belongs to.',
    minutes: 6,
  ),
  // A story page from the website: tagged with two topics, and a day in the
  // calendar.
  LibraryEntry(
    id: 'harmandir-sahib-foundation-stone',
    kind: EntryKind.gurdwara,
    tags: {EntryKind.gurdwara, EntryKind.guru},
    title: 'Foundation stone of Sri Harmandir Sahib',
    dates: ['2027-01-14'],
  ),
  LibraryEntry(
    id: 'bandi-chhor-divas',
    kind: EntryKind.guru,
    tags: {EntryKind.guru, EntryKind.day},
    title: 'Bandi Chhor Divas',
    dates: ['2026-11-08'],
  ),
];

/// Designs 122 and 46. Nothing in the library is written in the app, so these
/// tests are about the shell: what it shows, what it filters, and what it
/// says when there is nothing.
void main() {
  Future<L> pump(
    WidgetTester tester, {
    List<LibraryEntry> entries = _entries,
    Locale locale = const Locale('en'),
  }) async {
    final app = await TestApp.create(
      prefs: {'onboarding_done': true},
      extra: [
        libraryRepositoryProvider.overrideWithValue(_FakeLibrary(entries)),
        libraryTodayProvider.overrideWithValue('2026-10-19'),
      ],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const LibraryScreen(), locale: locale));
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('entries are listed with their kind above them', (tester) async {
    final l = await pump(tester);
    expect(find.text('Gurdwara Bangla Sahib, Delhi'), findsOneWidget);
    expect(find.text(l.libraryKindGurdwara.toUpperCase()), findsWidgets);
  });

  testWidgets('an empty library says why, not "nothing matches"',
      (tester) async {
    final l = await pump(tester, entries: const []);
    expect(find.text(l.libraryEmpty), findsOneWidget);
    expect(find.text(l.libraryNothingMatches), findsNothing);
  });

  testWidgets('searching narrows the list and counts what is left',
      (tester) async {
    final l = await pump(tester);
    await tester.enterText(find.byType(TextField), 'bangla');
    await settle(tester);

    expect(find.text('Gurdwara Bangla Sahib, Delhi'), findsOneWidget);
    expect(find.text('Why Rehras Sahib is read at sunset'), findsNothing);
    expect(find.text(l.libraryResults(1, 'bangla')), findsOneWidget);
  });

  testWidgets('a search that finds nothing says so, with entries present',
      (tester) async {
    final l = await pump(tester);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await settle(tester);
    expect(find.text(l.libraryNothingMatches), findsOneWidget);
    expect(find.text(l.libraryEmpty), findsNothing);
  });

  Finder chip(EntryKind k) => find.byKey(ValueKey('vichar-tile-${k.name}'));

  testWidgets('four tiles in one row, Sikh days first, and no All or Articles',
      (tester) async {
    final l = await pump(tester);
    const kinds = [EntryKind.day, EntryKind.gurdwara, EntryKind.guru, EntryKind.bani];
    final xs = kinds.map((k) => tester.getTopLeft(chip(k)).dx).toList();
    expect(xs, orderedEquals([...xs]..sort()));
    // One row, all on screen at once (design 122), not a scrolling strip.
    final ys = kinds.map((k) => tester.getTopLeft(chip(k)).dy).toSet();
    expect(ys, hasLength(1));
    expect(tester.getTopRight(chip(EntryKind.bani)).dx, lessThanOrEqualTo(390));
    for (final (k, t) in [
      (EntryKind.day, l.libraryKindDay),
      (EntryKind.gurdwara, l.libraryKindGurdwara),
      (EntryKind.guru, l.libraryKindGuru),
      (EntryKind.bani, l.libraryKindBani),
    ]) {
      expect(find.descendant(of: chip(k), matching: find.text(t)), findsOneWidget);
    }
    expect(find.text('All'), findsNothing);
    expect(chip(EntryKind.article), findsNothing);
  });

  testWidgets('each card carries its kind and the date it is about, '
      'the minutes, and a picture', (tester) async {
    final l = await pump(tester);
    // Bandi Chhor Divas is a guru entry about 8 November.
    expect(find.text('${l.libraryKindGuru} · 8 Nov'.toUpperCase()), findsOneWidget);
    // Bangla Sahib has no date: the kind alone.
    expect(find.text(l.libraryKindGurdwara.toUpperCase()), findsOneWidget);
    expect(find.text(l.libraryMinutes(4)), findsOneWidget);
    final card = find.ancestor(
      of: find.text('Gurdwara Bangla Sahib, Delhi'),
      matching: find.byType(HazriCard),
    );
    expect(find.descendant(of: card, matching: find.byType(Image)), findsOneWidget);
  });

  testWidgets('Sikh days is selected at first and lists every entry, '
      'the days to come first', (tester) async {
    await pump(tester);
    for (final t in ['Bandi Chhor Divas', 'Foundation stone of Sri Harmandir Sahib',
        'Gurdwara Bangla Sahib, Delhi', 'Why Rehras Sahib is read at sunset']) {
      expect(find.text(t), findsOneWidget);
    }
    double y(String t) => tester.getTopLeft(find.text(t)).dy;
    // 8 November comes before 14 January; undated entries follow.
    expect(y('Bandi Chhor Divas'), lessThan(y('Foundation stone of Sri Harmandir Sahib')));
    expect(y('Foundation stone of Sri Harmandir Sahib'),
        lessThan(y('Gurdwara Bangla Sahib, Delhi')));
  });

  testWidgets('a chip lists the entries tagged with it, '
      'whatever their own kind', (tester) async {
    await pump(tester);
    await tester.tap(chip(EntryKind.gurdwara));
    await settle(tester);
    expect(find.text('Gurdwara Bangla Sahib, Delhi'), findsOneWidget);
    expect(find.text('Foundation stone of Sri Harmandir Sahib'), findsOneWidget);
    expect(find.text('Bandi Chhor Divas'), findsNothing);
    expect(find.text('Why Rehras Sahib is read at sunset'), findsNothing);

    await tester.ensureVisible(chip(EntryKind.guru));
    await settle(tester);
    await tester.tap(chip(EntryKind.guru));
    await settle(tester);
    expect(find.text('Bandi Chhor Divas'), findsOneWidget);
    expect(find.text('Foundation stone of Sri Harmandir Sahib'), findsOneWidget);
    expect(find.text('Gurdwara Bangla Sahib, Delhi'), findsNothing);

    // Tapping the chip that is already selected keeps it selected.
    await tester.tap(chip(EntryKind.guru));
    await settle(tester);
    expect(find.text('Gurdwara Bangla Sahib, Delhi'), findsNothing);

    await tester.ensureVisible(chip(EntryKind.day));
    await settle(tester);
    await tester.tap(chip(EntryKind.day));
    await settle(tester);
    expect(find.text('Gurdwara Bangla Sahib, Delhi'), findsOneWidget);
  });

  testWidgets('the screen says out loud that this part needs a connection',
      (tester) async {
    final l = await pump(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await settle(tester);
    expect(find.text(l.libraryNeedsConnection), findsOneWidget);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      await pump(tester, locale: locale);
      expect(tester.takeException(), isNull);
    });
  }
}
