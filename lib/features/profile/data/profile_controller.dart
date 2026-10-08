import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/api_exception.dart';
import '../../../core/backend/auth_service.dart';
import '../../../core/settings/settings_controller.dart';
import '../domain/profile.dart';
import 'profile_api.dart';
import 'profile_cache.dart';

/// `01-accounts.md` §8.3.
sealed class ProfileState {
  const ProfileState();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileNone extends ProfileState {
  const ProfileNone();
}

/// [isStale]: shown from the cache, not (yet) confirmed by the server.
class ProfileLoaded extends ProfileState {
  const ProfileLoaded(this.profile, {required this.isStale});

  final Profile profile;
  final bool isStale;
}

/// No cache and the server could not be reached.
class ProfileUnavailable extends ProfileState {
  const ProfileUnavailable();
}

final profileCacheProvider =
    Provider<ProfileCache>((ref) => ProfileCache(ref.watch(sharedPreferencesProvider)));

/// The only source of profile state; every screen reads it, and only the
/// flows of §8.5–§8.11 change it.
class ProfileController extends Notifier<ProfileState> {
  bool _refreshing = false;

  /// Whether [refresh] is running, for the Profile screen's progress bar.
  bool get refreshing => _refreshing;

  AuthService get _auth => ref.read(authServiceProvider);
  ProfileCache get _cache => ref.read(profileCacheProvider);
  ProfileApi get _api => ref.read(profileApiProvider);

  @override
  ProfileState build() {
    scheduleMicrotask(_bootstrap);
    return const ProfileLoading();
  }

  Future<void> _bootstrap() async {
    // 1. Sign in; with no network and nobody signed in there is nothing to
    // read the cache against.
    try {
      await _auth.ensureSignedIn();
    } on NetworkException {
      if (_auth.uid == null) {
        state = const ProfileUnavailable();
        return;
      }
    }
    // 2. The cache shows the name at once.
    final cached = _cache.read(currentUid: _auth.uid);
    if (cached != null) state = ProfileLoaded(cached, isStale: true);
    // 3. The server.
    await refresh();
  }

  /// GET /profile with the rules of §8.3 step 3.
  Future<void> refresh() async {
    _refreshing = true;
    // Notify listeners that a refresh started without changing the state.
    ref.notifyListeners();
    try {
      final p = await _api.get();
      await setProfile(p);
    } on ApiException catch (e) {
      if (e.statusCode == 404 && e.code == 'NO_PROFILE') {
        await markNone();
      } else {
        _keepOrUnavailable();
      }
    } on NetworkException {
      _keepOrUnavailable();
    } on Object catch (e) {
      debugPrint('Hazri: profile refresh failed ($e)');
      _keepOrUnavailable();
    } finally {
      _refreshing = false;
      ref.notifyListeners();
    }
  }

  void _keepOrUnavailable() {
    final s = state;
    state = s is ProfileLoaded ? ProfileLoaded(s.profile, isStale: true) : const ProfileUnavailable();
  }

  Future<void> setProfile(Profile p) async {
    await _cache.write(p, ownerUid: _auth.uid);
    state = ProfileLoaded(p, isStale: false);
  }

  Future<void> markNone() async {
    await _cache.clear();
    state = const ProfileNone();
  }
}

final profileControllerProvider =
    NotifierProvider<ProfileController, ProfileState>(ProfileController.new);

/// The profile when there is one, from the server or the cache.
final profileProvider = Provider<Profile?>((ref) {
  final s = ref.watch(profileControllerProvider);
  return s is ProfileLoaded ? s.profile : null;
});
