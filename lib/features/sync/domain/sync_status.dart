import 'package:flutter/foundation.dart';

/// The three states on design 49, and there are only three on purpose.
///
/// A sync indicator with five states is a sync indicator nobody reads. These
/// answer the only question somebody has: is my paath safe, and if not, why
/// not — and the answer to the first is always yes, because it is on the
/// phone either way.
sealed class SyncStatus {
  const SyncStatus();
}

/// Everything the server should have, it has.
class Synced extends SyncStatus {
  const Synced(this.at);
  final DateTime at;
}

/// Nothing is going up right now: no signal, or mobile data with Wi-Fi-only
/// switched on. Not an error, and the screen says "carry on".
class SyncWaiting extends SyncStatus {
  const SyncWaiting({this.forWifi = false});

  /// Waiting for Wi-Fi rather than for any connection at all. Worth telling
  /// apart: one is the phone's situation and the other is a setting the
  /// person can change.
  final bool forWifi;
}

/// Days still to go up.
class Sending extends SyncStatus {
  const Sending(this.days);
  final int days;
}

/// Sync is off, or there is no account. The commonest state of all.
class SyncOff extends SyncStatus {
  const SyncOff();
}

/// One day of the diary, in the shape the server keeps it.
///
/// Deliberately a summary rather than rows: what came back on a new phone
/// should be the marks in the grid, and a copy of the local tables would be
/// a second schema to migrate for no gain.
@immutable
class DiaryDaySync {
  const DiaryDaySync({
    required this.localDate,
    required this.baniIds,
    required this.slots,
    required this.simran,
  });

  final String localDate;
  final List<String> baniIds;
  final List<String> slots;
  final bool simran;

  Map<String, Object?> toFirestore() => {
        'baniIds': baniIds,
        'slots': slots,
        'simran': simran,
      };

  static DiaryDaySync fromFirestore(String day, Map<String, Object?> data) =>
      DiaryDaySync(
        localDate: day,
        baniIds: [
          for (final v in (data['baniIds'] as List<Object?>? ?? const []))
            if (v is String) v,
        ],
        slots: [
          for (final v in (data['slots'] as List<Object?>? ?? const []))
            if (v is String) v,
        ],
        simran: (data['simran'] as bool?) ?? false,
      );

  @override
  bool operator ==(Object other) =>
      other is DiaryDaySync &&
      other.localDate == localDate &&
      other.simran == simran &&
      listEquals(other.baniIds, baniIds) &&
      listEquals(other.slots, slots);

  @override
  int get hashCode => Object.hash(localDate, simran, Object.hashAll(baniIds), Object.hashAll(slots));
}
