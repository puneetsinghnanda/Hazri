// 08-sangat §12 backend checklist and 12-badges §9, against the emulator.
import { runBadgeGoalReached } from '../../src/jobs/badges';
import { runSangatProfileSync, runSangatRollover, runSangatTotals } from '../../src/jobs/sangat';
import { clearFirestore, createProfile, describeEmu, harness, Harness, uuid } from './helpers';

const japji = (n: number, at = '2026-10-08T01:00:00Z', source = 'READER', action = 'ADD') => ({
  id: uuid(n),
  kind: 'BANI',
  baniId: 'JAPJ',
  source,
  at,
  action,
});

async function builtInGroup(h: Harness, template: Record<string, unknown>, en = 'Amrit Vela Sangat') {
  const res = await h.admin().post('/api/v1/admin/groups/built-in', { names: { en, pa: 'ਸੰਗਤ', hi: 'संगत' }, goalTemplate: template });
  expect(res.status).toBe(201);
  const id = res.body.group.groupId as string;
  expect((await h.admin().post(`/api/v1/admin/groups/${id}/start`)).status).toBe(200);
  return id;
}

async function customGroup(h: Harness, uid: string, goal: Record<string, unknown> = { type: 'BANI', baniId: 'JAPJ', target: 10, endDay: '2026-10-31' }) {
  const g = await h.as(uid).post('/api/v1/sangat/groups', { name: 'Gill Parivar' });
  expect(g.status).toBe(201);
  const id = g.body.group.groupId as string;
  const set = await h.as(uid).post(`/api/v1/sangat/groups/${id}/goal`, goal);
  expect(set.status).toBe(200);
  return { id, code: g.body.group.invite.code as string };
}

describeEmu('sangat (08-sangat §7)', () => {
  let h: Harness;
  beforeEach(async () => {
    await clearFirestore();
    h = harness();
  });

  it('built-in: join without a profile, count through shards, sangatTotals twice (S-2, S-13, S-14, S-30)', async () => {
    const gid = await builtInGroup(h, { type: 'BANI', baniId: 'JAPJ', target: 100, lengthDays: 30 });
    const list = await h.as('anon1').get('/api/v1/sangat/groups/built-in');
    expect(list.body.groups).toHaveLength(1);
    expect(list.body.groups[0]).toMatchObject({ groupId: gid, kind: 'BUILT_IN', isMember: false, goal: { target: 100, total: 0 } });

    expect((await h.as('anon1').post(`/api/v1/sangat/groups/${gid}/join`)).body).toEqual({ result: 'JOINED', groupId: gid });
    expect((await h.as('anon1').post(`/api/v1/sangat/groups/${gid}/join`)).body.result).toBe('ALREADY_MEMBER');

    const items = [japji(1), japji(2), { ...japji(3), baniId: 'JAAP' }];
    const sent = await h.as('anon1').post('/api/v1/sangat/contributions', { items });
    expect(sent.body).toEqual({ result: 'CONTRIBUTIONS_RECEIVED', processed: [uuid(1), uuid(2), uuid(3)] });
    await h.as('anon1').post('/api/v1/sangat/contributions', { items }); // S-14: a resend

    await runSangatTotals(h.db, h.clock.now());
    await runSangatTotals(h.db, h.clock.now()); // FN6: twice
    const detail = await h.as('anon1').get(`/api/v1/sangat/groups/${gid}`);
    expect(detail.body.group.goal).toMatchObject({ total: 2, todayTotal: 2, pct: 2 });
    expect(detail.body.group.members).toEqual([
      { memberKey: 'u_anon1', name: null, role: 'MEMBER', status: 'ACTIVE', contribution: 2, isYou: true },
    ]);
    expect((await h.as('anon1').get('/api/v1/sangat/groups/mine')).body.groups.map((g: { groupId: string }) => g.groupId)).toEqual([gid]);

    // Leave keeps the contribution (CT6).
    expect((await h.as('anon1').post(`/api/v1/sangat/groups/${gid}/leave`)).body.result).toBe('LEFT');
    await runSangatTotals(h.db, h.clock.now());
    expect((await h.as('anon2').get(`/api/v1/sangat/groups/${gid}`)).body.group.goal.total).toBe(2);
    expect((await h.as('anon1').get('/api/v1/sangat/groups/mine')).body.groups).toEqual([]);
  });

  it('profile creation adopts u_ memberships, contributions, caps and facts (MB2, SF3, S-3)', async () => {
    const gid = await builtInGroup(h, { type: 'BANI', baniId: 'JAPJ', target: 100, lengthDays: 30 });
    await h.as('u1').post(`/api/v1/sangat/groups/${gid}/join`);
    await h.as('u1').post('/api/v1/sangat/contributions', { items: [japji(1, undefined, 'DIARY')] });
    await h.db.doc('badgeFacts/u_u1').set({ goalsReached: ['x/y'], joins: [] });
    const p = await createProfile(h, 'u1');
    const key = `p_${p.profileId}`;
    expect((await h.db.doc('memberships/u_u1').get()).exists).toBe(false);
    expect((await h.db.doc(`memberships/${key}`).get()).get('groupIds')).toEqual([gid]);
    const member = await h.db.doc(`groups/${gid}/members/${key}`).get();
    expect(member.data()).toMatchObject({ memberKey: key, name: 'Harpreet Kaur', sortName: 'harpreet kaur', contribution: 1 });
    expect((await h.db.doc(`groups/${gid}/members/u_u1`).get()).exists).toBe(false);
    expect((await h.db.doc(`contributions/${key}_${uuid(1)}`).get()).exists).toBe(true);
    expect((await h.db.collection('contributionCaps').where('memberKey', '==', key).get()).size).toBe(1);
    expect((await h.as('u1').get('/api/v1/badges/sangat')).body).toEqual({ goalsReached: 1, joins: 0 });
    // The resend after adoption is still a duplicate.
    await h.as('u1').post('/api/v1/sangat/contributions', { items: [japji(1, undefined, 'DIARY')] });
    expect((await h.db.doc(`groups/${gid}/members/${key}`).get()).get('contribution')).toBe(1);
  });

  it('custom group: create, goal once, invite, join, diary cap, retraction, target met (S-4, S-11, S-12, S-15, S-17)', async () => {
    await createProfile(h, 'creator', { email: 'c@example.com', name: 'Gurdev Singh' });
    expect((await h.as('anon').post('/api/v1/sangat/groups', { name: 'X' })).body.error.code).toBe('NO_PROFILE');
    expect((await h.as('creator').post('/api/v1/sangat/groups', { name: '   ' })).body.error.code).toBe('VALIDATION_ERROR');
    const { id, code } = await customGroup(h, 'creator', { type: 'BANI', baniId: 'JAPJ', target: 5, endDay: '2026-10-31' });
    expect(code).toMatch(/^[A-Z2-9]{4}-[A-Z2-9]{4}$/);
    expect((await h.as('creator').post(`/api/v1/sangat/groups/${id}/goal`, { type: 'SIMRAN', target: 3, endDay: '2026-10-31' })).body.error.code).toBe(
      'GOAL_ALREADY_SET',
    );

    // A second custom group with the same goal: one paath counts in both (CT3).
    const second = await customGroup(h, 'creator', { type: 'BANI', baniId: 'JAPJ', target: 100, endDay: '2026-10-31' });

    const joined = await h.as('member').post('/api/v1/sangat/join', { code: code.toLowerCase() });
    expect(joined.body).toEqual({ result: 'JOINED', groupId: id });
    expect((await h.as('member').post('/api/v1/sangat/join', { code })).body.result).toBe('ALREADY_MEMBER');
    await h.as('member').post('/api/v1/sangat/join', { code: second.code.replace('-', '') });

    // Five Diary + today: each group counts 3 (S-12).
    const diary = [1, 2, 3, 4].map((n) => japji(n, '2026-10-08T02:00:00Z', 'DIARY'));
    await h.as('member').post('/api/v1/sangat/contributions', { items: diary });
    let g = (await h.as('member').get(`/api/v1/sangat/groups/${id}`)).body.group;
    expect(g.goal.total).toBe(3);
    // Undo one counted Diary paath (S-15): taken back from both groups.
    await h.as('member').post('/api/v1/sangat/contributions', { items: [{ ...diary[0], action: 'RETRACT' }] });
    g = (await h.as('member').get(`/api/v1/sangat/groups/${id}`)).body.group;
    expect(g.goal.total).toBe(2);
    expect((await h.as('member').get(`/api/v1/sangat/groups/${second.id}`)).body.group.goal.total).toBe(2);
    // The freed cap lets one more Diary paath count.
    await h.as('member').post('/api/v1/sangat/contributions', { items: [japji(5, '2026-10-08T03:00:00Z', 'DIARY')] });
    expect((await h.as('member').get(`/api/v1/sangat/groups/${id}`)).body.group.goal.total).toBe(3);

    // Reader paath is not capped; the 5th reaches the target: inactive at once (CG6, S-17).
    await h.as('member').post('/api/v1/sangat/contributions', { items: [japji(6), japji(7)] });
    g = (await h.as('member').get(`/api/v1/sangat/groups/${id}`)).body.group;
    expect(g).toMatchObject({ status: 'INACTIVE', endReason: 'TARGET_MET', goal: { status: 'COMPLETED', total: 5, pct: 100 } });
    await h.as('member').post('/api/v1/sangat/contributions', { items: [japji(8)] });
    expect((await h.as('member').get(`/api/v1/sangat/groups/${id}`)).body.group.goal.total).toBe(5); // CT7
    expect((await h.as('member').post('/api/v1/sangat/join', { code })).body.result).toBe('ALREADY_MEMBER');
    expect((await h.as('late').post('/api/v1/sangat/join', { code })).body.error.code).toBe('GROUP_INACTIVE');

    // Members list: names first, alphabetically, then "Sangat member" (VS4).
    const list = (await h.as('creator').get(`/api/v1/sangat/groups/${second.id}`)).body.group;
    expect(list.members.map((m: { name: string | null; role: string }) => [m.name, m.role])).toEqual([
      ['Gurdev Singh', 'CREATOR'],
      [null, 'MEMBER'],
    ]);
    expect(list.moreMembers).toBe(0);
  });

  it('invite rules: expired, reset, full, disabled, members only (IV2, IV8, S-9, S-10, S-25, S-27)', async () => {
    await createProfile(h, 'creator');
    const { id, code } = await customGroup(h, 'creator');
    expect((await h.as('stranger').get(`/api/v1/sangat/groups/${id}`)).body.error.code).toBe('GROUP_NOT_FOUND');
    expect((await h.as('stranger').post('/api/v1/sangat/join', { code: 'ABCD-EFGH' })).body.error.code).toBe('CODE_INVALID');
    expect((await h.as('stranger').post(`/api/v1/sangat/groups/${id}/invite`, { reset: true })).status).toBe(404);

    const same = await h.as('creator').post(`/api/v1/sangat/groups/${id}/invite`);
    expect(same.body).toEqual({ code, link: `https://hazri-dfcc1.web.app/j/${code}`, expiresAt: expect.any(String) });
    await h.as('m1').post('/api/v1/sangat/join', { code });
    expect((await h.as('m1').post(`/api/v1/sangat/groups/${id}/invite`, { reset: true })).body.error.code).toBe('NOT_CREATOR');
    const reset = await h.as('creator').post(`/api/v1/sangat/groups/${id}/invite`, { reset: true });
    expect(reset.body.code).not.toBe(code);
    expect((await h.as('m2').post('/api/v1/sangat/join', { code })).body.error.code).toBe('CODE_INVALID');

    // 30 days later the code is invalid; the next share makes a new one.
    h.clock.advance(31 * 86400);
    expect((await h.as('m2').post('/api/v1/sangat/join', { code: reset.body.code })).body.error.code).toBe('CODE_INVALID');
    const fresh = await h.as('m1').post(`/api/v1/sangat/groups/${id}/invite`);
    expect(fresh.body.code).not.toBe(reset.body.code);

    await h.db.doc(`groups/${id}`).update({ memberCount: 1000 });
    expect((await h.as('m3').post('/api/v1/sangat/join', { code: fresh.body.code })).body.error.code).toBe('GROUP_FULL');
    await h.db.doc(`groups/${id}`).update({ memberCount: 2 });

    await h.admin().patch(`/api/v1/admin/groups/${id}`, { status: 'DISABLED' });
    expect((await h.as('m3').post('/api/v1/sangat/join', { code: fresh.body.code })).body.error.code).toBe('CODE_INVALID');
    expect((await h.as('m1').get('/api/v1/sangat/groups/mine')).body.groups).toEqual([]);
    const audit = await h.db.collection('adminAudit').get();
    expect(audit.docs.map((d) => d.get('action'))).toEqual(expect.arrayContaining(['UPDATE_GROUP']));
  });

  it('creator rules: cannot leave, delete only alone, remove a member (CG8, CG9, MB4, S-21, S-22, S-23)', async () => {
    await createProfile(h, 'creator');
    const { id, code } = await customGroup(h, 'creator');
    expect((await h.as('creator').post(`/api/v1/sangat/groups/${id}/leave`)).body.error.code).toBe('CREATOR_CANNOT_LEAVE');
    await h.as('m1').post('/api/v1/sangat/join', { code });
    await h.as('m1').post('/api/v1/sangat/contributions', { items: [japji(1)] });
    expect((await h.as('creator').del(`/api/v1/sangat/groups/${id}`)).body.error.code).toBe('GROUP_HAS_MEMBERS');
    expect((await h.as('m1').del(`/api/v1/sangat/groups/${id}/members/u_m1`)).body.error.code).toBe('NOT_CREATOR');
    expect((await h.as('creator').del(`/api/v1/sangat/groups/${id}/members/u_nobody`)).body.error.code).toBe('MEMBER_NOT_FOUND');
    expect((await h.as('creator').del(`/api/v1/sangat/groups/${id}/members/u_m1`)).body.result).toBe('MEMBER_REMOVED');
    const g = (await h.as('creator').get(`/api/v1/sangat/groups/${id}`)).body.group;
    expect(g.goal.total).toBe(1);
    expect(g.members.find((m: { memberKey: string }) => m.memberKey === 'u_m1')).toMatchObject({ status: 'REMOVED', contribution: 1 });
    expect((await h.as('creator').del(`/api/v1/sangat/groups/${id}`)).body.result).toBe('GROUP_DELETED');
    expect((await h.db.doc(`groups/${id}`).get()).exists).toBe(false);
    expect((await h.db.doc(`inviteCodes/${code.replace('-', '')}`).get()).exists).toBe(false);
  });

  it('GROUP_LIMIT_REACHED at 5 active, raised by the admin (CG5, S-5, S-6, AW-7)', async () => {
    const p = await createProfile(h, 'creator', { email: 'lim@example.com' });
    for (let i = 0; i < 5; i++) expect((await h.as('creator').post('/api/v1/sangat/groups', { name: `G${i}` })).status).toBe(201);
    const sixth = await h.as('creator').post('/api/v1/sangat/groups', { name: 'G6' });
    expect(sixth.status).toBe(409);
    expect(sixth.body.error).toMatchObject({ code: 'GROUP_LIMIT_REACHED', limit: 5 });
    expect((await h.admin().put(`/api/v1/admin/people/${p.profileId}/group-limit`, { limit: 4 })).status).toBe(400);
    expect((await h.admin().put(`/api/v1/admin/people/${p.profileId}/group-limit`, { limit: 10 })).status).toBe(200);
    expect((await h.as('creator').post('/api/v1/sangat/groups', { name: 'G6' })).status).toBe(201);
    const person = await h.admin().get('/api/v1/admin/people?email=LIM@example.com');
    expect(person.body.person).toMatchObject({ activeCustomGroups: 6, groupLimit: 10 });
  });

  it('report: stored once per member, support emailed (RP1–RP3, S-26)', async () => {
    await createProfile(h, 'creator');
    const { id, code } = await customGroup(h, 'creator');
    await h.as('m1').post('/api/v1/sangat/join', { code });
    expect((await h.as('m1').post(`/api/v1/sangat/groups/${id}/report`, { reason: 'RUDE' })).status).toBe(400);
    expect((await h.as('m1').post(`/api/v1/sangat/groups/${id}/report`, { reason: 'SPAM' })).body).toEqual({ result: 'REPORT_SENT' });
    await h.as('m1').post(`/api/v1/sangat/groups/${id}/report`, { reason: 'OTHER', note: 'Not a real group' });
    const reports = await h.db.collection('groupReports').get();
    expect(reports.size).toBe(1);
    expect(reports.docs[0].data()).toMatchObject({ reason: 'OTHER', note: 'Not a real group', status: 'OPEN', memberKey: 'u_m1' });
    expect(h.mailer.sent.filter((m) => m.to === 'support@hazri.me')).toHaveLength(2);
    const admin = await h.admin().get('/api/v1/admin/reports?status=OPEN');
    expect(admin.body.reports[0]).toMatchObject({ groupId: id, groupName: 'Gill Parivar', reportsForGroup: 1, reason: 'OTHER' });
  });

  it('a Simran goal counts minutes: a sitting adds its whole minutes, a retraction takes them back (SG-1)', async () => {
    await createProfile(h, 'creator');
    const { id } = await customGroup(h, 'creator', { type: 'SIMRAN', target: 20, endDay: '2026-10-31' });
    const sit = (n: number, durationS: number, action = 'ADD') =>
      ({ id: uuid(100 + n), kind: 'SIMRAN', durationS, source: 'TIMER', at: '2026-10-08T01:00:00Z', action });
    await h.as('creator').post('/api/v1/sangat/contributions', { items: [sit(1, 7 * 60 + 59)] });
    let goal = (await h.as('creator').get(`/api/v1/sangat/groups/${id}`)).body.group.goal;
    expect(goal).toMatchObject({ total: 7, todayTotal: 7, simranMinutes: null });
    await h.as('creator').post('/api/v1/sangat/contributions', { items: [sit(1, 7 * 60 + 59, 'RETRACT')] });
    goal = (await h.as('creator').get(`/api/v1/sangat/groups/${id}`)).body.group.goal;
    expect(goal.total).toBe(0);
    await h.as('creator').post('/api/v1/sangat/contributions', { items: [sit(2, 15 * 60), sit(3, 6 * 60)] });
    const group = (await h.as('creator').get(`/api/v1/sangat/groups/${id}`)).body.group;
    expect(group).toMatchObject({ status: 'INACTIVE', endReason: 'TARGET_MET', goal: { total: 21, status: 'COMPLETED' } });
    expect(group.members[0].contribution).toBe(21);
  });

  it('sangatRollover twice: expiry, inactive custom group, built-in reset with history (CG6, BI4, S-18, S-19, S-20)', async () => {
    // Two 5-minute sittings are 10 minutes of Naam Simran (SG-1).
    const builtIn = await builtInGroup(h, { type: 'SIMRAN', target: 10, lengthDays: 3 });
    await createProfile(h, 'creator');
    const { id } = await customGroup(h, 'creator', { type: 'BANI', baniId: 'JAPJ', target: 10, endDay: '2026-10-08' });
    await h.as('m1').post(`/api/v1/sangat/groups/${builtIn}/join`);
    const sit = (n: number, at: string) => ({ id: uuid(n), kind: 'SIMRAN', durationS: 300, source: 'TIMER', at, action: 'ADD' });
    await h.as('m1').post('/api/v1/sangat/contributions', { items: [sit(1, '2026-10-08T01:00:00Z'), sit(2, '2026-10-08T02:00:00Z')] });
    await runSangatTotals(h.db, h.clock.now());
    const goalBefore = (await h.as('m1').get(`/api/v1/sangat/groups/${builtIn}`)).body.group.goal;
    expect(goalBefore).toMatchObject({ status: 'COMPLETED', total: 10 });
    // badgeGoalReached, twice (SF1, FN6).
    await runBadgeGoalReached(h.db, builtIn, goalBefore.goalId, 'ACTIVE', 'COMPLETED');
    await runBadgeGoalReached(h.db, builtIn, goalBefore.goalId, 'ACTIVE', 'COMPLETED');
    expect((await h.db.doc('badgeFacts/u_m1').get()).get('goalsReached')).toEqual([`${builtIn}/${goalBefore.goalId}`]);

    // Admin edits the template mid-goal: the next goal uses it (AW-5).
    await h.admin().patch(`/api/v1/admin/groups/${builtIn}`, { goalTemplate: { type: 'SIMRAN', target: 7, lengthDays: 3 } });

    h.clock.set('2026-10-08T18:35:00Z'); // 00:05 IST on the 9th
    const first = await runSangatRollover(h.db, h.clock.now());
    const second = await runSangatRollover(h.db, h.clock.now());
    expect(first).toEqual({ expired: 1, groupsEnded: 1, goalsStarted: 1 });
    expect(second).toEqual({ expired: 0, groupsEnded: 0, goalsStarted: 0 });

    const custom = (await h.as('creator').get(`/api/v1/sangat/groups/${id}`)).body.group;
    expect(custom).toMatchObject({ status: 'INACTIVE', endedOn: '2026-10-09', endReason: 'END_DATE', goal: { status: 'EXPIRED' } });
    const next = (await h.as('m1').get(`/api/v1/sangat/groups/${builtIn}`)).body.group;
    expect(next.goal).toMatchObject({ goalId: 'g0002', sequence: 2, target: 7, startDay: '2026-10-09', endDay: '2026-10-11', total: 0 });
    expect(next.members[0].contribution).toBe(0);
    const history = await h.admin().get(`/api/v1/admin/groups/${builtIn}/history`);
    expect(history.body.goals).toEqual([expect.objectContaining({ goalId: 'g0001', total: 10, memberCount: 1, status: 'COMPLETED' })]);
    expect((await h.db.doc(`groups/${builtIn}/goals/g0001/members/u_m1`).get()).get('contribution')).toBe(10);
  });

  it('Satsangi joins: once per person per group, never the creator, stop at 5 (SF2, B-10, B-11)', async () => {
    const p = await createProfile(h, 'creator');
    const { id, code } = await customGroup(h, 'creator', { type: 'BANI', baniId: 'JAPJ', target: 1000, endDay: '2026-10-31' });
    for (const u of ['a', 'b', 'c', 'd', 'e', 'f']) await h.as(u).post('/api/v1/sangat/join', { code });
    await h.as('a').post(`/api/v1/sangat/groups/${id}/leave`);
    await h.as('a').post('/api/v1/sangat/join', { code });
    const facts = (await h.db.doc(`badgeFacts/p_${p.profileId}`).get()).get('joins') as string[];
    expect(facts).toHaveLength(5);
    expect(new Set(facts).size).toBe(5);
    expect((await h.as('creator').get('/api/v1/badges/sangat')).body).toEqual({ goalsReached: 0, joins: 5 });
  });

  it('sangatProfileSync: a name change reaches the member rows, twice is a no-op', async () => {
    const p = await createProfile(h, 'creator');
    const { id } = await customGroup(h, 'creator');
    await h.as('creator').patch('/api/v1/profile', { name: 'Gurpreet Singh' });
    const one = await runSangatProfileSync(h.db, p.profileId, { name: 'Harpreet Kaur' }, { name: 'Gurpreet Singh' });
    const two = await runSangatProfileSync(h.db, p.profileId, { name: 'Harpreet Kaur' }, { name: 'Gurpreet Singh' });
    expect(one.rowsUpdated).toBe(1);
    expect(two.rowsUpdated).toBe(0);
    expect((await h.db.doc(`groups/${id}/members/p_${p.profileId}`).get()).data()).toMatchObject({ name: 'Gurpreet Singh', sortName: 'gurpreet singh' });
    expect((await runSangatProfileSync(h.db, p.profileId, { name: 'X' }, { name: 'X' })).rowsUpdated).toBe(0);
  });

  it('admin dashboard figures (11-admin 4.1)', async () => {
    await createProfile(h, 'u1');
    await h.as('u1').post('/api/v1/presence/attendance');
    const gid = await builtInGroup(h, { type: 'BANI', baniId: 'JAPJ', target: 100, lengthDays: 30 });
    await h.as('u1').post(`/api/v1/sangat/groups/${gid}/join`);
    await h.as('u1').post('/api/v1/sangat/contributions', { items: [japji(1, '2026-10-08T05:00:00Z')] });
    const d = await h.admin().get('/api/v1/admin/dashboard');
    expect(d.status).toBe(200);
    expect(d.body).toMatchObject({ day: '2026-10-08', openedToday: 1, totalProfiles: 1, activeCustomGroups: 0, sangatPaathToday: 1, openReports: 0 });
    expect(d.body.newProfilesPerDay).toHaveLength(30);
    expect(d.body.newProfilesPerDay.at(-1).day).toBe('2026-10-08');
    expect(d.body.builtInGroups).toHaveLength(1);
    expect((await h.as('u1').get('/api/v1/admin/dashboard')).status).toBe(403); // AW-3
    const groups = await h.admin().get('/api/v1/admin/groups?kind=BUILT_IN&status=ACTIVE');
    expect(groups.body).toMatchObject({ groups: [{ groupId: gid }], next: null });
    expect((await h.admin().del(`/api/v1/admin/groups/${gid}`, { confirmName: 'wrong' })).body.error.code).toBe('CONFIRM_MISMATCH');
    expect((await h.admin().del(`/api/v1/admin/groups/${gid}`, { confirmName: 'Amrit Vela Sangat' })).body.result).toBe('GROUP_DELETED');
    expect((await h.as('u1').get('/api/v1/sangat/groups/mine')).body.groups).toEqual([]);
  });
});
