import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/api_client.dart';
import '../domain/profile.dart';

/// One method per profile endpoint (ARCHITECTURE §6.1, `01-accounts.md` §6,
/// §13.8). Errors are the [ApiClient]'s: `ApiException` or
/// `NetworkException`.
class ProfileApi {
  ProfileApi(this._api);

  final ApiClient _api;

  Future<Profile> get() async => _profile(await _api.get('/profile'));

  Future<Profile> create({
    required String name,
    required String email,
    String? phone,
    required String cityId,
  }) async =>
      _profile(await _api.post('/profile', {
        'name': name,
        'email': email,
        'phone': ?phone,
        'cityId': cityId,
      }));

  /// §13.8: name and/or city.
  Future<Profile> update({String? name, String? cityId}) async =>
      _profile(await _api.patch('/profile', {'name': ?name, 'cityId': ?cityId}));

  /// §6.3. Returns the cooldown in seconds.
  Future<int> sendVerification() async =>
      _cooldown(await _api.post('/profile/verification-email'));

  /// §6.4. Returns the cooldown in seconds.
  Future<int> requestRestore(String email) async =>
      _cooldown(await _api.post('/profile/restore-request', {'email': email}));

  /// §6.6 / §13.8: `EMAIL_CHANGED` or `EMAIL_CHANGE_PENDING`.
  Future<({String result, Profile profile, int cooldownSeconds})> changeEmail(String email) async {
    final j = await _api.patch('/profile/email', {'email': email});
    return (result: j['result']! as String, profile: _profile(j), cooldownSeconds: _cooldown(j));
  }

  /// §6.5: the outcome of a tapped link.
  Future<TokenResult> verifyToken(String token) async {
    final j = await _api.post('/tokens/verify', {'token': token});
    final p = j['profile'];
    return TokenResult(
      result: j['result']! as String,
      purpose: j['purpose'] as String?,
      isOwner: j['isOwner'] == true,
      profile: p is Map<String, Object?> ? Profile.fromJson(p) : null,
    );
  }

  static Profile _profile(Map<String, Object?> j) =>
      Profile.fromJson(j['profile']! as Map<String, Object?>);

  static int _cooldown(Map<String, Object?> j) => (j['cooldownSeconds'] as num?)?.toInt() ?? 60;
}

/// `POST /tokens/verify`'s 200 body.
class TokenResult {
  const TokenResult({required this.result, this.purpose, this.isOwner = false, this.profile});

  /// `EMAIL_VERIFIED`, `EMAIL_ALREADY_VERIFIED`, `EMAIL_CHANGED` or
  /// `PROFILE_RESTORED`.
  final String result;
  final String? purpose;
  final bool isOwner;
  final Profile? profile;
}

final profileApiProvider = Provider<ProfileApi>((ref) => ProfileApi(ref.watch(apiClientProvider)));
