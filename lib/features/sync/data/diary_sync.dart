import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/sync_status.dart';

/// Copying the diary to the account, and bringing it back (design 49).
///
/// Off by default and off is a complete answer. Nothing in Hazri needs this:
/// the diary, the streak and every mark in the grid are on the phone and work
/// with the radio off. What sync buys is the diary surviving a change of
/// phone, and the screen says exactly that rather than implying the data is
/// safer elsewhere than here.
abstract interface class DiarySync {
  /// Sends anything the server does not have. Safe to call often; it works
  /// out what is missing rather than resending the lot.
  Future<SyncStatus> push();

  /// Brings the server's days down and merges them into the local diary,
  /// which is what makes a restored account feel restored.
  ///
  /// A merge, never a replace: a day marked on either side stays marked. The
  /// diary is a record of what somebody did, and no copy of it is more
  /// authoritative than another.
  Future<int> pull();

  Stream<SyncStatus> watch();
}

/// Sync with nowhere to sync to.
class NoDiarySync implements DiarySync {
  const NoDiarySync();

  @override
  Future<SyncStatus> push() async => const SyncOff();

  @override
  Future<int> pull() async => 0;

  @override
  Stream<SyncStatus> watch() => Stream.value(const SyncOff());
}

final diarySyncProvider = Provider<DiarySync>((ref) => const NoDiarySync());

final syncStatusProvider = StreamProvider<SyncStatus>(
  (ref) => ref.watch(diarySyncProvider).watch(),
);
