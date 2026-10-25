# Hazri Saakhis: handoff bundle

Four finished saakhis for the Hazri app, ready to be built into the app in
another session. Made 2026-10-25.

The words, rules and design already live in the repository
`puneetsinghnanda/Hazri` on branch **`claude/pensive-hawking-k87ese`**. This
bundle adds what git deliberately does not hold, which is the images and the
narration, plus a playable preview of each saakhi.

## What is in here

| Folder | Holds |
|---|---|
| `previews/` | One self-contained HTML file per saakhi: images and English narration embedded. Open on a phone and tap **Listen**. This is the approved design. |
| `content/` | The four saakhi files (`<id>.json`): every page in English and Punjabi, the lesson line and family question, Gurbani by reference, the page timings, and image notes. Same as `content/source/saakhi/` in the repo. |
| `images/<id>/` | `cover`, `p1` … `p8` for each saakhi (WebP, portrait 9:16, as supplied by the owner). |
| `audio/<id>.en.mp3` | The English narration for each saakhi, as supplied by the owner (text to speech). |
| `design/` | `reader.template.html` (the approved reader), `build_saakhi_preview.py` (builds a preview from a saakhi file, its images and audio), and `menu-and-today-options.html` (the options the owner chose from on 2026-10-25). |
| `docs/13-saakhi.md` | The feature specification: rules SK1–SK14, scenarios, what is open. Same as `docs/features/13-saakhi.md` in the repo. |

## The four saakhis (all final, 2026-10-20 to 2026-10-25)

| id | Title | Pages | Narration | Gurbani on the lesson page |
|---|---|---|---|---|
| `bhai-lalo-malik-bhago` | Bhai Lalo and Malik Bhago · ਭਾਈ ਲਾਲੋ ਤੇ ਮਲਿਕ ਭਾਗੋ | 7 + lesson | 2:12, pages at 0:00 0:15 0:27 0:40 0:58 1:15 1:39 1:52 | Ang 105 pankti (transcribed from a screenshot; to be checked) |
| `anand-bhaya-meri-maaye` | Anand Bhaya Meri Maaye · ਅਨੰਦੁ ਭਇਆ ਮੇਰੀ ਮਾਏ | 7 + lesson | 1:49, pages at 0:00 0:20 0:35 0:42 0:56 1:10 1:20 1:42 | Anand Sahib line, Ang 917, read from `content/source/anand-sahib.json` |
| `why-was-the-hut-broken` | Why Was the Hut Broken? · ਕੁੱਲੀ ਕਿਉਂ ਢਾਹੀ ਗਈ? | 7 + lesson | 2:28, pages at 0:00 0:16 0:38 1:00 1:24 1:42 1:56 2:17 | none |
| `the-saint-soldier` | The Saint-Soldier · ਸੰਤ ਸਿਪਾਹੀ | 7 + lesson | 2:32, pages at 0:00 0:18 0:37 0:57 1:20 1:43 2:08 2:25 | pending: ਸੂਰਾ ਸੋ ਪਹਿਚਾਨੀਐ … needs its Ang and meaning |

## Decisions the owner has made (do not re-open)

- **The Guru's face is never shown.** A Guru may be drawn as a figure, AI art
  included, with only light where the face would be (SK2, CLAUDE.md rule 3,
  2026-10-21). All four saakhis' images are accepted as they are.
- **Gurbani comes from a named source file**, never typed into Dart, never
  voiced by text to speech (SK3).
- **The lesson page is design D for every saakhi**: one big line, a "Talk
  about it together" question, the Gurbani row (closed) if there is a shabad,
  Share and Read again (SK7).
- **Nothing about a saakhi is counted**: no Diary row, goal item or badge, and
  no "Reflect in Diary" (SK7).
- **Share** is a labelled button at the bottom of every page; it makes a
  1080 x 1920 image with the Hazri band and the link (SK10).
- **Narration turns the pages** at the page times; the lesson page stays until
  the audio ends; the Gurbani row opens itself when the meaning is read (SK8).
- **On Today: option 1A**, a "Saakhis" row of tall cover cards scrolling
  sideways, after the Nitnem button and before ਅੱਜ ਦਾ ਵਿਚਾਰ, with "See all"
  to the library (SK11).
- **The menu: option A**, a left drawer instead of today's bottom sheet: the
  navy header (name, city, badges), then Today, Saakhis (with a count),
  Library, Badges, Notifications, Settings, Privacy and data, About and
  credits, Help (SK11).

## What is still open

From `docs/13-saakhi.md` §4: the Punjabi narration for all four (the owner is
recording it), the two Gurbani checks (the Ang 105 pankti against a named
source; a person's voice for the Anand Sahib line), the Saint-Soldier pankti's
Ang and meaning, and the hut saakhi's painted cover title
(ਝੌਂਪੜੀ ਕਿਉਂ ਟੁੱਟੀ ਸੀ?) differing from the chosen one.

## Prompt to paste into the new session

> I am attaching `saakhi-handoff`, four finished saakhis for the Hazri app.
> Work on branch `claude/pensive-hawking-k87ese` of `puneetsinghnanda/Hazri`.
> Read `saakhi-handoff/README.md` first, then `docs/features/13-saakhi.md`
> and `CLAUDE.md`. Open the files in `previews/` to see the approved design.
> The decisions listed in the README are final. Next: build the Saakhi
> feature into the app: the content pipeline for `content/source/saakhi/*.json`
> (tables in `docs/ARCHITECTURE.md`), the images and audio as app assets, the
> library screen, the reader with narration, Share, the Today row (option
> 1A) and the left drawer menu (option A). Draw the new screens in the design
> set first (`tools/design/build_phase2.py`) for my approval.
