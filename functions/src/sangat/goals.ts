// Starting a built-in group's goal from its template (BI3, BI4, 11-admin 4.2),
// and validating a template.
import type { DocumentReference, Transaction } from 'firebase-admin/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import {
  GOAL_DAYS_MAX,
  GOAL_DAYS_MIN,
  GOAL_TARGET_MAX,
  GOAL_TARGET_MIN,
  GROUP_NAME_MAX,
  SIMRAN_MINUTES_MAX,
  SIMRAN_MINUTES_MIN,
} from '../config';
import { isBaniId } from '../reference';
import { addDays } from '../time';
import { codePoints } from '../validation';
import { GoalTemplate, goalIdFor } from './model';

/** Creates goal number `sequence` (deterministic id) starting `today`; sets it current. */
export function writeGoalFromTemplate(
  tx: Transaction,
  groupRef: DocumentReference,
  template: GoalTemplate,
  sequence: number,
  today: string,
): string {
  const goalId = goalIdFor(sequence);
  tx.set(groupRef.collection('goals').doc(goalId), {
    type: template.type,
    baniId: template.type === 'BANI' ? template.baniId : null,
    simranMinutes: template.type === 'SIMRAN' ? template.simranMinutes : null,
    target: template.target,
    startDay: today,
    endDay: addDays(today, template.lengthDays - 1),
    status: 'ACTIVE',
    total: 0,
    dayTotals: {},
    completedAt: null,
    sequence,
    archivedAt: null,
    createdAt: FieldValue.serverTimestamp(),
  });
  tx.update(groupRef, { currentGoalId: goalId, updatedAt: FieldValue.serverTimestamp() });
  return goalId;
}

const isInt = (v: unknown, min: number, max: number): v is number =>
  typeof v === 'number' && Number.isInteger(v) && v >= min && v <= max;

export function parseTemplate(raw: unknown): { ok: true; value: GoalTemplate } | { ok: false; fields: Record<string, string> } {
  const fields: Record<string, string> = {};
  const o = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
  if (o.type !== 'BANI' && o.type !== 'SIMRAN') fields['goalTemplate.type'] = 'type must be BANI or SIMRAN';
  if (o.type === 'BANI' && !isBaniId(o.baniId)) fields['goalTemplate.baniId'] = 'Choose a bani';
  if (o.type === 'SIMRAN' && !isInt(o.simranMinutes, SIMRAN_MINUTES_MIN, SIMRAN_MINUTES_MAX)) {
    fields['goalTemplate.simranMinutes'] = `Minutes must be ${SIMRAN_MINUTES_MIN}–${SIMRAN_MINUTES_MAX}`;
  }
  if (!isInt(o.target, GOAL_TARGET_MIN, GOAL_TARGET_MAX)) fields['goalTemplate.target'] = 'Target must be 1–1,000,000';
  if (!isInt(o.lengthDays, GOAL_DAYS_MIN, GOAL_DAYS_MAX)) fields['goalTemplate.lengthDays'] = 'Length must be 1–365 days';
  if (Object.keys(fields).length > 0) return { ok: false, fields };
  return {
    ok: true,
    value: {
      type: o.type as 'BANI' | 'SIMRAN',
      baniId: o.type === 'BANI' ? (o.baniId as string) : null,
      simranMinutes: o.type === 'SIMRAN' ? (o.simranMinutes as number) : null,
      target: o.target as number,
      lengthDays: o.lengthDays as number,
    },
  };
}

export function parseNames(raw: unknown): { ok: true; value: { en: string; pa: string; hi: string } } | { ok: false; fields: Record<string, string> } {
  const o = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
  const fields: Record<string, string> = {};
  const out: Record<string, string> = {};
  for (const lang of ['en', 'pa', 'hi']) {
    const v = typeof o[lang] === 'string' ? (o[lang] as string).trim() : '';
    const n = codePoints(v);
    if (n < 1 || n > GROUP_NAME_MAX) fields[`names.${lang}`] = `Name must be 1–${GROUP_NAME_MAX} characters`;
    out[lang] = v;
  }
  if (Object.keys(fields).length > 0) return { ok: false, fields };
  return { ok: true, value: { en: out.en, pa: out.pa, hi: out.hi } };
}
