// 02-notifications AN1-AN8 (owner, 2026-11-19, option B) against the emulator.
import { clearFirestore, createProfile, describeEmu, harness, Harness } from './helpers';

describeEmu('announcements', () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
    h.clock.set('2026-11-19T06:00:00Z');
  });

  const token = (uid: string, t: string, locale: string, announcements?: boolean) =>
    h.as(uid).post('/api/v1/devices/fcm-token', { token: t, locale, tz: 'Asia/Kolkata', ...(announcements === undefined ? {} : { announcements }) });

  const texts = {
    title: { pa: 'ਗੁਰਪੁਰਬ ਦੀਆਂ ਵਧਾਈਆਂ', hi: '', en: 'Gurpurab greetings' },
    body: { pa: 'ਅੱਜ ਸ਼ਾਮ ਨੂੰ ਕੀਰਤਨ', hi: '', en: 'Kirtan this evening' },
    message: { pa: '', hi: '', en: 'Join the **sangat** at 7 pm.' },
  };

  it('reaches every profile with a token, each in its language, and skips those switched off (AN1-AN3, AN7)', async () => {
    await createProfile(h, 'u1', { name: 'Harpreet Kaur', cityId: 'ludhiana' });
    await createProfile(h, 'u2', { name: 'Gurdeep Singh', cityId: 'amritsar', email: '' });
    await createProfile(h, 'u3', { name: 'Simran Kaur', cityId: 'new_delhi', email: '' });
    expect((await token('u1', 'tok-pa', 'pa')).status).toBe(200);
    await token('u2', 'tok-hi', 'hi');
    await token('u3', 'tok-off', 'en', false);

    const aud = await h.admin().get('/api/v1/admin/announcements/audience');
    expect(aud.body).toEqual({ reach: 2, optedOut: 1, byLang: { pa: 1, hi: 1, en: 0 } });

    const res = await h.admin().post('/api/v1/admin/announcements', texts);
    expect(res.status).toBe(201);
    expect(res.body.announcement).toMatchObject({ sent: 2, failed: 0, optedOut: 1, opened: 0 });
    const byToken = Object.fromEntries(h.messenger.sent.map((m) => [m.token, m]));
    expect(byToken['tok-pa']).toMatchObject({ title: 'ਗੁਰਪੁਰਬ ਦੀਆਂ ਵਧਾਈਆਂ', channelId: 'announcements_v1' });
    // No Hindi written: English instead.
    expect(byToken['tok-hi']).toMatchObject({ title: 'Gurpurab greetings', body: 'Kirtan this evening' });
    expect(byToken['tok-off']).toBeUndefined();
    const id = res.body.announcement.id as string;
    expect(byToken['tok-pa'].data).toEqual({ kind: 'ANNOUNCEMENT', groupId: '', route: `/announcement/${id}`, announcementId: id });
  });

  it('a tap is counted once per profile and the admin sees who, with name and city (AN5, AN6)', async () => {
    await createProfile(h, 'u1', { name: 'Harpreet Kaur', cityId: 'ludhiana' });
    await token('u1', 'tok', 'en');
    const id = (await h.admin().post('/api/v1/admin/announcements', texts)).body.announcement.id as string;

    const msg = await h.as('u1').get(`/api/v1/announcements/${id}?lang=pa`);
    // Punjabi has no long message: the English one is shown.
    expect(msg.body).toMatchObject({ title: 'ਗੁਰਪੁਰਬ ਦੀਆਂ ਵਧਾਈਆਂ', message: 'Join the **sangat** at 7 pm.' });
    expect((await h.as('u1').post(`/api/v1/announcements/${id}/opened`)).body.result).toBe('COUNTED');
    expect((await h.as('u1').post(`/api/v1/announcements/${id}/opened`)).body.result).toBe('ALREADY');
    expect((await h.as('anon').post(`/api/v1/announcements/${id}/opened`)).body.error.code).toBe('NO_PROFILE');

    const list = await h.admin().get('/api/v1/admin/announcements');
    expect(list.body.announcements[0]).toMatchObject({ id, opened: 1, sent: 1 });
    const opens = await h.admin().get(`/api/v1/admin/announcements/${id}/opens`);
    expect(opens.body.opens).toEqual([{ name: 'Harpreet Kaur', cityId: 'ludhiana', at: expect.any(String) }]);
  });

  it('an uninstalled app is counted as failed and its token removed (FM4)', async () => {
    await createProfile(h, 'u1');
    await token('u1', 'gone', 'en');
    h.messenger.dead.add('gone');
    const res = await h.admin().post('/api/v1/admin/announcements', texts);
    expect(res.body.announcement).toMatchObject({ sent: 0, failed: 1 });
    expect((await h.db.collection('fcmTokens').get()).size).toBe(0);
  });

  it('refuses an empty or too long message, and anybody but the admin', async () => {
    const empty = await h.admin().post('/api/v1/admin/announcements', { title: {}, body: {} });
    expect(empty.status).toBe(400);
    expect(Object.keys(empty.body.error.fields).sort()).toEqual(['body', 'title']);
    const long = await h.admin().post('/api/v1/admin/announcements', { ...texts, title: { ...texts.title, en: 'x'.repeat(66) } });
    expect(long.body.error.fields).toEqual({ 'title.en': 'At most 65 characters' });
    expect((await h.as('u1').post('/api/v1/admin/announcements', texts)).status).toBe(403);
  });

  it('a test goes only to the profile with that email, in the language asked, even with its switch off (AN10)', async () => {
    await createProfile(h, 'me', { name: 'Puneet Singh', cityId: 'ludhiana', email: 'owner@example.com' });
    await createProfile(h, 'u2', { name: 'Gurdeep Singh', cityId: 'amritsar', email: '' });
    await token('me', 'tok-me', 'en', false);
    await token('u2', 'tok-u2', 'pa');

    const res = await h.admin().post('/api/v1/admin/announcements', { ...texts, testEmail: 'Owner@Example.com', testLang: 'pa' });
    expect(res.status).toBe(201);
    expect(res.body.announcement).toMatchObject({ sent: 1, testTo: 'owner@example.com' });
    expect(h.messenger.sent.map((m) => m.token)).toEqual(['tok-me']);
    expect(h.messenger.sent[0].title).toBe('ਗੁਰਪੁਰਬ ਦੀਆਂ ਵਧਾਈਆਂ');

    const nobody = await h.admin().post('/api/v1/admin/announcements', { ...texts, testEmail: 'nobody@example.com' });
    expect(nobody.status).toBe(404);
    await createProfile(h, 'u3', { name: 'Simran Kaur', cityId: 'new_delhi', email: 'simran@example.com' });
    const noPhone = await h.admin().post('/api/v1/admin/announcements', { ...texts, testEmail: 'simran@example.com' });
    expect(noPhone.body.error.code).toBe('NO_DEVICE');
  });
});
