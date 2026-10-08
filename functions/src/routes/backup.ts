// Weekly backup (10-backup §6, ARCHITECTURE §6.4) and badge backup (§5.9).
import { Router } from 'express';
import type { DocumentReference, DocumentSnapshot } from 'firebase-admin/firestore';
import { FieldPath, FieldValue, Timestamp } from 'firebase-admin/firestore';
import { callerUid } from '../auth';
import {
  BACKUP_DOC_MAX_BYTES,
  BACKUP_MAX_ROWS_PER_REQUEST,
  BACKUP_RATE_LIMIT,
  BACKUP_RATE_WINDOW_SECONDS,
  RESTORE_PAGE_WEEKS,
} from '../config';
import type { Deps } from '../deps';
import { ApiError, Errors } from '../errors';
import { bodyOf, h, queryString } from '../http';
import { requireProfile } from '../profile/profile';
import { isValidDay, toIso, weekIdOf } from '../time';
import { approxSize, canonical, fromStored, mergeInto, Row, Table, toStored, validateRow } from '../backup/rows';

interface ParsedBackup {
  goals: Array<{ goal: Row; items: Row[] }>;
  completions: Row[];
  simranSessions: Row[];
  badges: Row[];
  final: boolean;
  rows: number;
}

function arr(v: unknown): unknown[] | null {
  if (v === undefined || v === null) return [];
  return Array.isArray(v) ? v : null;
}

/** Step 1: every row valid, at most BACKUP_MAX_ROWS_PER_REQUEST, or 400 naming the first bad row. */
export function parseBackup(body: Record<string, unknown>): ParsedBackup {
  const goalsRaw = arr(body.goals);
  const completionsRaw = arr(body.completions);
  const sessionsRaw = arr(body.simranSessions);
  const badgesRaw = arr(body.badges);
  if (!goalsRaw || !completionsRaw || !sessionsRaw || !badgesRaw) {
    throw Errors.validation({ body: 'goals, completions, simranSessions and badges must be lists' });
  }
  let rows = completionsRaw.length + sessionsRaw.length + badgesRaw.length;
  for (const g of goalsRaw) {
    const items = g && typeof g === 'object' ? (g as { items?: unknown }).items : undefined;
    rows += 1 + (Array.isArray(items) ? items.length : 0);
  }
  if (rows > BACKUP_MAX_ROWS_PER_REQUEST) {
    throw Errors.validation({ rows: `At most ${BACKUP_MAX_ROWS_PER_REQUEST} rows per request` });
  }
  const one = (table: Table, raw: unknown, where: string): Row => {
    const v = validateRow(table, raw);
    if ('error' in v) throw Errors.validation({ [where]: v.error });
    return canonical(table, v.row);
  };
  const goals: ParsedBackup['goals'] = goalsRaw.map((g, i) => {
    if (!g || typeof g !== 'object' || Array.isArray(g)) throw Errors.validation({ [`goals[${i}]`]: 'must be { goal, items }' });
    const o = g as { goal?: unknown; items?: unknown };
    const goal = one('goal', o.goal, `goals[${i}].goal`);
    const itemsRaw = arr(o.items);
    if (!itemsRaw) throw Errors.validation({ [`goals[${i}].items`]: 'must be a list' });
    const items = itemsRaw.map((it, j) => {
      const row = one('item', it, `goals[${i}].items[${j}]`);
      if (row.goalId !== goal.id) throw Errors.validation({ [`goals[${i}].items[${j}]`]: 'goalId must be its goal’s id' });
      return row;
    });
    return { goal, items };
  });
  return {
    goals,
    completions: completionsRaw.map((r, i) => one('completion', r, `completions[${i}]`)),
    simranSessions: sessionsRaw.map((r, i) => one('session', r, `simranSessions[${i}]`)),
    badges: badgesRaw.map((r, i) => one('badge', r, `badges[${i}]`)),
    final: body.final === true,
    rows,
  };
}

function storedMap(table: Table, m: unknown): Record<string, Row> {
  const out: Record<string, Row> = {};
  if (m && typeof m === 'object') {
    for (const [k, v] of Object.entries(m as Record<string, Record<string, unknown>>)) out[k] = fromStored(table, v);
  }
  return out;
}

function toStoredMap(table: Table, rows: Record<string, Row>): Record<string, unknown> {
  return Object.fromEntries(Object.entries(rows).map(([k, r]) => [k, toStored(table, r)]));
}

function byUpdated(a: Row, b: Row): number {
  return String(a.createdAt ?? a.updatedAt).localeCompare(String(b.createdAt ?? b.updatedAt)) || String(a.id).localeCompare(String(b.id));
}

export function backupRouter(deps: Deps): Router {
  const { db, clock } = deps;
  const r = Router();
  const P = '/api/v1/backup';

  // §6.1 GET /backup/manifest
  r.get(
    `${P}/manifest`,
    h(async (_req, res) => {
      const p = await requireProfile(db, callerUid(res));
      const snap = await p.ref.collection('backupMeta').doc('manifest').get();
      const m = snap.data() ?? {};
      res.json({
        lastBackupAt: toIso(m.lastBackupAt),
        goalIds: (m.goalIds as string[]) ?? [],
        weeks: (m.weeks as Record<string, number>) ?? {},
        rowCount: (m.rowCount as number) ?? 0,
      });
    }),
  );

  // §6.2 POST /backup
  r.post(
    `${P}`,
    h(async (req, res) => {
      const uid = callerUid(res);
      const p = await requireProfile(db, uid);
      const parsed = parseBackup(bodyOf(req));
      const now = clock.now();

      // Step 2: BACKUP_RATE_LIMIT requests per profile per hour.
      const rateRef = p.ref.collection('backupMeta').doc('rate');
      await db.runTransaction(async (tx) => {
        const s = await tx.get(rateRef);
        const start = s.exists ? (s.get('windowStartAt') as Timestamp).toMillis() : null;
        const count = s.exists ? ((s.get('count') as number) ?? 0) : 0;
        const nowMs = now.getTime();
        if (start === null || nowMs - start >= BACKUP_RATE_WINDOW_SECONDS * 1000) {
          tx.set(rateRef, { windowStartAt: Timestamp.fromMillis(nowMs), count: 1 });
          return;
        }
        if (count >= BACKUP_RATE_LIMIT) {
          throw Errors.rateLimited(Math.ceil(BACKUP_RATE_WINDOW_SECONDS - (nowMs - start) / 1000), 'Too many backups; try again later');
        }
        tx.update(rateRef, { count: count + 1 });
      });

      // Step 3: group rows by target document.
      const goalsById = new Map<string, { goal: Row; items: Row[] }>();
      for (const g of parsed.goals) {
        const id = g.goal.id as string;
        const prev = goalsById.get(id);
        if (prev) {
          prev.goal = g.goal;
          prev.items.push(...g.items);
        } else goalsById.set(id, { goal: g.goal, items: [...g.items] });
      }
      const weeks = new Map<string, { completions: Row[]; simranSessions: Row[] }>();
      const weekOf = (id: string) => {
        let w = weeks.get(id);
        if (!w) weeks.set(id, (w = { completions: [], simranSessions: [] }));
        return w;
      };
      for (const c of parsed.completions) weekOf(weekIdOf(c.localDate as string)).completions.push(c);
      for (const s of parsed.simranSessions) weekOf(weekIdOf(s.localDate as string)).simranSessions.push(s);

      // Step 4–5: one transaction: read, merge, size check, write; then the manifest.
      const manifestRef = p.ref.collection('backupMeta').doc('manifest');
      const result = await db.runTransaction(async (tx) => {
        const goalRefs = [...goalsById.keys()].map((id) => p.ref.collection('backupGoals').doc(id));
        const weekRefs = [...weeks.keys()].map((id) => p.ref.collection('backupWeeks').doc(id));
        const badgesRef = p.ref.collection('backupBadges').doc('all');
        const refs: DocumentReference[] = [manifestRef, ...goalRefs, ...weekRefs];
        if (parsed.badges.length > 0) refs.push(badgesRef);
        const snaps: DocumentSnapshot[] = refs.length > 0 ? await tx.getAll(...refs) : [];
        const snapOf = new Map(snaps.map((s) => [s.ref.path, s]));
        const manifest = snapOf.get(manifestRef.path)?.data() ?? {};
        const goalIds = new Set<string>((manifest.goalIds as string[]) ?? []);
        const weekCounts: Record<string, number> = { ...((manifest.weeks as Record<string, number>) ?? {}) };
        const goalRowCounts: Record<string, number> = { ...((manifest.goalRowCounts as Record<string, number>) ?? {}) };
        let badgeCount = (manifest.badgeCount as number) ?? 0;
        const writes: Array<{ ref: DocumentReference; data: Record<string, unknown> }> = [];
        const tooLarge = () => new ApiError(413, 'BACKUP_TOO_LARGE', "This week's backup is too large");

        for (const ref of goalRefs) {
          const incoming = goalsById.get(ref.id)!;
          const cur = snapOf.get(ref.path)?.data();
          const goalM = mergeInto('goal', cur?.goal ? { [ref.id]: fromStored('goal', cur.goal) } : {}, [incoming.goal]);
          const itemsM = mergeInto('item', storedMap('item', cur?.items), incoming.items);
          goalIds.add(ref.id);
          goalRowCounts[ref.id] = 1 + Object.keys(itemsM.rows).length;
          if (!goalM.changed && !itemsM.changed && cur) continue;
          const data = {
            goal: toStored('goal', goalM.rows[ref.id]),
            items: toStoredMap('item', itemsM.rows),
            serverUpdatedAt: FieldValue.serverTimestamp(),
          };
          if (approxSize(data) > BACKUP_DOC_MAX_BYTES) throw tooLarge();
          writes.push({ ref, data });
        }
        for (const ref of weekRefs) {
          const incoming = weeks.get(ref.id)!;
          const cur = snapOf.get(ref.path)?.data();
          const cM = mergeInto('completion', storedMap('completion', cur?.completions), incoming.completions);
          const sM = mergeInto('session', storedMap('session', cur?.simranSessions), incoming.simranSessions);
          weekCounts[ref.id] = Object.keys(cM.rows).length + Object.keys(sM.rows).length;
          if (!cM.changed && !sM.changed && cur) continue;
          const data = {
            weekId: ref.id,
            completions: toStoredMap('completion', cM.rows),
            simranSessions: toStoredMap('session', sM.rows),
            serverUpdatedAt: FieldValue.serverTimestamp(),
          };
          if (approxSize(data) > BACKUP_DOC_MAX_BYTES) throw tooLarge();
          writes.push({ ref, data });
        }
        if (parsed.badges.length > 0) {
          const cur = snapOf.get(badgesRef.path)?.data();
          const bM = mergeInto('badge', storedMap('badge', cur?.badges), parsed.badges);
          badgeCount = Object.keys(bM.rows).length;
          if (bM.changed || !cur) {
            writes.push({ ref: badgesRef, data: { badges: toStoredMap('badge', bM.rows), serverUpdatedAt: FieldValue.serverTimestamp() } });
          }
        }
        for (const w of writes) tx.set(w.ref, w.data);
        const rowCount =
          Object.values(weekCounts).reduce((a, b) => a + b, 0) + Object.values(goalRowCounts).reduce((a, b) => a + b, 0) + badgeCount;
        const lastBackupAt = parsed.final ? Timestamp.fromDate(now) : null;
        const m: Record<string, unknown> = {
          goalIds: [...goalIds].sort(),
          weeks: weekCounts,
          goalRowCounts,
          badgeCount,
          rowCount,
          schemaVersion: 1,
          updatedAt: FieldValue.serverTimestamp(),
        };
        if (!snapOf.get(manifestRef.path)?.exists) {
          m.lastBackupAt = null;
          m.lastBackupUid = null;
        }
        if (lastBackupAt) {
          m.lastBackupAt = lastBackupAt;
          m.lastBackupUid = uid;
        }
        tx.set(manifestRef, m, { merge: true });
        return { documentsWritten: writes.length + 1, lastBackupAt };
      });

      const body: Record<string, unknown> = {
        result: 'BACKUP_SAVED',
        rowsReceived: parsed.rows,
        documentsWritten: result.documentsWritten,
      };
      body.lastBackupAt = result.lastBackupAt ? result.lastBackupAt.toDate().toISOString() : null;
      res.json(body);
    }),
  );

  // §6.3 GET /backup/goals
  r.get(
    `${P}/goals`,
    h(async (_req, res) => {
      const p = await requireProfile(db, callerUid(res));
      const snap = await p.ref.collection('backupGoals').get();
      const goals = snap.docs.map((d) => {
        const data = d.data();
        const items = Object.values(storedMap('item', data.items)).sort(byUpdated);
        return { goal: fromStored('goal', data.goal as Record<string, unknown>), items };
      });
      res.json({ goals });
    }),
  );

  // §6.4 GET /backup/weeks?from={weekId}&limit={n}
  r.get(
    `${P}/weeks`,
    h(async (req, res) => {
      const p = await requireProfile(db, callerUid(res));
      const from = queryString(req, 'from');
      if (from !== null && !isValidDay(from)) throw Errors.validation({ from: 'from must be a weekId (YYYY-MM-DD)' });
      const limitRaw = queryString(req, 'limit');
      const limit = limitRaw === null ? RESTORE_PAGE_WEEKS : Number(limitRaw);
      if (!Number.isInteger(limit) || limit < 1 || limit > RESTORE_PAGE_WEEKS) {
        throw Errors.validation({ limit: `limit must be 1–${RESTORE_PAGE_WEEKS}` });
      }
      let q = p.ref.collection('backupWeeks').orderBy(FieldPath.documentId());
      if (from) q = q.startAt(from);
      const snap = await q.limit(limit + 1).get();
      const docs = snap.docs.slice(0, limit);
      const weeks = docs.map((d) => {
        const data = d.data();
        return {
          weekId: d.id,
          completions: Object.values(storedMap('completion', data.completions)).sort(byUpdated),
          simranSessions: Object.values(storedMap('session', data.simranSessions)).sort(byUpdated),
        };
      });
      res.json({ weeks, next: snap.docs.length > limit ? snap.docs[limit].id : null });
    }),
  );

  // §6.4a GET /backup/badges
  r.get(
    `${P}/badges`,
    h(async (_req, res) => {
      const p = await requireProfile(db, callerUid(res));
      const snap = await p.ref.collection('backupBadges').doc('all').get();
      const badges = Object.values(storedMap('badge', snap.data()?.badges)).sort((a, b) =>
        String(a.badgeId).localeCompare(String(b.badgeId)),
      );
      res.json({ badges });
    }),
  );

  return r;
}
