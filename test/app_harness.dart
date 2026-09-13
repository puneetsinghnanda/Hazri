import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_db.dart';
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/reminders/data/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for the local-notifications plugin, which is not registered in a
/// widget test and throws if its platform instance is asked for.
class FakeReminderService extends ReminderService {
  final scheduled = <ScheduledNotification>[];

  bool notificationsGranted = true;
  bool exactAlarmsGranted = true;

  @override
  Future<void> init() async {}

  @override
  Future<bool> requestNotificationPermission() async => notificationsGranted;

  @override
  Future<bool> notificationsAllowed() async => notificationsGranted;

  @override
  Future<bool> canScheduleExact() async => exactAlarmsGranted;

  @override
  Future<void> requestExactAlarmPermission() async => exactAlarmsGranted = true;

  @override
  Future<void> replaceSchedule(List<ScheduledNotification> notifications) async {
    scheduled
      ..clear()
      ..addAll(notifications);
  }

  @override
  Future<void> cancelAll() async => scheduled.clear();

  @override
  Future<int> pendingCount() async => scheduled.length;
}

/// Everything a widget test needs to render a real screen: the shipped content
/// database, an empty user database, and stubs for the plugins that would
/// otherwise reach for a platform.
class TestApp {
  TestApp._(this.container, this.contentDb, this.userDb, this.reminders, this.overrides);

  final ProviderContainer container;
  final ContentDb contentDb;
  final UserDb userDb;
  final FakeReminderService reminders;

  /// The same overrides the container was built from, so a test can add one.
  final List<Override> overrides;

  static const _silencedChannels = {
    'dexterous.com/flutter/local_notifications': <String, Object?>{
      'requestNotificationsPermission': true,
      'areNotificationsEnabled': true,
      'canScheduleExactNotifications': true,
      'pendingNotificationRequests': <Object?>[],
      'getNotificationAppLaunchDetails': <String, Object?>{
        'notificationLaunchedApp': false,
      },
    },
    'dev.fluttercommunity.plus/wakelock_plus': <String, Object?>{
      'toggle': null,
      'isEnabled': false,
    },
    'dev.fluttercommunity.plus/share': <String, Object?>{},
  };

  /// Installs the stubs and builds a container with real databases.
  static Future<TestApp> create({
    Map<String, Object> prefs = const {},
    DateTime? now,
  }) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    for (final entry in _silencedChannels.entries) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        MethodChannel(entry.key),
        (call) async => entry.value[call.method],
      );
    }

    SharedPreferences.setMockInitialValues(prefs);
    final sharedPreferences = await SharedPreferences.getInstance();

    // Each test gets its own database instances; the warning drift prints when
    // it sees a second one is noise here.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

    final contentFile = File('assets/content/content.db');
    final contentDb = ContentDb(NativeDatabase(contentFile));
    final userDb = UserDb.memory();
    final reminders = FakeReminderService();

    final overrides = <Override>[
      sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      contentDbProvider.overrideWithValue(contentDb),
      userDbProvider.overrideWithValue(userDb),
      reminderServiceProvider.overrideWithValue(reminders),
      if (now != null) clockProvider.overrideWithValue(FixedClock(now)),
    ];
    final container = ProviderContainer(overrides: overrides);

    return TestApp._(container, contentDb, userDb, reminders, overrides);
  }

  /// Tears the container down and lets the databases go.
  ///
  /// The closes are deliberately not awaited: drift waits on its opening lock,
  /// and under `flutter_test`'s fake clock that lock never clears while a
  /// `watch()` subscription is still unwinding, so awaiting one hangs the
  /// test. Both databases are per-test -- the user one is in memory and the
  /// content one is opened read-only -- so letting the handles fall away with
  /// the test isolate costs nothing.
  void dispose() {
    container.dispose();
    unawaited(contentDb.close());
    unawaited(userDb.close());
  }

  /// Wraps [child] in the app's theme and localisations, without the router,
  /// so one screen can be pumped on its own.
  Widget wrap(Widget child, {Locale locale = const Locale('en'), bool dark = false}) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: dark ? HazriTheme.dark() : HazriTheme.light(),
        home: child,
      ),
    );
  }
}

/// Pumps a fixed number of frames.
///
/// `pumpAndSettle` is not used: the screens hold streams and repaints that
/// never quiesce, and a fixed number of frames is enough for the providers to
/// deliver their first values.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Sizes the test surface to the design frame: 390 x 844 dp (tokens.json ->
/// size.designFrame). Widget tests default to 800 x 600, which is wider than
/// any phone and hides real overflows.
void usePhoneFrame(WidgetTester tester) {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
