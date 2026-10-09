// Sangat endpoints (08-sangat §7, ARCHITECTURE §6.3), all under /api/v1/sangat.
import { Router } from 'express';
import type { DocumentReference, Firestore, Transaction } from 'firebase-admin/firestore';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { callerUid } from '../auth';
import { BADGE_JOINS_CAP, CONTRIBUTIONS_MAX_PER_REQUEST, CUSTOM_GROUP_MAX_MEMBERS, CUSTOM_GROUPS_ACTIVE_DEFAULT, GOAL_DAYS_MAX, GOAL_TARGET_MAX, GOAL_TARGET_MIN, GROUP_NAME_MAX, INVITE_CODE_TTL_DAYS, MEMBER_LIST_SIZE, REPORT_NOTE_MAX, SUPPORT_EMAIL } from '../config';
import type { Deps } from '../deps';
import { reportTemplate } from '../email/templates';
import { ApiError, Errors } from '../errors';
import { bodyOf, h, param } from '../http';
import { requireProfile } from '../profile/profile';
import { isBaniId } from '../reference';
import { addDays, dayIst, isValidDay, toIso } from '../time';
import { codePoints } from '../validation';
import { factWouldGrow } from '../badges/facts';
import { sangatCaller, sangatCallerWithName, SangatCaller } from '../sangat/caller';
import { processItem } from '../sangat/contribute';
import { refreshTokenGroups } from '../sangat/tokenGroups';
import { OutboxItem, parseOutboxItem } from '../sangat/counting';
import { formatInviteCode, generateInviteCode, inviteLink, normalizeInviteCode } from '../sangat/invite';
import {
  contributionFor,
  GoalDoc,
  goalIdFor,
  GroupDoc,
  groupSummaryDto,
  GroupSummaryDto,
  MemberDoc,
  Role,
  sortNameOf,
} from '../sangat/model';

const groupNotFound = () => new ApiError(404, 'GROUP_NOT_FOUND', 'Group not found');
const notCreator = () => new ApiError(403, 'NOT_CREATOR', 'Only the person who started this group can do that');
const groupInactive = () => new ApiError(409, 'GROUP_INACTIVE', 'This group has ended.');
const codeInvalid = () => new ApiError(404, 'CODE_INVALID', "This code isn't valid. Ask for a new invite.");

export interface MemberRowDto {
  memberKey: string;
  name: string | null;
  role: Role;
  status: string;
  contribution: number;
  isYou: boolean;
}

export interface GroupDetailDto extends GroupSummaryDto {
  members: MemberRowDto[];
  moreMembers: number;
  invite: { code: string; link: string; expiresAt: string | null } | null;
}

async function readGoal(groupRef: DocumentReference, goalId: string | null, tx?: Transaction) {
  if (!goalId) return null;
  const ref = groupRef.collection('goals').doc(goalId);
  const snap = tx ? await tx.get(ref) : await ref.get();
  return snap.exists ? { id: goalId, doc: snap.data() as GoalDoc } : null;
}

function validInvite(g: GroupDoc, nowMs: number): boolean {
  return !!g.inviteCode && !!g.inviteExpiresAt && g.inviteExpiresAt.toMillis() > nowMs;
}

/** 7.3: group, goal, today's total, member count, the first 50 members, the caller's role. */
export async function groupDetail(db: Firestore, groupId: string, caller: SangatCaller, now: Date): Promise<GroupDetailDto> {
  const groupRef = db.doc(`groups/${groupId}`);
  const snap = await groupRef.get();
  if (!snap.exists) throw groupNotFound();
  const g = snap.data() as GroupDoc;
  if (g.status === 'DISABLED') throw groupNotFound();
  const meSnap = await groupRef.collection('members').doc(caller.memberKey).get();
  const me = meSnap.exists ? (meSnap.data() as MemberDoc) : null;
  const isMember = me?.status === 'ACTIVE';
  if (g.kind === 'CUSTOM' && !isMember) throw groupNotFound(); // members only
  const today = dayIst(now);
  const goal = await readGoal(groupRef, g.currentGoalId);
  // VS4: profiles first, alphabetically, then "Sangat member" rows ('~' sorts last).
  const [rows, all] = await Promise.all([
    groupRef.collection('members').orderBy('sortName').limit(MEMBER_LIST_SIZE).get(),
    groupRef.collection('members').count().get(),
  ]);
  const members: MemberRowDto[] = rows.docs.map((d) => {
    const m = d.data() as MemberDoc;
    return {
      memberKey: m.memberKey,
      name: m.name ?? null,
      role: m.role,
      status: m.status,
      contribution: contributionFor(m, g.currentGoalId),
      isYou: m.memberKey === caller.memberKey,
    };
  });
  const summary = groupSummaryDto(groupId, g, goal, today, { isMember, role: isMember ? (me?.role ?? null) : null });
  return {
    ...summary,
    members,
    moreMembers: Math.max(0, all.data().count - members.length),
    invite:
      g.kind === 'CUSTOM' && validInvite(g, now.getTime())
        ? { code: formatInviteCode(g.inviteCode as string), link: inviteLink(g.inviteCode as string), expiresAt: toIso(g.inviteExpiresAt) }
        : null,
  };
}

/** A fresh invite code not already in use (checked inside the transaction). */
async function freshCode(db: Firestore, tx: Transaction): Promise<string> {
  for (let i = 0; i < 6; i++) {
    const code = generateInviteCode();
    if (!(await tx.get(db.doc(`inviteCodes/${code}`))).exists) return code;
  }
  throw new Error('could not find a free invite code');
}

function inviteExpiry(now: Date): Timestamp {
  return Timestamp.fromMillis(now.getTime() + INVITE_CODE_TTL_DAYS * 86_400_000);
}

interface GoalInput {
  type: 'BANI' | 'SIMRAN';
  baniId: string | null;
  simranMinutes: number | null;
  target: number;
  endDay: string;
}

/** 7.5 body: CG3, CG4, §3. */
export function parseGoalInput(
  body: Record<string, unknown>,
  today: string,
): { ok: true; value: GoalInput } | { ok: false; fields: Record<string, string> } {
  const fields: Record<string, string> = {};
  const type = body.type;
  if (type !== 'BANI' && type !== 'SIMRAN') fields.type = 'Choose a bani or Naam Simran';
  let baniId: string | null = null;
  const simranMinutes: number | null = null;
  if (type === 'BANI') {
    if (!isBaniId(body.baniId)) fields.baniId = 'Choose a bani';
    else baniId = body.baniId;
  }
  // A Simran goal counts minutes of Naam Simran (SG-1), so any
  // `simranMinutes` an older app sends is ignored rather than refused.
  const target = body.target;
  if (typeof target !== 'number' || !Number.isInteger(target) || target < GOAL_TARGET_MIN || target > GOAL_TARGET_MAX) {
    fields.target = `Target must be ${GOAL_TARGET_MIN}–${GOAL_TARGET_MAX.toLocaleString('en-US')}`;
  }
  const endDay = body.endDay;
  if (!isValidDay(endDay) || endDay < today || endDay > addDays(today, GOAL_DAYS_MAX - 1)) {
    fields.endDay = 'The end date must be from today to 365 days ahead';
  }
  if (Object.keys(fields).length > 0) return { ok: false, fields };
  return {
    ok: true,
    value: { type: type as 'BANI' | 'SIMRAN', baniId, simranMinutes, target: target as number, endDay: endDay as string },
  };
}

export function sangatRouter(deps: Deps): Router {
  const { db, clock, mailer } = deps;
  const r = Router();
  const P = '/api/v1/sangat';

  // 7.1 GET /groups/mine
  r.get(
    `${P}/groups/mine`,
    h(async (_req, res) => {
      const caller = await sangatCaller(db, callerUid(res));
      const ms = await db.doc(`memberships/${caller.memberKey}`).get();
      const ids: string[] = ms.exists ? ((ms.get('groupIds') as string[]) ?? []) : [];
      const today = dayIst(clock.now());
      const groups: GroupSummaryDto[] = [];
      for (const groupId of ids) {
        const groupRef = db.doc(`groups/${groupId}`);
        const snap = await groupRef.get();
        if (!snap.exists) continue;
        const g = snap.data() as GroupDoc;
        if (g.status === 'DISABLED') continue; // RP4
        const goal = await readGoal(groupRef, g.currentGoalId);
        const role: Role = g.creatorKey === caller.memberKey ? 'CREATOR' : 'MEMBER';
        groups.push(groupSummaryDto(groupId, g, goal, today, { isMember: true, role }));
      }
      // VS1: active first, then ended.
      groups.sort((a, b) => (a.status === b.status ? 0 : a.status === 'ACTIVE' ? -1 : 1));
      res.json({ groups });
    }),
  );

  // 7.2 GET /groups/built-in
  r.get(
    `${P}/groups/built-in`,
    h(async (_req, res) => {
      const caller = await sangatCaller(db, callerUid(res));
      const [snap, ms] = await Promise.all([
        db.collection('groups').where('kind', '==', 'BUILT_IN').where('status', '==', 'ACTIVE').get(),
        db.doc(`memberships/${caller.memberKey}`).get(),
      ]);
      const mine = new Set<string>(ms.exists ? ((ms.get('groupIds') as string[]) ?? []) : []);
      const today = dayIst(clock.now());
      const groups: GroupSummaryDto[] = [];
      for (const d of snap.docs) {
        const g = d.data() as GroupDoc;
        if (!g.currentGoalId) continue; // not started yet in the admin website
        const goal = await readGoal(d.ref, g.currentGoalId);
        groups.push(groupSummaryDto(d.id, g, goal, today, { isMember: mine.has(d.id), role: mine.has(d.id) ? 'MEMBER' : null }));
      }
      groups.sort((a, b) => (a.names?.en ?? '').localeCompare(b.names?.en ?? ''));
      res.json({ groups });
    }),
  );

  // 7.3 GET /groups/{groupId}
  r.get(
    `${P}/groups/:groupId`,
    h(async (req, res) => {
      const caller = await sangatCaller(db, callerUid(res));
      res.json({ group: await groupDetail(db, param(req, 'groupId'), caller, clock.now()) });
    }),
  );

  // 7.4 POST /groups
  r.post(
    `${P}/groups`,
    h(async (req, res) => {
      const uid = callerUid(res);
      const p = await requireProfile(db, uid);
      const raw = bodyOf(req).name;
      const name = typeof raw === 'string' ? raw.trim() : '';
      const n = codePoints(name);
      if (n < 1 || n > GROUP_NAME_MAX) throw Errors.validation({ name: `Group name must be 1–${GROUP_NAME_MAX} characters` });
      const key = `p_${p.doc.profileId}`;
      const [limitSnap, active] = await Promise.all([
        db.doc(`groupLimits/${p.doc.profileId}`).get(),
        db
          .collection('groups')
          .where('creatorKey', '==', key)
          .where('kind', '==', 'CUSTOM')
          .where('status', '==', 'ACTIVE')
          .count()
          .get(),
      ]);
      const limit = limitSnap.exists ? ((limitSnap.get('limit') as number) ?? CUSTOM_GROUPS_ACTIVE_DEFAULT) : CUSTOM_GROUPS_ACTIVE_DEFAULT;
      if (active.data().count >= limit) {
        throw new ApiError(409, 'GROUP_LIMIT_REACHED', `You have ${limit} active groups. To start more, write to ${SUPPORT_EMAIL}.`, { limit });
      }
      const now = clock.now();
      const groupRef = db.collection('groups').doc();
      await db.runTransaction(async (tx) => {
        const code = await freshCode(db, tx);
        const ts = FieldValue.serverTimestamp();
        tx.create(groupRef, {
          kind: 'CUSTOM',
          name,
          names: null,
          creatorKey: key,
          status: 'ACTIVE',
          endedOn: null,
          endReason: null,
          currentGoalId: null,
          memberCount: 1,
          inviteCode: code,
          inviteExpiresAt: inviteExpiry(now),
          goalTemplate: null,
          joinNoticeAt: Timestamp.fromDate(now),
          createdAt: ts,
          updatedAt: ts,
        });
        tx.create(db.doc(`inviteCodes/${code}`), { groupId: groupRef.id, expiresAt: inviteExpiry(now) });
        tx.create(groupRef.collection('members').doc(key), {
          memberKey: key,
          name: p.doc.name,
          role: 'CREATOR',
          status: 'ACTIVE',
          joinedDay: dayIst(now),
          joinedAt: Timestamp.fromDate(now),
          contribution: 0,
          contributionGoalId: null,
          sortName: sortNameOf(p.doc.name),
          updatedAt: ts,
        });
        tx.set(db.doc(`memberships/${key}`), { groupIds: FieldValue.arrayUnion(groupRef.id), updatedAt: ts }, { merge: true });
      });
      const caller: SangatCaller = { uid, memberKey: key, profileId: p.doc.profileId, name: p.doc.name };
      await refreshTokenGroups(db, uid, key);
      res.status(201).json({ group: await groupDetail(db, groupRef.id, caller, now) });
    }),
  );

  /** Reads a custom group and the caller's row; enforces creator-only. */
  async function creatorGroup(tx: Transaction, groupId: string, caller: SangatCaller) {
    const groupRef = db.doc(`groups/${groupId}`);
    const snap = await tx.get(groupRef);
    if (!snap.exists) throw groupNotFound();
    const g = snap.data() as GroupDoc;
    if (g.status === 'DISABLED' || g.kind !== 'CUSTOM') throw groupNotFound();
    const me = await tx.get(groupRef.collection('members').doc(caller.memberKey));
    if (!me.exists || me.get('status') !== 'ACTIVE') throw groupNotFound();
    if (g.creatorKey !== caller.memberKey) throw notCreator();
    return { groupRef, g };
  }

  // 7.5 POST /groups/{groupId}/goal
  r.post(
    `${P}/groups/:groupId/goal`,
    h(async (req, res) => {
      const caller = await sangatCaller(db, callerUid(res));
      const now = clock.now();
      const today = dayIst(now);
      const parsed = parseGoalInput(bodyOf(req), today);
      if (!parsed.ok) throw Errors.validation(parsed.fields);
      const input = parsed.value;
      const groupId = param(req, 'groupId');
      await db.runTransaction(async (tx) => {
        const { groupRef, g } = await creatorGroup(tx, groupId, caller);
        if (g.currentGoalId) throw new ApiError(409, 'GOAL_ALREADY_SET', 'This group already has its goal');
        if (g.status !== 'ACTIVE') throw groupInactive();
        const goalId = goalIdFor(1);
        tx.create(groupRef.collection('goals').doc(goalId), {
          type: input.type,
          baniId: input.baniId,
          simranMinutes: input.simranMinutes,
          target: input.target,
          startDay: today,
          endDay: input.endDay,
          status: 'ACTIVE',
          total: 0,
          dayTotals: {},
          completedAt: null,
          sequence: 1,
          createdAt: FieldValue.serverTimestamp(),
        });
        tx.update(groupRef, { currentGoalId: goalId, updatedAt: FieldValue.serverTimestamp() });
      });
      res.json({ group: await groupDetail(db, groupId, caller, now) });
    }),
  );

  // 7.6 PATCH /groups/{groupId}/goal
  r.patch(
    `${P}/groups/:groupId/goal`,
    h(async (req, res) => {
      const caller = await sangatCaller(db, callerUid(res));
      const now = clock.now();
      const today = dayIst(now);
      const endDay = bodyOf(req).endDay;
      const groupId = param(req, 'groupId');
      await db.runTransaction(async (tx) => {
        const { groupRef, g } = await creatorGroup(tx, groupId, caller);
        if (g.status !== 'ACTIVE') throw groupInactive();
        const goal = await readGoal(groupRef, g.currentGoalId, tx);
        if (!goal) throw new ApiError(409, 'GOAL_NOT_SET', 'This group has no goal yet');
        if (goal.doc.status !== 'ACTIVE') throw groupInactive();
        // CG4: any day from today to start + 364.
        if (!isValidDay(endDay) || endDay < today || endDay > addDays(goal.doc.startDay, GOAL_DAYS_MAX - 1)) {
          throw Errors.validation({ endDay: 'The end date must be from today to 365 days after the start' });
        }
        tx.update(groupRef.collection('goals').doc(goal.id), { endDay });
        tx.update(groupRef, { updatedAt: FieldValue.serverTimestamp() });
      });
      res.json({ group: await groupDetail(db, groupId, caller, now) });
    }),
  );

  // 7.7 DELETE /groups/{groupId}
  r.delete(
    `${P}/groups/:groupId`,
    h(async (req, res) => {
      const caller = await sangatCaller(db, callerUid(res));
      const groupId = param(req, 'groupId');
      let code: string | null = null;
      await db.runTransaction(async (tx) => {
        const { g } = await creatorGroup(tx, groupId, caller);
        if (g.memberCount > 1) throw new ApiError(409, 'GROUP_HAS_MEMBERS', 'The group still has other members');
        code = g.inviteCode;
        // Mark it first so nothing can join while the documents are removed.
        tx.update(db.doc(`groups/${groupId}`), { status: 'DISABLED', endReason: 'ADMIN', updatedAt: FieldValue.serverTimestamp() });
      });
      await deleteGroupEverywhere(db, groupId, code);
      await refreshTokenGroups(db, caller.uid, caller.memberKey);
      res.json({ result: 'GROUP_DELETED', groupId });
    }),
  );

  // 7.8 POST /join
  r.post(
    `${P}/join`,
    h(async (req, res) => {
      const uid = callerUid(res);
      const code = normalizeInviteCode(bodyOf(req).code);
      if (!code) throw codeInvalid();
      const now = clock.now();
      const outcome = await db.runTransaction(async (tx) => {
        const caller = await sangatCallerWithName(db, uid, tx);
        const invite = await tx.get(db.doc(`inviteCodes/${code}`));
        if (!invite.exists) throw codeInvalid();
        const expires = invite.get('expiresAt') as Timestamp;
        if (!expires || expires.toMillis() <= now.getTime()) throw codeInvalid();
        const groupId = invite.get('groupId') as string;
        const groupRef = db.doc(`groups/${groupId}`);
        const gSnap = await tx.get(groupRef);
        if (!gSnap.exists) throw codeInvalid();
        const g = gSnap.data() as GroupDoc;
        if (g.status === 'DISABLED' || g.inviteCode !== code) throw codeInvalid();
        const memberRef = groupRef.collection('members').doc(caller.memberKey);
        const mSnap = await tx.get(memberRef);
        const factsRef = g.creatorKey ? db.doc(`badgeFacts/${g.creatorKey}`) : null;
        const facts = factsRef ? await tx.get(factsRef) : null;
        if (mSnap.exists && mSnap.get('status') === 'ACTIVE') return { result: 'ALREADY_MEMBER', groupId, memberKey: '' };
        if (g.status !== 'ACTIVE') throw groupInactive();
        if (g.memberCount >= CUSTOM_GROUP_MAX_MEMBERS) throw new ApiError(409, 'GROUP_FULL', 'This group is full.');
        writeJoin(tx, groupRef, caller, mSnap.exists ? (mSnap.data() as MemberDoc) : null, now);
        // SF2: the first join of this member key counts toward the creator's Satsangi.
        const joinKey = `${groupId}/${caller.memberKey}`;
        if (!mSnap.exists && factsRef && g.creatorKey !== caller.memberKey && factWouldGrow(facts?.get('joins'), joinKey, BADGE_JOINS_CAP)) {
          tx.set(factsRef, { joins: FieldValue.arrayUnion(joinKey), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
        }
        return { result: 'JOINED', groupId, memberKey: caller.memberKey };
      });
      await refreshTokenGroups(db, uid, outcome.memberKey ?? '');
      res.json({ result: outcome.result, groupId: outcome.groupId });
    }),
  );

  /** Creates or reactivates a member row, counts it, and adds it to "my groups". */
  function writeJoin(tx: Transaction, groupRef: DocumentReference, caller: SangatCaller, existing: MemberDoc | null, now: Date) {
    const ts = FieldValue.serverTimestamp();
    const row = {
      memberKey: caller.memberKey,
      name: caller.name,
      role: existing?.role === 'CREATOR' ? 'CREATOR' : 'MEMBER',
      status: 'ACTIVE',
      joinedDay: dayIst(now),
      joinedAt: Timestamp.fromDate(now),
      contribution: existing?.contribution ?? 0,
      contributionGoalId: existing?.contributionGoalId ?? null,
      sortName: sortNameOf(caller.name),
      updatedAt: ts,
    };
    tx.set(groupRef.collection('members').doc(caller.memberKey), row);
    tx.update(groupRef, { memberCount: FieldValue.increment(1), updatedAt: ts });
    tx.set(db.doc(`memberships/${caller.memberKey}`), { groupIds: FieldValue.arrayUnion(groupRef.id), updatedAt: ts }, { merge: true });
  }

  // 7.9 POST /groups/{groupId}/join (built-in only)
  r.post(
    `${P}/groups/:groupId/join`,
    h(async (req, res) => {
      const uid = callerUid(res);
      const groupId = param(req, 'groupId');
      const now = clock.now();
      const outcome = await db.runTransaction(async (tx) => {
        const caller = await sangatCallerWithName(db, uid, tx);
        const groupRef = db.doc(`groups/${groupId}`);
        const gSnap = await tx.get(groupRef);
        if (!gSnap.exists) throw groupNotFound();
        const g = gSnap.data() as GroupDoc;
        if (g.kind !== 'BUILT_IN' || g.status !== 'ACTIVE') throw groupNotFound();
        const mSnap = await tx.get(groupRef.collection('members').doc(caller.memberKey));
        if (mSnap.exists && mSnap.get('status') === 'ACTIVE') return { result: 'ALREADY_MEMBER', groupId, memberKey: '' };
        writeJoin(tx, groupRef, caller, mSnap.exists ? (mSnap.data() as MemberDoc) : null, now);
        return { result: 'JOINED', groupId, memberKey: caller.memberKey };
      });
      await refreshTokenGroups(db, uid, outcome.memberKey);
      res.json({ result: outcome.result, groupId: outcome.groupId });
    }),
  );

  // 7.9 POST /groups/{groupId}/leave (built-in, or a custom group for anyone but the creator)
  r.post(
    `${P}/groups/:groupId/leave`,
    h(async (req, res) => {
      const caller = await sangatCaller(db, callerUid(res));
      const groupId = param(req, 'groupId');
      await db.runTransaction(async (tx) => {
        const groupRef = db.doc(`groups/${groupId}`);
        const gSnap = await tx.get(groupRef);
        if (!gSnap.exists || gSnap.get('status') === 'DISABLED') throw groupNotFound();
        const memberRef = groupRef.collection('members').doc(caller.memberKey);
        const mSnap = await tx.get(memberRef);
        if (!mSnap.exists || mSnap.get('status') !== 'ACTIVE') throw groupNotFound();
        if (mSnap.get('role') === 'CREATOR') throw new ApiError(409, 'CREATOR_CANNOT_LEAVE', 'The person who started a group cannot leave it');
        const ts = FieldValue.serverTimestamp();
        tx.update(memberRef, { status: 'LEFT', updatedAt: ts }); // CT6: contributions stay
        tx.update(groupRef, { memberCount: FieldValue.increment(-1), updatedAt: ts });
        tx.set(db.doc(`memberships/${caller.memberKey}`), { groupIds: FieldValue.arrayRemove(groupId), updatedAt: ts }, { merge: true });
      });
      await refreshTokenGroups(db, caller.uid, caller.memberKey);
      res.json({ result: 'LEFT', groupId });
    }),
  );

  // 7.10 DELETE /groups/{groupId}/members/{memberKey}
  r.delete(
    `${P}/groups/:groupId/members/:memberKey`,
    h(async (req, res) => {
      const caller = await sangatCaller(db, callerUid(res));
      const groupId = param(req, 'groupId');
      const target = param(req, 'memberKey');
      await db.runTransaction(async (tx) => {
        const { groupRef } = await creatorGroup(tx, groupId, caller);
        const ref = groupRef.collection('members').doc(target);
        const snap = await tx.get(ref);
        if (!snap.exists || snap.get('status') !== 'ACTIVE' || snap.get('role') === 'CREATOR') {
          throw new ApiError(404, 'MEMBER_NOT_FOUND', 'Member not found');
        }
        const ts = FieldValue.serverTimestamp();
        tx.update(ref, { status: 'REMOVED', updatedAt: ts }); // MB4
        tx.update(groupRef, { memberCount: FieldValue.increment(-1), updatedAt: ts });
        tx.set(db.doc(`memberships/${target}`), { groupIds: FieldValue.arrayRemove(groupId), updatedAt: ts }, { merge: true });
      });
      res.json({ result: 'MEMBER_REMOVED', groupId, memberKey: target });
    }),
  );

  // 7.11 POST /groups/{groupId}/invite
  r.post(
    `${P}/groups/:groupId/invite`,
    h(async (req, res) => {
      const caller = await sangatCaller(db, callerUid(res));
      const groupId = param(req, 'groupId');
      const reset = bodyOf(req).reset === true;
      const now = clock.now();
      const out = await db.runTransaction(async (tx) => {
        const groupRef = db.doc(`groups/${groupId}`);
        const gSnap = await tx.get(groupRef);
        if (!gSnap.exists) throw groupNotFound();
        const g = gSnap.data() as GroupDoc;
        if (g.kind !== 'CUSTOM' || g.status === 'DISABLED') throw groupNotFound();
        const me = await tx.get(groupRef.collection('members').doc(caller.memberKey));
        if (!me.exists || me.get('status') !== 'ACTIVE') throw groupNotFound(); // IV1: any member
        if (reset && g.creatorKey !== caller.memberKey) throw notCreator();
        if (g.status !== 'ACTIVE') throw groupInactive();
        if (!reset && validInvite(g, now.getTime())) {
          return { code: g.inviteCode as string, expiresAt: g.inviteExpiresAt as Timestamp };
        }
        // IV2: a new code when expired or reset; the old one ends at once.
        const code = await freshCode(db, tx);
        const expiresAt = inviteExpiry(now);
        if (g.inviteCode) tx.delete(db.doc(`inviteCodes/${g.inviteCode}`));
        tx.create(db.doc(`inviteCodes/${code}`), { groupId, expiresAt });
        tx.update(groupRef, { inviteCode: code, inviteExpiresAt: expiresAt, updatedAt: FieldValue.serverTimestamp() });
        return { code, expiresAt };
      });
      res.json({ code: formatInviteCode(out.code), link: inviteLink(out.code), expiresAt: toIso(out.expiresAt) });
    }),
  );

  // 7.12 POST /contributions
  r.post(
    `${P}/contributions`,
    h(async (req, res) => {
      const items = bodyOf(req).items;
      if (!Array.isArray(items) || items.length > CONTRIBUTIONS_MAX_PER_REQUEST) {
        throw Errors.validation({ items: `items must be a list of at most ${CONTRIBUTIONS_MAX_PER_REQUEST}` });
      }
      const parsed: OutboxItem[] = [];
      for (let i = 0; i < items.length; i++) {
        const p = parseOutboxItem(items[i]);
        if (typeof p === 'string') throw Errors.validation({ [`items[${i}]`]: p });
        parsed.push(p);
      }
      const caller = await sangatCaller(db, callerUid(res));
      const now = clock.now();
      const processed: string[] = [];
      // In order: an ADD and a RETRACT of one id are applied in the order sent (§5.1).
      for (const item of parsed) {
        await processItem(db, caller.memberKey, item, now);
        processed.push(item.id);
      }
      res.json({ result: 'CONTRIBUTIONS_RECEIVED', processed });
    }),
  );

  // 7.13 POST /groups/{groupId}/report
  r.post(
    `${P}/groups/:groupId/report`,
    h(async (req, res) => {
      const caller = await sangatCaller(db, callerUid(res));
      const groupId = param(req, 'groupId');
      const body = bodyOf(req);
      const reason = body.reason;
      if (reason !== 'OFFENSIVE' && reason !== 'SPAM' && reason !== 'OFF_TOPIC' && reason !== 'OTHER') {
        throw Errors.validation({ reason: 'reason must be OFFENSIVE, SPAM, OFF_TOPIC or OTHER' });
      }
      let note: string | null = null;
      if (reason === 'OTHER' && body.note !== undefined && body.note !== null) {
        if (typeof body.note !== 'string' || codePoints(body.note.trim()) > REPORT_NOTE_MAX) {
          throw Errors.validation({ note: `The note can be at most ${REPORT_NOTE_MAX} characters` });
        }
        note = body.note.trim() === '' ? null : body.note.trim();
      }
      const groupRef = db.doc(`groups/${groupId}`);
      const gSnap = await groupRef.get();
      if (!gSnap.exists || gSnap.get('status') === 'DISABLED') throw groupNotFound();
      const me = await groupRef.collection('members').doc(caller.memberKey).get();
      if (!me.exists || me.get('status') !== 'ACTIVE') throw groupNotFound();
      const g = gSnap.data() as GroupDoc;
      // RP3: one report per member per group; reporting again replaces it.
      await db.doc(`groupReports/${groupId}_${caller.memberKey}`).set({
        groupId,
        memberKey: caller.memberKey,
        reason,
        note,
        status: 'OPEN',
        createdAt: FieldValue.serverTimestamp(),
      });
      // RP2: email support. The report is stored either way (README decisions).
      if (mailer.configured()) {
        try {
          await mailer.send({ to: SUPPORT_EMAIL, ...reportTemplate({ groupId, groupName: g.name ?? g.names?.en ?? '', reason, note, memberKey: caller.memberKey }) });
        } catch (err) {
          logger.error('report: support email failed', { groupId, error: String(err) });
        }
      } else {
        logger.error('report: BREVO_API_KEY is not configured; support was not emailed', { groupId });
      }
      res.json({ result: 'REPORT_SENT' });
    }),
  );

  return r;
}

/** Removes a group, its goals, shards, members and invite, and its links from members' lists and contributions. */
export async function deleteGroupEverywhere(db: Firestore, groupId: string, inviteCode: string | null): Promise<void> {
  const groupRef = db.doc(`groups/${groupId}`);
  const members = await groupRef.collection('members').get();
  const writer = db.bulkWriter();
  for (const m of members.docs) {
    void writer.set(db.doc(`memberships/${m.id}`), { groupIds: FieldValue.arrayRemove(groupId) }, { merge: true });
  }
  const contribs = await db.collection('contributions').where('groupIds', 'array-contains', groupId).get();
  for (const c of contribs.docs) {
    const countedIn = ((c.get('countedIn') as string[]) ?? []).filter((k) => !k.startsWith(`${groupId}/`));
    void writer.update(c.ref, { groupIds: FieldValue.arrayRemove(groupId), countedIn });
  }
  if (inviteCode) void writer.delete(db.doc(`inviteCodes/${inviteCode}`));
  await writer.close();
  await db.recursiveDelete(groupRef);
}
