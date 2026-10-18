// 08-sangat GG1–GG9, ARCHITECTURE §6.4a and 7.15, against the emulator: the
// member rows' cityId and lastAddDay, the contribution's cityId, and
// GET /groups/{groupId}/globe built, stored, served and rebuilt.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { runSangatProfileSync } from '../../src/jobs/sangat';
import { clearFirestore, createProfile, describeEmu, harness, Harness, uuid } from './helpers';

const japji = (n: number, at = '2026-10-08T05:00:00Z', action = 'ADD') => ({ id: uuid(n), kind: 'BANI', baniId: 'JAPJ', source: 'READER', at, action });

async function customGroup(h: Harness, uid: string, goal: Record<string, unknown> | null = { type: 'BANI', baniId: 'JAPJ', target: 10, endDay: '2026-10-31' }) {
  const g = await h.as(uid).post('/api/v1/sangat/groups', { name: 'Gill Parivar' });
  expect(g.status).toBe(201);
  const id = g.body.group.groupId as string;
  if (goal) expect((await h.as(uid).post(`/api/v1/sangat/groups/${id}/goal`, goal)).status).toBe(200);
  return { id, code: g.body.group.invite.code as string };
}

async function builtInGroup(h: Harness) {
  const res = await h.admin().post('/api/v1/admin/groups/built-in', {
    names: { en: 'Amrit Vela Sangat', pa: 'ਸੰਗਤ', hi: 'संगत' },
    goalTemplate: { type: 'BANI', baniId: 'JAPJ', target: 100, lengthDays: 30 },
  });
  const id = res.body.group.groupId as string;
  expect((await h.admin().post(`/api/v1/admin/groups/${id}/start`)).status).toBe(200);
  return id;
}

const globePath = (id: string) => `/api/v1/sangat/groups/${id}/globe`;

describeEmu("the group's globe (08-sangat GG1–GG9, 7.15)", () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
  });

  it('custom: member rows carry the profile city, a paath sets lastAddDay, and the globe counts per city', async () => {
    const creator = await createProfile(h, 'creator', { email: 'c@example.com', cityId: 'amritsar' });
    const londoner = await createProfile(h, 'londoner', { email: 'l@example.com', cityId: 'london' });
    const { id, code } = await customGroup(h, 'creator');
    await h.as('londoner').post('/api/v1/sangat/join', { code });
    await h.as('anon').post('/api/v1/sangat/join', { code });

    const row = async (key: string) => (await h.db.doc(`groups/${id}/members/${key}`).get()).data();
    expect(await row(`p_${creator.profileId}`)).toMatchObject({ cityId: 'amritsar', lastAddDay: null });
    expect(await row(`p_${londoner.profileId}`)).toMatchObject({ cityId: 'london', lastAddDay: null });
    expect(await row('u_anon')).toMatchObject({ cityId: null, lastAddDay: null });

    await h.as('creator').post('/api/v1/sangat/contributions', { items: [japji(1)] });
    await h.as('anon').post('/api/v1/sangat/contributions', { items: [japji(2, '2026-10-08T05:30:00Z')] });
    expect(await row(`p_${creator.profileId}`)).toMatchObject({ lastAddDay: '2026-10-08', contribution: 1 });
    expect((await h.db.doc(`contributions/p_${creator.profileId}_${uuid(1)}`).get()).get('cityId')).toBe('amritsar');
    expect((await h.db.doc(`contributions/u_anon_${uuid(2)}`).get()).get('cityId')).toBeNull();

    const res = await h.as('londoner').get(globePath(id));
    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      day: '2026-10-08',
      builtAt: '2026-10-08T06:00:00.000Z',
      cities: { amritsar: [1, 1], london: [0, 1] },
      unplaced: { today: 1, members: 1 },
      recent: [
        { cityId: null, at: expect.any(String), amount: 1 },
        { cityId: 'amritsar', at: expect.any(String), amount: 1 },
      ],
    });
    // Never a name or a member key (GG7).
    expect(JSON.stringify(res.body)).not.toMatch(/p_|u_anon|Harpreet/);
    const stored = (await h.db.doc(`groups/${id}/globe/current`).get()).data();
    expect(stored).toMatchObject({ goalId: 'g0001', day: '2026-10-08', cities: { amritsar: [1, 1], london: [0, 1] } });
  });

  it('members only for a custom group, and nobody for a missing or disabled one (as 7.3)', async () => {
    await createProfile(h, 'creator');
    const { id, code } = await customGroup(h, 'creator');
    expect((await h.as('stranger').get(globePath(id))).body.error.code).toBe('GROUP_NOT_FOUND');
    expect((await h.as('stranger').get(globePath('nope'))).status).toBe(404);
    await h.as('m1').post('/api/v1/sangat/join', { code });
    expect((await h.as('m1').get(globePath(id))).status).toBe(200);
    await h.as('m1').post(`/api/v1/sangat/groups/${id}/leave`);
    expect((await h.as('m1').get(globePath(id))).status).toBe(404);
    await h.admin().patch(`/api/v1/admin/groups/${id}`, { status: 'DISABLED' });
    expect((await h.as('creator').get(globePath(id))).body.error.code).toBe('GROUP_NOT_FOUND');
  });

  it('one globe per group, rebuilt only after GROUP_GLOBE_SECONDS; arrivals only the last hour, never a retracted one (GG4, GG6)', async () => {
    const p = await createProfile(h, 'creator', { cityId: 'amritsar' });
    const { id, code } = await customGroup(h, 'creator');
    await h.as('m1').post('/api/v1/sangat/join', { code });
    await h.as('creator').post('/api/v1/sangat/contributions', { items: [japji(1)] });
    const first = (await h.as('creator').get(globePath(id))).body;
    expect(first.recent).toHaveLength(1);

    // Another paath, 60 s later: the stored globe is served unchanged.
    h.clock.advance(60);
    await h.as('m1').post('/api/v1/sangat/contributions', { items: [japji(2)] });
    const cached = (await h.as('m1').get(globePath(id))).body;
    expect(cached).toEqual(first);

    // Past 120 s: built again.
    h.clock.advance(61);
    const rebuilt = (await h.as('m1').get(globePath(id))).body;
    expect(rebuilt.builtAt).toBe('2026-10-08T06:02:01.000Z');
    expect(rebuilt.unplaced).toEqual({ today: 1, members: 1 });
    expect(rebuilt.recent.map((r: { cityId: string | null }) => r.cityId)).toEqual([null, 'amritsar']);

    // A retracted paath is not replayed.
    await h.as('m1').post('/api/v1/sangat/contributions', { items: [japji(2, undefined, 'RETRACT')] });
    h.clock.advance(121);
    expect((await h.as('m1').get(globePath(id))).body.recent.map((r: { cityId: string | null }) => r.cityId)).toEqual(['amritsar']);

    // Nor one received more than GROUP_ARRIVALS_MINUTES ago.
    const old = Timestamp.fromMillis(h.clock.now().getTime() - 61 * 60_000);
    await h.db.doc(`contributions/p_${p.profileId}_${uuid(1)}`).update({ createdAt: old });
    h.clock.advance(121);
    expect((await h.as('m1').get(globePath(id))).body.recent).toEqual([]);
  });

  it('lastAddDay never moves back: a late outbox row for an earlier day leaves it', async () => {
    const p = await createProfile(h, 'creator');
    const { id } = await customGroup(h, 'creator');
    h.clock.set('2026-10-09T06:00:00Z');
    await h.as('creator').post('/api/v1/sangat/contributions', { items: [japji(1, '2026-10-09T05:00:00Z')] });
    await h.as('creator').post('/api/v1/sangat/contributions', { items: [japji(2, '2026-10-08T05:00:00Z')] });
    expect((await h.db.doc(`groups/${id}/members/p_${p.profileId}`).get()).data()).toMatchObject({ contribution: 2, lastAddDay: '2026-10-09' });
    // Yesterday's paath does not make anybody green today.
    h.clock.set('2026-10-10T06:00:00Z');
    expect((await h.as('creator').get(globePath(id))).body.cities).toEqual({ amritsar: [0, 1] });
  });

  it('a row from before 2026-10-17 gets its city on the member’s next counted paath', async () => {
    const p = await createProfile(h, 'creator', { cityId: 'toronto' });
    const { id } = await customGroup(h, 'creator');
    const ref = h.db.doc(`groups/${id}/members/p_${p.profileId}`);
    await ref.update({ cityId: FieldValue.delete(), lastAddDay: FieldValue.delete() });
    await h.as('creator').post('/api/v1/sangat/contributions', { items: [japji(1)] });
    expect((await ref.get()).data()).toMatchObject({ cityId: 'toronto', lastAddDay: '2026-10-08' });
  });

  it('rows from before 2026-10-17 are filled from their profiles on the first build, once (GG2)', async () => {
    const p = await createProfile(h, 'creator', { email: 'c@example.com', cityId: 'toronto' });
    const q = await createProfile(h, 'londoner', { email: 'l@example.com', cityId: 'london' });
    const { id, code } = await customGroup(h, 'creator');
    await h.as('londoner').post('/api/v1/sangat/join', { code });
    await h.as('anon').post('/api/v1/sangat/join', { code });
    for (const key of [`p_${p.profileId}`, `p_${q.profileId}`]) await h.db.doc(`groups/${id}/members/${key}`).update({ cityId: FieldValue.delete() });
    // A globe stored by the build before this one, without the fill.
    await h.db.doc(`groups/${id}/globe/current`).set({
      goalId: 'g0001', day: '2026-10-08', cities: {}, unplaced: { today: 0, members: 3 }, recent: [], builtAt: Timestamp.fromDate(h.clock.now()),
    });
    const body = (await h.as('creator').get(globePath(id))).body;
    expect(body).toMatchObject({ cities: { toronto: [0, 1], london: [0, 1] }, unplaced: { members: 1, today: 0 } });
    expect((await h.db.doc(`groups/${id}/members/p_${q.profileId}`).get()).get('cityId')).toBe('london');
    expect((await h.db.doc(`groups/${id}/globe/current`).get()).get('citiesFilled')).toBe(true);

    const gid = await builtInGroup(h);
    await h.as('londoner').post(`/api/v1/sangat/groups/${gid}/join`);
    await h.db.doc(`groups/${gid}/members/p_${q.profileId}`).update({ cityId: FieldValue.delete() });
    expect((await h.as('passer-by').get(globePath(gid))).body).toMatchObject({ cities: { london: [0, 1] }, unplaced: { members: 0 } });
  });

  it('built-in: count() per city, unplaced from memberCount, open to anybody', async () => {
    const gid = await builtInGroup(h);
    await createProfile(h, 'a', { email: 'a@example.com', cityId: 'amritsar' });
    await createProfile(h, 'b', { email: 'b@example.com', cityId: 'amritsar' });
    for (const u of ['a', 'b', 'anon']) await h.as(u).post(`/api/v1/sangat/groups/${gid}/join`);
    await h.as('a').post('/api/v1/sangat/contributions', { items: [japji(1)] });
    await h.as('anon').post('/api/v1/sangat/contributions', { items: [japji(2)] });
    const body = (await h.as('passer-by').get(globePath(gid))).body;
    expect(body).toMatchObject({ day: '2026-10-08', cities: { amritsar: [1, 2] }, unplaced: { members: 1, today: 1 } });
    expect(body.recent.map((r: { cityId: string | null }) => r.cityId)).toEqual([null, 'amritsar']);
    // Leaving takes the member off.
    await h.as('b').post(`/api/v1/sangat/groups/${gid}/leave`);
    h.clock.advance(121);
    expect((await h.as('passer-by').get(globePath(gid))).body.cities).toEqual({ amritsar: [1, 1] });
  });

  it('profile creation carries the city onto adopted rows; sangatProfileSync follows a city change, twice is a no-op', async () => {
    await createProfile(h, 'creator', { email: 'c@example.com' });
    const { id, code } = await customGroup(h, 'creator');
    await h.as('u1').post('/api/v1/sangat/join', { code });
    await h.as('u1').post('/api/v1/sangat/contributions', { items: [japji(1)] });
    const p = await createProfile(h, 'u1', { email: 'u1@example.com', cityId: 'ludhiana' });
    const ref = h.db.doc(`groups/${id}/members/p_${p.profileId}`);
    expect((await ref.get()).data()).toMatchObject({ cityId: 'ludhiana', lastAddDay: '2026-10-08', contribution: 1 });

    expect((await h.as('u1').patch('/api/v1/profile', { cityId: 'london' })).status).toBe(200);
    const before = { name: 'Harpreet Kaur', cityId: 'ludhiana' };
    const after = { name: 'Harpreet Kaur', cityId: 'london' };
    expect((await runSangatProfileSync(h.db, p.profileId, before, after)).rowsUpdated).toBe(1);
    expect((await runSangatProfileSync(h.db, p.profileId, before, after)).rowsUpdated).toBe(0);
    expect((await ref.get()).get('cityId')).toBe('london');
    expect((await h.as('u1').get(globePath(id))).body.cities).toEqual({ amritsar: [0, 1], london: [1, 1] });
  });

  it('no goal yet: the members are on it, nothing arrives', async () => {
    await createProfile(h, 'creator', { cityId: 'amritsar' });
    const { id } = await customGroup(h, 'creator', null);
    expect((await h.as('creator').get(globePath(id))).body).toMatchObject({ cities: { amritsar: [0, 1] }, recent: [] });
  });

  it('an ended goal keeps its globe as it was, with no arrivals (GG9)', async () => {
    await createProfile(h, 'creator', { cityId: 'amritsar' });
    const { id } = await customGroup(h, 'creator', { type: 'BANI', baniId: 'JAPJ', target: 2, endDay: '2026-10-31' });
    await h.as('creator').post('/api/v1/sangat/contributions', { items: [japji(1)] });
    const live = (await h.as('creator').get(globePath(id))).body;
    expect(live.recent).toHaveLength(1);
    await h.as('creator').post('/api/v1/sangat/contributions', { items: [japji(2)] }); // target met: INACTIVE (CG6)
    const ended = (await h.as('creator').get(globePath(id))).body;
    expect(ended).toEqual({ ...live, recent: [] });
    h.clock.set('2026-10-12T06:00:00Z');
    expect((await h.as('creator').get(globePath(id))).body).toEqual({ ...live, recent: [] });
  });
});
