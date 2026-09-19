import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'group_repository.dart';

/// The two kinds of ref this can be called with.
///
/// The reader has a `WidgetRef` and the playback controller a `Ref`; they
/// share `read` and nothing else that matters here, so the function takes the
/// reading of a provider rather than the ref itself.
typedef ReadProvider = T Function<T>(ProviderListenable<T> provider);

/// Adds a finished paath to every group whose shared goal is that bani.
///
/// Called where `creditGoalsFor` is called, and for the same reason: a paath
/// somebody actually read should not need logging by hand a second time.
/// Manual logging stays, because a paath read from a gutka is still a paath
/// and the app cannot see it.
///
/// A simran circle is not credited here. Its unit is minutes and a bani is
/// not minutes, so crediting one for the other would be an invented number.
Future<void> creditGroupsFor(ReadProvider read, String baniId) async {
  final groups = read(myGroupsProvider).value ?? const [];
  final repo = read(groupRepositoryProvider);
  for (final group in groups) {
    if (group.countsMinutes) continue;
    if (group.goal?.slug != baniId) continue;
    await repo.logPaath(group.id, 1);
  }
}
