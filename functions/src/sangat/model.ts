// Sangat documents (ARCHITECTURE §5.6, 08-sangat.md §6) and the DTOs the app
// caches (08-sangat.md §5.2).
import type { Timestamp } from 'firebase-admin/firestore';
import { diffDays } from '../time';
import { toIso } from '../time';

export type GroupKind = 'BUILT_IN' | 'CUSTOM';
export type GroupStatus = 'ACTIVE' | 'INACTIVE' | 'DISABLED';
export type GoalType = 'BANI' | 'SIMRAN';
export type GoalStatus = 'ACTIVE' | 'COMPLETED' | 'EXPIRED';
export type MemberStatus = 'ACTIVE' | 'LEFT' | 'REMOVED';
export type Role = 'CREATOR' | 'MEMBER';

export interface GoalTemplate {
  type: GoalType;
  baniId: string | null;
  simranMinutes: number | null;
  target: number;
  lengthDays: number;
}

export interface GroupDoc {
  kind: GroupKind;
  name: string | null;
  names: { en: string; pa: string; hi: string } | null;
  creatorKey: string | null;
  status: GroupStatus;
  /** Admin enable restores this (README decisions). */
  statusBeforeDisable?: GroupStatus | null;
  endedOn: string | null;
  endReason: 'TARGET_MET' | 'END_DATE' | 'ADMIN' | null;
  currentGoalId: string | null;
  memberCount: number;
  inviteCode: string | null;
  inviteExpiresAt: Timestamp | null;
  goalTemplate: GoalTemplate | null;
  /** SG7: when the creator was last told who joined. */
  joinNoticeAt?: Timestamp | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface GoalDoc {
  type: GoalType;
  baniId: string | null;
  simranMinutes: number | null;
  target: number;
  startDay: string;
  endDay: string;
  status: GoalStatus;
  total: number;
  /** Count per group day, for "today's total" (VS3) and the digest (SG2). */
  dayTotals: Record<string, number>;
  completedAt: Timestamp | null;
  sequence: number;
  /** Built-in only: per-goal member contributions have been archived (§6.3). */
  archivedAt?: Timestamp | null;
  createdAt: Timestamp;
}

export interface MemberDoc {
  memberKey: string;
  name: string | null;
  role: Role;
  status: MemberStatus;
  joinedDay: string;
  joinedAt?: Timestamp;
  contribution: number;
  /** The goal `contribution` counts toward; a different goal means 0 (README decisions). */
  contributionGoalId: string | null;
  sortName: string;
  /** The profile's city, for the group's globe (GG2); null for `u_` members and rows from before 2026-10-17. */
  cityId?: string | null;
  /** `dayIst` of the latest counted paath toward the current goal (GG3); never moved backwards. */
  lastAddDay?: string | null;
  updatedAt: Timestamp;
}

export const ANON_SORT_NAME = '~';

export function sortNameOf(name: string | null): string {
  return name ? name.toLowerCase() : ANON_SORT_NAME;
}

/** Member key: `p_{profileId}` with a profile, `u_{uid}` without (§6). */
export function profileMemberKey(profileId: string): string {
  return `p_${profileId}`;
}
export function anonMemberKey(uid: string): string {
  return `u_${uid}`;
}
export function profileIdOfKey(key: string): string | null {
  return key.startsWith('p_') ? key.slice(2) : null;
}

export function pctOf(total: number, target: number): number {
  if (target <= 0) return 0;
  return Math.min(100, Math.floor((total * 100) / target));
}

/** Days left including today; 0 once the end day has passed. */
export function daysLeftOf(endDay: string, today: string): number {
  return Math.max(0, diffDays(today, endDay) + 1);
}

export function contributionFor(m: MemberDoc, goalId: string | null): number {
  return goalId !== null && m.contributionGoalId === goalId ? m.contribution : 0;
}

export interface GoalDto {
  goalId: string;
  type: GoalType;
  baniId: string | null;
  simranMinutes: number | null;
  target: number;
  startDay: string;
  endDay: string;
  status: GoalStatus;
  total: number;
  pct: number;
  todayTotal: number;
  daysLeft: number;
  completedAt: string | null;
  sequence: number;
}

export function goalDto(goalId: string, g: GoalDoc, today: string): GoalDto {
  return {
    goalId,
    type: g.type,
    baniId: g.baniId ?? null,
    simranMinutes: g.simranMinutes ?? null,
    target: g.target,
    startDay: g.startDay,
    endDay: g.endDay,
    status: g.status,
    total: g.total,
    pct: pctOf(g.total, g.target),
    todayTotal: g.dayTotals?.[today] ?? 0,
    daysLeft: g.status === 'ACTIVE' ? daysLeftOf(g.endDay, today) : 0,
    completedAt: toIso(g.completedAt),
    sequence: g.sequence,
  };
}

export interface GroupSummaryDto {
  groupId: string;
  kind: GroupKind;
  name: string | null;
  names: { en: string; pa: string; hi: string } | null;
  status: GroupStatus;
  endedOn: string | null;
  endReason: string | null;
  memberCount: number;
  isMember: boolean;
  role: Role | null;
  goal: GoalDto | null;
}

export function groupSummaryDto(
  groupId: string,
  g: GroupDoc,
  goal: { id: string; doc: GoalDoc } | null,
  today: string,
  membership: { isMember: boolean; role: Role | null },
): GroupSummaryDto {
  return {
    groupId,
    kind: g.kind,
    name: g.name ?? null,
    names: g.names ?? null,
    status: g.status,
    endedOn: g.endedOn ?? null,
    endReason: g.endReason ?? null,
    memberCount: g.memberCount,
    isMember: membership.isMember,
    role: membership.role,
    goal: goal ? goalDto(goal.id, goal.doc, today) : null,
  };
}

/** Deterministic goal ids, so a retried rollover creates nothing twice (FN4). */
export function goalIdFor(sequence: number): string {
  return `g${String(sequence).padStart(4, '0')}`;
}
