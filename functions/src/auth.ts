// Authentication middleware (01-accounts.md §6.0) and the admin check
// (11-admin.md AC3).
import type { NextFunction, Request, Response } from 'express';
import { ADMIN_EMAIL } from './config';
import type { TokenVerifier, VerifiedToken } from './deps';
import { ApiError, Errors } from './errors';

export interface AuthedLocals {
  uid: string;
  token: VerifiedToken;
}

function bearer(req: Request): string | null {
  const h = req.header('authorization') ?? '';
  const m = /^Bearer\s+(.+)$/i.exec(h);
  return m ? m[1].trim() : null;
}

/** Missing or invalid token → 401 UNAUTHENTICATED; else res.locals.uid = decoded.uid. */
export function requireUser(verifier: TokenVerifier) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    const idToken = bearer(req);
    if (!idToken) return next(Errors.unauthenticated());
    let decoded: VerifiedToken;
    try {
      decoded = await verifier.verifyIdToken(idToken);
    } catch {
      return next(Errors.unauthenticated());
    }
    if (!decoded || typeof decoded.uid !== 'string' || decoded.uid === '') return next(Errors.unauthenticated());
    res.locals.uid = decoded.uid;
    res.locals.token = decoded;
    next();
  };
}

/** AC3: valid token, provider google.com, email verified, email == ADMIN_EMAIL; otherwise 403 NOT_ADMIN. */
export function isAdminToken(t: VerifiedToken): boolean {
  return (
    t.firebase?.sign_in_provider === 'google.com' &&
    t.email_verified === true &&
    typeof t.email === 'string' &&
    t.email.toLowerCase() === ADMIN_EMAIL.toLowerCase()
  );
}

export function requireAdmin() {
  return (_req: Request, res: Response, next: NextFunction): void => {
    const token = res.locals.token as VerifiedToken | undefined;
    if (!token || !isAdminToken(token)) {
      return next(new ApiError(403, 'NOT_ADMIN', 'This account cannot use Hazri admin.'));
    }
    next();
  };
}

export function callerUid(res: Response): string {
  return res.locals.uid as string;
}
