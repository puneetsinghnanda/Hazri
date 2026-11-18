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
    expect((await h.db.collection('liveListens').get()).size).toBe(0);
  });

  it('join shows in "joined from" with first name, initial and city (LS8), once', async () => {
    await createProfile(h, 'u1', { name: 'Harpreet Kaur', cityId: 'ludhiana' });
    expect((await h.as('u1').post('/api/v1/live/mool-mantar/join')).status).toBe(200);
    expect((await h.as('u1').post('/api/v1/live/mool-mantar/join')).status).toBe(200);
    const g = await group('u1', 'mool-mantar');
    expect(g).toMatchObject({ members: 1, joined: true });
    expect(g.joins).toEqual([{ name: 'Harpreet K.', cityId: 'ludhiana', at: expect.any(String) }]);
    expect(g.memberRows).toEqual([{ name: 'Harpreet K.', cityId: 'ludhiana', minutesMonth: 0 }]);
    expect((await h.as('u1').post('/api/v1/live/nowhere/join')).status).toBe(404);
  });

  it('a mark counts the listener for ten minutes and adds five minutes, but not twice in four (LS7, LS7a)', async () => {
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
    // Ten minutes after u2's only mark, u2 is no longer listening.
    h.clock.advance(6 * 60);
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
});
