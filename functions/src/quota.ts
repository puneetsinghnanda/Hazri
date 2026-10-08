// The email quota check of 01-accounts.md §6.0, as a pure function over the
// profile's `emailQuota` and the current time (both in milliseconds).
import { EMAIL_COOLDOWN_SECONDS, EMAIL_MAX_PER_WINDOW, EMAIL_WINDOW_SECONDS } from './config';

export interface EmailQuota {
  lastSentAtMs: number | null;
  windowStartAtMs: number | null;
  countInWindow: number;
}

export type QuotaResult =
  | { ok: true; next: { lastSentAtMs: number; windowStartAtMs: number; countInWindow: number } }
  | { ok: false; retryAfterSeconds: number };

export function checkEmailQuota(q: EmailQuota, nowMs: number): QuotaResult {
  // 1. Cooldown since the last send.
  if (q.lastSentAtMs !== null) {
    const elapsed = (nowMs - q.lastSentAtMs) / 1000;
    if (elapsed < EMAIL_COOLDOWN_SECONDS) {
      return { ok: false, retryAfterSeconds: Math.ceil(EMAIL_COOLDOWN_SECONDS - elapsed) };
    }
  }
  // 2. A new window.
  if (q.windowStartAtMs === null || (nowMs - q.windowStartAtMs) / 1000 >= EMAIL_WINDOW_SECONDS) {
    return { ok: true, next: { lastSentAtMs: nowMs, windowStartAtMs: nowMs, countInWindow: 1 } };
  }
  // 3. Full window.
  if (q.countInWindow >= EMAIL_MAX_PER_WINDOW) {
    const elapsed = (nowMs - q.windowStartAtMs) / 1000;
    return { ok: false, retryAfterSeconds: Math.ceil(EMAIL_WINDOW_SECONDS - elapsed) };
  }
  // 4–5.
  return {
    ok: true,
    next: { lastSentAtMs: nowMs, windowStartAtMs: q.windowStartAtMs, countInWindow: q.countInWindow + 1 },
  };
}
