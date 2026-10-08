// The rows of the weekly backup (10-backup §3.1, 04-goals §5, 12-badges §4.1),
// their validation, and the BK9 merge. Rows travel as JSON with ISO
// date-times; they are stored with those fields as Firestore Timestamps
// (10-backup §5.1). Everything here is pure.
import { Timestamp } from 'firebase-admin/firestore';
import { isValidDay } from '../time';

export type Row = Record<string, unknown> & { id?: string };

type Spec =
  | { t: 'uuid' }
  | { t: 'date'; null?: boolean }
  | { t: 'datetime'; null?: boolean }
  | { t: 'string'; null?: boolean }
  | { t: 'int'; min: number; max: number; null?: boolean }
  | { t: 'bool' }
  | { t: 'enum'; values: readonly string[] }
  | { t: 'hhmm'; null?: boolean };

const UUID_RE = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;
const ISO_RE = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2}(\.\d{1,9})?)?(Z|[+-]\d{2}:\d{2})$/;
const HHMM_RE = /^([01]\d|2[0-3]):[0-5]\d$/;

export const BADGE_IDS = [
  'JIGYASU',
  'SHARDHALU',
  'ABHYASI',
  'NITNEMI',
  'SIMRANI',
  'PAATHI',
  'SEVADAR',
  'GURSIKH',
  'SATSANGI',
  'VICHARI',
] as const;

export const TABLES = {
  goal: {
    id: { t: 'uuid' },
    startDate: { t: 'date' },
    completedOn: { t: 'date', null: true },
    createdAt: { t: 'datetime' },
    updatedAt: { t: 'datetime' },
  },
  item: {
    id: { t: 'uuid' },
    goalId: { t: 'uuid' },
    seriesId: { t: 'uuid' },
    itemType: { t: 'enum', values: ['BANI', 'SIMRAN'] },
    baniId: { t: 'string', null: true },
    timesPerDay: { t: 'int', min: 1, max: 11 },
    simranMinutes: { t: 'int', min: 5, max: 120, null: true },
    durationType: { t: 'enum', values: ['EVERY_DAY', 'DAYS', 'UNTIL_DATE'] },
    durationDays: { t: 'int', min: 1, max: 365, null: true },
    startDate: { t: 'date' },
    endDate: { t: 'date', null: true },
    removedOn: { t: 'date', null: true },
    reminderTime: { t: 'hhmm', null: true },
    createdAt: { t: 'datetime' },
    updatedAt: { t: 'datetime' },
  },
  completion: {
    id: { t: 'uuid' },
    localDate: { t: 'date' },
    baniId: { t: 'string' },
    slot: { t: 'enum', values: ['MORNING', 'EVENING', 'BEDTIME', 'NONE'] },
    source: { t: 'enum', values: ['READER', 'AUDIO', 'DIARY', 'RESTORED', 'MIGRATED'] },
    completedAt: { t: 'datetime' },
    updatedAt: { t: 'datetime' },
    deletedAt: { t: 'datetime', null: true },
  },
  session: {
    id: { t: 'uuid' },
    localDate: { t: 'date' },
    startedAt: { t: 'datetime' },
    durationS: { t: 'int', min: 0, max: 86400 * 7 },
    completed: { t: 'bool' },
    count: { t: 'int', min: 0, max: 10_000_000 },
    source: { t: 'enum', values: ['TIMER', 'DIARY', 'RESTORED', 'MIGRATED'] },
    updatedAt: { t: 'datetime' },
    deletedAt: { t: 'datetime', null: true },
  },
  badge: {
    badgeId: { t: 'enum', values: BADGE_IDS },
    earnedOn: { t: 'date' },
    announcedAt: { t: 'datetime', null: true },
    createdAt: { t: 'datetime' },
    updatedAt: { t: 'datetime' },
  },
} satisfies Record<string, Record<string, Spec>>;

export type Table = keyof typeof TABLES;

function checkField(v: unknown, s: Spec): string | null {
  const nullable = 'null' in s && s.null === true;
  if (v === null || v === undefined) return nullable ? null : 'is required';
  switch (s.t) {
    case 'uuid':
      return typeof v === 'string' && UUID_RE.test(v) ? null : 'must be a UUID';
    case 'date':
      return isValidDay(v) ? null : 'must be YYYY-MM-DD';
    case 'datetime':
      return typeof v === 'string' && ISO_RE.test(v) && !Number.isNaN(Date.parse(v)) ? null : 'must be an ISO date-time';
    case 'string':
      return typeof v === 'string' && v.length > 0 && v.length <= 64 ? null : 'must be a string';
    case 'int':
      return typeof v === 'number' && Number.isInteger(v) && v >= s.min && v <= s.max ? null : `must be a whole number ${s.min}–${s.max}`;
    case 'bool':
      return typeof v === 'boolean' ? null : 'must be true or false';
    case 'enum':
      return typeof v === 'string' && s.values.includes(v) ? null : `must be one of ${s.values.join(', ')}`;
    case 'hhmm':
      return typeof v === 'string' && HHMM_RE.test(v) ? null : 'must be HH:mm';
  }
}

/** Returns the row with only its own columns (unknown fields dropped), or the first problem. */
export function validateRow(table: Table, raw: unknown): { row: Row } | { error: string } {
  if (raw === null || typeof raw !== 'object' || Array.isArray(raw)) return { error: 'must be an object' };
  const o = raw as Record<string, unknown>;
  const spec = TABLES[table] as Record<string, Spec>;
  const row: Row = {};
  for (const [k, s] of Object.entries(spec)) {
    const e = checkField(o[k], s);
    if (e) return { error: `${k} ${e}` };
    row[k] = o[k] ?? null;
  }
  if (table === 'item') {
    // 04-goals §5.3 cross-field rules.
    if (row.itemType === 'BANI' && (row.baniId === null || row.simranMinutes !== null)) {
      return { error: 'a BANI item has a baniId and no simranMinutes' };
    }
    if (row.itemType === 'SIMRAN' && (row.baniId !== null || row.simranMinutes === null || row.timesPerDay !== 1)) {
      return { error: 'a SIMRAN item has simranMinutes, no baniId and timesPerDay 1' };
    }
    if ((row.durationType === 'DAYS') !== (row.durationDays !== null)) {
      return { error: 'durationDays is set for DAYS only' };
    }
  }
  return { row };
}

/** The key a row is merged by: `id`, or `badgeId` for badges. */
export function keyOf(table: Table, row: Row): string {
  return table === 'badge' ? (row.badgeId as string) : (row.id as string);
}

const ms = (v: unknown): number => (typeof v === 'string' ? Date.parse(v) : -Infinity);

/** BK9: the later updatedAt wins; on a tie the server keeps what it has. */
export function mergeRow(existing: Row | undefined, incoming: Row): { row: Row; changed: boolean } {
  if (!existing) return { row: incoming, changed: true };
  if (ms(incoming.updatedAt) > ms(existing.updatedAt)) return { row: incoming, changed: true };
  return { row: existing, changed: false };
}

/**
 * 12-badges §5.9: keep the earlier earnedOn, and announcedAt when either side
 * has one; createdAt the earlier, updatedAt the later.
 */
export function mergeBadge(existing: Row | undefined, incoming: Row): { row: Row; changed: boolean } {
  if (!existing) return { row: incoming, changed: true };
  const pickEarlier = (a: unknown, b: unknown) => (ms(a) <= ms(b) ? a : b);
  const merged: Row = {
    badgeId: existing.badgeId,
    earnedOn: (existing.earnedOn as string) <= (incoming.earnedOn as string) ? existing.earnedOn : incoming.earnedOn,
    announcedAt:
      existing.announcedAt && incoming.announcedAt
        ? pickEarlier(existing.announcedAt, incoming.announcedAt)
        : (existing.announcedAt ?? incoming.announcedAt ?? null),
    createdAt: pickEarlier(existing.createdAt, incoming.createdAt),
    updatedAt: ms(incoming.updatedAt) > ms(existing.updatedAt) ? incoming.updatedAt : existing.updatedAt,
  };
  const changed = JSON.stringify(merged) !== JSON.stringify(existing);
  return { row: changed ? merged : existing, changed };
}

/** Merges many rows into a map (in request order). Never deletes a row (BK9). */
export function mergeInto(table: Table, current: Record<string, Row>, incoming: Row[]): { rows: Record<string, Row>; changed: boolean } {
  const rows = { ...current };
  let changed = false;
  for (const r of incoming) {
    const key = keyOf(table, r);
    const m = table === 'badge' ? mergeBadge(rows[key], r) : mergeRow(rows[key], r);
    if (m.changed) {
      rows[key] = m.row;
      changed = true;
    }
  }
  return { rows, changed };
}

const DATETIME_FIELDS: Record<Table, string[]> = {
  goal: ['createdAt', 'updatedAt'],
  item: ['createdAt', 'updatedAt'],
  completion: ['completedAt', 'updatedAt', 'deletedAt'],
  session: ['startedAt', 'updatedAt', 'deletedAt'],
  badge: ['announcedAt', 'createdAt', 'updatedAt'],
};

/** JSON row → stored row (ISO → Timestamp). */
export function toStored(table: Table, row: Row): Record<string, unknown> {
  const out: Record<string, unknown> = { ...row };
  for (const f of DATETIME_FIELDS[table]) {
    const v = row[f];
    out[f] = typeof v === 'string' ? Timestamp.fromDate(new Date(v)) : null;
  }
  return out;
}

/** Stored row → JSON row (Timestamp → ISO with milliseconds). */
export function fromStored(table: Table, stored: Record<string, unknown>): Row {
  const out: Row = { ...stored };
  for (const f of DATETIME_FIELDS[table]) {
    const v = stored[f] as { toDate?: () => Date } | null | undefined;
    out[f] = v && typeof v.toDate === 'function' ? v.toDate().toISOString() : null;
  }
  return out;
}

/** Normalises an incoming ISO string to the form it reads back as, so a resend compares equal (BK8). */
export function canonical(table: Table, row: Row): Row {
  const out: Row = { ...row };
  for (const f of DATETIME_FIELDS[table]) {
    const v = row[f];
    if (typeof v === 'string') out[f] = new Date(v).toISOString();
  }
  return out;
}

/** An approximation of the stored size of a document, for the 900 KB limit (§5.5). */
export function approxSize(doc: unknown): number {
  return Buffer.byteLength(JSON.stringify(doc), 'utf8');
}
