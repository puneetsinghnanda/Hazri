#!/usr/bin/env node
// Writes functions/src/cities.json (id, country, state) from the app's city
// list, tools/content_pipeline/cities.json, which this script only READS.
//
// 07-simran.md §5.1 says the content pipeline writes this file once every
// city carries an ISO 3166-2 `state`. Until the pipeline does, this script
// stands in for it. A city with no `state` yet is written with `state: null`
// and the globe snapshot files it under `<country>-XX` (src/presence/snapshot.ts).
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const src = join(here, '..', '..', 'tools', 'content_pipeline', 'cities.json');
const out = join(here, '..', 'src', 'cities.json');

const cities = JSON.parse(readFileSync(src, 'utf8'));
const rows = cities.map((c) => ({ id: c.id, country: c.cc, state: c.state ?? null }));
writeFileSync(out, JSON.stringify(rows, null, 1) + '\n');
const missing = rows.filter((r) => r.state === null).length;
console.log(`gen-cities: wrote ${rows.length} cities to ${out}; ${missing} without a state`);
