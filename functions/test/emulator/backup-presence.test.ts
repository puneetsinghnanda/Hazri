// 10-backup §10, 07-simran §10 and the small endpoints, against the emulator.
import { gunzipSync } from 'node:zlib';
import request from 'supertest';
import { runBuildGlobeSnapshot } from '../../src/jobs/globe';
import { clearFirestore, createProfile, describeEmu, harness, Harness, lastToken, uuid } from './helpers';

const goalRow = (n: number, updatedAt = '2026-10-01T00:00:00.000Z') => ({
  goal: { id: uuid(n), startDate: '2026-10-01', completedOn: null, createdAt: '2026-10-01T00:00:00.000Z', updatedAt },
  items: [
    {
      id: uuid(100 + n),
      goalId: uuid(n),
      seriesId: uuid(100 + n),
      itemType: 'BANI',
      baniId: 'JAPJ',
      timesPerDay: 1,
      simranMinutes: null,
      durationType: 'EVERY_DAY',
      durationDays: null,
      startDate: '2026-10-01',
      endDate: null,
      removedOn: null,
      reminderTime: '06:40',
      createdAt: '2026-10-01T00:00:00.000Z',
      updatedAt,
    },
  ],
});
const completion = (n: number, localDate: string, updatedAt = '2026-10-08T01:00:00.000Z', deletedAt: string | null = null) => ({
  id: uuid(n),
  localDate,
  baniId: 'JAPJ',
  slot: 'MORNING',
  source: 'READER',
  completedAt: `${localDate}T01:00:00.000Z`,
  updatedAt,
  deletedAt,
});
const sitting = (n: number, localDate: string) => ({
  id: uuid(n),
  localDate,
  startedAt: `${localDate}T02:00:00.000Z`,
  durationS: 300,
  completed: true,
  count: 0,
  source: 'TIMER',
  updatedAt: `${localDate}T02:05:00.000Z`,
  deletedAt: null,
});
const badge = (id: string, earnedOn: string, announcedAt: string | null) => ({
  badgeId: id,
  earnedOn,
  announcedAt,
  createdAt: `${earnedOn}T00:00:00.000Z`,
  updatedAt: `${earnedOn}T00:00:00.000Z`,
});

async function snapshotOf(h: Harness, profileId: string) {
  const base = h.db.doc(`profiles/${profileId}`);
  const [g, w, b] = await Promise.all([base.collection('backupGoals').get(), base.collection('backupWeeks').get(), base.collection('backupBadges').get()]);
  return JSON.stringify([...g.docs, ...w.docs, ...b.docs].map((d) => [d.id, d.data()]));
}

describeEmu('weekly backup (10-backup §6)', () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
  });

  it('manifest before and after; the same request twice gives identical documents (BK8, K-5)', async () => {
    const p = await createProfile(h, 'u1');
    expect((await h.as('u1').get('/api/v1/backup/manifest')).body).toEqual({ lastBackupAt: null, goalIds: [], weeks: {}, rowCount: 0 });
    const body = {
      goals: [goalRow(1)],
      completions: [completion(1, '2026-10-08'), completion(2, '2026-10-01'), completion(3, '2026-09-30', undefined, '2026-10-02T00:00:00.000Z')],
      simranSessions: [sitting(4, '2026-10-08')],
      badges: [badge('JIGYASU', '2026-10-01', '2026-10-01T05:00:00.000Z')],
      final: true,
    };
    const first = await h.as('u1').post('/api/v1/backup', body);
    // The goal, two weeks, the badges and the manifest.
    expect(first.body).toEqual({ result: 'BACKUP_SAVED', rowsReceived: 7, documentsWritten: 5, lastBackupAt: '2026-10-08T06:00:00.000Z' });
    const before = await snapshotOf(h, p.profileId);
    const second = await h.as('u1').post('/api/v1/backup', body);
    expect(second.body.documentsWritten).toBe(1); // the manifest only
    expect(await snapshotOf(h, p.profileId)).toBe(before);

    const m = (await h.as('u1').get('/api/v1/backup/manifest')).body;
    expect(m).toEqual({
      lastBackupAt: '2026-10-08T06:00:00.000Z',
      goalIds: [uuid(1)],
      weeks: { '2026-10-04': 2, '2026-09-27': 2 },
      rowCount: 7,
    });

    const goals = (await h.as('u1').get('/api/v1/backup/goals')).body;
    expect(goals).toEqual({ goals: [goalRow(1)] });
    const weeks = (await h.as('u1').get('/api/v1/backup/weeks?limit=1')).body;
    expect(weeks.weeks).toHaveLength(1);
    expect(weeks.weeks[0].weekId).toBe('2026-09-27');
    // A restore merges by id, so the order inside a week carries no meaning.
    expect(weeks.weeks[0].completions).toHaveLength(2);
    expect(weeks.weeks[0].completions).toEqual(
      expect.arrayContaining([completion(3, '2026-09-30', undefined, '2026-10-02T00:00:00.000Z'), completion(2, '2026-10-01')]),
    );
    expect(weeks.next).toBe('2026-10-04');
    const page2 = (await h.as('u1').get(`/api/v1/backup/weeks?from=${weeks.next}&limit=26`)).body;
    expect(page2.next).toBeNull();
    expect(page2.weeks[0].simranSessions).toEqual([sitting(4, '2026-10-08')]);
    expect((await h.as('u1').get('/api/v1/backup/badges')).body).toEqual({ badges: [badge('JIGYASU', '2026-10-01', '2026-10-01T05:00:00.000Z')] });
  });

  it('BK9: newer wins, a tie keeps the server, an omitted row stays; badges keep the earlier date', async () => {
    const p = await createProfile(h, 'u1');
    await h.as('u1').post('/api/v1/backup', { completions: [completion(1, '2026-10-08'), completion(2, '2026-10-08')] });
    // A newly installed phone sends only its one newer row, and one older copy.
    await h.as('u1').post('/api/v1/backup', {
      completions: [completion(1, '2026-10-08', '2026-10-08T05:00:00.000Z', '2026-10-08T05:00:00.000Z'), { ...completion(2, '2026-10-08', '2026-10-08T01:00:00.000Z'), slot: 'EVENING' }],
      badges: [badge('JIGYASU', '2026-10-05', null)],
    });
    await h.as('u1').post('/api/v1/backup', { badges: [badge('JIGYASU', '2026-10-01', null)] });
    const w = (await h.as('u1').get('/api/v1/backup/weeks')).body.weeks[0];
    expect(w.completions.find((c: { id: string }) => c.id === uuid(1)).deletedAt).toBe('2026-10-08T05:00:00.000Z');
    expect(w.completions.find((c: { id: string }) => c.id === uuid(2)).slot).toBe('MORNING');
    expect((await h.as('u1').get('/api/v1/backup/badges')).body.badges[0].earnedOn).toBe('2026-10-01');
    expect(p.profileId).toBeTruthy();
  });

  it('400 names the first bad row and writes nothing; 413 at 900 KB; 429 at the rate limit', async () => {
    const p = await createProfile(h, 'u1');
    const bad = await h.as('u1').post('/api/v1/backup', { completions: [completion(1, '2026-10-08'), { ...completion(2, '2026-10-08'), slot: 'NOON' }] });
    expect(bad.status).toBe(400);
    expect(bad.body.error.fields).toEqual({ 'completions[1]': 'slot must be one of MORNING, EVENING, BEDTIME, NONE' });
    expect((await h.db.collection(`profiles/${p.profileId}/backupWeeks`).get()).size).toBe(0);

    const huge = Array.from({ length: 2000 }, (_, i) => ({ ...completion(1000 + i, '2026-10-08'), baniId: 'X'.repeat(64) }));
    const fat = Array.from({ length: 2000 }, (_, i) => ({ ...completion(5000 + i, '2026-10-08'), baniId: 'Y'.repeat(64) }));
    expect((await h.as('u1').post('/api/v1/backup', { completions: huge })).status).toBe(200);
    const tooBig = await h.as('u1').post('/api/v1/backup', { completions: fat });
    expect(tooBig.status).toBe(413);
    expect(tooBig.body.error).toEqual({ code: 'BACKUP_TOO_LARGE', message: "This week's backup is too large" });

    // The 400 is refused before the rate limit; the 200 and the 413 count, so
    // 18 more make 20 and the 21st is refused.
    for (let i = 0; i < 18; i++) await h.as('u1').post('/api/v1/backup', {});
    const limited = await h.as('u1').post('/api/v1/backup', {});
    expect(limited.status).toBe(429);
    expect(limited.body.error.retryAfterSeconds).toBeGreaterThan(0);
  });

  it('K-8: after a restore elsewhere, the old phone gets 404 NO_PROFILE', async () => {
    await createProfile(h, 'old', { email: 'k8@example.com' });
    await h.as('new').post('/api/v1/profile/restore-request', { email: 'k8@example.com' });
    await h.as('new').post('/api/v1/tokens/verify', { token: lastToken(h.mailer) });
    for (const path of ['/api/v1/backup/manifest', '/api/v1/backup/goals', '/api/v1/backup/weeks', '/api/v1/backup/badges']) {
      expect((await h.as('old').get(path)).body.error.code).toBe('NO_PROFILE');
    }
    expect((await h.as('old').post('/api/v1/backup', {})).body.error.code).toBe('NO_PROFILE');
    expect((await h.as('new').get('/api/v1/backup/manifest')).status).toBe(200);
  });
});

describeEmu('presence (07-simran §6)', () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
  });

  it('attendance: 404 without a profile; once a day; updatedAt untouched (G-3, G-4)', async () => {
    expect((await h.as('x').post('/api/v1/presence/attendance')).body.error.code).toBe('NO_PROFILE');
    const p = await createProfile(h, 'u1');
    const before = (await h.db.doc(`profiles/${p.profileId}`).get()).get('updatedAt');
    expect((await h.as('u1').post('/api/v1/presence/attendance')).body).toEqual({ result: 'ATTENDANCE_MARKED', day: '2026-10-08' });
    expect((await h.as('u1').post('/api/v1/presence/attendance')).body.day).toBe('2026-10-08');
    const after = await h.db.doc(`profiles/${p.profileId}`).get();
    expect(after.get('lastSeenDay')).toBe('2026-10-08');
    expect(after.get('updatedAt').isEqual(before)).toBe(true);
  });

  it('globe: 503 before the first build; counts across a day change; built twice is the same (G-7, G-14)', async () => {
    expect((await h.as('x').get('/api/v1/presence/globe')).body.error.code).toBe('GLOBE_NOT_READY');
    await createProfile(h, 'a', { email: 'a@example.com', cityId: 'new_delhi' });
    await createProfile(h, 'b', { email: 'b@example.com', cityId: 'new_delhi' });
    await createProfile(h, 'c', { email: 'c@example.com', cityId: 'amritsar' });
    await h.as('a').post('/api/v1/presence/attendance');
    expect(await runBuildGlobeSnapshot(h.db, h.clock.now())).toEqual({ live: 1, counted: 3 });
    expect(await runBuildGlobeSnapshot(h.db, h.clock.now())).toEqual({ live: 1, counted: 3 });

    const res = await request(h.app).get('/api/v1/presence/globe').set('Authorization', 'Bearer anon:x').set('Accept-Encoding', 'gzip').buffer(true).parse((r, cb) => {
      const chunks: Buffer[] = [];
      r.on('data', (c: Buffer) => chunks.push(c));
      r.on('end', () => cb(null, Buffer.concat(chunks)));
    });
    expect(res.headers['content-encoding']).toBe('gzip');
    // supertest may already have unzipped it; the header says what was sent.
    const raw = res.body as Buffer;
    const body = JSON.parse((raw[0] === 0x1f && raw[1] === 0x8b ? gunzipSync(raw) : raw).toString('utf8'));
    expect(body).toMatchObject({ day: '2026-10-08', live: 1, counted: 3, builtAt: expect.stringMatching(/Z$/) });
    expect(body.countries.IN.s['IN-XX'].k).toEqual({ new_delhi: [1, 2], amritsar: [0, 1] });

    // Next IST day: nobody is live until they open the app again.
    expect(await runBuildGlobeSnapshot(h.db, new Date('2026-10-08T18:31:00Z'))).toEqual({ live: 0, counted: 3 });
  });
});

describeEmu('devices, badges and the Vichar library', () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
  });

  it('fcm token: 404 without a profile; saved with the zone offset; deleted (FT1–FT2)', async () => {
    expect((await h.as('x').post('/api/v1/devices/fcm-token', { token: 't', locale: 'pa', tz: 'Asia/Kolkata' })).body.error.code).toBe('NO_PROFILE');
    const p = await createProfile(h, 'u1');
    expect((await h.as('u1').post('/api/v1/devices/fcm-token', { token: 't', locale: 'xx', tz: 'Mars/Base' })).body.error.fields).toEqual({
      locale: 'locale must be pa, hi or en',
      tz: 'tz must be an IANA time zone',
    });
    expect((await h.as('u1').post('/api/v1/devices/fcm-token', { token: 'tok', locale: 'pa', tz: 'Europe/London' })).body).toEqual({ result: 'TOKEN_SAVED' });
    expect((await h.db.doc('fcmTokens/u1').get()).data()).toMatchObject({ profileId: p.profileId, token: 'tok', locale: 'pa', utcOffsetMin: 60, groupIds: [] });
    expect((await h.as('u1').del('/api/v1/devices/fcm-token')).body).toEqual({ result: 'TOKEN_DELETED' });
    expect((await h.db.doc('fcmTokens/u1').get()).exists).toBe(false);
    expect((await h.as('x').del('/api/v1/devices/fcm-token')).status).toBe(404);
  });

  it('badges/sangat: profile needed; 0 without facts', async () => {
    expect((await h.as('x').get('/api/v1/badges/sangat')).body.error.code).toBe('NO_PROFILE');
    await createProfile(h, 'u1');
    expect((await h.as('u1').get('/api/v1/badges/sangat')).body).toEqual({ goalsReached: 0, joins: 0 });
  });

  it('vichar: sorted by title, facts as ordered pairs, untitled skipped', async () => {
    const entries = h.db.collection('content/vichar/entries');
    await entries.doc('b').set({ title: 'Bangla Sahib', kind: 'gurdwara', place: 'New Delhi', minutes: 4, facts: { Where: 'Delhi', Langar: 'Always' } });
    await entries.doc('a').set({ title: 'Anand Karaj', kind: 'nonsense', body: 'One.\n\nTwo.' });
    await entries.doc('c').set({ kind: 'article' });
    const res = await h.as('x').get('/api/v1/vichar/entries');
    expect(res.body).toEqual({
      entries: [
        { id: 'a', title: 'Anand Karaj', kind: 'article', summary: null, body: 'One.\n\nTwo.', minutes: null, place: null, facts: [] },
        {
          id: 'b',
          title: 'Bangla Sahib',
          kind: 'gurdwara',
          summary: null,
          body: null,
          minutes: 4,
          place: 'New Delhi',
          facts: expect.arrayContaining([
            { label: 'Where', value: 'Delhi' },
            { label: 'Langar', value: 'Always' },
          ]),
        },
      ],
    });
  });
});
