// Invite codes (08-sangat IV1–IV8, §3): 8 characters from an alphabet with
// no 0, O, 1, I or L, shown as XXXX-XXXX, valid 30 days.
import { randomInt } from 'node:crypto';
import { INVITE_CODE_ALPHABET, INVITE_CODE_LENGTH, INVITE_LINK_BASE } from '../config';

export function generateInviteCode(rand: (max: number) => number = randomInt): string {
  let s = '';
  for (let i = 0; i < INVITE_CODE_LENGTH; i++) s += INVITE_CODE_ALPHABET[rand(INVITE_CODE_ALPHABET.length)];
  return s;
}

/**
 * IV7: typed or pasted, with or without the hyphen, in any case. Returns the
 * 8-character stored form, or null when it cannot be a code.
 */
export function normalizeInviteCode(raw: unknown): string | null {
  if (typeof raw !== 'string') return null;
  const s = raw.toUpperCase().replace(/[\s-]/g, '');
  if (s.length !== INVITE_CODE_LENGTH) return null;
  for (const ch of s) if (!INVITE_CODE_ALPHABET.includes(ch)) return null;
  return s;
}

export function formatInviteCode(code: string): string {
  return `${code.slice(0, 4)}-${code.slice(4)}`;
}

/** IV4: https://hazri-dfcc1.web.app/j/{code}, with the code as shown (XXXX-XXXX). */
export function inviteLink(code: string): string {
  return `${INVITE_LINK_BASE}/${formatInviteCode(code)}`;
}
