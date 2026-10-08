// sangatMilestone and sangatDispatch (02-notifications §8.2, ARCHITECTURE §7.2).
import type { DocumentData, Firestore, QueryDocumentSnapshot } from 'firebase-admin/firestore';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { dayAtOffset, localMinuteOfDay, offsetRangesForLocalHour, utcOffsetMinutes } from '../time';
import { GoalDoc, GroupDoc, MemberDoc, daysLeftOf, pctOf } from '../sangat/model';
import { asLocale, groupNameFor, Locale, renderSangat, SangatKind, someone, unitFor } from '../notifications/render';
import { chooseDigest, heldForThisMorning, isDaytime, milestonesCrossed } from '../notifications/rules';
import { isDeadTokenError, Messenger, PushMessage } from '../notifications/messenger';

export interface TokenDoc {
  profileId: string;
  token: string;
  locale: string;
  tz: string;
  utcOffsetMin: number;
  groupIds?: string[];
}

function push(t: TokenDoc, kind: SangatKind, groupId: string, values: Record<string, string | number>): PushMessage {
  const locale = asLocale(t.locale);
  const { title, body } = renderSangat(kind, locale, values);
  // FM2 data; FM5: no member names, profile ids or emails beyond the text of 5.5-E.
  return { token: t.token, title, body, data: { kind: `SANGAT_${kind.toUpperCase()}`, groupId, route: `/sangat/${groupId}` } };
}

/** Sends, then deletes every token FCM reports as unregistered or invalid (FM4). */
async function sendAll(db: Firestore, messenger: Messenger, messages: PushMessage[], tokenDocIdOf: Map<string, string>): Promise<number> {
  if (messages.length === 0) return 0;
  const results = await messenger.sendEach(messages);
  let sent = 0;
  const dead = new Set<string>();
  results.forEach((r, i) => {
    if (r.ok) sent++;
    else if (isDeadTokenError(r.errorCode)) dead.add(messages[i].token);
  });
  for (const token of dead) {
    const id = tokenDocIdOf.get(token);
    if (id) await db.doc(`fcmTokens/${id}`).delete();
  }
  return sent;
}

function milestoneValues(group: GroupDoc, goal: Pick<GoalDoc, 'type' | 'baniId' | 'target' | 'endDay'>, total: number, pct: number, today: string, locale: Locale) {
  return {
    group: groupNameFor(group, locale),
    pct,
    done: total,
    target: goal.target,
    bani: unitFor(goal, locale),
    daysLeft: daysLeftOf(goal.endDay, today),
  };
}

/** Tokens of the group's members with a profile; verified against memberships so a stale token list cannot leak a push. */
async function memberTokens(db: Firestore, groupId: string): Promise<Array<{ id: string; t: TokenDoc }>> {
  const snap = await db.collection('fcmTokens').where('groupIds', 'array-contains', groupId).get();
  const docs = snap.docs;
  const out: Array<{ id: string; t: TokenDoc }> = [];
  for (let i = 0; i < docs.length; i += 300) {
    const chunk = docs.slice(i, i + 300);
    const ms = await db.getAll(...chunk.map((d) => db.doc(`memberships/p_${d.get('profileId') as string}`)));
    chunk.forEach((d, j) => {
      const ids = (ms[j].get('groupIds') as string[] | undefined) ?? [];
      if (ids.includes(groupId)) out.push({ id: d.id, t: d.data() as TokenDoc });
    });
  }
  return out;
}

/**
 * sangatMilestone: on an update of a goal (the group's progress document),
 * when the percentage crosses 25, 50, 75 or 100, create
 * sangatNotices/{groupId}_{goalId}_{milestone} if absent (so it is sent once),
 * then send 5.5-B (or 5.5-D at 100) to members whose local time is 07:00–20:59.
 * The rest wait for sangatDispatch at their 07:00. Writes only sangatNotices
 * and deletes dead tokens; never the goal (FN3).
 */
export async function runSangatMilestone(
  db: Firestore,
  messenger: Messenger,
  groupId: string,
  goalId: string,
  before: DocumentData | undefined,
  after: DocumentData | undefined,
  now: Date,
): Promise<{ notices: number; sent: number }> {
  if (!before || !after) return { notices: 0, sent: 0 };
  const target = (after.target as number) ?? 0;
  const crossed = milestonesCrossed((before.total as number) ?? 0, (after.total as number) ?? 0, target);
  if (crossed.length === 0) return { notices: 0, sent: 0 };
  const groupSnap = await db.doc(`groups/${groupId}`).get();
  const group = groupSnap.data() as GroupDoc | undefined;
  if (!group || group.status === 'DISABLED') return { notices: 0, sent: 0 };

  // Create-if-absent for every milestone crossed; only the highest new one is sent.
  const created: number[] = [];
  for (const m of crossed) {
    try {
      await db.doc(`sangatNotices/${groupId}_${goalId}_${m}`).create({
        groupId,
        goalId,
        milestone: m,
        total: after.total,
        target,
        createdAt: Timestamp.fromDate(now),
      });
      created.push(m);
    } catch (err) {
      if ((err as { code?: number }).code !== 6) throw err; // 6 = ALREADY_EXISTS: sent before
    }
  }
  if (created.length === 0) return { notices: 0, sent: 0 };
  const milestone = Math.max(...created);
  const kind: SangatKind = milestone === 100 ? 'Complete' : 'Milestone';
  const today = dayAtOffset(now, 330);
  const tokens = await memberTokens(db, groupId);
  const messages: PushMessage[] = [];
  const idOf = new Map<string, string>();
  for (const { id, t } of tokens) {
    if (!isDaytime(now, t.utcOffsetMin)) continue;
    const locale = asLocale(t.locale);
    const goal = after as GoalDoc;
    messages.push(push(t, kind, groupId, milestoneValues(group, goal, (after.total as number) ?? 0, milestone, today, locale)));
    idOf.set(t.token, id);
  }
  const sent = await sendAll(db, messenger, messages, idOf);
  return { notices: created.length, sent };
}

/** The hour sangatDispatch runs for, floored, so a late start still means "this hour". */
export function hourKey(now: Date): { at: Date; key: string } {
  const at = new Date(Math.floor(now.getTime() / 3_600_000) * 3_600_000);
  return { at, key: at.toISOString().slice(0, 13) };
}

async function tokensAtLocalHour(db: Firestore, at: Date, hour: number): Promise<QueryDocumentSnapshot[]> {
  const out: QueryDocumentSnapshot[] = [];
  for (const [from, to] of offsetRangesForLocalHour(at, hour)) {
    const snap = await db.collection('fcmTokens').where('utcOffsetMin', '>=', from).where('utcOffsetMin', '<', to).get();
    out.push(...snap.docs);
  }
  return out;
}

/** Re-reads the zone's offset (DST moves it); returns null when the token is not at `hour` after all. */
async function confirmOffset(d: QueryDocumentSnapshot, at: Date, hour: number): Promise<number | null> {
  const t = d.data() as TokenDoc;
  const offset = utcOffsetMinutes(t.tz, at) ?? t.utcOffsetMin;
  if (offset !== t.utcOffsetMin) await d.ref.update({ utcOffsetMin: offset });
  return Math.floor(localMinuteOfDay(at, offset) / 60) === hour ? offset : null;
}

/**
 * sangatDispatch, hourly at :00 (SG2, SG3, SG4, SG7, SG8). A run marker
 * `sangatDispatchRuns/{hour}` is created first, so a retried run of the same
 * hour sends nothing twice (at most once; README decisions).
 */
export async function runSangatDispatch(db: Firestore, messenger: Messenger, now: Date): Promise<{ sent: number; skipped: boolean }> {
  const { at, key } = hourKey(now);
  try {
    await db.doc(`sangatDispatchRuns/${key}`).create({ startedAt: FieldValue.serverTimestamp() });
  } catch (err) {
    if ((err as { code?: number }).code === 6) return { sent: 0, skipped: true };
    throw err;
  }
  const groups = new Map<string, { group: GroupDoc | null; goal: GoalDoc | null }>();
  const groupInfo = async (groupId: string) => {
    let g = groups.get(groupId);
    if (!g) {
      const gs = await db.doc(`groups/${groupId}`).get();
      const group = gs.exists ? (gs.data() as GroupDoc) : null;
      let goal: GoalDoc | null = null;
      if (group?.currentGoalId) {
        const s = await gs.ref.collection('goals').doc(group.currentGoalId).get();
        goal = s.exists ? (s.data() as GoalDoc) : null;
      }
      g = { group, goal };
      groups.set(groupId, g);
    }
    return g;
  };
  const membershipsOf = async (profileId: string) =>
    ((await db.doc(`memberships/p_${profileId}`).get()).get('groupIds') as string[] | undefined) ?? [];

  const messages: PushMessage[] = [];
  const idOf = new Map<string, string>();

  // 21:00: the digest (A), final days (C), or group ended (F).
  for (const d of await tokensAtLocalHour(db, at, 21)) {
    const offset = await confirmOffset(d, at, 21);
    if (offset === null) continue;
    const t = d.data() as TokenDoc;
    const locale = asLocale(t.locale);
    const localDate = dayAtOffset(at, offset);
    for (const groupId of await membershipsOf(t.profileId)) {
      const { group, goal } = await groupInfo(groupId);
      if (!group || !goal) continue;
      const choice = chooseDigest(group, goal, localDate);
      if (!choice) continue;
      const base = { group: groupNameFor(group, locale), target: goal.target, bani: unitFor(goal, locale) };
      if (choice.kind === 'Digest') {
        messages.push(push(t, 'Digest', groupId, { ...base, count: choice.count, pct: pctOf(goal.total, goal.target) }));
      } else if (choice.kind === 'Final') {
        messages.push(push(t, 'Final', groupId, { ...base, daysLeft: choice.daysLeft, remaining: choice.remaining }));
      } else {
        messages.push(push(t, 'Ended', groupId, { ...base, total: goal.total }));
      }
      idOf.set(t.token, d.id);
    }
  }

  // 20:00: creators hear who joined since the last time (SG7, 5.5-E).
  for (const d of await tokensAtLocalHour(db, at, 20)) {
    const offset = await confirmOffset(d, at, 20);
    if (offset === null) continue;
    const t = d.data() as TokenDoc;
    const locale = asLocale(t.locale);
    const myKey = `p_${t.profileId}`;
    for (const groupId of await membershipsOf(t.profileId)) {
      const { group } = await groupInfo(groupId);
      if (!group || group.kind !== 'CUSTOM' || group.creatorKey !== myKey || group.status !== 'ACTIVE') continue;
      const groupRef = db.doc(`groups/${groupId}`);
      // At most once: move the mark first, then send.
      const joined = await db.runTransaction(async (tx) => {
        const fresh = (await tx.get(groupRef)).data() as GroupDoc | undefined;
        const since = fresh?.joinNoticeAt ?? fresh?.createdAt ?? Timestamp.fromMillis(0);
        const q = groupRef.collection('members').where('joinedAt', '>', since).orderBy('joinedAt');
        const rows = (await tx.get(q)).docs.map((m) => m.data() as MemberDoc).filter((m) => m.status === 'ACTIVE' && m.role === 'MEMBER');
        tx.update(groupRef, { joinNoticeAt: Timestamp.fromDate(at) });
        return { rows, memberCount: fresh?.memberCount ?? group.memberCount };
      });
      if (joined.rows.length === 0) continue;
      const first = joined.rows[0].name ?? someone(locale);
      const values = { name: first, others: joined.rows.length - 1, group: groupNameFor(group, locale), count: joined.memberCount };
      messages.push(push(t, joined.rows.length === 1 ? 'Joined' : 'JoinedMany', groupId, values));
      idOf.set(t.token, d.id);
    }
  }

  // 07:00: milestone notices held overnight (SG3).
  for (const d of await tokensAtLocalHour(db, at, 7)) {
    const offset = await confirmOffset(d, at, 7);
    if (offset === null) continue;
    const t = d.data() as TokenDoc;
    const locale = asLocale(t.locale);
    const ids = await membershipsOf(t.profileId);
    for (let i = 0; i < ids.length; i += 30) {
      const chunk = ids.slice(i, i + 30);
      const notices = await db
        .collection('sangatNotices')
        .where('groupId', 'in', chunk)
        .where('createdAt', '>=', Timestamp.fromMillis(at.getTime() - 11 * 3_600_000))
        .get();
      // One message per group: the highest milestone held for this morning.
      const best = new Map<string, DocumentData>();
      for (const n of notices.docs) {
        const created = (n.get('createdAt') as Timestamp).toDate();
        if (!heldForThisMorning(created, at, offset)) continue;
        const prev = best.get(n.get('groupId') as string);
        if (!prev || (prev.milestone as number) < (n.get('milestone') as number)) best.set(n.get('groupId') as string, n.data());
      }
      for (const [groupId, n] of best) {
        const { group, goal } = await groupInfo(groupId);
        if (!group || !goal || group.status === 'DISABLED') continue;
        const m = n.milestone as number;
        const today = dayAtOffset(at, 330);
        messages.push(push(t, m === 100 ? 'Complete' : 'Milestone', groupId, milestoneValues(group, goal, n.total as number, m, today, locale)));
        idOf.set(t.token, d.id);
      }
    }
  }

  const sent = await sendAll(db, messenger, messages, idOf);
  logger.info('sangatDispatch', { hour: key, messages: messages.length, sent });
  return { sent, skipped: false };
}
