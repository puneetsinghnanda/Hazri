// Who is calling, as the Sangat sees them: `p_{profileId}` with a profile,
// `u_{uid}` without (08-sangat §6 "Member key").
import type { Firestore, Transaction } from 'firebase-admin/firestore';
import { ownedProfile } from '../profile/profile';
import { anonMemberKey, profileMemberKey } from './model';

export interface SangatCaller {
  uid: string;
  memberKey: string;
  profileId: string | null;
  /** The profile name, when it was read (withName). */
  name: string | null;
  /** The profile city, when it was read (withName): the group's globe (08-sangat GG2). */
  cityId: string | null;
}

/** One read (owners/{uid}); restore deletes the old uid's owner document, so it is enough. */
export async function sangatCaller(db: Firestore, uid: string, tx?: Transaction): Promise<SangatCaller> {
  const ref = db.doc(`owners/${uid}`);
  const owner = tx ? await tx.get(ref) : await ref.get();
  if (!owner.exists) return { uid, memberKey: anonMemberKey(uid), profileId: null, name: null, cityId: null };
  const profileId = owner.get('profileId') as string;
  return { uid, memberKey: profileMemberKey(profileId), profileId, name: null, cityId: null };
}

/** Two reads: also the profile, for the member row's name and city. */
export async function sangatCallerWithName(db: Firestore, uid: string, tx?: Transaction): Promise<SangatCaller> {
  const p = await ownedProfile(db, uid, tx);
  if (!p) return { uid, memberKey: anonMemberKey(uid), profileId: null, name: null, cityId: null };
  return {
    uid,
    memberKey: profileMemberKey(p.doc.profileId),
    profileId: p.doc.profileId,
    name: p.doc.name,
    cityId: p.doc.cityId ?? null,
  };
}
