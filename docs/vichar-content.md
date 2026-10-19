# Vichar content (the library)

The Vichar library — articles, Gurdwaras, the Guru Sahibans, the banis and
the Sikh days — is **not in the app**. The app ships the shell; every word
comes from Firestore and is corrected in one place. That is deliberate and it
is the same rule CLAUDE.md rule 3 applies to Gurbani: nothing about Sikhi is
written in Dart, generated, or paraphrased into the build.

It follows that the library needs a connection the first time it is opened;
after that the last copy is kept on the phone (below). With nothing published
it is empty and says so rather than pretending.

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
| `layout` | string | `calendar`, `photo` or `timeline` (see Layouts below). Anything else, or none, is the plain reader of designs 44 and 45. |
| `label` | string | The kind of day in words, e.g. `Prakash Purab`: the eyebrow over the title and the first chip. |
| `image` | string | A Wikimedia Commons photo, `https://commons.wikimedia.org/…` or `upload.wikimedia.org` only. Served, **not loaded by the app**: PRD §8 lists no photo host. |
| `imageCaption` | string | What the photo shows. The photo-led layout writes it over the picture it draws, so the place is named even though its photo is not shown. |

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

## Layouts (owner, 2026-10-19)

Chosen from four drawn options: **A for Gurpurabs, B for gurdwaras, C for
multi-day history.** The website's build picks one for every story page
(`layout_of` in `tools/site/articles.py`), and an article's own `"layout"` in
its JSON wins:

| Layout | For | What it shows | Design |
|---|---|---|---|
| `calendar` (A) | Every Gurpurab: Prakash, Gurgaddi, Joti Jot (30 pages) | The date as a tile, the countdown ("In 8 days"), title and opening in a navy card; headings with a kesri bar; the facts; the next two days in the calendar; Share | 107 |
| `photo` (B) | A story listed under Gurdwaras that has a photo on the website (19) | A drawn Gurdwara at dusk with the place's name over it, kind and topics as chips, the story, previous and next in the calendar | 108 |
| `timeline` (C) | Everything else: Shaheedi, the days of the Panth, Sangrand, Masya, Puranmashi (53) | A navy band with every date the story is in the calendar (the next in kesri), the opening, then each `## ` section as a step on a line, the first in kesri | 109 |

The same text appears in every layout; only the frame differs. The photo-led
page draws its picture instead of loading the Commons photo, because the app
reaches nothing PRD §8 does not list; adding a photo host would be a change to
§8 and to the privacy screen first.

## On the phone (owner, 2026-10-19)

The library is fetched in one call, `GET /api/v1/vichar/entries`, the first
time it is opened in a session — never at app start — and held in memory for
the rest of the session. Each answer is also saved on the phone, as
`vichar-entries.json` in the app's support directory
(`lib/features/library/data/library_store.dart`):

- **With a saved copy**, the library opens on it at once, with or without a
  connection, and fetches a fresh one behind it. When the fresh one differs,
  it replaces the saved copy and the screen shows it; when the fetch fails,
  the saved copy stays.
- **With none** (the first visit after installing), the screen waits for the
  fetch, and with no connection says the library is empty and why.

The saved copy is published text, not the person's own, so it is not in
`user.db` and not in the backup; a restored phone fetches it again. A new or
corrected entry reaches a phone the next time the library is opened in a new
session with a connection, after the server's own 10-minute cache.

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
