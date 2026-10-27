import { readFileSync } from 'fs';
import { join } from 'path';
import type { DocumentReference, Firestore } from 'firebase-admin/firestore';
import { buildGroupGlobe } from '../../src/sangat/globe';
import type { GoalDoc, GroupDoc } from '../../src/sangat/model';

/** The emulator serves every query without an index, so a missing composite
 *  index only shows in production, as 500 INTERNAL. The admin dashboard died
 *  that way on 2026-10-10: its "Sangat paath today" is a sum() over
 *  contributions filtered by day and retracted, and Firestore needs the summed
 *  field in the index with the filters. Each query here is one the code runs
 *  that needs a composite index; the index has to be declared. */
type IndexField = { fieldPath: string; order?: 'ASCENDING' | 'DESCENDING'; arrayConfig?: 'CONTAINS' };
type Index = { collectionGroup: string; queryScope: 'COLLECTION' | 'COLLECTION_GROUP'; fields: IndexField[] };
const indexes: Index[] = JSON.parse(readFileSync(join(__dirname, '../../../firestore.indexes.json'), 'utf8')).indexes;
const has = (group: string, fields: string[]) =>
  indexes.some((i) => i.collectionGroup === group && i.fields.map((f) => f.fieldPath).join(',') === fields.join(','));

describe('composite indexes the queries need', () => {
  it('admin dashboard: sum(countedCount) of contributions where day == and retracted ==', () => {
    expect(has('contributions', ['day', 'retracted', 'countedCount'])).toBe(true);
  });
  // src/quiz/boards.ts: buildBoard's top twenty and placeOf's count (14-quiz QZ28).
  it('quiz board: quizScores where boardId == order by score desc, reachedAt', () => {
    expect(has('quizScores', ['boardId', 'score', 'reachedAt'])).toBe(true);
  });
  it('quiz place: count of quizScores where boardId == and score >', () => {
    expect(has('quizScores', ['boardId', 'score'])).toBe(true);
  });
});

// --- Queries recorded from the code itself -----------------------------------
//
// A list of index names in this file would pass for ever while the code moved
// on. Instead the group's globe is built against a fake that records every
// query it runs, and each recorded query is checked against the declared
// indexes the way Firestore would serve it.

interface RecordedQuery {
  collectionGroup: string;
  scope: 'COLLECTION' | 'COLLECTION_GROUP';
  equals: string[];
  arrayContains: string[];
  /** Range filters and orderBy, in order, with their direction. */
  ordered: Array<{ field: string; dir: 'ASCENDING' | 'DESCENDING' }>;
}

class FakeQuery {
  constructor(
    private readonly log: RecordedQuery[],
    private readonly path: string,
    private readonly q: RecordedQuery,
    private readonly countValue: number,
  ) {}
  private with(next: Partial<RecordedQuery>): FakeQuery {
    return new FakeQuery(this.log, this.path, { ...this.q, ...next }, this.countValue);
  }
  where(field: string, op: string, _value: unknown): FakeQuery {
    if (op === '==') return this.with({ equals: [...this.q.equals, field] });
    if (op === 'array-contains') return this.with({ arrayContains: [...this.q.arrayContains, field] });
    if (this.q.ordered.some((o) => o.field === field)) return this;
    return this.with({ ordered: [...this.q.ordered, { field, dir: 'ASCENDING' }] });
  }
  orderBy(field: string, dir: 'asc' | 'desc' = 'asc'): FakeQuery {
    const o = { field, dir: dir === 'desc' ? ('DESCENDING' as const) : ('ASCENDING' as const) };
    const i = this.q.ordered.findIndex((x) => x.field === field);
    return this.with({ ordered: i >= 0 ? this.q.ordered.map((x, j) => (j === i ? o : x)) : [...this.q.ordered, o] });
  }
  limit(): FakeQuery {
    return this;
  }
  select(): FakeQuery {
    return this;
  }
  count() {
    return { get: async () => (this.log.push(this.q), { data: () => ({ count: this.countValue }) }) };
  }
  async get() {
    this.log.push(this.q);
    return { docs: [], empty: true, size: 0 };
  }
  doc(id: string) {
    return fakeDoc(this.log, `${this.path}/${id}`, this.countValue);
  }
}

function fakeQuery(log: RecordedQuery[], path: string, countValue: number): FakeQuery {
  const group = path.split('/').pop() as string;
  return new FakeQuery(log, path, { collectionGroup: group, scope: 'COLLECTION', equals: [], arrayContains: [], ordered: [] }, countValue);
}

function fakeDoc(log: RecordedQuery[], path: string, countValue: number) {
  return { id: path.split('/').pop() as string, path, collection: (name: string) => fakeQuery(log, `${path}/${name}`, countValue) };
}

function fakeDb(log: RecordedQuery[], countValue = 1) {
  return { collection: (path: string) => fakeQuery(log, path, countValue), doc: (path: string) => fakeDoc(log, path, countValue) };
}

/** Does this declared index serve the query: the equality and array fields first (any order), then the ordered fields, in order and direction. */
function serves(index: Index, q: RecordedQuery): boolean {
  if (index.collectionGroup !== q.collectionGroup || index.queryScope !== q.scope) return false;
  const head = [...q.equals, ...q.arrayContains];
  if (index.fields.length !== head.length + q.ordered.length) return false;
  const first = index.fields.slice(0, head.length);
  for (const f of first) {
    if (q.arrayContains.includes(f.fieldPath)) {
      if (f.arrayConfig !== 'CONTAINS') return false;
    } else if (!q.equals.includes(f.fieldPath) || f.arrayConfig) return false;
  }
  if (new Set(first.map((f) => f.fieldPath)).size !== head.length) return false;
  return q.ordered.every((o, i) => {
    const f = index.fields[head.length + i];
    return f.fieldPath === o.field && f.order === o.dir;
  });
}

/** A query on one field (or none) is served by Firestore's automatic single-field indexes. */
function needsComposite(q: RecordedQuery): boolean {
  return new Set([...q.equals, ...q.arrayContains, ...q.ordered.map((o) => o.field)]).size > 1;
}

const goal: { id: string; doc: GoalDoc } = {
  id: 'g0001',
  doc: { type: 'BANI', baniId: 'JAPJ', simranMinutes: null, target: 10, startDay: '2026-10-01', endDay: '2026-10-31', status: 'ACTIVE' } as GoalDoc,
};
const group = (kind: GroupDoc['kind']) => ({ kind, status: 'ACTIVE', currentGoalId: 'g0001', memberCount: 5 }) as GroupDoc;
const now = new Date('2026-10-17T06:00:00Z');

async function queriesOf(kind: GroupDoc['kind']): Promise<RecordedQuery[]> {
  const log: RecordedQuery[] = [];
  const db = fakeDb(log);
  const groupRef = db.doc('groups/grp');
  await buildGroupGlobe(db as unknown as Firestore, groupRef as unknown as DocumentReference, group(kind), goal, false, now);
  return log;
}

function uncovered(log: RecordedQuery[]): RecordedQuery[] {
  return log.filter((q) => needsComposite(q) && !indexes.some((i) => serves(i, q)));
}

describe("the group's globe (08-sangat §6.4a, §6.6): every query it runs has its index", () => {
  it('built-in: per-city counts, today per city, today overall, and the arrivals', async () => {
    const log = await queriesOf('BUILT_IN');
    const shapes = new Set(log.map((q) => JSON.stringify([q.collectionGroup, q.equals, q.arrayContains, q.ordered])));
    expect(shapes).toEqual(
      new Set([
        JSON.stringify(['members', ['status', 'cityId'], [], []]),
        JSON.stringify(['members', ['status', 'cityId', 'lastAddDay'], [], []]),
        JSON.stringify(['members', ['status', 'lastAddDay'], [], []]),
        JSON.stringify(['contributions', [], ['groupIds'], [{ field: 'createdAt', dir: 'DESCENDING' }]]),
      ]),
    );
    expect(uncovered(log)).toEqual([]);
  });

  it('custom: the active member rows (single field) and the arrivals', async () => {
    const log = await queriesOf('CUSTOM');
    expect(log.map((q) => q.collectionGroup).sort()).toEqual(['contributions', 'members']);
    expect(uncovered(log)).toEqual([]);
  });

  it('the checker itself fails on a query with no index (a guard nobody has seen fail is not a guard)', () => {
    const q: RecordedQuery = { collectionGroup: 'members', scope: 'COLLECTION', equals: ['status', 'name'], arrayContains: [], ordered: [] };
    expect(uncovered([q])).toEqual([q]);
    const wrongDir: RecordedQuery = {
      collectionGroup: 'contributions',
      scope: 'COLLECTION',
      equals: [],
      arrayContains: ['groupIds'],
      ordered: [{ field: 'createdAt', dir: 'ASCENDING' }],
    };
    expect(uncovered([wrongDir])).toEqual([wrongDir]);
  });
});
