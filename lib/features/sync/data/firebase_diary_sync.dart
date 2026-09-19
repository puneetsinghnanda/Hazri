import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../domain/sync_status.dart';
import 'diary_sync.dart';

/// Diary sync on Firestore, under `users/{uid}/diary/{day}`.
///
/// The rules put that path behind `isSelf(uid)` and nothing else: not another
/// member, not a group admin, not anybody. It is the most private data in the
/// app and it is the only collection with no sharing rule at all.
class FirebaseDiarySync implements DiarySync {
  FirebaseDiarySync({
    required this.repo,
    required this.enabled,
    required this.wifiOnly,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    Connectivity? connectivity,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _connectivity = connectivity ?? Connectivity();

  final UserRepository repo;

  /// Read fresh on every call rather than captured: somebody turning sync off
  /// means it stops now, not after the next restart.
  final bool Function() enabled;
  final bool Function() wifiOnly;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final Connectivity _connectivity;

  final _status = StreamController<SyncStatus>.broadcast();

  @override
  Stream<SyncStatus> watch() async* {
    yield _last;
    yield* _status.stream;
  }

  SyncStatus _last = const SyncOff();

  void _emit(SyncStatus status) {
    _last = status;
    if (!_status.isClosed) _status.add(status);
  }

  CollectionReference<Map<String, Object?>>? get _diary {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('diary');
  }

  /// Whether anything may go up right now.
  ///
  /// Three answers rather than two, because "not now" has two quite different
  /// causes and only one of them is the person's to fix.
  Future<SyncStatus?> _blocked() async {
    if (!enabled() || _diary == null) return const SyncOff();
    final result = await _connectivity.checkConnectivity();
    if (result.isEmpty || result.every((r) => r == ConnectivityResult.none)) {
      return const SyncWaiting();
    }
    if (wifiOnly() &&
        !result.contains(ConnectivityResult.wifi) &&
        !result.contains(ConnectivityResult.ethernet)) {
      return const SyncWaiting(forWifi: true);
    }
    return null;
  }

  @override
  Future<SyncStatus> push() async {
    final blocked = await _blocked();
    if (blocked != null) {
      _emit(blocked);
      return blocked;
    }
    final diary = _diary!;

    try {
      final local = await _localDays();
      final remote = await diary.get();
      final have = {
        for (final doc in remote.docs)
          doc.id: DiaryDaySync.fromFirestore(doc.id, doc.data()),
      };

      // Only what differs. Re-sending an unchanged year every time somebody
      // opens the app is how a free tier stops being free.
      final missing = [
        for (final day in local)
          if (have[day.localDate] != day) day,
      ];
      if (missing.isEmpty) {
        final done = Synced(DateTime.now());
        _emit(done);
        return done;
      }

      _emit(Sending(missing.length));
      // Batched: 500 writes a batch is Firestore's limit, and a year of
      // diary is well under one.
      for (var i = 0; i < missing.length; i += 400) {
        final batch = _db.batch();
        for (final day in missing.skip(i).take(400)) {
          batch.set(diary.doc(day.localDate), day.toFirestore());
        }
        await batch.commit();
      }
      final done = Synced(DateTime.now());
      _emit(done);
      return done;
    } on FirebaseException catch (e) {
      debugPrint('Hazri: diary push failed (${e.code})');
      const waiting = SyncWaiting();
      _emit(waiting);
      return waiting;
    }
  }

  @override
  Future<int> pull() async {
    final diary = _diary;
    if (diary == null || !enabled()) return 0;
    try {
      final remote = await diary.get();
      var restored = 0;
      for (final doc in remote.docs) {
        final day = DiaryDaySync.fromFirestore(doc.id, doc.data());
        final date = DateTime.tryParse(day.localDate);
        if (date == null) continue;
        // A merge, never a replace: logCompletion already refuses a duplicate,
        // so a day marked on both sides stays marked once.
        for (final baniId in day.baniIds) {
          await repo.logCompletion(
            baniId: baniId,
            slot: _slot(day.slots, baniId),
            source: CompletionSource.restored,
            on: date,
          );
        }
        if (day.simran) {
          await repo.logSimran(
            duration: const Duration(minutes: 5),
            count: 0,
            completed: true,
            on: date,
          );
        }
        restored++;
      }
      return restored;
    } on FirebaseException catch (e) {
      debugPrint('Hazri: diary pull failed (${e.code})');
      return 0;
    }
  }

  /// The slot a restored bani belongs to. The server keeps the day's slots
  /// as a set, so a day with one bani is unambiguous and a day with several
  /// falls back to the first — the grid shows the day either way.
  BaniSlotValue _slot(List<String> slots, String baniId) {
    for (final name in slots) {
      final match = BaniSlotValue.values.where((v) => v.name == name).firstOrNull;
      if (match != null) return match;
    }
    return BaniSlotValue.none;
  }

  Future<List<DiaryDaySync>> _localDays() async {
    final completions = await repo.watchCompletions().first;
    final sessions = await repo.watchSimranSessions().first;

    final byDay = <String, ({Set<String> banis, Set<String> slots, bool simran})>{};
    for (final c in completions) {
      final day = byDay.putIfAbsent(
          c.localDate, () => (banis: <String>{}, slots: <String>{}, simran: false));
      day.banis.add(c.baniId);
      day.slots.add(c.slot.name);
    }
    for (final s in sessions) {
      if (!s.completed) continue;
      byDay.update(
        s.localDate,
        (d) => (banis: d.banis, slots: d.slots, simran: true),
        ifAbsent: () => (banis: <String>{}, slots: <String>{}, simran: true),
      );
    }

    return [
      for (final entry in byDay.entries)
        DiaryDaySync(
          localDate: entry.key,
          baniIds: entry.value.banis.toList()..sort(),
          slots: entry.value.slots.toList()..sort(),
          simran: entry.value.simran,
        ),
    ];
  }
}
