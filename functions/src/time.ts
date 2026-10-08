// Days and clocks. "Today" for the globe and the Sangat is the IST day
// (07-simran.md §2 "Day", 08-sangat.md CT9); a backup week is Sunday to
// Saturday by the phone's local date (10-backup.md §2 "Week").

const IST_OFFSET_MIN = 330;
const DAY_MS = 86_400_000;
const DAY_RE = /^(\d{4})-(\d{2})-(\d{2})$/;

/** A clock the tests can replace. */
export interface Clock {
  now(): Date;
}
export const systemClock: Clock = { now: () => new Date() };

function pad(n: number, width = 2): string {
  return String(n).padStart(width, '0');
}

/** `YYYY-MM-DD` of a UTC-midnight Date. */
function formatUtcDay(d: Date): string {
  return `${pad(d.getUTCFullYear(), 4)}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;
}

/** The calendar day at a fixed UTC offset (minutes east of UTC). */
export function dayAtOffset(at: Date, offsetMin: number): string {
  return formatUtcDay(new Date(at.getTime() + offsetMin * 60_000));
}

/** dayIst: the IST calendar day of an instant (CT9). */
export function dayIst(at: Date): string {
  return dayAtOffset(at, IST_OFFSET_MIN);
}

/** True for a real calendar date written `YYYY-MM-DD`. */
export function isValidDay(s: unknown): s is string {
  if (typeof s !== 'string') return false;
  const m = DAY_RE.exec(s);
  if (!m) return false;
  const d = new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
  return formatUtcDay(d) === s;
}

function parseDay(day: string): Date {
  const m = DAY_RE.exec(day);
  if (!m) throw new Error(`not a day: ${day}`);
  return new Date(Date.UTC(+m[1], +m[2] - 1, +m[3]));
}

export function addDays(day: string, n: number): string {
  return formatUtcDay(new Date(parseDay(day).getTime() + n * DAY_MS));
}

/** Whole days from `a` to `b` (b - a). */
export function diffDays(a: string, b: string): number {
  return Math.round((parseDay(b).getTime() - parseDay(a).getTime()) / DAY_MS);
}

/** weekId: the Sunday on or before a local date (10-backup.md §5.5). */
export function weekIdOf(localDate: string): string {
  const d = parseDay(localDate);
  return addDays(localDate, -d.getUTCDay());
}

/** The start (UTC instant) of an IST day. */
export function istDayStart(day: string): Date {
  return new Date(parseDay(day).getTime() - IST_OFFSET_MIN * 60_000);
}

/** Minutes since local midnight at an offset, 0..1439. */
export function localMinuteOfDay(at: Date, offsetMin: number): number {
  const shifted = new Date(at.getTime() + offsetMin * 60_000);
  return shifted.getUTCHours() * 60 + shifted.getUTCMinutes();
}

/**
 * The current UTC offset of an IANA zone, in minutes east of UTC, or null when
 * the zone is not known to the runtime.
 */
export function utcOffsetMinutes(tz: string, at: Date): number | null {
  let parts: Intl.DateTimeFormatPart[];
  try {
    parts = new Intl.DateTimeFormat('en-US', { timeZone: tz, timeZoneName: 'longOffset' }).formatToParts(at);
  } catch {
    return null;
  }
  const name = parts.find((p) => p.type === 'timeZoneName')?.value ?? '';
  if (name === 'GMT') return 0;
  const m = /^GMT([+-])(\d{1,2})(?::?(\d{2}))?$/.exec(name);
  if (!m) return null;
  const minutes = Number(m[2]) * 60 + Number(m[3] ?? '0');
  return m[1] === '-' ? -minutes : minutes;
}

/** Offsets that exist on Earth, in minutes. */
export const MIN_OFFSET = -720;
export const MAX_OFFSET = 840;

/**
 * The ranges of utcOffsetMin whose local hour is `localHour` at the UTC
 * instant `at` (the dispatcher's "tokens whose local time is now 21:00",
 * read as the hour 21:00–21:59; see README decisions). Returned as half-open
 * [from, to) ranges inside [MIN_OFFSET, MAX_OFFSET].
 */
export function offsetRangesForLocalHour(at: Date, localHour: number): Array<[number, number]> {
  const utcMinute = at.getUTCHours() * 60 + at.getUTCMinutes();
  // local = utc + offset (mod 1440) in [localHour*60, localHour*60+60)
  const from = localHour * 60 - utcMinute;
  const ranges: Array<[number, number]> = [];
  for (const k of [-1440, 0, 1440]) {
    const a = Math.max(from + k, MIN_OFFSET);
    const b = Math.min(from + k + 60, MAX_OFFSET + 1);
    if (a < b) ranges.push([a, b]);
  }
  return ranges;
}

export function toIso(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  if (value instanceof Date) return value.toISOString();
  const maybe = value as { toDate?: () => Date };
  if (typeof maybe.toDate === 'function') return maybe.toDate().toISOString();
  return null;
}
