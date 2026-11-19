// Announcements (02-notifications AN1-AN8, owner 2026-11-19, option B): the
// admin writes a message in Punjabi, Hindi and English and it is pushed to
// every install with a profile whose token is saved and whose Announcements
// switch is on, each in its own language. A tap opens the message in the app,
// which reports the open; the admin sees who opened it, with name and city.
//
// Cost: one read per token when sending, one write per open. FCM is free.
import { FieldValue, Firestore, Timestamp } from 'firebase-admin/firestore';
import { Router } from 'express';
import { callerUid } from '../auth';
import type { Deps, VerifiedToken } from '../deps';
import { ApiError, Errors } from '../errors';
import { bodyOf, h, param } from '../http';
import { isDeadTokenError, PushMessage } from '../notifications/messenger';
import { ProfileDoc, requireProfile } from '../profile/profile';
import { displayNameOf } from '../quiz/model';
import { toIso } from '../time';
import { emailHashOf, emailNormalizedOf, normalizeEmail } from '../validation';

const LANGS = ['pa', 'hi', 'en'] as const;
type Lang = (typeof LANGS)[number];
type Texts = Record<Lang, string>;

/** What a phone's notification can show without being cut (AN2). */
export const ANNOUNCE_TITLE_MAX = 65;
export const ANNOUNCE_BODY_MAX = 180;
/** The message shown in the app when it is tapped (AN4). */
export const ANNOUNCE_MESSAGE_MAX = 5000;
export const ANNOUNCE_CHANNEL = 'announcements_v1';

export interface AnnouncementDoc {
  title: Texts;
  body: Texts;
  message: Texts;
  createdAt: Timestamp;
  createdBy: string;
  sent: number;
  failed: number;
  optedOut: number;
  opened: number;
  byLang: Record<Lang, number>;
  /** A test sent to one profile (AN10): its email; shown as Test in the list. */
  testTo?: string;
}

interface TokenDoc {
  profileId: string;
  token: string;
  locale: string;
  announcements?: boolean;
}

const asLang = (l: string): Lang => ((LANGS as readonly string[]).includes(l) ? (l as Lang) : 'en');

/** A language left empty falls back to English, then to whichever is written. */
function pick(t: Texts, lang: Lang): string {
  return t[lang].trim() || t.en.trim() || t.pa.trim() || t.hi.trim();
}

function readTexts(b: Record<string, unknown>, key: string, max: number, required: boolean, fields: Record<string, string>): Texts {
  const raw = (b[key] ?? {}) as Record<string, unknown>;
  const out = {} as Texts;
  for (const l of LANGS) {
    const v = typeof raw[l] === 'string' ? (raw[l] as string).trim() : '';
    if (v.length > max) fields[`${key}.${l}`] = `At most ${max} characters`;
    out[l] = v;
  }
  if (required && LANGS.every((l) => out[l] === '')) fields[key] = 'Write it in at least one language';
  return out;
}

/**
 * A test (AN10): the phones of the one profile with this email, whatever its
 * switch says, so the admin can see a message before everybody does.
 */
async function testAudience(db: Firestore, raw: string): Promise<Array<{ id: string; t: TokenDoc }>> {
  const email = normalizeEmail(raw);
  if (email === '') throw Errors.validation({ testEmail: 'Please enter an email' });
  const norm = emailNormalizedOf(email);
  const idx = await db.doc(`emailIndex/${emailHashOf(norm)}`).get();
  const profileId = idx.exists ? (idx.get('profileId') as string) : null;
  const p = profileId ? ((await db.doc(`profiles/${profileId}`).get()).data() as ProfileDoc | undefined) : undefined;
  if (!p || p.emailNormalized !== norm) throw new ApiError(404, 'NOT_FOUND', 'No profile has that email');
  const snap = await db.collection('fcmTokens').where('profileId', '==', p.profileId).get();
  const reach = snap.docs.map((d) => ({ id: d.id, t: d.data() as TokenDoc })).filter(({ t }) => !!t.token);
  if (reach.length === 0) {
    throw new ApiError(409, 'NO_DEVICE', 'That profile has no phone ready: open the new app once with the profile, then try again');
  }
  return reach;
}

/** Who an announcement would reach now: tokens with a profile, and those switched off. */
async function audience(db: Firestore): Promise<{ reach: Array<{ id: string; t: TokenDoc }>; optedOut: number }> {
  const snap = await db.collection('fcmTokens').get();
  const reach: Array<{ id: string; t: TokenDoc }> = [];
  let optedOut = 0;
  for (const d of snap.docs) {
    const t = d.data() as TokenDoc;
    if (!t.token || !t.profileId) continue;
    if (t.announcements === false) optedOut++;
    else reach.push({ id: d.id, t });
  }
  return { reach, optedOut };
}

function dto(id: string, a: AnnouncementDoc) {
  return {
    id,
    title: a.title,
    body: a.body,
    message: a.message,
    createdAt: toIso(a.createdAt),
    sent: a.sent,
    failed: a.failed,
    optedOut: a.optedOut,
    opened: a.opened,
    byLang: a.byLang,
    testTo: a.testTo ?? null,
  };
}

export function announcementsRouter(deps: Deps): Router {
  const { db, clock, messenger } = deps;
  const r = Router();
  const A = '/api/v1/admin/announcements';

  // GET /admin/announcements/audience: how many it would reach, before sending.
  r.get(
    `${A}/audience`,
    h(async (_req, res) => {
      const { reach, optedOut } = await audience(db);
      const byLang: Record<Lang, number> = { pa: 0, hi: 0, en: 0 };
      for (const { t } of reach) byLang[asLang(t.locale)]++;
      res.json({ reach: reach.length, optedOut, byLang });
    }),
  );

  // POST /admin/announcements { title, body, message }: each a { pa, hi, en }.
  // Sends at once, to everyone it reaches, each in their language (AN1-AN3).
  r.post(
    A,
    h(async (req, res) => {
      const b = bodyOf(req);
      const fields: Record<string, string> = {};
      const title = readTexts(b, 'title', ANNOUNCE_TITLE_MAX, true, fields);
      const body = readTexts(b, 'body', ANNOUNCE_BODY_MAX, true, fields);
      const message = readTexts(b, 'message', ANNOUNCE_MESSAGE_MAX, false, fields);
      if (Object.keys(fields).length > 0) throw Errors.validation(fields);

      // AN10: { testEmail, testLang } sends to that one profile, in that language.
      const testEmail = typeof b.testEmail === 'string' ? b.testEmail : null;
      const testLang = typeof b.testLang === 'string' ? asLang(b.testLang) : null;
      const ref = db.collection('announcements').doc();
      const { reach, optedOut } = testEmail !== null ? { reach: await testAudience(db, testEmail), optedOut: 0 } : await audience(db);
      const byLang: Record<Lang, number> = { pa: 0, hi: 0, en: 0 };
      const messages: PushMessage[] = reach.map(({ t }) => {
        const lang = testLang ?? asLang(t.locale);
        byLang[lang]++;
        return {
          token: t.token,
          title: pick(title, lang),
          body: pick(body, lang),
          channelId: ANNOUNCE_CHANNEL,
          data: { kind: 'ANNOUNCEMENT', groupId: '', route: `/announcement/${ref.id}`, announcementId: ref.id },
        };
      });
      const results = messages.length ? await messenger.sendEach(messages) : [];
      let sent = 0;
      let failed = 0;
      const dead: string[] = [];
      results.forEach((x, i) => {
        if (x.ok) sent++;
        else {
          failed++;
          if (isDeadTokenError(x.errorCode)) dead.push(reach[i].id);
        }
      });
      // FM4: an uninstalled app's token goes at once.
      await Promise.all(dead.map((id) => db.doc(`fcmTokens/${id}`).delete()));
      const doc: AnnouncementDoc = {
        title,
        body,
        message,
        createdAt: Timestamp.fromDate(clock.now()),
        createdBy: (res.locals.token as VerifiedToken).email ?? 'admin',
        sent,
        failed,
        optedOut,
        opened: 0,
        byLang,
        ...(testEmail !== null ? { testTo: normalizeEmail(testEmail).toLowerCase() } : {}),
      };
      await ref.set(doc);
      res.status(201).json({ announcement: dto(ref.id, doc) });
    }),
  );

  // GET /admin/announcements: the last 50, newest first, with their numbers.
  r.get(
    A,
    h(async (_req, res) => {
      const snap = await db.collection('announcements').orderBy('createdAt', 'desc').limit(50).get();
      res.json({ announcements: snap.docs.map((d) => dto(d.id, d.data() as AnnouncementDoc)) });
    }),
  );

  // GET /admin/announcements/:id/opens: who opened it, newest first (AN6).
  r.get(
    `${A}/:id/opens`,
    h(async (req, res) => {
      const id = param(req, 'id');
      const snap = await db.collection(`announcements/${id}/opens`).orderBy('at', 'desc').limit(500).get();
      res.json({
        opens: snap.docs.map((d) => ({
          name: ((d.get('fullName') as string | undefined) ?? (d.get('name') as string)) || '',
          cityId: (d.get('cityId') as string | null) ?? null,
          at: toIso(d.get('at')),
        })),
      });
    }),
  );

  // GET /announcements/:id: the message, in the caller's language (AN4).
  r.get(
    '/api/v1/announcements/:id',
    h(async (req, res) => {
      callerUid(res);
      const snap = await db.doc(`announcements/${param(req, 'id')}`).get();
      if (!snap.exists) throw Errors.notFound('No such announcement');
      const a = snap.data() as AnnouncementDoc;
      const lang = asLang(typeof req.query.lang === 'string' ? req.query.lang : 'en');
      res.json({
        id: snap.id,
        title: pick(a.title, lang),
        body: pick(a.body, lang),
        message: pick(a.message, lang) || pick(a.body, lang),
        createdAt: toIso(a.createdAt),
      });
    }),
  );

  // POST /announcements/:id/opened: the tap report (AN5), once per profile.
  r.post(
    '/api/v1/announcements/:id/opened',
    h(async (req, res) => {
      const p = await requireProfile(db, callerUid(res));
      const ref = db.doc(`announcements/${param(req, 'id')}`);
      const open = ref.collection('opens').doc(p.doc.profileId);
      const counted = await db.runTransaction(async (tx) => {
        const [a, o] = await Promise.all([tx.get(ref), tx.get(open)]);
        if (!a.exists) throw new ApiError(404, 'NOT_FOUND', 'No such announcement');
        if (o.exists) return false;
        tx.set(open, {
          name: displayNameOf(p.doc.name),
          fullName: p.doc.name,
          cityId: p.doc.cityId ?? null,
          at: Timestamp.fromDate(clock.now()),
        });
        tx.update(ref, { opened: FieldValue.increment(1) });
        return true;
      });
      res.json({ result: counted ? 'COUNTED' : 'ALREADY' });
    }),
  );

  return r;
}
