import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/profile.dart';

/// `profile_cache_v1` (ARCHITECTURE §2.5): the Profile DTO plus the uid that
/// owned it, so the name shows at once and offline. A cache written under
/// another uid is not this install's and is dropped.
class ProfileCache {
  ProfileCache(this._prefs);

  static const key = 'profile_cache_v1';

  final SharedPreferences _prefs;

  Future<void> write(Profile p, {required String? ownerUid}) =>
      _prefs.setString(key, jsonEncode({...p.toJson(), 'ownerUid': ownerUid}));

  /// Null, and the key deleted, when missing, not valid JSON, or owned by
  /// another uid.
  Profile? read({required String? currentUid}) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, Object?>;
      if (j['ownerUid'] != currentUid) {
        _prefs.remove(key);
        return null;
      }
      return Profile.fromJson(j);
    } on Object {
      _prefs.remove(key);
      return null;
    }
  }

  Future<void> clear() => _prefs.remove(key);
}
