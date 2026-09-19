# Vichar content (the library)

The Vichar library — articles, Gurdwaras, the Guru Sahibans, the banis and
the Sikh days — is **not in the app**. The app ships the shell; every word
comes from Firestore and is corrected in one place. That is deliberate and it
is the same rule CLAUDE.md rule 3 applies to Gurbani: nothing about Sikhi is
written in Dart, generated, or paraphrased into the build.

It follows that a fresh install shows an empty library until entries are
published, and the screen says so rather than pretending.

## Where entries live

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
| `body` | string | The entry itself. Blank lines separate paragraphs. |
| `minutes` | number | Reading time **as the source states it**. Not computed: a word count is a poor guess in Gurmukhi and worse in mixed script. Omit it and no time is shown. |
| `place` | string | A city or region, for a Gurdwara. Shown under the title. |
| `facts` | map of string to string | The labelled rows on design 45 — Where, Marks, Open, Langar. The source decides what appears and in what order. |

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
