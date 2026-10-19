# Vichar content (the library)

The Vichar library — articles, Gurdwaras, the Guru Sahibans, the banis and
the Sikh days — is **not in the app**. The app ships the shell; every word
comes from Firestore and is corrected in one place. That is deliberate and it
is the same rule CLAUDE.md rule 3 applies to Gurbani: nothing about Sikhi is
written in Dart, generated, or paraphrased into the build.

It follows that the library needs a connection, and that with nothing
published it is empty and says so rather than pretending.

## The four chips (owner, 2026-10-19)

The screen has four chips and no others: **Sikh days**, **Gurdwaras**, **Guru
Sahibans**, **Banis**, in that order. Sikh days is selected when the screen
opens and lists **every** entry, because every story page is a day in the
calendar. Each of the others lists the entries tagged with it (`tags`), or,
for an entry with no tags, whose `kind` it is. There is no "All" chip and no
"Articles" chip; `article` survives only as the label of an entry that names
no topic. Within a chip, the days still to come are listed first, soonest
first, then the days already past, then anything without a date, by title.
Designs 43 and 46 show the older six chips; this file wins.

## Where entries come from

**The website's story pages** (since 2026-10-19). `python3 tools/site/build.py`
writes the 102 pages of `hazri.me/gurpurab` into
`functions/src/vichar-entries.json` as well as into `public/`, and the `api`
Function bundles that file, so the app and the website read the same text from
the same source (`tools/site/articles/*.json`, topics in
`tools/site/categories.json`, see `docs/site-stories.md`) and serving them
costs no Firestore read. A change reaches phones after
`firebase deploy --only functions`; the website's after
`firebase deploy --only hosting:public`.

**Firestore**, as before, for anything else, and for a quick correction: an
entry stored under the same id as a story page (its slug) replaces that page
in the app until the next deploy, with no deploy needed.

```
content/vichar/entries/{id}
```

`firestore.rules` already covers this path: any signed-in phone may read it,
no phone may write it. Entries are added in the Firebase console, or by
whatever the website uses in Phase 3.

## The document

| Field | Type | Notes |
|---|---|---|
| `title` | string | Required. An entry with no title is skipped rather than shown blank. |
| `kind` | string | `article`, `gurdwara`, `guru`, `bani` or `day`. Anything else falls back to `article`. |
| `summary` | string | One or two sentences. Shown under the title in the list and at the top of the entry. |
| `body` | string | The entry itself. Blank lines separate paragraphs; a paragraph that starts `## ` is a heading. |
| `minutes` | number | Reading time **as the source states it**. Not computed: a word count is a poor guess in Gurmukhi and worse in mixed script. Omit it and no time is shown. The story pages state it from their English word count at 200 a minute. |
| `place` | string | A city or region, for a Gurdwara. Shown under the title. |
| `facts` | list of `{label, value}`, or a map of string to string | The labelled rows on design 45 — Where, Marks, Open, Langar. The source decides what appears and in what order (a map's order is not kept by Firestore; a list's is). |
| `tags` | list of string | The chips it is listed under: any of `day`, `gurdwara`, `guru`, `bani`. Omit it and the entry is listed under its `kind`. Every entry is listed under Sikh days regardless. |
| `dates` | list of string | The calendar days it tells the story of, `YYYY-MM-DD`. Used to put the coming days first. |

Example:

```json
{
  "title": "Gurdwara Bangla Sahib, Delhi",
  "kind": "gurdwara",
  "place": "New Delhi, India",
  "minutes": 4,
  "summary": "…",
  "facts": {
    "Where": "Baba Kharak Singh Marg, New Delhi",
    "Marks": "The stay of Guru Har Krishan Sahib Ji",
    "Open": "All day, every day",
    "Langar": "Served continuously"
  },
  "body": "First paragraph.\n\nSecond paragraph."
}
```

## Searching

Search is done on the phone, over the entries already fetched: title, summary
and place, case-folded, substring. There is no ranking, because there are not
enough entries for ranking to beat "it is in there somewhere". The list is
fetched once per session and held, so typing in the search box costs nothing.

## Translation

An entry is stored in one language today. Entries in `pa`, `hi` and `en`
would be three documents, or one document with per-language fields; the app
does not choose for the website, and this is the open question to settle when
the website is built.
