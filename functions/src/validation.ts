// 01-accounts.md §5: normalise first, then validate the normalised value.
// The server is authoritative; the app runs the same rules.
import { createHash } from 'node:crypto';
import { isCityId } from './reference';

export const NAME_REGEX = new RegExp("^[\\p{L}\\p{M}][\\p{L}\\p{M} .'\\-]{1,49}$", 'u');
export const EMAIL_REGEX = new RegExp('^[A-Za-z0-9._%+\\-]+@[A-Za-z0-9.\\-]+\\.[A-Za-z]{2,}$', 'u');

export const MESSAGES = {
  nameEmpty: 'Please enter your name',
  nameInvalid: "Name must be 2–50 letters (spaces, . ' - allowed)",
  emailEmpty: 'Please enter your email',
  emailInvalid: 'Please enter a valid email address',
  cityEmpty: 'Please choose your city',
} as const;

/** Length in Unicode code points (§5 "Length checks count Unicode code points"). */
export function codePoints(s: string): number {
  return Array.from(s).length;
}

/** Name: trim; collapse runs of whitespace to one space. */
export function normalizeName(raw: unknown): string {
  return typeof raw === 'string' ? raw.trim().replace(/\s+/gu, ' ') : '';
}

export function validateName(name: string): string | null {
  if (name === '') return MESSAGES.nameEmpty;
  const n = codePoints(name);
  if (n < 2 || n > 50 || !NAME_REGEX.test(name)) return MESSAGES.nameInvalid;
  return null;
}

/** Email: trim (store as typed otherwise). */
export function normalizeEmail(raw: unknown): string {
  return typeof raw === 'string' ? raw.trim() : '';
}

export function emailNormalizedOf(email: string): string {
  return email.trim().toLowerCase();
}

export function validateEmail(email: string): string | null {
  if (email === '') return MESSAGES.emailEmpty;
  if (codePoints(email) > 254 || !EMAIL_REGEX.test(email)) return MESSAGES.emailInvalid;
  return null;
}

/**
 * Phone (§13 D2, P3): every character that is not a digit is removed, a
 * leading `+` is kept if typed; empty becomes null. Always valid.
 */
export function normalizePhone(raw: unknown): string | null {
  if (raw === null || raw === undefined) return null;
  if (typeof raw !== 'string' && typeof raw !== 'number') return null;
  const s = String(raw).trim();
  const plus = s.startsWith('+');
  const digits = s.replace(/\D/g, '');
  if (digits === '') return null;
  return plus ? `+${digits}` : digits;
}

/** City (§13 D9): an id from the app's city list. */
export function validateCityId(raw: unknown): string | null {
  if (typeof raw !== 'string' || raw.trim() === '' || !isCityId(raw.trim())) return MESSAGES.cityEmpty;
  return null;
}

export function sha256Hex(s: string): string {
  return createHash('sha256').update(s, 'utf8').digest('hex');
}

export function emailHashOf(emailNormalized: string): string {
  return sha256Hex(emailNormalized);
}

export interface ProfileInput {
  name: string;
  email: string;
  phone: string | null;
  cityId: string;
}

/** POST /profile body (§6.2 step 1): every failing field in `fields`. */
export function validateProfileInput(body: Record<string, unknown>): { value: ProfileInput } | { fields: Record<string, string> } {
  const name = normalizeName(body.name);
  const email = normalizeEmail(body.email);
  const phone = normalizePhone(body.phone);
  const cityId = typeof body.cityId === 'string' ? body.cityId.trim() : '';
  const fields: Record<string, string> = {};
  const n = validateName(name);
  if (n) fields.name = n;
  const e = validateEmail(email);
  if (e) fields.email = e;
  const c = validateCityId(cityId);
  if (c) fields.cityId = c;
  if (Object.keys(fields).length > 0) return { fields };
  return { value: { name, email, phone, cityId } };
}
