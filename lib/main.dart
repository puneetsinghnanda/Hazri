import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/db/content_db.dart';
import 'core/db/content_repository.dart';
import 'core/db/user_db.dart';
import 'core/db/user_repository.dart';
import 'core/settings/settings_controller.dart';
import 'features/reminders/data/reminder_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge is enforced from Android 15 (PRD §4.1), so opt in everywhere
  // and let each screen handle its own insets.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final prefs = await SharedPreferences.getInstance();
  final contentDb = await ContentDb.open();
  final userDb = await UserDb.open();
  final reminders = ReminderService();
  await reminders.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        contentDbProvider.overrideWithValue(contentDb),
        userDbProvider.overrideWithValue(userDb),
        reminderServiceProvider.overrideWithValue(reminders),
      ],
      child: const HazriApp(),
    ),
  );
}
