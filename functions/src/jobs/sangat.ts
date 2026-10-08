// sangatTotals, sangatRollover and sangatProfileSync (08-sangat §7.14).
// Each is a plain function over Firestore and a time, so a test can run it
// twice (FN4, FN6); src/index.ts wraps them as Functions.
import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { AggregateField, FieldPath, FieldValue } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { addDays, dayIst } from '../time';
import { writeGoalFromTemplate } from '../sangat/goals';
import { GoalDoc, GroupDoc, MemberDoc, sortNameOf } from '../sangat/model';

/**
 * Every minute: adds each active built-in goal's shards into `total` (and
 * today's and yesterday's day totals), and marks the goal COMPLETED at its
 * target. Recomputed from the shards each time, so running twice changes
 * nothing (FN4). Uses sum() aggregations: about one read per goal per field.
 */
export async function runSangatTotals(db: Firestore, now: Date): Promise<{ goalsUpdated: number }> {
  const today = dayIst(now);
  const yesterday = addDays(today, -1);
  const groups = await db.collection('groups').where('kind', '==', 'BUILT_IN').where('status', '==', 'ACTIVE').get();
  let goalsUpdated = 0;
  for (const g of groups.docs) {
    const goalId = g.get('currentGoalId') as string | null;
    if (!goalId) continue;
    const goalRef = g.ref.collection('goals').doc(goalId);
    const goalSnap = await goalRef.get();
    if (!goalSnap.exists || goalSnap.get('status') !== 'ACTIVE') continue;
    // Three separate queries: a query with several aggregations only counts
    // documents that hold every field, and a shard may lack a day.
    const shards = goalRef.collection('shards');
    const sumOf = async (field: string | FieldPath) =>
      Math.max(0, (await shards.aggregate({ s: AggregateField.sum(field) }).get()).data().s ?? 0);
    const [total, dayToday, dayYesterday] = await Promise.all([
      sumOf('count'),
      sumOf(new FieldPath('days', today)),
      sumOf(new FieldPath('days', yesterday)),
    ]);
    const changed = await db.runTransaction(async (tx) => {
      const s = await tx.get(goalRef);
      const goal = s.data() as GoalDoc | undefined;
      if (!goal || goal.status !== 'ACTIVE') return false;
      const completes = total >= goal.target;
      const same =
        goal.total === total &&
        (goal.dayTotals?.[today] ?? 0) === dayToday &&
        (goal.dayTotals?.[yesterday] ?? 0) === dayYesterday &&
        !completes;
      if (same) return false;
      const args: unknown[] = [
        new FieldPath('dayTotals', today),
        dayToday,
        new FieldPath('dayTotals', yesterday),
        dayYesterday,
      ];
      if (completes) args.push(new FieldPath('status'), 'COMPLETED', new FieldPath('completedAt'), FieldValue.serverTimestamp());
      tx.update(goalRef, new FieldPath('total'), total, ...args);
      return true;
    });
    if (changed) goalsUpdated++;
  }
  return { goalsUpdated };
}

/** Writes goals/{goalId}/members/{key} { memberKey, contribution } for a finished built-in goal (§6.3). */
async function archiveContributions(db: Firestore, groupRef: DocumentReference, goalId: string): Promise<number> {
  const members = await groupRef.collection('members').where('contributionGoalId', '==', goalId).get();
  const writer = db.bulkWriter();
  let n = 0;
  for (const m of members.docs) {
    const c = (m.get('contribution') as number) ?? 0;
    if (c <= 0) continue;
    void writer.set(groupRef.collection('goals').doc(goalId).collection('members').doc(m.id), {
      memberKey: m.id,
      contribution: c,
    });
    n++;
  }
  await writer.close();
  return n;
}

/**
 * 00:05 IST daily: expires goals past their end day; makes those custom
 * groups INACTIVE (CG6); starts the next goal of each built-in group whose
 * goal completed or expired (BI4). Every step checks before it writes, and
 * goal ids are deterministic, so a second run does nothing (FN4).
 */
export async function runSangatRollover(
  db: Firestore,
  now: Date,
): Promise<{ expired: number; groupsEnded: number; goalsStarted: number }> {
  const today = dayIst(now);
  let expired = 0;
  let groupsEnded = 0;
  let goalsStarted = 0;

  // 1. Goals past their end day.
  const due = await db.collectionGroup('goals').where('status', '==', 'ACTIVE').where('endDay', '<', today).get();
  for (const d of due.docs) {
    const groupRef = d.ref.parent.parent;
    if (!groupRef || groupRef.parent.id !== 'groups') continue;
    const ended = await db.runTransaction(async (tx) => {
      const [gs, gl] = await Promise.all([tx.get(groupRef), tx.get(d.ref)]);
      const goal = gl.data() as GoalDoc | undefined;
      if (!goal || goal.status !== 'ACTIVE' || goal.endDay >= today) return { expired: false, ended: false };
      tx.update(d.ref, { status: 'EXPIRED' });
      const group = gs.data() as GroupDoc | undefined;
      if (group && group.kind === 'CUSTOM' && group.status === 'ACTIVE' && group.currentGoalId === d.id) {
        tx.update(groupRef, { status: 'INACTIVE', endedOn: today, endReason: 'END_DATE', updatedAt: FieldValue.serverTimestamp() });
        return { expired: true, ended: true };
      }
      return { expired: true, ended: false };
    });
    if (ended.expired) expired++;
    if (ended.ended) groupsEnded++;
  }

  // 2. Built-in groups whose goal has finished: archive, then the next goal (BI4).
  const builtIn = await db.collection('groups').where('kind', '==', 'BUILT_IN').where('status', '==', 'ACTIVE').get();
  for (const g of builtIn.docs) {
    const group = g.data() as GroupDoc;
    if (!group.currentGoalId || !group.goalTemplate) continue;
    const goalRef = g.ref.collection('goals').doc(group.currentGoalId);
    const goalSnap = await goalRef.get();
    if (!goalSnap.exists) continue;
    const goal = goalSnap.data() as GoalDoc;
    if (goal.status === 'ACTIVE') continue;
    if (!goal.archivedAt) {
      await archiveContributions(db, g.ref, goalSnap.id);
      await goalRef.update({ archivedAt: FieldValue.serverTimestamp() });
    }
    const started = await db.runTransaction(async (tx) => {
      const fresh = (await tx.get(g.ref)).data() as GroupDoc | undefined;
      if (!fresh || fresh.currentGoalId !== goalSnap.id || !fresh.goalTemplate || fresh.status !== 'ACTIVE') return false;
      writeGoalFromTemplate(tx, g.ref, fresh.goalTemplate, goal.sequence + 1, today);
      return true;
    });
    if (started) goalsStarted++;
  }
  logger.info('sangatRollover', { today, expired, groupsEnded, goalsStarted });
  return { expired, groupsEnded, goalsStarted };
}

/**
 * On a profile update: when the name changed, update `name` and `sortName`
 * on that member's rows in every group. Writes member rows, never the
 * profile that triggered it (FN3); skips rows already right (FN4).
 */
export async function runSangatProfileSync(
  db: Firestore,
  profileId: string,
  before: { name?: unknown } | undefined,
  after: { name?: unknown } | undefined,
): Promise<{ rowsUpdated: number }> {
  if (!after || typeof after.name !== 'string' || before?.name === after.name) return { rowsUpdated: 0 };
  const name = after.name;
  const key = `p_${profileId}`;
  const rows = await db.collectionGroup('members').where('memberKey', '==', key).get();
  const writer = db.bulkWriter();
  let rowsUpdated = 0;
  for (const r of rows.docs) {
    // Only groups/{g}/members/{k}; the per-goal archive rows carry no name.
    if (r.ref.parent.parent?.parent.id !== 'groups') continue;
    const m = r.data() as MemberDoc;
    if (m.name === name && m.sortName === sortNameOf(name)) continue;
    void writer.update(r.ref, { name, sortName: sortNameOf(name), updatedAt: FieldValue.serverTimestamp() });
    rowsUpdated++;
  }
  await writer.close();
  return { rowsUpdated };
}
