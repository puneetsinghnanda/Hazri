// firestore.rules: no client may read or write anything (ARCHITECTURE §5.11;
// 01-accounts A4, 07-simran §10, 08-sangat §12, 10-backup §10, 02-notifications §11).
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { assertFails, initializeTestEnvironment, RulesTestEnvironment } from '@firebase/rules-unit-testing';
import { collection, deleteDoc, doc, getDoc, getDocs, setDoc } from 'firebase/firestore';
import { describeEmu } from './helpers';

const PATHS = [
  'profiles/p1',
  'emailIndex/h1',
  'owners/u1',
  'verificationTokens/t1',
  'mail/m1',
  'presenceSnapshot/current',
  'groups/g1',
  'groups/g1/goals/g0001',
  'groups/g1/goals/g0001/shards/0',
  'groups/g1/members/u_u1',
  'contributions/u_u1_x',
  'contributionCaps/u_u1_g1_2026-10-08',
  'inviteCodes/ABCDEFGH',
  'memberships/u_u1',
  'groupLimits/p1',
  'groupReports/g1_u_u1',
  'badgeFacts/p_p1',
  'profiles/p1/backupMeta/manifest',
  'profiles/p1/backupGoals/x',
  'profiles/p1/backupWeeks/2026-10-04',
  'profiles/p1/backupBadges/all',
  'fcmTokens/u1',
  'sangatNotices/g1_g0001_50',
  'adminAudit/a1',
  'content/vichar/entries/e1',
  'users/u1',
];

describeEmu('firestore.rules deny all', () => {
  let env: RulesTestEnvironment;
  beforeAll(async () => {
    const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST as string).split(':');
    env = await initializeTestEnvironment({
      projectId: 'demo-hazri-rules',
      firestore: { rules: readFileSync(join(__dirname, '..', '..', '..', 'firestore.rules'), 'utf8'), host, port: Number(port) },
    });
    await env.withSecurityRulesDisabled(async (ctx) => {
      for (const p of PATHS) await setDoc(doc(ctx.firestore(), p), { seeded: true, ownerUid: 'u1' });
    });
  });
  afterAll(async () => {
    await env.clearFirestore();
    await env.cleanup();
  });

  for (const who of ['signed in as the owner', 'signed out']) {
    it(`${who}: every read and write is refused`, async () => {
      const db = who === 'signed out' ? env.unauthenticatedContext().firestore() : env.authenticatedContext('u1').firestore();
      for (const p of PATHS) {
        await assertFails(getDoc(doc(db, p)));
        await assertFails(setDoc(doc(db, p), { x: 1 }));
        await assertFails(deleteDoc(doc(db, p)));
      }
      await assertFails(getDocs(collection(db, 'profiles')));
      await assertFails(getDocs(collection(db, 'groups')));
    });
  }
});
