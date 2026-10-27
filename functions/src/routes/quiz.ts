// The Gurmat Quiz (14-quiz.md, ARCHITECTURE §6.7). Sessions, answers and
// /me need a profile: without one the app plays on the phone and sends
// nothing (QZ14, QZ31). A board can be read by any install.
import { FieldValue, Firestore, Timestamp, Transaction } from 'firebase-admin/firestore';
import { Router } from 'express';
import { callerUid } from '../auth';
import {
  QUIZ_DAYS_KEPT,
  QUIZ_MAX_SECONDS,
  QUIZ_MIN_SECONDS,
  QUIZ_SESSIONS_PER_DAY,
} from '../config';
import type { Deps } from '../deps';
import { ApiError, Errors } from '../errors';
import { bodyOf, h, param } from '../http';
import { ownerProfileId, requireProfile } from '../profile/profile';
import { profileMemberKey } from '../sangat/model';
import { addDays, dayIst } from '../time';
import { BANK, Choice, drawQuestions, isChoices, isTopic, score } from '../quiz/bank';
import { freshBoard, placeOf, placeRows } from '../quiz/boards';
import { ALL, boardId, deleteAtOf, displayNameOf, Period, PERIODS, pruneDays } from '../quiz/model';

const RECENT_KEPT = 10; // the last two attempts' five questions (QZ13)

interface PlayerDoc {
  displayName: string;
  cityId: string | null;
  points: number;
  attempts: number;
  topics: Record<string, number>;
  days: Record<string, number>;
  recent: Record<string, string[]>;
  today: { day: string; sessions: number };
}

interface SessionDoc {
  memberKey: string;
  topicId: string;
  questionIds: string[];
  bankVersion: number;
  dayIst: string;
  status: 'OPEN' | 'SUBMITTED' | 'REFUSED';
  createdAt: Timestamp;
  choices?: Choice[];
  correct?: boolean[];
  points?: number;
  totalPoints?: number;
}

const QuizErrors = {
  dailyLimit: () => new ApiError(429, 'QUIZ_DAILY_LIMIT', 'Quiz limit reached for today'),
  sessionNotFound: () => new ApiError(404, 'SESSION_NOT_FOUND', 'No such quiz'),
  tooFast: () => new ApiError(409, 'SESSION_TOO_FAST', 'Answered too quickly to count'),
  expired: () => new ApiError(409, 'SESSION_EXPIRED', 'This quiz has expired'),
};

function emptyPlayer(displayName: string, cityId: string | null): PlayerDoc {
  return { displayName, cityId, points: 0, attempts: 0, topics: {}, days: {}, recent: {}, today: { day: '', sessions: 0 } };
}

/** The scores an attempt feeds: its topic's and everyone's, for its day, week and month. */
function scoreIds(day: string, topic: string, memberKey: string): Array<{ id: string; period: Period; scope: string }> {
  const out = [];
  for (const scope of [topic, ALL]) for (const period of PERIODS) out.push({ id: `${boardId(period, day, scope)}_${memberKey}`, period, scope });
  return out;
}

async function readPlayer(tx: Transaction, db: Firestore, key: string, name: string, cityId: string | null): Promise<PlayerDoc> {
  const snap = await tx.get(db.doc(`quizPlayers/${key}`));
  return snap.exists ? { ...emptyPlayer(name, cityId), ...(snap.data() as PlayerDoc) } : emptyPlayer(name, cityId);
}

export function quizRouter(deps: Deps): Router {
  const { db, clock } = deps;
  const r = Router();

  // POST /quiz/sessions { topicId, bankVersion }: draw five, count the session (QZ13, QZ14, QZ22).
  r.post(
    '/api/v1/quiz/sessions',
    h(async (req, res) => {
      const body = bodyOf(req);
      const fields: Record<string, string> = {};
      if (!isTopic(body.topicId)) fields.topicId = 'Unknown topic';
      if (typeof body.bankVersion !== 'number' || !Number.isInteger(body.bankVersion) || body.bankVersion < 1) {
        fields.bankVersion = 'A content version is required';
      }
      if (Object.keys(fields).length > 0) throw Errors.validation(fields);
      const topicId = body.topicId as string;
      const bankVersion = body.bankVersion as number;
      const uid = callerUid(res);
      const now = clock.now();
      const today = dayIst(now);
      const sessionRef = db.collection('quizSessions').doc();

      const questionIds = await db.runTransaction(async (tx) => {
        const profile = await requireProfile(db, uid, tx);
        const key = profileMemberKey(profile.doc.profileId);
        const player = await readPlayer(tx, db, key, displayNameOf(profile.doc.name), profile.doc.cityId ?? null);
        const sessions = player.today.day === today ? player.today.sessions : 0;
        if (sessions >= QUIZ_SESSIONS_PER_DAY) throw QuizErrors.dailyLimit();
        const ids = drawQuestions(topicId, bankVersion, player.recent[topicId] ?? []);
        if (ids.length === 0) throw Errors.validation({ bankVersion: 'No questions for this content version' });
        const session: SessionDoc = {
          memberKey: key,
          topicId,
          questionIds: ids,
          bankVersion,
          dayIst: today,
          status: 'OPEN',
          createdAt: Timestamp.fromDate(now),
        };
        tx.set(sessionRef, { ...session, deleteAt: Timestamp.fromDate(new Date(now.getTime() + 30 * 86_400_000)) });
        tx.set(db.doc(`quizPlayers/${key}`), {
          ...player,
          displayName: displayNameOf(profile.doc.name),
          cityId: profile.doc.cityId ?? null,
          recent: { ...player.recent, [topicId]: [...ids, ...(player.recent[topicId] ?? [])].slice(0, RECENT_KEPT) },
          today: { day: today, sessions: sessions + 1 },
          updatedAt: FieldValue.serverTimestamp(),
        });
        return ids;
      });
      res.status(200).json({
        sessionId: sessionRef.id,
        questionIds,
        expiresAt: new Date(now.getTime() + QUIZ_MAX_SECONDS * 1000).toISOString(),
      });
    }),
  );

  // POST /quiz/sessions/{id}/answers { choices }: mark, record, place (QZ18-QZ20, QZ22).
  r.post(
    '/api/v1/quiz/sessions/:id/answers',
    h(async (req, res) => {
      const choices = bodyOf(req).choices;
      if (!isChoices(choices)) throw Errors.validation({ choices: 'Five answers, each A to D' });
      const uid = callerUid(res);
      const now = clock.now();
      const ref = db.doc(`quizSessions/${param(req, 'id')}`);

      const outcome = await db.runTransaction(async (tx) => {
        const profile = await requireProfile(db, uid, tx);
        const key = profileMemberKey(profile.doc.profileId);
        const snap = await tx.get(ref);
        if (!snap.exists || snap.get('memberKey') !== key) throw QuizErrors.sessionNotFound();
        const s = snap.data() as SessionDoc;
        if (s.status === 'SUBMITTED') {
          return { kind: 'done' as const, key, s, best: null };
        }
        const elapsed = (now.getTime() - s.createdAt.toMillis()) / 1000;
        if (s.status === 'REFUSED' || elapsed > QUIZ_MAX_SECONDS) return { kind: 'expired' as const };
        if (elapsed < QUIZ_MIN_SECONDS) {
          tx.update(ref, { status: 'REFUSED' });
          return { kind: 'tooFast' as const };
        }

        const { correct, points } = score(s.questionIds, choices);
        const name = displayNameOf(profile.doc.name);
        const cityId = profile.doc.cityId ?? null;
        const player = await readPlayer(tx, db, key, name, cityId);
        const feeds = scoreIds(s.dayIst, s.topicId, key);
        const dayTopicRef = db.doc(`quizScores/${feeds[0].id}`);
        const dayTopic = await tx.get(dayTopicRef);
        const dayBest = dayTopic.exists ? (dayTopic.get('score') as number) : 0;
        const delta = points - dayBest;
        // The day's first attempt is recorded even at 0, so the player counts as played (QZ28).
        const raises = delta > 0 || !dayTopic.exists;
        const others = raises ? await Promise.all(feeds.slice(1).map((f) => tx.get(db.doc(`quizScores/${f.id}`)))) : [];

        // Reads done; writes follow.
        const totalPoints = player.points + points;
        tx.set(db.doc(`quizPlayers/${key}`), {
          ...player,
          displayName: name,
          cityId,
          points: totalPoints,
          attempts: player.attempts + 1,
          topics: { ...player.topics, [s.topicId]: (player.topics[s.topicId] ?? 0) + points },
          days: pruneDays({ ...player.days, [s.dayIst]: (player.days[s.dayIst] ?? 0) + points }, dayIst(now), QUIZ_DAYS_KEPT),
          updatedAt: FieldValue.serverTimestamp(),
        });
        if (raises) {
          const snaps = [dayTopic, ...others];
          feeds.forEach((f, i) => {
            const before = snaps[i].exists ? (snaps[i].get('score') as number) : 0;
            tx.set(db.doc(`quizScores/${f.id}`), {
              boardId: f.id.slice(0, f.id.length - key.length - 1),
              memberKey: key,
              score: before + Math.max(delta, 0),
              displayName: name,
              cityId,
              reachedAt: Timestamp.fromDate(now),
              deleteAt: Timestamp.fromDate(deleteAtOf(f.period, s.dayIst)),
            });
          });
        }
        tx.update(ref, { status: 'SUBMITTED', choices, correct, points, totalPoints, submittedAt: Timestamp.fromDate(now) });
        return { kind: 'done' as const, key, s: { ...s, correct, points, totalPoints }, best: Math.max(dayBest, points) };
      });

      if (outcome.kind === 'tooFast') throw QuizErrors.tooFast();
      if (outcome.kind === 'expired') throw QuizErrors.expired();
      const { s, key } = outcome;
      const dayTopicId = boardId('day', s.dayIst, s.topicId);
      let best = outcome.best;
      if (best === null) {
        const mine = await db.doc(`quizScores/${dayTopicId}_${key}`).get();
        best = mine.exists ? (mine.get('score') as number) : 0;
      }
      const placeToday = await placeOf(db, dayTopicId, best);
      res.status(200).json({ correct: s.correct, points: s.points, totalPoints: s.totalPoints, placeToday });
    }),
  );

  // GET /quiz/board?period=&scope=: the current board, the caller's row marked (QZ28-QZ30).
  r.get(
    '/api/v1/quiz/board',
    h(async (req, res) => {
      const period = req.query.period;
      const scope = req.query.scope;
      const fields: Record<string, string> = {};
      if (period !== 'day' && period !== 'week' && period !== 'month') fields.period = 'day, week or month';
      if (scope !== ALL && !isTopic(scope)) fields.scope = 'all or a topic';
      if (Object.keys(fields).length > 0) throw Errors.validation(fields);
      const now = clock.now();
      const today = dayIst(now);
      const id = boardId(period as Period, today, scope as string);
      const [board, profileId] = await Promise.all([
        freshBoard(db, id, period as Period, today, now),
        ownerProfileId(db, callerUid(res)),
      ]);
      const key = profileId ? profileMemberKey(profileId) : null;
      let me: { score: number; place: number } | null = null;
      if (key) {
        const mine = await db.doc(`quizScores/${id}_${key}`).get();
        if (mine.exists) {
          const s = mine.get('score') as number;
          me = { score: s, place: await placeOf(db, id, s) };
        }
      }
      res.status(200).json({
        boardId: id,
        builtAt: board.builtAt.toDate().toISOString(),
        played: board.played,
        rows: placeRows(board.rows).map((r) => ({
          place: r.place,
          name: r.displayName,
          cityId: r.cityId,
          score: r.score,
          you: key !== null && r.memberKey === key,
        })),
        me,
      });
    }),
  );

  // GET /quiz/me: the player's own numbers (QZ34, QZ35).
  r.get(
    '/api/v1/quiz/me',
    h(async (_req, res) => {
      const profile = await requireProfile(db, callerUid(res));
      const key = profileMemberKey(profile.doc.profileId);
      const now = clock.now();
      const today = dayIst(now);
      const snap = await db.doc(`quizPlayers/${key}`).get();
      const p = snap.exists ? (snap.data() as PlayerDoc) : emptyPlayer('', null);
      const lastMonth = addDays(`${today.slice(0, 7)}-01`, -1).slice(0, 7);
      const days: Record<string, number> = {};
      for (const [d, n] of Object.entries(p.days ?? {})) if (d.startsWith(today.slice(0, 7)) || d.startsWith(lastMonth)) days[d] = n;
      const places: Record<Period, number | null> = { day: null, week: null, month: null };
      await Promise.all(
        PERIODS.map(async (period) => {
          const id = boardId(period, today, ALL);
          const mine = await db.doc(`quizScores/${id}_${key}`).get();
          if (mine.exists) places[period] = await placeOf(db, id, mine.get('score') as number);
        }),
      );
      res.status(200).json({ points: p.points ?? 0, attempts: p.attempts ?? 0, topics: p.topics ?? {}, days, places, bankVersion: BANK.contentVersion });
    }),
  );

  return r;
}
