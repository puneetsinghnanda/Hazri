// Admin endpoints (11-admin §5, ARCHITECTURE §6.6), all under /api/v1/admin,
// admin-only (AC3). Every change writes adminAudit (AC5).
import { Router } from 'express';
import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { AggregateField, FieldPath, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { CUSTOM_GROUPS_ACTIVE_DEFAULT, GROUP_LIMIT_MAX, GROUP_LIMIT_MIN } from '../config';
import type { Deps, VerifiedToken } from '../deps';
import { ApiError, Errors } from '../errors';
import { bodyOf, h, param, queryString } from '../http';
import type { ProfileDoc } from '../profile/profile';
import { BANIS } from '../reference';
import { goalDto, GoalDoc, GroupDoc } from '../sangat/model';
import { parseNames, parseTemplate, writeGoalFromTemplate } from '../sangat/goals';
import { addDays, dayIst, istDayStart, toIso } from '../time';
import { emailHashOf, emailNormalizedOf, normalizeEmail } from '../validation';
import { deleteGroupEverywhere } from './sangat';

const notFound = () => Errors.notFound('Not found');
const PAGE = 50;

async function audit(db: Firestore, by: string, action: string, target: string, before: unknown, after: unknown) {
  await db.collection('adminAudit').add({
    action,
    target,
    before: before ?? null,
    after: after ?? null,
    by,
    at: FieldValue.serverTimestamp(),
  });
}

/** Firestore values to plain JSON for the audit row and the website. */
function plain(v: unknown): unknown {
  if (v === null || v === undefined) return null;
  if (v instanceof Timestamp) return v.toDate().toISOString();
  if (Array.isArray(v)) return v.map(plain);
  if (typeof v === 'object') return Object.fromEntries(Object.entries(v as Record<string, unknown>).map(([k, x]) => [k, plain(x)]));
  return v;
}

function adminGroupDto(id: string, g: GroupDoc, goal: { id: string; doc: GoalDoc } | null, today: string) {
  return {
    groupId: id,
    kind: g.kind,
    name: g.name ?? null,
    names: g.names ?? null,
    status: g.status,
    creatorKey: g.creatorKey ?? null,
    memberCount: g.memberCount,
    endedOn: g.endedOn ?? null,
    endReason: g.endReason ?? null,
    goalTemplate: g.goalTemplate ?? null,
    currentGoal: goal ? goalDto(goal.id, goal.doc, today) : null,
    createdAt: toIso(g.createdAt),
  };
}

async function currentGoal(db: Firestore, groupId: string, g: GroupDoc) {
  if (!g.currentGoalId) return null;
  const s = await db.doc(`groups/${groupId}/goals/${g.currentGoalId}`).get();
  return s.exists ? { id: s.id, doc: s.data() as GoalDoc } : null;
}

export function adminRouter(deps: Deps): Router {
  const { db, clock } = deps;
  const r = Router();
  const P = '/api/v1/admin';
  const by = (res: { locals: Record<string, unknown> }) => (res.locals.token as VerifiedToken).email ?? 'admin';

  // 4.1 Dashboard: counted when the page opens; nothing polls.
  r.get(
    `${P}/dashboard`,
    h(async (_req, res) => {
      const now = clock.now();
      const today = dayIst(now);
      const profiles = db.collection('profiles');
      const days = Array.from({ length: 30 }, (_, i) => addDays(today, -29 + i));
      const [opened, total, perDay, activeCustom, builtIn, paath, openReports] = await Promise.all([
        profiles.where('lastSeenDay', '==', today).count().get(),
        profiles.count().get(),
        Promise.all(
          days.map((d) =>
            profiles
              .where('createdAt', '>=', Timestamp.fromDate(istDayStart(d)))
              .where('createdAt', '<', Timestamp.fromDate(istDayStart(addDays(d, 1))))
              .count()
              .get()
              .then((s) => ({ day: d, count: s.data().count })),
          ),
        ),
        db.collection('groups').where('kind', '==', 'CUSTOM').where('status', '==', 'ACTIVE').count().get(),
        db.collection('groups').where('kind', '==', 'BUILT_IN').get(),
        db
          .collection('contributions')
          .where('day', '==', today)
          .where('retracted', '==', false)
          .aggregate({ n: AggregateField.sum('countedCount') })
          .get(),
        db.collection('groupReports').where('status', '==', 'OPEN').count().get(),
      ]);
      const builtInGroups = await Promise.all(
        builtIn.docs.map(async (d) => adminGroupDto(d.id, d.data() as GroupDoc, await currentGoal(db, d.id, d.data() as GroupDoc), today)),
      );
      res.json({
        day: today,
        openedToday: opened.data().count,
        totalProfiles: total.data().count,
        newProfilesPerDay: perDay,
        activeCustomGroups: activeCustom.data().count,
        builtInGroups,
        sangatPaathToday: paath.data().n ?? 0,
        openReports: openReports.data().count,
      });
    }),
  );

  // GET /groups?kind=&status=&cursor=
  r.get(
    `${P}/groups`,
    h(async (req, res) => {
      const kind = queryString(req, 'kind');
      const status = queryString(req, 'status');
      const cursor = queryString(req, 'cursor');
      if (kind && kind !== 'BUILT_IN' && kind !== 'CUSTOM') throw Errors.validation({ kind: 'kind must be BUILT_IN or CUSTOM' });
      if (status && !['ACTIVE', 'INACTIVE', 'DISABLED'].includes(status)) {
        throw Errors.validation({ status: 'status must be ACTIVE, INACTIVE or DISABLED' });
      }
      let q: FirebaseFirestore.Query = db.collection('groups');
      if (kind) q = q.where('kind', '==', kind);
      if (status) q = q.where('status', '==', status);
      q = q.orderBy(FieldPath.documentId());
      if (cursor) q = q.startAfter(cursor);
      const snap = await q.limit(PAGE + 1).get();
      const docs = snap.docs.slice(0, PAGE);
      const today = dayIst(clock.now());
      const groups = await Promise.all(
        docs.map(async (d) => adminGroupDto(d.id, d.data() as GroupDoc, await currentGoal(db, d.id, d.data() as GroupDoc), today)),
      );
      res.json({ groups, next: snap.docs.length > PAGE ? docs[docs.length - 1].id : null });
    }),
  );

  // GET /groups/{groupId}: one group, for the report page (4.3).
  r.get(
    `${P}/groups/:groupId`,
    h(async (req, res) => {
      const id = param(req, 'groupId');
      const snap = await db.doc(`groups/${id}`).get();
      if (!snap.exists) throw notFound();
      const g = snap.data() as GroupDoc;
      res.json({ group: adminGroupDto(id, g, await currentGoal(db, id, g), dayIst(clock.now())) });
    }),
  );

  // POST /groups/built-in { names, goalTemplate }
  r.post(
    `${P}/groups/built-in`,
    h(async (req, res) => {
      const b = bodyOf(req);
      const names = parseNames(b.names);
      const template = parseTemplate(b.goalTemplate);
      const fields = { ...(names.ok ? {} : names.fields), ...(template.ok ? {} : template.fields) };
      if (!names.ok || !template.ok) throw Errors.validation(fields);
      const ref = db.collection('groups').doc();
      const ts = FieldValue.serverTimestamp();
      const doc = {
        kind: 'BUILT_IN',
        name: null,
        names: names.value,
        creatorKey: null,
        status: 'ACTIVE',
        endedOn: null,
        endReason: null,
        currentGoalId: null,
        memberCount: 0,
        inviteCode: null,
        inviteExpiresAt: null,
        goalTemplate: template.value,
        createdAt: ts,
        updatedAt: ts,
      };
      await ref.create(doc);
      await audit(db, by(res), 'CREATE_BUILT_IN_GROUP', `groups/${ref.id}`, null, { names: names.value, goalTemplate: template.value });
      const g = (await ref.get()).data() as GroupDoc;
      res.status(201).json({ group: adminGroupDto(ref.id, g, null, dayIst(clock.now())) });
    }),
  );

  // PATCH /groups/{groupId} { names?, goalTemplate?, status? }
  r.patch(
    `${P}/groups/:groupId`,
    h(async (req, res) => {
      const id = param(req, 'groupId');
      const b = bodyOf(req);
      const ref = db.doc(`groups/${id}`);
      const out = await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists) throw notFound();
        const g = snap.data() as GroupDoc;
        const update: Record<string, unknown> = {};
        const fields: Record<string, string> = {};
        if (b.names !== undefined) {
          if (g.kind !== 'BUILT_IN') fields.names = 'Only built-in groups have three names';
          else {
            const n = parseNames(b.names);
            if (n.ok) update.names = n.value;
            else Object.assign(fields, n.fields);
          }
        }
        let goalChange: { ref: DocumentReference; before: { target: number; endDay: string }; after: { target: number; endDay: string } } | null = null;
        if (b.goalTemplate !== undefined) {
          if (g.kind !== 'BUILT_IN') fields.goalTemplate = 'Only built-in groups have a goal template';
          else {
            const t = parseTemplate(b.goalTemplate);
            if (t.ok) {
              update.goalTemplate = t.value;
              // 4.2: the template applies to the running goal too -- its target
              // and length, never its bani, which its total was counted in.
              if (g.currentGoalId) {
                const goalRef = ref.collection('goals').doc(g.currentGoalId);
                const goal = (await tx.get(goalRef)).data() as GoalDoc | undefined;
                if (goal && goal.status === 'ACTIVE') {
                  const today = dayIst(clock.now());
                  const end = addDays(goal.startDay, t.value.lengthDays - 1);
                  const after = { target: t.value.target, endDay: end < today ? today : end };
                  if (after.target !== goal.target || after.endDay !== goal.endDay) {
                    goalChange = { ref: goalRef, before: { target: goal.target, endDay: goal.endDay }, after };
                  }
                }
              }
            } else Object.assign(fields, t.fields);
          }
        }
        if (b.status !== undefined) {
          if (b.status === 'DISABLED') {
            if (g.status !== 'DISABLED') {
              update.status = 'DISABLED';
              update.statusBeforeDisable = g.status;
            }
          } else if (b.status === 'ACTIVE') {
            if (g.status === 'DISABLED') {
              update.status = g.statusBeforeDisable ?? 'ACTIVE';
              update.statusBeforeDisable = null;
            }
          } else fields.status = 'status must be ACTIVE or DISABLED';
        }
        if (Object.keys(fields).length > 0) throw Errors.validation(fields);
        if (Object.keys(update).length > 0) tx.update(ref, { ...update, updatedAt: FieldValue.serverTimestamp() });
        if (goalChange) tx.update(goalChange.ref, goalChange.after);
        const before: Record<string, unknown> = Object.fromEntries(Object.keys(update).map((k) => [k, plain((g as unknown as Record<string, unknown>)[k])]));
        const after: Record<string, unknown> = plain(update) as Record<string, unknown>;
        if (goalChange) {
          before.currentGoal = goalChange.before;
          after.currentGoal = goalChange.after;
        }
        return { before, after };
      });
      await audit(db, by(res), 'UPDATE_GROUP', `groups/${id}`, out.before, out.after);
      const g = (await ref.get()).data() as GroupDoc;
      res.json({ group: adminGroupDto(id, g, await currentGoal(db, id, g), dayIst(clock.now())) });
    }),
  );

  // POST /groups/{groupId}/start: the first goal of a built-in group, from today (IST).
  r.post(
    `${P}/groups/:groupId/start`,
    h(async (req, res) => {
      const id = param(req, 'groupId');
      const ref = db.doc(`groups/${id}`);
      const today = dayIst(clock.now());
      const goalId = await db.runTransaction(async (tx) => {
        const snap = await tx.get(ref);
        if (!snap.exists) throw notFound();
        const g = snap.data() as GroupDoc;
        if (g.kind !== 'BUILT_IN') throw Errors.validation({ groupId: 'Only built-in groups are started here' });
        if (g.currentGoalId) throw new ApiError(409, 'GOAL_ALREADY_SET', 'This group has already been started');
        if (!g.goalTemplate) throw Errors.validation({ goalTemplate: 'Set a goal template first' });
        return writeGoalFromTemplate(tx, ref, g.goalTemplate, 1, today);
      });
      await audit(db, by(res), 'START_GROUP', `groups/${id}`, null, { goalId, startDay: today });
      const g = (await ref.get()).data() as GroupDoc;
      res.json({ group: adminGroupDto(id, g, await currentGoal(db, id, g), today) });
    }),
  );

  // DELETE /groups/{groupId} { confirmName }
  r.delete(
    `${P}/groups/:groupId`,
    h(async (req, res) => {
      const id = param(req, 'groupId');
      const ref = db.doc(`groups/${id}`);
      const snap = await ref.get();
      if (!snap.exists) throw notFound();
      const g = snap.data() as GroupDoc;
      const name = g.kind === 'BUILT_IN' ? (g.names?.en ?? '') : (g.name ?? '');
      const confirm = bodyOf(req).confirmName;
      if (typeof confirm !== 'string' || confirm.trim() !== name.trim()) {
        throw new ApiError(409, 'CONFIRM_MISMATCH', 'The name typed does not match the group');
      }
      await ref.update({ status: 'DISABLED', updatedAt: FieldValue.serverTimestamp() });
      await deleteGroupEverywhere(db, id, g.inviteCode ?? null);
      await audit(db, by(res), 'DELETE_GROUP', `groups/${id}`, plain(g), null);
      res.json({ result: 'GROUP_DELETED', groupId: id });
    }),
  );

  // GET /groups/{groupId}/history: past goals.
  r.get(
    `${P}/groups/:groupId/history`,
    h(async (req, res) => {
      const id = param(req, 'groupId');
      const gSnap = await db.doc(`groups/${id}`).get();
      if (!gSnap.exists) throw notFound();
      const g = gSnap.data() as GroupDoc;
      const goals = await db.collection(`groups/${id}/goals`).orderBy('sequence', 'desc').get();
      const today = dayIst(clock.now());
      const past = await Promise.all(
        goals.docs
          .filter((d) => d.get('status') !== 'ACTIVE')
          .map(async (d) => {
            const memberCount =
              g.kind === 'BUILT_IN' ? (await d.ref.collection('members').count().get()).data().count : g.memberCount;
            return { ...goalDto(d.id, d.data() as GoalDoc, today), memberCount };
          }),
      );
      res.json({ goals: past });
    }),
  );

  // GET /reports?status=
  r.get(
    `${P}/reports`,
    h(async (req, res) => {
      const status = queryString(req, 'status');
      if (status && !['OPEN', 'ACTIONED', 'DISMISSED'].includes(status)) {
        throw Errors.validation({ status: 'status must be OPEN, ACTIONED or DISMISSED' });
      }
      let q: FirebaseFirestore.Query = db.collection('groupReports');
      if (status) q = q.where('status', '==', status);
      const snap = await q.orderBy('createdAt', 'desc').limit(200).get();
      const groupIds = [...new Set(snap.docs.map((d) => d.get('groupId') as string))];
      const info = new Map<string, { name: string | null; kind: string | null; status: string | null; reports: number }>();
      await Promise.all(
        groupIds.map(async (gid) => {
          const [g, n] = await Promise.all([
            db.doc(`groups/${gid}`).get(),
            db.collection('groupReports').where('groupId', '==', gid).count().get(),
          ]);
          const gd = g.data() as GroupDoc | undefined;
          info.set(gid, {
            name: gd ? (gd.name ?? gd.names?.en ?? null) : null,
            kind: gd?.kind ?? null,
            status: gd?.status ?? null,
            reports: n.data().count,
          });
        }),
      );
      const reports = snap.docs.map((d) => {
        const gi = info.get(d.get('groupId') as string);
        return {
          reportId: d.id,
          groupId: d.get('groupId') as string,
          groupName: gi?.name ?? null,
          groupKind: gi?.kind ?? null,
          groupStatus: gi?.status ?? null,
          reportsForGroup: gi?.reports ?? 0,
          memberKey: d.get('memberKey') as string,
          reason: d.get('reason') as string,
          note: (d.get('note') as string | null) ?? null,
          status: d.get('status') as string,
          createdAt: toIso(d.get('createdAt')),
        };
      });
      // 4.3: open reports first.
      reports.sort((a, b) => (a.status === 'OPEN' ? 0 : 1) - (b.status === 'OPEN' ? 0 : 1));
      res.json({ reports });
    }),
  );

  // PATCH /reports/{reportId} { status }
  r.patch(
    `${P}/reports/:reportId`,
    h(async (req, res) => {
      const id = param(req, 'reportId');
      const status = bodyOf(req).status;
      if (status !== 'DISMISSED' && status !== 'ACTIONED') throw Errors.validation({ status: 'status must be DISMISSED or ACTIONED' });
      const ref = db.doc(`groupReports/${id}`);
      const snap = await ref.get();
      if (!snap.exists) throw notFound();
      await ref.update({ status });
      await audit(db, by(res), 'UPDATE_REPORT', `groupReports/${id}`, { status: snap.get('status') }, { status });
      res.json({ result: 'REPORT_UPDATED', reportId: id, status });
    }),
  );

  // GET /people?email= (4.4)
  r.get(
    `${P}/people`,
    h(async (req, res) => {
      const email = normalizeEmail(queryString(req, 'email') ?? '');
      if (email === '') throw Errors.validation({ email: 'Please enter an email' });
      const norm = emailNormalizedOf(email);
      const idx = await db.doc(`emailIndex/${emailHashOf(norm)}`).get();
      if (!idx.exists) throw notFound();
      const pSnap = await db.doc(`profiles/${idx.get('profileId') as string}`).get();
      const p = pSnap.data() as ProfileDoc | undefined;
      if (!p || p.emailNormalized !== norm) throw notFound();
      const [active, limit] = await Promise.all([
        db
          .collection('groups')
          .where('creatorKey', '==', `p_${p.profileId}`)
          .where('kind', '==', 'CUSTOM')
          .where('status', '==', 'ACTIVE')
          .count()
          .get(),
        db.doc(`groupLimits/${p.profileId}`).get(),
      ]);
      res.json({
        person: {
          profileId: p.profileId,
          name: p.name,
          email: p.email,
          cityId: p.cityId,
          emailVerified: p.emailVerified,
          createdAt: toIso(p.createdAt),
          lastSeenDay: p.lastSeenDay ?? null,
          activeCustomGroups: active.data().count,
          groupLimit: limit.exists ? (limit.get('limit') as number) : CUSTOM_GROUPS_ACTIVE_DEFAULT,
        },
      });
    }),
  );

  // PUT /people/{profileId}/group-limit { limit }
  r.put(
    `${P}/people/:profileId/group-limit`,
    h(async (req, res) => {
      const profileId = param(req, 'profileId');
      const limit = bodyOf(req).limit;
      if (typeof limit !== 'number' || !Number.isInteger(limit) || limit < GROUP_LIMIT_MIN || limit > GROUP_LIMIT_MAX) {
        throw Errors.validation({ limit: `limit must be ${GROUP_LIMIT_MIN}–${GROUP_LIMIT_MAX}` });
      }
      const p = await db.doc(`profiles/${profileId}`).get();
      if (!p.exists) throw notFound();
      const ref = db.doc(`groupLimits/${profileId}`);
      const before = await ref.get();
      await ref.set({ limit, setBy: by(res), updatedAt: FieldValue.serverTimestamp() });
      await audit(db, by(res), 'SET_GROUP_LIMIT', `groupLimits/${profileId}`, before.exists ? { limit: before.get('limit') } : null, { limit });
      res.json({ result: 'GROUP_LIMIT_SET', profileId, limit });
    }),
  );

  // GET /banis: for the goal form (4.2), from content.db.
  r.get(
    `${P}/banis`,
    h(async (_req, res) => {
      res.json({ banis: BANIS.map((b) => ({ id: b.id, nameEn: b.en, namePa: b.pa, nameHi: b.hi })) });
    }),
  );

  return r;
}
