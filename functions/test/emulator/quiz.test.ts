// 14-quiz.md §11 and §13, against the emulator: sessions, answers, the best
// per topic per day, the boards, /me, the limits and the name sync.
import { runQuizProfileSync } from '../../src/jobs/quiz';
import { questionById } from '../../src/quiz/bank';
import { clearFirestore, createProfile, describeEmu, harness, Harness } from './helpers';

const TOPIC = 'guru-ram-das-ji';

describeEmu('Gurmat Quiz', () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
    h.clock.set('2026-10-27T06:00:00Z'); // 11:30 IST
  });

  async function start(uid: string, topicId = TOPIC) {
    const res = await h.as(uid).post('/api/v1/quiz/sessions', { topicId, bankVersion: 10 });
    expect(res.status).toBe(200);
    return res.body as { sessionId: string; questionIds: string[] };
  }

  /** Answers `right` of the five correctly. */
  function choicesFor(ids: string[], right: number): string[] {
    return ids.map((id, i) => {
      const a = questionById(id)!.answer;
      return i < right ? a : a === 'A' ? 'B' : 'A';
    });
  }

  async function play(uid: string, right: number, topicId = TOPIC) {
    const s = await start(uid, topicId);
    h.clock.advance(60);
    const res = await h.as(uid).post(`/api/v1/quiz/sessions/${s.sessionId}/answers`, { choices: choicesFor(s.questionIds, right) });
    expect(res.status).toBe(200);
    return res.body as { correct: boolean[]; points: number; totalPoints: number; placeToday: number | null };
  }

  it('without a profile, a session is refused and nothing is stored (QZ14, QZ31)', async () => {
    const res = await h.as('anon1').post('/api/v1/quiz/sessions', { topicId: TOPIC, bankVersion: 10 });
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NO_PROFILE');
    expect((await h.db.collection('quizSessions').get()).size).toBe(0);
    expect((await h.as('anon1').get('/api/v1/quiz/me')).status).toBe(404);
  });

  it('draws five questions of the topic, two easy, two medium, one hard (QZ13)', async () => {
    await createProfile(h, 'u1');
    const s = await start('u1');
    expect(s.questionIds).toHaveLength(5);
    expect(s.questionIds.map((id) => questionById(id)!.difficulty)).toEqual(['easy', 'easy', 'medium', 'medium', 'hard']);
    expect(s.questionIds.every((id) => questionById(id)!.topic === TOPIC)).toBe(true);
  });

  it('a second start avoids the five just drawn', async () => {
    await createProfile(h, 'u1');
    const a = await start('u1');
    const b = await start('u1');
    expect(b.questionIds.filter((id) => a.questionIds.includes(id))).toEqual([]);
  });

  it('scores with its own key, ten a right answer, and places the player (QZ18, QZ26)', async () => {
    await createProfile(h, 'u1');
    const r = await play('u1', 4);
    expect(r.correct).toEqual([true, true, true, true, false]);
    expect(r.points).toBe(40);
    expect(r.totalPoints).toBe(40);
    expect(r.placeToday).toBe(1);
  });

  it('a forged body cannot claim points: only the choices count', async () => {
    await createProfile(h, 'u1');
    const s = await start('u1');
    h.clock.advance(60);
    const res = await h.as('u1').post(`/api/v1/quiz/sessions/${s.sessionId}/answers`, { choices: choicesFor(s.questionIds, 0), points: 50 });
    expect(res.body.points).toBe(0);
  });

  it('a second submission returns the first answer and writes nothing', async () => {
    await createProfile(h, 'u1');
    const s = await start('u1');
    h.clock.advance(60);
    const first = await h.as('u1').post(`/api/v1/quiz/sessions/${s.sessionId}/answers`, { choices: choicesFor(s.questionIds, 3) });
    const again = await h.as('u1').post(`/api/v1/quiz/sessions/${s.sessionId}/answers`, { choices: choicesFor(s.questionIds, 5) });
    expect(again.status).toBe(200);
    expect(again.body).toEqual(first.body);
    const me = await h.as('u1').get('/api/v1/quiz/me');
    expect(me.body.points).toBe(30);
    expect(me.body.attempts).toBe(1);
  });

  it('another player cannot submit my session', async () => {
    await createProfile(h, 'u1');
    await createProfile(h, 'u2');
    const s = await start('u1');
    h.clock.advance(60);
    const res = await h.as('u2').post(`/api/v1/quiz/sessions/${s.sessionId}/answers`, { choices: choicesFor(s.questionIds, 5) });
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('SESSION_NOT_FOUND');
  });

  it('too fast and too late are refused and earn nothing (QZ22)', async () => {
    await createProfile(h, 'u1');
    const fast = await start('u1');
    h.clock.advance(4);
    const r1 = await h.as('u1').post(`/api/v1/quiz/sessions/${fast.sessionId}/answers`, { choices: choicesFor(fast.questionIds, 5) });
    expect(r1.status).toBe(409);
    expect(r1.body.error.code).toBe('SESSION_TOO_FAST');
    h.clock.advance(60);
    const retry = await h.as('u1').post(`/api/v1/quiz/sessions/${fast.sessionId}/answers`, { choices: choicesFor(fast.questionIds, 5) });
    expect(retry.status).toBe(409);

    const late = await start('u1');
    h.clock.advance(31 * 60);
    const r2 = await h.as('u1').post(`/api/v1/quiz/sessions/${late.sessionId}/answers`, { choices: choicesFor(late.questionIds, 5) });
    expect(r2.status).toBe(409);
    expect(r2.body.error.code).toBe('SESSION_EXPIRED');
    expect((await h.as('u1').get('/api/v1/quiz/me')).body.points).toBe(0);
  });

  it('the 31st session of a day is refused, and the next day is fresh (QZ22)', async () => {
    await createProfile(h, 'u1');
    for (let i = 0; i < 30; i++) await start('u1');
    const res = await h.as('u1').post('/api/v1/quiz/sessions', { topicId: TOPIC, bankVersion: 10 });
    expect(res.status).toBe(429);
    expect(res.body.error.code).toBe('QUIZ_DAILY_LIMIT');
    h.clock.set('2026-10-27T18:31:00Z'); // 00:01 IST on the 28th
    await start('u1');
  });

  it('every attempt adds to the total; a board counts the best per topic per day (QZ19, QZ20)', async () => {
    await createProfile(h, 'u1');
    await play('u1', 3);
    await play('u1', 4);
    await play('u1', 2);
    await play('u1', 5, 'five-takhts');
    const me = await h.as('u1').get('/api/v1/quiz/me');
    expect(me.body.points).toBe(30 + 40 + 20 + 50);
    expect(me.body.topics[TOPIC]).toBe(90);
    expect(me.body.days['2026-10-27']).toBe(140);

    const topicDay = await h.as('u1').get(`/api/v1/quiz/board?period=day&scope=${TOPIC}`);
    expect(topicDay.body.rows).toEqual([{ place: 1, name: 'Harpreet K.', cityId: 'amritsar', score: 40, you: true }]);
    expect(topicDay.body.me).toEqual({ score: 40, place: 1 });
    const everyoneWeek = await h.as('u1').get('/api/v1/quiz/board?period=week&scope=all');
    expect(everyoneWeek.body.boardId).toBe('w2026-W44_all');
    expect(everyoneWeek.body.rows[0].score).toBe(90);

    // Next day: a new day board, the week and month keep adding daily bests.
    h.clock.set('2026-10-28T06:00:00Z');
    await play('u1', 1);
    const month = await h.as('u1').get('/api/v1/quiz/board?period=month&scope=all');
    expect(month.body.rows[0].score).toBe(100);
    const day = await h.as('u1').get('/api/v1/quiz/board?period=day&scope=all');
    expect(day.body.rows[0].score).toBe(10);
  });

  it('a quiz from yesterday is on this week\'s and month\'s boards, not today\'s (QZ21, owner 2026-10-28)', async () => {
    await createProfile(h, 'u1');
    await play('u1', 3);
    h.clock.set('2026-10-28T05:46:00Z'); // 11:16 IST the next day, without playing
    for (const scope of ['all', TOPIC]) {
      const day = await h.as('u1').get(`/api/v1/quiz/board?period=day&scope=${scope}`);
      expect(day.body.rows).toEqual([]);
      for (const period of ['week', 'month']) {
        const b = await h.as('u1').get(`/api/v1/quiz/board?period=${period}&scope=${scope}`);
        expect(b.body.rows).toEqual([{ place: 1, name: 'Harpreet K.', cityId: 'amritsar', score: 30, you: true }]);
        expect(b.body.me).toEqual({ score: 30, place: 1 });
      }
    }
  });

  it('boards list the top twenty, places, and the caller below them; any install can read (QZ28, QZ29)', async () => {
    const letters = 'abcdefghijklmnopqrstuv';
    for (let i = 0; i < 22; i++) {
      await createProfile(h, `p${i}`, { name: `Player ${letters[i]}`, email: `p${i}@example.com` });
      await play(`p${i}`, i % 6);
    }
    h.clock.advance(300);
    // Scores i % 6 right: three on 50, three on 40, four each on 30, 20, 10 and 0.
    const board = await h.as('p18').get(`/api/v1/quiz/board?period=day&scope=${TOPIC}`);
    expect(board.status).toBe(200);
    expect(board.body.rows).toHaveLength(20);
    expect(board.body.played).toBe(22);
    expect(board.body.rows.map((r: { place: number }) => r.place).slice(0, 7)).toEqual([1, 1, 1, 4, 4, 4, 7]);
    expect(board.body.rows[19]).toMatchObject({ name: 'Player G.', score: 0, place: 19 });
    expect(board.body.rows.find((r: { you: boolean }) => r.you)).toBeUndefined();
    expect(board.body.me).toEqual({ score: 0, place: 19 }); // p18 is below the twenty

    const anon = await h.as('nobody').get(`/api/v1/quiz/board?period=day&scope=${TOPIC}`);
    expect(anon.status).toBe(200);
    expect(anon.body.me).toBeNull();
    expect(JSON.stringify(anon.body)).not.toContain('p_');
  });

  it('a board is rebuilt at most every two minutes (QZ30)', async () => {
    await createProfile(h, 'u1');
    await createProfile(h, 'u2', { name: 'Jasleen Kaur', email: 'u2@example.com' });
    await play('u1', 2);
    const first = await h.as('u1').get(`/api/v1/quiz/board?period=day&scope=${TOPIC}`);
    expect(first.body.rows).toHaveLength(1);
    await play('u2', 5);
    const soon = await h.as('u1').get(`/api/v1/quiz/board?period=day&scope=${TOPIC}`);
    expect(soon.body.rows).toHaveLength(1);
    expect(soon.body.builtAt).toBe(first.body.builtAt);
    h.clock.advance(121);
    const later = await h.as('u1').get(`/api/v1/quiz/board?period=day&scope=${TOPIC}`);
    expect(later.body.rows.map((r: { name: string }) => r.name)).toEqual(['Jasleen K.', 'Harpreet K.']);
    expect(later.body.me).toEqual({ score: 20, place: 2 });
  });

  it('rejects an unknown topic, period or bank version', async () => {
    await createProfile(h, 'u1');
    expect((await h.as('u1').post('/api/v1/quiz/sessions', { topicId: 'nope', bankVersion: 10 })).status).toBe(400);
    expect((await h.as('u1').post('/api/v1/quiz/sessions', { topicId: TOPIC })).status).toBe(400);
    expect((await h.as('u1').post('/api/v1/quiz/sessions', { topicId: TOPIC, bankVersion: 9 })).status).toBe(400);
    expect((await h.as('u1').get('/api/v1/quiz/board?period=year&scope=all')).status).toBe(400);
    expect((await h.as('u1').get('/api/v1/quiz/board?period=day&scope=nope')).status).toBe(400);
  });

  it('a name or city change reaches the current boards (QZ31)', async () => {
    const p = await createProfile(h, 'u1');
    await play('u1', 3);
    const out = await runQuizProfileSync(h.db, p.profileId, { name: 'Harpreet Kaur', cityId: 'amritsar' }, { name: 'Harpreet Gill', cityId: 'delhi' }, h.clock.now());
    expect(out.rowsUpdated).toBe(6);
    h.clock.advance(121);
    const board = await h.as('u1').get('/api/v1/quiz/board?period=month&scope=all');
    expect(board.body.rows[0]).toMatchObject({ name: 'Harpreet G.', cityId: 'delhi' });
    const again = await runQuizProfileSync(h.db, p.profileId, { name: 'Harpreet Gill' }, { name: 'Harpreet Gill' }, h.clock.now());
    expect(again.rowsUpdated).toBe(0);
  });
});
