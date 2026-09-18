#!/usr/bin/env python3
"""Force-align a recitation to its text, producing a timing file.

The reader highlights the line and word being recited and scrolls with it
(PRD 1.6), which needs a start and end offset for each. Earlier attempts
derived those from the recording's pauses alone -- from how *long* each line
sounded rather than from *what was said* -- and slid off the text partway
through, because nothing in that search could tell two lines of similar length
apart.

This is a forced aligner, so the alignment is decided by content:

1. Every word of the bani is spoken by espeak-ng's Punjabi voice, trimmed of
   its padding and concatenated. That gives a synthetic recitation whose word
   boundaries are known exactly, and whose phonetic content is the text.
2. Both recordings are reduced to MFCCs -- what was said, with the speaker,
   the pitch and the loudness largely normalised away.
3. Dynamic time warping finds the monotonic mapping between the two, coarsely
   first (100 ms frames over the whole recording) and then finely (20 ms frames
   in a 3-second band around the coarse path).
4. Each word's known span in the synthetic audio is read through the mapping to
   get its span in the real one; a line runs from its first word to its last.

Because the mapping is monotonic and driven by phonetic content, it cannot
silently slide a line late the way pause counting did: to get a line wrong it
has to match the wrong sounds, which shows up as a poor local distance. That
distance is what `--report` ranks the lines by, so the least trustworthy ones
can be checked by hand (PRD §8) rather than the whole bani.

Usage:
    python3 tools/audio_pipeline/forced_align.py japji-sahib --report
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
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

# Some recitations open with something the text does not carry -- an
# invocation, a spoken dedication, the reciter naming the bani -- and some skip
# the text's opening lines altogether. The warp has to account for every frame
# of the recording and is anchored at the start, so it cannot pass over either:
# it spreads the mismatch across the opening lines and the whole alignment
# reads early. This file says where each recitation starts saying the text.
AUDIO_START_FILE = os.path.join(TIMINGS_DIR, "audio-start.json")

# Which alignments a person has listened to and accepted (PRD §8). Keyed by a
# hash of the exact timings they heard, so re-aligning a bani drops it back to
# unverified on its own rather than carrying somebody's word onto a file they
# never checked.
VERIFIED_FILE = os.path.join(TIMINGS_DIR, "verified.json")

SR = 16000

# espeak-ng's Punjabi voice. The speed only has to be in the same range as the
# recitation; the global rate difference is normalised away before the warp.
VOICE = "pa"
SPEED = 140
WORD_GAP_S = 0.03

# MFCC. Two passes: a coarse one over the whole recording, then a fine one in a
# band around it.
COARSE_HOP, COARSE_WIN, COARSE_BAND_S = 0.100, 0.200, 90.0
FINE_HOP, FINE_WIN, FINE_BAND_S = 0.020, 0.050, 3.0

# Snapping. The warp decides which pause a line boundary belongs in; the pause
# itself decides where in it the boundary falls, to the frame. -27 dB sits
# above the room tone of every recitation here and below all of their speech,
# which one level can do because build_audio.py normalises them all to -16
# LUFS before they ship.
#
# Deriving it per recording instead -- the recording's own 25th percentile --
# was tried and is worse: measured against a fixed instrument it took Japji
# from 98% of line starts landing in a pause to 91%, Chaupai from 100% to 87%,
# and Rehras from 70% to 36%. It looked like an improvement only while the
# check was moving with it, which is the one thing this pipeline's verifier
# exists to prevent.
QUIET_DB = -27.0
MIN_PAUSE_S = 0.10
SNAP_WINDOW_S = 1.00

# A recording may open or close with words that are not in the text -- an
# invocation, a closing salutation, the last line said once more. Only the
# first and last line can absorb those, and they do it by running far longer
# than their share of the recitation, so an outer edge is pulled back in when
# its line would otherwise take more than this many times its expected span.
# Nothing between the first and last line is ever moved this way.
END_SLACK = 2.5

# How much a step off the diagonal costs, in the same units as the frame
# distance. Holding and skipping cost the same, which was tested rather than
# assumed: when eight recitations came back with the text running ahead of the
# voice partway through, the obvious suspect was this cost -- absorbing five
# seconds of unexpected audio means holding for 250 fine frames, which at 0.6
# each is a cost no frame distance can repay. Neither direction helped.
# Charging more to skip than to hold took Chaupai's physically impossible
# lines from 7 to 5 and then to 9 as the gap widened; making holding nearly
# free took it to 10. The text running ahead is not the warp choosing a cheap
# path. It is the recording saying something the text does not contain. The recitation and the synthesis have already been matched for
# overall pace, so a path that races through two lines of near-identical text
# is paying for it; without this, a run of lines that all open the same way
# ("ਅਸੰਖ ..."), which the ear tells apart only by what follows, gives the search
# nothing to hold onto.
STEP_PENALTY = 0.60

N_MEL = 26
N_CEPS = 13  # c0 is loudness and is dropped, leaving 12


# ---------------------------------------------------------------------------
# Audio


def decode(src: str, dst: str) -> None:
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", src,
         "-ac", "1", "-ar", str(SR), "-c:a", "pcm_s16le", "-y", dst],
        check=True,
    )


def read_wav(path: str) -> tuple[int, np.ndarray]:
    with wave.open(path) as w:
        if w.getsampwidth() != 2 or w.getnchannels() != 1:
            raise SystemExit(f"{path}: expected 16-bit mono")
        raw = w.readframes(w.getnframes())
        return w.getframerate(), np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0


def write_wav(path: str, rate: int, x: np.ndarray) -> None:
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes(np.clip(x * 32767.0, -32768, 32767).astype(np.int16).tobytes())


def trim_silence(x: np.ndarray, rate: int, floor: float = 0.02) -> np.ndarray:
    """Drops espeak's leading and trailing padding.

    espeak pads every utterance with a fixed silence, which would put ~0.3 s of
    nothing between each of the bani's words and stretch the synthetic
    recitation far past the real one.
    """
    a = np.abs(x)
    if a.size == 0 or a.max() <= 0:
        return x
    loud = np.where(a > a.max() * floor)[0]
    if len(loud) == 0:
        return x
    pad = int(0.01 * rate)
    return x[max(0, loud[0] - pad): min(len(x), loud[-1] + 1 + pad)]


# ---------------------------------------------------------------------------
# Synthesis


def synthesise(words: list[str], tmp: str, verbose: bool = False) -> tuple[str, np.ndarray]:
    """Speaks every word once, and returns the wav path and each word's span.

    Word by word rather than line by line, so the span of every word is known
    exactly rather than divided up by a rule of thumb afterwards.
    """
    if shutil.which("espeak-ng") is None:
        raise SystemExit("espeak-ng is not installed; it is what speaks the text")

    out = os.path.join(tmp, "espeak.wav")
    one = os.path.join(tmp, "word.wav")
    chunks: list[np.ndarray] = []
    spans = np.zeros((len(words), 2), dtype=np.float64)
    gap = None
    rate = None
    cursor = 0

    for i, word in enumerate(words):
        subprocess.run(
            ["espeak-ng", "-v", VOICE, "-s", str(SPEED), "-w", one, "--", word],
            check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
        )
        r, x = read_wav(one)
        if rate is None:
            rate = r
            gap = np.zeros(int(WORD_GAP_S * rate), dtype=np.float32)
        x = trim_silence(x, rate)
        spans[i] = (cursor / rate, (cursor + len(x)) / rate)
        chunks.append(x)
        chunks.append(gap)
        cursor += len(x) + len(gap)
        if verbose and (i + 1) % 250 == 0:
            print(f"  spoken {i + 1}/{len(words)} words", file=sys.stderr)

    if rate is None:
        raise SystemExit("no words to align")
    write_wav(out, rate, np.concatenate(chunks))
    resampled = os.path.join(tmp, "espeak16.wav")
    decode(out, resampled)
    return resampled, spans


# ---------------------------------------------------------------------------
# Features


def _mel_filters(n_fft: int) -> np.ndarray:
    def to_mel(f):
        return 2595.0 * np.log10(1.0 + f / 700.0)

    def to_hz(m):
        return 700.0 * (10.0 ** (m / 2595.0) - 1.0)

    lo, hi = to_mel(80.0), to_mel(SR / 2)
    points = to_hz(np.linspace(lo, hi, N_MEL + 2))
    bins = np.floor((n_fft + 1) * points / SR).astype(int)
    filters = np.zeros((N_MEL, n_fft // 2 + 1), dtype=np.float32)
    for m in range(1, N_MEL + 1):
        left, centre, right = bins[m - 1], bins[m], bins[m + 1]
        if centre == left:
            centre = left + 1
        if right <= centre:
            right = centre + 1
        rise = np.arange(left, centre)
        fall = np.arange(centre, right)
        filters[m - 1, left:centre] = (rise - left) / (centre - left)
        filters[m - 1, centre:right] = (right - fall) / (right - centre)
    return filters


def _dct_matrix() -> np.ndarray:
    n = np.arange(N_MEL)
    k = np.arange(N_CEPS)[:, None]
    return (np.cos(np.pi * k * (2 * n + 1) / (2 * N_MEL)) * np.sqrt(2.0 / N_MEL)).astype(np.float32)


def mfcc(x: np.ndarray, hop_s: float, win_s: float) -> np.ndarray:
    """MFCCs, mean/variance normalised and L2-scaled for a cosine distance.

    Normalising per recording is what lets a synthetic voice be compared with a
    real one at all: it takes out the fixed differences in channel and timbre
    and leaves the part that moves with the phonemes.
    """
    hop, win = int(hop_s * SR), int(win_s * SR)
    n_fft = 1 << (win - 1).bit_length()
    x = np.append(x[0], x[1:] - 0.97 * x[:-1])  # pre-emphasis
    count = max(1, 1 + (len(x) - win) // hop)
    idx = np.arange(win)[None, :] + hop * np.arange(count)[:, None]
    frames = np.take(x, np.minimum(idx, len(x) - 1)) * np.hamming(win).astype(np.float32)
    power = np.abs(np.fft.rfft(frames, n_fft)) ** 2
    energies = np.log(power @ _mel_filters(n_fft).T + 1e-10)
    ceps = energies @ _dct_matrix().T
    ceps = ceps[:, 1:]  # c0 is loudness, which differs by recording, not by sound
    ceps -= ceps.mean(axis=0)
    ceps /= ceps.std(axis=0) + 1e-8
    ceps /= np.linalg.norm(ceps, axis=1, keepdims=True) + 1e-8
    return ceps.astype(np.float32)


# ---------------------------------------------------------------------------
# Dynamic time warping

INF = np.float32(1e30)


def dtw(real: np.ndarray, synth: np.ndarray, band: int,
        penalty: float = STEP_PENALTY, skip_penalty: float | None = None) -> np.ndarray:
    """Maps every frame of `real` to a frame of `synth`, monotonically.

    `synth` has already been resampled so that the mapping runs along the
    diagonal; the search only has to find the local departures from it, inside
    `band` frames either side.

    One real frame is consumed per step and the synthetic side advances 0, 1 or
    2 frames, so the reciter may hold a pause for as long as they like without
    the text running on, and the text may never outrun the recitation by more
    than double. That makes each row depend only on the row before it, which is
    what keeps a warp this long computable.
    """
    n = len(real)
    if len(synth) != n:
        raise ValueError("synth must be resampled to the real length")
    width = 2 * band + 1
    back = np.zeros((n, width), dtype=np.int8)
    offsets = np.arange(width) - band

    # One row of the cost table, in band coordinates: prev[k] is the cost of
    # reaching synthetic frame i - 1 + offsets[k] at the previous real frame.
    prev = np.full(width, INF, dtype=np.float32)
    prev[band] = 0.0  # the recitation starts at the start of the text

    chunk = 256
    row_costs = np.empty(width, dtype=np.float32)
    for start in range(0, n, chunk):
        stop = min(n, start + chunk)
        lo = max(0, start - band)
        hi = min(n, stop - 1 + band + 1)
        gram = 1.0 - real[start:stop] @ synth[lo:hi].T
        for i in range(start, stop):
            j = i + offsets
            valid = (j >= lo) & (j < hi) & (j >= 0) & (j < n)
            row_costs[:] = INF
            np.copyto(row_costs, gram[i - start][np.clip(j - lo, 0, hi - lo - 1)], where=valid)

            # prev[k] is (i-1, j-1); prev[k+1] is (i-1, j); prev[k-1] is (i-1, j-2).
            diag = prev
            hold = np.empty(width, dtype=np.float32)
            hold[:-1] = prev[1:]
            hold[-1] = INF
            skip = np.empty(width, dtype=np.float32)
            skip[1:] = prev[:-1]
            skip[0] = INF

            np.putmask(hold, hold < INF, hold + penalty)
            np.putmask(skip, skip < INF, skip + (penalty if skip_penalty is None
                                                 else skip_penalty))
            stacked = np.stack((diag, hold, skip))
            choice = np.argmin(stacked, axis=0).astype(np.int8)
            best = stacked[choice, offsets + band]
            back[i] = choice
            prev = np.where(np.isfinite(best) & (best < INF) & valid, best + row_costs, INF)

    # The recitation ends at the end of the text.
    path = np.zeros(n, dtype=np.int64)
    k = band
    if prev[k] >= INF:
        k = int(np.argmin(prev))
    for i in range(n - 1, -1, -1):
        path[i] = i + offsets[k]
        step = back[i, k]
        k = k + 1 if step == 1 else (k - 1 if step == 2 else k)
        k = min(max(k, 0), width - 1)
    return np.clip(path, 0, n - 1)


def resample_to(seq: np.ndarray, n: int) -> tuple[np.ndarray, np.ndarray]:
    """Nearest-frame resampling, plus the index map that undoes it."""
    idx = np.clip(np.round(np.linspace(0, len(seq) - 1, n)).astype(np.int64), 0, len(seq) - 1)
    return seq[idx], idx


def warp(real_wav: str, synth_wav: str, verbose: bool = False,
         penalty: float = STEP_PENALTY,
         skip_penalty: float | None = None) -> np.ndarray:
    """Returns, for each 20 ms frame of the recitation, the synthetic time it matches."""
    _, real = read_wav(real_wav)
    _, synth = read_wav(synth_wav)

    if verbose:
        print("  coarse pass (100 ms frames)", file=sys.stderr)
    a = mfcc(real, COARSE_HOP, COARSE_WIN)
    b = mfcc(synth, COARSE_HOP, COARSE_WIN)
    bb, index = resample_to(b, len(a))
    coarse = dtw(a, bb, int(COARSE_BAND_S / COARSE_HOP), penalty, skip_penalty)
    coarse_t = index[coarse] * COARSE_HOP  # synthetic seconds per coarse real frame

    if verbose:
        print("  fine pass (20 ms frames)", file=sys.stderr)
    a = mfcc(real, FINE_HOP, FINE_WIN)
    b = mfcc(synth, FINE_HOP, FINE_WIN)
    # Resample the synthetic side along the coarse path rather than along the
    # diagonal, so the fine search only has the residual to find.
    centres = np.interp(
        np.arange(len(a)) * FINE_HOP,
        np.arange(len(coarse_t)) * COARSE_HOP,
        coarse_t,
    ) / FINE_HOP
    index = np.clip(np.round(centres).astype(np.int64), 0, len(b) - 1)
    fine = dtw(a, b[index], int(FINE_BAND_S / FINE_HOP), penalty, skip_penalty)
    return index[fine] * FINE_HOP


# ---------------------------------------------------------------------------
# Snapping to the reciter's own pauses


def find_pauses(path: str) -> tuple[list[tuple[float, float]], float, float]:
    """The quiet stretches inside the recitation, and where speech starts and ends."""
    _, x = read_wav(path)
    hop = int(FINE_HOP * SR)
    frames = x[: len(x) // hop * hop].reshape(-1, hop)
    db = 20 * np.log10(np.sqrt((frames ** 2).mean(axis=1)) + 1e-12)
    loud = np.where(db > QUIET_DB)[0]
    if len(loud) == 0:
        raise SystemExit("no speech detected in the recording")
    speech = (float(loud[0] * FINE_HOP), float((loud[-1] + 1) * FINE_HOP))

    quiet = db < QUIET_DB
    edges = np.flatnonzero(np.diff(np.concatenate(([0], quiet.view(np.int8), [0]))))
    pauses = [
        (float(a * FINE_HOP), float(b * FINE_HOP))
        for a, b in zip(edges[::2], edges[1::2])
        if (b - a) * FINE_HOP >= MIN_PAUSE_S and a * FINE_HOP > speech[0]
        and b * FINE_HOP < speech[1]
    ]
    return pauses, speech[0], speech[1]


def snap(bounds: np.ndarray, pauses: list[tuple[float, float]]) -> np.ndarray:
    """Moves each line boundary onto the pause the warp put it in.

    The warp works in 20 ms frames against a synthetic voice, so it lands in
    the right pause but rarely on its edges, which the reader sees as the
    highlight changing a fraction of a second early or late. Snapping is what
    makes a boundary exact -- the previous line ends where the reciter stopped
    and the next begins where they started again.

    The pauses are assigned to the boundaries all at once rather than one at a
    time, by a dynamic program that keeps them in order and never gives one
    pause to two boundaries. Taking the nearest free pause greedily instead
    lets an early boundary claim the pause its neighbour needed and push a
    whole run of lines onto the wrong breaths.

    A boundary further than `SNAP_WINDOW_S` from any free pause keeps the time
    the warp gave it. Returns one (end-of-previous, start-of-next) pair per
    boundary.
    """
    if not pauses:
        return np.stack((bounds, bounds), axis=1)

    lo = np.array([a for a, _ in pauses])
    hi = np.array([b for _, b in pauses])
    n_b, n_p = len(bounds), len(pauses)

    # Leaving a boundary where it is costs the width of the window, so a pause
    # inside the window always wins -- unless taking it would cost a
    # neighbouring boundary more.
    skip_cost = SNAP_WINDOW_S

    # state 0: no pause used yet; state p+1: pause p was the last one used.
    best = np.full(n_p + 1, INF, dtype=np.float64)
    best[0] = 0.0
    from_take = np.zeros((n_b, n_p + 1), dtype=bool)
    from_state = np.zeros((n_b, n_p + 1), dtype=np.int32)

    for i, bound in enumerate(bounds):
        # Distance from the boundary to the pause, zero when it falls inside.
        gap = np.maximum(np.maximum(lo - bound, bound - hi), 0.0)
        take_cost = np.where(gap <= SNAP_WINDOW_S, gap, INF)

        order = np.minimum.accumulate(best)
        which = np.zeros(n_p + 1, dtype=np.int32)
        running, arg = best[0], 0
        for q in range(n_p + 1):
            if best[q] < running:
                running, arg = best[q], q
            which[q] = arg
        take = np.full(n_p + 1, INF)
        take[1:] = take_cost + order[:-1]
        skip = best + skip_cost

        from_take[i] = take < skip
        from_state[i] = np.where(from_take[i], np.concatenate(([0], which[:-1])),
                                 np.arange(n_p + 1))
        best = np.minimum(take, skip)

    out = np.stack((bounds, bounds), axis=1)
    state = int(np.argmin(best))
    for i in range(n_b - 1, -1, -1):
        if from_take[i][state]:
            out[i] = (lo[state - 1], hi[state - 1])
        state = int(from_state[i][state])
    return out


def trim_ends(spans: np.ndarray, spoken: np.ndarray,
              pauses: list[tuple[float, float]]) -> list[str]:
    """Pulls the first and last line back off audio the text does not cover.

    The warp has to account for every frame of the recording, so anything said
    before the first word or after the last gets absorbed into the line next to
    it -- which the reader would show as one line highlighted for ten or twenty
    seconds. Returns a note for each edge it moved, for `--report` to print,
    because what it trimmed is speech somebody may still want in the app.
    """
    durations = spans[:, 1] - spans[:, 0]
    inner = slice(1, len(spans) - 1)
    pace = float(np.median(durations[inner] / np.maximum(spoken[inner], 1e-6)))
    notes: list[str] = []

    expected = pace * spoken[-1]
    if durations[-1] > END_SLACK * expected:
        target = spans[-1][0] + expected
        after = [a for a, _ in pauses if a >= target]
        end = min(after) if after else target
        notes.append(f"trimmed {spans[-1][1] - end:.1f}s off the end of the "
                     f"recording: it carries speech the text does not")
        spans[-1][1] = end

    expected = pace * spoken[0]
    if durations[0] > END_SLACK * expected:
        target = spans[0][1] - expected
        before = [b for _, b in pauses if b <= target]
        start = max(before) if before else target
        notes.append(f"trimmed {start - spans[0][0]:.1f}s off the start of the "
                     f"recording: it carries speech the text does not")
        spans[0][0] = start

    return notes


# ---------------------------------------------------------------------------
# Reading the warp


def to_real(synth_t: np.ndarray, query: float, last: bool) -> float:
    """The real time matching a synthetic time.

    A whole run of real frames can share one synthetic time -- that is what a
    pause in the recitation looks like -- so a word's start takes the first
    frame of the run and its end takes the last.
    """
    if last:
        i = int(np.searchsorted(synth_t, query, side="right")) - 1
    else:
        i = int(np.searchsorted(synth_t, query, side="left"))
    i = min(max(i, 0), len(synth_t) - 1)
    return i * FINE_HOP


# ---------------------------------------------------------------------------
# Content


def load_lines(slug: str) -> tuple[str, list[dict]]:
    con = sqlite3.connect(f"file:{CONTENT_DB}?mode=ro", uri=True)
    row = con.execute(
        "SELECT v.id FROM bani_version v JOIN bani b ON b.id = v.bani_id "
        "WHERE b.slug = ? AND v.is_default = 1",
        (slug,),
    ).fetchone()
    if row is None:
        raise SystemExit(f"no default version for bani '{slug}'")
    lines = [
        {"idx": idx, "gurmukhi": gurmukhi, "pauri": pauri, "ends_pauri": bool(ends)}
        for idx, gurmukhi, pauri, ends in con.execute(
            "SELECT idx, gurmukhi, pauri, ends_pauri FROM line "
            "WHERE bani_version_id = ? ORDER BY idx",
            (row[0],),
        )
    ]
    con.close()
    return row[0], lines


def spoken_words(text: str) -> list[str]:
    """The words a reciter actually says.

    The line-end markers and their pauri numbers are written, not spoken; the
    reciter pauses there instead, and asking espeak to read them would put
    sounds in the synthesis that are not in the recording.
    """
    words = []
    for w in text.split():
        stripped = w.strip("॥।")
        if stripped and not stripped.isdigit():
            words.append(w)
    return words


def audio_start_for(slug: str) -> tuple[float, int]:
    """Where this recitation starts saying the text: seconds in, and from
    which line. Zero and one when the file says nothing about it."""
    if not os.path.exists(AUDIO_START_FILE):
        return 0.0, 1
    with open(AUDIO_START_FILE, encoding="utf-8") as fh:
        entry = json.load(fh).get(slug) or {}
    return float(entry.get("seconds", 0.0)), int(entry.get("fromLine", 1))


def lines_sha(out_lines: list[dict]) -> str:
    payload = json.dumps(out_lines, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:16]


def verified_sha_for(slug: str) -> str | None:
    if not os.path.exists(VERIFIED_FILE):
        return None
    with open(VERIFIED_FILE, encoding="utf-8") as fh:
        return ((json.load(fh).get(slug) or {}).get("linesSha"))


def skip_audio_for(slug: str) -> list[list[float]]:
    """Stretches of the recording that carry no text, in seconds.

    A recitation may say something the text does not at either end or in the
    middle -- an invocation, a closing salutation, a line said twice. The warp
    has to account for every frame it is given, so anything it is given that
    the text does not cover gets absorbed into the lines around it, and the
    highlight drags. These stretches are taken out before the warp and added
    back to the times afterwards; the recording itself is untouched and still
    plays them.
    """
    if not os.path.exists(AUDIO_START_FILE):
        return []
    with open(AUDIO_START_FILE, encoding="utf-8") as fh:
        entry = json.load(fh).get(slug) or {}
    return [[float(a), float(b)] for a, b in entry.get("skipAudio", [])]


class Timebase:
    """Maps a time in the spliced recording back to the real one."""

    def __init__(self, skips: list[list[float]], total: float):
        self.keep: list[tuple[float, float]] = []
        cursor = 0.0
        for a, b in sorted(skips):
            a, b = max(0.0, a), min(total, b)
            if b <= a:
                continue
            if a > cursor:
                self.keep.append((cursor, a))
            cursor = max(cursor, b)
        if cursor < total:
            self.keep.append((cursor, total))
        self.offsets: list[tuple[float, float]] = []
        t = 0.0
        for a, b in self.keep:
            self.offsets.append((t, a - t))
            t += b - a
        self.trimmed = t

    def to_real(self, t: float) -> float:
        off = self.offsets[0][1] if self.offsets else 0.0
        for start, o in self.offsets:
            if t >= start:
                off = o
            else:
                break
        return t + off


def pins_for(slug: str) -> list[tuple[int, float]]:
    """Times somebody listened to, used to hold the alignment in place.

    The warp snaps each boundary onto the pause it lands in, and where a
    reciter barely stops between lines the pauses are shallow and it can take
    the wrong one -- Tav Prasad Savaiye's closing lines sit 2.6s late for
    exactly that reason, with no missing audio to blame. A pin says where a
    line actually starts; the timeline is stretched piecewise between pins so
    every pinned line lands on its time and everything between follows.

    A pinned line is no longer evidence: it is an input. Keep the anchors file
    for lines that are not pinned, which is what still checks the result.

    A lone pin is a blunt instrument, because the stretch that brings it onto
    its time has to go somewhere and the only other knots are the two ends of
    the recording. One pin 1.4s early on Jaap dragged the preceding sixteen
    minutes with it -- half a second out in the middle, enough to take the
    pause hit rate from 44% to 14% -- and the same drag is what threw Tav
    Prasad Savaiye's opening out when its closing line was pinned. Bracket a
    pin with `hold` (below) unless the whole timeline really is adrift.
    """
    if not os.path.exists(AUDIO_START_FILE):
        return []
    with open(AUDIO_START_FILE, encoding="utf-8") as fh:
        entry = json.load(fh).get(slug) or {}
    return sorted((int(p["line"]), float(p["s"])) for p in entry.get("pin", []))


def holds_for(slug: str) -> list[int]:
    """Lines to leave exactly where the warp put them.

    A hold is a knot that maps a line's time to itself, so a neighbouring
    pin's stretch stops there instead of running to the end of the recording.
    Bracketing a pin with a hold either side confines the change to those few
    lines and leaves every other line in the bani bit-identical, which is what
    you want when one boundary snapped to the wrong pause and the rest of the
    alignment is accepted.

    A hold is not a claim about the recitation and costs no evidence: it says
    only "this was already right, do not move it".
    """
    if not os.path.exists(AUDIO_START_FILE):
        return []
    with open(AUDIO_START_FILE, encoding="utf-8") as fh:
        entry = json.load(fh).get(slug) or {}
    return sorted(int(n) for n in entry.get("hold", []))


def raw_path(slug: str) -> str:
    return os.path.join(TIMINGS_DIR, f"{slug}.raw.json")


def write_raw(slug: str, out_lines: list[dict], full_len: float) -> None:
    """The alignment as the warp produced it, before any pin."""
    with open(raw_path(slug), "w", encoding="utf-8") as fh:
        json.dump({"durationMs": int(round(full_len * 1000)),
                   "lines": out_lines}, fh, ensure_ascii=False,
                  separators=(",", ":"))
        fh.write("\n")


def apply_pins(out_lines: list[dict], pins: list[tuple[int, float]],
               total_s: float, holds: list[int] = ()) -> int:
    """Stretches the timeline so each pinned line starts where it was heard."""
    def start_of(line: int, what: str) -> float:
        row = next((r for r in out_lines if r["line"] == line), None)
        if row is None:
            raise SystemExit(f"{what}: line {line} has no timing")
        return row["s"] / 1000.0

    knots = [(0.0, 0.0), (total_s, total_s)]
    knots += [(start_of(line, "pin"), want) for line, want in pins]
    # A held line is its own target: the map is the identity through it.
    knots += [((t := start_of(line, "hold")), t) for line in holds]
    knots = sorted(set(knots))
    # A pin that would run the timeline backwards is a bad number, not a warp
    # to force: refuse it rather than produce times that go the wrong way. A
    # hold that lands the wrong side of a pin trips this too, which is the
    # point -- it means the pin moves the line past something said to be fixed.
    for (a, b), (c, d) in zip(knots, knots[1:]):
        if c <= a or d <= b:
            raise SystemExit(f"pin: {knots} is not in order; check the times")
    src = [k[0] for k in knots]
    dst = [k[1] for k in knots]

    def remap(ms: int) -> int:
        return int(round(float(np.interp(ms / 1000.0, src, dst)) * 1000))

    for row in out_lines:
        row["s"], row["e"] = remap(row["s"]), remap(row["e"])
        row["w"] = [[remap(a), remap(b)] for a, b in row["w"]]
    return len(pins)


def repeats_for(slug: str) -> list[list[int]]:
    """Line ranges the reciter says more than once, as [first, last, times].

    A reciter commonly closes a bani by saying its last couplet twice. The
    text has those lines once, so the second pass is audio the warp cannot
    account for: it stretches the final lines to cover it and the highlight
    sits there while the voice carries on. Repeating the lines here gives the
    warp text for both passes, and the timing file carries the line twice, so
    the highlight follows the reciter round again.
    """
    if not os.path.exists(AUDIO_START_FILE):
        return []
    with open(AUDIO_START_FILE, encoding="utf-8") as fh:
        entry = json.load(fh).get(slug) or {}
    out = []
    for r in entry.get("repeat", []):
        first, last = int(r[0]), int(r[1])
        out.append([first, last, int(r[2]) if len(r) > 2 else 2])
    return out


def recited_ranges_for(slug: str) -> list[list[int]] | None:
    """Which 1-based line ranges of the text this recitation actually says.

    A recording may leave out a stretch in the middle as well as at the ends --
    a colophon the reciter passes over, a section the arrangement does not
    include. Lines outside these ranges keep their text and get no timing, so
    they read and are never highlighted.
    """
    if not os.path.exists(AUDIO_START_FILE):
        return None
    with open(AUDIO_START_FILE, encoding="utf-8") as fh:
        entry = json.load(fh).get(slug) or {}
    ranges = entry.get("lines")
    return [[int(a), int(b)] for a, b in ranges] if ranges else None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("bani", help="bani slug, e.g. japji-sahib")
    ap.add_argument("--audio", help="override the source audio path")
    ap.add_argument("--report", action="store_true", help="rank the lines by how well they matched")
    ap.add_argument("--worst", type=int, default=20, help="how many lines --report lists")
    ap.add_argument("--out", help="write the timings here instead of content/source/timings")
    ap.add_argument(
        "--lead-in", type=float, default=None,
        help="seconds of the recording before the text's first word. Defaults "
             "to this bani's entry in timings/audio-start.json, or 0.")
    ap.add_argument(
        "--from-line", type=int, default=None,
        help="the 1-based line the recitation begins at, when it skips the "
             "text's opening lines. Those lines keep their text and simply "
             "get no timing.")
    ap.add_argument(
        "--lines",
        help="1-based line ranges the recitation actually says, e.g. "
             "'3-102,121-128'. Overrides this bani's `lines` in "
             "timings/audio-start.json. Lines outside them keep their text "
             "and get no timing.")
    ap.add_argument("--hold-penalty", type=float, default=STEP_PENALTY,
                    help="cost of the text waiting while the recitation goes on")
    ap.add_argument("--skip-penalty", type=float, default=None,
                    help="cost of the text running at double pace; defaults to "
                         "the hold penalty")
    ap.add_argument(
        "--repin", action="store_true",
        help="re-apply this bani's pins to the timing file it already has, "
             "without warping again. Pins are a remap of the finished "
             "timeline, so the result is the same as a full run, and a long "
             "recitation does not have to be re-aligned to move one.")
    ap.add_argument("--quiet", action="store_true")
    args = ap.parse_args()

    out_path = args.out or os.path.join(TIMINGS_DIR, f"{args.bani}.json")
    if args.repin:
        with open(out_path, encoding="utf-8") as fh:
            doc = json.load(fh)
        already = doc.get("pinnedLines") or []
        raw = raw_path(args.bani)
        if already and not os.path.exists(raw):
            raise SystemExit(
                f"{out_path} was written with pins {already} already applied "
                f"and there is no {os.path.basename(raw)} to start from; "
                "re-align it rather than pinning a pinned timeline")
        pins = pins_for(args.bani)
        if not pins:
            raise SystemExit(f"no pins for {args.bani} in {AUDIO_START_FILE}")
        holds = holds_for(args.bani)
        # Always start from the warp's own answer where there is one. Pinning
        # a pinned timeline compounds; pinning the raw one is the same
        # arithmetic the full run does, and gives the same file.
        if os.path.exists(raw):
            with open(raw, encoding="utf-8") as fh:
                doc["lines"] = json.load(fh)["lines"]
        apply_pins(doc["lines"], pins, doc["durationMs"] / 1000.0, holds)
        doc["verified"] = lines_sha(doc["lines"]) == verified_sha_for(args.bani)
        doc["pinnedLines"] = [p[0] for p in pins]
        doc["heldLines"] = holds
        with open(out_path, "w", encoding="utf-8") as fh:
            json.dump(doc, fh, ensure_ascii=False, separators=(",", ":"))
            fh.write("\n")
        print(f"re-pinned {out_path} to {len(pins)} time(s) taken by ear"
              + (f", held at {len(holds)} line(s)" if holds else ""))
        return 0

    audio = args.audio or os.path.join(AUDIO_SRC, f"{args.bani}.mp3")
    if not os.path.exists(audio):
        raise SystemExit(f"missing audio: {audio}")

    version_id, lines = load_lines(args.bani)
    verbose = not args.quiet
    file_lead, file_from = audio_start_for(args.bani)
    lead = args.lead_in if args.lead_in is not None else file_lead
    from_line = args.from_line if args.from_line is not None else file_from
    ranges = ([[int(a), int(b)] for a, b in
               (r.split("-") for r in args.lines.split(","))]
              if args.lines else recited_ranges_for(args.bani))
    if ranges:
        keep = [ln for ln in lines
                if any(a <= ln["idx"] + 1 <= b for a, b in ranges)]
        if not keep:
            raise SystemExit(f"--lines {ranges} leaves no text to align")
        if verbose:
            print(f"the recitation says {len(keep)} of {len(lines)} lines "
                  f"({ranges}); the rest get no timing", file=sys.stderr)
        lines = keep
        from_line = 1
    repeats = repeats_for(args.bani)
    if repeats:
        # The block comes round again as a block: a reciter closing on a
        # couplet says both lines, then both again -- 208, 209, 208, 209, not
        # 208, 208, 209, 209. Expanded in recitation order, so a repeat in the
        # middle of a bani works the same way as one at the end. The numbers
        # in the file are always the source text's own line numbers.
        spans = sorted((int(a) - 1, int(b) - 1, int(t)) for a, b, t in repeats)
        expanded, i, used = [], 0, 0
        while i < len(lines):
            here = next((s for s in spans if s[0] == lines[i]["idx"]), None)
            if here is None:
                expanded.append(lines[i])
                i += 1
                continue
            first, last, times = here
            block = []
            while i < len(lines) and lines[i]["idx"] <= last:
                block.append(lines[i])
                i += 1
            for _ in range(times):
                expanded.extend(dict(ln) for ln in block)
            used += 1
        if used != len(spans):
            raise SystemExit(f"repeat {repeats} names a line that is not aligned")
        if verbose:
            shown = ", ".join(f"{a + 1}-{b + 1} x{t}" for a, b, t in spans)
            print(f"repeated as a block ({shown}): {len(lines)} lines become "
                  f"{len(expanded)} timing rows", file=sys.stderr)
        lines = expanded
    if from_line > 1:
        skipped = lines[: from_line - 1]
        lines = lines[from_line - 1:]
        if not lines:
            raise SystemExit(f"--from-line {from_line} leaves no text to align")
        if verbose:
            print(f"the recitation starts at line {from_line}; "
                  f"{len(skipped)} line(s) before it get no timing",
                  file=sys.stderr)
    if lead and verbose:
        print(f"skipping the first {lead:.2f}s: the text starts there",
              file=sys.stderr)

    # Every spoken word of the bani, and which line it belongs to.
    words: list[str] = []
    owner: list[int] = []
    for i, line in enumerate(lines):
        spoken = spoken_words(line["gurmukhi"])
        if not spoken:  # a line of nothing but markers still needs a span
            spoken = [line["gurmukhi"].strip() or "।"]
        for w in spoken:
            words.append(w)
            owner.append(i)

    with tempfile.TemporaryDirectory() as tmp:
        if verbose:
            print(f"speaking {len(words)} words with espeak-ng ({VOICE})", file=sys.stderr)
        synth_wav, word_spans = synthesise(words, tmp, verbose)
        real_wav = os.path.join(tmp, "real.wav")
        decode(audio, real_wav)
        rate, x = read_wav(real_wav)
        full_len = len(x) / SR
        skips = ([[0.0, lead]] if lead else []) + skip_audio_for(args.bani)
        base = Timebase(skips, full_len)
        if skips:
            # Everything from here on works in the spliced recording's own
            # timebase; `base` maps back to the real one where times are
            # written. The file on disk is never changed.
            kept = np.concatenate([x[int(a * SR):int(b * SR)] for a, b in base.keep])
            write_wav(real_wav, rate, kept)
            if verbose:
                total = sum(b - a for a, b in skips)
                print(f"leaving {total:.1f}s of the recording unattributed "
                      f"({len(skips)} stretch(es))", file=sys.stderr)
        real_len = len(read_wav(real_wav)[1]) / SR
        if verbose:
            print(f"warping {real_len:.0f}s of recitation onto "
                  f"{word_spans[-1][1]:.0f}s of synthesis", file=sys.stderr)
        synth_t = warp(real_wav, synth_wav, verbose, args.hold_penalty,
                       args.skip_penalty)
        pauses, speech_start, speech_end = find_pauses(real_wav)

    # Read every word's span through the warp.
    real_spans = np.array([
        [to_real(synth_t, s, last=False), to_real(synth_t, e, last=True)]
        for s, e in word_spans
    ])
    # A word may not start before it ends, nor before the word before it.
    for i in range(len(real_spans)):
        if i and real_spans[i][0] < real_spans[i - 1][1]:
            real_spans[i][0] = real_spans[i - 1][1]
        if real_spans[i][1] < real_spans[i][0] + FINE_HOP:
            real_spans[i][1] = real_spans[i][0] + FINE_HOP

    owner_arr = np.array(owner)
    members = [np.where(owner_arr == i)[0] for i in range(len(lines))]
    raw = np.array([
        [real_spans[m[0]][0], real_spans[m[-1]][1]] for m in members
    ])

    # Tighten each boundary onto the pause the warp put it in, then let the
    # first and last line stop at the edges of the speech rather than the file.
    bounds = (raw[:-1, 1] + raw[1:, 0]) / 2
    snapped = snap(bounds, pauses)
    spans = raw.copy()
    spans[:-1, 1] = snapped[:, 0]
    spans[1:, 0] = snapped[:, 1]
    spans[0, 0] = max(spans[0, 0], speech_start - MIN_PAUSE_S)
    spans[-1, 1] = min(spans[-1, 1], speech_end + MIN_PAUSE_S)
    spoken = np.array([
        sum(word_spans[j][1] - word_spans[j][0] for j in m) for m in members
    ])
    notes = trim_ends(spans, spoken, pauses)

    out_lines = []
    stats = []
    for i, line in enumerate(lines):
        mine = members[i]
        s, e = float(spans[i][0]), float(spans[i][1])
        # The words keep their shares of the line after the line moved.
        width = max(raw[i][1] - raw[i][0], 1e-6)
        scale = (e - s) / width
        words_out = []
        for j in mine:
            ws = s + (real_spans[j][0] - raw[i][0]) * scale
            we = s + (real_spans[j][1] - raw[i][0]) * scale
            words_out.append([int(round(ws * 1000)), int(round(we * 1000))])
        out_lines.append({
            "line": line["idx"],
            "s": int(round(base.to_real(s) * 1000)),
            "e": int(round(base.to_real(e) * 1000)),
            "w": [[int(round(base.to_real(a / 1000) * 1000)),
                   int(round(base.to_real(b / 1000) * 1000))] for a, b in words_out],
        })
        stats.append((i, s, e, float(spoken[i])))

    pins = pins_for(args.bani)
    holds = holds_for(args.bani)
    if pins:
        # Kept before the pins go on, so a later round can re-pin from the
        # warp's own answer instead of re-warping. Sukhmani takes thirty-five
        # minutes to align and a pin is only a remap of the result; four
        # rounds of corrections in one sitting is two hours of doing the same
        # arithmetic again.
        write_raw(args.bani, out_lines, full_len)
        apply_pins(out_lines, pins, full_len, holds)
        if verbose:
            print(f"pinned {len(pins)} line(s) to times taken by ear"
                  + (f", held at {len(holds)} line(s)" if holds else ""),
                  file=sys.stderr)

    timings = {
        "track": f"{args.bani}_sgpc_voice1",
        "baniVersionId": version_id,
        "durationMs": int(round(full_len * 1000)),
        "leadInMs": int(round(lead * 1000)),
        "unattributedMs": int(round(sum(b - a for a, b in skips) * 1000)),
        "pinnedLines": [p[0] for p in pins],
        "heldLines": holds,
        "version": 6,
        "method": "espeak-ng synthesis + two-pass MFCC dynamic time warping, snapped to pauses",
        # True only when somebody has listened to exactly these timings.
        "verified": lines_sha(out_lines) == verified_sha_for(args.bani),
        "lines": out_lines,
    }

    out = out_path
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(timings, fh, ensure_ascii=False, separators=(",", ":"))
        fh.write("\n")
    print(f"wrote {out}  ({len(lines)} lines, {len(words)} words, "
          f"{full_len:.1f}s)")

    for note in notes:
        print(note)

    if args.report:
        report(lines, stats, args.worst)
        print_snap_rate(spans, pauses)
    return 0


def print_snap_rate(spans, pauses) -> None:
    """How many boundaries the reciter's own pauses agreed with.

    This is the part of the check the aligner did not decide: the warp works on
    what was said, the pauses on the recording's energy, so the two agreeing is
    evidence rather than arithmetic.
    """
    ends = np.array([b for _, b in pauses])
    hit = sum(1 for s in spans[1:, 0] if np.any(np.abs(ends - s) < 1e-6))
    print(f"\nboundaries landing exactly on one of the reciter's "
          f"{len(pauses)} pauses: {hit}/{len(spans) - 1} ({hit / (len(spans) - 1):.0%})")


def report(lines, stats, worst: int) -> None:
    """Ranks the lines by how far each one's pace strays from the bani's.

    The warp itself cannot say "this line is wrong" -- it always produces a
    mapping -- but a line the recitation spent far more or far less time on
    than its share of the text is where to look first.
    """
    durations = np.array([e - s for _, s, e, _ in stats])
    spoken = np.array([sp for _, _, _, sp in stats])
    rate = durations / np.maximum(spoken, 1e-6)
    median = float(np.median(rate))
    strays = np.abs(np.log(np.maximum(rate, 1e-6) / median))

    print(f"\nrecitation is {median:.2f}x the pace of the synthesis, line for line")
    print(f"lines within 25% of that pace: "
          f"{int((strays < np.log(1.25)).sum())}/{len(stats)}")
    print(f"\nthe {worst} least typical lines (check these first):")
    print(f"{'line':>5}  {'start':>9}  {'dur':>6}  {'pace':>5}  text")
    for i in np.argsort(-strays)[:worst]:
        _, s, e, _ = stats[i]
        print(f"{lines[i]['idx']:>5}  {int(s)//60:>3}:{s % 60:05.2f}  "
              f"{e - s:>6.2f}  {rate[i] / median:>5.2f}  {lines[i]['gurmukhi'][:42]}")


if __name__ == "__main__":
    raise SystemExit(main())
