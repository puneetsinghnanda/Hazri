import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/platform/system_settings.dart';
import 'package:hazri/features/audio/data/notification_access.dart';
import 'package:hazri/features/reminders/data/reminder_service.dart';

import '../app_harness.dart';

class FakeSystemSettings implements SystemSettings {
  int opened = 0;

  @override
  Future<bool> openNotificationSettings() async {
    opened++;
    return true;
  }

  @override
  Future<bool?> ignoringBatteryOptimizations() async => null;

  @override
  Future<String?> installReferrer() async => null;

  final List<String> urls = [];

  @override
  Future<bool> openUrl(String url) async {
    urls.add(url);
    return true;
  }
}

/// The lock-screen controls are the playback service's notification, so this is
/// the difference between a paath that can be paused from a locked phone and
/// one that cannot.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeReminderService service;
  late FakeSystemSettings settings;
  late ProviderContainer container;

  setUp(() {
    service = FakeReminderService();
    settings = FakeSystemSettings();
    container = ProviderContainer(overrides: [
      reminderServiceProvider.overrideWithValue(service),
      systemSettingsProvider.overrideWithValue(settings),
    ]);
  });

  tearDown(() => container.dispose());

  Future<bool> read() => container.read(notificationsAllowedProvider.future);
  NotificationAccess access() =>
      container.read(notificationsAllowedProvider.notifier);

  test('reports what Android says', () async {
    service.notificationsGranted = false;
    expect(await read(), isFalse);
  });

  test('asking is enough when the permission has never been answered', () async {
    service.notificationsGranted = false;
    expect(await read(), isFalse);

    service.notificationsGranted = true; // the dialog is accepted
    expect(await access().request(), isTrue);
    expect(container.read(notificationsAllowedProvider).value, isTrue);
    expect(settings.opened, 0, reason: 'no need to send anyone to Settings');
  });

  test('a recorded denial sends the user to the notification screen', () async {
    service.notificationsGranted = false;
    expect(await read(), isFalse);

    // Android shows nothing and returns false once it has an answer on file.
    expect(await access().allow(), isFalse);
    expect(settings.opened, 1);
  });

  test('an allowed permission never opens Settings or asks again', () async {
    expect(await read(), isTrue);
    expect(await access().allow(), isTrue);
    expect(settings.opened, 0);
  });

  test('recheck picks up a change made outside the app', () async {
    service.notificationsGranted = false;
    expect(await read(), isFalse);

    service.notificationsGranted = true;
    await access().recheck();
    expect(container.read(notificationsAllowedProvider).value, isTrue);
  });
}
