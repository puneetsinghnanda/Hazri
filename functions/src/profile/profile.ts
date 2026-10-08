// profiles/{profileId} (ARCHITECTURE §5.4, 01-accounts §4.1 with §13 D9,
// D10, 13.8) and the Profile DTO of §6.0.
import type { DocumentReference, Firestore, Timestamp, Transaction } from 'firebase-admin/firestore';
import { Timestamp as Ts } from 'firebase-admin/firestore';
import { Errors } from '../errors';
import type { EmailQuota } from '../quota';
import { toIso } from '../time';

export interface ProfileDoc {
  profileId: string;
  ownerUid: string;
  name: string;
  email: string;
  emailNormalized: string;
  phone: string | null;
  cityId: string;
  lastSeenDay: string | null;
  emailVerified: boolean;
  emailVerifiedAt: Timestamp | null;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  restoredAt: Timestamp | null;
  emailQuota: { lastSentAt: Timestamp | null; windowStartAt: Timestamp | null; countInWindow: number };
  pendingEmail: string | null;
  pendingEmailNormalized: string | null;
}

export interface ProfileDto {
  profileId: string;
  name: string;
  email: string;
  phone: string | null;
  cityId: string;
  emailVerified: boolean;
  createdAt: string | null;
  /** 13.8: the address waiting to be confirmed, or null. */
  pendingEmail: string | null;
}

/** Never ownerUid, emailNormalized, emailQuota or token data (§6.0). */
export function profileDto(p: ProfileDoc): ProfileDto {
  return {
    profileId: p.profileId,
    name: p.name,
    email: p.email,
    phone: p.phone ?? null,
    cityId: p.cityId,
    emailVerified: p.emailVerified === true,
    createdAt: toIso(p.createdAt),
    pendingEmail: p.pendingEmail ?? null,
  };
}

export function quotaOf(p: ProfileDoc): EmailQuota {
  const q = p.emailQuota ?? { lastSentAt: null, windowStartAt: null, countInWindow: 0 };
  return {
    lastSentAtMs: q.lastSentAt ? q.lastSentAt.toMillis() : null,
    windowStartAtMs: q.windowStartAt ? q.windowStartAt.toMillis() : null,
    countInWindow: q.countInWindow ?? 0,
  };
}

export function quotaDoc(next: { lastSentAtMs: number; windowStartAtMs: number; countInWindow: number }) {
  return {
    lastSentAt: Ts.fromMillis(next.lastSentAtMs),
    windowStartAt: Ts.fromMillis(next.windowStartAtMs),
    countInWindow: next.countInWindow,
  };
}

export interface OwnedProfile {
  ref: DocumentReference;
  doc: ProfileDoc;
}

/**
 * The caller's profile: owners/{uid} → profiles/{id}, and the profile must
 * still be owned by the caller (10-backup §6 "when it is missing, or its
 * profile's ownerUid is not the caller, it returns 404 NO_PROFILE").
 */
export async function ownedProfile(db: Firestore, uid: string, tx?: Transaction): Promise<OwnedProfile | null> {
  const ownerRef = db.doc(`owners/${uid}`);
  const owner = tx ? await tx.get(ownerRef) : await ownerRef.get();
  if (!owner.exists) return null;
  const profileId = owner.get('profileId') as string;
  const ref = db.doc(`profiles/${profileId}`);
  const snap = tx ? await tx.get(ref) : await ref.get();
  if (!snap.exists) return null;
  const doc = snap.data() as ProfileDoc;
  if (doc.ownerUid !== uid) return null;
  return { ref, doc };
}

export async function requireProfile(db: Firestore, uid: string, tx?: Transaction): Promise<OwnedProfile> {
  const p = await ownedProfile(db, uid, tx);
  if (!p) throw Errors.noProfile();
  return p;
}

/** The profile id owned by a uid, from owners/{uid} alone (one read). */
export async function ownerProfileId(db: Firestore, uid: string, tx?: Transaction): Promise<string | null> {
  const ref = db.doc(`owners/${uid}`);
  const snap = tx ? await tx.get(ref) : await ref.get();
  return snap.exists ? ((snap.get('profileId') as string) ?? null) : null;
}
