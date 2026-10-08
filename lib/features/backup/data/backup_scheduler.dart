import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

/// The weekly job (`10-backup.md` §8.1), behind an interface so a test needs
/// no platform and a second platform would need an adapter, not a rewrite.
abstract interface class BackupScheduler {
  /// One job, `weekly-backup`, due at [at], needing any network (B-4).
  Future<void> schedule(DateTime at);

  Future<void> cancel();
}

/// Does nothing: tests, and a run where WorkManager failed to start.
class NoBackupScheduler implements BackupScheduler {
  const NoBackupScheduler();

  @override
  Future<void> schedule(DateTime at) async {}

  @override
  Future<void> cancel() async {}
}

/// Android's WorkManager. A one-off job re-enqueued after each run for the
/// next Sunday, rather than a periodic one, because a periodic job drifts
/// from Sunday 00:00 and BK1 names the time.
class WorkmanagerBackupScheduler implements BackupScheduler {
  static const uniqueName = 'weekly-backup';
  static const taskName = 'weekly-backup';

  @override
  Future<void> schedule(DateTime at) async {
    final delay = at.difference(DateTime.now());
    try {
      await Workmanager().registerOneOffTask(
        uniqueName,
        taskName,
        initialDelay: delay.isNegative ? Duration.zero : delay,
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );
    } on Exception catch (e) {
      debugPrint('Hazri: could not schedule the weekly backup ($e)');
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await Workmanager().cancelByUniqueName(uniqueName);
    } on Exception catch (e) {
      debugPrint('Hazri: could not cancel the weekly backup ($e)');
    }
  }
}

/// Overridden in `main()` with [WorkmanagerBackupScheduler].
final backupSchedulerProvider = Provider<BackupScheduler>((ref) => const NoBackupScheduler());
