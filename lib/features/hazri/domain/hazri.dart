import 'package:flutter/foundation.dart';

/// What marked the day's hazri.
///
/// One thing, not a list: hazri is the moment somebody first turned up, and
/// the rest of the day's paath is the day's paath. The diary keeps the full
/// account; this keeps the moment.
@immutable
class Hazri {
  const Hazri({this.markedAt, this.baniId, this.bySimran = false});

  /// Nothing yet today. The commonest state at nine in the morning, and it
  /// is not a failure — design 59 says "not marked yet", never "missed".
  static const none = Hazri();

  /// When somebody first turned up today, local time.
  final DateTime? markedAt;

  /// The bani that did it, if a bani did.
  final String? baniId;

  /// Whether a sitting of simran did it instead.
  final bool bySimran;

  bool get isMarked => markedAt != null;

  /// Hazri and goals are different things, and this is the line between them.
  ///
  /// **One** paath, or **one** sitting of simran, marks the day. A goal is
  /// met only when everything it asks for is done. Somebody who reads Japji
  /// and nothing else has marked their hazri and not met a three-bani goal,
  /// and the app says both of those plainly rather than letting the smaller
  /// achievement disappear into the larger one.
  static Hazri from({
    required Iterable<({DateTime at, String baniId})> completions,
    required Iterable<DateTime> completedSimran,
  }) {
    DateTime? earliest;
    String? baniId;
    var bySimran = false;

    for (final c in completions) {
      if (earliest == null || c.at.isBefore(earliest)) {
        earliest = c.at;
        baniId = c.baniId;
        bySimran = false;
      }
    }
    for (final at in completedSimran) {
      if (earliest == null || at.isBefore(earliest)) {
        earliest = at;
        baniId = null;
        bySimran = true;
      }
    }
    if (earliest == null) return none;
    return Hazri(markedAt: earliest, baniId: baniId, bySimran: bySimran);
  }

  @override
  bool operator ==(Object other) =>
      other is Hazri &&
      other.markedAt == markedAt &&
      other.baniId == baniId &&
      other.bySimran == bySimran;

  @override
  int get hashCode => Object.hash(markedAt, baniId, bySimran);
}
