// 08-sangat GG1–GG9 and ARCHITECTURE §6.4a: the group's globe as pure
// functions, and the member-row changes that feed it (§6.3 cityId, lastAddDay).
import { Timestamp } from 'firebase-admin/firestore';
import { GROUP_ARRIVALS_MAX, GROUP_GLOBE_SECONDS } from '../../src/config';
import { profileSyncChange } from '../../src/jobs/sangat';
import { memberChange } from '../../src/sangat/contribute';
import { cityFills, fromCityCounts, globeDto, globeIsFresh, GroupGlobeDoc, pickArrivals, tallyMembers } from '../../src/sangat/globe';

const day = '2026-10-17';
const now = new Date('2026-10-17T06:00:00Z');
const ts = (iso: string) => Timestamp.fromDate(new Date(iso));

describe('tallyMembers: a custom group, from its active member rows (GG2, GG3)', () => {
  it('counts per city, green when the latest counted paath is today, the rest unplaced', () => {
    const rows = [
      { cityId: 'amritsar', lastAddDay: day },
      { cityId: 'amritsar', lastAddDay: '2026-10-16' },
      { cityId: 'amritsar', lastAddDay: null },
      { cityId: 'london', lastAddDay: day },
      { cityId: null, lastAddDay: day }, // u_ member who added today
      {}, // a row from before 2026-10-17: no city, no day
    ];
    expect(tallyMembers(rows, day)).toEqual({
      cities: { amritsar: [1, 3], london: [1, 1] },
      unplaced: { today: 1, members: 2 },
    });
  });
  it('a city the reference list does not have cannot be drawn, so it is unplaced, not lost', () => {
    expect(tallyMembers([{ cityId: 'atlantis', lastAddDay: day }], day)).toEqual({ cities: {}, unplaced: { today: 1, members: 1 } });
  });
  it('no members: nothing on the globe', () => {
    expect(tallyMembers([], day)).toEqual({ cities: {}, unplaced: { today: 0, members: 0 } });
  });
});

describe('fromCityCounts: a built-in group, from count() per city (§6.4a)', () => {
  it('unplaced is memberCount less the placed, and today less the placed today', () => {
    const counts = [
      { cityId: 'amritsar', members: 4, today: 2 },
      { cityId: 'london', members: 1, today: 0 },
      { cityId: 'toronto', members: 0, today: 0 },
    ];
    expect(fromCityCounts(counts, 8, 3)).toEqual({
      cities: { amritsar: [2, 4], london: [0, 1] },
      unplaced: { members: 3, today: 1 },
    });
  });
  it('never negative when memberCount lags the counts (read a moment apart)', () => {
    expect(fromCityCounts([{ cityId: 'amritsar', members: 3, today: 3 }], 2, 1).unplaced).toEqual({ members: 0, today: 0 });
  });
  it('unplaced today is never more than the unplaced', () => {
    expect(fromCityCounts([], 2, 5).unplaced).toEqual({ members: 2, today: 2 });
  });
});

describe('pickArrivals: the paath arriving as light (GG4)', () => {
  const bani = { type: 'BANI' as const, baniId: 'JAPJ' };
  const simran = { type: 'SIMRAN' as const, baniId: null };
  const row = (n: number, over: Record<string, unknown> = {}) => ({
    kind: 'BANI',
    baniId: 'JAPJ',
    durationS: null,
    retracted: false,
    countedIn: ['grp/g0001'],
    cityId: 'amritsar',
    createdAt: ts(`2026-10-17T05:${String(59 - n).padStart(2, '0')}:00Z`),
    ...over,
  });

  it('keeps the order given (newest first), each with its city and what it added', () => {
    const out = pickArrivals([row(0), row(1, { cityId: null })], 'grp', 'g0001', bani);
    expect(out.map((a) => [a.cityId, a.at.toDate().toISOString(), a.amount])).toEqual([
      ['amritsar', '2026-10-17T05:59:00.000Z', 1],
      [null, '2026-10-17T05:58:00.000Z', 1],
    ]);
  });
  it('drops the retracted, and what counted in another goal or another group', () => {
    const rows = [
      row(0, { retracted: true }),
      row(1, { countedIn: ['grp/g0000'] }), // the previous built-in goal
      row(2, { countedIn: ['other/g0001'] }),
      row(3, { countedIn: [] }),
      row(4),
    ];
    expect(pickArrivals(rows, 'grp', 'g0001', bani).map((a) => a.at.toDate().toISOString())).toEqual(['2026-10-17T05:55:00.000Z']);
  });
  it(`at most GROUP_ARRIVALS_MAX (${GROUP_ARRIVALS_MAX}), the newest`, () => {
    const rows = Array.from({ length: 30 }, (_, i) => row(i));
    const out = pickArrivals(rows, 'grp', 'g0001', bani);
    expect(out).toHaveLength(GROUP_ARRIVALS_MAX);
    expect(out[0].at.toDate().toISOString()).toBe('2026-10-17T05:59:00.000Z');
  });
  it('a Naam Simran goal: each sitting brings its whole minutes (CT1, SG-1)', () => {
    const rows = [row(0, { kind: 'SIMRAN', baniId: null, durationS: 7 * 60 + 59 }), row(1, { kind: 'SIMRAN', baniId: null, durationS: 20 * 60 })];
    expect(pickArrivals(rows, 'grp', 'g0001', simran).map((a) => a.amount)).toEqual([7, 20]);
  });
});

describe('cityFills: rows from before cities were kept, from their profiles (GG2)', () => {
  const known = (c: string) => ['amritsar', 'london'].includes(c);
  it('fills a profile row with no city or an unknown one; leaves a known city, an anonymous row and a cityless profile', () => {
    const rows = [
      { id: 'p_a' },
      { id: 'p_b', cityId: 'atlantis' },
      { id: 'p_c', cityId: 'amritsar' },
      { id: 'u_d' },
      { id: 'p_e' },
    ];
    const profiles: Record<string, string | undefined> = { a: 'london', b: 'amritsar', c: 'london', e: undefined };
    expect(cityFills(rows, (id) => profiles[id], known)).toEqual([
      { id: 'p_a', cityId: 'london' },
      { id: 'p_b', cityId: 'amritsar' },
    ]);
  });
});

describe('globeIsFresh: one globe per group, rebuilt after GROUP_GLOBE_SECONDS (GG6)', () => {
  const stored = { goalId: 'g0001', day, builtAt: Timestamp.fromDate(new Date(now.getTime() - 60_000)) };
  const want = { goalId: 'g0001', day };
  it('fresh while younger than the limit, for this goal and this day', () => {
    expect(globeIsFresh(stored, want, now)).toBe(true);
  });
  it(`stale at ${GROUP_GLOBE_SECONDS} s`, () => {
    const old = { ...stored, builtAt: Timestamp.fromDate(new Date(now.getTime() - GROUP_GLOBE_SECONDS * 1000)) };
    expect(globeIsFresh(old, want, now)).toBe(false);
  });
  it('stale when built for another goal (a built-in reset) or another IST day', () => {
    expect(globeIsFresh(stored, { goalId: 'g0002', day }, now)).toBe(false);
    expect(globeIsFresh(stored, { goalId: 'g0001', day: '2026-10-18' }, now)).toBe(false);
    expect(globeIsFresh({ ...stored, goalId: null }, want, now)).toBe(false);
  });
  it('nothing stored is never fresh', () => {
    expect(globeIsFresh(null, want, now)).toBe(false);
  });
});

describe('globeDto: the reply of 7.15', () => {
  const doc: GroupGlobeDoc = {
    goalId: 'g0001',
    day,
    cities: { amritsar: [1, 2] },
    unplaced: { today: 0, members: 1 },
    recent: [{ cityId: 'amritsar', at: ts('2026-10-17T05:59:00Z'), amount: 1 }],
    builtAt: ts('2026-10-17T06:00:00Z'),
  };
  it('ISO times, and nothing finer than a city (GG7)', () => {
    expect(globeDto(doc, false)).toEqual({
      day,
      builtAt: '2026-10-17T06:00:00.000Z',
      cities: { amritsar: [1, 2] },
      unplaced: { today: 0, members: 1 },
      recent: [{ cityId: 'amritsar', at: '2026-10-17T05:59:00.000Z', amount: 1 }],
    });
  });
  it('an ended goal has no arrivals (GG9)', () => {
    expect(globeDto(doc, true).recent).toEqual([]);
  });
});

describe('memberChange: the member row in the contribution transaction (§6.3)', () => {
  const row = { contributionGoalId: 'g0001', lastAddDay: '2026-10-16', cityId: 'amritsar' };
  it('a paath today moves lastAddDay to today', () => {
    expect(memberChange(row, 'g0001', 1, day, 'amritsar')).toEqual({ contribution: { increment: 1 }, lastAddDay: day });
  });
  it('a late outbox row for an earlier day never moves it back', () => {
    expect(memberChange(row, 'g0001', 1, '2026-10-10', 'amritsar')).toEqual({ contribution: { increment: 1 } });
  });
  it('the first paath toward a new goal sets it whatever the old goal had', () => {
    expect(memberChange({ ...row, lastAddDay: '2026-10-20' }, 'g0002', 1, day, 'amritsar')).toEqual({
      contribution: { set: 1, goalId: 'g0002' },
      lastAddDay: day,
    });
  });
  it('fills a missing city from the caller’s profile, never overwrites one, never invents one', () => {
    expect(memberChange({ ...row, cityId: null }, 'g0001', 1, day, 'london')?.cityId).toBe('london');
    expect(memberChange({ ...row, cityId: undefined }, 'g0001', 1, day, 'london')?.cityId).toBe('london');
    expect(memberChange(row, 'g0001', 1, day, 'london')?.cityId).toBeUndefined();
    expect(memberChange({ ...row, cityId: null }, 'g0001', 1, day, null)?.cityId).toBeUndefined();
  });
  it('a retraction takes the amount back and touches neither the day nor the city', () => {
    expect(memberChange({ ...row, cityId: null }, 'g0001', -1, day, 'london')).toEqual({ contribution: { increment: -1 } });
    expect(memberChange(row, 'g0002', -1, day, 'london')).toBeNull();
  });
});

describe('profileSyncChange: what a profile update sends to the member rows', () => {
  it('a name change, a city change, or both', () => {
    expect(profileSyncChange({ name: 'A', cityId: 'amritsar' }, { name: 'B', cityId: 'amritsar' })).toEqual({ name: 'B' });
    expect(profileSyncChange({ name: 'A', cityId: 'amritsar' }, { name: 'A', cityId: 'london' })).toEqual({ cityId: 'london' });
    expect(profileSyncChange({ name: 'A', cityId: 'amritsar' }, { name: 'B', cityId: 'london' })).toEqual({ name: 'B', cityId: 'london' });
  });
  it('nothing for every other profile write (attendance, email), so they cost no query', () => {
    expect(profileSyncChange({ name: 'A', cityId: 'amritsar', lastSeenDay: '1' } as object, { name: 'A', cityId: 'amritsar', lastSeenDay: '2' } as object)).toBeNull();
    expect(profileSyncChange(undefined, undefined)).toBeNull();
  });
});
