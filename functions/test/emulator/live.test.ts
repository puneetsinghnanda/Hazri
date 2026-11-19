// 15-live-sangat.md against the emulator: joining, the listening mark, the
// counts and the minutes, and that nothing is written without a profile.
import { clearFirestore, createProfile, describeEmu, harness, Harness } from './helpers';

describeEmu('live sangat', () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
    h.clock.set('2026-11-18T06:00:00Z'); // 11:30 IST
  });

  const live = async (uid: string) => {
    const res = await h.as(uid).get('/api/v1/live');
    expect(res.status).toBe(200);
    return res.body as { groups: Array<Record<string, unknown> & { id: string }> };
  };
  const group = async (uid: string, id: string) => (await live(uid)).groups.find((g) => g.id === id)!;

  it('three groups, none listening, for an install with no profile; and its writes are refused (LS15)', async () => {
    const body = await live('anon');
    expect(body.groups.map((g) => g.id)).toEqual(['naam-simran', 'mool-mantar', 'chaupai-sahib']);
    expect(body.groups[0]).toMatchObject({ listening: 0, members: 0, minutesToday: 0, joined: false, myMinutesMonth: null });
    expect((await h.as('anon').post('/api/v1/live/naam-simran/listen')).body.error.code).toBe('NO_PROFILE');
    expect((await h.as('anon').post('/api/v1/live/naam-simran/join')).body.error.code).toBe('NO_PROFILE');
    for (const g of ['naam-simran', 'mool-mantar', 'chaupai-sahib']) {
      expect((await h.db.collection(`liveGroups/${g}/listens`).get()).size).toBe(0);
    }
  });

  it('join shows in "joined from" with first name, initial and city (LS8), once', async () => {
    await createProfile(h, 'u1', { name: 'Harpreet Kaur', cityId: 'ludhiana' });
    expect((await h.as('u1').post('/api/v1/live/mool-mantar/join')).status).toBe(200);
    expect((await h.as('u1').post('/api/v1/live/mool-mantar/join')).status).toBe(200);
    // Joining rebuilds the snapshot at once: no two-minute wait (2026-11-19).
    const g = await group('u1', 'mool-mantar');
    expect(g).toMatchObject({ members: 1, joined: true });
    expect(g.joins).toEqual([{ name: 'Harpreet K.', cityId: 'ludhiana', at: expect.any(String) }]);
    expect(g.memberRows).toEqual([{ name: 'Harpreet K.', cityId: 'ludhiana', minutesMonth: 0 }]);
    expect((await h.as('u1').post('/api/v1/live/nowhere/join')).status).toBe(404);
  });

  it('a mark counts the listener for 24 hours and adds five minutes, but not twice in four (LS7, LS7a)', async () => {
    await createProfile(h, 'u1', { name: 'Harpreet Kaur', cityId: 'ludhiana' });
    await createProfile(h, 'u2', { name: 'Gurdeep Singh', cityId: 'amritsar', email: 'g@example.com' });
    await h.as('u1').post('/api/v1/live/naam-simran/join');
    expect((await h.as('u1').post('/api/v1/live/naam-simran/listen')).body.result).toBe('COUNTED');
    expect((await h.as('u1').post('/api/v1/live/naam-simran/listen')).body.result).toBe('TOO_SOON');
    await h.as('u2').post('/api/v1/live/naam-simran/listen');
    h.clock.advance(5 * 60);
    expect((await h.as('u1').post('/api/v1/live/naam-simran/listen')).body.result).toBe('COUNTED');
    const g = await group('u1', 'naam-simran');
    expect(g).toMatchObject({ listening: 2, cities: 2, minutesToday: 15, minutesMonth: 15 });
    expect([...(g.cityIds as string[])].sort()).toEqual(['amritsar', 'ludhiana']);
    // A member's own minutes this month: u1's two marks.
    expect(g.myMinutesMonth).toBe(10);
    expect((await group('u2', 'naam-simran')).joined).toBe(false);
    // Still counted 23 hours on; a day after u2's only mark, u2 is not.
    h.clock.advance(23 * 3600 - 5 * 60);
    expect((await group('u1', 'naam-simran')).listening).toBe(2);
    h.clock.advance(3601);
    expect((await group('u1', 'naam-simran')).listening).toBe(1);
  });

  it('the snapshot is shared for two minutes, then rebuilt', async () => {
    await createProfile(h, 'u1', { name: 'Harpreet Kaur', cityId: 'ludhiana' });
    expect((await group('u1', 'chaupai-sahib')).listening).toBe(0);
    await h.as('u1').post('/api/v1/live/chaupai-sahib/listen');
    expect((await group('u1', 'chaupai-sahib')).listening).toBe(0);
    h.clock.advance(121);
    expect((await group('u1', 'chaupai-sahib')).listening).toBe(1);
  });

  it('youCounted says whether the snapshot already holds the caller (LS7b)', async () => {
    await createProfile(h, 'u1', { name: 'Harpreet Kaur', cityId: 'ludhiana' });
    expect((await group('u1', 'naam-simran')).youCounted).toBe(false);
    await h.as('u1').post('/api/v1/live/naam-simran/listen');
    // The snapshot from before the mark is still fresh: the app adds itself.
    expect((await group('u1', 'naam-simran'))).toMatchObject({ listening: 0, youCounted: false });
    h.clock.advance(121);
    expect((await group('u1', 'naam-simran'))).toMatchObject({ listening: 1, youCounted: true });
    expect((await group('anon', 'naam-simran')).youCounted).toBe(false);
  });

  it('leaving shows at once too', async () => {
    await createProfile(h, 'u1', { name: 'Harpreet Kaur', cityId: 'ludhiana' });
    await h.as('u1').post('/api/v1/live/chaupai-sahib/join');
    expect((await group('u1', 'chaupai-sahib')).members).toBe(1);
    await h.as('u1').post('/api/v1/live/chaupai-sahib/leave');
    expect((await group('u1', 'chaupai-sahib'))).toMatchObject({ members: 0, joined: false, memberRows: [] });
  });
});
