// 01-accounts §11 backend checklist, against the Firestore emulator.
import { clearFirestore, createProfile, describeEmu, harness, Harness, lastToken } from './helpers';
import { emailHashOf } from '../../src/validation';

describeEmu('profile (01-accounts §6)', () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
  });

  it('POST 201, GET 200, and the DTO hides private fields (C1, C2)', async () => {
    const res = await h.as('u1').post('/api/v1/profile', { name: ' Harpreet  Kaur ', email: 'Harpreet@Example.com', phone: '', cityId: 'amritsar' });
    expect(res.status).toBe(201);
    expect(res.body.profile).toEqual({
      profileId: expect.any(String),
      name: 'Harpreet Kaur',
      email: 'Harpreet@Example.com',
      phone: null,
      cityId: 'amritsar',
      emailVerified: false,
      createdAt: expect.stringMatching(/Z$/),
      pendingEmail: null,
    });
    const get = await h.as('u1').get('/api/v1/profile');
    expect(get.status).toBe(200);
    expect(get.body.profile.profileId).toBe(res.body.profile.profileId);
    const stored = (await h.db.doc(`profiles/${res.body.profile.profileId}`).get()).data();
    expect(stored?.emailNormalized).toBe('harpreet@example.com');
    expect((await h.db.doc(`emailIndex/${emailHashOf('harpreet@example.com')}`).get()).exists).toBe(true);
  });

  it('409 EMAIL_EXISTS with another case, without data (C8, R1); 409 PROFILE_ALREADY_EXISTS (C10)', async () => {
    await createProfile(h, 'u1', { email: 'a@example.com' });
    const dup = await h.as('u2').post('/api/v1/profile', { name: 'Other Name', email: ' A@EXAMPLE.com ', cityId: 'amritsar' });
    expect(dup.status).toBe(409);
    expect(dup.body).toEqual({ error: { code: 'EMAIL_EXISTS', message: 'An account with this email already exists' } });
    const again = await h.as('u1').post('/api/v1/profile', { name: 'Harpreet Kaur', email: 'b@example.com', cityId: 'amritsar' });
    expect(again.status).toBe(409);
    expect(again.body.error.code).toBe('PROFILE_ALREADY_EXISTS');
  });

  it('C9: two installs with one new email at once: one 201, one 409', async () => {
    const body = { name: 'Same Person', email: 'same@example.com', cityId: 'amritsar' };
    const [a, b] = await Promise.all([h.as('u1').post('/api/v1/profile', body), h.as('u2').post('/api/v1/profile', body)]);
    expect([a.status, b.status].sort()).toEqual([201, 409]);
  });

  it('GET 404 NO_PROFILE, and a stale owner is cleaned up (6.1)', async () => {
    expect((await h.as('nobody').get('/api/v1/profile')).body.error.code).toBe('NO_PROFILE');
    const p = await createProfile(h, 'u1');
    await h.db.doc(`profiles/${p.profileId}`).update({ ownerUid: 'someone-else' });
    expect((await h.as('u1').get('/api/v1/profile')).status).toBe(404);
    expect((await h.db.doc('owners/u1').get()).exists).toBe(false);
  });

  it('verification: one mail per send, quota, verify, used again (V1, V4, V9, V10)', async () => {
    await createProfile(h, 'u1', { email: 'v@example.com' });
    const send = await h.as('u1').post('/api/v1/profile/verification-email');
    expect(send.status).toBe(200);
    expect(send.body).toEqual({ result: 'VERIFICATION_EMAIL_SENT', email: 'v@example.com', cooldownSeconds: 60 });
    expect(h.mailer.sent).toHaveLength(1);
    expect(h.mailer.sent[0].subject).toBe('Confirm your email for Hazri');
    const mails = await h.db.collection('mail').get();
    expect(mails.size).toBe(1);
    expect(mails.docs[0].get('delivery.state')).toBe('SUCCESS');
    expect(JSON.stringify(mails.docs[0].data())).not.toContain('token='); // the raw token is never stored

    const tooSoon = await h.as('u1').post('/api/v1/profile/verification-email');
    expect(tooSoon.status).toBe(429);
    expect(tooSoon.body.error.retryAfterSeconds).toBe(60);

    const first = lastToken(h.mailer);
    h.clock.advance(61);
    await h.as('u1').post('/api/v1/profile/verification-email');
    const second = lastToken(h.mailer);
    // V5: the older link is superseded.
    const old = await h.as('u1').post('/api/v1/tokens/verify', { token: first });
    expect(old.status).toBe(404);
    expect(old.body.error).toEqual({ code: 'TOKEN_INVALID', message: 'This link is invalid or has been replaced by a newer link', purpose: 'VERIFY_EMAIL' });

    const ok = await h.as('u1').post('/api/v1/tokens/verify', { token: second });
    expect(ok.status).toBe(200);
    expect(ok.body).toMatchObject({ result: 'EMAIL_VERIFIED', purpose: 'VERIFY_EMAIL', isOwner: true });
    expect(ok.body.profile.emailVerified).toBe(true);

    const reuse = await h.as('u1').post('/api/v1/tokens/verify', { token: second });
    expect(reuse.body.result).toBe('EMAIL_ALREADY_VERIFIED');
    // V7: another phone opens it: no profile in the answer.
    const other = await h.as('u9').post('/api/v1/tokens/verify', { token: second });
    expect(other.body).toEqual({ result: 'EMAIL_ALREADY_VERIFIED', purpose: 'VERIFY_EMAIL', isOwner: false });

    const already = await h.as('u1').post('/api/v1/profile/verification-email');
    expect(already.body.error.code).toBe('EMAIL_ALREADY_VERIFIED');
  });

  it('V10: the 6th email in 24 h is refused, and the window resets', async () => {
    await createProfile(h, 'u1');
    for (let i = 0; i < 5; i++) {
      expect((await h.as('u1').post('/api/v1/profile/verification-email')).status).toBe(200);
      h.clock.advance(61);
    }
    const sixth = await h.as('u1').post('/api/v1/profile/verification-email');
    expect(sixth.status).toBe(429);
    expect(sixth.body.error.retryAfterSeconds).toBe(86400 - 5 * 61);
    h.clock.advance(86400);
    expect((await h.as('u1').post('/api/v1/profile/verification-email')).status).toBe(200);
  });

  it('V6: expired; V13: malformed', async () => {
    await createProfile(h, 'u1');
    await h.as('u1').post('/api/v1/profile/verification-email');
    h.clock.advance(86400);
    const res = await h.as('u1').post('/api/v1/tokens/verify', { token: lastToken(h.mailer) });
    expect(res.status).toBe(410);
    expect(res.body.error.code).toBe('TOKEN_EXPIRED');
    const bad = await h.as('u1').post('/api/v1/tokens/verify', { token: 'short' });
    expect(bad.body.error).toEqual({ code: 'INVALID_REQUEST', message: 'Invalid link' });
  });

  it('503 EMAIL_NOT_CONFIGURED writes nothing', async () => {
    await createProfile(h, 'u1');
    h.mailer.setConfigured(false);
    const res = await h.as('u1').post('/api/v1/profile/verification-email');
    expect(res.status).toBe(503);
    expect(res.body.error.code).toBe('EMAIL_NOT_CONFIGURED');
    expect((await h.db.collection('verificationTokens').get()).size).toBe(0);
  });

  it('V14: a failed send still answers 200 and records the error', async () => {
    await createProfile(h, 'u1');
    h.mailer.setFailing(true);
    const res = await h.as('u1').post('/api/v1/profile/verification-email');
    expect(res.status).toBe(200);
    const mail = (await h.db.collection('mail').get()).docs[0];
    expect(mail.get('delivery.state')).toBe('ERROR');
  });

  it('restore: R2, R3, R5, R6, R8, R9 and FT3', async () => {
    const p = await createProfile(h, 'old', { email: 'r@example.com' });
    await h.as('old').post('/api/v1/profile/verification-email');
    const oldVerify = lastToken(h.mailer);
    await h.db.doc('fcmTokens/old').set({ profileId: p.profileId, token: 't', locale: 'en', tz: 'UTC', utcOffsetMin: 0 });

    expect((await h.as('old').post('/api/v1/profile/restore-request', { email: 'r@example.com' })).body.error.code).toBe('DEVICE_HAS_PROFILE');
    expect((await h.as('new').post('/api/v1/profile/restore-request', { email: 'nobody@example.com' })).body.error.code).toBe('EMAIL_NOT_FOUND');
    h.clock.advance(61);
    const req = await h.as('new').post('/api/v1/profile/restore-request', { email: ' R@Example.com ' });
    expect(req.body).toEqual({ result: 'RESTORE_EMAIL_SENT', email: 'r@example.com', cooldownSeconds: 60 });
    expect(h.mailer.sent.at(-1)?.subject).toBe('Restore your Hazri profile');
    const restore = lastToken(h.mailer);

    const wrong = await h.as('third').post('/api/v1/tokens/verify', { token: restore });
    expect(wrong.status).toBe(403);
    expect(wrong.body.error.code).toBe('RESTORE_WRONG_DEVICE');

    const ok = await h.as('new').post('/api/v1/tokens/verify', { token: restore });
    expect(ok.body).toMatchObject({ result: 'PROFILE_RESTORED', purpose: 'RESTORE_PROFILE', isOwner: true });
    expect(ok.body.profile.emailVerified).toBe(true);

    expect((await h.as('new').post('/api/v1/tokens/verify', { token: restore })).body.error.code).toBe('TOKEN_ALREADY_USED');
    expect((await h.as('old').get('/api/v1/profile')).status).toBe(404);
    expect((await h.as('old').post('/api/v1/tokens/verify', { token: oldVerify })).body.error.code).toBe('TOKEN_INVALID');
    expect((await h.db.doc('fcmTokens/old').get()).exists).toBe(false);
    expect((await h.as('new').get('/api/v1/profile')).body.profile.profileId).toBe(p.profileId);
  });

  it('R5: the phone made its own profile before opening the restore link', async () => {
    await createProfile(h, 'old', { email: 'r@example.com' });
    await h.as('new').post('/api/v1/profile/restore-request', { email: 'r@example.com' });
    const restore = lastToken(h.mailer);
    await createProfile(h, 'new', { email: 'n@example.com' });
    expect((await h.as('new').post('/api/v1/tokens/verify', { token: restore })).body.error.code).toBe('DEVICE_HAS_PROFILE');
  });

  it('email change while unverified (§6.6, E1–E4, E7)', async () => {
    await createProfile(h, 'u1', { email: 'old@example.com' });
    await h.as('u1').post('/api/v1/profile/verification-email');
    const oldLink = lastToken(h.mailer);
    h.clock.advance(61);
    expect((await h.as('u1').patch('/api/v1/profile/email', { email: ' OLD@example.com' })).body.error.code).toBe('EMAIL_UNCHANGED');
    await createProfile(h, 'u2', { email: 'taken@example.com' });
    expect((await h.as('u1').patch('/api/v1/profile/email', { email: 'taken@example.com' })).body.error.code).toBe('EMAIL_EXISTS');
    const res = await h.as('u1').patch('/api/v1/profile/email', { email: 'New@example.com' });
    expect(res.status).toBe(200);
    expect(res.body).toMatchObject({ result: 'EMAIL_CHANGED', cooldownSeconds: 60, profile: { email: 'New@example.com', emailVerified: false } });
    expect(h.mailer.sent.at(-1)?.to).toBe('New@example.com');
    expect((await h.db.doc(`emailIndex/${emailHashOf('old@example.com')}`).get()).exists).toBe(false);
    expect((await h.as('u1').post('/api/v1/tokens/verify', { token: oldLink })).body.error.code).toBe('TOKEN_INVALID');
    // E7: the old email is free again.
    expect((await h.as('u3').post('/api/v1/profile', { name: 'Third One', email: 'old@example.com', cityId: 'amritsar' })).status).toBe(201);
    // E6: within 60 s of the last email.
    expect((await h.as('u1').patch('/api/v1/profile/email', { email: 'other@example.com' })).status).toBe(429);
  });

  it('verified email change waits for confirmation (13.8, P-5, P-6, P-8, P-9)', async () => {
    await createProfile(h, 'u1', { email: 'a@example.com' });
    await h.as('u1').post('/api/v1/profile/verification-email');
    await h.as('u1').post('/api/v1/tokens/verify', { token: lastToken(h.mailer) });
    h.clock.advance(61);

    const b = await h.as('u1').patch('/api/v1/profile/email', { email: 'b@example.com' });
    expect(b.body).toMatchObject({ result: 'EMAIL_CHANGE_PENDING', profile: { email: 'a@example.com', emailVerified: true, pendingEmail: 'b@example.com' } });
    const bLink = lastToken(h.mailer);
    // b@ is reserved: nobody else can take it (P-9 the other way round).
    expect((await h.as('u2').post('/api/v1/profile', { name: 'Someone Else', email: 'b@example.com', cityId: 'amritsar' })).status).toBe(409);
    // A restore still goes to a@ (P-7) and not to the pending address.
    expect((await h.as('u5').post('/api/v1/profile/restore-request', { email: 'b@example.com' })).body.error.code).toBe('EMAIL_NOT_FOUND');

    h.clock.advance(61);
    const c = await h.as('u1').patch('/api/v1/profile/email', { email: 'c@example.com' });
    expect(c.body.result).toBe('EMAIL_CHANGE_PENDING');
    expect((await h.db.doc(`emailIndex/${emailHashOf('b@example.com')}`).get()).exists).toBe(false); // P-8 released
    expect((await h.as('u1').post('/api/v1/tokens/verify', { token: bLink })).body.error.code).toBe('TOKEN_INVALID');

    const done = await h.as('u1').post('/api/v1/tokens/verify', { token: lastToken(h.mailer) });
    expect(done.body).toMatchObject({ result: 'EMAIL_CHANGED', purpose: 'CHANGE_EMAIL', isOwner: true, profile: { email: 'c@example.com', emailVerified: true, pendingEmail: null } });
    expect((await h.db.doc(`emailIndex/${emailHashOf('a@example.com')}`).get()).exists).toBe(false);
    expect((await h.db.doc(`emailIndex/${emailHashOf('c@example.com')}`).get()).get('reserved')).toBeUndefined();
  });

  it('PATCH /profile: name and city, NOTHING_CHANGED, validation (13.8)', async () => {
    await createProfile(h, 'u1');
    expect((await h.as('u1').patch('/api/v1/profile', { name: 'Harpreet Kaur', cityId: 'amritsar' })).body.error.code).toBe('NOTHING_CHANGED');
    expect((await h.as('u1').patch('/api/v1/profile', { name: 'A' })).body.error.fields).toEqual({ name: "Name must be 2–50 letters (spaces, . ' - allowed)" });
    const ok = await h.as('u1').patch('/api/v1/profile', { cityId: 'new_delhi' });
    expect(ok.body).toMatchObject({ result: 'PROFILE_UPDATED', profile: { cityId: 'new_delhi' } });
    expect((await h.as('nobody').patch('/api/v1/profile', { cityId: 'new_delhi' })).body.error.code).toBe('NO_PROFILE');
  });
});
