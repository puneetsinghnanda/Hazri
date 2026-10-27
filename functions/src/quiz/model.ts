// Board ids, periods and names for the Gurmat Quiz (ARCHITECTURE §5.13).
// Days, weeks and months are IST (14-quiz.md QZ21).
import { addDays } from '../time';

export type Period = 'day' | 'week' | 'month';
export const PERIODS: Period[] = ['day', 'week', 'month'];
export const ALL = 'all';

const DAY_MS = 86_400_000;

function utc(day: string): Date {
  const [y, m, d] = day.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d));
}

/** The ISO week of an IST day, `YYYY-Www`; weeks run Monday to Sunday. */
export function isoWeekOf(day: string): string {
  const d = utc(day);
  const dow = (d.getUTCDay() + 6) % 7; // Monday 0
  const thursday = new Date(d.getTime() + (3 - dow) * DAY_MS);
  const year = thursday.getUTCFullYear();
  const week = 1 + Math.floor((thursday.getTime() - Date.UTC(year, 0, 1)) / DAY_MS / 7);
  return `${year}-W${String(week).padStart(2, '0')}`;
}

/** The Monday that starts an IST day's week. */
export function weekStartOf(day: string): string {
  const dow = (utc(day).getUTCDay() + 6) % 7;
  return addDays(day, -dow);
}

/** The key of a period containing an IST day. */
export function periodKey(period: Period, day: string): string {
  if (period === 'day') return day;
  if (period === 'week') return isoWeekOf(day);
  return day.slice(0, 7);
}

/** `d2026-10-27_guru-ram-das-ji`, `w2026-W44_all`, `m2026-10_all`. */
export function boardId(period: Period, day: string, scope: string): string {
  return `${period[0]}${periodKey(period, day)}_${scope}`;
}

/** When a board's rows may be removed: a day's 35 days on, a week's 70, a month's 400 (§5.13). */
export function deleteAtOf(period: Period, day: string): Date {
  if (period === 'day') return utc(addDays(day, 35));
  if (period === 'week') return utc(addDays(weekStartOf(day), 70));
  return utc(addDays(`${day.slice(0, 7)}-01`, 400));
}

/** "Manpreet Singh" -> "Manpreet S."; one word stays as it is (QZ28). */
export function displayNameOf(name: string): string {
  const words = name.trim().split(/\s+/).filter(Boolean);
  if (words.length === 0) return '';
  if (words.length === 1) return words[0];
  const last = Array.from(words[words.length - 1])[0] ?? '';
  return `${words[0]} ${last.toUpperCase()}.`;
}

/** The days of `days` within the last `keep` days up to `today`. */
export function pruneDays(days: Record<string, number>, today: string, keep: number): Record<string, number> {
  const oldest = addDays(today, -(keep - 1));
  const out: Record<string, number> = {};
  for (const [d, n] of Object.entries(days)) if (d >= oldest && d <= today) out[d] = n;
  return out;
}
