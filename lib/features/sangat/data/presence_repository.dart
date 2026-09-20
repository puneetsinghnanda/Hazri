import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/content_db.dart';
import '../../../core/db/content_repository.dart';
import '../../../core/settings/settings_controller.dart';
import '../domain/simran_presence.dart';
import 'account_repository.dart';

/// Who is sitting in simran today, and where.
///
/// Reading this needs an account; adding to it needs one too. Somebody who
/// never joined the sangat sees the globe quiet and their own simran is
/// counted nowhere but their own diary, which is CLAUDE.md rule 4 kept at the
/// data layer rather than argued about in the UI.
abstract interface class PresenceRepository {
  /// Today's cities and today's total. Re-read rather than streamed: a globe
  /// that re-renders on every stranger's tap is a battery bill, and this
  /// number does not need to be live to the second.
  Future<SangatPresence> today();

  /// Adds this phone to today's count, in the city the person chose. Called
  /// once a session actually completes, never on opening the screen.
  Future<void> markSitting({
    required String cityId,
    required String cityName,
    required double lat,
    required double lon,
  });
}

/// No server: a quiet globe, and nothing recorded anywhere.
class NoPresenceRepository implements PresenceRepository {
  const NoPresenceRepository();

  @override
  Future<SangatPresence> today() async => SangatPresence.empty;

  @override
  Future<void> markSitting({
    required String cityId,
    required String cityName,
    required double lat,
    required double lon,
  }) async {}
}

final presenceRepositoryProvider =
    Provider<PresenceRepository>((ref) => const NoPresenceRepository());

/// Today's presence, or nothing for somebody who has not joined.
final simranPresenceProvider = FutureProvider<SangatPresence>((ref) {
  final account = ref.watch(sangatAccountProvider).value;
  if (account == null) return Future.value(SangatPresence.empty);
  return ref.watch(presenceRepositoryProvider).today();
});

/// What design 29's globe draws: today's presence with this person's own city
/// always lit.
///
/// The city comes from Settings, which is on the phone and needs no account
/// and no network, so somebody who never joins the sangat still sees where
/// they are. It adds nothing to the count -- see [SangatPresence.withHome].
final globePresenceProvider = Provider<SangatPresence>((ref) {
  final presence =
      ref.watch(simranPresenceProvider).value ?? SangatPresence.empty;
  final id = ref.watch(settingsProvider).cityId;
  final rows = ref.watch(citiesProvider).value ?? const <CityRow>[];
  final home = rows.where((c) => c.id == id).firstOrNull;
  if (home == null) return presence;
  return presence.withHome(
    PresenceCity(
      id: home.id,
      name: home.nameEn,
      lat: home.lat,
      lon: home.lon,
      count: 0,
    ),
  );
});
