import { readFileSync } from 'fs';
import { join } from 'path';

/** The emulator serves every query without an index, so a missing composite
 *  index only shows in production, as 500 INTERNAL. The admin dashboard died
 *  that way on 2026-10-10: its "Sangat paath today" is a sum() over
 *  contributions filtered by day and retracted, and Firestore needs the summed
 *  field in the index with the filters. Each query here is one the code runs
 *  that needs a composite index; the index has to be declared. */
type Index = { collectionGroup: string; fields: { fieldPath: string }[] };
const indexes: Index[] = JSON.parse(readFileSync(join(__dirname, '../../../firestore.indexes.json'), 'utf8')).indexes;
const has = (group: string, fields: string[]) =>
  indexes.some((i) => i.collectionGroup === group && i.fields.map((f) => f.fieldPath).join(',') === fields.join(','));

describe('composite indexes the queries need', () => {
  it('admin dashboard: sum(countedCount) of contributions where day == and retracted ==', () => {
    expect(has('contributions', ['day', 'retracted', 'countedCount'])).toBe(true);
  });
});
