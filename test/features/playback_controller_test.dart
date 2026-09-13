import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_db.dart' show BaniSlot;
import 'package:hazri/core/settings/settings_controller.dart';
import 'package:hazri/features/audio/data/audio_controller.dart';
import 'package:hazri/features/nitnem/domain/bani.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_harness.dart';

void main() {
  late FakePaathPlayer player;
  late ProviderContainer container;
  late TestApp app;

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

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    app = await TestApp.create();
    player = FakePaathPlayer();
    container = ProviderContainer(
      overrides: [
        ...app.overrides,
        paathPlayerProvider.overrideWithValue(player),
      ],
    );
  });

  tearDown(() {
    container.dispose();
    app.dispose();
  });

  PlaybackController controller() => container.read(playbackControllerProvider);

  group('pressing play', () {
    test('loads the recitation before starting it', () async {
      // The bug this replaces: play() was called on a player that had never
      // been given a source, so nothing happened and the position stayed 0:00.
      expect(player.isLoaded, isFalse);

      final ok = await controller().playOrToggle(japji, language: 'en');

      expect(ok, isTrue);
      expect(player.setQueueCalls, 1, reason: 'the track must be loaded');
      expect(player.queued.single.slug, 'japji-sahib');
      expect(player.isPlaying, isTrue, reason: 'and it must actually be playing');
    });

    test('does not reload a bani that is already loaded', () async {
      await controller().playOrToggle(japji, language: 'en');
      await controller().playOrToggle(japji, language: 'en');
      expect(player.setQueueCalls, 1);
    });

    test('toggles to paused on a second press, then back', () async {
      await controller().playOrToggle(japji, language: 'en');
      expect(player.isPlaying, isTrue);

      await controller().playOrToggle(japji, language: 'en');
      expect(player.isPlaying, isFalse);

      await controller().playOrToggle(japji, language: 'en');
      expect(player.isPlaying, isTrue);
      expect(player.setQueueCalls, 1);
    });
  });

  group('prepare', () {
    test('loads the track without starting it', () async {
      final ok = await controller().prepare(japji, language: 'en');
      expect(ok, isTrue);
      expect(player.isLoaded, isTrue, reason: 'the scrubber needs a duration');
      expect(player.isPlaying, isFalse, reason: 'opening a bani must not blare out');
    });

    test('seeks to a saved position', () async {
      await controller().prepare(
        japji,
        at: const Duration(minutes: 3),
        language: 'en',
      );
      expect(player.position, const Duration(minutes: 3));
    });

    test('an already-loaded bani is seeked, not reloaded', () async {
      await controller().prepare(japji, language: 'en');
      await controller().prepare(japji, at: const Duration(minutes: 5), language: 'en');
      expect(player.setQueueCalls, 1);
      expect(player.position, const Duration(minutes: 5));
    });

    test('applies the saved speed', () async {
      await container.read(settingsProvider.notifier).setSpeed(1.5);
      await controller().prepare(japji, language: 'en');
      expect(player.speed, 1.5);
    });

    test('reports failure for a bani with no recitation', () async {
      const sukhmani = Bani(
        id: 'SUKH',
        slug: 'sukhmani-sahib',
        nameEn: 'Sukhmani Sahib',
        namePa: 'ਸੁਖਮਨੀ ਸਾਹਿਬ',
        nameHi: 'सुखमनी साहिब',
        category: 'other',
        defaultSlot: BaniSlot.none,
        sort: 9,
        estMinutes: 60,
        hasText: false,
        versionId: 'SUKH_SGPC',
      );
      expect(await controller().prepare(sukhmani, language: 'en'), isFalse);
      expect(player.isLoaded, isFalse);
    });
  });

  group('speed toggle', () {
    test('flips between normal pace and 1.5x', () async {
      expect(container.read(settingsProvider).speed, 1.0);

      expect(await controller().toggleSpeed(), 1.5);
      expect(player.speed, 1.5);
      expect(container.read(settingsProvider).speed, 1.5);

      expect(await controller().toggleSpeed(), 1.0);
      expect(player.speed, 1.0);
    });

    test('a speed set from the sheet is remembered and applied', () async {
      await controller().setSpeed(0.75);
      expect(player.speed, 0.75);
      expect(container.read(settingsProvider).speed, 0.75);
    });
  });

  group('play all', () {
    test('queues every morning bani that has a recitation', () async {
      final ok = await controller().playSlot(BaniSlot.morning, language: 'en');
      // Only Japji has audio in this build, so the queue is one long.
      expect(ok, isTrue);
      expect(player.queued.map((t) => t.slug), ['japji-sahib']);
      expect(player.isPlaying, isTrue);
    });

    test('reports failure for a slot with no recitations', () async {
      expect(await controller().playSlot(BaniSlot.bedtime, language: 'en'), isFalse);
    });
  });

  group('with no player at all', () {
    test('every command is a no-op rather than a crash', () async {
      final noPlayer = ProviderContainer(
        overrides: [...app.overrides, paathPlayerProvider.overrideWithValue(null)],
      );
      addTearDown(noPlayer.dispose);
      final c = noPlayer.read(playbackControllerProvider);
      expect(await c.playOrToggle(japji, language: 'en'), isFalse);
      expect(await c.prepare(japji, language: 'en'), isFalse);
      expect(await c.playSlot(BaniSlot.morning, language: 'en'), isFalse);
    });
  });
}
