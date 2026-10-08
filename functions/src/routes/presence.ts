// Presence (07-simran §6, ARCHITECTURE §6.2).
import { gzipSync } from 'node:zlib';
import { Router } from 'express';
import { callerUid } from '../auth';
import { GLOBE_CACHE_SECONDS } from '../config';
import type { Deps } from '../deps';
import { ApiError, Errors } from '../errors';
import { h } from '../http';
import { dayIst, toIso } from '../time';

interface CachedGlobe {
  at: number;
  json: string;
  gzip: Buffer;
}

export function presenceRouter(deps: Deps): Router {
  const { db, clock } = deps;
  const r = Router();
  // One snapshot per instance for GLOBE_CACHE_SECONDS (§6.2).
  let cache: CachedGlobe | null = null;

  // §6.1 POST /presence/attendance: 2 reads, at most 1 write; updatedAt untouched.
  r.post(
    '/api/v1/presence/attendance',
    h(async (_req, res) => {
      const uid = callerUid(res);
      const owner = await db.doc(`owners/${uid}`).get();
      if (!owner.exists) throw Errors.noProfile();
      const ref = db.doc(`profiles/${owner.get('profileId') as string}`);
      const snap = await ref.get();
      if (!snap.exists || snap.get('ownerUid') !== uid) throw Errors.noProfile();
      const today = dayIst(clock.now());
      if (snap.get('lastSeenDay') !== today) await ref.update({ lastSeenDay: today });
      res.status(200).json({ result: 'ATTENDANCE_MARKED', day: today });
    }),
  );

  // §6.2 GET /presence/globe: the snapshot as stored, builtAt as ISO, gzip.
  r.get(
    '/api/v1/presence/globe',
    h(async (req, res) => {
      const nowMs = clock.now().getTime();
      if (!cache || nowMs - cache.at >= GLOBE_CACHE_SECONDS * 1000) {
        const snap = await db.doc('presenceSnapshot/current').get();
        if (!snap.exists) throw new ApiError(503, 'GLOBE_NOT_READY', 'The globe has not been built yet');
        const data = snap.data() ?? {};
        const json = JSON.stringify({ ...data, builtAt: toIso(data.builtAt) });
        cache = { at: nowMs, json, gzip: gzipSync(json) };
      }
      res.setHeader('Content-Type', 'application/json; charset=utf-8');
      res.setHeader('Cache-Control', 'private, max-age=60');
      res.setHeader('Vary', 'Accept-Encoding');
      if (/\bgzip\b/.test(req.header('accept-encoding') ?? '')) {
        res.setHeader('Content-Encoding', 'gzip');
        res.status(200).send(cache.gzip);
      } else {
        res.status(200).send(cache.json);
      }
    }),
  );

  return r;
}
