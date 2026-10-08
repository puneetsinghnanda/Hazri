// badgeGoalReached (12-badges SF1, ARCHITECTURE §5.8): when a goal's status
// becomes COMPLETED, add "{groupId}/{goalId}" to the goalsReached of every
// member who contributed at least 1, skipping any already holding 3. Writes
// only badgeFacts, never the goal that triggered it (FN3); arrayUnion and the
// cap make a second run add nothing (FN4).
import type { Firestore } from 'firebase-admin/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { BADGE_GOALS_REACHED_CAP } from '../config';
import { factWouldGrow } from '../badges/facts';

export async function runBadgeGoalReached(
  db: Firestore,
  groupId: string,
  goalId: string,
  beforeStatus: unknown,
  afterStatus: unknown,
): Promise<{ factsUpdated: number }> {
  if (afterStatus !== 'COMPLETED' || beforeStatus === 'COMPLETED') return { factsUpdated: 0 };
  const groupRef = db.doc(`groups/${groupId}`);
  const goalKey = `${groupId}/${goalId}`;

  // Contributors: live member rows still counting toward this goal, and the
  // per-goal archive a built-in group writes when the goal ends.
  const [live, archived] = await Promise.all([
    groupRef.collection('members').where('contributionGoalId', '==', goalId).get(),
    groupRef.collection('goals').doc(goalId).collection('members').get(),
  ]);
  const keys = new Set<string>();
  for (const d of [...live.docs, ...archived.docs]) {
    if (((d.get('contribution') as number) ?? 0) >= 1) keys.add(d.id);
  }

  let factsUpdated = 0;
  const all = [...keys];
  const writer = db.bulkWriter();
  for (let i = 0; i < all.length; i += 300) {
    const chunk = all.slice(i, i + 300);
    const snaps = await db.getAll(...chunk.map((k) => db.doc(`badgeFacts/${k}`)));
    for (const s of snaps) {
      if (!factWouldGrow(s.get('goalsReached'), goalKey, BADGE_GOALS_REACHED_CAP)) continue;
      void writer.set(s.ref, { goalsReached: FieldValue.arrayUnion(goalKey), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      factsUpdated++;
    }
  }
  await writer.close();
  return { factsUpdated };
}
