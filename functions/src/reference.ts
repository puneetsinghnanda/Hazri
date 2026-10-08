// Reference lists generated from the app's own sources (never typed):
// cities.json from tools/content_pipeline/cities.json (scripts/gen-cities.mjs,
// 07-simran.md §5.1) and banis.json from content.db (scripts/gen_banis.py).
import citiesJson from './cities.json';
import banisJson from './banis.json';

export interface City {
  id: string;
  country: string;
  state: string | null;
}
export interface Bani {
  id: string;
  en: string;
  pa: string;
  hi: string;
  defaultSlot: string;
}

export const CITIES: readonly City[] = citiesJson as City[];
export const BANIS: readonly Bani[] = banisJson as Bani[];

const cityIds = new Set(CITIES.map((c) => c.id));
const baniById = new Map(BANIS.map((b) => [b.id, b]));

export function isCityId(id: string): boolean {
  return cityIds.has(id);
}
export function isBaniId(id: unknown): id is string {
  return typeof id === 'string' && baniById.has(id);
}
export function baniName(id: string, locale: string): string {
  const b = baniById.get(id);
  if (!b) return id;
  return locale === 'pa' ? b.pa : locale === 'hi' ? b.hi : b.en;
}
/** The state key a city is filed under on the globe (`<country>-XX` until the pipeline adds states). */
export function stateKeyOf(c: City): string {
  return c.state ?? `${c.country}-XX`;
}
