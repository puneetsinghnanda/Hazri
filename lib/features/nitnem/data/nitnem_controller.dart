import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../domain/bani.dart';

/// The Nitnem list, grouped into its sections.
typedef NitnemSections = Map<BaniSlot, List<Bani>>;

/// The banis by their `default_slot` (06-nitnem §6.2). Slot overrides went
/// with the per-slot reminders (02-notifications N-2).
final nitnemSectionsProvider = Provider<NitnemSections>((ref) {
  final banis = ref.watch(banisProvider).value ?? const <Bani>[];
  final sections = <BaniSlot, List<Bani>>{
    BaniSlot.morning: [],
    BaniSlot.evening: [],
    BaniSlot.bedtime: [],
    BaniSlot.none: [],
  };
  for (final b in banis) {
    sections[b.defaultSlot]!.add(b);
  }
  return sections;
});

/// The resume point for every bani, keyed by version id.
final progressByVersionProvider = StreamProvider<Map<String, ReadingProgressData>>((ref) {
  return ref.watch(userRepositoryProvider).watchAllProgress().map(
        (rows) => {for (final r in rows) r.baniVersionId: r},
      );
});
