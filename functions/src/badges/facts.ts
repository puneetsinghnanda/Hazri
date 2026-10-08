// The two Sangat badge facts (12-badges.md §5, ARCHITECTURE §5.8): arrays of
// keys, not counters, so a retried write adds nothing twice; each stops
// growing at its cap.

function asStrings(v: unknown): string[] {
  return Array.isArray(v) ? v.filter((x): x is string => typeof x === 'string') : [];
}

/** Union of two fact arrays, existing entries first, never past `cap`. */
export function mergeFactArrays(existing: unknown, incoming: unknown, cap: number): string[] {
  const out: string[] = [];
  for (const k of [...asStrings(existing), ...asStrings(incoming)]) {
    if (out.length >= cap) break;
    if (!out.includes(k)) out.push(k);
  }
  return out;
}

/** Whether adding `key` to a fact array would change it (not present and under the cap). */
export function factWouldGrow(existing: unknown, key: string, cap: number): boolean {
  const arr = asStrings(existing);
  return !arr.includes(key) && arr.length < cap;
}

/** GET /badges/sangat body: array lengths, 0 when absent (§6.5). */
export function factCounts(doc: { goalsReached?: unknown; joins?: unknown } | undefined): {
  goalsReached: number;
  joins: number;
} {
  return { goalsReached: asStrings(doc?.goalsReached).length, joins: asStrings(doc?.joins).length };
}
