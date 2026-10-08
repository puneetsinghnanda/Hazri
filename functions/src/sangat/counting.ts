// The counting rules CT1–CT9 (08-sangat §4.5) as pure functions, and the
// validation of an outbox row (§5.1, API 7.12).
import { DIARY_DAILY_CAP } from '../config';
import { dayIst } from '../time';
import type { GoalDoc, GroupDoc, MemberDoc } from './model';

export type ItemKind = 'BANI' | 'SIMRAN';
export type ItemAction = 'ADD' | 'RETRACT';
export const COMPLETION_SOURCES = ['READER', 'AUDIO', 'DIARY', 'RESTORED', 'MIGRATED'] as const;
export const SITTING_SOURCES = ['TIMER', 'DIARY', 'RESTORED', 'MIGRATED'] as const;

export interface OutboxItem {
  id: string;
  kind: ItemKind;
  baniId: string | null;
  durationS: number | null;
  source: string;
  at: Date;
  action: ItemAction;
}

const ID_RE = /^[A-Za-z0-9_-]{1,64}$/;

/** Validates one row of POST /contributions; returns the item or a message. */
export function parseOutboxItem(raw: unknown): OutboxItem | string {
  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) return 'Not an object';
  const o = raw as Record<string, unknown>;
  if (typeof o.id !== 'string' || !ID_RE.test(o.id)) return 'id must be a UUID';
  if (o.kind !== 'BANI' && o.kind !== 'SIMRAN') return 'kind must be BANI or SIMRAN';
  if (o.action !== 'ADD' && o.action !== 'RETRACT') return 'action must be ADD or RETRACT';
  const sources: readonly string[] = o.kind === 'BANI' ? COMPLETION_SOURCES : SITTING_SOURCES;
  if (typeof o.source !== 'string' || !sources.includes(o.source)) return `source must be one of ${sources.join(', ')}`;
  if (typeof o.at !== 'string' || Number.isNaN(Date.parse(o.at))) return 'at must be an ISO date-time';
  let baniId: string | null = null;
  let durationS: number | null = null;
  if (o.kind === 'BANI') {
    if (typeof o.baniId !== 'string' || o.baniId === '') return 'baniId is required for BANI';
    baniId = o.baniId;
  } else {
    if (typeof o.durationS !== 'number' || !Number.isInteger(o.durationS) || o.durationS < 0) {
      return 'durationS must be a whole number of seconds for SIMRAN';
    }
    durationS = o.durationS;
  }
  return { id: o.id, kind: o.kind, baniId, durationS, source: o.source, at: new Date(o.at), action: o.action };
}

/** CT9: the group day of a contribution is the IST date of completedAt/startedAt. */
export function groupDayOf(item: OutboxItem): string {
  return dayIst(item.at);
}

/** CT1: does this paath match the goal? */
export function matchesGoal(item: Pick<OutboxItem, 'kind' | 'baniId' | 'durationS'>, goal: Pick<GoalDoc, 'type' | 'baniId' | 'simranMinutes'>): boolean {
  if (goal.type === 'BANI') return item.kind === 'BANI' && item.baniId !== null && item.baniId === goal.baniId;
  const minutes = goal.simranMinutes ?? 0;
  return item.kind === 'SIMRAN' && item.durationS !== null && item.durationS >= minutes * 60;
}

export type NotCounted =
  | 'GROUP_NOT_ACTIVE'
  | 'NO_GOAL'
  | 'GOAL_ENDED'
  | 'OUTSIDE_GOAL_DAYS'
  | 'NOT_A_MEMBER'
  | 'BEFORE_JOINING'
  | 'NO_MATCH'
  | 'DIARY_CAP';

/**
 * CT1–CT4, CT7: whether one ADD counts toward one group's current goal.
 * `diaryCount` is the member's Diary-added count already counted toward this
 * group on that group day (contributionCaps).
 */
export function countDecision(args: {
  item: Pick<OutboxItem, 'kind' | 'baniId' | 'durationS' | 'source'>;
  day: string;
  group: Pick<GroupDoc, 'status'>;
  goal: Pick<GoalDoc, 'type' | 'baniId' | 'simranMinutes' | 'startDay' | 'endDay' | 'status'> | null;
  member: Pick<MemberDoc, 'status' | 'joinedDay'> | null;
  diaryCount: number;
}): { counts: true } | { counts: false; why: NotCounted } {
  const { item, day, group, goal, member, diaryCount } = args;
  if (group.status !== 'ACTIVE') return { counts: false, why: 'GROUP_NOT_ACTIVE' };
  if (!goal) return { counts: false, why: 'NO_GOAL' };
  if (goal.status !== 'ACTIVE') return { counts: false, why: 'GOAL_ENDED' }; // CT7
  if (day < goal.startDay || day > goal.endDay) return { counts: false, why: 'OUTSIDE_GOAL_DAYS' }; // CT2
  if (!member || member.status !== 'ACTIVE') return { counts: false, why: 'NOT_A_MEMBER' }; // CT2
  if (day < member.joinedDay) return { counts: false, why: 'BEFORE_JOINING' }; // CT2
  if (!matchesGoal(item, goal)) return { counts: false, why: 'NO_MATCH' }; // CT1
  if (item.source === 'DIARY' && diaryCount >= DIARY_DAILY_CAP) return { counts: false, why: 'DIARY_CAP' }; // CT4
  return { counts: true };
}

/** Cap document id: `{memberKey}_{groupId}_{dayIst}` (§6.4). */
export function capDocId(memberKey: string, groupId: string, day: string): string {
  return `${memberKey}_${groupId}_${day}`;
}

/** Contribution document id: `{memberKey}_{id}` (§6.4). */
export function contributionDocId(memberKey: string, id: string): string {
  return `${memberKey}_${id}`;
}
