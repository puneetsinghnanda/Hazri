import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../config/app_config.dart';
import '../../../core/backend/api_client.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/clock.dart';
import '../domain/backup_json.dart';
import 'backup_store.dart';

/// The outcome of a backup or restore, for the Profile screen.
sealed class BackupOutcome {
  const BackupOutcome();
}

class BackupSaved extends BackupOutcome {
  const BackupSaved(this.at);
  final DateTime at;
}

class RestoreDone extends BackupOutcome {
  const RestoreDone(this.added);
  final int added;
}

/// R-7: there is no backup on the server.
class RestoreNothing extends BackupOutcome {
  const RestoreNothing();
}

/// BK4 / ST2: no profile, or this phone no longer owns it.
class BackupNoProfile extends BackupOutcome {
  const BackupNoProfile();
}

/// ST3: rate-limited; try again after [retryAfter].
class BackupLater extends BackupOutcome {
  const BackupLater(this.retryAfter);
  final Duration retryAfter;
}

class BackupFailed extends BackupOutcome {
  const BackupFailed(this.error);
  final Object error;
}

/// The weekly backup and the restore (`10-backup.md` §4), against the `api`
/// Function (ARCHITECTURE §6.4).
class BackupService {
  BackupService({
    required ApiClient api,
    required BackupStore store,
    required SharedPreferences prefs,
    required Clock clock,
    this.afterRestore,
  })  : _api = api,
        _store = store,
        _prefs = prefs,
        _clock = clock;

  final ApiClient _api;
  final BackupStore _store;
  final SharedPreferences _prefs;
  final Clock _clock;

  /// RS6: what runs after a restore (close a blank goal, re-plan reminders).
  final Future<void> Function()? afterRestore;

  static const kLastAt = 'backup_last_at_v1';
  static const kRunningSince = 'backup_running_since_v1';
  static const kNextDue = 'backup_next_due_v1';

  /// The watermark, which is also "last backed up" (§7).
  DateTime? get lastBackupAt => _read(kLastAt);

  DateTime? get nextDue => _read(kNextDue);

  DateTime? _read(String key) {
    final v = _prefs.getString(key);
    return v == null ? null : DateTime.tryParse(v);
  }

  /// ST1: no successful backup for over `BACKUP_STALE_DAYS`.
  bool get isStale {
    final last = lastBackupAt;
    return last != null &&
        _clock.now().difference(last.toLocal()) > const Duration(days: AppConfig.backupStaleDays);
  }

  /// BK1: the next Sunday 00:00 local after [from], plus 0–60 minutes.
  static DateTime nextSlot(DateTime from, {math.Random? random}) {
    final day = DateTime(from.year, from.month, from.day);
    final daysToSunday = (DateTime.sunday - day.weekday) % 7;
    var sunday = day.add(Duration(days: daysToSunday == 0 ? 7 : daysToSunday));
    if (!sunday.isAfter(from)) sunday = sunday.add(const Duration(days: 7));
    final jitter = (random ?? math.Random()).nextInt(AppConfig.backupJitterMinutes + 1);
    return sunday.add(Duration(minutes: jitter));
  }

  Future<void> setNextDue(DateTime at) => _prefs.setString(kNextDue, at.toIso8601String());

  /// BK2: the scheduled time has passed without a backup.
  bool get isDue {
    final due = nextDue;
    return due != null && !_clock.now().isBefore(due);
  }

  /// BK6, BK7: sends every changed row in chunks; the watermark moves to the
  /// time this run started only after the last chunk is confirmed.
  Future<BackupOutcome> backup() async {
    final startedAt = _clock.now().toUtc();
    await _prefs.setString(kRunningSince, startedAt.toIso8601String());
    try {
      final rows = await _store.changedSince(lastBackupAt);
      final chunks = _chunks(rows);
      DateTime? serverAt;
      for (var i = 0; i < chunks.length; i++) {
        final body = {...chunks[i], 'final': i == chunks.length - 1};
        final r = await _api.post('/backup', body);
        final at = r['lastBackupAt'];
        if (at is String) serverAt = DateTime.tryParse(at);
      }
      await _prefs.setString(kLastAt, startedAt.toIso8601String());
      return BackupSaved(serverAt ?? startedAt);
    } on ApiException catch (e) {
      return _failure(e);
    } on NetworkException catch (e) {
      return BackupFailed(e);
    } finally {
      await _prefs.remove(kRunningSince);
    }
  }

  /// Packs goal groups (a goal with its changed items), completions and
  /// sittings into requests of at most `BACKUP_MAX_ROWS_PER_REQUEST` rows. An
  /// empty backup is still one request, so `final` sets `lastBackupAt`.
  static List<Map<String, Object?>> chunksOf(ChangedRows rows, {int max = AppConfig.backupMaxRowsPerRequest}) {
    final out = <Map<String, Object?>>[];
    var goals = <Map<String, Object?>>[];
    var completions = <Map<String, Object?>>[];
    var sittings = <Map<String, Object?>>[];
    var n = 0;
    void flush() {
      out.add({'goals': goals, 'completions': completions, 'simranSessions': sittings, 'badges': const []});
      goals = [];
      completions = [];
      sittings = [];
      n = 0;
    }

    final itemsByGoal = <String, List<GoalItem>>{};
    for (final i in rows.items) {
      itemsByGoal.putIfAbsent(i.goalId, () => []).add(i);
    }
    for (final g in rows.goals) {
      final items = itemsByGoal[g.id] ?? const <GoalItem>[];
      final size = 1 + items.length;
      if (n > 0 && n + size > max) flush();
      goals.add({'goal': BackupJson.goal(g), 'items': [for (final i in items) BackupJson.item(i)]});
      n += size;
    }
    for (final c in rows.completions) {
      if (n + 1 > max) flush();
      completions.add(BackupJson.completion(c));
      n++;
    }
    for (final s in rows.sittings) {
      if (n + 1 > max) flush();
      sittings.add(BackupJson.sitting(s));
      n++;
    }
    if (n > 0 || out.isEmpty) flush();
    return out;
  }

  List<Map<String, Object?>> _chunks(ChangedRows rows) => chunksOf(rows);

  /// §4.3: goals, then the weeks oldest first in pages, each page merged in
  /// one transaction. The watermark is left as it was (RS6).
  Future<BackupOutcome> restore() async {
    try {
      final manifest = await _api.get('/backup/manifest');
      final weeks = (manifest['weeks'] as Map<String, Object?>?) ?? const {};
      final goalIds = (manifest['goalIds'] as List<Object?>?) ?? const [];
      if (manifest['lastBackupAt'] == null && weeks.isEmpty && goalIds.isEmpty) {
        return const RestoreNothing();
      }
      var added = 0;
      final g = await _api.get('/backup/goals');
      final goals = [
        for (final e in (g['goals'] as List<Object?>? ?? const []).cast<Map<String, Object?>>())
          (
            goal: BackupJson.goalFrom(e['goal']! as Map<String, Object?>),
            items: [
              for (final i in (e['items'] as List<Object?>? ?? const []).cast<Map<String, Object?>>())
                BackupJson.itemFrom(i),
            ],
          ),
      ];
      added += await _store.mergeGoals(goals);

      if (weeks.isNotEmpty) {
        String? from = (weeks.keys.toList()..sort()).first;
        while (from != null) {
          final page = await _api.get('/backup/weeks', query: {
            'from': from,
            'limit': '${AppConfig.restorePageWeeks}',
          });
          for (final w in (page['weeks'] as List<Object?>? ?? const []).cast<Map<String, Object?>>()) {
            added += await _store.mergeWeek(
              [
                for (final c in (w['completions'] as List<Object?>? ?? const []).cast<Map<String, Object?>>())
                  BackupJson.completionFrom(c),
              ],
              [
                for (final s in (w['simranSessions'] as List<Object?>? ?? const []).cast<Map<String, Object?>>())
                  BackupJson.sittingFrom(s),
              ],
            );
          }
          from = page['next'] as String?;
        }
      }
      await afterRestore?.call();
      return RestoreDone(added);
    } on ApiException catch (e) {
      return _failure(e);
    } on NetworkException catch (e) {
      return BackupFailed(e);
    } on Object catch (e) {
      debugPrint('Hazri: restore failed ($e)');
      return BackupFailed(e);
    }
  }

  BackupOutcome _failure(ApiException e) => switch (e.code) {
        'NO_PROFILE' => const BackupNoProfile(),
        'RATE_LIMITED' => BackupLater(Duration(seconds: e.retryAfterSeconds ?? 60)),
        _ => BackupFailed(e),
      };
}

final backupStoreProvider = Provider<BackupStore>((ref) => BackupStore(ref.watch(userDbProvider)));

final backupServiceProvider = Provider<BackupService>((ref) {
  final repo = ref.watch(userRepositoryProvider);
  return BackupService(
    api: ref.watch(apiClientProvider),
    store: ref.watch(backupStoreProvider),
    prefs: ref.watch(sharedPreferencesProvider),
    clock: ref.watch(clockProvider),
    afterRestore: () async {
      await repo.closeGoalIfBlank();
      repo.onChanged?.call();
    },
  );
});
