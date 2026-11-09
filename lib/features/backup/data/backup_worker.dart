import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../../core/backend/api_client.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/backend/auth_service.dart';
import '../../../core/backend/firebase_backend.dart';
import '../../../core/db/user_db.dart';
import '../../../core/time/clock.dart';
import '../../profile/data/profile_cache.dart';
import 'backup_scheduler.dart';
import 'backup_service.dart';
import 'backup_store.dart';

/// The background entry point WorkManager runs (§8.1), in its own isolate
/// with the app closed. Never throws: a failed run returns false and
/// WorkManager retries with backoff (ST1).
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, _) async {
    if (task != WorkmanagerBackupScheduler.taskName) return true;
    WidgetsFlutterBinding.ensureInitialized();
    final backend = FirebaseBackend();
    await backend.start();
    if (!backend.isUp) return false;
    final prefs = await SharedPreferences.getInstance();
    final auth = FirebaseAuthService();
    // BK4: only with a profile this install owns.
    if (ProfileCache(prefs).read(currentUid: auth.uid) == null) return true;
    final api = ApiClient(auth: auth);
    final db = await UserDb.open();
    try {
      final service = BackupService(
        api: api,
        store: BackupStore(db),
        prefs: prefs,
        clock: const SystemClock(),
      );
      final outcome = await service.backup();
      final scheduler = WorkmanagerBackupScheduler();
      switch (outcome) {
        case BackupNoProfile():
          // R2: only GET /profile's own NO_PROFILE clears the profile; any
          // other answer leaves it, and WorkManager tries again later.
          if (!await profileGone(api)) return false;
          // ST2: the profile moved to another phone; stop.
          await ProfileCache(prefs).clear();
          await prefs.remove(BackupService.kNextDue);
          return true;
        case BackupSaved():
          final next = BackupService.nextSlot(DateTime.now());
          await service.setNextDue(next);
          await scheduler.schedule(next);
          return true;
        case BackupLater(:final retryAfter):
          await scheduler.schedule(DateTime.now().add(retryAfter));
          return true;
        default:
          return false;
      }
    } on Object catch (e) {
      debugPrint('Hazri: background backup failed ($e)');
      return false;
    } finally {
      await db.close();
    }
  });
}

/// R2: whether GET /profile itself says this install has no profile. Any
/// other answer, an error included, is not proof that it has gone.
Future<bool> profileGone(ApiClient api) async {
  try {
    await api.get('/profile');
    return false;
  } on ApiException catch (e) {
    return e.statusCode == 404 && e.code == 'NO_PROFILE';
  } on Object {
    return false;
  }
}
