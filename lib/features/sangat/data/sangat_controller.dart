import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/backend/api_client.dart';
import '../../../core/backend/api_exception.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../domain/sangat_models.dart';
import 'sangat_api.dart';

/// What a Sangat screen shows: the server's last answer, from the copy on
/// the phone first (08-sangat §5.2), and when it was saved.
@immutable
class SangatView<T> {
  const SangatView(this.value, {this.savedAt, this.offline = false});

  final T value;
  final DateTime? savedAt;

  /// The last refresh could not reach the server.
  final bool offline;
}

/// `sangat_cache_v1`: the last responses of 7.1, 7.2 and 7.3, as JSON.
class SangatCache {
  SangatCache(this._prefs);

  static const key = 'sangat_cache_v1';
  final SharedPreferences _prefs;

  Map<String, Object?> _all() {
    final raw = _prefs.getString(key);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, Object?>;
    } on Object {
      return {};
    }
  }

  (Map<String, Object?>, DateTime)? read(String slot) {
    final e = _all()[slot];
    if (e is! Map<String, Object?>) return null;
    final at = DateTime.tryParse('${e['savedAt']}');
    final body = e['body'];
    if (at == null || body is! Map<String, Object?>) return null;
    return (body, at);
  }

  Future<void> write(String slot, Map<String, Object?> body, DateTime at) {
    final all = _all()..[slot] = {'savedAt': at.toIso8601String(), 'body': body};
    return _prefs.setString(key, jsonEncode(all));
  }

  Future<void> remove(String slot) {
    final all = _all()..remove(slot);
    return _prefs.setString(key, jsonEncode(all));
  }

  Future<void> clear() => _prefs.remove(key);
}

final sangatCacheProvider = Provider<SangatCache>((ref) => SangatCache(ref.watch(sharedPreferencesProvider)));

/// My groups and the built-in groups (8.1), cache first.
@immutable
class SangatLists {
  const SangatLists({this.mine = const [], this.builtIn = const []});

  final List<SangatGroup> mine;
  final List<SangatGroup> builtIn;

  /// Belongs to at least one active group: the outbox and the Sangat
  /// notification switch depend on it (§5.1, 02-notifications §9).
  bool get isMember => mine.any((g) => g.isActive) || builtIn.any((g) => g.isMember);
}

class SangatListsController extends Notifier<SangatView<SangatLists>?> {
  static const kMember = 'sangat_member_v1';

  ApiClient get _api => ref.read(apiClientProvider);
  SangatCache get _cache => ref.read(sangatCacheProvider);

  @override
  SangatView<SangatLists>? build() {
    final mine = _cache.read('mine');
    final builtIn = _cache.read('builtIn');
    if (mine == null && builtIn == null) return null;
    return SangatView(
      SangatLists(
        mine: mine == null ? const [] : _groups(mine.$1),
        builtIn: builtIn == null ? const [] : _groups(builtIn.$1),
      ),
      savedAt: mine?.$2 ?? builtIn?.$2,
    );
  }

  static List<SangatGroup> _groups(Map<String, Object?> j) => [
        for (final g in (j['groups'] as List<Object?>? ?? const []).cast<Map<String, Object?>>())
          SangatGroup.fromJson(g),
      ];

  /// Asks the server; offline, the copy stays with its time.
  Future<void> refresh() async {
    try {
      final now = DateTime.now();
      final results = await Future.wait([_api.get('/sangat/groups/mine'), _api.get('/sangat/groups/built-in')]);
      await _cache.write('mine', results[0], now);
      await _cache.write('builtIn', results[1], now);
      final lists = SangatLists(mine: _groups(results[0]), builtIn: _groups(results[1]));
      state = SangatView(lists, savedAt: now);
      await setMember(lists.isMember);
    } on NetworkException {
      _offline();
    } on ApiException catch (e) {
      debugPrint('Hazri: sangat lists refused ($e)');
      _offline();
    }
  }

  void _offline() {
    final s = state;
    state = SangatView(s?.value ?? const SangatLists(), savedAt: s?.savedAt, offline: true);
  }

  /// Persists whether the person is in a group, and turns the outbox on or
  /// off to match.
  Future<void> setMember(bool member) async {
    await ref.read(sharedPreferencesProvider).setBool(kMember, member);
    ref.read(userRepositoryProvider).queueForSangat = member;
    ref.invalidate(sangatMemberProvider);
  }
}

final sangatListsProvider =
    NotifierProvider<SangatListsController, SangatView<SangatLists>?>(SangatListsController.new);

/// Whether this install belongs to an active group, from the last answer
/// saved on the phone (02-notifications §9, 08-sangat §5.1).
final sangatMemberProvider = Provider<bool>((ref) {
  final member = ref.watch(sharedPreferencesProvider).getBool(SangatListsController.kMember) ?? false;
  ref.read(userRepositoryProvider).queueForSangat = member;
  return member;
});

/// One group in full (7.3), cache first.
class SangatGroupController extends FamilyNotifier<SangatView<SangatGroup>?, String> {
  SangatCache get _cache => ref.read(sangatCacheProvider);

  @override
  SangatView<SangatGroup>? build(String groupId) {
    final c = _cache.read('group:$groupId');
    return c == null ? null : SangatView(SangatGroup.fromJson(c.$1['group']! as Map<String, Object?>), savedAt: c.$2);
  }

  /// Returns false when the group is gone (disabled, deleted or left).
  Future<bool> refresh() async {
    try {
      final now = DateTime.now();
      final j = await ref.read(apiClientProvider).get('/sangat/groups/$arg');
      await _cache.write('group:$arg', j, now);
      state = SangatView(SangatGroup.fromJson(j['group']! as Map<String, Object?>), savedAt: now);
      return true;
    } on ApiException catch (e) {
      if (e.code == 'GROUP_NOT_FOUND') {
        await _cache.remove('group:$arg');
        state = null;
        return false;
      }
      _offline();
      return true;
    } on NetworkException {
      _offline();
      return true;
    }
  }

  /// Replaces the copy with a group an action returned.
  Future<void> put(SangatGroup g, Map<String, Object?> json) async {
    final now = DateTime.now();
    await _cache.write('group:$arg', json, now);
    state = SangatView(g, savedAt: now);
  }

  void _offline() {
    final s = state;
    if (s != null) state = SangatView(s.value, savedAt: s.savedAt, offline: true);
  }
}

final sangatGroupProvider =
    NotifierProvider.family<SangatGroupController, SangatView<SangatGroup>?, String>(SangatGroupController.new);

/// Sends the outbox (§5.1): at start, on resume, when the network returns,
/// and right after a row is queued. Rows go in order, at most 200 a request,
/// and are deleted only once the server says it processed them.
class OutboxSender {
  OutboxSender(this._ref);

  final Ref _ref;
  bool _sending = false;
  Timer? _soon;

  void sendSoon() {
    _soon?.cancel();
    _soon = Timer(const Duration(seconds: 2), () => unawaited(send()));
  }

  /// Sends what is queued. A call while a send is running waits for that
  /// one, so "send, then refresh" never refreshes ahead of the rows.
  Future<void> send() => _inFlight ??= _send().whenComplete(() => _inFlight = null);

  Future<void>? _inFlight;

  Future<void> _send() async {
    if (_sending) return;
    _sending = true;
    final repo = _ref.read(userRepositoryProvider);
    final api = _ref.read(sangatApiProvider);
    try {
      while (true) {
        final rows = await repo.outbox();
        if (rows.isEmpty) return;
        final processed = await api.contribute(rows);
        final done = rows.where((r) => processed.contains(r.id)).toList();
        if (done.isEmpty) return;
        await repo.clearOutbox(done);
        if (rows.length < 200) return;
      }
    } on NetworkException {
      // K13: sent when the phone is back online.
    } on ApiException catch (e) {
      debugPrint('Hazri: outbox refused ($e)');
    } finally {
      _sending = false;
    }
  }
}

final outboxSenderProvider = Provider<OutboxSender>((ref) {
  final sender = OutboxSender(ref);
  ref.read(userRepositoryProvider).onOutbox = sender.sendSoon;
  return sender;
});
