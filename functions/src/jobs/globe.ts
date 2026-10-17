// buildGlobeSnapshot (07-simran §5.4): two count() aggregations per city on
// `profiles`, written as one document that replaces the last. Recomputed from
// the profiles every time, so a second run writes the same numbers (FN4).
import type { Firestore } from 'firebase-admin/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { CITIES } from '../reference';
import { buildSnapshot, CityCount } from '../presence/snapshot';
import { dayIst } from '../time';

/** Runs `fn` over `items`, `size` at a time (aggregations in parallel, not all at once). */
export async function inBatches<T, R>(items: readonly T[], size: number, fn: (t: T) => Promise<R>): Promise<R[]> {
  const out: R[] = [];
  for (let i = 0; i < items.length; i += size) out.push(...(await Promise.all(items.slice(i, i + size).map(fn))));
  return out;
}

export async function runBuildGlobeSnapshot(db: Firestore, now: Date): Promise<{ live: number; counted: number }> {
  const day = dayIst(now);
  const profiles = db.collection('profiles');
  const counts: CityCount[] = await inBatches(CITIES, 16, async (c) => {
    const [counted, live] = await Promise.all([
      profiles.where('cityId', '==', c.id).count().get(),
      profiles.where('cityId', '==', c.id).where('lastSeenDay', '==', day).count().get(),
    ]);
    return { cityId: c.id, live: live.data().count, counted: counted.data().count };
  });
  const body = buildSnapshot(day, counts);
  await db.doc('presenceSnapshot/current').set({ ...body, builtAt: FieldValue.serverTimestamp() });
  return { live: body.live, counted: body.counted };
}
