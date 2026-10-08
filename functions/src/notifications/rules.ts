// The pure rules of the Sangat pushes (02-notifications §4.5): which message a
// member gets for a group on a day, which milestones a change crosses, and
// which milestone notices wait for a member's 07:00.
import { diffDays, localMinuteOfDay } from '../time';
import type { GoalDoc, GroupDoc } from '../sangat/model';
import { pctOf } from '../sangat/model';

export const MILESTONES = [25, 50, 75, 100] as const;

/** SG3: the milestones a total crosses between two values (before < m ≤ after). */
export function milestonesCrossed(beforeTotal: number, afterTotal: number, target: number): number[] {
  const b = pctOf(beforeTotal, target);
  const a = pctOf(afterTotal, target);
  return MILESTONES.filter((m) => b < m && a >= m);
}

export type DigestChoice =
  | { kind: 'Digest'; count: number }
  | { kind: 'Final'; daysLeft: number; remaining: number }
  | { kind: 'Ended' }
  | null;

/**
 * The 21:00 message for one group on the member's local date (read as the
 * group day of that date; README decisions):
 * - SG8: a custom group ended by its end date gets 5.5-F on the date it
 *   became inactive;
 * - SG4: an active goal in its last two days gets 5.5-C;
 * - SG2: otherwise 5.5-A, only when the group recorded paath that day.
 */
export function chooseDigest(group: Pick<GroupDoc, 'kind' | 'status' | 'endedOn' | 'endReason'>, goal: GoalDoc | null, localDate: string): DigestChoice {
  if (group.status === 'DISABLED' || !goal) return null;
  if (group.kind === 'CUSTOM' && group.status === 'INACTIVE') {
    return group.endReason === 'END_DATE' && group.endedOn === localDate ? { kind: 'Ended' } : null;
  }
  if (goal.status !== 'ACTIVE' || localDate < goal.startDay || localDate > goal.endDay) return null;
  const daysLeft = diffDays(localDate, goal.endDay) + 1;
  if (daysLeft <= 2) return { kind: 'Final', daysLeft, remaining: Math.max(0, goal.target - goal.total) };
  const count = goal.dayTotals?.[localDate] ?? 0;
  return count > 0 ? { kind: 'Digest', count } : null;
}

/** SG3: may a milestone go now to a member at this offset (07:00–20:59 local)? */
export function isDaytime(at: Date, offsetMin: number): boolean {
  const m = localMinuteOfDay(at, offsetMin);
  return m >= 7 * 60 && m < 21 * 60;
}

/**
 * Was a notice created at `createdAt` held for this member's 07:00, which is
 * now (`at` falls in the member's 07:00 hour)? True when it was created after
 * their previous 21:00 and before 07:00 today.
 */
export function heldForThisMorning(createdAt: Date, at: Date, offsetMin: number): boolean {
  const localNow = localMinuteOfDay(at, offsetMin);
  const sevenToday = at.getTime() - (localNow - 7 * 60) * 60_000;
  const ninePrev = sevenToday - 10 * 3_600_000;
  const t = createdAt.getTime();
  return t >= ninePrev && t < sevenToday;
}
