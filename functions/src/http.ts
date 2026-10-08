// Small helpers shared by the routers.
import type { NextFunction, Request, RequestHandler, Response } from 'express';
import { asLocale, Locale } from './notifications/render';

/** Wraps an async handler so a rejection reaches the error middleware. */
export function h(fn: (req: Request, res: Response) => Promise<void>): RequestHandler {
  return (req: Request, res: Response, next: NextFunction) => {
    fn(req, res).catch(next);
  };
}

/** The JSON body as a plain object; anything else reads as `{}` (unknown fields are ignored, §5). */
export function bodyOf(req: Request): Record<string, unknown> {
  const b: unknown = req.body;
  return b !== null && typeof b === 'object' && !Array.isArray(b) ? (b as Record<string, unknown>) : {};
}

/** The reader's language: `locale` in the body, else Accept-Language, else en. */
export function localeOf(req: Request): Locale {
  const fromBody = bodyOf(req).locale;
  if (fromBody === 'pa' || fromBody === 'hi' || fromBody === 'en') return fromBody;
  const al = (req.header('accept-language') ?? '').toLowerCase();
  return asLocale(al.slice(0, 2));
}

export function param(req: Request, name: string): string {
  const v = req.params[name];
  return typeof v === 'string' ? v : '';
}

export function queryString(req: Request, name: string): string | null {
  const v = req.query[name];
  return typeof v === 'string' && v !== '' ? v : null;
}
