# 13 · Saakhis

Written 2026-10-20 with the owner, from the first saakhi (Bhai Lalo and Malik
Bhago) designed and approved over 2026-10-19 and 2026-10-20. Saakhis were on
the 2026-09-22 list of things removed from the roadmap; the owner brought them
back on 2026-10-19 (PRD §2.2, §4.20).

The approved design is `design/saakhi/reader.template.html`, built into a
playable preview by `tools/design/build_saakhi_preview.py` (§7). The first
saakhi's words are `content/source/saakhi/bhai-lalo-malik-bhago.json`.

---

## 1. What a saakhi is

A story from Sikh history, told in a few illustrated pages, read or listened
to by a parent with a child. It is the competitor feature done properly: in
the reader's language, with the source of every line of Gurbani named, and
with the Guru's face never shown.

## 2. Rules

**SK1. Every saakhi is on the phone.** Text, images and narration are bundled
like the banis. Reading or listening needs no network, no profile and no
group (CLAUDE.md rule 4).

**SK2. The Guru's face is never shown.** The Guru may be drawn as a figure,
but where the face would be there is only a warm golden light, and the other
people in the scene react to it (owner, 2026-10-21, replacing "never drawn" of
2026-10-19). An image in which any feature of the Guru's face can be seen does
not ship. AI art is allowed, the Guru's figure included, on that condition
(CLAUDE.md rule 3).

**SK3. Gurbani comes from a named source.** A saakhi may carry one shabad; most
will not. Its Gurmukhi and its meaning come from the source file, with Ang and
source shown, and are never typed into Dart. A meaning that does not exist in
a language is not shown in that language: the Punjabi lesson page shows the
pankti without a meaning. The pankti is never voiced by text to speech; it is
silent until a person records it.

**SK4. The story is retold, the Guru's words are not.** The owner supplies the
account; it is retold simply for children with the core meaning unchanged.
The Guru's own words stay exactly as in the account and are marked `<q>` in the
source file, so the reader shows them in a warm tint. The website the account
came from is recorded privately, not shown in the app.

**SK5. The owner reviews every saakhi** in every language before it ships.

**SK6. Pages.** A cover, then story pages, then one lesson page. Each story
page is one full-bleed portrait image (9:16, at least 1080 x 1920; the subject
in the middle, the bottom 40% calm for the text) with the page number, a short
page title and 40 to 70 words of text over a dark fade. Seven story pages for
the first saakhi; the number may differ per saakhi.

**SK7. The lesson page is design D for every saakhi** (owner, 2026-10-20):
- ✦ and the page title, with a small play button;
- one big line of the lesson ("Honest bread is sweet like milk.");
- a "Talk about it together" card with one question for the family;
- if the saakhi has a shabad, a ੴ Gurbani · Ang row, closed, that opens to the
  pankti and its meaning;
- Share as the main button, Read again beside it.

Nothing on it is counted: a saakhi is not a Diary row, not a goal item and not
part of any badge. There is no "Reflect in Diary": the Diary has no note
(`09-diary.md` §9.8), and the owner chose not to add one.

**SK8. Narration** is one recording per language, with the time each page
starts. Playing turns the pages with the voice; the lesson page stays until
the audio ends. Tapping or swiping to a page while it plays moves the voice to
that page's start; pause resumes in place. When the voice reaches the meaning
of the pankti, the Gurbani row opens by itself so it can be read along. A
language with no recording shows its text and a disabled play button that
says the narration is coming.

**SK9. Languages.** Every string on these screens is in the ARB files in pa,
hi and en (CLAUDE.md rule 5). A saakhi's own text ships in the languages it
has; the first ships in English and Punjabi, with English narration first.

**SK9a. Punjabi first** (owner, 2026-10-27). A saakhi opens in Punjabi, text
and narration, in every app language, whenever it has Punjabi; English only
for one that does not. The language switch on the cover still changes it for
that reading. The library card says "Punjabi and English narration".

**SK8a. The bars at the top** are one per page after the cover, the lesson
last. Pages already passed are full, and so is the page being read, so the
lesson fills the last bar; while the narration is part-way through a page,
its bar shows how far (owner, 2026-10-27: the last bar never filled).

**SK10. Share** is a labelled button at the bottom of every story page and the
main button of the lesson page, never only an icon in the top bar. It makes a
1080 x 1920 image of the current page (or the cover, for the whole saakhi):
the picture, the saakhi's name, the page's text, and a band reading "Read and
listen to the full saakhi · Free in the Hazri app" with the link. It goes out
through Android's share sheet with a short message; the app itself sends
nothing (PRD §8).

**SK11. The library.** Saakhis are listed as cards: the cover, the Punjabi name
above the English, the page count, the narration languages and the length.
Two ways in (owner, 2026-10-25, from the options of that day):
- **On Today, option C** (owner, 2026-10-27, replacing option 1A's bare row
  of covers, which was the one part of Today not in a card): one card with
  "Saakhis" and "See all", then the day's saakhi large (its cover, "Today's
  saakhi", the Punjabi name above the English, the Punjabi subtitle, Listen
  and Read), then "More saakhis" and the others as small covers. The day's
  saakhi turns by date (days since 1970 modulo the number of saakhis), the
  same on every phone. It sits after the quiz card and before ਅੱਜ ਦਾ
  ਵਿਚਾਰ. "See all" opens the library. The options were drawn at
  <https://claude.ai/artifact/XHPjPXhGyvdjvZDD33BxGP>; it is design 113, which
  supersedes 110.
- **In the menu, option A:** the menu becomes a left drawer (no longer a
  bottom sheet) with today's navy header (name, city, badges), then one
  list: Today, Saakhis with a count, Library, Badges, then Notifications,
  Settings, Privacy and data, About and credits, Help. This changes PRD §3.2
  and design 37/99 (5C) when it is drawn and built.

**SK12. Favourite** is a heart on each story page, kept on the phone. It
marks the saakhi (`user.db` `saakhi_favourites`), and the library shows it.

**SK15. Built** (2026-10-25). The reader, the library (design 111), Share,
the Today card (design 113, option C since 2026-10-27; it was 110) and the
left drawer (design 112) are in the app. The Today card is shown in elder mode too (owner, 2026-10-27; until then it
stepped aside there with ਅੱਜ ਦਾ ਵਿਚਾਰ). The
share sheet offers Share (the picture, labelled just "Share", owner 2026-10-27) and Copy text; **Save** is left out until the
app has a way to write to the phone's gallery (a share to Files or Photos
does the same today).

**SK13. Audio masters are not in git**, like the banis' (`audio/README.md`).
The images join git as app assets when the feature is built.

## 3. Scenarios

**Listen from the cover.** Given the reader opens Bhai Lalo and Malik Bhago,
when they tap Listen, then page 1 shows at 0:00, page 2 at 0:15, 3 at 0:27, 4
at 0:40, 5 at 0:58, 6 at 1:15, 7 at 1:39, and the lesson at 1:52, which stays
until the audio ends at 2:12.

**Jump while listening.** Given narration is playing on page 3, when the
reader taps next, then page 4 shows and the voice starts from 0:40.

**Read along with the meaning.** Given narration is playing on the lesson
page, when it reaches 2:05, then the Gurbani row opens and its meaning is
highlighted.

**No recording yet.** Given the reader has chosen Punjabi, when they open a
story page, then the Punjabi text shows and the play button is disabled and
says the Punjabi narration is coming.

**Share a page.** Given the reader is on page 4, when they tap Share, then the
sheet previews page 4's image with its text and the Hazri band, and offers
Share, Save and Copy text.

**Failure: a face in an image.** Given an image in which any feature of the
Guru's face can be seen, then the saakhi does not ship until the image is
replaced.

**Failure: an unsourced pankti.** Given a pankti whose text has not been
checked against a named source, then the saakhi does not ship.

## 4. Open before each saakhi ships

Final so far (design, words and timings approved by the owner): *Bhai Lalo
and Malik Bhago* and *Anand Bhaya Meri Maaye*, both 2026-10-20. On 2026-10-21
the owner accepted both saakhis' images as they are (the Guru's figure with the
face in light, SK2) and closed the remaining items, except the Punjabi
narration. The two Gurbani checks stay listed because SK3 asks for them.
*The Saint-Soldier* and *Why Was the Hut Broken?* became final on
2026-10-25.

### Bhai Lalo and Malik Bhago

| # | Item | Default |
|---|---|---|
| SK-1 | Images: the Guru as a figure, meat on three pages, the cover's painted title | **Closed**: accepted by the owner, 2026-10-21; the reader draws no second title over a cover that has one |
| SK-2 | The Punjabi text is Claude's draft | **Closed**: accepted by the owner, 2026-10-21 |
| SK-3 | The Ang 105 pankti and its English were transcribed from a screenshot | **Closed** 2026-10-25: both match BaniDB (Ang 105, verses 4211-4213, shabad 306) word for word; recorded as `checked` in the saakhi file |
| SK-4 | Where Share's link leads | `hazri.me` today; a Play Store link or a per-saakhi page later |
| SK-5 | The recording ends while the voice is still speaking (2:12) | **Closed**: accepted by the owner, 2026-10-21 |
| SK-6 | The big lesson line and the family question are Claude's wording | Approved by the owner with design D |
| SK-7 | Punjabi narration | **Closed**: recorded by the owner, 2026-10-27; page timings placed by Claude, open under SK-23 |

### Anand Bhaya Meri Maaye

| # | Item | Default |
|---|---|---|
| SK-8 | Images: the Guru as a figure, the cover's teacher and painted title, the Khanda on page 1, the teacher's age on page 3 | **Closed**: accepted by the owner, 2026-10-21 |
| SK-9 | The Anand Sahib line on page 4 (about 0:43) must be a person's recording | **Open under SK3**: confirm before release |
| SK-14 | Punjabi narration | **Closed**: recorded by the owner, 2026-10-27, a person's voice, so the Anand Sahib line is read by a person in Punjabi (SK-9 stays open for the English) |
| SK-10 | The Punjabi text is Claude's draft, and the source's Punjabi meaning of the line opens "ਹੇ ਭਾਈ ਮਾਂ!" | **Closed**: accepted by the owner, 2026-10-21 |
| SK-11 | The recording may hold only one of the lesson page's two sentences (1:42 to 1:49) | **Closed**: accepted by the owner, 2026-10-21 |
| SK-12 | A second pankti the owner supplied is not used | **Closed**: the Anand Sahib line is the saakhi's Gurbani |
| SK-13 | The Guru is not named in the account | **Closed**: the text says Guru Ji |

### Why Was the Hut Broken?

| # | Item | Default |
|---|---|---|
| SK-19 | The cover's painted Punjabi title reads ਝੌਂਪੜੀ ਕਿਉਂ ਟੁੱਟੀ ਸੀ?; the chosen title is ਕੁੱਲੀ ਕਿਉਂ ਢਾਹੀ ਗਈ? | **Open**: a text-free cover, or the owner picks one title |
| SK-20 | The recording ends before the family question (2:17 to 2:28) | The question shows on screen |
| SK-21 | Punjabi text is Claude's draft; Punjabi narration | **Closed**: the owner recorded it, 2026-10-27 (`sone_di_khaan`); timings under SK-23 |
| SK-22 | No shabad | None unless the owner sends one with its Ang |

### The Saint-Soldier

| # | Item | Default |
|---|---|---|
| SK-15 | The pankti ਸੂਰਾ ਸੋ ਪਹਿਚਾਨੀਐ ... has no Ang or English meaning from a named source yet | **Open under SK3**: no Gurbani row until both come |
| SK-16 | The recording ends before the family question (2:25 to 2:32) | The question shows on screen; the owner listens |
| SK-17 | The Khanda emblem on flags and turbans is later than 1757 | Accepted as on the second saakhi |
| SK-18 | Punjabi text is Claude's draft; Punjabi narration | **Closed**: the owner recorded it, 2026-10-27; timings under SK-23 |

### All four

| # | Item | Default |
|---|---|---|
| SK-23 | The Punjabi page timings were placed by Claude, 2026-10-27, from each page's share of the Punjabi text snapped to the nearest long pause; nobody has listened yet | **Open**: the owner listens and corrects any page that turns early or late. The Punjabi lesson page has no `meaning_at`, so its Gurbani row does not open by itself |

## 5. Storage

`content.db` table `saakhi` and `user.db` table `saakhi_favourites`:
`docs/ARCHITECTURE.md` §3.2 and §3.6a. The pipeline reads
`content/source/saakhi/*.json`; a typed-in shabad ships only with a `checked`
record (SK3). Pictures and narration are app assets made by
`tools/saakhi/build_assets.py` from the owner's masters, which sit in
`saakhi-handoff/` until they move to a release (SK13).

## 6. Adding a saakhi

1. The owner sends the account and, if there is one, the shabad.
2. Claude splits it into pages, retells it (SK4), drafts the lesson line and
   the family question, the Punjabi text, image prompts and the narration
   script.
3. The owner sends the images and the recording with each page's start time.
4. Claude builds the preview (§7); the owner tests it on the phone.
5. When it is approved, its JSON goes into `content/source/saakhi/`.

## 7. The preview

`python3 tools/design/build_saakhi_preview.py <saakhi.json> <images-dir> <out.html> [--audio <narration.mp3>]`
writes one self-contained HTML file from `design/saakhi/reader.template.html`,
which reads everything about a saakhi from its JSON: images and audio
embedded, playable on a phone. The images directory holds `cover`, `p1` ...
`p8` in any common format; an image the JSON marks `missing` borrows the page
before it. Without `--audio` the play button is disabled and says the
narration is coming. Gurbani a saakhi names by `ref` (a bani and a line id) is
read from that bani's source file at build time, with its Ang and the
meanings the saakhi names by source.

**SK14. A line of Gurbani may sit on a story page** (`"gurbani"` on the page),
below the text, with its meaning in the reader's language and its Ang. It
follows SK3: from a named source file, never voiced by text to speech.
