// MB2 and 12-badges SF3: creating a profile moves every `u_{uid}` membership,
// contribution, cap and badgeFacts document under `p_{profileId}`, inside the
// profile-creation transaction (01-accounts §13 D12).
//
// Split into a read phase and a write phase because a Firestore transaction
// must do all its reads before any write.
import type { DocumentData, DocumentReference, DocumentSnapshot, Firestore, Transaction } from 'firebase-admin/firestore';
import { FieldValue } from 'firebase-admin/firestore';
import { BADGE_GOALS_REACHED_CAP, BADGE_JOINS_CAP } from '../config';
import { anonMemberKey, MemberDoc, profileMemberKey, sortNameOf } from './model';
import { mergeFactArrays } from '../badges/facts';

export interface AdoptionReads {
  fromKey: string;
  toKey: string;
  memberships: DocumentSnapshot;
  targetMemberships: DocumentSnapshot;
  members: Array<{ groupId: string; from: DocumentSnapshot; to: DocumentSnapshot }>;
  contributions: Array<{ ref: DocumentReference; data: DocumentData }>;
  caps: Array<{ ref: DocumentReference; data: DocumentData }>;
  facts: DocumentSnapshot;
  targetFacts: DocumentSnapshot;
}

export async function readAdoption(
  db: Firestore,
  tx: Transaction,
  uid: string,
  profileId: string,
): Promise<AdoptionReads> {
  const fromKey = anonMemberKey(uid);
  const toKey = profileMemberKey(profileId);
  const [memberships, targetMemberships, facts, targetFacts] = await Promise.all([
    tx.get(db.doc(`memberships/${fromKey}`)),
    tx.get(db.doc(`memberships/${toKey}`)),
    tx.get(db.doc(`badgeFacts/${fromKey}`)),
    tx.get(db.doc(`badgeFacts/${toKey}`)),
  ]);
  const groupIds: string[] = memberships.exists ? ((memberships.get('groupIds') as string[]) ?? []) : [];
  const members = await Promise.all(
    groupIds.map(async (groupId) => ({
      groupId,
      from: await tx.get(db.doc(`groups/${groupId}/members/${fromKey}`)),
      to: await tx.get(db.doc(`groups/${groupId}/members/${toKey}`)),
    })),
  );
  const [contribSnap, capSnap] = await Promise.all([
    tx.get(db.collection('contributions').where('memberKey', '==', fromKey)),
    tx.get(db.collection('contributionCaps').where('memberKey', '==', fromKey)),
  ]);
  return {
    fromKey,
    toKey,
    memberships,
    targetMemberships,
    members,
    contributions: contribSnap.docs.map((d) => ({ ref: d.ref, data: d.data() })),
    caps: capSnap.docs.map((d) => ({ ref: d.ref, data: d.data() })),
    facts,
    targetFacts,
  };
}

/** True when there is nothing to move (the common case). */
export function adoptionIsEmpty(r: AdoptionReads): boolean {
  return !r.memberships.exists && r.contributions.length === 0 && r.caps.length === 0 && !r.facts.exists;
}

/** The later of two `dayIst` values, either of which may be missing. */
function laterDay(a: string | null | undefined, b: string | null | undefined): string | null {
  if (!a) return b ?? null;
  if (!b) return a;
  return a > b ? a : b;
}

/**
 * The profile the rows move to: its name for the member list (MB3), its city
 * for the group's globe (08-sangat GG2).
 */
export interface AdoptingProfile {
  name: string;
  cityId: string | null;
}

export function writeAdoption(db: Firestore, tx: Transaction, r: AdoptionReads, profile: AdoptingProfile): void {
  const { fromKey, toKey } = r;
  const profileName = profile.name;
  const cityId = profile.cityId ?? null;
  const now = FieldValue.serverTimestamp();

  // Member rows. When the profile already has a row in that group (a restore
  // onto a phone that had joined anonymously), the two are merged into one.
  for (const m of r.members) {
    if (!m.from.exists) continue;
    const from = m.from.data() as MemberDoc;
    const groupRef = db.doc(`groups/${m.groupId}`);
    if (m.to.exists) {
      const to = m.to.data() as MemberDoc;
      const sameGoal = to.contributionGoalId === from.contributionGoalId;
      const merged: Partial<MemberDoc> = {
        status: to.status === 'ACTIVE' || from.status === 'ACTIVE' ? 'ACTIVE' : to.status,
        contribution: sameGoal ? to.contribution + from.contribution : to.contribution,
        lastAddDay: sameGoal ? laterDay(to.lastAddDay, from.lastAddDay) : (to.lastAddDay ?? null),
        name: profileName,
        sortName: sortNameOf(profileName),
        cityId,
      };
      tx.set(m.to.ref, { ...merged, updatedAt: now }, { merge: true });
      if (to.status === 'ACTIVE' && from.status === 'ACTIVE') {
        // One person was counted twice.
        tx.update(groupRef, { memberCount: FieldValue.increment(-1), updatedAt: now });
      }
    } else {
      tx.set(m.to.ref, {
        ...from,
        memberKey: toKey,
        name: profileName,
        sortName: sortNameOf(profileName),
        cityId,
        updatedAt: now,
      });
    }
    tx.delete(m.from.ref);
  }

  // "My groups".
  if (r.memberships.exists) {
    const ids = (r.memberships.get('groupIds') as string[]) ?? [];
    tx.set(
      db.doc(`memberships/${toKey}`),
      { groupIds: FieldValue.arrayUnion(...ids), updatedAt: now },
      { merge: true },
    );
    tx.delete(r.memberships.ref);
  }

  // Received outbox rows, so a later retraction still finds what it counted.
  for (const c of r.contributions) {
    const id = c.ref.id.slice(fromKey.length + 1);
    tx.set(db.doc(`contributions/${toKey}_${id}`), { ...c.data, memberKey: toKey });
    tx.delete(c.ref);
  }

  // Diary caps (CT4).
  for (const c of r.caps) {
    const rest = c.ref.id.slice(fromKey.length + 1);
    tx.set(db.doc(`contributionCaps/${toKey}_${rest}`), { ...c.data, memberKey: toKey }, { merge: true });
    tx.delete(c.ref);
  }

  // SF3: badge facts, arrays unioned and capped.
  if (r.facts.exists) {
    const from = r.facts.data() ?? {};
    const to = r.targetFacts.exists ? (r.targetFacts.data() ?? {}) : {};
    tx.set(db.doc(`badgeFacts/${toKey}`), {
      goalsReached: mergeFactArrays(to.goalsReached, from.goalsReached, BADGE_GOALS_REACHED_CAP),
      joins: mergeFactArrays(to.joins, from.joins, BADGE_JOINS_CAP),
      updatedAt: now,
    });
    tx.delete(r.facts.ref);
  }
}
