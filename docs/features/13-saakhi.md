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
with the Guru never drawn.

## 2. Rules

**SK1. Every saakhi is on the phone.** Text, images and narration are bundled
like the banis. Reading or listening needs no network, no profile and no
group (CLAUDE.md rule 4).

**SK2. The Guru is never drawn.** Not a face, not a body, not robes, not hands,
not an outline. The Guru's presence is a warm golden light, and the other
people in the scene react to it. An image that shows any part of a figure for
the Guru does not ship (CLAUDE.md rule 3). AI art is allowed for every other
person and scene (owner, 2026-10-19).

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

**SK10. Share** is a labelled button at the bottom of every story page and the
main button of the lesson page, never only an icon in the top bar. It makes a
1080 x 1920 image of the current page (or the cover, for the whole saakhi):
the picture, the saakhi's name, the page's text, and a band reading "Read and
listen to the full saakhi · Free in the Hazri app" with the link. It goes out
through Android's share sheet with a short message; the app itself sends
nothing (PRD §8).

**SK11. The library.** Saakhis are listed as cards: the cover, the Punjabi name
above the English, the page count, the narration languages and the length.
Where the list lives in the app is decided when it is built (PRD §3.2).

**SK12. Favourite** is a heart on each story page, kept on the phone.

**SK13. Audio masters are not in git**, like the banis' (`audio/README.md`).
The images are not in git until every one of them meets SK2.

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
Share image, Save and Copy text.

**Failure: a figure in an image.** Given an image shows any part of a figure
for the Guru, then the saakhi does not ship until the image is replaced.

**Failure: an unsourced pankti.** Given a pankti whose text has not been
checked against a named source, then the saakhi does not ship.

## 4. Open before each saakhi ships

Final so far (design, words and timings approved by the owner): *Bhai Lalo
and Malik Bhago* and *Anand Bhaya Meri Maaye*, both 2026-10-20.

### Bhai Lalo and Malik Bhago

| # | Item | Default |
|---|---|---|
| SK-1 | Six images show the Guru as a robed figure (cover, 1, 3, 4, 5, 6); three show meat (2, 4, 7); the cover has its title painted in | Regenerate them; SK2 |
| SK-2 | The Punjabi text is Claude's draft | The owner checks it |
| SK-3 | The Ang 105 pankti and its English were transcribed from a screenshot | Check against BaniDB or another named source |
| SK-4 | Where Share's link leads | `hazri.me` today; a Play Store link or a per-saakhi page later |
| SK-5 | The recording ends while the voice is still speaking (2:12) | Trim at a pause |
| SK-6 | The big lesson line and the family question are Claude's wording | Approved by the owner with design D |
| SK-7 | Punjabi narration | Text first; recording when the owner has it |

### Anand Bhaya Meri Maaye

| # | Item | Default |
|---|---|---|
| SK-8 | Six images draw the Guru as a figure (cover, 1, 2, 3, 6, 7); the cover shows the Guru teaching, where the story's teacher is the learned Sikh, and has its title painted in; page 1's canopy carries a Khanda; the teacher looks younger on page 3 | Regenerate them; SK2 |
| SK-9 | The Anand Sahib line on page 4 (about 0:43) must be a person's recording | Replace it if it is text to speech; SK3 |
| SK-10 | The Punjabi text is Claude's draft, and the source's Punjabi meaning of the line opens "ਹੇ ਭਾਈ ਮਾਂ!" | The owner checks both; a fault in the meaning is fixed in `anand-sahib.json` |
| SK-11 | The recording may hold only one of the lesson page's two sentences (1:42 to 1:49) | The owner listens |
| SK-12 | A second pankti the owner supplied is not used | Placed once its Ang is known |
| SK-13 | The Guru is not named in the account | The text says Guru Ji |

## 5. Storage

The `content.db` tables (a saakhi, its pages, its narration cues) are added
to `docs/ARCHITECTURE.md` when the feature is built, and the pipeline reads
`content/source/saakhi/*.json`. Favourites go in `user.db`.

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
