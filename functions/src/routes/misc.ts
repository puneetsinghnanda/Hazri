// Small endpoints: badges (ARCHITECTURE §6.5), devices (§5.10, 02-notifications
// FT1–FT3) and the Vichar library read (01-accounts §13.4).
import { Router } from 'express';
import { FieldValue } from 'firebase-admin/firestore';
import { callerUid } from '../auth';
import { VICHAR_CACHE_SECONDS, VICHAR_MAX_ENTRIES } from '../config';
import type { Deps } from '../deps';
import { Errors } from '../errors';
import { bodyOf, h } from '../http';
import { factCounts } from '../badges/facts';
import { ownedProfile, requireProfile } from '../profile/profile';
import { utcOffsetMinutes } from '../time';

export const VICHAR_KINDS = ['article', 'gurdwara', 'guru', 'bani', 'day'] as const;

export interface VicharEntryDto {
  id: string;
  title: string;
  kind: (typeof VICHAR_KINDS)[number];
  summary: string | null;
  body: string | null;
  minutes: number | null;
  place: string | null;
  facts: Array<{ label: string; value: string }>;
}

const strOrNull = (v: unknown): string | null => (typeof v === 'string' && v.trim() !== '' ? v : null);

/** One stored entry as the app reads it; null when it has no title (docs/vichar-content.md). */
export function vicharEntryDto(id: string, d: Record<string, unknown>): VicharEntryDto | null {
  const title = strOrNull(d.title);
  if (!title) return null;
  const kind = (VICHAR_KINDS as readonly string[]).includes(d.kind as string) ? (d.kind as VicharEntryDto['kind']) : 'article';
  const facts: VicharEntryDto['facts'] = [];
  if (d.facts && typeof d.facts === 'object' && !Array.isArray(d.facts)) {
    for (const [label, value] of Object.entries(d.facts as Record<string, unknown>)) {
      if (typeof value === 'string') facts.push({ label, value });
    }
  }
  return {
    id,
    title,
    kind,
    summary: strOrNull(d.summary),
    body: strOrNull(d.body),
    minutes: typeof d.minutes === 'number' && Number.isFinite(d.minutes) ? d.minutes : null,
    place: strOrNull(d.place),
    facts,
  };
}

export function miscRouter(deps: Deps): Router {
  const { db, clock } = deps;
  const r = Router();
  let vichar: { at: number; entries: VicharEntryDto[] } | null = null;

  // §6.5 GET /badges/sangat: one read of badgeFacts/{callerMemberKey}.
  r.get(
    '/api/v1/badges/sangat',
    h(async (_req, res) => {
      const p = await requireProfile(db, callerUid(res));
      const snap = await db.doc(`badgeFacts/p_${p.doc.profileId}`).get();
      res.json(factCounts(snap.data()));
    }),
  );

  // FT2 POST /devices/fcm-token
  r.post(
    '/api/v1/devices/fcm-token',
    h(async (req, res) => {
      const uid = callerUid(res);
      const p = await requireProfile(db, uid);
      const b = bodyOf(req);
      const fields: Record<string, string> = {};
      const token = typeof b.token === 'string' ? b.token.trim() : '';
      if (token === '' || token.length > 4096) fields.token = 'token is required';
      if (b.locale !== 'pa' && b.locale !== 'hi' && b.locale !== 'en') fields.locale = 'locale must be pa, hi or en';
      const tz = typeof b.tz === 'string' ? b.tz : '';
      const offset = tz ? utcOffsetMinutes(tz, clock.now()) : null;
      if (offset === null) fields.tz = 'tz must be an IANA time zone';
      if (Object.keys(fields).length > 0) throw Errors.validation(fields);
      const ms = await db.doc(`memberships/p_${p.doc.profileId}`).get();
      await db.doc(`fcmTokens/${uid}`).set({
        profileId: p.doc.profileId,
        groupIds: (ms.get('groupIds') as string[] | undefined) ?? [],
        token,
        locale: b.locale,
        tz,
        utcOffsetMin: offset,
        updatedAt: FieldValue.serverTimestamp(),
      });
      res.json({ result: 'TOKEN_SAVED' });
    }),
  );

  // FT2 DELETE /devices/fcm-token. The token is removed even without a profile
  // (it can only ever be this install's), and the answer is still 404 then.
  r.delete(
    '/api/v1/devices/fcm-token',
    h(async (_req, res) => {
      const uid = callerUid(res);
      await db.doc(`fcmTokens/${uid}`).delete();
      if (!(await ownedProfile(db, uid))) throw Errors.noProfile();
      res.json({ result: 'TOKEN_DELETED' });
    }),
  );

  // GET /vichar/entries: the published library, sorted by title, at most 200.
  r.get(
    '/api/v1/vichar/entries',
    h(async (_req, res) => {
      const nowMs = clock.now().getTime();
      if (!vichar || nowMs - vichar.at >= VICHAR_CACHE_SECONDS * 1000) {
        const snap = await db.collection('content').doc('vichar').collection('entries').get();
        const entries = snap.docs
          .map((d) => vicharEntryDto(d.id, d.data()))
          .filter((e): e is VicharEntryDto => e !== null)
          .sort((a, b) => a.title.localeCompare(b.title))
          .slice(0, VICHAR_MAX_ENTRIES);
        vichar = { at: nowMs, entries };
      }
      res.json({ entries: vichar.entries });
    }),
  );

  return r;
}
