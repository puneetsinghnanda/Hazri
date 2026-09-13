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

```bash
# master -> shipping AAC at -16 LUFS
python3 tools/audio_pipeline/build_audio.py japji-sahib

# recitation -> line and word timings
python3 tools/audio_pipeline/align_timings.py japji-sahib --report

# check the alignment against the recording itself
python3 tools/audio_pipeline/verify_timings.py japji-sahib

# fold the audio and timings into content.db
python3 tools/content_pipeline/build_content_db.py
```

Both audio steps need `ffmpeg` on the PATH. They are not run in CI: their
outputs are committed, and CI only checks that `content.db` still matches them.

## How the timings are made

There is no forced aligner for Gurmukhi available, so `align_timings.py`
derives them from the recording:

1. Pauses are found from a 20 ms energy envelope (the paathi pauses between
   lines, so most line boundaries show up as a dip).
2. Each line gets a weight — an estimate of how long it takes to recite,
   counting syllable nuclei rather than characters.
3. A dynamic program assigns one detected pause to each line boundary, in
   order, choosing the assignment whose segment durations best fit the weights
   while preferring longer pauses. Mid-line breaths are skipped by the same
   search.
4. Word spans inside a line are split by syllable weight — the fallback the
   PRD allows (§8) when an aligner cannot give word timings.

`verify_timings.py` checks the result acoustically rather than taking it on
trust. Japji repeats eight lines verbatim; the tool compares the audio under
each repeat with dynamic time warping and reports how far matched pairs sit
from unrelated ones. On the shipped alignment, matched pairs average a DTW
distance of 0.136 against 0.311 for controls — **4.3 standard deviations** of
separation.

## Still to do

Line timings are marked `"verified": false`. The PRD requires a human to check
them before release (§8). The alignment is good enough to read along with, but
it is an estimate, and the word highlight in particular drifts where the paathi
lingers.
