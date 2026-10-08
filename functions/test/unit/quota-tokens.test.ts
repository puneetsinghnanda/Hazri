import { createHash } from 'node:crypto';
import { checkEmailQuota } from '../../src/quota';
import { isRawToken, linkFor, newToken } from '../../src/tokens';

const S = 1000;
const DAY = 86400 * S;

describe('email quota (01-accounts §6.0)', () => {
  const t0 = 1_800_000_000_000;
  it('first send opens a window', () => {
    expect(checkEmailQuota({ lastSentAtMs: null, windowStartAtMs: null, countInWindow: 0 }, t0)).toEqual({
      ok: true,
      next: { lastSentAtMs: t0, windowStartAtMs: t0, countInWindow: 1 },
    });
  });
  it('within 60 s → retryAfterSeconds rounded up (V9)', () => {
    const r = checkEmailQuota({ lastSentAtMs: t0, windowStartAtMs: t0, countInWindow: 1 }, t0 + 10.5 * S);
    expect(r).toEqual({ ok: false, retryAfterSeconds: 50 });
  });
  it('exactly 60 s later is allowed and counts', () => {
    const r = checkEmailQuota({ lastSentAtMs: t0, windowStartAtMs: t0, countInWindow: 1 }, t0 + 60 * S);
    expect(r).toEqual({ ok: true, next: { lastSentAtMs: t0 + 60 * S, windowStartAtMs: t0, countInWindow: 2 } });
  });
  it('6th in 24 h is refused until the window ends (V10)', () => {
    const r = checkEmailQuota({ lastSentAtMs: t0 + 3600 * S, windowStartAtMs: t0, countInWindow: 5 }, t0 + 7200 * S);
    expect(r).toEqual({ ok: false, retryAfterSeconds: 86400 - 7200 });
  });
  it('the window resets after 24 h', () => {
    const r = checkEmailQuota({ lastSentAtMs: t0 + 3600 * S, windowStartAtMs: t0, countInWindow: 5 }, t0 + DAY);
    expect(r).toEqual({ ok: true, next: { lastSentAtMs: t0 + DAY, windowStartAtMs: t0 + DAY, countInWindow: 1 } });
  });
});

describe('tokens (01-accounts §6.0)', () => {
  it('is 43 base64url characters; only its sha256 is the id', () => {
    const t = newToken();
    expect(t.raw).toMatch(/^[A-Za-z0-9_-]{43}$/);
    expect(t.hash).toBe(createHash('sha256').update(t.raw).digest('hex'));
    expect(t.link).toBe(`https://hazri-dfcc1.web.app/verify?token=${t.raw}`);
    expect(linkFor('x')).toBe('https://hazri-dfcc1.web.app/verify?token=x');
  });
  it('two tokens differ', () => {
    expect(newToken().raw).not.toBe(newToken().raw);
  });
  it('isRawToken rejects anything else (V13)', () => {
    expect(isRawToken('a'.repeat(43))).toBe(true);
    expect(isRawToken('a'.repeat(42))).toBe(false);
    expect(isRawToken('a'.repeat(44))).toBe(false);
    expect(isRawToken(`${'a'.repeat(42)}=`)).toBe(false);
    expect(isRawToken(undefined)).toBe(false);
    expect(isRawToken('')).toBe(false);
  });
});
