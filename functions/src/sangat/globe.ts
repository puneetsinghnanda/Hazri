// The group's globe (08-sangat GG1–GG9): `groups/{groupId}/globe/current`
// (ARCHITECTURE §6.4a), read and rebuilt by GET /groups/{groupId}/globe
// (7.15). One document per group, rebuilt at most every GROUP_GLOBE_SECONDS
// whoever is looking, so the cost does not grow with the people looking
// (GG6). Counts per city only: never a name or a member key (GG7).
//
// The shape, the count split, the arrivals and the staleness are pure
// functions below; the Firestore reads are at the bottom.
import type { DocumentData, DocumentReference, Firestore } from 'firebase-admin/firestore';
import { Timestamp } from 'firebase-admin/firestore';
import { CUSTOM_GROUP_MAX_MEMBERS, GROUP_ARRIVALS_MAX, GROUP_ARRIVALS_MINUTES, GROUP_GLOBE_SECONDS } from '../config';
import { inBatches } from '../jobs/globe';
import { CITIES, isCityId } from '../reference';
import { dayIst, toIso } from '../time';
import { amountFor, ItemKind } from './counting';
import type { GoalDoc, GroupDoc } from './model';

/** `[today, members]`: active members with this profile city, and how many of them added today (GG3). */
export type CityPair = [number, number];

export interface Arrival {
  cityId: string | null;
  /** When the server received it: newest first, and what lets the app play only the new ones (GG4). */
  at: Timestamp;
  /** What it added to the goal: 1 for a bani, its whole minutes for Naam Simran (CT1). */
  amount: number;
}

/** The stored document (§6.4a). */
export interface GroupGlobeDoc {
  goalId: string | null;
  day: string;
  cities: Record<string, CityPair>;
  unplaced: { today: number; members: number };
  recent: Arrival[];
  builtAt: Timestamp;
}

/** The reply of 7.15. */
export interface GroupGlobeDto {
  day: string;
  builtAt: string;
  cities: Record<string, CityPair>;
  unplaced: { today: number; members: number };
  recent: Array<{ cityId: string | null; at: string; amount: number }>;
}

export interface MemberGlobeRow {
  cityId?: unknown;
  lastAddDay?: unknown;
}

/**
 * A custom group (§6.4a): its active member rows, counted per city. A row
 * with no city, or a city the reference list does not have (and so the app
 * could not place), is `unplaced` (GG2: not drawn, still in the key).
 */
export function tallyMembers(
  rows: readonly MemberGlobeRow[],
  day: string,
  isCity: (id: string) => boolean = isCityId,
): Pick<GroupGlobeDoc, 'cities' | 'unplaced'> {
  const cities: Record<string, CityPair> = {};
  const unplaced = { today: 0, members: 0 };
  for (const r of rows) {
    const today = r.lastAddDay === day ? 1 : 0;
    if (typeof r.cityId === 'string' && isCity(r.cityId)) {
      const pair = (cities[r.cityId] ??= [0, 0]);
      pair[0] += today;
      pair[1] += 1;
    } else {
      unplaced.today += today;
      unplaced.members += 1;
    }
  }
  return { cities, unplaced };
}

/**
 * A built-in group (§6.4a): per-city counts from aggregations, and
 * `unplaced` as what the group's member count and the day's count leave
 * over once the placed are taken off. Never negative: `memberCount` is
 * maintained by increments and the counts are read a moment apart.
 */
export function fromCityCounts(
  counts: ReadonlyArray<{ cityId: string; members: number; today: number }>,
  memberCount: number,
  todayAll: number,
): Pick<GroupGlobeDoc, 'cities' | 'unplaced'> {
  const cities: Record<string, CityPair> = {};
  let placed = 0;
  let placedToday = 0;
  for (const c of counts) {
    if (c.members <= 0) continue;
    const today = Math.min(c.today, c.members);
    cities[c.cityId] = [today, c.members];
    placed += c.members;
    placedToday += today;
  }
  const members = Math.max(0, memberCount - placed);
  return { cities, unplaced: { members, today: Math.min(members, Math.max(0, todayAll - placedToday)) } };
}

/** A `contributions` document as the arrivals read it (§6.4). */
export interface ContributionRow {
  retracted?: unknown;
  countedIn?: unknown;
  cityId?: unknown;
  createdAt?: unknown;
  kind?: unknown;
  baniId?: unknown;
  durationS?: unknown;
}

/**
 * GG4: from contributions newest first, the first `max` that were counted
 * toward this goal (`countedIn` holds `{groupId}/{goalId}`) and not taken
 * back, with what each added.
 */
export function pickArrivals(
  rows: readonly ContributionRow[],
  groupId: string,
  goalId: string,
  goal: Pick<GoalDoc, 'type' | 'baniId'>,
  max: number = GROUP_ARRIVALS_MAX,
): Arrival[] {
  const key = `${groupId}/${goalId}`;
  const out: Arrival[] = [];
  for (const r of rows) {
    if (out.length >= max) break;
    if (r.retracted === true) continue;
    if (!Array.isArray(r.countedIn) || !r.countedIn.includes(key)) continue;
    if (!(r.createdAt instanceof Timestamp)) continue;
    const amount = amountFor(
      {
        kind: r.kind as ItemKind,
        baniId: typeof r.baniId === 'string' ? r.baniId : null,
        durationS: typeof r.durationS === 'number' ? r.durationS : null,
      },
      goal,
    );
    if (amount <= 0) continue;
    out.push({ cityId: typeof r.cityId === 'string' ? r.cityId : null, at: r.createdAt, amount });
  }
  return out;
}

/**
 * GG6: the stored globe can be served while it is younger than
 * GROUP_GLOBE_SECONDS and was built for this goal and this IST day.
 */
export function globeIsFresh(
  stored: Pick<GroupGlobeDoc, 'goalId' | 'day' | 'builtAt'> | null,
  want: { goalId: string | null; day: string },
  now: Date,
  seconds: number = GROUP_GLOBE_SECONDS,
): boolean {
  if (!stored || !(stored.builtAt instanceof Timestamp)) return false;
  if ((stored.goalId ?? null) !== want.goalId || stored.day !== want.day) return false;
  const age = now.getTime() - stored.builtAt.toMillis();
  return Math.abs(age) < seconds * 1000;
}

/** The reply of 7.15. `ended` (GG9) drops the arrivals: an ended goal has none and no line. */
export function globeDto(doc: GroupGlobeDoc, ended: boolean): GroupGlobeDto {
  return {
    day: doc.day,
    builtAt: toIso(doc.builtAt) ?? '',
    cities: doc.cities ?? {},
    unplaced: doc.unplaced ?? { today: 0, members: 0 },
    recent: ended
      ? []
      : (doc.recent ?? []).map((a) => ({ cityId: a.cityId ?? null, at: toIso(a.at) ?? '', amount: a.amount })),
  };
}

// --- Firestore ---------------------------------------------------------------

/** Custom: one read of the active member rows, two fields each (§6.4a). */
async function customCounts(groupRef: DocumentReference, day: string) {
  const snap = await groupRef
    .collection('members')
    .where('status', '==', 'ACTIVE')
    .select('cityId', 'lastAddDay')
    .limit(CUSTOM_GROUP_MAX_MEMBERS)
    .get();
  return tallyMembers(
    snap.docs.map((d) => d.data() as MemberGlobeRow),
    day,
  );
}

/**
 * Built-in, too large to read: count() per reference city (members, then
 * today only where there are any), and one count of everybody who added
 * today for `unplaced`. Batched as buildGlobeSnapshot is.
 */
async function builtInCounts(groupRef: DocumentReference, g: GroupDoc, day: string) {
  const active = groupRef.collection('members').where('status', '==', 'ACTIVE');
  if ((g.memberCount ?? 0) <= 0) return fromCityCounts([], 0, 0);
  const counts = await inBatches(CITIES, 16, async (c) => {
    const inCity = active.where('cityId', '==', c.id);
    const members = (await inCity.count().get()).data().count;
    const today = members > 0 ? (await inCity.where('lastAddDay', '==', day).count().get()).data().count : 0;
    return { cityId: c.id, members, today };
  });
  const todayAll = (await active.where('lastAddDay', '==', day).count().get()).data().count;
  return fromCityCounts(counts, g.memberCount ?? 0, todayAll);
}

/** GG4: one query, newest first, 3 × the most kept, so retracted rows and other goals cannot starve it. */
async function readArrivals(
  db: Firestore,
  groupId: string,
  goal: { id: string; doc: GoalDoc },
  now: Date,
): Promise<Arrival[]> {
  const since = Timestamp.fromMillis(now.getTime() - GROUP_ARRIVALS_MINUTES * 60_000);
  const snap = await db
    .collection('contributions')
    .where('groupIds', 'array-contains', groupId)
    .where('createdAt', '>=', since)
    .orderBy('createdAt', 'desc')
    .limit(3 * GROUP_ARRIVALS_MAX)
    .get();
  return pickArrivals(
    snap.docs.map((d) => d.data() as DocumentData as ContributionRow),
    groupId,
    goal.id,
    goal.doc,
  );
}

/** Builds the document from scratch. Recomputed every time, so two builds at once write the same numbers (FN4). */
export async function buildGroupGlobe(
  db: Firestore,
  groupRef: DocumentReference,
  g: GroupDoc,
  goal: { id: string; doc: GoalDoc } | null,
  ended: boolean,
  now: Date,
): Promise<GroupGlobeDoc> {
  const day = dayIst(now);
  const [counts, recent] = await Promise.all([
    g.kind === 'BUILT_IN' ? builtInCounts(groupRef, g, day) : customCounts(groupRef, day),
    goal && !ended ? readArrivals(db, groupRef.id, goal, now) : Promise.resolve([] as Arrival[]),
  ]);
  return { goalId: goal?.id ?? g.currentGoalId ?? null, day, ...counts, recent, builtAt: Timestamp.fromDate(now) };
}

/**
 * 7.15 after access is checked: the stored globe when fresh (GG6), else a
 * new one, stored. An ended goal (GG9) keeps the globe it last had, without
 * arrivals; with none stored, one is built once.
 *
 * Reads: the stored globe; the goal only when it has to be built or the
 * goal may have ended; the counts and arrivals only on a rebuild.
 */
export async function groupGlobe(
  db: Firestore,
  groupRef: DocumentReference,
  g: GroupDoc,
  now: Date,
): Promise<GroupGlobeDto> {
  const ref = groupRef.collection('globe').doc('current');
  const snap = await ref.get();
  const stored = snap.exists ? (snap.data() as GroupGlobeDoc) : null;
  const goalId = g.currentGoalId ?? null;
  const sameGoal = stored !== null && (stored.goalId ?? null) === goalId;
  const groupEnded = g.status !== 'ACTIVE';
  if (groupEnded && sameGoal) return globeDto(stored, true);
  if (!groupEnded && globeIsFresh(stored, { goalId, day: dayIst(now) }, now)) return globeDto(stored as GroupGlobeDoc, false);

  const goalSnap = goalId ? await groupRef.collection('goals').doc(goalId).get() : null;
  const goal = goalSnap?.exists ? { id: goalSnap.id, doc: goalSnap.data() as GoalDoc } : null;
  // A built-in goal completes mid-day while its group stays active (BI4).
  const ended = groupEnded || (goal !== null && goal.doc.status !== 'ACTIVE');
  if (ended && sameGoal) return globeDto(stored, true);

  const built = await buildGroupGlobe(db, groupRef, g, goal, ended, now);
  await ref.set(built);
  return globeDto(built, ended);
}
