// POST /api/v1/tokens/verify (01-accounts §6.5, and the CHANGE_EMAIL purpose
// of §13.8 step 3).
import { Router } from 'express';
import type { Firestore } from 'firebase-admin/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { callerUid } from '../auth';
import type { Deps } from '../deps';
import { ApiError } from '../errors';
import { bodyOf, h } from '../http';
import { ProfileDoc, profileDto } from '../profile/profile';
import { adoptionIsEmpty, readAdoption, writeAdoption } from '../sangat/adopt';
import { isRawToken, TokenPurpose } from '../tokens';
import { emailHashOf, sha256Hex } from '../validation';
import { activeTokens } from './profile';

type VerifyResult = 'EMAIL_VERIFIED' | 'EMAIL_ALREADY_VERIFIED' | 'PROFILE_RESTORED' | 'EMAIL_CHANGED';

const tokenInvalid = (purpose?: string) =>
  new ApiError(404, 'TOKEN_INVALID', 'This link is invalid or has been replaced by a newer link', { purpose });
const tokenUsed = (purpose: string) =>
  new ApiError(409, 'TOKEN_ALREADY_USED', 'This link has already been used', { purpose });
const tokenExpired = (purpose: string) => new ApiError(410, 'TOKEN_EXPIRED', 'This link has expired', { purpose });

async function dto(db: Firestore, profileId: string) {
  return profileDto((await db.doc(`profiles/${profileId}`).get()).data() as ProfileDoc);
}

export function tokensRouter(deps: Deps): Router {
  const { db, clock } = deps;
  const r = Router();

  r.post(
    '/api/v1/tokens/verify',
    h(async (req, res) => {
      const uid = callerUid(res);
      const raw = bodyOf(req).token;
      if (!isRawToken(raw)) throw new ApiError(400, 'INVALID_REQUEST', 'Invalid link');
      const tokenRef = db.doc(`verificationTokens/${sha256Hex(raw)}`);

      const out = await db.runTransaction(async (tx) => {
        const tokSnap = await tx.get(tokenRef);
        if (!tokSnap.exists) throw tokenInvalid();
        const tok = tokSnap.data() as {
          profileId: string;
          purpose: TokenPurpose;
          requestingUid: string;
          emailNormalized: string;
          status: string;
          expiresAt: FirebaseFirestore.Timestamp;
        };
        const purpose = tok.purpose;
        if (tok.status === 'SUPERSEDED') throw tokenInvalid(purpose);
        const profileRef = db.doc(`profiles/${tok.profileId}`);
        const p = (await tx.get(profileRef)).data() as ProfileDoc;
        const expired = clock.now().getTime() >= tok.expiresAt.toMillis();
        const isOwner = p.ownerUid === uid;
        const now = FieldValue.serverTimestamp();
        const useToken = () => tx.update(tokenRef, { status: 'USED', usedAt: now, usedByUid: uid });

        if (purpose === 'VERIFY_EMAIL') {
          if (tok.status === 'USED') {
            if (p.emailVerified) {
              return { result: 'EMAIL_ALREADY_VERIFIED' as VerifyResult, purpose, isOwner, profileId: p.profileId };
            }
            throw tokenUsed(purpose);
          }
          if (expired) throw tokenExpired(purpose);
          if (p.emailNormalized !== tok.emailNormalized) throw tokenInvalid(purpose);
          const update: Record<string, FirebaseFirestore.FieldValue | string | boolean | null> = { emailVerified: true, updatedAt: now };
          if (!p.emailVerifiedAt) update.emailVerifiedAt = now;
          tx.update(profileRef, update);
          useToken();
          return { result: 'EMAIL_VERIFIED' as VerifyResult, purpose, isOwner, profileId: p.profileId };
        }

        if (purpose === 'CHANGE_EMAIL') {
          if (tok.status === 'USED') {
            if (p.emailVerified && p.emailNormalized === tok.emailNormalized) {
              return { result: 'EMAIL_ALREADY_VERIFIED' as VerifyResult, purpose, isOwner, profileId: p.profileId };
            }
            throw tokenUsed(purpose);
          }
          if (expired) throw tokenExpired(purpose);
          if (!p.pendingEmailNormalized || p.pendingEmailNormalized !== tok.emailNormalized) throw tokenInvalid(purpose);
          const others = (await activeTokens(db, tx, p.profileId)).filter((d) => d.id !== tokenRef.id);
          tx.delete(db.doc(`emailIndex/${emailHashOf(p.emailNormalized)}`));
          tx.set(db.doc(`emailIndex/${emailHashOf(tok.emailNormalized)}`), { profileId: p.profileId, createdAt: now });
          tx.update(profileRef, {
            email: p.pendingEmail,
            emailNormalized: tok.emailNormalized,
            pendingEmail: null,
            pendingEmailNormalized: null,
            emailVerified: true,
            emailVerifiedAt: now,
            updatedAt: now,
          });
          for (const t of others) tx.update(t.ref, { status: 'SUPERSEDED' });
          useToken();
          return { result: 'EMAIL_CHANGED' as VerifyResult, purpose, isOwner, profileId: p.profileId };
        }

        // RESTORE_PROFILE
        if (tok.status === 'USED') throw tokenUsed(purpose);
        if (expired) throw tokenExpired(purpose);
        if (p.emailNormalized !== tok.emailNormalized) throw tokenInvalid(purpose);
        if (tok.requestingUid !== uid) {
          throw new ApiError(403, 'RESTORE_WRONG_DEVICE', 'Open this link on the phone where you requested the restore');
        }
        const callerOwner = await tx.get(db.doc(`owners/${uid}`));
        if (callerOwner.exists) throw new ApiError(409, 'DEVICE_HAS_PROFILE', 'A profile already exists on this device');
        const others = (await activeTokens(db, tx, p.profileId)).filter((d) => d.id !== tokenRef.id);
        // The memberships this phone made before restoring move to the profile (README decisions).
        const adoption = await readAdoption(db, tx, uid, p.profileId);
        const oldUid = p.ownerUid;
        tx.delete(db.doc(`owners/${oldUid}`));
        tx.delete(db.doc(`fcmTokens/${oldUid}`)); // FT3
        tx.create(db.doc(`owners/${uid}`), { profileId: p.profileId, createdAt: now });
        const update: Record<string, FirebaseFirestore.FieldValue | string | boolean | null> = {
          ownerUid: uid,
          emailVerified: true,
          restoredAt: now,
          updatedAt: now,
        };
        if (!p.emailVerifiedAt) update.emailVerifiedAt = now;
        tx.update(profileRef, update);
        useToken();
        for (const t of others) tx.update(t.ref, { status: 'SUPERSEDED' });
        if (!adoptionIsEmpty(adoption)) writeAdoption(db, tx, adoption, p.name);
        return { result: 'PROFILE_RESTORED' as VerifyResult, purpose, isOwner: true, profileId: p.profileId };
      });

      const body: Record<string, unknown> = { result: out.result, purpose: out.purpose, isOwner: out.isOwner };
      if (out.isOwner) body.profile = await dto(db, out.profileId);
      res.status(200).json(body);
    }),
  );

  return r;
}
