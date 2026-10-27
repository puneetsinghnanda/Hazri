// A profile's name or city change reaches the quiz (14-quiz.md QZ31): the
// player's own document and their rows on the current boards. Run from the
// same profile trigger as the Sangat's sync; writes quiz documents only.
import { Firestore } from 'firebase-admin/firestore';
import { profileMemberKey } from '../sangat/model';
import { dayIst } from '../time';
import { boardId, displayNameOf, PERIODS } from '../quiz/model';
import { profileSyncChange } from './sangat';

export async function runQuizProfileSync(
  db: Firestore,
  profileId: string,
  before: { name?: unknown; cityId?: unknown } | undefined,
  after: { name?: unknown; cityId?: unknown } | undefined,
  now: Date,
): Promise<{ rowsUpdated: number }> {
  const change = profileSyncChange(before, after);
  if (!change) return { rowsUpdated: 0 };
  const key = profileMemberKey(profileId);
  const update: { displayName?: string; cityId?: string } = {};
  if (change.name !== undefined) update.displayName = displayNameOf(change.name);
  if (change.cityId !== undefined) update.cityId = change.cityId;

  const today = dayIst(now);
  // `d2026-10-27_`, `w2026-W44_`, `m2026-10_`: the boards still running.
  const current = PERIODS.map((p) => boardId(p, today, ''));
  const [player, rows] = await Promise.all([
    db.doc(`quizPlayers/${key}`).get(),
    db.collection('quizScores').where('memberKey', '==', key).get(),
  ]);
  const writer = db.bulkWriter();
  let rowsUpdated = 0;
  if (player.exists) void writer.update(player.ref, update);
  for (const r of rows.docs) {
    const id = r.get('boardId') as string;
    if (!current.some((prefix) => id.startsWith(prefix))) continue;
    void writer.update(r.ref, update);
    rowsUpdated++;
  }
  await writer.close();
  return { rowsUpdated };
}
