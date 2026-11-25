import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/features/announcements/ui/announcement_screen.dart';
import 'package:hazri/features/profile/data/profile_controller.dart';
import 'package:hazri/features/sangat/data/sangat_device.dart';
import 'package:http/http.dart' as http;

import '../app_harness.dart';
import 'profile/profile_fakes.dart';

class _Push extends NoPushTokens {
  const _Push();
  @override
  Future<String?> token() async => 'push-token-1';
}

/// 02-notifications AN1, AN4, AN5, AN7 (owner, 2026-11-19, option B).
void main() {
  late FakeServer server;
  late List<Map<String, Object?>> saved;
  late L l;

  setUpAll(() async => l = await L.delegate.load(const Locale('en')));

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_timezone'), (_) async => 'Asia/Kolkata');
    server = FakeServer();
    saved = [];
    server.on('GET', '/profile', 200, {'profile': profileJson()});
    server.routes['POST /devices/fcm-token'] = (body) {
      saved.add(body);
      return http.Response(jsonEncode({'result': 'TOKEN_SAVED'}), 200, headers: {'content-type': 'application/json'});
    };
  });

  test('AN1: with a profile and no group the token is saved, announcements on; the switch turns them off (AN7)', () async {
    final app = await TestApp.create(extra: [...server.overrides(), pushTokensProvider.overrideWithValue(const _Push())]);
    addTearDown(app.dispose);
    app.container.read(profileControllerProvider);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(app.container.read(profileControllerProvider), isA<ProfileLoaded>());
    await app.container.read(sangatDeviceProvider).sync(force: true);
    expect(saved.last, containsPair('token', 'push-token-1'));
    expect(saved.last, containsPair('announcements', true));
    await app.container.read(announcementsOnProvider.notifier).set(false);
    expect(saved.last, containsPair('announcements', false));
    expect(app.container.read(announcementsOnProvider), isFalse);
  });

  testWidgets('AN4, AN5: a tapped announcement shows its message, formatted, and reports the open', (tester) async {
    server.on('GET', '/announcements/a1', 200, {
      'id': 'a1',
      'title': 'Gurpurab greetings',
      'message': 'Join the **sangat** at 7 pm.\n\n- Kirtan\n- Langar',
      'createdAt': '2026-11-19T06:00:00Z',
    });
    server.on('POST', '/announcements/a1/opened', 200, {'result': 'COUNTED'});
    late TestApp app;
    await tester.runAsync(() async {
      app = await TestApp.create(prefs: {'onboarding_done': true}, extra: server.overrides());
      app.container.read(profileControllerProvider);
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    addTearDown(app.dispose);
    usePhoneFrame(tester);
    await tester.pumpWidget(app.wrapRouted(const AnnouncementScreen(id: 'a1')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await settle(tester);
    expect(find.text(l.announcementTitle), findsOneWidget);
    expect(find.text('Gurpurab greetings'), findsOneWidget);
    expect(find.textContaining('Join the sangat at 7 pm.', findRichText: true), findsOneWidget);
    expect(find.textContaining('Langar', findRichText: true), findsOneWidget);
    expect(server.requests, contains('POST /announcements/a1/opened'));
  });

  test('inlineSpans: bold, italic and a link, and nothing else is touched', () {
    const base = TextStyle();
    final opened = <String>[];
    final spans = inlineSpans('a **b** *c* [d](https://hazri.me) e*f', base, Colors.blue, opened.add);
    expect([for (final s in spans) (s as TextSpan).text], ['a ', 'b', ' ', 'c', ' ', 'd', ' e*f']);
    expect((spans[1] as TextSpan).style!.fontWeight, FontWeight.w700);
    expect((spans[3] as TextSpan).style!.fontStyle, FontStyle.italic);
  });
}
