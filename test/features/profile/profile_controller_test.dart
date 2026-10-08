import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/features/profile/data/profile_cache.dart';
import 'package:hazri/features/profile/data/profile_controller.dart';
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
}
