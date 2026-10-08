// POST /sangat/contributions (08-sangat 7.12): one transaction per outbox row,
// idempotent by `contributions/{memberKey}_{id}` (§6.4).
import type { DocumentReference, DocumentSnapshot, Firestore, Transaction } from 'firebase-admin/firestore';
import { FieldPath, FieldValue } from 'firebase-admin/firestore';
import { BUILT_IN_SHARDS } from '../config';
import { dayIst } from '../time';
import { capDocId, contributionDocId, countDecision, groupDayOf, OutboxItem } from './counting';
import type { GoalDoc, GroupDoc, MemberDoc } from './model';

type Rand = (n: number) => number;
const defaultRand: Rand = (n) => Math.floor(Math.random() * n);

interface Target {
  groupId: string;
  groupRef: DocumentReference;
  group: GroupDoc;
  goalId: string;
  goalRef: DocumentReference;
  goal: GoalDoc;
  memberRef: DocumentReference;
  member: MemberDoc | null;
  capRef: DocumentReference | null;
}

/** Adds (or takes back, with delta -1) one count on a goal: shard for built-in, goal for custom (§6.4). */
function bumpGoal(tx: Transaction, t: Target, day: string, delta: 1 | -1, rand: Rand, now: Date): void {
  const inc = FieldValue.increment(delta);
  if (t.group.kind === 'BUILT_IN') {
    const shard = t.goalRef.collection('shards').doc(String(rand(BUILT_IN_SHARDS)));
    tx.set(shard, { count: inc, days: { [day]: inc } }, { merge: true });
    return;
  }
  const completes = delta === 1 && t.goal.total + 1 >= t.goal.target;
  if (!completes) {
    tx.update(t.goalRef, new FieldPath('total'), inc, new FieldPath('dayTotals', day), inc);
  } else {
    // CG6: a custom group is inactive at once when its target is met.
    tx.update(
      t.goalRef,
      new FieldPath('total'),
      inc,
      new FieldPath('dayTotals', day),
      inc,
      new FieldPath('status'),
      'COMPLETED',
      new FieldPath('completedAt'),
      FieldValue.serverTimestamp(),
    );
    tx.update(t.groupRef, {
      status: 'INACTIVE',
      endedOn: dayIst(now),
      endReason: 'TARGET_MET',
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
}

function bumpMember(tx: Transaction, t: Target, delta: 1 | -1): void {
  if (!t.member) return;
  if (t.member.contributionGoalId === t.goalId) {
    tx.update(t.memberRef, { contribution: FieldValue.increment(delta), updatedAt: FieldValue.serverTimestamp() });
  } else if (delta === 1) {
    tx.update(t.memberRef, { contribution: 1, contributionGoalId: t.goalId, updatedAt: FieldValue.serverTimestamp() });
  }
}

async function readTarget(
  db: Firestore,
  tx: Transaction,
  groupId: string,
  memberKey: string,
  goalIdWanted: string | null,
  capDay: string | null,
): Promise<Target | null> {
  const groupRef = db.doc(`groups/${groupId}`);
  const groupSnap = await tx.get(groupRef);
  if (!groupSnap.exists) return null;
  const group = groupSnap.data() as GroupDoc;
  const goalId = goalIdWanted ?? group.currentGoalId;
  if (!goalId) return null;
  const goalRef = groupRef.collection('goals').doc(goalId);
  const memberRef = groupRef.collection('members').doc(memberKey);
  const capRef = capDay ? db.doc(`contributionCaps/${capDocId(memberKey, groupId, capDay)}`) : null;
  const [goalSnap, memberSnap] = await Promise.all([tx.get(goalRef), tx.get(memberRef)]);
  if (!goalSnap.exists) return null;
  return {
    groupId,
    groupRef,
    group,
    goalId,
    goalRef,
    goal: goalSnap.data() as GoalDoc,
    memberRef,
    member: memberSnap.exists ? (memberSnap.data() as MemberDoc) : null,
    capRef,
  };
}

export type ProcessOutcome = 'COUNTED' | 'RECORDED' | 'DUPLICATE' | 'RETRACTED';

/** Processes one outbox row. Safe to run twice (S-14). */
export async function processItem(
  db: Firestore,
  memberKey: string,
  item: OutboxItem,
  now: Date,
  rand: Rand = defaultRand,
): Promise<ProcessOutcome> {
  const ref = db.doc(`contributions/${contributionDocId(memberKey, item.id)}`);
  const day = groupDayOf(item);
  return db.runTransaction(async (tx) => {
    const existing: DocumentSnapshot = await tx.get(ref);

    if (item.action === 'ADD') {
      if (existing.exists) return 'DUPLICATE';
      const ms = await tx.get(db.doc(`memberships/${memberKey}`));
      const groupIds: string[] = ms.exists ? ((ms.get('groupIds') as string[]) ?? []) : [];
      const isDiary = item.source === 'DIARY';
      const targets: Target[] = [];
      const caps = new Map<string, number>();
      for (const groupId of groupIds) {
        const t = await readTarget(db, tx, groupId, memberKey, null, isDiary ? day : null);
        if (!t) continue;
        if (t.capRef) {
          const cap = await tx.get(t.capRef);
          caps.set(groupId, cap.exists ? ((cap.get('diaryCount') as number) ?? 0) : 0);
        }
        targets.push(t);
      }
      // Writes (CT3: once in every group whose goal it matches).
      const countedIn: string[] = [];
      const groupIdsCounted: string[] = [];
      for (const t of targets) {
        const d = countDecision({ item, day, group: t.group, goal: t.goal, member: t.member, diaryCount: caps.get(t.groupId) ?? 0 });
        if (!d.counts) continue;
        bumpGoal(tx, t, day, 1, rand, now);
        bumpMember(tx, t, 1);
        if (t.capRef) {
          tx.set(
            t.capRef,
            { memberKey, groupId: t.groupId, day, diaryCount: FieldValue.increment(1) },
            { merge: true },
          );
        }
        countedIn.push(`${t.groupId}/${t.goalId}`);
        groupIdsCounted.push(t.groupId);
      }
      tx.create(ref, {
        memberKey,
        kind: item.kind,
        baniId: item.baniId,
        durationS: item.durationS,
        source: item.source,
        day,
        at: item.at,
        retracted: false,
        countedIn,
        groupIds: groupIdsCounted,
        countedCount: countedIn.length,
        createdAt: FieldValue.serverTimestamp(),
      });
      return countedIn.length > 0 ? 'COUNTED' : 'RECORDED';
    }

    // RETRACT (CT5): take back what its ADD counted, from goals still running.
    if (!existing.exists) {
      // A retraction that arrives first leaves a tombstone, so a late ADD counts nothing.
      tx.create(ref, {
        memberKey,
        kind: item.kind,
        baniId: item.baniId,
        durationS: item.durationS,
        source: item.source,
        day,
        at: item.at,
        retracted: true,
        countedIn: [],
        groupIds: [],
        countedCount: 0,
        createdAt: FieldValue.serverTimestamp(),
        retractedAt: FieldValue.serverTimestamp(),
      });
      return 'RETRACTED';
    }
    if (existing.get('retracted') === true) return 'DUPLICATE';
    const countedIn = (existing.get('countedIn') as string[]) ?? [];
    const cDay = (existing.get('day') as string) ?? day;
    const wasDiary = existing.get('source') === 'DIARY';
    const targets: Target[] = [];
    for (const key of countedIn) {
      const [groupId, goalId] = key.split('/');
      const t = await readTarget(db, tx, groupId, memberKey, goalId, wasDiary ? cDay : null);
      if (t) targets.push(t);
    }
    for (const t of targets) {
      if (t.goal.status !== 'ACTIVE') continue; // CT7: a finished goal is history
      bumpGoal(tx, t, cDay, -1, rand, now);
      bumpMember(tx, t, -1);
      if (t.capRef) tx.set(t.capRef, { diaryCount: FieldValue.increment(-1) }, { merge: true });
    }
    tx.update(ref, { retracted: true, retractedAt: FieldValue.serverTimestamp() });
    return 'RETRACTED';
  });
}
