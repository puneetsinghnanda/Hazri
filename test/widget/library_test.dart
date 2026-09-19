import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
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
];

/// Designs 43 and 46. Nothing in the library is written in the app, so these
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
      extra: [libraryRepositoryProvider.overrideWithValue(_FakeLibrary(entries))],
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

  testWidgets('a chip filters by kind and untaps to show everything',
      (tester) async {
    final l = await pump(tester);
    // Six chips do not fit across a phone, so the row scrolls and the chip
    // has to be brought into view before it can be tapped.
    await tester.ensureVisible(find.text(l.libraryKindBani));
    await settle(tester);
    await tester.tap(find.text(l.libraryKindBani));
    await settle(tester);
    expect(find.text('Gurdwara Bangla Sahib, Delhi'), findsNothing);

    await tester.tap(find.text(l.libraryKindBani));
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
