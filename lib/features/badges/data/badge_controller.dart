import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backend/api_client.dart';
import '../../../core/db/content_db.dart' show BaniSlot;
import '../../../core/db/content_repository.dart';
import '../../../core/db/user_db.dart';
import '../../../core/db/user_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../../../core/time/clock.dart';
import '../../profile/data/profile_controller.dart';
import '../domain/badges.dart';
import 'badge_store.dart';

final badgeStoreProvider = Provider<BadgeStore>((ref) => BadgeStore(ref.watch(userDbProvider)));

/// The earned rows, live.
final earnedBadgesProvider = StreamProvider<List<BadgeRow>>((ref) => ref.watch(badgeStoreProvider).watchAll());

/// Hazri days, for `badgesSummary`.
final hazriDayCountProvider = FutureProvider<int>((ref) async {
  ref.watch(earnedBadgesProvider);
  return (await ref.read(badgeControllerProvider).counts()).hazriDays;
});

/// The badge whose sheet is due (AN1); set by [BadgeController.evaluate]
/// and cleared by the sheet.
final pendingBadgeProvider = StateProvider<BadgeId?>((ref) => null);

/// 12-badges §4.2 and §5.3.
class BadgeController {
  BadgeController(this._ref);

  final Ref _ref;
  static const kFacts = 'badge_sangat_facts_v1';
  static const kFactsDay = 'badge_sangat_facts_day_v1';

  Timer? _soon;
  bool _running = false;

  BadgeStore get _store => _ref.read(badgeStoreProvider);

  Future<BadgeCounts> counts() async {
    final banis = await _ref.read(contentRepositoryProvider).banis();
    final prefs = _ref.read(sharedPreferencesProvider);
    final facts = prefs.getStringList(kFacts);
    return _store.counts(
      morningBanis: {for (final b in banis) if (b.defaultSlot == BaniSlot.morning) b.id},
      allBanis: {for (final b in banis) b.id},
      goalsReached: int.tryParse(facts?.firstOrNull ?? '') ?? 0,
      joins: int.tryParse(facts?.lastOrNull ?? '') ?? 0,
    );
  }

  /// EV2: coalesced, off the UI's way.
  void evaluateSoon() {
    _soon?.cancel();
    _soon = Timer(const Duration(milliseconds: 600), () => unawaited(evaluate()));
  }

  /// EV1. [silent]: found after a restore, so not announced (BB4).
  Future<void> evaluate({bool silent = false}) async {
    if (_running) return evaluateSoon();
    _running = true;
    try {
      final held = {for (final r in await _store.all()) BadgeId.byId(r.badgeId)}.whereType<BadgeId>().toSet();
      final met = badgesMet(await counts(), earned: held);
      final today = localDateKey(_ref.read(clockProvider).today());
      await _store.insertNew(met, today: today, silent: silent);
      // AN2, LS2: the highest waiting is announced, the rest marked.
      final next = await _store.takeAnnouncement();
      if (next != null) _ref.read(pendingBadgeProvider.notifier).state = next;
    } on Object catch (e) {
      debugPrint('Hazri: badges not evaluated ($e)');
    } finally {
      _running = false;
    }
  }

  /// SF4: the Sangat facts, with a profile, while Sevadar or Satsangi is
  /// still to earn; at app start once a day ([daily]) and when the Sangat
  /// tab opens. SF5: cached; a failure changes nothing.
  Future<void> refreshFacts({bool daily = false}) async {
    if (_ref.read(profileControllerProvider) is! ProfileLoaded) return;
    final held = {for (final r in await _store.all()) r.badgeId};
    if (held.contains(BadgeId.sevadar.id) && held.contains(BadgeId.satsangi.id)) return;
    final prefs = _ref.read(sharedPreferencesProvider);
    final today = localDateKey(_ref.read(clockProvider).today());
    if (daily && prefs.getString(kFactsDay) == today) return;
    try {
      final j = await _ref.read(apiClientProvider).get('/badges/sangat');
      await prefs.setStringList(kFacts, ['${j['goalsReached'] ?? 0}', '${j['joins'] ?? 0}']);
      await prefs.setString(kFactsDay, today);
      await evaluate();
    } on Object catch (e) {
      debugPrint('Hazri: badge facts not fetched ($e)');
    }
  }
}

final badgeControllerProvider = Provider<BadgeController>((ref) {
  final c = BadgeController(ref);
  ref.read(userRepositoryProvider).addChangeListener(c.evaluateSoon);
  return c;
});
