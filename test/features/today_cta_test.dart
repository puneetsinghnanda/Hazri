import 'package:flutter_test/flutter_test.dart';
import 'package:hazri/core/db/content_db.dart' show BaniSlot;
import 'package:hazri/features/nitnem/domain/bani.dart';
import 'package:hazri/features/today/domain/today_state.dart';

/// Today's CTA state machine, one test per row of the PRD 1.3 table.
void main() {
  Bani bani(
    String id,
    String slug,
    BaniSlot slot,
    int sort,
    int minutes, {
    int lines = 100,
  }) =>
      Bani(
        id: id,
        slug: slug,
        nameEn: slug,
        namePa: slug,
        nameHi: slug,
        category: slot == BaniSlot.none ? 'other' : 'nitnem',
        defaultSlot: slot,
        sort: sort,
        estMinutes: minutes,
        hasText: true,
        versionId: '${id}_SGPC',
        lineCount: lines,
      );

  final banis = [
    bani('JAPJ', 'japji-sahib', BaniSlot.morning, 1, 20, lines: 385),
    bani('JAAP', 'jaap-sahib', BaniSlot.morning, 2, 18),
    bani('TVPS', 'tav-prasad-savaiye', BaniSlot.morning, 3, 4),
    bani('CHAU', 'chaupai-sahib', BaniSlot.morning, 4, 8),
    bani('ANND', 'anand-sahib', BaniSlot.morning, 5, 13),
    bani('REHR', 'rehras-sahib', BaniSlot.evening, 6, 18),
    bani('SOHL', 'kirtan-sohila', BaniSlot.bedtime, 7, 5),
  ];

  DayProgress progress({
    Set<String> baniIds = const {},
    Set<BaniSlot> slots = const {},
    ResumePoint? resume,
  }) =>
      DayProgress(completedBaniIds: baniIds, completedSlots: slots, resume: resume);

  test('nothing started: Start my Nitnem, with the whole morning in minutes', () {
    final cta = TodayLogic.cta(banis: banis, progress: progress());
    expect(cta.kind, TodayCtaKind.startNitnem);
    expect(cta.bani?.id, 'JAPJ');
    expect(cta.minutes, 63, reason: '20 + 18 + 4 + 8 + 13');
  });

  test('a bani in progress today: Continue, with the minutes left', () {
    final cta = TodayLogic.cta(
      banis: banis,
      progress: progress(
        resume: ResumePoint(
          baniVersionId: 'JAPJ_SGPC',
          // Roughly a fifth of the way through Japji's 385 lines.
          lineIdx: 77,
          updatedAt: DateTime(2026, 9, 12, 5),
        ),
      ),
    );
    expect(cta.kind, TodayCtaKind.continueBani);
    expect(cta.bani?.id, 'JAPJ');
    expect(cta.minutes, 16, reason: '80% of 20 minutes, rounded up');
    expect(cta.line, 77);
  });

  test('a resume point for a bani already finished today is ignored', () {
    final cta = TodayLogic.cta(
      banis: banis,
      progress: progress(
        baniIds: {'JAPJ'},
        resume: ResumePoint(
          baniVersionId: 'JAPJ_SGPC',
          lineIdx: 77,
          updatedAt: DateTime(2026, 9, 12, 5),
        ),
      ),
    );
    expect(cta.kind, TodayCtaKind.startNitnem);
    expect(cta.bani?.id, 'JAAP', reason: 'the next unfinished morning bani');
    expect(cta.minutes, 43, reason: 'the morning minus Japji');
  });

  const morning = {'JAPJ', 'JAAP', 'TVPS', 'CHAU', 'ANND'};

  test('T4 (3): morning done, in the evening slot: Start Rehras Sahib', () {
    final cta = TodayLogic.cta(
      banis: banis,
      progress: progress(baniIds: morning),
      currentSlot: BaniSlot.evening,
    );
    expect(cta.kind, TodayCtaKind.startBani);
    expect(cta.bani?.id, 'REHR');
    expect(cta.minutes, 18);
  });

  test('T4 (4): the current slot done, the next slot\'s first bani', () {
    final cta = TodayLogic.cta(
      banis: banis,
      progress: progress(baniIds: {...morning, 'REHR'}),
      currentSlot: BaniSlot.evening,
    );
    expect(cta.kind, TodayCtaKind.startBani);
    expect(cta.bani?.id, 'SOHL');
    expect(cta.minutes, 5);
  });

  test('all three slots done: the day is complete', () {
    final cta = TodayLogic.cta(
      banis: banis,
      progress: progress(baniIds: {...morning, 'REHR', 'SOHL'}),
      currentSlot: BaniSlot.bedtime,
    );
    expect(cta.kind, TodayCtaKind.allDone);
    expect(cta.bani, isNull);
  });

  test('T-h: an unmet goal item comes before the slot\'s bani (T-5)', () {
    final cta = TodayLogic.cta(
      banis: banis,
      progress: progress(),
      unmetItems: const [(baniId: 'REHR', simranMinutes: null)],
    );
    expect(cta.kind, TodayCtaKind.startBani);
    expect(cta.bani?.id, 'REHR');
  });

  test('T-i: a simran item unmet offers the Simran menu with its minutes', () {
    final cta = TodayLogic.cta(
      banis: banis,
      progress: progress(baniIds: {'JAPJ'}),
      unmetItems: const [(baniId: null, simranMinutes: 11)],
    );
    expect(cta.kind, TodayCtaKind.simran);
    expect(cta.minutes, 11);
  });

  test('T-l: a paath in progress comes before any goal item', () {
    final cta = TodayLogic.cta(
      banis: banis,
      progress: progress(
        resume: ResumePoint(baniVersionId: 'REHR_SGPC', lineIdx: 30, updatedAt: DateTime(2026, 9, 12, 18)),
      ),
      unmetItems: const [(baniId: 'JAPJ', simranMinutes: null)],
    );
    expect(cta.kind, TodayCtaKind.continueBani);
    expect(cta.bani?.id, 'REHR');
  });

  test('the slot follows the clock', () {
    final times = {
      BaniSlot.morning: DateTime(2026, 9, 12, 4, 30),
      BaniSlot.evening: DateTime(2026, 9, 12, 18, 30),
      BaniSlot.bedtime: DateTime(2026, 9, 12, 22),
    };
    expect(TodayLogic.slotAt(DateTime(2026, 9, 12, 9), times), BaniSlot.morning);
    expect(TodayLogic.slotAt(DateTime(2026, 9, 12, 19), times), BaniSlot.evening);
    expect(TodayLogic.slotAt(DateTime(2026, 9, 12, 22, 30), times), BaniSlot.bedtime);
  });

  group('morningCount', () {
    test('counts only the morning banis', () {
      final (done, total) = TodayLogic.morningCount(
        banis: banis,
        progress: progress(baniIds: {'JAPJ', 'JAAP', 'REHR'}),
      );
      expect(done, 2);
      expect(total, 5);
    });
  });

  group('activeSlot', () {
    final times = {
      BaniSlot.morning: DateTime(2026, 9, 12, 4, 30),
      BaniSlot.evening: DateTime(2026, 9, 12, 18, 30),
      BaniSlot.bedtime: DateTime(2026, 9, 12, 22),
    };

    test('is the first slot not finished', () {
      expect(
        TodayLogic.activeSlot(
          progress: progress(slots: {BaniSlot.morning}),
          slotTimes: times,
          now: DateTime(2026, 9, 12, 9),
        ),
        BaniSlot.evening,
      );
    });

    test('stays on bedtime once everything is done', () {
      expect(
        TodayLogic.activeSlot(
          progress: progress(
            slots: {BaniSlot.morning, BaniSlot.evening, BaniSlot.bedtime},
          ),
          slotTimes: times,
          now: DateTime(2026, 9, 12, 23),
        ),
        BaniSlot.bedtime,
      );
    });
  });
}
