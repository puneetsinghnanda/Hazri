import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_db.dart' show BaniSlot;
import 'package:hazri/core/db/user_db.dart';
import 'package:hazri/core/db/user_repository.dart';
import 'package:hazri/core/time/clock.dart';
import 'package:hazri/features/audio/data/audio_controller.dart';
import 'package:hazri/features/nitnem/data/complete_bani.dart';
import 'package:hazri/features/nitnem/domain/bani.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

/// 06-nitnem RS1-RS3 (owner, 2026-11-21): Japji Sahib finished yesterday
/// opened at its end today. Every new day each bani starts at its first line
/// and 0:00; within the day one stopped halfway resumes.
void main() {
  const japji = Bani(
    id: 'JAPJ',
    slug: 'japji-sahib',
    nameEn: 'Japji Sahib',
    namePa: 'ਜਪੁ ਜੀ ਸਾਹਿਬ',
    nameHi: 'जपु जी साहिब',
    category: 'nitnem',
    defaultSlot: BaniSlot.morning,
    sort: 1,
    estMinutes: 20,
    hasText: true,
    versionId: 'JAPJ_SGPC',
    lineCount: 385,
  );

  group('RS1: a resume point counts only on the day it was saved', () {
    late UserDb db;
    late FixedClock clock;
    late UserRepository repo;
    setUp(() {
      db = UserDb.memory();
      clock = FixedClock(DateTime(2026, 11, 20, 7));
      repo = UserRepository(db, clock);
    });
    tearDown(() => db.close());

    test('stopped halfway: the same day it resumes', () async {
      await repo.saveProgress('JAPJ_SGPC', 120, audioPosMs: 600000);
      clock.instant = DateTime(2026, 11, 20, 21);
      expect((await repo.progressFor('JAPJ_SGPC'))?.lineIdx, 120);
    });

    test('the next day it starts at the beginning, in the reader and on Nitnem', () async {
      await repo.saveProgress('JAPJ_SGPC', 120, audioPosMs: 600000);
      clock.instant = DateTime(2026, 11, 21, 5);
      expect(await repo.progressFor('JAPJ_SGPC'), isNull);
      expect(await repo.watchAllProgress().first, isEmpty, reason: 'Nitnem must not say "10:00 in"');
    });
  });

  group('RS2, RS3: a finished paath starts again from the top', () {
    late FakePaathPlayer player;
    late ProviderContainer c;
    late TestApp app;
    late FixedClock clock;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      app = await TestApp.create();
      player = FakePaathPlayer();
      clock = FixedClock(DateTime(2026, 11, 20, 7));
      c = ProviderContainer(overrides: [
        ...app.overrides,
        paathPlayerProvider.overrideWithValue(player),
        clockProvider.overrideWithValue(clock),
      ]);
    });
    tearDown(() {
      c.dispose();
      app.dispose();
    });

    test('completing a paath clears where it was left', () async {
      final repo = c.read(userRepositoryProvider);
      await repo.saveProgress('JAPJ_SGPC', 384, audioPosMs: 1200000);
      await c.read(completionPathProvider).completeBani(japji, CompletionSource.audio);
      expect(await repo.progressFor('JAPJ_SGPC'), isNull);
    });

    test('a recitation still loaded at its end opens at 0:00', () async {
      final pc = c.read(playbackControllerProvider);
      await pc.prepare(japji, language: 'en');
      player.position = const Duration(minutes: 20);
      player.finished = true;
      await pc.prepare(japji, language: 'en');
      expect(player.position, Duration.zero);
    });

    test('one loaded yesterday and paused halfway opens at 0:00 today', () async {
      final pc = c.read(playbackControllerProvider);
      await pc.prepare(japji, language: 'en');
      player.position = const Duration(minutes: 10);
      clock.instant = DateTime(2026, 11, 21, 5);
      await pc.prepare(japji, language: 'en');
      expect(player.position, Duration.zero);
    });

    test('paused halfway today keeps its place, and a playing one is never moved', () async {
      final pc = c.read(playbackControllerProvider);
      await pc.prepare(japji, language: 'en');
      player.position = const Duration(minutes: 10);
      await pc.prepare(japji, language: 'en');
      expect(player.position, const Duration(minutes: 10));

      await player.play();
      clock.instant = DateTime(2026, 11, 21, 5);
      await pc.prepare(japji, language: 'en');
      expect(player.position, const Duration(minutes: 10));
    });
  });
}
