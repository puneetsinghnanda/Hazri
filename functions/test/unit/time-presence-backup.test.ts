import { addDays, dayAtOffset, dayIst, diffDays, isValidDay, localMinuteOfDay, offsetRangesForLocalHour, utcOffsetMinutes, weekIdOf } from '../../src/time';
import { buildSnapshot, splitCity } from '../../src/presence/snapshot';
import { approxSize, canonical, fromStored, mergeBadge, mergeInto, mergeRow, toStored, validateRow } from '../../src/backup/rows';
import { parseBackup } from '../../src/routes/backup';
import { ApiError } from '../../src/errors';

describe('days and clocks', () => {
  it('IST day turns at 18:30 UTC (07-simran §2, CT9)', () => {
    expect(dayIst(new Date('2026-10-07T18:29:59Z'))).toBe('2026-10-07');
    expect(dayIst(new Date('2026-10-07T18:30:00Z'))).toBe('2026-10-08');
  });
  it('validates and moves days', () => {
    expect(isValidDay('2026-02-29')).toBe(false);
    expect(isValidDay('2028-02-29')).toBe(true);
    expect(isValidDay('2026-1-01')).toBe(false);
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01');
    expect(addDays('2026-10-08', 364)).toBe('2027-10-07');
    expect(diffDays('2026-10-01', '2026-10-08')).toBe(7);
  });
  it('weekId is the Sunday on or before the date (10-backup §5.5)', () => {
    expect(weekIdOf('2026-10-04')).toBe('2026-10-04'); // a Sunday
    expect(weekIdOf('2026-10-10')).toBe('2026-10-04'); // Saturday
    expect(weekIdOf('2026-10-11')).toBe('2026-10-11');
    expect(weekIdOf('2027-01-01')).toBe('2026-12-27');
  });
  it('offsets of IANA zones', () => {
    const at = new Date('2026-10-08T12:00:00Z');
    expect(utcOffsetMinutes('Asia/Kolkata', at)).toBe(330);
    expect(utcOffsetMinutes('Europe/London', at)).toBe(60);
    expect(utcOffsetMinutes('America/Toronto', at)).toBe(-240);
    expect(utcOffsetMinutes('UTC', at)).toBe(0);
    expect(utcOffsetMinutes('Not/AZone', at)).toBeNull();
    expect(dayAtOffset(at, -720)).toBe('2026-10-08');
    expect(localMinuteOfDay(at, 330)).toBe(17 * 60 + 30);
  });
  it('the dispatcher finds every zone whose local hour is 21 (SG2)', () => {
    const at = new Date('2026-10-08T15:00:00Z'); // 20:30 IST, 16:00 London
    const ranges = offsetRangesForLocalHour(at, 21);
    const hits = (o: number) => ranges.some(([a, b]) => o >= a && o < b);
    expect(hits(360)).toBe(true); // UTC+6 → 21:00
    expect(hits(390)).toBe(true); // UTC+6:30 → 21:30
    expect(hits(330)).toBe(false); // IST → 20:30
    expect(hits(60)).toBe(false);
    const at2 = new Date('2026-10-08T16:00:00Z');
    const r2 = offsetRangesForLocalHour(at2, 21);
    expect(r2.some(([a, b]) => 330 >= a && 330 < b)).toBe(true); // IST 21:30
    // Wrap-around: 21:00 in UTC-12 is 09:00 UTC the next day.
    const at3 = new Date('2026-10-09T09:00:00Z');
    expect(offsetRangesForLocalHour(at3, 21).some(([a, b]) => -720 >= a && -720 < b)).toBe(true);
    expect(offsetRangesForLocalHour(at3, 21).some(([a, b]) => 720 >= a && 720 < b)).toBe(true); // UTC+12 also 21:00
  });
});

describe('globe snapshot (07-simran §5.4, §2.1)', () => {
  const cities = [
    { id: 'new_delhi', country: 'IN', state: 'IN-DL' },
    { id: 'amritsar', country: 'IN', state: 'IN-PB' },
    { id: 'ludhiana', country: 'IN', state: 'IN-PB' },
    { id: 'toronto', country: 'CA', state: null },
  ];
  it('counts by country, state and city, leaving out empty cities', () => {
    const s = buildSnapshot(
      '2026-10-08',
      [
        { cityId: 'new_delhi', live: 25, counted: 40 },
        { cityId: 'amritsar', live: 3, counted: 10 },
        { cityId: 'ludhiana', live: 0, counted: 0 },
        { cityId: 'toronto', live: 1, counted: 2 },
        { cityId: 'unknown', live: 9, counted: 9 },
      ],
      cities,
    );
    expect(s).toEqual({
      day: '2026-10-08',
      live: 29,
      counted: 52,
      countries: {
        IN: {
          l: 28,
          c: 50,
          s: { 'IN-DL': { l: 25, c: 40, k: { new_delhi: [25, 40] } }, 'IN-PB': { l: 3, c: 10, k: { amritsar: [3, 10] } } },
        },
        CA: { l: 1, c: 2, s: { 'CA-XX': { l: 1, c: 2, k: { toronto: [1, 2] } } } },
      },
    });
  });
  it('G-8/G-9: Delhi 40 counted, 25 live', () => {
    expect(splitCity({ live: 25, counted: 40 }, { inThisCity: false, markedToday: true })).toEqual({ you: 0, live: 25, here: 15 });
    expect(splitCity({ live: 25, counted: 40 }, { inThisCity: true, markedToday: true })).toEqual({ you: 1, live: 24, here: 15 });
    expect(splitCity({ live: 25, counted: 40 }, { inThisCity: true, markedToday: false })).toEqual({ you: 1, live: 25, here: 14 });
    expect(splitCity({ live: 25, counted: 40 }, null)).toEqual({ you: 0, live: 25, here: 15 });
  });
});

const uuid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const completion = (n: number, updatedAt: string, extra: Record<string, unknown> = {}) => ({
  id: uuid(n),
  localDate: '2026-10-08',
  baniId: 'JAPJ',
  slot: 'MORNING',
  source: 'READER',
  completedAt: '2026-10-08T01:00:00.000Z',
  updatedAt,
  deletedAt: null,
  ...extra,
});

describe('backup rows (10-backup BK9, 12-badges §5.9)', () => {
  it('validates columns and drops unknown fields', () => {
    const v = validateRow('completion', { ...completion(1, '2026-10-08T01:00:00Z'), extra: 'x' });
    expect('row' in v && v.row.extra).toBeUndefined();
    expect(validateRow('completion', { ...completion(1, '2026-10-08T01:00:00Z'), slot: 'NOON' })).toEqual({ error: expect.stringMatching(/^slot/) });
    expect(validateRow('completion', { ...completion(1, '2026-10-08T01:00:00Z'), id: 'nope' })).toEqual({ error: 'id must be a UUID' });
  });
  it('item cross-field rules (04-goals §5.3)', () => {
    const item = {
      id: uuid(1),
      goalId: uuid(2),
      seriesId: uuid(1),
      itemType: 'SIMRAN',
      baniId: null,
      timesPerDay: 1,
      simranMinutes: 11,
      durationType: 'DAYS',
      durationDays: 40,
      startDate: '2026-10-01',
      endDate: '2026-11-09',
      removedOn: null,
      reminderTime: '06:40',
      createdAt: '2026-10-01T00:00:00Z',
      updatedAt: '2026-10-01T00:00:00Z',
    };
    expect('row' in validateRow('item', item)).toBe(true);
    expect(validateRow('item', { ...item, timesPerDay: 2 })).toHaveProperty('error');
    expect(validateRow('item', { ...item, durationType: 'EVERY_DAY' })).toHaveProperty('error');
    expect(validateRow('item', { ...item, reminderTime: '25:00' })).toHaveProperty('error');
  });
  it('newer wins, a tie keeps the server, an omitted row is never deleted', () => {
    const old = canonical('completion', completion(1, '2026-10-08T01:00:00Z'));
    const newer = canonical('completion', completion(1, '2026-10-08T02:00:00Z', { deletedAt: '2026-10-08T02:00:00Z' }));
    const tie = canonical('completion', completion(1, '2026-10-08T01:00:00Z', { slot: 'EVENING' }));
    expect(mergeRow(old, newer)).toEqual({ row: newer, changed: true });
    expect(mergeRow(newer, old)).toEqual({ row: newer, changed: false });
    expect(mergeRow(old, tie)).toEqual({ row: old, changed: false });
    const other = canonical('completion', completion(2, '2026-10-08T01:00:00Z'));
    const merged = mergeInto('completion', { [uuid(1)]: old, [uuid(2)]: other }, [newer]);
    expect(Object.keys(merged.rows).sort()).toEqual([uuid(1), uuid(2)]);
    expect(merged.rows[uuid(1)]).toEqual(newer);
    expect(mergeInto('completion', merged.rows, [newer]).changed).toBe(false); // BK8
  });
  it('badges keep the earlier earnedOn and an announcedAt from either side', () => {
    const a = { badgeId: 'JIGYASU', earnedOn: '2026-10-01', announcedAt: null, createdAt: '2026-10-01T00:00:00.000Z', updatedAt: '2026-10-01T00:00:00.000Z' };
    const b = { badgeId: 'JIGYASU', earnedOn: '2026-10-05', announcedAt: '2026-10-05T00:00:00.000Z', createdAt: '2026-10-05T00:00:00.000Z', updatedAt: '2026-10-05T00:00:00.000Z' };
    const m = mergeBadge(a, b);
    expect(m.row).toEqual({ ...a, announcedAt: b.announcedAt, updatedAt: b.updatedAt });
    expect(mergeBadge(m.row, b).changed).toBe(false);
  });
  it('stored form round-trips', () => {
    const r = canonical('session', {
      id: uuid(3),
      localDate: '2026-10-08',
      startedAt: '2026-10-08T01:00:00Z',
      durationS: 300,
      completed: true,
      count: 0,
      source: 'TIMER',
      updatedAt: '2026-10-08T01:05:00Z',
      deletedAt: null,
    });
    expect(fromStored('session', toStored('session', r))).toEqual(r);
    expect(approxSize({ a: 'xx' })).toBe(10);
  });
  it('POST /backup body: first bad row is named; at most 2000 rows', () => {
    expect(() => parseBackup({ completions: [completion(1, 'x')] })).toThrow(ApiError);
    try {
      parseBackup({ completions: [completion(1, '2026-10-08T01:00:00Z'), { ...completion(2, '2026-10-08T01:00:00Z'), baniId: 7 }] });
    } catch (e) {
      expect((e as ApiError).extras.fields).toEqual({ 'completions[1]': 'baniId must be a string' });
    }
    const many = Array.from({ length: 2001 }, (_, i) => completion(i, '2026-10-08T01:00:00Z'));
    expect(() => parseBackup({ completions: many })).toThrow(/Some fields/);
    const ok = parseBackup({ completions: [completion(1, '2026-10-08T01:00:00Z')], final: true });
    expect(ok.rows).toBe(1);
    expect(ok.final).toBe(true);
  });
});
