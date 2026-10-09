// 02-notifications §11 Functions checklist, against the emulator.
import { runSangatDispatch, runSangatMilestone } from '../../src/jobs/notify';
import { clearFirestore, createProfile, describeEmu, harness, Harness, uuid } from './helpers';

async function groupWithMembers(h: Harness) {
  await createProfile(h, 'creator', { email: 'c@example.com', name: 'Gurdev Singh' });
  const g = await h.as('creator').post('/api/v1/sangat/groups', { name: 'Gill Parivar' });
  const id = g.body.group.groupId as string;
  h.clock.advance(60); // members join after the group exists, as they do on a real clock
  await h.as('creator').post(`/api/v1/sangat/groups/${id}/goal`, { type: 'BANI', baniId: 'JAPJ', target: 100, endDay: '2026-10-31' });
  const delhi = await createProfile(h, 'delhi', { email: 'd@example.com', name: 'Delhi Member' });
  const london = await createProfile(h, 'london', { email: 'l@example.com', name: 'London Member' });
  for (const u of ['delhi', 'london']) {
    h.clock.advance(1); // Delhi joins first, so Delhi is the name the creator hears
    await h.as(u).post('/api/v1/sangat/join', { code: g.body.group.invite.code });
  }
  await h.as('delhi').post('/api/v1/devices/fcm-token', { token: 'tok-delhi', locale: 'pa', tz: 'Asia/Kolkata' });
  await h.as('london').post('/api/v1/devices/fcm-token', { token: 'tok-london', locale: 'en', tz: 'Europe/London' });
  return { id, delhi, london };
}

describeEmu('Sangat pushes (02-notifications §8)', () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
  });

  it('milestone: sent once, at once only to members in their daytime (SG3, T-20)', async () => {
    const { id } = await groupWithMembers(h);
    const now = new Date('2026-10-08T18:00:00Z'); // 23:30 Delhi, 19:00 London
    const before = { target: 100, total: 49, type: 'BANI', baniId: 'JAPJ', endDay: '2026-10-31' };
    const after = { ...before, total: 50 };
    const first = await runSangatMilestone(h.db, h.messenger, id, 'g0001', before, after, now);
    const again = await runSangatMilestone(h.db, h.messenger, id, 'g0001', before, after, now);
    expect(first).toEqual({ notices: 1, sent: 1 });
    expect(again).toEqual({ notices: 0, sent: 0 });
    expect(h.messenger.sent).toHaveLength(1);
    expect(h.messenger.sent[0]).toMatchObject({
      token: 'tok-london',
      title: 'Gill Parivar has reached 50%',
      // Days left count today (the 8th, IST) through the 31st, as the app shows them.
      body: '50 of 100 Japji Sahib, with 24 days to go.',
      data: { kind: 'SANGAT_MILESTONE', groupId: id, route: `/sangat-group/${id}` },
    });

    // Delhi's 07:00 hour, as the hourly run at 02:00 UTC (07:30 IST) sees it:
    // the held notice is delivered by the dispatcher.
    h.messenger.sent.length = 0;
    const morning = await runSangatDispatch(h.db, h.messenger, new Date('2026-10-09T02:00:00Z'));
    expect(morning.sent).toBe(1);
    expect(h.messenger.sent[0]).toMatchObject({ token: 'tok-delhi', title: 'Gill Parivar ਨੇ 50% ਪੂਰਾ ਕੀਤਾ' });
  });

  it('dispatch: 21:00 digest per zone, nothing on a zero day, once per hour, dead tokens deleted (T-18, T-19, T-21, T-24)', async () => {
    const { id } = await groupWithMembers(h);
    await h.as('delhi').post('/api/v1/sangat/contributions', {
      items: [1, 2, 3].map((n) => ({ id: uuid(n), kind: 'BANI', baniId: 'JAPJ', source: 'READER', at: '2026-10-08T01:00:00Z', action: 'ADD' })),
    });
    // 16:00 UTC = 21:30 IST: Delhi's 21:00 hour.
    const r = await runSangatDispatch(h.db, h.messenger, new Date('2026-10-08T16:00:00Z'));
    expect(r).toEqual({ sent: 1, skipped: false });
    expect(h.messenger.sent[0]).toMatchObject({ token: 'tok-delhi', title: 'Gill Parivar: ਅੱਜ 3 ਪਾਠ' });
    expect((await runSangatDispatch(h.db, h.messenger, new Date('2026-10-08T16:20:00Z'))).skipped).toBe(true);

    // London's 21:00 is 20:00 UTC; its local date is the 8th, so the 8th's count.
    h.messenger.dead.add('tok-london');
    const l = await runSangatDispatch(h.db, h.messenger, new Date('2026-10-08T20:00:00Z'));
    expect(l.sent).toBe(0);
    expect((await h.db.doc('fcmTokens/london').get()).exists).toBe(false); // FM4

    // The next day nobody read: no digest (T-21).
    h.messenger.sent.length = 0;
    await runSangatDispatch(h.db, h.messenger, new Date('2026-10-09T16:00:00Z'));
    expect(h.messenger.sent).toHaveLength(0);
    expect(id).toBeTruthy();
  });

  it('creator hears who joined at 20:00, once (SG7, T-24a)', async () => {
    await groupWithMembers(h);
    await h.as('creator').post('/api/v1/devices/fcm-token', { token: 'tok-creator', locale: 'en', tz: 'Asia/Kolkata' });
    // 15:00 UTC = 20:30 IST.
    await runSangatDispatch(h.db, h.messenger, new Date('2026-10-08T15:00:00Z'));
    const msg = h.messenger.sent.find((m) => m.token === 'tok-creator');
    expect(msg).toMatchObject({ title: 'Delhi Member and 1 more joined Gill Parivar', body: 'Your sangat is growing: 3 members now.' });
    h.messenger.sent.length = 0;
    await runSangatDispatch(h.db, h.messenger, new Date('2026-10-09T15:00:00Z'));
    expect(h.messenger.sent.find((m) => m.token === 'tok-creator')).toBeUndefined();
  });
});
