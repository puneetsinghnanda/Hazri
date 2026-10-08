// The common rules of 01-accounts §6.0 at the HTTP seam, with no Firestore:
// every request below is refused before any route touches the database.
import request from 'supertest';
import type { Firestore } from 'firebase-admin/firestore';
import { createApp } from '../../src/app';
import { isAdminToken } from '../../src/auth';
import type { VerifiedToken } from '../../src/deps';
import { MemoryMailer } from '../../src/email/mailer';
import { MemoryMessenger } from '../../src/notifications/messenger';

const tokens: Record<string, VerifiedToken> = {
  anon: { uid: 'u1', firebase: { sign_in_provider: 'anonymous' } },
  googleOther: { uid: 'g2', email: 'someone@gmail.com', email_verified: true, firebase: { sign_in_provider: 'google.com' } },
  googleUnverified: { uid: 'g3', email: 'puneetsingh1802@gmail.com', email_verified: false, firebase: { sign_in_provider: 'google.com' } },
  passwordAdmin: { uid: 'g4', email: 'puneetsingh1802@gmail.com', email_verified: true, firebase: { sign_in_provider: 'password' } },
  admin: { uid: 'g5', email: 'puneetsingh1802@gmail.com', email_verified: true, firebase: { sign_in_provider: 'google.com' } },
};

const app = createApp({
  db: {} as Firestore,
  verifier: {
    verifyIdToken: async (t: string) => {
      const v = tokens[t];
      if (!v) throw new Error('bad token');
      return v;
    },
  },
  mailer: new MemoryMailer(),
  clock: { now: () => new Date('2026-10-08T06:00:00Z') },
  messenger: new MemoryMessenger(),
});

describe('authentication (§6.0, A2)', () => {
  it('no token → 401 UNAUTHENTICATED with the error body', async () => {
    const res = await request(app).get('/api/v1/profile');
    expect(res.status).toBe(401);
    expect(res.body).toEqual({ error: { code: 'UNAUTHENTICATED', message: 'Sign-in required' } });
  });
  it('an invalid token → 401', async () => {
    const res = await request(app).get('/api/v1/profile').set('Authorization', 'Bearer nope');
    expect(res.status).toBe(401);
  });
  it('a malformed JSON body → 400 INVALID_REQUEST', async () => {
    const res = await request(app)
      .post('/api/v1/profile')
      .set('Authorization', 'Bearer anon')
      .set('Content-Type', 'application/json')
      .send('{not json');
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('INVALID_REQUEST');
  });
  it('an unknown endpoint → 404 NOT_FOUND', async () => {
    const res = await request(app).get('/api/v1/nothing').set('Authorization', 'Bearer anon');
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe('NOT_FOUND');
  });
  it('validation runs before any read: 400 with every failing field (C11)', async () => {
    const res = await request(app).post('/api/v1/profile').set('Authorization', 'Bearer anon').send({ name: 'A' });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe('VALIDATION_ERROR');
    expect(Object.keys(res.body.error.fields).sort()).toEqual(['cityId', 'email', 'name']);
  });
  it('an unexpected exception → 500 INTERNAL "Something went wrong" (A3)', async () => {
    // {} as Firestore has no .doc(): the route throws a TypeError.
    const res = await request(app).get('/api/v1/profile').set('Authorization', 'Bearer anon');
    expect(res.status).toBe(500);
    expect(res.body).toEqual({ error: { code: 'INTERNAL', message: 'Something went wrong' } });
  });
});

describe('admin access (11-admin AC3, §8)', () => {
  for (const t of ['anon', 'googleOther', 'googleUnverified', 'passwordAdmin']) {
    it(`${t} → 403 NOT_ADMIN`, async () => {
      const res = await request(app).get('/api/v1/admin/banis').set('Authorization', `Bearer ${t}`);
      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('NOT_ADMIN');
    });
  }
  it('no token → 401', async () => {
    expect((await request(app).get('/api/v1/admin/dashboard')).status).toBe(401);
  });
  it('the admin reads the bani list', async () => {
    const res = await request(app).get('/api/v1/admin/banis').set('Authorization', 'Bearer admin');
    expect(res.status).toBe(200);
    expect(res.body.banis[0]).toEqual({ id: 'JAPJ', nameEn: 'Japji Sahib', namePa: 'ਜਪੁ ਜੀ ਸਾਹਿਬ', nameHi: 'जपु जी साहिब' });
  });
  it('CORS preflight is answered for the admin site', async () => {
    const res = await request(app)
      .options('/api/v1/admin/dashboard')
      .set('Origin', 'https://hazri-admin.web.app')
      .set('Access-Control-Request-Method', 'GET')
      .set('Access-Control-Request-Headers', 'authorization');
    expect(res.status).toBe(204);
    expect(res.headers['access-control-allow-origin']).toBe('https://hazri-admin.web.app');
  });
  it('isAdminToken', () => {
    expect(isAdminToken(tokens.admin)).toBe(true);
    expect(isAdminToken({ ...tokens.admin, email: 'PuneetSingh1802@gmail.com' })).toBe(true);
    expect(isAdminToken(tokens.passwordAdmin)).toBe(false);
  });
});
