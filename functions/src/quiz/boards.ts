// The leaderboards (14-quiz.md QZ20, QZ28, QZ30; ARCHITECTURE §5.13). A board
// is one document, rebuilt from `quizScores` at most every QUIZ_BOARD_SECONDS
// and only when somebody asks, so opening one costs one read.
import { Firestore, Timestamp } from 'firebase-admin/firestore';
import { QUIZ_BOARD_SECONDS, QUIZ_BOARD_SIZE } from '../config';
import { boardId, deleteAtOf, Period } from './model';

export interface BoardRow {
  place: number;
  displayName: string;
  cityId: string | null;
  score: number;
  memberKey: string;
}

export interface BoardDoc {
  rows: BoardRow[];
  played: number;
  builtAt: Timestamp;
  deleteAt: Timestamp;
}

/** Places for rows already in score order: equal scores share a place (QZ28). */
export function placeRows<T extends { score: number }>(rows: T[]): Array<T & { place: number }> {
  return rows.map((r) => ({ ...r, place: 1 + rows.filter((o) => o.score > r.score).length }));
}

/** The board's top twenty and how many played, as stored. */
export async function buildBoard(db: Firestore, id: string, period: Period, day: string, now: Date): Promise<BoardDoc> {
  const scores = db.collection('quizScores').where('boardId', '==', id);
  const [top, played] = await Promise.all([
    scores.orderBy('score', 'desc').orderBy('reachedAt', 'asc').limit(QUIZ_BOARD_SIZE).get(),
    scores.count().get(),
  ]);
  const rows = placeRows(
    top.docs.map((d) => ({
      displayName: (d.get('displayName') as string) ?? '',
      cityId: (d.get('cityId') as string | null) ?? null,
      score: d.get('score') as number,
      memberKey: d.get('memberKey') as string,
    })),
  );
  const doc: BoardDoc = {
    rows,
    played: played.data().count,
    builtAt: Timestamp.fromDate(now),
    deleteAt: Timestamp.fromDate(deleteAtOf(period, day)),
  };
  await db.doc(`quizBoards/${id}`).set(doc);
  return doc;
}

/**
 * Fills the All time boards once, from the month boards kept since the quiz
 * began (a month's rows are kept 400 days): each player's score on `a_{scope}`
 * is the sum of their month scores for that scope, which is the sum of their
 * daily bests, the rule of every other board (QZ20). Claimed by creating
 * `quizMeta/allTime`, so it runs once however many ask at the same moment.
 * A submission since the deploy has already raised its month row, so the sum
 * includes it.
 */
export async function backfillAllTime(db: Firestore, now: Date): Promise<boolean> {
  const meta = db.doc('quizMeta/allTime');
  try {
    await meta.create({ startedAt: Timestamp.fromDate(now) });
  } catch {
    return false;
  }
  const months = await db.collection('quizScores').where('boardId', '>=', 'm').where('boardId', '<', 'n').get();
  const sums = new Map<string, { scope: string; memberKey: string; score: number; displayName: string; cityId: string | null; reachedAt: Timestamp }>();
  for (const d of months.docs) {
    const board = d.get('boardId') as string;
    const scope = board.slice(board.indexOf('_') + 1);
    const memberKey = d.get('memberKey') as string;
    const reachedAt = d.get('reachedAt') as Timestamp;
    const k = `${scope}|${memberKey}`;
    const was = sums.get(k);
    const newer = !was || reachedAt.toMillis() >= was.reachedAt.toMillis();
    sums.set(k, {
      scope,
      memberKey,
      score: (was?.score ?? 0) + ((d.get('score') as number) ?? 0),
      displayName: newer ? ((d.get('displayName') as string) ?? '') : was!.displayName,
      cityId: newer ? ((d.get('cityId') as string | null) ?? null) : was!.cityId,
      reachedAt: newer ? reachedAt : was!.reachedAt,
    });
  }
  const rows = [...sums.values()];
  for (let i = 0; i < rows.length; i += 400) {
    const batch = db.batch();
    for (const r of rows.slice(i, i + 400)) {
      const id = boardId('all', '', r.scope);
      batch.set(db.doc(`quizScores/${id}_${r.memberKey}`), {
        boardId: id,
        memberKey: r.memberKey,
        score: r.score,
        displayName: r.displayName,
        cityId: r.cityId,
        reachedAt: r.reachedAt,
        deleteAt: Timestamp.fromDate(deleteAtOf('all', '')),
      });
    }
    await batch.commit();
  }
  await meta.set({ doneAt: Timestamp.fromDate(now), rows: rows.length }, { merge: true });
  return true;
}

/** The stored board when it is fresh, else a new one. */
export async function freshBoard(db: Firestore, id: string, period: Period, day: string, now: Date): Promise<BoardDoc> {
  if (period === 'all' && (await backfillAllTime(db, now))) return buildBoard(db, id, period, day, now);
  const snap = await db.doc(`quizBoards/${id}`).get();
  const doc = snap.exists ? (snap.data() as BoardDoc) : null;
  if (doc && now.getTime() - doc.builtAt.toMillis() < QUIZ_BOARD_SECONDS * 1000) return doc;
  return buildBoard(db, id, period, day, now);
}

/** A score's place on a board: one more than the scores above it. */
export async function placeOf(db: Firestore, id: string, score: number): Promise<number> {
  const above = await db.collection('quizScores').where('boardId', '==', id).where('score', '>', score).count().get();
  return above.data().count + 1;
}
