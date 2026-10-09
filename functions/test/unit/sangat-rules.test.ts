import { amountFor, countDecision, matchesGoal, parseOutboxItem, groupDayOf, capDocId } from '../../src/sangat/counting';
import { formatInviteCode, generateInviteCode, inviteLink, normalizeInviteCode } from '../../src/sangat/invite';
import { contributionFor, daysLeftOf, goalIdFor, pctOf, sortNameOf } from '../../src/sangat/model';
import { factCounts, factWouldGrow, mergeFactArrays } from '../../src/badges/facts';
import { INVITE_CODE_ALPHABET } from '../../src/config';
import type { MemberDoc } from '../../src/sangat/model';

const japjiGoal = { type: 'BANI' as const, baniId: 'JAPJ', simranMinutes: null, startDay: '2026-10-01', endDay: '2026-10-31', status: 'ACTIVE' as const };
const simranGoal = { type: 'SIMRAN' as const, baniId: null, simranMinutes: null, startDay: '2026-10-01', endDay: '2026-10-31', status: 'ACTIVE' as const };
const member = { status: 'ACTIVE' as const, joinedDay: '2026-10-05' };
const active = { status: 'ACTIVE' as const };
const japji = { kind: 'BANI' as const, baniId: 'JAPJ', durationS: null, source: 'READER' };

describe('counting (08-sangat CT1–CT9)', () => {
  it('CT1: a completion of the goal bani counts; another bani does not', () => {
    expect(matchesGoal(japji, japjiGoal)).toBe(true);
    expect(matchesGoal({ ...japji, baniId: 'JAAP' }, japjiGoal)).toBe(false);
    expect(matchesGoal({ kind: 'SIMRAN', baniId: null, durationS: 3600 }, japjiGoal)).toBe(false);
  });
  it('CT1/SG-1: a Simran goal counts the whole minutes of every sitting', () => {
    expect(amountFor({ kind: 'SIMRAN', baniId: null, durationS: 7 * 60 }, simranGoal)).toBe(7);
    expect(amountFor({ kind: 'SIMRAN', baniId: null, durationS: 11 * 60 - 1 }, simranGoal)).toBe(10);
    expect(amountFor({ kind: 'SIMRAN', baniId: null, durationS: 59 }, simranGoal)).toBe(0);
    expect(matchesGoal({ kind: 'SIMRAN', baniId: null, durationS: 59 }, simranGoal)).toBe(false);
    expect(matchesGoal({ kind: 'SIMRAN', baniId: null, durationS: 60 }, simranGoal)).toBe(true);
    expect(amountFor({ kind: 'BANI', baniId: 'JAPJ', durationS: null }, simranGoal)).toBe(0);
    expect(amountFor({ kind: 'BANI', baniId: 'JAPJ', durationS: null }, japjiGoal)).toBe(1);
  });
  const base = { item: japji, day: '2026-10-08', group: active, goal: japjiGoal, member, diaryCount: 0 };
  it('counts in the ordinary case', () => {
    expect(countDecision(base)).toEqual({ counts: true });
  });
  it('CT2: outside the goal days, before joining, or not a member', () => {
    expect(countDecision({ ...base, day: '2026-09-30' })).toEqual({ counts: false, why: 'OUTSIDE_GOAL_DAYS' });
    expect(countDecision({ ...base, day: '2026-11-01' })).toEqual({ counts: false, why: 'OUTSIDE_GOAL_DAYS' });
    expect(countDecision({ ...base, day: '2026-10-04' })).toEqual({ counts: false, why: 'BEFORE_JOINING' });
    expect(countDecision({ ...base, member: { ...member, status: 'LEFT' } })).toEqual({ counts: false, why: 'NOT_A_MEMBER' });
    expect(countDecision({ ...base, member: null })).toEqual({ counts: false, why: 'NOT_A_MEMBER' });
  });
  it('CT2: the join day itself counts', () => {
    expect(countDecision({ ...base, day: '2026-10-05' })).toEqual({ counts: true });
  });
  it('CT4: Diary + counts at most 3 per member per group per day; other sources are not capped', () => {
    const diary = { ...base, item: { ...japji, source: 'DIARY' } };
    expect(countDecision({ ...diary, diaryCount: 2 })).toEqual({ counts: true });
    expect(countDecision({ ...diary, diaryCount: 3 })).toEqual({ counts: false, why: 'DIARY_CAP' });
    expect(countDecision({ ...base, diaryCount: 99 })).toEqual({ counts: true });
  });
  it('CT6/CG6/CT7: an inactive group or a finished goal counts nothing', () => {
    expect(countDecision({ ...base, group: { status: 'INACTIVE' } })).toEqual({ counts: false, why: 'GROUP_NOT_ACTIVE' });
    expect(countDecision({ ...base, group: { status: 'DISABLED' } })).toEqual({ counts: false, why: 'GROUP_NOT_ACTIVE' });
    expect(countDecision({ ...base, goal: { ...japjiGoal, status: 'COMPLETED' } })).toEqual({ counts: false, why: 'GOAL_ENDED' });
    expect(countDecision({ ...base, goal: null })).toEqual({ counts: false, why: 'NO_GOAL' });
  });
  it('CT9: the group day is the IST date of the time', () => {
    const item = parseOutboxItem({ id: 'a', kind: 'BANI', baniId: 'JAPJ', source: 'READER', at: '2026-10-07T19:00:00Z', action: 'ADD' });
    if (typeof item === 'string') throw new Error(item);
    expect(groupDayOf(item)).toBe('2026-10-08'); // 00:30 IST
    const late = parseOutboxItem({ id: 'b', kind: 'BANI', baniId: 'JAPJ', source: 'READER', at: '2026-10-07T18:29:59Z', action: 'ADD' });
    if (typeof late === 'string') throw new Error(late);
    expect(groupDayOf(late)).toBe('2026-10-07');
  });
  it('validates outbox rows', () => {
    expect(parseOutboxItem({ id: 'a', kind: 'BANI', source: 'READER', at: '2026-10-07T19:00:00Z', action: 'ADD' })).toMatch(/baniId/);
    expect(parseOutboxItem({ id: 'a', kind: 'SIMRAN', source: 'READER', at: '2026-10-07T19:00:00Z', action: 'ADD', durationS: 300 })).toMatch(/source/);
    expect(parseOutboxItem({ id: 'a', kind: 'SIMRAN', source: 'TIMER', at: 'nope', action: 'ADD', durationS: 300 })).toMatch(/at/);
    expect(parseOutboxItem({ id: 'a/b', kind: 'SIMRAN', source: 'TIMER', at: '2026-10-07T19:00:00Z', action: 'ADD', durationS: 300 })).toMatch(/id/);
    expect(parseOutboxItem({ id: 'a', kind: 'SIMRAN', source: 'TIMER', at: '2026-10-07T19:00:00Z', action: 'UNDO', durationS: 300 })).toMatch(/action/);
    expect(typeof parseOutboxItem({ id: 'a', kind: 'SIMRAN', source: 'TIMER', at: '2026-10-07T19:00:00Z', action: 'RETRACT', durationS: 300 })).toBe('object');
  });
  it('document ids', () => {
    expect(capDocId('p_x', 'g1', '2026-10-08')).toBe('p_x_g1_2026-10-08');
  });
});

describe('invite codes (IV2, IV7, §3)', () => {
  it('8 characters from the alphabet with no 0 O 1 I L', () => {
    for (let i = 0; i < 200; i++) {
      const c = generateInviteCode();
      expect(c).toHaveLength(8);
      for (const ch of c) expect(INVITE_CODE_ALPHABET).toContain(ch);
    }
    expect(INVITE_CODE_ALPHABET).not.toMatch(/[0O1IL]/);
  });
  it('typed with or without the hyphen, in any case', () => {
    expect(normalizeInviteCode('abcd-efgh')).toBe('ABCDEFGH');
    expect(normalizeInviteCode(' ABCD EFGH ')).toBe('ABCDEFGH');
    expect(normalizeInviteCode('ABCD-EFG')).toBeNull();
    expect(normalizeInviteCode('ABCD-EFG0')).toBeNull();
    expect(normalizeInviteCode('ABCD-EFGI')).toBeNull();
    expect(normalizeInviteCode(42)).toBeNull();
  });
  it('shown as XXXX-XXXX in the link', () => {
    expect(formatInviteCode('ABCDEFGH')).toBe('ABCD-EFGH');
    expect(inviteLink('ABCDEFGH')).toBe('https://hazri-dfcc1.web.app/j/ABCD-EFGH');
  });
});

describe('group figures', () => {
  it('percentage floors and stops at 100', () => {
    expect(pctOf(0, 100)).toBe(0);
    expect(pctOf(249, 1000)).toBe(24);
    expect(pctOf(250, 1000)).toBe(25);
    expect(pctOf(2000, 1000)).toBe(100);
  });
  it('days left includes today', () => {
    expect(daysLeftOf('2026-10-08', '2026-10-08')).toBe(1);
    expect(daysLeftOf('2026-10-10', '2026-10-08')).toBe(3);
    expect(daysLeftOf('2026-10-01', '2026-10-08')).toBe(0);
  });
  it('a member contribution belongs to one goal', () => {
    const m = { contribution: 4, contributionGoalId: 'g0001' } as MemberDoc;
    expect(contributionFor(m, 'g0001')).toBe(4);
    expect(contributionFor(m, 'g0002')).toBe(0);
  });
  it('sort names put "Sangat member" rows last (VS4)', () => {
    expect(sortNameOf('Harpreet')).toBe('harpreet');
    expect(sortNameOf(null) > 'zzzz').toBe(true);
    expect(goalIdFor(12)).toBe('g0012');
  });
});

describe('badge facts (12-badges §5.1)', () => {
  it('arrays of keys, capped, never duplicated', () => {
    expect(mergeFactArrays(['a'], ['a', 'b', 'c', 'd'], 3)).toEqual(['a', 'b', 'c']);
    expect(mergeFactArrays(undefined, ['x'], 5)).toEqual(['x']);
    expect(factWouldGrow(['a', 'b', 'c'], 'd', 3)).toBe(false);
    expect(factWouldGrow(['a', 'b'], 'a', 3)).toBe(false);
    expect(factWouldGrow(['a', 'b'], 'c', 3)).toBe(true);
    expect(factCounts(undefined)).toEqual({ goalsReached: 0, joins: 0 });
    expect(factCounts({ goalsReached: ['a', 'b'], joins: ['x'] })).toEqual({ goalsReached: 2, joins: 1 });
  });
});
