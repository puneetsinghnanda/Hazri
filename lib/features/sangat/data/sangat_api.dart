import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/api_client.dart';
import '../../../core/db/user_db.dart';
import '../domain/sangat_models.dart';

/// One method per Sangat endpoint (ARCHITECTURE §6.3).
class SangatApi {
  SangatApi(this._api);

  final ApiClient _api;
  static const _p = '/sangat';

  static List<SangatGroup> _groups(Map<String, Object?> j) => [
        for (final g in (j['groups'] as List<Object?>? ?? const []).cast<Map<String, Object?>>())
          SangatGroup.fromJson(g),
      ];

  static SangatGroup _group(Map<String, Object?> j) => SangatGroup.fromJson(j['group']! as Map<String, Object?>);

  /// 7.1.
  Future<List<SangatGroup>> mine() async => _groups(await _api.get('$_p/groups/mine'));

  /// 7.2.
  Future<List<SangatGroup>> builtIn() async => _groups(await _api.get('$_p/groups/built-in'));

  /// 7.3.
  Future<SangatGroup> group(String id) async => _group(await _api.get('$_p/groups/$id'));

  /// 7.4. Needs a profile.
  Future<SangatGroup> create(String name) async => _group(await _api.post('$_p/groups', {'name': name}));

  /// 7.5, once.
  Future<SangatGroup> setGoal(
    String id, {
    required String type,
    String? baniId,
    required int target,
    required String endDay,
  }) async =>
      _group(await _api.post('$_p/groups/$id/goal', {
        'type': type,
        'baniId': ?baniId,
        'target': target,
        'endDay': endDay,
      }));

  /// 7.6.
  Future<SangatGroup> changeEndDay(String id, String endDay) async =>
      _group(await _api.patch('$_p/groups/$id/goal', {'endDay': endDay}));

  /// 7.7.
  Future<void> delete(String id) => _api.delete('$_p/groups/$id');

  /// 7.8. Returns the group id joined (`JOINED` or `ALREADY_MEMBER`).
  Future<String> join(String code) async =>
      (await _api.post('$_p/join', {'code': code}))['groupId']! as String;

  /// 7.9.
  Future<void> joinBuiltIn(String id) => _api.post('$_p/groups/$id/join');
  Future<void> leave(String id) => _api.post('$_p/groups/$id/leave');

  /// 7.10.
  Future<void> removeMember(String id, String memberKey) =>
      _api.delete('$_p/groups/$id/members/${Uri.encodeComponent(memberKey)}');

  /// 7.11.
  Future<SangatInvite> invite(String id, {bool reset = false}) async =>
      SangatInvite.fromJson(await _api.post('$_p/groups/$id/invite', {if (reset) 'reset': true}));

  /// 7.12: returns the ids the server processed.
  Future<Set<String>> contribute(List<OutboxRow> rows) async {
    final r = await _api.post('$_p/contributions', {
      'items': [
        for (final o in rows)
          {
            'id': o.id,
            'kind': o.kind,
            'baniId': ?o.baniId,
            'durationS': ?o.durationS,
            'source': o.source,
            'at': o.at.toUtc().toIso8601String(),
            'action': o.retracted ? 'RETRACT' : 'ADD',
          },
      ],
    });
    return {for (final id in (r['processed'] as List<Object?>? ?? const [])) '$id'};
  }

  /// 7.13. [reason]: `OFFENSIVE`, `SPAM`, `OFF_TOPIC` or `OTHER`.
  Future<void> report(String id, String reason, {String? note}) =>
      _api.post('$_p/groups/$id/report', {'reason': reason, 'note': ?note});

  /// FT2: the push token, with a profile and a group.
  Future<void> saveFcmToken({required String token, required String locale, required String tz}) =>
      _api.post('/devices/fcm-token', {'token': token, 'locale': locale, 'tz': tz});

  Future<void> deleteFcmToken() => _api.delete('/devices/fcm-token');
}

final sangatApiProvider = Provider<SangatApi>((ref) => SangatApi(ref.watch(apiClientProvider)));
