// fcmTokens/{uid}.groupIds mirrors the member's "my groups", so a milestone
// finds its members' tokens in one query (ARCHITECTURE §7.3 "1 read of the
// group's members' tokens"). It is refreshed when the token is registered and
// after the caller joins, leaves, creates or deletes a group; sangatMilestone
// re-checks memberships before sending, so a stale copy can never reach a
// person who is no longer a member.
import type { Firestore } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';

export async function refreshTokenGroups(db: Firestore, uid: string, memberKey: string): Promise<void> {
  if (!memberKey.startsWith('p_')) return; // push needs a profile (FT1)
  try {
    const tokenRef = db.doc(`fcmTokens/${uid}`);
    const [tok, ms] = await Promise.all([tokenRef.get(), db.doc(`memberships/${memberKey}`).get()]);
    if (!tok.exists) return;
    await tokenRef.update({ groupIds: (ms.get('groupIds') as string[] | undefined) ?? [] });
  } catch (err) {
    logger.warn('fcm token groups not refreshed', { uid, error: String(err) });
  }
}
