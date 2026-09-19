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

final libraryEntryProvider = FutureProvider.family<LibraryEntry?, String>(
  (ref, id) => ref.watch(libraryRepositoryProvider).entry(id),
);

/// What somebody has typed into the search box (design 46).
final librarySearchProvider = StateProvider<String>((ref) => '');

/// Which chip is selected, or null for everything.
final libraryKindProvider = StateProvider<EntryKind?>((ref) => null);

/// The entries that survive the search box and the chip.
final libraryResultsProvider = Provider<List<LibraryEntry>>((ref) {
  final all = ref.watch(libraryEntriesProvider).value ?? const <LibraryEntry>[];
  final query = ref.watch(librarySearchProvider);
  final kind = ref.watch(libraryKindProvider);
  return [
    for (final e in all)
      if ((kind == null || e.kind == kind) && e.matches(query)) e,
  ];
});
