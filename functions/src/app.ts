// The Express app behind the `api` Function. Routes carry the full /api/v1
// prefix, because Hosting forwards the full path (01-accounts §3.1).
import cors from 'cors';
import express, { NextFunction, Request, Response } from 'express';
import { logger } from 'firebase-functions';
import { requireAdmin, requireUser } from './auth';
import { ADMIN_ORIGINS } from './config';
import type { Deps } from './deps';
import { ApiError, Errors } from './errors';
import { adminRouter } from './routes/admin';
import { backupRouter } from './routes/backup';
import { miscRouter } from './routes/misc';
import { presenceRouter } from './routes/presence';
import { profileRouter } from './routes/profile';
import { sangatRouter } from './routes/sangat';
import { tokensRouter } from './routes/tokens';

export function createApp(deps: Deps): express.Express {
  const app = express();
  app.disable('x-powered-by');
  app.set('etag', false);

  // The admin website is a different origin (hazri-admin.web.app) calling
  // https://hazri-dfcc1.web.app/api/v1/admin/*.
  app.use('/api/v1/admin', cors({ origin: ADMIN_ORIGINS, methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE'], maxAge: 3600 }));

  app.use(express.json({ limit: '5mb' }));

  // Every endpoint needs the install's (or, for /admin, the admin's) ID token.
  app.use('/api/v1', requireUser(deps.verifier));
  app.use('/api/v1/admin', requireAdmin());

  app.use(profileRouter(deps));
  app.use(tokensRouter(deps));
  app.use(presenceRouter(deps));
  app.use(sangatRouter(deps));
  app.use(backupRouter(deps));
  app.use(miscRouter(deps));
  app.use(adminRouter(deps));

  app.use((_req: Request, _res: Response, next: NextFunction) => next(Errors.notFound('No such endpoint')));

  // The error body of §6.0; unexpected exceptions are logged and answered 500 INTERNAL.
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  app.use((err: unknown, req: Request, res: Response, _next: NextFunction) => {
    let e: ApiError;
    if (err instanceof ApiError) e = err;
    else if (isBodyParseError(err)) e = Errors.invalidRequest('Invalid request');
    else {
      logger.error('api: unexpected exception', { path: req.path, method: req.method, error: errorText(err) });
      e = Errors.internal();
    }
    res.status(e.status).json(e.body());
  });

  return app;
}

function isBodyParseError(err: unknown): boolean {
  const e = err as { type?: string; status?: number } | null;
  return !!e && (e.type === 'entity.parse.failed' || e.type === 'entity.too.large' || e.status === 400);
}

function errorText(err: unknown): string {
  return err instanceof Error ? `${err.name}: ${err.message}\n${err.stack ?? ''}` : String(err);
}
