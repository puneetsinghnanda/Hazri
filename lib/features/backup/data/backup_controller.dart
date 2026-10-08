import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/data/profile_controller.dart';
import 'backup_scheduler.dart';
import 'backup_service.dart';

/// Keeps the weekly job in step with the profile (§8.1) and catches up on a
/// missed Sunday when the app opens (BK2).
class BackupController {
  BackupController(this._ref);

  final Ref _ref;
  bool _running = false;

  BackupService get _service => _ref.read(backupServiceProvider);
  BackupScheduler get _scheduler => _ref.read(backupSchedulerProvider);

  /// The profile reached ProfileLoaded, or the app came back to the front.
  Future<void> onProfileLoaded() async {
    final due = _service.nextDue;
    if (due == null) {
      final next = BackupService.nextSlot(DateTime.now());
      await _service.setNextDue(next);
      await _scheduler.schedule(next);
      return;
    }
    if (_service.isDue) await runNow();
  }

  /// No profile: cancel the job (§8.1, ST2).
  Future<void> onProfileGone() async {
    await _scheduler.cancel();
  }

  /// BK3 and BK2. Re-schedules the next Sunday on success.
  Future<BackupOutcome> runNow() async {
    if (_running) return const BackupLater(Duration(seconds: 5));
    _running = true;
    try {
      final outcome = await _service.backup();
      switch (outcome) {
        case BackupSaved():
          final next = BackupService.nextSlot(DateTime.now());
          await _service.setNextDue(next);
          await _scheduler.schedule(next);
        case BackupNoProfile():
          await _ref.read(profileControllerProvider.notifier).markNone();
          await onProfileGone();
        default:
          break;
      }
      _ref.invalidate(backupStatusProvider);
      return outcome;
    } finally {
      _running = false;
    }
  }

  Future<BackupOutcome> restore() async {
    final outcome = await _service.restore();
    if (outcome is BackupNoProfile) {
      await _ref.read(profileControllerProvider.notifier).markNone();
    }
    return outcome;
  }
}

final backupControllerProvider = Provider<BackupController>((ref) {
  final c = BackupController(ref);
  ref.listen(profileControllerProvider, (was, now) {
    if (now is ProfileLoaded && was is! ProfileLoaded) unawaited(c.onProfileLoaded());
    if (now is ProfileNone) unawaited(c.onProfileGone());
  }, fireImmediately: true);
  return c;
});

/// What the Profile screen shows about the backup (§8.2).
final backupStatusProvider = Provider<({DateTime? lastAt, bool stale})>((ref) {
  final s = ref.watch(backupServiceProvider);
  return (lastAt: s.lastBackupAt, stale: s.isStale);
});
