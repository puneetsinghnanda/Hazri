// 01-accounts §8.3 R9 (owner's report, 2026-11-21): setting up showed "No
// profile found" at once. A profile removed by hand left owners/{uid} and its
// emailIndex behind, which refused setup and restore while GET said NO_PROFILE.
import { clearFirestore, createProfile, describeEmu, harness, Harness } from './helpers';

describeEmu('leftovers of a profile removed by hand (R9)', () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
    h.clock.set('2026-11-21T06:00:00Z');
  });

  const details = { name: 'Puneet Singh', email: 'owner@example.com', phone: '', cityId: 'ludhiana' };

  it('setting up again on the same phone, with the same email, makes the profile', async () => {
    const first = await createProfile(h, 'u1', details);
    await h.db.doc(`profiles/${first.profileId}`).delete(); // removed by hand
    const again = await h.as('u1').post('/api/v1/profile', details);
    expect(again.status).toBe(201);
    expect((await h.as('u1').get('/api/v1/profile')).body.profile.name).toBe('Puneet Singh');
    const owner = await h.db.doc('owners/u1').get();
    expect(owner.get('profileId')).toBe(again.body.profile.profileId);
  });

  it('the same email from another phone is free once its profile is gone', async () => {
    const first = await createProfile(h, 'u1', details);
    await h.db.doc(`profiles/${first.profileId}`).delete();
    expect((await h.as('u2').post('/api/v1/profile', details)).status).toBe(201);
  });

  it('a restore is not refused as DEVICE_HAS_PROFILE because of a leftover', async () => {
    const gone = await createProfile(h, 'u1', { ...details, email: 'old@example.com' });
    await h.db.doc(`profiles/${gone.profileId}`).delete();
    await createProfile(h, 'u2', details);
    const r = await h.as('u1').post('/api/v1/profile/restore-request', { email: 'owner@example.com' });
    expect(r.body.error?.code).not.toBe('DEVICE_HAS_PROFILE');
  });

  it('a live profile still refuses both, as before', async () => {
    await createProfile(h, 'u1', details);
    expect((await h.as('u1').post('/api/v1/profile', { ...details, email: 'x@example.com' })).body.error.code).toBe('PROFILE_ALREADY_EXISTS');
    expect((await h.as('u2').post('/api/v1/profile', details)).body.error.code).toBe('EMAIL_EXISTS');
  });
});
