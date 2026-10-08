import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/settings/settings_controller.dart';
import '../domain/reminder_plan.dart';

/// One switch per kind (02-notifications CM7, §9). All on by default; the
/// Sangat's is shown only to members. Stored as `notif_on_<channel>`
/// (ARCHITECTURE §3.8).
class NotificationSwitches extends Notifier<Set<NotificationKind>> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  static String key(NotificationKind k) => 'notif_on_${k.channelId}';

  @override
  Set<NotificationKind> build() => {
        for (final k in NotificationKind.values)
          if (_prefs.getBool(key(k)) ?? true) k,
      };

  Future<void> set(NotificationKind kind, bool on) async {
    await _prefs.setBool(key(kind), on);
    state = on ? {...state, kind} : ({...state}..remove(kind));
  }
}

final notificationSwitchesProvider =
    NotifierProvider<NotificationSwitches, Set<NotificationKind>>(NotificationSwitches.new);
