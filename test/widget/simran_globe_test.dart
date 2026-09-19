import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/sangat/data/account_repository.dart';
import 'package:hazri/features/sangat/data/presence_repository.dart';
import 'package:hazri/features/sangat/domain/sangat_account.dart';
import 'package:hazri/features/sangat/domain/simran_presence.dart';
import 'package:hazri/features/simran/ui/simran_globe.dart';
import 'package:hazri/features/simran/ui/simran_screen.dart';

import '../app_harness.dart';
import '../fake_account_repository.dart';

const _account = SangatAccount(
  id: 'uid-1',
  name: 'Harjit Singh',
  city: 'Amritsar',
  email: 'harjit@example.com',
);

const _cities = [
  PresenceCity(id: 'amritsar', name: 'Amritsar', lat: 31.63, lon: 74.87, count: 12),
  PresenceCity(id: 'london', name: 'London', lat: 51.5, lon: -0.12, count: 3),
  // Directly behind the earth from Amritsar: the painter must drop it rather
  // than draw it on top.
  PresenceCity(id: 'far', name: 'Far side', lat: -31.63, lon: -105.13, count: 1),
];

class _FakePresence implements PresenceRepository {
  _FakePresence(this.value);
  final SangatPresence value;
  final marked = <String>[];

  @override
  Future<SangatPresence> today() async => value;

  @override
  Future<void> markSitting({
    required String cityId,
    required String cityName,
    required double lat,
    required double lon,
  }) async =>
      marked.add(cityId);
}

/// Design 29 — the globe, and what it says when there is nobody on it.
void main() {
  Future<L> pump(
    WidgetTester tester, {
    required SangatPresence presence,
    SangatAccount? signedIn = _account,
    Locale locale = const Locale('en'),
  }) async {
    final account = FakeAccountRepository(account: signedIn);
    addTearDown(account.dispose);
    final app = await TestApp.create(
      prefs: {'onboarding_done': true},
      extra: [
        accountRepositoryProvider.overrideWithValue(account),
        presenceRepositoryProvider.overrideWithValue(_FakePresence(presence)),
      ],
    );
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(
      app.wrapRouted(const Scaffold(body: SimranPresenceCard()), locale: locale),
    );
    await settle(tester);
    return L.delegate.load(locale);
  }

  testWidgets('a new app says you are the first, never nought others',
      (tester) async {
    final l = await pump(tester, presence: const SangatPresence(total: 1, yours: 1));
    expect(find.text(l.simranGlobeFirst), findsOneWidget);
    expect(find.text(l.simranOthersHere(0)), findsNothing);
  });

  testWidgets('a busy day counts everybody but you', (tester) async {
    final l = await pump(
      tester,
      presence: const SangatPresence(cities: _cities, total: 48, yours: 1),
    );
    expect(find.text(l.simranOthersHere(47)), findsOneWidget);
    expect(find.text(l.simranOthersSub), findsOneWidget);
  });

  testWidgets('the globe draws without throwing, spinning or still',
      (tester) async {
    await pump(tester, presence: const SangatPresence(cities: _cities, total: 48, yours: 1));
    expect(find.byType(SimranGlobe), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Turning it by hand is the one gesture design 29 asks for.
    await tester.drag(find.byType(SimranGlobe), const Offset(-60, 0));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  for (final locale in [const Locale('en'), const Locale('pa'), const Locale('hi')]) {
    testWidgets('lays out without overflowing in ${locale.languageCode}',
        (tester) async {
      await pump(
        tester,
        presence: const SangatPresence(cities: _cities, total: 48, yours: 1),
        locale: locale,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
