// Rendering the Sangat pushes in the recipient's locale (02-notifications.md
// §5.5, FM1). The strings are generated from the app's ARB files
// (scripts/gen-notif-strings.mjs).
import en from './en.json';
import pa from './pa.json';
import hi from './hi.json';
import { baniName } from '../reference';

export type Locale = 'en' | 'pa' | 'hi';
type Strings = Record<string, string>;
const TABLES: Record<Locale, Strings> = { en, pa, hi };

export function asLocale(v: unknown): Locale {
  return v === 'pa' || v === 'hi' ? v : 'en';
}

export function fill(template: string, values: Record<string, string | number>): string {
  return template.replace(/\{(\w+)\}/g, (whole, key: string) =>
    Object.prototype.hasOwnProperty.call(values, key) ? formatValue(values[key]) : whole,
  );
}

function formatValue(v: string | number): string {
  return typeof v === 'number' ? String(v) : v;
}

function str(locale: Locale, key: string): string {
  return TABLES[locale][key] ?? TABLES.en[key] ?? key;
}

export type SangatKind = 'Digest' | 'Milestone' | 'Final' | 'Complete' | 'Joined' | 'JoinedMany' | 'Ended';

/**
 * Title and body of `notifSangat<Kind>` in a locale. A Simran goal counts
 * minutes, not paath (08-sangat SG-1), so where a `...Simran` variant exists
 * (the digest and the final days) it is used instead.
 */
export function renderSangat(
  kind: SangatKind,
  locale: Locale,
  values: Record<string, string | number>,
  simran = false,
): { title: string; body: string } {
  const pick = (part: 'Title' | 'Body') => {
    const key = `notifSangat${kind}${part}`;
    return simran && TABLES.en[`${key}Simran`] !== undefined ? str(locale, `${key}Simran`) : str(locale, key);
  };
  return { title: fill(pick('Title'), values), body: fill(pick('Body'), values) };
}

export interface GoalLike {
  type: 'BANI' | 'SIMRAN';
  baniId?: string | null;
}

/** `{bani}`: the bani's name from content.db, or `notifSangatSimranUnit` for a Simran goal (SG9). */
export function unitFor(goal: GoalLike, locale: Locale): string {
  if (goal.type === 'SIMRAN' || !goal.baniId) return str(locale, 'notifSangatSimranUnit');
  return baniName(goal.baniId, locale);
}

export function someone(locale: Locale): string {
  return str(locale, 'notifSangatSomeone');
}

/** A group's name in a locale: custom groups have one name, built-in ones three. */
export function groupNameFor(
  group: { name?: string | null; names?: Record<string, string> | null },
  locale: Locale,
): string {
  if (group.names) return group.names[locale] ?? group.names.en ?? '';
  return group.name ?? '';
}
