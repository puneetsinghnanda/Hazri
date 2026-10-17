// Profile endpoints: 01-accounts §6.1–6.4, §6.6 and §13.8 (ARCHITECTURE §6.1).
import { Router } from 'express';
import type { Firestore, Transaction } from 'firebase-admin/firestore';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { callerUid } from '../auth';
import { EMAIL_COOLDOWN_SECONDS, RESTORE_TOKEN_TTL_SECONDS, VERIFY_EMAIL_TOKEN_TTL_SECONDS } from '../config';
import type { Deps } from '../deps';
import { deliver, queueMail, QueuedMail } from '../email/outbox';
import { restoreProfileTemplate, verifyEmailTemplate } from '../email/templates';
import { ApiError, Errors } from '../errors';
import { bodyOf, h, localeOf } from '../http';
import { ProfileDoc, profileDto, quotaDoc, quotaOf, requireProfile } from '../profile/profile';
import { checkEmailQuota } from '../quota';
import { adoptionIsEmpty, readAdoption, writeAdoption } from '../sangat/adopt';
import { newToken, TokenPurpose } from '../tokens';
import {
  emailHashOf,
  emailNormalizedOf,
  normalizeEmail,
  normalizeName,
  validateCityId,
  validateEmail,
  validateName,
  validateProfileInput,
} from '../validation';

export const COOLDOWN = EMAIL_COOLDOWN_SECONDS;

/** Runs the quota check (§6.0) or throws 429. Returns the new emailQuota value. */
export function quotaOrThrow(p: ProfileDoc, nowMs: number) {
  const q = checkEmailQuota(quotaOf(p), nowMs);
  if (!q.ok) throw Errors.rateLimited(q.retryAfterSeconds);
  return quotaDoc(q.next);
}

/** Reads the ACTIVE tokens of a profile (optionally of one purpose), for superseding. */
export async function activeTokens(db: Firestore, tx: Transaction, profileId: string, purpose?: TokenPurpose) {
  let q = db.collection('verificationTokens').where('profileId', '==', profileId);
  if (purpose) q = q.where('purpose', '==', purpose);
  q = q.where('status', '==', 'ACTIVE');
  return (await tx.get(q)).docs;
}

/** Writes a new token document; returns the raw token's link. */
export function createToken(
  db: Firestore,
  tx: Transaction,
  args: { profileId: string; purpose: TokenPurpose; uid: string; emailNormalized: string; ttlSeconds: number; nowMs: number },
): string {
  const t = newToken();
  tx.create(db.doc(`verificationTokens/${t.hash}`), {
    tokenHash: t.hash,
    profileId: args.profileId,
    purpose: args.purpose,
    requestingUid: args.uid,
    emailNormalized: args.emailNormalized,
    status: 'ACTIVE',
    createdAt: FieldValue.serverTimestamp(),
    expiresAt: Timestamp.fromMillis(args.nowMs + args.ttlSeconds * 1000),
    usedAt: null,
    usedByUid: null,
  });
  return t.link;
}

async function readProfileDto(db: Firestore, profileId: string) {
  const snap = await db.doc(`profiles/${profileId}`).get();
  return profileDto(snap.data() as ProfileDoc);
}

export function profileRouter(deps: Deps): Router {
  const { db, mailer, clock } = deps;
  const r = Router();

  // §6.1 GET /profile
  r.get(
    '/api/v1/profile',
    h(async (_req, res) => {
      const uid = callerUid(res);
      const ownerRef = db.doc(`owners/${uid}`);
      const owner = await ownerRef.get();
      if (!owner.exists) throw Errors.noProfile();
      const snap = await db.doc(`profiles/${owner.get('profileId') as string}`).get();
      if (!snap.exists || (snap.get('ownerUid') as string) !== uid) {
        await ownerRef.delete();
        throw Errors.noProfile();
      }
      res.status(200).json({ profile: profileDto(snap.data() as ProfileDoc) });
    }),
  );

  // §6.2 POST /profile (+ MB2/SF3 adoption of u_{uid})
  r.post(
    '/api/v1/profile',
    h(async (req, res) => {
      const uid = callerUid(res);
      const v = validateProfileInput(bodyOf(req));
      if ('fields' in v) throw Errors.validation(v.fields);
      const { name, email, phone, cityId } = v.value;
      const emailNormalized = emailNormalizedOf(email);
      const emailHash = emailHashOf(emailNormalized);
      const profileRef = db.collection('profiles').doc();
      await db.runTransaction(async (tx) => {
        const ownerSnap = await tx.get(db.doc(`owners/${uid}`));
        const indexSnap = await tx.get(db.doc(`emailIndex/${emailHash}`));
        const adoption = await readAdoption(db, tx, uid, profileRef.id);
        if (ownerSnap.exists) {
          throw new ApiError(409, 'PROFILE_ALREADY_EXISTS', 'A profile already exists on this device');
        }
        if (indexSnap.exists) throw new ApiError(409, 'EMAIL_EXISTS', 'An account with this email already exists');
        const now = FieldValue.serverTimestamp();
        tx.create(profileRef, {
          profileId: profileRef.id,
          ownerUid: uid,
          name,
          email,
          emailNormalized,
          phone,
          cityId,
          lastSeenDay: null,
          emailVerified: false,
          emailVerifiedAt: null,
          createdAt: now,
          updatedAt: now,
          restoredAt: null,
          emailQuota: { lastSentAt: null, windowStartAt: null, countInWindow: 0 },
          pendingEmail: null,
          pendingEmailNormalized: null,
        });
        tx.create(db.doc(`emailIndex/${emailHash}`), { profileId: profileRef.id, createdAt: now });
        tx.create(db.doc(`owners/${uid}`), { profileId: profileRef.id, createdAt: now });
        if (!adoptionIsEmpty(adoption)) writeAdoption(db, tx, adoption, { name, cityId });
      });
      res.status(201).json({ profile: await readProfileDto(db, profileRef.id) });
    }),
  );

  // §13.8 PATCH /profile (name and city)
  r.patch(
    '/api/v1/profile',
    h(async (req, res) => {
      const uid = callerUid(res);
      const body = bodyOf(req);
      const fields: Record<string, string> = {};
      const changes: { name?: string; cityId?: string } = {};
      if (body.name !== undefined) {
        const name = normalizeName(body.name);
        const e = validateName(name);
        if (e) fields.name = e;
        else changes.name = name;
      }
      if (body.cityId !== undefined) {
        const e = validateCityId(body.cityId);
        if (e) fields.cityId = e;
        else changes.cityId = (body.cityId as string).trim();
      }
      if (Object.keys(fields).length > 0) throw Errors.validation(fields);
      let profileId = '';
      await db.runTransaction(async (tx) => {
        const p = await requireProfile(db, uid, tx);
        profileId = p.doc.profileId;
        const update: Record<string, unknown> = {};
        if (changes.name !== undefined && changes.name !== p.doc.name) update.name = changes.name;
        if (changes.cityId !== undefined && changes.cityId !== p.doc.cityId) update.cityId = changes.cityId;
        if (Object.keys(update).length === 0) throw new ApiError(400, 'NOTHING_CHANGED', 'Nothing to change');
        tx.update(p.ref, { ...update, updatedAt: FieldValue.serverTimestamp() });
      });
      res.status(200).json({ result: 'PROFILE_UPDATED', profile: await readProfileDto(db, profileId) });
    }),
  );

  // §6.3 POST /profile/verification-email
  r.post(
    '/api/v1/profile/verification-email',
    h(async (req, res) => {
      const uid = callerUid(res);
      const locale = localeOf(req);
      if (!mailer.configured()) {
        // Checked before anything is written, so no quota or token is spent.
        await requireProfile(db, uid);
        throw Errors.emailNotConfigured();
      }
      const sent: { q: QueuedMail | null } = { q: null };
      let email = '';
      await db.runTransaction(async (tx) => {
        const p = await requireProfile(db, uid, tx);
        if (p.doc.emailVerified) throw new ApiError(409, 'EMAIL_ALREADY_VERIFIED', 'Your email is already verified');
        const nowMs = clock.now().getTime();
        const quota = quotaOrThrow(p.doc, nowMs);
        const old = await activeTokens(db, tx, p.doc.profileId, 'VERIFY_EMAIL');
        for (const t of old) tx.update(t.ref, { status: 'SUPERSEDED' });
        const link = createToken(db, tx, {
          profileId: p.doc.profileId,
          purpose: 'VERIFY_EMAIL',
          uid,
          emailNormalized: p.doc.emailNormalized,
          ttlSeconds: VERIFY_EMAIL_TOKEN_TTL_SECONDS,
          nowMs,
        });
        tx.update(p.ref, { emailQuota: quota, updatedAt: FieldValue.serverTimestamp() });
        email = p.doc.email;
        sent.q = queueMail(db, tx, p.doc.email, verifyEmailTemplate(p.doc.name, link, locale), {
          template: '7.1-A',
          profileId: p.doc.profileId,
          locale,
        });
      });
      if (sent.q) await deliver(mailer, sent.q);
      res.status(200).json({ result: 'VERIFICATION_EMAIL_SENT', email, cooldownSeconds: COOLDOWN });
    }),
  );

  // §6.4 POST /profile/restore-request
  r.post(
    '/api/v1/profile/restore-request',
    h(async (req, res) => {
      const uid = callerUid(res);
      const locale = localeOf(req);
      const typed = normalizeEmail(bodyOf(req).email);
      const e = validateEmail(typed);
      if (e) throw Errors.validation({ email: e });
      if (!mailer.configured()) throw Errors.emailNotConfigured();
      const emailNormalized = emailNormalizedOf(typed);
      const sent: { q: QueuedMail | null } = { q: null };
      let email = '';
      await db.runTransaction(async (tx) => {
        const owner = await tx.get(db.doc(`owners/${uid}`));
        if (owner.exists) throw new ApiError(409, 'DEVICE_HAS_PROFILE', 'A profile already exists on this device');
        const index = await tx.get(db.doc(`emailIndex/${emailHashOf(emailNormalized)}`));
        if (!index.exists) throw new ApiError(404, 'EMAIL_NOT_FOUND', 'No account found for this email');
        const profileRef = db.doc(`profiles/${index.get('profileId') as string}`);
        const snap = await tx.get(profileRef);
        const p = snap.data() as ProfileDoc | undefined;
        // An address only reserved by a pending change (13.8) restores nothing.
        if (!p || p.emailNormalized !== emailNormalized) {
          throw new ApiError(404, 'EMAIL_NOT_FOUND', 'No account found for this email');
        }
        const nowMs = clock.now().getTime();
        const quota = quotaOrThrow(p, nowMs);
        const old = await activeTokens(db, tx, p.profileId, 'RESTORE_PROFILE');
        for (const t of old) tx.update(t.ref, { status: 'SUPERSEDED' });
        const link = createToken(db, tx, {
          profileId: p.profileId,
          purpose: 'RESTORE_PROFILE',
          uid,
          emailNormalized: p.emailNormalized,
          ttlSeconds: RESTORE_TOKEN_TTL_SECONDS,
          nowMs,
        });
        tx.update(profileRef, { emailQuota: quota, updatedAt: FieldValue.serverTimestamp() });
        email = p.email;
        sent.q = queueMail(db, tx, p.email, restoreProfileTemplate(p.name, link, locale), {
          template: '7.1-B',
          profileId: p.profileId,
          locale,
        });
      });
      if (sent.q) await deliver(mailer, sent.q);
      res.status(200).json({ result: 'RESTORE_EMAIL_SENT', email, cooldownSeconds: COOLDOWN });
    }),
  );

  // §6.6 PATCH /profile/email, and §13.8 for a verified email
  r.patch(
    '/api/v1/profile/email',
    h(async (req, res) => {
      const uid = callerUid(res);
      const locale = localeOf(req);
      const typed = normalizeEmail(bodyOf(req).email);
      const e = validateEmail(typed);
      if (e) throw Errors.validation({ email: e });
      if (!mailer.configured()) {
        await requireProfile(db, uid);
        throw Errors.emailNotConfigured();
      }
      const newNorm = emailNormalizedOf(typed);
      const newHash = emailHashOf(newNorm);
      const sent: { q: QueuedMail | null } = { q: null };
      let profileId = '';
      let result: 'EMAIL_CHANGED' | 'EMAIL_CHANGE_PENDING' = 'EMAIL_CHANGED';
      await db.runTransaction(async (tx) => {
        // Reads.
        const p = await requireProfile(db, uid, tx);
        profileId = p.doc.profileId;
        if (newNorm === p.doc.emailNormalized) {
          throw new ApiError(400, 'EMAIL_UNCHANGED', 'This is already your email');
        }
        const newIndexRef = db.doc(`emailIndex/${newHash}`);
        const newIndex = await tx.get(newIndexRef);
        const nowMs = clock.now().getTime();
        const now = FieldValue.serverTimestamp();

        if (!p.doc.emailVerified) {
          // §6.6: changed at once.
          if (newIndex.exists) throw new ApiError(409, 'EMAIL_EXISTS', 'An account with this email already exists');
          const quota = quotaOrThrow(p.doc, nowMs);
          const active = await activeTokens(db, tx, profileId);
          // Writes.
          tx.delete(db.doc(`emailIndex/${emailHashOf(p.doc.emailNormalized)}`));
          tx.create(newIndexRef, { profileId, createdAt: now });
          tx.update(p.ref, { email: typed, emailNormalized: newNorm, emailQuota: quota, updatedAt: now });
          for (const t of active) tx.update(t.ref, { status: 'SUPERSEDED' });
          const link = createToken(db, tx, {
            profileId,
            purpose: 'VERIFY_EMAIL',
            uid,
            emailNormalized: newNorm,
            ttlSeconds: VERIFY_EMAIL_TOKEN_TTL_SECONDS,
            nowMs,
          });
          sent.q = queueMail(db, tx, typed, verifyEmailTemplate(p.doc.name, link, locale), {
            template: '7.1-A',
            profileId,
            locale,
          });
          result = 'EMAIL_CHANGED';
          return;
        }

        // §13.8: a verified email waits for the new address to be confirmed.
        if (newIndex.exists && (newIndex.get('profileId') as string) !== profileId) {
          throw new ApiError(409, 'EMAIL_EXISTS', 'An account with this email already exists');
        }
        const previousPending = p.doc.pendingEmailNormalized;
        const previousRef =
          previousPending && previousPending !== newNorm ? db.doc(`emailIndex/${emailHashOf(previousPending)}`) : null;
        const previous = previousRef ? await tx.get(previousRef) : null;
        const quota = quotaOrThrow(p.doc, nowMs);
        const olderChange = await activeTokens(db, tx, profileId, 'CHANGE_EMAIL');
        // Writes.
        if (previousRef && previous?.exists && (previous.get('profileId') as string) === profileId) {
          tx.delete(previousRef); // 13.8 step 4: release the first reservation.
        }
        tx.set(newIndexRef, { profileId, reserved: true, createdAt: now });
        tx.update(p.ref, { pendingEmail: typed, pendingEmailNormalized: newNorm, emailQuota: quota, updatedAt: now });
        for (const t of olderChange) tx.update(t.ref, { status: 'SUPERSEDED' });
        const link = createToken(db, tx, {
          profileId,
          purpose: 'CHANGE_EMAIL',
          uid,
          emailNormalized: newNorm,
          ttlSeconds: VERIFY_EMAIL_TOKEN_TTL_SECONDS,
          nowMs,
        });
        sent.q = queueMail(db, tx, typed, verifyEmailTemplate(p.doc.name, link, locale), {
          template: '7.1-A',
          profileId,
          locale,
        });
        result = 'EMAIL_CHANGE_PENDING';
      });
      if (sent.q) await deliver(mailer, sent.q);
      res.status(200).json({ result, profile: await readProfileDto(db, profileId), cooldownSeconds: COOLDOWN });
    }),
  );

  return r;
}
