import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../reminders/data/reminders_controller.dart';
import '../../reminders/domain/reminder_plan.dart';
import '../domain/bani.dart';

/// The Nitnem list, grouped into its sections.
typedef NitnemSections = Map<BaniSlot, List<Bani>>;

/// Where each bani sits once slot overrides are applied.
///
/// Moving Rehras to Morning in the reminder sheet moves its row into Amrit
/// Vela here, and the day arc follows (PRD 1.4 AC).
final nitnemSectionsProvider = Provider<NitnemSections>((ref) {
  final banis = ref.watch(banisProvider).value ?? const <Bani>[];
  final reminders = ref.watch(remindersProvider).value ?? const <Reminder>[];

  final overrideFor = <BaniSlot, BaniSlot>{};
  for (final r in reminders) {
    final target = switch (r.id) {
      ReminderIds.amritVela => BaniSlot.morning,
      ReminderIds.evening => BaniSlot.evening,
      ReminderIds.bedtime => BaniSlot.bedtime,
      _ => null,
    };
    final override = r.slotOverride;
    if (target == null || override == null) continue;
    final resolved = BaniSlot.values.where((s) => s.name == override).firstOrNull;
    if (resolved != null) overrideFor[target] = resolved;
  }

  final sections = <BaniSlot, List<Bani>>{
    BaniSlot.morning: [],
    BaniSlot.evening: [],
    BaniSlot.bedtime: [],
    BaniSlot.none: [],
  };
  for (final b in banis) {
    final slot = overrideFor[b.defaultSlot] ?? b.defaultSlot;
    sections[slot]!.add(b);
  }
  return sections;
});

/// The resume point for every bani, keyed by version id.
final progressByVersionProvider = StreamProvider<Map<String, ReadingProgressData>>((ref) {
  return ref.watch(userRepositoryProvider).watchAllProgress().map(
        (rows) => {for (final r in rows) r.baniVersionId: r},
      );
});
