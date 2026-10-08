// Shared set-up for the emulator tests. They run only when the Firestore
// emulator is up (FIRESTORE_EMULATOR_HOST set, as `firebase emulators:exec`
// does); otherwise every suite is skipped, so `npm run test:emulator` with no
// emulator is a no-op rather than a failure.
import { getApps, initializeApp } from 'firebase-admin/app';
import { Firestore, getFirestore } from 'firebase-admin/firestore';
import type { Express } from 'express';
import request from 'supertest';
import { createApp } from '../../src/app';
import type { VerifiedToken } from '../../src/deps';
import { MemoryMailer } from '../../src/email/mailer';
import { MemoryMessenger } from '../../src/notifications/messenger';

export const PROJECT_ID = 'demo-hazri';
export const hasEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
export const describeEmu = hasEmulator ? describe : describe.skip;

let db: Firestore | null = null;
export function testDb(): Firestore {
  if (!db) {
    if (getApps().length === 0) initializeApp({ projectId: PROJECT_ID });
    db = getFirestore();
    db.settings({ ignoreUndefinedProperties: true });
  }
  return db;
}

export async function clearFirestore(): Promise<void> {
  const host = process.env.FIRESTORE_EMULATOR_HOST;
  const res = await fetch(`http://${host}/emulator/v1/projects/${PROJECT_ID}/databases/(default)/documents`, { method: 'DELETE' });
  if (!res.ok) throw new Error(`could not clear the emulator: ${res.status}`);
}

export class TestClock {
  constructor(public t: Date = new Date('2026-10-08T06:00:00Z')) {}
  now(): Date {
    return this.t;
  }
  set(iso: string): void {
    this.t = new Date(iso);
  }
  advance(seconds: number): void {
    this.t = new Date(this.t.getTime() + seconds * 1000);
  }
}

/**
 * Tokens: "anon:<uid>" is an anonymous install; "admin" the admin's Google
 * token; "google:<email>" any other Google account.
 */
function verify(token: string): VerifiedToken {
  if (token.startsWith('anon:')) return { uid: token.slice(5), firebase: { sign_in_provider: 'anonymous' } };
  if (token === 'admin') {
    return { uid: 'admin-uid', email: 'puneetsingh1802@gmail.com', email_verified: true, firebase: { sign_in_provider: 'google.com' } };
  }
  if (token.startsWith('google:')) {
    return { uid: `g-${token.slice(7)}`, email: token.slice(7), email_verified: true, firebase: { sign_in_provider: 'google.com' } };
  }
  throw new Error('invalid token');
}

export interface Harness {
  app: Express;
  db: Firestore;
  mailer: MemoryMailer;
  messenger: MemoryMessenger;
  clock: TestClock;
  as(uid: string): Caller;
  admin(): Caller;
}

export interface Caller {
  get(path: string): request.Test;
  post(path: string, body?: object): request.Test;
  patch(path: string, body?: object): request.Test;
  put(path: string, body?: object): request.Test;
  del(path: string, body?: object): request.Test;
}

export function harness(): Harness {
  const db = testDb();
  const mailer = new MemoryMailer();
  const messenger = new MemoryMessenger();
  const clock = new TestClock();
  const app = createApp({ db, verifier: { verifyIdToken: async (t) => verify(t) }, mailer, clock, messenger });
  const callerFor = (token: string): Caller => ({
    get: (p) => request(app).get(p).set('Authorization', `Bearer ${token}`),
    post: (p, b = {}) => request(app).post(p).set('Authorization', `Bearer ${token}`).send(b),
    patch: (p, b = {}) => request(app).patch(p).set('Authorization', `Bearer ${token}`).send(b),
    put: (p, b = {}) => request(app).put(p).set('Authorization', `Bearer ${token}`).send(b),
    del: (p, b = {}) => request(app).delete(p).set('Authorization', `Bearer ${token}`).send(b),
  });
  return { app, db, mailer, messenger, clock, as: (uid) => callerFor(`anon:${uid}`), admin: () => callerFor('admin') };
}

/** The raw token in the last mail sent. */
export function lastToken(mailer: MemoryMailer): string {
  const m = mailer.sent[mailer.sent.length - 1];
  const match = /token=([A-Za-z0-9_-]{43})/.exec(m.text);
  if (!match) throw new Error('no token in the last mail');
  return match[1];
}

export async function createProfile(h: Harness, uid: string, over: Record<string, unknown> = {}) {
  const res = await h.as(uid).post('/api/v1/profile', {
    name: 'Harpreet Kaur',
    email: `${uid}@example.com`,
    phone: '',
    cityId: 'amritsar',
    ...over,
  });
  if (res.status !== 201) throw new Error(`createProfile ${res.status} ${JSON.stringify(res.body)}`);
  return res.body.profile as { profileId: string; email: string; name: string };
}

export const uuid = (n: number): string => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
