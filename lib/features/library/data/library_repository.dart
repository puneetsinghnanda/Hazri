import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/library_entry.dart';

/// Where the library's entries come from.
///
/// **This is the one part of Hazri that needs a connection**, and the screen
/// says so out loud. Every bani, its recitation, the calendar, the diary and
/// the daily Vichar work with the radio off; looking up a Gurdwara does not,
/// because the answer is corrected on the website and every phone should see
/// the correction rather than a copy frozen at install time.
abstract interface class LibraryRepository {
  Future<List<LibraryEntry>> entries();
  Future<LibraryEntry?> entry(String id);
}

/// No server: an empty library, and a screen that says why.
class NoLibraryRepository implements LibraryRepository {
  const NoLibraryRepository();

  @override
  Future<List<LibraryEntry>> entries() async => const [];

  @override
  Future<LibraryEntry?> entry(String id) async => null;
}

final libraryRepositoryProvider =
    Provider<LibraryRepository>((ref) => const NoLibraryRepository());

final libraryEntriesProvider = FutureProvider<List<LibraryEntry>>(
  (ref) => ref.watch(libraryRepositoryProvider).entries(),
);

/// One entry, read from the list, so a fresh list fetched behind the saved
/// one (`onUpdated`) redraws an article that is already open. It once asked
/// the repository on its own and kept the first answer for the session, so
/// an article opened before the fresh list arrived stayed old until restart.
final libraryEntryProvider = FutureProvider.family<LibraryEntry?, String>(
  (ref, id) async =>
      (await ref.watch(libraryEntriesProvider.future)).where((e) => e.id == id).firstOrNull,
);

/// What somebody has typed into the search box (design 46).
final librarySearchProvider = StateProvider<String>((ref) => '');

/// Which chip is selected. There is always one: Sikh days, which lists
/// everything, until another is tapped.
final libraryKindProvider = StateProvider<EntryKind>((ref) => EntryKind.day);

/// Today as YYYY-MM-DD, for putting the coming days first. A provider so a
/// test can fix the date.
final libraryTodayProvider = Provider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
});

/// The entries that survive the search box and the chip: the days still to
/// come first, soonest first, then the days already past in calendar order,
/// then anything without a date by title.
final libraryResultsProvider = Provider<List<LibraryEntry>>((ref) {
  final all = ref.watch(libraryEntriesProvider).value ?? const <LibraryEntry>[];
  final query = ref.watch(librarySearchProvider);
  final kind = ref.watch(libraryKindProvider);
  final today = ref.watch(libraryTodayProvider);
  String key(LibraryEntry e) {
    final next = e.nextDate(today);
    if (next != null) return '0$next';
    if (e.dates.isNotEmpty) return '1${e.dates.first}';
    return '2';
  }

  return [
    for (final e in all)
      if (e.listedUnder(kind) && e.matches(query)) e,
  ]..sort((a, b) {
      final c = key(a).compareTo(key(b));
      return c != 0 ? c : a.title.compareTo(b.title);
    });
});
