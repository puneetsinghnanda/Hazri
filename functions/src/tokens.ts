// Link tokens (01-accounts.md §6.0 "Token creation", §4.4).
import { randomBytes } from 'node:crypto';
import { VERIFY_LINK_BASE } from './config';
import { sha256Hex } from './validation';

export type TokenPurpose = 'VERIFY_EMAIL' | 'RESTORE_PROFILE' | 'CHANGE_EMAIL';
export type TokenStatus = 'ACTIVE' | 'USED' | 'SUPERSEDED';

export const RAW_TOKEN_RE = /^[A-Za-z0-9_-]{43}$/;

export interface NewToken {
  raw: string;
  hash: string;
  link: string;
}

/** 32 random bytes, base64url (43 characters); only the SHA-256 is stored. */
export function newToken(): NewToken {
  const raw = randomBytes(32).toString('base64url');
  return { raw, hash: sha256Hex(raw), link: linkFor(raw) };
}

export function linkFor(raw: string): string {
  return `${VERIFY_LINK_BASE}?token=${raw}`;
}

export function isRawToken(t: unknown): t is string {
  return typeof t === 'string' && RAW_TOKEN_RE.test(t);
}
