# Audio

## What is committed

`assets/audio/*.m4a` — the files the app ships: mono AAC, 64 kbps,
loudness-normalised to −16 LUFS. Japji Sahib is 9.0 MB for 19 minutes.

`content/source/timings/*.json` — line and word timings, so the reader can
follow the recitation.

## What is not committed

The masters. A 320 kbps master is ~43 MB per bani and git would keep every
version of it forever, so they live as assets on the **`audio-masters`**
GitHub release instead.

To fetch one:

```bash
mkdir -p audio/source
gh release download audio-masters --pattern 'japji-sahib.mp3' --dir audio/source
```

Name each master after the bani's slug in `content.db` (`japji-sahib.mp3`,
`rehras-sahib.mp3`, …) so the pipeline can pair audio to bani without a lookup
table.

## Rebuilding

Every bani takes the same three steps; `japji-sahib` below is any slug from
the `bani` table (`jaap-sahib`, `tav-prasad-savaiye`, `chaupai-sahib`,
`anand-sahib`, `rehras-sahib`, `kirtan-sohila`, `ardas`, `sukhmani-sahib`).

```bash
# master -> shipping AAC at -16 LUFS
python3 tools/audio_pipeline/build_audio.py japji-sahib

# recitation -> line and word timings
python3 tools/audio_pipeline/forced_align.py japji-sahib --report

# check the alignment against the recording itself
python3 tools/audio_pipeline/verify_timings.py japji-sahib

# fold the audio and timings into content.db
python3 tools/content_pipeline/build_content_db.py
```

The Naam Simran recitation is not a bani and takes a different path:

```bash
# the session is five minutes and the master is sixteen, so only the part
# that plays is shipped -- 2.4 MB rather than 8. The fade matters: five
# minutes lands wherever the reciter happens to be, and the last three
# seconds ending rather than stopping is the difference between a session
# that closes and one that is cut off.
python3 tools/audio_pipeline/build_audio.py naam-simran --seconds 300 --fade 3

# measure the shape the Simran ring follows
python3 tools/audio_pipeline/simran_envelope.py naam-simran

python3 tools/content_pipeline/build_content_db.py
```

The alignment step also needs `espeak-ng`; both audio steps need `ffmpeg`.
Neither runs in CI: their outputs are committed, and CI only checks that
`content.db` still matches them.

## Where the alignment stands

Two checks, and they answer different questions.

`<bani>.anchors.json` holds times somebody listened to and wrote down. The
aligner never sees them, and they are the only thing here that can catch a
recitation being aligned to the wrong place altogether -- which is exactly
what happened when these eight arrived, and what the pause check missed. There
is one anchor per bani so far, at the first line, so they prove where each
recitation starts and nothing further.

The pause check asks whether line boundaries land in the reciter's silences.
It can only speak where the reciter is silent between lines, which the last
column measures.

| bani | anchor error | line starts in a pause | random | gap between lines |
|---|---|---|---|---|
| Japji Sahib | -- | 98% | 17% | 360 ms |
| Jaap Sahib | 0.00s | 44% | 11% | 0 ms |
| Tav Prasad Savaiye | -- | 88% | 16% | 370 ms |
| Chaupai Sahib | 0.00s | 99% | 35% | 140 ms |
| Anand Sahib | 0.00s | 98% | 17% | 400 ms |
| Rehras Sahib | 0.10s | 72% | 17% | 220 ms |
| Kirtan Sohila | 0.00s | 94% | 18% | 420 ms |
| Ardas | 0.14s | 100% | 27% | 490 ms |
| Sukhmani Sahib | 0.22s | 64% | 11% | 120 ms |

Nothing is verified: every timing file says `"verified": false`, and the PRD
requires a person to listen before release (§8). What to listen for:

* **Rehras** first. Its reciter breaks between lines, so the pause check has
  something to find, and 72% is short of the 85% the others clear. Its start
  is right; what is not established is whether it stays right.
* **Jaap and Sukhmani** score lowest and mean least. Jaap's chhands are
  recited with no gap at all between lines and Sukhmani's with 120 ms, so most
  of their boundaries fall mid-flow however well they are placed. Their
  openings are exact; past that, nothing here has looked.
* **Tav Prasad Savaiye** has no anchor yet.

`text_vs_audio.py` is the third check, and the one that found what the other
two could not. The aligner cannot refuse: given a text and a recording it
always produces a mapping, so text the reciter never says gets absorbed rather
than reported, and the highlight runs ahead of the voice from there on. The
tool compares how often the reciter stops for breath against how many lines
the timing file puts in the same stretch. Phrasing rate is roughly constant
through a bani, so where the line count climbs against a flat pause count, the
text is being packed in.

On Chaupai it is unmistakable: the reciter takes 6 to 8 phrase pauses in every
30 seconds from beginning to end, while the lines assigned climb from 11 to 23
after 1:30 -- right after ॥੩੮੮॥, which is where the Benti Chaupai of Nitnem
ends and this source file carries on into ੩੮੯-੪੦੫. It says where to listen,
not which lines; only an ear can say that.

A second anchor near the end of a bani would be worth more than any of this.
One at the first line proves where a recitation starts; two, far apart, prove
it does not drift -- which is the failure the pause check cannot see either.

## How the timings are made

`forced_align.py` is a forced aligner. The first version of this pipeline was
not: it found the recording's pauses, estimated how long each line ought to
take from its syllable count, and assigned pauses to boundaries so the
durations fitted. Nothing in that search ever looked at *what was said*, so two
lines of similar length were interchangeable to it, and partway through the
bani it slid one line late and stayed there. Adding rounds of re-estimation
made it worse, and the check that said otherwise was measuring something the
re-estimation was directly optimising.

What the aligner does instead:

1. **Speak the text.** Every word of the bani is spoken once by `espeak-ng`'s
   Punjabi voice, trimmed of its padding and concatenated. The result sounds
   nothing like a paathi, but it says the same words in the same order, and
   every word boundary in it is known exactly.
2. **Reduce both to MFCCs.** Mean/variance normalised per recording, which
   takes out the fixed differences in voice and channel and leaves the part
   that moves with the phonemes.
3. **Warp one onto the other.** Dynamic time warping finds the monotonic
   mapping between them — coarsely first, in 100 ms frames across the whole
   nineteen minutes, then finely in 20 ms frames inside a 3-second band around
   the coarse path. One real frame is consumed per step and the text advances
   0, 1 or 2, so the reciter may hold a pause as long as they like without the
   text running on.
4. **Read the words off the mapping.** Each word's known span in the synthesis
   becomes a span in the recording; a line runs from its first word to its
   last. Word timings are measured here, not divided up by syllable count.
5. **Snap to the reciter's own pauses.** The warp lands in the right pause but
   rarely on its edges. A second dynamic program assigns the detected pauses to
   the boundaries, in order and one each, so the previous line ends where the
   reciter stopped and the next begins where they started again.
6. **Trim the ends.** The recording closes with words that are not in the text.
   Since the warp must account for every frame, that would otherwise be
   absorbed into the last line and highlight it for twelve seconds.

Two parameters were tuned against the stretch of the old timing file that had
been checked by ear, and both sit on a plateau rather than a peak:
`STEP_PENALTY` (0.6; anywhere from 0.4 to 1.2 gives the same result, 2.0
collapses) and `SNAP_WINDOW_S` (1.0; 0.45 upwards gives the same result).

### How it is checked

`verify_timings.py` runs three checks, and deliberately not the one the aligner
would pass by construction:

- **Pauses.** The warp knows nothing about the recording's energy, so a line
  boundary landing in a stretch the reciter was silent for is two independent
  readings agreeing. 98% of the 384 boundaries do, against 17% for times drawn
  at random.
- **Repeated lines.** Japji repeats eight lines verbatim. The audio under two
  occurrences of the same line should sound alike and two unrelated lines
  should not: matched pairs average a DTW distance of 0.132 against 0.319 for
  controls, 3.1 standard deviations apart. This one is invariant to an
  alignment that has slid a constant amount late everywhere, which is why it is
  not the headline number.
- **Anchors.** `content/source/timings/<slug>.anchors.json`, if it exists,
  holds times somebody listened to and wrote down; the aligner never sees it.
  That is the only ground truth here, and there is none yet.

## The Simran ring

Android offers no way to read audio as it plays -- the player the app uses has
no visualiser -- so the ring cannot react to the recitation at runtime. Instead
`simran_envelope.py` measures the shipped `.m4a` once: its loudness 25 times a
second, and the moment each Waheguru begins. Both ride in content.db, and the
ring reads them against the session clock. A bloom in the app is a real
utterance, not a timer.

It reads the shipped file rather than the master, so what was measured is
exactly what will play.

## Still to do

Line timings are marked `"verified": false`. The PRD requires a human to check
them before release (§8). `tools/timing_tool/` opens the recitation next to the
text so the lines the aligner was least sure of can be corrected by ear, and
writes the corrections back into the timing file.
