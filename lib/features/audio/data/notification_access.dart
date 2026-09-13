import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform/system_settings.dart';
import '../../reminders/data/reminder_service.dart';

final systemSettingsProvider = Provider<SystemSettings>(
  (ref) => const AndroidSystemSettings(),
);

/// Whether Android will show any notification from Hazri.
///
/// This is what decides whether the lock screen gets transport controls: the
/// media session rides on the playback service's foreground notification, so a
/// denied POST_NOTIFICATIONS means audio plays with nothing in the shade and
/// nothing on the lock screen.
final notificationsAllowedProvider =
    AsyncNotifierProvider<NotificationAccess, bool>(NotificationAccess.new);

class NotificationAccess extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    // The answer changes outside the app — in system settings — so re-read it
    // whenever Hazri comes back to the foreground.
    final listener = AppLifecycleListener(onResume: recheck);
    ref.onDispose(listener.dispose);
    return ref.read(reminderServiceProvider).notificationsAllowed();
  }

  Future<void> recheck() async {
    final allowed = await ref.read(reminderServiceProvider).notificationsAllowed();
    if (state.value != allowed) state = AsyncData(allowed);
  }

  /// Asks for the permission without pushing the user anywhere.
  ///
  /// Android only shows the system dialog while it has no recorded answer; once
  /// the permission has been denied this returns false having shown nothing,
  /// which is cheap enough to call before every paath.
  Future<bool> request() async {
    final service = ref.read(reminderServiceProvider);
    if (await service.notificationsAllowed()) {
      state = const AsyncData(true);
      return true;
    }
    final granted = await service.requestNotificationPermission();
    state = AsyncData(granted);
    return granted;
  }

  /// What the banner and the settings row do: ask, and when Android has
  /// already recorded a denial, open the app's notification screen, which is
  /// then the only way back.
  Future<bool> allow() async {
    if (await request()) return true;
    await ref.read(systemSettingsProvider).openNotificationSettings();
    return false;
  }
}
