import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/backend/backend.dart';
import 'core/backend/firebase_backend.dart';
import 'core/db/content_db.dart';
import 'core/db/content_repository.dart';
import 'core/db/user_db.dart';
import 'core/db/user_repository.dart';
import 'core/settings/settings_controller.dart';
import 'features/audio/data/audio_controller.dart';
import 'features/audio/data/audio_handler.dart';
import 'features/reminders/data/reminder_service.dart';
import 'core/backend/api_client.dart';
import 'core/backend/auth_service.dart';
import 'features/library/data/api_library_repository.dart';
import 'features/library/data/library_repository.dart';
import 'features/backup/data/backup_scheduler.dart';
import 'features/backup/data/backup_worker.dart';
import 'features/sangat/data/sangat_device.dart';
import 'package:workmanager/workmanager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge is enforced from Android 15 (PRD §4.1), so opt in everywhere
  // and let each screen handle its own insets.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // The sangat is optional and start-up says so: this never throws, and if
  // it fails the app is Phase 1's app (CLAUDE.md rule 4).
  final backend = FirebaseBackend();
  await backend.start();

  // The weekly backup's background entry point (10-backup §8.1).
  var backupScheduler = const NoBackupScheduler() as BackupScheduler;
  if (backend.isUp) {
    try {
      await Workmanager().initialize(backupCallbackDispatcher);
      backupScheduler = WorkmanagerBackupScheduler();
    } on Exception catch (e) {
      debugPrint('Hazri: WorkManager unavailable, no weekly backup ($e)');
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final contentDb = await ContentDb.open();
  final userDb = await UserDb.open();
  final reminders = ReminderService();
  await reminders.init();

  // The media session is the one piece of startup that can fail on an unusual
  // device. If it does, the app still opens as a text-only reader rather than
  // refusing to start.
  HazriAudioHandler? audio;
  try {
    audio = await HazriAudioHandler.create();
  } on Exception catch (e) {
    debugPrint('Hazri: media session unavailable, audio disabled ($e)');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        contentDbProvider.overrideWithValue(contentDb),
        userDbProvider.overrideWithValue(userDb),
        reminderServiceProvider.overrideWithValue(reminders),
        audioHandlerProvider.overrideWithValue(audio),
        backendProvider.overrideWithValue(backend),
        backupSchedulerProvider.overrideWithValue(backupScheduler),
        if (backend.isUp) pushTokensProvider.overrideWithValue(FirebasePushTokens()),
        // With Firebase up, the install signs in anonymously and every server
        // call goes through the `api` Function (ARCHITECTURE §6). Without it,
        // the offline defaults stand and the app is the app on the phone.
        if (backend.isUp)
          authServiceProvider.overrideWithValue(FirebaseAuthService()),
        if (backend.isUp)
          libraryRepositoryProvider.overrideWith(
            (ref) => ApiLibraryRepository(
              ref.watch(apiClientProvider),
              // A fresh list fetched behind the saved one is shown as soon
              // as it arrives.
              onUpdated: () => ref.invalidate(libraryEntriesProvider),
            ),
          ),
      ],
      child: const HazriApp(),
    ),
  );
}
