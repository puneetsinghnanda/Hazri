import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../domain/bani.dart';

/// The one completion path (06-nitnem B1): the reader, the player and nothing
/// else call this; the Diary's + goes through the repository directly with
/// `source` = `DIARY` (04-goals CR3).
///
/// It logs the completion and — through the repository's change hook —
/// re-plans reminders (CM2). The Sangat outbox (step 6) and badges (step 9)
/// hang off the same call.
///
/// **One opening, one completion** (04-goals CR2): reading to the end and the
/// recitation reaching the end in the same opening of a bani log one row
/// between them. An opening starts when the reader opens a bani and ends when
/// it closes; a recitation finishing with no reader open is its own opening.
class CompletionPath {
  CompletionPath(this._ref);

  final Ref _ref;
  final _open = <String, int>{};
  final _completedOpenings = <int>{};
  var _next = 0;

  /// The reader opened the bani with [slug]. Returns the opening's id.
  int opened(String slug) => _open[slug] = ++_next;

  /// The reader closed the bani with [slug].
  void closed(String slug, int opening) {
    if (_open[slug] == opening) _open.remove(slug);
  }

  /// Records one paath of [bani] by [source], unless this opening already
  /// recorded one. Returns the row, or null when it was a duplicate.
  Future<Completion?> completeBani(Bani bani, CompletionSource source) async {
    final opening = _open[bani.slug];
    if (opening != null) {
      if (_completedOpenings.contains(opening)) return null;
      _completedOpenings.add(opening);
    }
    return _ref.read(userRepositoryProvider).logCompletion(
          baniId: bani.id,
          slot: slotValue(bani.defaultSlot),
          source: source,
        );
  }

  static BaniSlotValue slotValue(BaniSlot slot) => switch (slot) {
        BaniSlot.morning => BaniSlotValue.morning,
        BaniSlot.evening => BaniSlotValue.evening,
        BaniSlot.bedtime => BaniSlotValue.bedtime,
        BaniSlot.none => BaniSlotValue.none,
      };
}

final completionPathProvider = Provider<CompletionPath>((ref) => CompletionPath(ref));
