// The quiz's answer key and the draw (14-quiz.md QZ13, QZ14, QZ18). The bank
// is written by tools/content_pipeline/build_content_db.py from the same
// source files as the app's content.db, so an id the server draws is one the
// phone can show, as long as it is drawn from the bank version the app sent.
import bankJson from '../quiz-bank.json';
import { QUIZ_POINTS_PER_RIGHT, QUIZ_QUESTIONS } from '../config';

export type Difficulty = 'easy' | 'medium' | 'hard';
export type Choice = 'A' | 'B' | 'C' | 'D';

export interface BankQuestion {
  id: string;
  topic: string;
  difficulty: Difficulty;
  answer: Choice;
  retired: boolean;
  since: number;
}

export interface Bank {
  contentVersion: number;
  topics: string[];
  questions: BankQuestion[];
}

export const BANK: Bank = bankJson as Bank;

const byId = new Map(BANK.questions.map((q) => [q.id, q]));

export function isTopic(topic: unknown, bank: Bank = BANK): topic is string {
  return typeof topic === 'string' && bank.topics.includes(topic);
}

export function questionById(id: string): BankQuestion | undefined {
  return byId.get(id);
}

/** Two easy, two medium, one hard, in that order (QZ13). */
const SLOTS: Difficulty[] = ['easy', 'easy', 'medium', 'medium', 'hard'];
/** A slot short of its difficulty: the next harder, then the next easier. */
const FALLBACK: Record<Difficulty, Difficulty[]> = {
  easy: ['easy', 'medium', 'hard'],
  medium: ['medium', 'hard', 'easy'],
  hard: ['hard', 'medium', 'easy'],
};

/**
 * Five question ids for a topic, from the questions the app's bank version
 * has (`since` <= bankVersion) that are not retired, avoiding `recent` (the
 * player's last two attempts) while the topic has enough others.
 */
export function drawQuestions(
  topic: string,
  bankVersion: number,
  recent: readonly string[],
  random: () => number = Math.random,
  bank: Bank = BANK,
): string[] {
  const live = bank.questions.filter((q) => q.topic === topic && !q.retired && q.since <= bankVersion);
  const avoid = new Set(recent);
  const used = new Set<string>();
  // The difficulty matters more than freshness: a recent question of the
  // right difficulty is taken before a fresh one of another.
  const pick = (d: Difficulty): string | null => {
    for (const want of FALLBACK[d]) {
      for (const allowRecent of [false, true]) {
        const pool = live.filter((q) => q.difficulty === want && !used.has(q.id) && (allowRecent || !avoid.has(q.id)));
        if (pool.length > 0) return pool[Math.floor(random() * pool.length) % pool.length].id;
      }
    }
    return null;
  };
  const out: string[] = [];
  for (const slot of SLOTS) {
    const id = pick(slot);
    if (id === null) break;
    used.add(id);
    out.push(id);
  }
  return out.length === QUIZ_QUESTIONS ? out : [];
}

/** Each choice marked against the bank's answer; ten points a right one. */
export function score(questionIds: readonly string[], choices: readonly Choice[]): { correct: boolean[]; points: number } {
  const correct = questionIds.map((id, i) => byId.get(id)?.answer === choices[i]);
  return { correct, points: correct.filter(Boolean).length * QUIZ_POINTS_PER_RIGHT };
}

export function isChoices(v: unknown): v is Choice[] {
  return (
    Array.isArray(v) &&
    v.length === QUIZ_QUESTIONS &&
    v.every((c) => c === 'A' || c === 'B' || c === 'C' || c === 'D')
  );
}
