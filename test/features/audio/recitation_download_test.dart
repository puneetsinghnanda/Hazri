import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/l10n/gen/app_localizations.dart';
import 'package:hazri/core/theme/hazri_theme.dart';
import 'package:hazri/core/db/content_db.dart' show AudioTrackRow, BaniSlot;
import 'package:hazri/core/db/content_repository.dart';
import 'package:hazri/features/audio/data/audio_controller.dart';
import 'package:hazri/features/audio/data/recitation_downloads.dart';
import 'package:hazri/features/audio/ui/recitation_download_sheet.dart';
import 'package:hazri/features/nitnem/domain/bani.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../app_harness.dart';

/// Sukhmani Sahib's recitation is downloaded once (owner, 2026-11-19; PRD §8).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;
  late List<String> asked;

  final body = utf8.encode('ogg bytes of a long recitation' * 1000);
  final good = AudioTrackRow(
    id: 'sukhmani-sahib_sgpc',
    baniVersionId: 'SUKH_SGPC',
    pack: 'download',
    file: 'sukhmani-sahib.ogg',
    durationMs: 1000,
    bytes: body.length,
    sha256: sha256.convert(body).toString(),
  );

  setUp(() {
    dir = Directory.systemTemp.createTempSync('recitations');
    asked = [];
  });
  tearDown(() => dir.deleteSync(recursive: true));

  ProviderContainer container({http.Client? client, List<Override> more = const []}) {
    final c = ProviderContainer(overrides: [
      recitationDirProvider.overrideWith((ref) async => dir),
      recitationHttpProvider.overrideWithValue(client ??
          MockClient((req) async {
            asked.add(req.url.toString());
            return http.Response.bytes(body, 200);
          })),
      ...more,
    ]);
    addTearDown(c.dispose);
    return c;
  }

  test('downloads from the website, checks it and keeps it; the second time asks nothing', () async {
    final c = container();
    final d = c.read(recitationDownloadsProvider.notifier);
    final path = await d.download(good);
    expect(asked, ['https://hazri-dfcc1.web.app/audio/sukhmani-sahib.ogg']);
    expect(File(path!).readAsBytesSync(), body);
    expect(c.read(recitationDownloadsProvider)[good.file], isA<RecitationReady>());
    expect(await d.download(good), path);
    expect(asked, hasLength(1));
    expect(dir.listSync().map((e) => e.path.split('/').last), ['sukhmani-sahib.ogg']);
  });

  test('a file that does not match its checksum is not kept', () async {
    final c = container(client: MockClient((_) async => http.Response.bytes(List.filled(body.length, 7), 200)));
    expect(await c.read(recitationDownloadsProvider.notifier).download(good), isNull);
    expect(c.read(recitationDownloadsProvider)[good.file], isA<RecitationFailed>());
    expect(dir.listSync(), isEmpty, reason: 'no .part and no file left behind');
  });

  test('no connection says so', () async {
    final c = container(client: MockClient((_) async => throw http.ClientException('offline')));
    expect(await c.read(recitationDownloadsProvider.notifier).download(good), isNull);
    expect((c.read(recitationDownloadsProvider)[good.file] as RecitationFailed).offline, isTrue);
  });

  test('fetches quietly on Wi-Fi only, and only what is downloaded rather than bundled', () async {
    final c = container();
    final d = c.read(recitationDownloadsProvider.notifier);
    final bundled = AudioTrackRow(id: 'japji', baniVersionId: 'JAPJ_SGPC', pack: 'bundled', file: 'japji-sahib.ogg');
    await d.fetchOnWifi([ConnectivityResult.mobile], [good, bundled]);
    expect(asked, isEmpty);
    await d.fetchOnWifi([ConnectivityResult.wifi], [good, bundled]);
    expect(asked, ['https://hazri-dfcc1.web.app/audio/sukhmani-sahib.ogg']);
  });

  group('playing Sukhmani Sahib', () {
    const sukhmani = Bani(
      id: 'SUKH',
      slug: 'sukhmani-sahib',
      nameEn: 'Sukhmani Sahib',
      namePa: 'ਸੁਖਮਨੀ ਸਾਹਿਬ',
      nameHi: 'सुखमनी साहिब',
      category: 'other',
      defaultSlot: BaniSlot.none,
      sort: 9,
      estMinutes: 78,
      hasText: true,
      versionId: 'SUKH_SGPC',
      lineCount: 1,
    );

    late TestApp app;
    late FakePaathPlayer player;
    late List<String> prompted;

    Future<ProviderContainer> boot({String? Function()? answer}) async {
      app = await TestApp.create();
      addTearDown(app.dispose);
      player = FakePaathPlayer();
      prompted = [];
      return container(more: [
        ...app.overrides,
        paathPlayerProvider.overrideWithValue(player),
        recitationPromptProvider.overrideWithValue((row, title) async {
          prompted.add(title);
          return answer?.call();
        }),
      ]);
    }

    test('the bundled recitations are in the APK and Sukhmani Sahib is not', () async {
      final c = await boot();
      final tracks = await c.read(audioTracksProvider.future);
      expect(tracks['SUKH']!.pack, 'download');
      expect(tracks['SUKH']!.sha256, hasLength(64));
      expect(tracks.values.where((t) => t.pack == 'bundled'), hasLength(8));
      expect(File('assets/audio/sukhmani-sahib.ogg').existsSync(), isFalse);
      // The file the website serves is the one content.db expects.
      final served = File('public/audio/sukhmani-sahib.ogg');
      expect(served.lengthSync(), tracks['SUKH']!.bytes);
      expect(sha256.convert(served.readAsBytesSync()).toString(), tracks['SUKH']!.sha256);
    });

    test('opening the reader does not ask to download; pressing play does, and plays the kept file', () async {
      final kept = '${dir.path}/sukhmani-sahib.ogg';
      final c = await boot(answer: () => kept);
      expect(await c.read(playbackControllerProvider).prepare(sukhmani, language: 'en'), isFalse);
      expect(prompted, isEmpty);
      expect(await c.read(playbackControllerProvider).playBani(sukhmani, language: 'en'), isTrue);
      expect(prompted, ['Sukhmani Sahib']);
      expect(player.queued.single.assetPath, kept);
      expect(player.isPlaying, isTrue);
    });

    test('cancelled, nothing plays', () async {
      final c = await boot(answer: () => null);
      expect(await c.read(playbackControllerProvider).playBani(sukhmani, language: 'en'), isFalse);
      expect(player.isPlaying, isFalse);
    });

    test('once kept, it plays with no sheet and no connection', () async {
      final c = await boot();
      final row = (await c.read(audioTracksProvider.future))['SUKH']!;
      File('${dir.path}/${row.file}').writeAsBytesSync(File('public/audio/${row.file}').readAsBytesSync());
      expect(await c.read(playbackControllerProvider).playBani(sukhmani, language: 'en'), isTrue);
      expect(prompted, isEmpty);
      expect(player.queued.single.assetPath, '${dir.path}/sukhmani-sahib.ogg');
    });
  });

  testWidgets('the sheet: no internet says so with Try again; then it downloads and closes with the path', (tester) async {
    var online = false;
    final c = container(client: MockClient((_) async {
      if (!online) throw http.ClientException('offline');
      return http.Response.bytes(body, 200);
    }));
    final l = await L.delegate.load(const Locale('en'));
    String? result;
    usePhoneFrame(tester);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        localizationsDelegates: L.localizationsDelegates,
        supportedLocales: L.supportedLocales,
        theme: HazriTheme.light(),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showModalBottomSheet<String>(
              context: context,
              isScrollControlled: true,
              builder: (_) => RecitationDownloadSheet(row: good, title: 'Sukhmani Sahib'),
            ),
            child: const Text('play'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('play'));
    await tester.pump();
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle(); // the sheet has slid up; no spinner once it failed
    expect(find.text('Sukhmani Sahib'), findsOneWidget);
    expect(find.text(l.recitationDownloadOnce), findsOneWidget);
    expect(find.text(l.recitationNoInternet), findsOneWidget);
    online = true;
    await tester.tap(find.text(l.actionRetry));
    // The download's file writes are real I/O; let them and the frames take turns.
    for (var i = 0; i < 20 && result == null; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await tester.pumpAndSettle();
    expect(result, '${dir.path}/sukhmani-sahib.ogg');
    expect(find.byType(RecitationDownloadSheet), findsNothing);
  });
}
