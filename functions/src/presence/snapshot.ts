// presenceSnapshot/current (07-simran §5.4) built from per-city counts, and
// the split of 07-simran §2.1 (which the app applies; tested here so the
// server's numbers are known to support it).
import { CITIES, City, stateKeyOf } from '../reference';

export interface CityCount {
  cityId: string;
  live: number;
  counted: number;
}

export interface SnapshotBody {
  day: string;
  live: number;
  counted: number;
  countries: Record<string, { l: number; c: number; s: Record<string, { l: number; c: number; k: Record<string, [number, number]> }> }>;
}

/** Steps 2–3 of §5.4: cities with a counted total of 0 are left out. */
export function buildSnapshot(day: string, counts: CityCount[], cities: readonly City[] = CITIES): SnapshotBody {
  const byId = new Map(cities.map((c) => [c.id, c]));
  const out: SnapshotBody = { day, live: 0, counted: 0, countries: {} };
  for (const cc of counts) {
    if (cc.counted <= 0) continue;
    const city = byId.get(cc.cityId);
    if (!city) continue;
    const country = (out.countries[city.country] ??= { l: 0, c: 0, s: {} });
    const stateKey = stateKeyOf(city);
    const state = (country.s[stateKey] ??= { l: 0, c: 0, k: {} });
    state.k[city.id] = [cc.live, cc.counted];
    state.l += cc.live;
    state.c += cc.counted;
    country.l += cc.live;
    country.c += cc.counted;
    out.live += cc.live;
    out.counted += cc.counted;
  }
  return out;
}

/**
 * §2.1: the dots drawn in one city for a viewer.
 * `you` is 1 in the viewer's own city; `live` loses the viewer once their own
 * attendance is marked; `here` loses the viewer while it is not.
 */
export function splitCity(
  city: { live: number; counted: number },
  viewer: { inThisCity: boolean; markedToday: boolean } | null,
): { you: number; live: number; here: number } {
  const here = city.counted - city.live;
  if (!viewer || !viewer.inThisCity) return { you: 0, live: city.live, here };
  if (viewer.markedToday) return { you: 1, live: Math.max(0, city.live - 1), here };
  return { you: 1, live: city.live, here: Math.max(0, here - 1) };
}

/** The `[live, counted]` pairs of a stored snapshot, back to counted per city. */
export function countedOf(stored: Partial<Pick<SnapshotBody, 'countries'>> | null | undefined): Map<string, number> {
  const out = new Map<string, number>();
  for (const country of Object.values(stored?.countries ?? {})) {
    for (const state of Object.values(country?.s ?? {})) {
      for (const [cityId, pair] of Object.entries(state?.k ?? {})) {
        const c = Array.isArray(pair) ? Number(pair[1]) : 0;
        if (c > 0) out.set(cityId, c);
      }
    }
  }
  return out;
}

/** Milliseconds of a stored Timestamp (or anything with toMillis), else null. */
export function millisOf(t: unknown): number | null {
  return t && typeof (t as { toMillis?: unknown }).toMillis === 'function' ? (t as { toMillis(): number }).toMillis() : null;
}

/**
 * §5.4: the stored snapshot can be served while it was built for this IST
 * day less than `seconds` ago. A snapshot from the future (a clock that went
 * back) is treated by its distance, as the group's globe does (GG6).
 */
export function snapshotIsFresh(
  stored: { day?: unknown; builtAt?: unknown } | null | undefined,
  day: string,
  now: Date,
  seconds: number,
): boolean {
  if (!stored || stored.day !== day) return false;
  const at = millisOf(stored.builtAt);
  return at !== null && Math.abs(now.getTime() - at) < seconds * 1000;
}

/**
 * §5.4: the counted totals of the stored snapshot can be reused while they
 * are younger than `seconds` and the number of profiles has not changed
 * since (a new or deleted profile counts every city again at once).
 */
export function countedIsFresh(
  stored: { countedAt?: unknown; profiles?: unknown } | null | undefined,
  profiles: number,
  now: Date,
  seconds: number,
): boolean {
  if (!stored || stored.profiles !== profiles) return false;
  const at = millisOf(stored.countedAt);
  return at !== null && Math.abs(now.getTime() - at) < seconds * 1000;
}
