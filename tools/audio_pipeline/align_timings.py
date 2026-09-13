#!/usr/bin/env python3
"""Align a bani's recitation to its lines, producing a timing file.

The reader highlights the line being recited and scrolls with it (PRD 1.6),
which needs a start and end millisecond offset for every line. There is no
forced aligner for Gurmukhi available here, so the timings are derived from the
recording itself:

1. The recitation's pauses are found from a short-time energy envelope. A
   paathi pauses between lines, so most line boundaries show up as a dip.
2. Every line is given a weight -- an estimate of how long it takes to recite,
   counting syllable nuclei rather than characters, so matras and subjoined
   consonants do not inflate it.
3. A dynamic program assigns one detected pause to each of the 384 boundaries
   between the 385 lines, in order, choosing the assignment whose segment
   durations best match the line weights while preferring longer pauses. Pauses
   the reciter takes mid-line (at a vishraam) are skipped by the same search.

The result is verified, not assumed: `--report` prints how well pauri
boundaries landed on long pauses, which is the signal that the alignment is
tracking the recitation rather than drifting through it.

The PRD requires human verification of line timings before release
(PRD §8); `tools/audio_pipeline/timing_tool.py` serves that purpose.

Usage:
    python3 tools/audio_pipeline/align_timings.py japji-sahib
"""
from __future__ import annotations

import argparse
import json
import math
import os
import sqlite3
import subprocess
import sys
import tempfile
import wave

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
CONTENT_DB = os.path.join(ROOT, "assets", "content", "content.db")
AUDIO_SRC = os.path.join(ROOT, "audio", "source")
TIMINGS_DIR = os.path.join(ROOT, "content", "source", "timings")

FRAME_S = 0.020
ANALYSIS_RATE = 16000

# Pause detection. The floor of this recording sits near -37 dBFS, so -27 dB
# separates a held breath from the room tone without cutting into speech.
QUIET_DB = -27.0
MIN_PAUSE_MS = 100

# How many detected pauses one line may swallow. A line can contain a couple of
# vishraam breaths; more than this and the search is being asked to paper over
# a missed boundary.
MAX_PAUSES_PER_LINE = 5

# Weight of the "prefer a long pause" term against the duration-fit term.
PAUSE_REWARD = 0.9

# Gurmukhi code points, by role.
_INDEPENDENT_VOWELS = range(0x0A05, 0x0A15)
_CONSONANTS = set(range(0x0A15, 0x0A3A)) | set(range(0x0A59, 0x0A5F))
_VIRAMA = 0x0A4D
_EK_ONKAR = 0x0A74


def syllables(text: str) -> float:
    """Estimate how many syllables a Gurmukhi line takes to recite.

    Counts syllable nuclei: independent vowels and consonants, minus one for
    each virama, since a subjoined consonant joins the syllable before it.
    Digits inside line-end markers score nothing -- a reciter pauses there
    rather than speaking the number.
    """
    count = 0.0
    for ch in text:
        cp = ord(ch)
        if cp == _EK_ONKAR:
            count += 3  # "ik oan kaar"
        elif cp in _CONSONANTS or cp in _INDEPENDENT_VOWELS:
            count += 1
        elif cp == _VIRAMA:
            count -= 1
    return max(count, 1.0)


def word_spans(text: str, start: float, end: float) -> list[list[int]]:
    """Split a line's span across its words, in proportion to their syllables.

    The PRD allows exactly this as the fallback when an aligner cannot give
    word timings (PRD §8). It is an estimate: the word highlight tracks the
    recitation closely on evenly paced lines and drifts a little where the
    paathi lingers. Line highlighting does not depend on it.
    """
    words = [w for w in text.split(" ") if w]
    if not words:
        return []
    weights = [syllables(w) for w in words]
    total = sum(weights)
    spans: list[list[int]] = []
    cursor = start
    for i, weight in enumerate(weights):
        span = (end - start) * weight / total
        # The last word ends exactly on the line's end, so rounding cannot
        # leave a gap the reader would see as an unhighlighted tail.
        stop = end if i == len(weights) - 1 else cursor + span
        spans.append([int(round(cursor * 1000)), int(round(stop * 1000))])
        cursor = stop
    return spans


def decode_to_wav(src: str, dst: str) -> None:
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", src,
         "-ac", "1", "-ar", str(ANALYSIS_RATE), "-c:a", "pcm_s16le", "-y", dst],
        check=True,
    )


def envelope(path: str) -> np.ndarray:
    with wave.open(path) as w:
        raw = w.readframes(w.getnframes())
    x = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    hop = int(FRAME_S * ANALYSIS_RATE)
    frames = x[: len(x) // hop * hop].reshape(-1, hop)
    rms = np.sqrt((frames ** 2).mean(axis=1) + 1e-12)
    return 20 * np.log10(rms)


def find_pauses(db: np.ndarray) -> tuple[list[tuple[float, float]], float, float]:
    """Returns the pauses inside the recitation, plus where speech starts/ends."""
    loud = np.where(db > QUIET_DB)[0]
    if len(loud) == 0:
        raise SystemExit("no speech detected in the recording")
    speech_start = float(loud[0] * FRAME_S)
    speech_end = float((loud[-1] + 1) * FRAME_S)

    quiet = db < QUIET_DB
    pauses: list[tuple[float, float]] = []
    i, n = 0, len(quiet)
    while i < n:
        if not quiet[i]:
            i += 1
            continue
        j = i
        while j < n and quiet[j]:
            j += 1
        start, end = i * FRAME_S, j * FRAME_S
        if (end - start) * 1000 >= MIN_PAUSE_MS and start > speech_start and end < speech_end:
            pauses.append((start, end))
        i = j
    return pauses, speech_start, speech_end


def align(
    weights: list[float],
    pauses: list[tuple[float, float]],
    speech_start: float,
    speech_end: float,
) -> list[int]:
    """Picks one pause per line boundary; returns the chosen pause indices.

    A dynamic program over (boundary, pause) minimising how far each line's
    duration strays from its weight, less a reward for landing on a long pause.
    """
    n_lines = len(weights)
    n_bounds = n_lines - 1
    n_pauses = len(pauses)
    if n_pauses < n_bounds:
        raise SystemExit(
            f"only {n_pauses} pauses detected for {n_bounds} line boundaries; "
            "loosen QUIET_DB or MIN_PAUSE_MS"
        )

    total_weight = sum(weights)
    seconds_per_weight = (speech_end - speech_start) / total_weight

    starts = np.array([p[0] for p in pauses])
    ends = np.array([p[1] for p in pauses])
    rewards = (ends - starts) * PAUSE_REWARD

    def segment_cost(duration: float, weight: float) -> float:
        # Squared log-ratio, so being 2x too fast costs the same as 2x too
        # slow. A plain squared difference barely notices a line collapsing to
        # a fraction of its expected length, which is exactly the failure to
        # avoid.
        expected = weight * seconds_per_weight
        return math.log(max(duration, 0.05) / expected) ** 2

    INF = math.inf
    # best[j] = cost of placing the current boundary at pause j
    best = np.full(n_pauses, INF)
    back = np.full((n_bounds, n_pauses), -1, dtype=np.int32)

    # Boundary 0 closes line 0, which starts where speech starts.
    lo, hi = 0, n_pauses - n_bounds
    for j in range(lo, hi + 1):
        best[j] = segment_cost(starts[j] - speech_start, weights[0]) - rewards[j]

    for b in range(1, n_bounds):
        nxt = np.full(n_pauses, INF)
        lo, hi = b, n_pauses - (n_bounds - b)
        for j in range(lo, hi + 1):
            k0 = max(b - 1, j - MAX_PAUSES_PER_LINE)
            best_cost, best_k = INF, -1
            for k in range(k0, j):
                prev = best[k]
                if prev == INF:
                    continue
                cost = prev + segment_cost(starts[j] - ends[k], weights[b])
                if cost < best_cost:
                    best_cost, best_k = cost, k
            if best_k >= 0:
                nxt[j] = best_cost - rewards[j]
                back[b, j] = best_k
        best = nxt

    # Close the last line against the end of speech.
    final_cost, final_j = INF, -1
    for j in range(n_bounds - 1, n_pauses):
        if best[j] == INF:
            continue
        cost = best[j] + segment_cost(speech_end - ends[j], weights[-1])
        if cost < final_cost:
            final_cost, final_j = cost, j

    if final_j < 0:
        raise SystemExit("alignment failed: no monotonic assignment found")

    chosen = [0] * n_bounds
    j = final_j
    for b in range(n_bounds - 1, -1, -1):
        chosen[b] = j
        j = int(back[b, j]) if b > 0 else j
    return chosen


def load_lines(bani_slug: str) -> tuple[str, list[dict]]:
    con = sqlite3.connect(f"file:{CONTENT_DB}?mode=ro", uri=True)
    row = con.execute(
        "SELECT v.id FROM bani_version v JOIN bani b ON b.id = v.bani_id "
        "WHERE b.slug = ? AND v.is_default = 1",
        (bani_slug,),
    ).fetchone()
    if row is None:
        raise SystemExit(f"no default version for bani '{bani_slug}'")
    version_id = row[0]
    lines = [
        {"idx": idx, "gurmukhi": gurmukhi, "pauri": pauri, "ends_pauri": bool(ends)}
        for idx, gurmukhi, pauri, ends in con.execute(
            "SELECT idx, gurmukhi, pauri, ends_pauri FROM line "
            "WHERE bani_version_id = ? ORDER BY idx",
            (version_id,),
        )
    ]
    con.close()
    return version_id, lines


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("bani", help="bani slug, e.g. japji-sahib")
    ap.add_argument("--audio", help="override the source audio path")
    ap.add_argument("--report", action="store_true", help="print alignment diagnostics")
    args = ap.parse_args()

    audio = args.audio or os.path.join(AUDIO_SRC, f"{args.bani}.mp3")
    if not os.path.exists(audio):
        raise SystemExit(f"missing audio: {audio}")

    version_id, lines = load_lines(args.bani)
    weights = [syllables(l["gurmukhi"]) for l in lines]

    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "analysis.wav")
        decode_to_wav(audio, wav)
        db = envelope(wav)

    pauses, speech_start, speech_end = find_pauses(db)
    duration_ms = int(round(len(db) * FRAME_S * 1000))
    chosen = align(weights, pauses, speech_start, speech_end)

    # Turn the chosen pauses into per-line spans.
    spans: list[tuple[float, float]] = []
    prev_end = speech_start
    for i in range(len(lines)):
        if i < len(chosen):
            end = pauses[chosen[i]][0]
            spans.append((prev_end, end))
            prev_end = pauses[chosen[i]][1]
        else:
            spans.append((prev_end, speech_end))

    timings = {
        "track": f"{args.bani}_sgpc_voice1",
        "baniVersionId": version_id,
        "durationMs": duration_ms,
        "version": 3,
        "method": "energy-pause detection + syllable-weighted DP alignment",
        "verified": False,
        "lines": [
            {
                "line": lines[i]["idx"],
                "s": int(round(s * 1000)),
                "e": int(round(e * 1000)),
                "w": word_spans(lines[i]["gurmukhi"], s, e),
            }
            for i, (s, e) in enumerate(spans)
        ],
    }

    os.makedirs(TIMINGS_DIR, exist_ok=True)
    out = os.path.join(TIMINGS_DIR, f"{args.bani}.json")
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(timings, fh, ensure_ascii=False, separators=(",", ":"))
        fh.write("\n")
    print(f"wrote {out}  ({len(lines)} lines, {duration_ms/1000:.1f}s)")

    if args.report:
        report(lines, spans, weights, pauses, chosen, speech_start, speech_end)
    return 0


def report(lines, spans, weights, pauses, chosen, speech_start, speech_end) -> None:
    durs = np.array([e - s for s, e in spans])
    w = np.array(weights)
    rate = durs / w
    print(f"\npauses detected: {len(pauses)}   boundaries needed: {len(lines)-1}")
    print(f"speech: {speech_start:.2f}s -> {speech_end:.2f}s")
    print(f"line duration: min {durs.min():.2f}s  median {np.median(durs):.2f}s  max {durs.max():.2f}s")
    print(f"seconds per syllable: median {np.median(rate):.3f}  "
          f"p10 {np.percentile(rate,10):.3f}  p90 {np.percentile(rate,90):.3f}")
    print(f"correlation(weight, duration): {np.corrcoef(w, durs)[0,1]:.3f}")

    # The real check: a pauri ends with a longer pause than a mid-pauri line.
    gap_at = {b: pauses[c][1] - pauses[c][0] for b, c in enumerate(chosen)}
    ends_pauri = [i for i, l in enumerate(lines) if l["ends_pauri"] and i < len(chosen)]
    mid = [i for i in range(len(chosen)) if i not in set(ends_pauri)]
    if ends_pauri and mid:
        pe = np.array([gap_at[i] for i in ends_pauri])
        mp = np.array([gap_at[i] for i in mid])
        print(f"\npause after a pauri ends : mean {pe.mean()*1000:6.0f}ms  (n={len(pe)})")
        print(f"pause mid-pauri          : mean {mp.mean()*1000:6.0f}ms  (n={len(mp)})")
        print(f"ratio                    : {pe.mean()/mp.mean():.2f}x  "
              f"(>1.2 means boundaries landed on real line ends)")

    worst = np.argsort(-np.abs(rate - np.median(rate)))[:8]
    print("\nlines whose pace strays furthest from the median:")
    for i in sorted(worst):
        print(f"  line {lines[i]['idx']:>3}  {spans[i][0]:7.2f}-{spans[i][1]:7.2f}s  "
              f"{durs[i]:5.2f}s  {weights[i]:4.0f} syl  {rate[i]:.3f} s/syl  "
              f"{lines[i]['gurmukhi'][:38]}")


if __name__ == "__main__":
    sys.exit(main())
