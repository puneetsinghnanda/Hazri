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
import 'features/audio/data/audio_controller.dart';
import 'features/audio/data/audio_handler.dart';
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
      ],
      child: const HazriApp(),
    ),
  );
}
