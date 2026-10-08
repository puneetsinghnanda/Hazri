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
