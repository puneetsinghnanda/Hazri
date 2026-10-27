// The leaderboards (14-quiz.md QZ20, QZ28, QZ30; ARCHITECTURE §5.13). A board
// is one document, rebuilt from `quizScores` at most every QUIZ_BOARD_SECONDS
// and only when somebody asks, so opening one costs one read.
import { Firestore, Timestamp } from 'firebase-admin/firestore';
import { QUIZ_BOARD_SECONDS, QUIZ_BOARD_SIZE } from '../config';
import { deleteAtOf, Period } from './model';

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

/** The stored board when it is fresh, else a new one. */
export async function freshBoard(db: Firestore, id: string, period: Period, day: string, now: Date): Promise<BoardDoc> {
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
