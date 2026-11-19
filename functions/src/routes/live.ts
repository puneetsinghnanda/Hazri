// Live sangat (15-live-sangat.md, ARCHITECTURE §6.8): three always-on groups
// whose recordings play on the phone. The server keeps who joined, who is
// listening and the minutes listened; nothing here streams anything.
//
// Cost: the app reads GET /live, which is one document, rebuilt at most every
// two minutes from the listening marks of the last ten minutes, the minute
// counters (sharded, so a thousand listeners never write one document more
// than once a second) and the members. Every write needs a profile (LS15).
import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import { Router } from 'express';
import { callerUid } from '../auth';
import type { Deps } from '../deps';
import { ApiError } from '../errors';
import { h, param } from '../http';
import { ownerProfileId, requireProfile } from '../profile/profile';
import { displayNameOf } from '../quiz/model';
import { dayIst } from '../time';

export const LIVE_GROUPS = ['naam-simran', 'mool-mantar', 'chaupai-sahib'] as const;
export type LiveGroupId = (typeof LIVE_GROUPS)[number];

/** A listening mark every five minutes while a page plays (LS15). */
export const LIVE_MARK_MINUTES = 5;
/** A listener counts as listening for this long after a mark (LS7; owner,
 * 2026-11-19: a day, then they drop off the count). */
export const LIVE_WINDOW_SECONDS = 24 * 60 * 60;
/** GET /live rebuilds its snapshot at most this often. */
export const LIVE_SNAPSHOT_SECONDS = 120;
const SHARDS = 10;
const JOINS_KEPT = 5;
const MEMBERS_SHOWN = 20;
const MEMBERS_READ = 500;
const CITIES_SHOWN = 60;
/** The listening marks read for the cities; the count itself is a count(). */
const LISTENS_READ = 300;

const isLive = (id: string): id is LiveGroupId => (LIVE_GROUPS as readonly string[]).includes(id);
const monthOf = (day: string) => day.slice(0, 7);

export interface LiveJoin {
  name: string;
  cityId: string | null;
  at: string;
}

export interface LiveMemberRow {
  name: string;
  cityId: string | null;
  minutesMonth: number;
}

export interface LiveGroupSnapshot {
  listening: number;
  cities: number;
  /** The cities with a listener now, for the globe's dots (LS1); at most 60. */
  cityIds: string[];
  members: number;
  minutesToday: number;
  minutesMonth: number;
  joins: LiveJoin[];
  memberRows: LiveMemberRow[];
}

interface MemberDoc {
  groupId: LiveGroupId;
  profileId: string;
  name: string;
  cityId: string | null;
  joinedAt: Timestamp;
  minutes: Record<string, number>;
}

const NotLive = () => new ApiError(404, 'NOT_FOUND', 'No such live group');

export function liveRouter(deps: Deps): Router {
  const { db, clock } = deps;
  const r = Router();

  // GET /live: the three groups as everybody sees them, and the caller's own
  // joins and minutes when there is a profile.
  r.get(
    '/api/v1/live',
    h(async (_req, res) => {
      const uid = callerUid(res);
      const now = clock.now();
      const snap = await readSnapshot(db, now);
      const profileId = await ownerProfileId(db, uid);
      const mine: Record<string, { joined: boolean; myMinutesMonth: number; youCounted: boolean }> = {};
      if (profileId) {
        const members = LIVE_GROUPS.map((g) => db.doc(`liveMembers/${g}_${profileId}`));
        const listens = LIVE_GROUPS.map((g) => listenRef(db, g, profileId));
        const docs = await db.getAll(...members, ...listens);
        const month = monthOf(dayIst(now));
        const builtAtMs = Date.parse(snap.builtAt);
        LIVE_GROUPS.forEach((g, i) => {
          const d = docs[i];
          const l = docs[LIVE_GROUPS.length + i];
          const lastAt = l.exists ? (l.get('lastAt') as Timestamp).toMillis() : 0;
          mine[g] = {
            joined: d.exists,
            myMinutesMonth: d.exists ? ((d.get('minutes') as Record<string, number>)?.[month] ?? 0) : 0,
            // The snapshot already counts the caller: their mark is inside the
            // window and was there when it was built. The app adds itself
            // otherwise (LS7b).
            youCounted: lastAt > 0 && lastAt < builtAtMs && builtAtMs - lastAt < LIVE_WINDOW_SECONDS * 1000,
          };
        });
      }
      res.status(200).json({
        builtAt: snap.builtAt,
        groups: LIVE_GROUPS.map((id) => ({ id, ...snap.groups[id], ...(mine[id] ?? { joined: false, myMinutesMonth: null, youCounted: false }) })),
      });
    }),
  );

  // POST /live/:id/join: a profile joins; idempotent. Shown in "joined from"
  // to everybody (LS8, no switch to hide, owner 2026-11-18).
  r.post(
    '/api/v1/live/:id/join',
    h(async (req, res) => {
      const uid = callerUid(res);
      const id = param(req, 'id');
      if (!isLive(id)) throw NotLive();
      const p = await requireProfile(db, uid);
      const ref = db.doc(`liveMembers/${id}_${p.doc.profileId}`);
      const name = displayNameOf(p.doc.name);
      const now = clock.now();
      await db.runTransaction(async (tx) => {
        const [member, group] = await Promise.all([tx.get(ref), tx.get(db.doc(`liveGroups/${id}`))]);
        if (member.exists) return;
        const joins = ((group.get('joins') as LiveJoin[] | undefined) ?? []).slice(0, JOINS_KEPT - 1);
        tx.set(ref, {
          groupId: id,
          profileId: p.doc.profileId,
          name,
          cityId: p.doc.cityId ?? null,
          joinedAt: Timestamp.fromDate(now),
          minutes: {},
        } satisfies MemberDoc);
        tx.set(db.doc(`liveGroups/${id}`), { joins: [{ name, cityId: p.doc.cityId ?? null, at: now.toISOString() }, ...joins] }, { merge: true });
      });
      await invalidateSnapshot(db);
      res.status(200).json({ result: 'JOINED' });
    }),
  );

  // POST /live/:id/leave
  r.post(
    '/api/v1/live/:id/leave',
    h(async (req, res) => {
      const uid = callerUid(res);
      const id = param(req, 'id');
      if (!isLive(id)) throw NotLive();
      const p = await requireProfile(db, uid);
      await db.doc(`liveMembers/${id}_${p.doc.profileId}`).delete();
      await invalidateSnapshot(db);
      res.status(200).json({ result: 'LEFT' });
    }),
  );

  // POST /live/:id/listen: the listening mark (LS15), every five minutes while
  // the page plays. It counts the caller as listening for ten minutes and
  // adds five minutes to the sangat's, and to theirs if they are a member.
  // A mark sooner than four minutes after the last adds nothing.
  r.post(
    '/api/v1/live/:id/listen',
    h(async (req, res) => {
      const uid = callerUid(res);
      const id = param(req, 'id');
      if (!isLive(id)) throw NotLive();
      const p = await requireProfile(db, uid);
      const now = clock.now();
      const day = dayIst(now);
      const month = monthOf(day);
      const mark = listenRef(db, id, p.doc.profileId);
      const memberRef = db.doc(`liveMembers/${id}_${p.doc.profileId}`);
      let counted = false;
      await db.runTransaction(async (tx) => {
        const [last, member] = await Promise.all([tx.get(mark), tx.get(memberRef)]);
        const lastAt = last.exists ? (last.get('lastAt') as Timestamp).toMillis() : 0;
        tx.set(mark, { groupId: id, cityId: p.doc.cityId ?? null, lastAt: Timestamp.fromDate(now) });
        if (now.getTime() - lastAt < (LIVE_MARK_MINUTES - 1) * 60_000) return;
        counted = true;
        const shard = Math.floor(Math.random() * SHARDS);
        const add = FieldValue.increment(LIVE_MARK_MINUTES);
        tx.set(db.doc(`liveMinutes/${id}_${day}_${shard}`), { groupId: id, period: day, minutes: add }, { merge: true });
        tx.set(db.doc(`liveMinutes/${id}_${month}_${shard}`), { groupId: id, period: month, minutes: add }, { merge: true });
        if (member.exists) tx.update(memberRef, { [`minutes.${month}`]: add });
      });
      res.status(200).json({ result: counted ? 'COUNTED' : 'TOO_SOON', nextInSeconds: LIVE_MARK_MINUTES * 60 });
    }),
  );

  return r;
}

/** A listener's last mark in a live group. */
function listenRef(db: Firestore, groupId: string, profileId: string) {
  return db.doc(`liveGroups/${groupId}/listens/${profileId}`);
}

/** Join and leave make the next GET /live rebuild, so a new member shows at
 * once rather than up to two minutes later (owner, 2026-11-19). */
async function invalidateSnapshot(db: Firestore): Promise<void> {
  await db.doc('liveSnapshot/current').set({ builtAt: Timestamp.fromMillis(0) }, { merge: true });
}

/** The snapshot every reader shares, rebuilt when older than two minutes. */
async function readSnapshot(db: Firestore, now: Date): Promise<{ builtAt: string; groups: Record<LiveGroupId, LiveGroupSnapshot> }> {
  const ref = db.doc('liveSnapshot/current');
  const snap = await ref.get();
  const builtAt = snap.exists ? (snap.get('builtAt') as Timestamp).toMillis() : 0;
  if (snap.exists && now.getTime() - builtAt < LIVE_SNAPSHOT_SECONDS * 1000) {
    return { builtAt: new Date(builtAt).toISOString(), groups: snap.get('groups') as Record<LiveGroupId, LiveGroupSnapshot> };
  }
  const groups = await buildSnapshot(db, now);
  await ref.set({ builtAt: Timestamp.fromDate(now), groups });
  return { builtAt: now.toISOString(), groups };
}

export async function buildSnapshot(db: Firestore, now: Date): Promise<Record<LiveGroupId, LiveGroupSnapshot>> {
  const day = dayIst(now);
  const month = monthOf(day);
  const cutoff = Timestamp.fromMillis(now.getTime() - LIVE_WINDOW_SECONDS * 1000);
  const out = {} as Record<LiveGroupId, LiveGroupSnapshot>;
  for (const id of LIVE_GROUPS) {
    // One collection per group, so a range on lastAt needs no composite
    // index: count() for the number (a read per thousand), and the newest
    // few hundred marks for the cities.
    const recent = db.collection(`liveGroups/${id}/listens`).where('lastAt', '>=', cutoff);
    const [listening, here] = await Promise.all([
      recent.count().get(),
      recent.orderBy('lastAt', 'desc').limit(LISTENS_READ).get(),
    ]);
    const shardRefs = [day, month].flatMap((period) =>
      Array.from({ length: SHARDS }, (_, s) => db.doc(`liveMinutes/${id}_${period}_${s}`)));
    const [shards, group, members, count] = await Promise.all([
      db.getAll(...shardRefs),
      db.doc(`liveGroups/${id}`).get(),
      db.collection('liveMembers').where('groupId', '==', id).limit(MEMBERS_READ).get(),
      db.collection('liveMembers').where('groupId', '==', id).count().get(),
    ]);
    const sum = (period: string) =>
      shards.filter((s) => s.exists && s.get('period') === period).reduce((a, s) => a + ((s.get('minutes') as number) ?? 0), 0);
    const cityIds = [...new Set(here.docs.map((d) => d.get('cityId') as string | null).filter((c): c is string => !!c))];
    out[id] = {
      listening: listening.data().count,
      cities: cityIds.length,
      cityIds: cityIds.slice(0, CITIES_SHOWN),
      members: count.data().count,
      minutesToday: sum(day),
      minutesMonth: sum(month),
      joins: ((group.get('joins') as LiveJoin[] | undefined) ?? []).slice(0, 3),
      memberRows: members.docs
        .map((d) => d.data() as MemberDoc)
        .sort((a, b) => a.name.localeCompare(b.name))
        .slice(0, MEMBERS_SHOWN)
        .map((m) => ({ name: m.name, cityId: m.cityId, minutesMonth: m.minutes?.[month] ?? 0 })),
    };
  }
  return out;
}

