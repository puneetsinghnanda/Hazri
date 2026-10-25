import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/time/clock.dart';
import '../domain/saakhi.dart';

/// The saakhis on the phone (SK1) and the reader's hearts (SK12).
class SaakhiRepository {
  SaakhiRepository(this._content, this._user, this._clock);

  final ContentDb _content;
  final UserDb _user;
  final Clock _clock;

  /// Every saakhi in the order the pipeline gave them. A content database
  /// from before the saakhis has no table, and answers with none.
  Future<List<Saakhi>> all() async {
    try {
      final rows = await _content.customSelect('SELECT json FROM saakhi ORDER BY sort').get();
      return [
        for (final r in rows)
          if (Saakhi.fromJson(jsonDecode(r.read<String>('json')) as Map<String, Object?>) case final Saakhi s) s,
      ];
    } on Object catch (e) {
      debugPrint('Hazri: no saakhis in content.db ($e)');
      return const [];
    }
  }

  Stream<Set<String>> watchFavourites() =>
      _user.select(_user.saakhiFavourites).watch().map((rows) => {for (final r in rows) r.saakhiId});

  Future<void> setFavourite(String saakhiId, bool on) async {
    if (on) {
      await _user
          .into(_user.saakhiFavourites)
          .insertOnConflictUpdate(
            SaakhiFavouritesCompanion.insert(saakhiId: saakhiId, createdAt: _clock.now().toUtc()),
          );
    } else {
      await (_user.delete(_user.saakhiFavourites)..where((f) => f.saakhiId.equals(saakhiId))).go();
    }
  }
}

final saakhiRepositoryProvider = Provider<SaakhiRepository>(
  (ref) => SaakhiRepository(ref.watch(contentDbProvider), ref.watch(userDbProvider), ref.watch(clockProvider)),
);

final saakhisProvider = FutureProvider<List<Saakhi>>((ref) => ref.watch(saakhiRepositoryProvider).all());

final saakhiProvider = FutureProvider.family<Saakhi?, String>((ref, id) async {
  final all = await ref.watch(saakhisProvider.future);
  return all.where((s) => s.id == id).firstOrNull;
});

final saakhiFavouritesProvider = StreamProvider<Set<String>>(
  (ref) => ref.watch(saakhiRepositoryProvider).watchFavourites(),
);
