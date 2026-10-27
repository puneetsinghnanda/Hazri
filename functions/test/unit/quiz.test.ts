// 14-quiz.md QZ13, QZ18, QZ20, QZ21, QZ28: the draw, the score, the periods
// and the names, as pure functions.
import { Bank, drawQuestions, isChoices, score, BANK } from '../../src/quiz/bank';
import { placeRows } from '../../src/quiz/boards';
import { boardId, deleteAtOf, displayNameOf, isoWeekOf, pruneDays, weekStartOf } from '../../src/quiz/model';

const q = (id: string, difficulty: 'easy' | 'medium' | 'hard', since = 10, retired = false) => ({
  id, topic: 't', difficulty, answer: 'A' as const, retired, since,
});

describe('the bank as built by the pipeline', () => {
  it('has seventeen topics and twenty questions in each', () => {
    expect(BANK.topics).toHaveLength(17);
    for (const t of BANK.topics) expect(BANK.questions.filter((x) => x.topic === t)).toHaveLength(20);
  });
});

describe('drawQuestions (QZ13)', () => {
  const bank: Bank = {
    contentVersion: 10,
    topics: ['t'],
    questions: [
      ...['e1', 'e2', 'e3', 'e4', 'e5', 'e6'].map((id) => q(id, 'easy')),
      ...['m1', 'm2', 'm3', 'm4', 'm5', 'm6'].map((id) => q(id, 'medium')),
      ...['h1', 'h2', 'h3'].map((id) => q(id, 'hard')),
    ],
  };
  const rng = () => 0;

  it('draws two easy, two medium and one hard, in that order', () => {
    const ids = drawQuestions('t', 10, [], rng, bank);
    expect(ids.map((id) => id[0])).toEqual(['e', 'e', 'm', 'm', 'h']);
    expect(new Set(ids).size).toBe(5);
  });

  it('avoids the last attempts while there are others', () => {
    const ids = drawQuestions('t', 10, ['e1', 'e2', 'm1', 'm2', 'h1'], rng, bank);
    expect(ids).toEqual(['e3', 'e4', 'm3', 'm4', 'h2']);
  });

  it('takes a recent question rather than fail when nothing else is left', () => {
    const ids = drawQuestions('t', 10, ['h1', 'h2', 'h3'], rng, bank);
    expect(ids[4]).toBe('h1');
  });

  it('fills a short difficulty from the next harder, then the next easier', () => {
    const short: Bank = { ...bank, questions: [q('e1', 'easy'), q('m1', 'medium'), q('m2', 'medium'), q('m3', 'medium'), q('h1', 'hard'), q('h2', 'hard')] };
    expect(drawQuestions('t', 10, [], rng, short)).toEqual(['e1', 'm1', 'm2', 'm3', 'h1']);
    const noHard: Bank = { ...bank, questions: bank.questions.filter((x) => x.difficulty !== 'hard') };
    expect(drawQuestions('t', 10, [], rng, noHard)[4]).toBe('m3');
  });

  it('never draws a retired question or one newer than the app', () => {
    const b: Bank = { ...bank, questions: [...bank.questions.map((x) => (x.id === 'e1' ? { ...x, retired: true } : x)), q('e0', 'easy', 11)] };
    const all = new Set<string>();
    for (let i = 0; i < 50; i++) for (const id of drawQuestions('t', 10, [], Math.random, b)) all.add(id);
    expect(all.has('e1')).toBe(false);
    expect(all.has('e0')).toBe(false);
  });

  it('draws nothing when the topic cannot fill five', () => {
    const tiny: Bank = { ...bank, questions: bank.questions.slice(0, 3) };
    expect(drawQuestions('t', 10, [], rng, tiny)).toEqual([]);
  });
});

describe('score (QZ18)', () => {
  it('gives ten points for each answer the bank marks right', () => {
    const [a, b] = BANK.questions;
    const wrong = a.answer === 'A' ? 'B' : 'A';
    const r = score([a.id, b.id, a.id, b.id, a.id], [a.answer, b.answer, wrong, b.answer, a.answer]);
    expect(r.correct).toEqual([true, true, false, true, true]);
    expect(r.points).toBe(40);
  });

  it('accepts exactly five choices among A to D', () => {
    expect(isChoices(['A', 'B', 'C', 'D', 'A'])).toBe(true);
    expect(isChoices(['A', 'B', 'C', 'D'])).toBe(false);
    expect(isChoices(['A', 'B', 'C', 'D', 'E'])).toBe(false);
    expect(isChoices('ABCDA')).toBe(false);
  });
});

describe('periods and boards (QZ21)', () => {
  it('names ISO weeks Monday to Sunday', () => {
    expect(isoWeekOf('2026-10-26')).toBe('2026-W44'); // Monday
    expect(isoWeekOf('2026-11-01')).toBe('2026-W44'); // Sunday
    expect(isoWeekOf('2026-11-02')).toBe('2026-W45');
    expect(isoWeekOf('2027-01-01')).toBe('2026-W53');
    expect(isoWeekOf('2021-01-03')).toBe('2020-W53');
    expect(isoWeekOf('2024-12-30')).toBe('2025-W01');
    expect(weekStartOf('2026-11-01')).toBe('2026-10-26');
  });

  it('builds board ids by period and scope', () => {
    expect(boardId('day', '2026-10-27', 'guru-ram-das-ji')).toBe('d2026-10-27_guru-ram-das-ji');
    expect(boardId('week', '2026-10-27', 'all')).toBe('w2026-W44_all');
    expect(boardId('month', '2026-10-27', 'all')).toBe('m2026-10_all');
  });

  it('lets a day board go after 35 days, a week after 70 from its Monday, a month after 400', () => {
    expect(deleteAtOf('day', '2026-10-27').toISOString().slice(0, 10)).toBe('2026-12-01');
    expect(deleteAtOf('week', '2026-10-27').toISOString().slice(0, 10)).toBe('2027-01-04');
    expect(deleteAtOf('month', '2026-10-27').toISOString().slice(0, 10)).toBe('2027-11-05');
  });

  it('keeps the last 62 days of points', () => {
    expect(pruneDays({ '2026-08-26': 10, '2026-08-27': 20, '2026-10-27': 30 }, '2026-10-27', 62)).toEqual({ '2026-08-27': 20, '2026-10-27': 30 });
  });
});

describe('names and places (QZ28)', () => {
  it('shows the first name and the last name initial', () => {
    expect(displayNameOf('Manpreet Singh')).toBe('Manpreet S.');
    expect(displayNameOf('  Harpreet  Kaur Gill ')).toBe('Harpreet G.');
    expect(displayNameOf('Harpreet')).toBe('Harpreet');
    expect(displayNameOf('ਹਰਪ੍ਰੀਤ ਕੌਰ')).toBe('ਹਰਪ੍ਰੀਤ ਕ.');
  });

  it('gives equal scores the same place', () => {
    expect(placeRows([{ score: 50 }, { score: 40 }, { score: 40 }, { score: 30 }]).map((r) => r.place)).toEqual([1, 2, 2, 4]);
  });
});
