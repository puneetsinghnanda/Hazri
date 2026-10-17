// Every Function of the project (ARCHITECTURE §6, §7.1, §7.2). All obey the
// contract of §5.3: maxInstances 10, minInstances 0, asia-south1, idempotent,
// never writing what triggers them.
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { defineSecret } from 'firebase-functions/params';
import { onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { createApp } from './app';
import { BREVO_SECRET_NAME, FUNCTION_DEFAULTS } from './config';
import { BrevoMailer } from './email/mailer';
import { runBadgeGoalReached } from './jobs/badges';
import { runBuildGlobeSnapshot } from './jobs/globe';
import { runSangatDispatch, runSangatMilestone } from './jobs/notify';
import { runSangatProfileSync, runSangatRollover, runSangatTotals } from './jobs/sangat';
import { FcmMessenger } from './notifications/messenger';
import { systemClock } from './time';

initializeApp();
const db = getFirestore();
db.settings({ ignoreUndefinedProperties: true });

const brevoApiKey = defineSecret(BREVO_SECRET_NAME);
const messenger = new FcmMessenger(() => getMessaging());

/** The one HTTPS Function: Express under /api/v1, behind the Hosting rewrite /api/**. */
export const api = onRequest(
  { ...FUNCTION_DEFAULTS, secrets: [brevoApiKey], memory: '512MiB', timeoutSeconds: 120 },
  createApp({
    db,
    verifier: { verifyIdToken: (t) => getAuth().verifyIdToken(t) },
    mailer: new BrevoMailer(() => brevoApiKey.value()),
    clock: systemClock,
    messenger,
  }),
);

/** Every minute: built-in goals' shards into `total` (08-sangat §7.14). */
export const sangatTotals = onSchedule(
  { ...FUNCTION_DEFAULTS, schedule: 'every 1 minutes', timeZone: 'Asia/Kolkata' },
  async () => {
    await runSangatTotals(db, new Date());
  },
);

/** 00:05 IST daily: expiries, ended custom groups, built-in resets. */
export const sangatRollover = onSchedule(
  { ...FUNCTION_DEFAULTS, schedule: '5 0 * * *', timeZone: 'Asia/Kolkata', timeoutSeconds: 540, memory: '512MiB' },
  async () => {
    await runSangatRollover(db, new Date());
  },
);

/** Profile name or city change → the member's rows (name, sortName, cityId). */
export const sangatProfileSync = onDocumentUpdated({ ...FUNCTION_DEFAULTS, document: 'profiles/{profileId}' }, async (event) => {
  await runSangatProfileSync(db, event.params.profileId, event.data?.before.data(), event.data?.after.data());
});

/** Hourly at :00: the 21:00 digest, the creator's 20:00 joins, held 07:00 milestones. */
export const sangatDispatch = onSchedule(
  { ...FUNCTION_DEFAULTS, schedule: '0 * * * *', timeZone: 'Etc/UTC', timeoutSeconds: 540, memory: '512MiB' },
  async () => {
    await runSangatDispatch(db, messenger, new Date());
  },
);

/** A goal's total moved: milestone notices at 25/50/75/100 %. */
export const sangatMilestone = onDocumentUpdated(
  { ...FUNCTION_DEFAULTS, document: 'groups/{groupId}/goals/{goalId}' },
  async (event) => {
    await runSangatMilestone(
      db,
      messenger,
      event.params.groupId,
      event.params.goalId,
      event.data?.before.data(),
      event.data?.after.data(),
      new Date(),
    );
  },
);

/** A goal's status became COMPLETED: Sevadar facts (12-badges SF1). */
export const badgeGoalReached = onDocumentUpdated(
  { ...FUNCTION_DEFAULTS, document: 'groups/{groupId}/goals/{goalId}', timeoutSeconds: 300 },
  async (event) => {
    await runBadgeGoalReached(
      db,
      event.params.groupId,
      event.params.goalId,
      event.data?.before.get('status'),
      event.data?.after.get('status'),
    );
  },
);

/** Every GLOBE_SNAPSHOT_SECONDS (120): presenceSnapshot/current. */
export const buildGlobeSnapshot = onSchedule(
  { ...FUNCTION_DEFAULTS, schedule: 'every 2 minutes', timeZone: 'Asia/Kolkata' },
  async () => {
    await runBuildGlobeSnapshot(db, new Date());
  },
);
