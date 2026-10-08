// Every call goes to /api/v1/admin with the admin's Google ID token. The
// server decides who is admin (11-admin §0.2, AC3); this file never does.
import { getAuth } from 'firebase/auth';

const BASE = (import.meta.env.VITE_API_BASE as string | undefined) ?? 'https://hazri-dfcc1.web.app/api/v1/admin';

export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly fields: Record<string, string> = {},
  ) {
    super(message);
  }
}

export async function api<T = Record<string, unknown>>(method: string, path: string, body?: unknown): Promise<T> {
  const user = getAuth().currentUser;
  if (!user) throw new ApiError(401, 'UNAUTHENTICATED', 'Sign in first');
  const token = await user.getIdToken();
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const json = (await res.json().catch(() => ({}))) as Record<string, unknown>;
  if (!res.ok) {
    const e = (json.error ?? {}) as { code?: string; message?: string; fields?: Record<string, string> };
    throw new ApiError(res.status, e.code ?? `HTTP_${res.status}`, e.message ?? res.statusText, e.fields ?? {});
  }
  return json as T;
}

export interface Goal {
  goalId: string;
  type: 'BANI' | 'SIMRAN';
  baniId: string | null;
  simranMinutes: number | null;
  target: number;
  startDay: string;
  endDay: string;
  status: string;
  total: number;
  pct: number;
}

export interface Template {
  type: 'BANI' | 'SIMRAN';
  baniId: string | null;
  simranMinutes: number | null;
  target: number;
  lengthDays: number;
}

export interface Group {
  groupId: string;
  kind: 'BUILT_IN' | 'CUSTOM';
  name: string | null;
  names: { en: string; pa: string; hi: string } | null;
  status: 'ACTIVE' | 'INACTIVE' | 'DISABLED';
  creatorKey: string | null;
  memberCount: number;
  goalTemplate: Template | null;
  currentGoal: Goal | null;
}

export interface Bani {
  id: string;
  nameEn: string;
}
