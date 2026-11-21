import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/backend/auth_service.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/features/profile/data/profile_cache.dart';
import 'package:hazri/features/profile/data/profile_controller.dart';
import 'package:hazri/features/profile/data/profile_recovery.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_fakes.dart';

/// The owner's report of 2026-11-21: "No profile found" after making one.
/// 01-accounts §8.3 R5 (one sign-in at a time), R6 (a profile this phone had
/// is offered back), R7 (a restore link waiting is said so).
void main() {
  group('R5: one sign-in at a time', () {
    test('callers arriving together share one sign-in, not one each', () async {
      final once = SignInOnce();
      var calls = 0;
      final gate = Completer<void>();
      Future<void> signIn() async {
        calls++;
        await gate.future;
      }

      final all = Future.wait([once.run(signIn), once.run(signIn), once.run(signIn)]);
      gate.complete();
      await all;
      expect(calls, 1, reason: 'each extra call would be another anonymous account');
    });

    test('a failed sign-in (offline) can be tried again', () async {
      final once = SignInOnce();
      var calls = 0;
      await expectLater(once.run(() async {
        calls++;
        throw StateError('offline');
      }), throwsStateError);
      await once.run(() async => calls++);
      expect(calls, 2);
    });
  });

  group('R6, R7: never only "No profile found"', () {
    late FakeServer server;
    setUp(() => server = FakeServer());

    Future<ProviderContainer> start(Map<String, Object> prefs, {String uid = 'uid-1'}) async {
      SharedPreferences.setMockInitialValues(prefs);
      final sp = await SharedPreferences.getInstance();
      final c = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        ...server.overrides(uid: uid),
      ]);
      addTearDown(c.dispose);
      c.read(profileControllerProvider);
      for (var i = 0; i < 30; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return c;
    }

    String cached(String owner) => jsonEncode({...profileJson(name: 'Puneet Singh', email: 'owner@example.com'), 'ownerUid': owner});

    test('the phone signed in as somebody new: the old profile is offered back by its email', () async {
      server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
      final c = await start({ProfileCache.key: cached('old-uid')}, uid: 'new-uid');
      expect(c.read(profileControllerProvider), isA<ProfileNone>());
      final r = c.read(profileRecoveryProvider);
      expect(r.email, 'owner@example.com');
      expect(r.lostName, 'Puneet Singh');
    });

    test('the server stops giving this phone its profile: offered back too', () async {
      server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
      final c = await start({ProfileCache.key: cached('uid-1')});
      expect(c.read(profileRecoveryProvider).email, 'owner@example.com');
    });

    test('a restore link sent is remembered as waiting, and a profile clears it all', () async {
      server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
      server.on('POST', '/profile/restore-request', 200, {'result': 'RESTORE_EMAIL_SENT', 'cooldownSeconds': 60});
      final c = await start({});
      expect(c.read(profileRecoveryProvider).email, isNull, reason: 'nothing to recover on a phone that never had one');

      await c.read(profileControllerProvider.notifier).requestRestore('owner@example.com');
      final r = c.read(profileRecoveryProvider);
      expect(r.waiting(DateTime.now()), isTrue);
      expect(r.waiting(DateTime.now().add(const Duration(hours: 2))), isFalse, reason: 'the link lives an hour');

      server.on('GET', '/profile', 200, {'profile': profileJson()});
      await c.read(profileControllerProvider.notifier).refresh();
      expect(c.read(profileRecoveryProvider).email, isNull);
    });
  });
}
