import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../core/l10n/gen/app_localizations.dart';
import '../../../core/settings/settings_controller.dart';
import '../../audio/data/notification_access.dart';
import '../../profile/data/profile_controller.dart';
import '../../reminders/data/reminder_service.dart';
import '../../reminders/data/reminders_controller.dart';
import '../../reminders/domain/reminder_plan.dart';
import '../domain/sangat_models.dart';
import 'sangat_api.dart';
import 'sangat_controller.dart';

/// The device's push token (02-notifications FT1, FT2), behind an interface
/// so a test needs no Firebase.
abstract interface class PushTokens {
  Future<String?> token();
  Stream<String> get onRefresh;

  /// Pushes that arrive while the app is open: (title, body, route).
  Stream<(String, String, String?)> get onForeground;

  /// The route of a push tapped while the app was in the background.
  Stream<String> get onOpened;

  /// The route of the push whose tap launched the app, once.
  Future<String?> initialRoute();
}

class NoPushTokens implements PushTokens {
  const NoPushTokens();
  @override
  Future<String?> token() async => null;
  @override
  Stream<String> get onRefresh => const Stream.empty();
  @override
  Stream<(String, String, String?)> get onForeground => const Stream.empty();
  @override
  Stream<String> get onOpened => const Stream.empty();
  @override
  Future<String?> initialRoute() async => null;
}

class FirebasePushTokens implements PushTokens {
  @override
  Future<String?> token() async {
    try {
      return await FirebaseMessaging.instance.getToken();
    } on Object catch (e) {
      debugPrint('Hazri: no push token ($e)');
      return null;
    }
  }

  @override
  Stream<String> get onRefresh => FirebaseMessaging.instance.onTokenRefresh;

  @override
  Stream<(String, String, String?)> get onForeground => FirebaseMessaging.onMessage
      .where((m) => m.notification != null)
      .map((m) => (m.notification!.title ?? '', m.notification!.body ?? '', m.data['route'] as String?));

  @override
  Stream<String> get onOpened => FirebaseMessaging.onMessageOpenedApp
      .map((m) => m.data['route'] as String?)
      .where((r) => r != null)
      .cast<String>();

  @override
  Future<String?> initialRoute() async {
    try {
      return (await FirebaseMessaging.instance.getInitialMessage())?.data['route'] as String?;
    } on Object {
      return null;
    }
  }
}

/// Overridden in `main()` with [FirebasePushTokens].
final pushTokensProvider = Provider<PushTokens>((ref) => const NoPushTokens());

/// Keeps the server's copy of the push token in step: saved with a profile
/// and a group, deleted when the last group is left (FT1–FT3). Also shows a
/// push that arrives with the app open.
class SangatDevice {
  SangatDevice(this._ref);

  final Ref _ref;
  StreamSubscription<String>? _refresh;
  StreamSubscription<(String, String, String?)>? _foreground;
  StreamSubscription<String>? _opened;
  bool? _saved;

  void start() {
    final push = _ref.read(pushTokensProvider);
    // A tapped Sangat push opens its group, through the same handler a
    // tapped reminder uses (the router's, or held until the router exists).
    void open(String route) {
      final reminders = _ref.read(reminderServiceProvider);
      final go = reminders.onTap;
      if (go == null) {
        reminders.pendingPayload = route;
      } else {
        go(route);
      }
    }

    _opened ??= push.onOpened.listen(open);
    unawaited(push.initialRoute().then((r) {
      if (r != null) open(r);
    }));
    _refresh ??= push.onRefresh.listen((_) => unawaited(sync(force: true)));
    _foreground ??= push.onForeground.listen((m) async {
      final l = await L.delegate.load(_ref.read(settingsProvider).locale);
      await _ref.read(reminderServiceProvider).showPush(
            title: m.$1,
            body: m.$2,
            route: m.$3,
            channelName: ReminderScheduler.channelNames(l)[NotificationKind.sangat] ?? 'Sangat',
          );
    });
  }

  Future<void> sync({bool force = false}) async {
    final want = _ref.read(profileControllerProvider) is ProfileLoaded && _ref.read(sangatMemberProvider);
    if (!force && _saved == want) return;
    final api = _ref.read(sangatApiProvider);
    try {
      if (want) {
        final token = await _ref.read(pushTokensProvider).token();
        if (token == null) return;
        await api.saveFcmToken(
          token: token,
          locale: _ref.read(settingsProvider).locale.languageCode,
          tz: await FlutterTimezone.getLocalTimezone(),
        );
      } else if (_saved == true) {
        await api.deleteFcmToken();
      }
      _saved = want;
    } on Object catch (e) {
      debugPrint('Hazri: push token not synced ($e)');
    }
  }

  void dispose() {
    _opened?.cancel();
    _refresh?.cancel();
    _foreground?.cancel();
  }
}

final sangatDeviceProvider = Provider<SangatDevice>((ref) {
  final d = SangatDevice(ref)..start();
  ref.onDispose(d.dispose);
  // A profile made or lost, a first group joined or the last one left.
  ref.listen(profileControllerProvider, (_, _) => unawaited(d.sync()));
  ref.listen(sangatMemberProvider, (_, _) => unawaited(d.sync()));
  return d;
});

/// IV6: Play's install referrer, read once on first launch. A
/// `sangat_code` in it is kept until onboarding is done, then offered on the
/// Join screen. Never sent anywhere.
class InstallInvite {
  InstallInvite(this._ref);

  final Ref _ref;
  static const kRead = 'install_referrer_read_v1';
  static const kPending = 'sangat_pending_code_v1';

  Future<void> readOnce() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    if (prefs.getBool(kRead) ?? false) return;
    await prefs.setBool(kRead, true);
    final referrer = await _ref.read(systemSettingsProvider).installReferrer();
    final code = codeFromReferrer(referrer);
    if (code != null) await prefs.setString(kPending, code);
  }

  /// The code waiting for the Join screen, cleared as it is taken.
  Future<String?> take() async {
    final prefs = _ref.read(sharedPreferencesProvider);
    final code = prefs.getString(kPending);
    if (code != null) await prefs.remove(kPending);
    return code;
  }
}

/// `sangat_code=ABCD2345` out of a referrer string, or null.
String? codeFromReferrer(String? referrer) {
  if (referrer == null || referrer.isEmpty) return null;
  try {
    final q = Uri.splitQueryString(referrer);
    final raw = q['sangat_code'];
    return raw == null ? null : normalizeInviteCode(raw);
  } on Object {
    return null;
  }
}

final installInviteProvider = Provider<InstallInvite>(InstallInvite.new);
