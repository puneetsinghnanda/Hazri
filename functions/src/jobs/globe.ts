// The Simran globe's snapshot (07-simran §5.4), built on demand by
// GET /presence/globe when the stored one is older than GLOBE_SNAPSHOT_SECONDS
// (2026-11-09; it used to be a Function every 2 minutes whether anybody was
// looking or not, 132,000 reads a day with nobody on the app). Recomputed from
// the profiles every time, so a second build writes the same numbers (FN4).
import type { Firestore } from 'firebase-admin/firestore';
import { Timestamp } from 'firebase-admin/firestore';
import { GLOBE_COUNTED_SECONDS } from '../config';
import { CITIES } from '../reference';
import { buildSnapshot, CityCount, countedIsFresh, countedOf, SnapshotBody } from '../presence/snapshot';
import { dayIst } from '../time';

/** Runs `fn` over `items`, `size` at a time (aggregations in parallel, not all at once). */
export async function inBatches<T, R>(items: readonly T[], size: number, fn: (t: T) => Promise<R>): Promise<R[]> {
  const out: R[] = [];
  for (let i = 0; i < items.length; i += size) out.push(...(await Promise.all(items.slice(i, i + size).map(fn))));
  return out;
}

/** presenceSnapshot/current as stored. */
export interface StoredSnapshot extends SnapshotBody {
  builtAt: Timestamp;
  /** When the counted totals were last taken city by city. */
  countedAt: Timestamp;
  /** count() of every profile at that time; a change counts every city again. */
  profiles: number;
}

/**
 * §5.4. One count() of all profiles; the per-city counted totals of `previous`
 * while they are fresh (`countedIsFresh`), else one count() per city of the
 * reference list; then one live count() per city that has anybody counted.
 * With fifteen people in five cities that is 1 + 5 reads, not 184.
 */
export async function runBuildGlobeSnapshot(
  db: Firestore,
  now: Date,
  previous: Partial<StoredSnapshot> | null = null,
): Promise<StoredSnapshot> {
  const day = dayIst(now);
  const profiles = db.collection('profiles');
  const total = (await profiles.count().get()).data().count;

  let counted: Map<string, number>;
  let countedAt: Timestamp;
  if (countedIsFresh(previous, total, now, GLOBE_COUNTED_SECONDS) && previous?.countedAt) {
    counted = countedOf(previous);
    countedAt = previous.countedAt;
  } else {
    const pairs = await inBatches(CITIES, 16, async (c) => [c.id, (await profiles.where('cityId', '==', c.id).count().get()).data().count] as const);
    counted = new Map(pairs.filter(([, n]) => n > 0));
    countedAt = Timestamp.fromDate(now);
  }

  const counts: CityCount[] = await inBatches([...counted.entries()], 16, async ([cityId, n]) => {
    const live = (await profiles.where('cityId', '==', cityId).where('lastSeenDay', '==', day).count().get()).data().count;
    // A count taken an hour ago can be under today's live count; never draw more live than counted.
    return { cityId, live, counted: Math.max(n, live) };
  });
  const doc: StoredSnapshot = { ...buildSnapshot(day, counts), builtAt: Timestamp.fromDate(now), countedAt, profiles: total };
  await db.doc('presenceSnapshot/current').set(doc);
  return doc;
}
