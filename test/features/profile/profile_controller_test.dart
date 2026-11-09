import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/features/profile/data/profile_cache.dart';
import 'package:hazri/features/profile/data/profile_controller.dart';
import 'package:hazri/features/profile/domain/profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_fakes.dart';

/// `01-accounts.md` §8.3 startup and refresh rules.
void main() {
  late FakeServer server;

  Future<ProviderContainer> start({Map<String, Object> prefs = const {}, String uid = 'uid-1'}) async {
    SharedPreferences.setMockInitialValues(prefs);
    final sp = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      ...server.overrides(uid: uid),
    ]);
    addTearDown(c.dispose);
    c.read(profileControllerProvider);
    // Let the bootstrap and the request run.
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return c;
  }

  String cached({String owner = 'uid-1', String name = 'Cached Name'}) =>
      jsonEncode({...profileJson(name: name), 'ownerUid': owner});

  setUp(() => server = FakeServer());

  Future<void> settle() async {
    for (var i = 0; i < 20; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  test('200: loaded, fresh, and cached for next time', () async {
    server.on('GET', '/profile', 200, {'profile': profileJson()});
    final c = await start();
    final s = c.read(profileControllerProvider);
    expect(s, isA<ProfileLoaded>());
    expect((s as ProfileLoaded).isStale, isFalse);
    final sp = await SharedPreferences.getInstance();
    expect(sp.getString(ProfileCache.key), contains('Harpreet Kaur'));
  });

  test('404 NO_PROFILE: none, and the cache is cleared', () async {
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    final c = await start(prefs: {ProfileCache.key: cached()});
    expect(c.read(profileControllerProvider), isA<ProfileNone>());
    final sp = await SharedPreferences.getInstance();
    expect(sp.getString(ProfileCache.key), isNull);
  });

  test('offline with a cache: the cached name, marked stale (T-c)', () async {
    server.offline = true;
    final c = await start(prefs: {ProfileCache.key: cached()});
    final s = c.read(profileControllerProvider) as ProfileLoaded;
    expect(s.profile.name, 'Cached Name');
    expect(s.isStale, isTrue);
  });

  test('offline with no cache: unavailable (T-d)', () async {
    server.offline = true;
    final c = await start();
    expect(c.read(profileControllerProvider), isA<ProfileUnavailable>());
  });

  test('a 500 keeps the cache rather than dropping it', () async {
    server.on('GET', '/profile', 500, errorJson('INTERNAL'));
    final c = await start(prefs: {ProfileCache.key: cached()});
    expect((c.read(profileControllerProvider) as ProfileLoaded).isStale, isTrue);
  });

  test('a cache written by another install is not shown', () async {
    server.offline = true;
    final c = await start(prefs: {ProfileCache.key: cached(owner: 'someone-else')});
    expect(c.read(profileControllerProvider), isA<ProfileUnavailable>());
  });

  // R1 (2026-11-05): the owner set up a profile, and the phone later said
  // "No profile found" until the Profile screen fetched it again. A GET sent
  // before the profile existed, answered after setup, had overwritten it.
  test('R1: a NO_PROFILE sent before setup and answered after it is dropped', () async {
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    final stale = server.hold('GET', '/profile');
    final c = await start();
    expect(c.read(profileControllerProvider), isA<ProfileLoading>(), reason: 'the start-up GET is still out');

    // Setup finishes while that GET is out.
    await c.read(profileControllerProvider.notifier).setProfile(Profile.fromJson(profileJson()));
    stale.complete();
    await settle();

    final s = c.read(profileControllerProvider);
    expect(s, isA<ProfileLoaded>());
    expect((s as ProfileLoaded).profile.name, 'Harpreet Kaur');
    final sp = await SharedPreferences.getInstance();
    expect(sp.getString(ProfileCache.key), contains('Harpreet Kaur'), reason: 'the cache survives too');
  });

  test('R1: of two refreshes, the newer answer wins whichever arrives last', () async {
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    final older = server.hold('GET', '/profile');
    final c = await start();
    server.on('GET', '/profile', 200, {'profile': profileJson()});
    await c.read(profileControllerProvider.notifier).refresh();
    expect(c.read(profileControllerProvider), isA<ProfileLoaded>());

    older.complete();
    await settle();
    expect(c.read(profileControllerProvider), isA<ProfileLoaded>());
    expect(c.read(profileControllerProvider.notifier).refreshing, isFalse);
  });

  test('R2: another endpoint\'s NO_PROFILE is checked, and a profile GET /profile finds stays', () async {
    server.on('GET', '/profile', 200, {'profile': profileJson()});
    final c = await start();
    final gone = await c.read(profileControllerProvider.notifier).confirmGone();
    expect(gone, isFalse);
    expect(c.read(profileControllerProvider), isA<ProfileLoaded>());
  });

  test('R2: when GET /profile agrees, the profile is gone', () async {
    server.on('GET', '/profile', 200, {'profile': profileJson()});
    final c = await start();
    server.on('GET', '/profile', 404, errorJson('NO_PROFILE'));
    final gone = await c.read(profileControllerProvider.notifier).confirmGone();
    expect(gone, isTrue);
    expect(c.read(profileControllerProvider), isA<ProfileNone>());
  });

  test('R3: reading the cache with no uid yet keeps it', () async {
    SharedPreferences.setMockInitialValues({ProfileCache.key: cached()});
    final sp = await SharedPreferences.getInstance();
    expect(ProfileCache(sp).read(currentUid: null), isNull);
    expect(sp.getString(ProfileCache.key), isNotNull, reason: 'a background isolate before sign-in must not delete it');
    expect(ProfileCache(sp).read(currentUid: 'uid-1')?.name, 'Cached Name');
  });
}
