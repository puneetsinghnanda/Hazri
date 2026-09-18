#!/usr/bin/env python3
"""Check an aligned timing file against the recording itself.

Alignment quality cannot be judged from the timings alone, so this measures it
against the recording, and deliberately by means the aligner does not use --
a check the aligner optimises is no check at all.

Three of them, strongest first:

1. **Anchors.** If `content/source/timings/<slug>.anchors.json` exists, it
   holds times somebody listened to and wrote down, and the aligner never sees
   it. The error at those lines is the only measurement here that is ground
   truth rather than evidence.
2. **Pauses.** Line boundaries are found by warping the text onto the audio,
   which knows nothing about the recording's energy. So a boundary landing in
   a stretch the reciter was silent for is agreement between two independent
   readings of the same recording. Compared against times drawn at random,
   which land in silence often enough in a recitation that the comparison is
   the point.
3. **Repeated lines.** Japji Sahib repeats eight lines verbatim -- "ਆਦੇਸੁ ਤਿਸੈ
   ਆਦੇਸੁ ॥" four times, and so on. Two occurrences of the same line should
   sound alike and two unrelated lines should not, which this measures by
   warping log-mel spectra. It is the weakest of the three: it says the spans
   sit on the right words, but an alignment that had slid a constant amount
   late everywhere would still pass it.

Usage:
    python3 tools/audio_pipeline/verify_timings.py japji-sahib
"""
from __future__ import annotations

import argparse
import json
import os
import random
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

RATE = 16000
WIN = 400          # 25 ms
HOP = 160          # 10 ms
NFFT = 512
N_MELS = 26


# A reciter does not say a word in under a tenth of a second. The median
# across the nine banis is about 390 ms, so this is a quarter of the pace
# of the slowest of them -- low enough that only a collapsed line trips it.
FLOOR_MS = 100.0


def mel_filterbank() -> np.ndarray:
    def hz_to_mel(f):
        return 2595 * np.log10(1 + f / 700)

    def mel_to_hz(m):
        return 700 * (10 ** (m / 2595) - 1)

    low, high = hz_to_mel(50), hz_to_mel(8000)
    points = mel_to_hz(np.linspace(low, high, N_MELS + 2))
    bins = np.floor((NFFT + 1) * points / RATE).astype(int)
    fb = np.zeros((N_MELS, NFFT // 2 + 1))
    for m in range(1, N_MELS + 1):
        left, centre, right = bins[m - 1], bins[m], bins[m + 1]
        if centre == left:
            centre = left + 1
        if right == centre:
            right = centre + 1
        for k in range(left, centre):
            fb[m - 1, k] = (k - left) / (centre - left)
        for k in range(centre, right):
            fb[m - 1, k] = (right - k) / (right - centre)
    return fb


def log_mel(path: str) -> np.ndarray:
    with wave.open(path) as w:
        raw = w.readframes(w.getnframes())
    x = np.frombuffer(raw, dtype=np.int16).astype(np.float32) / 32768.0
    n_frames = 1 + (len(x) - WIN) // HOP
    idx = np.arange(WIN)[None, :] + HOP * np.arange(n_frames)[:, None]
    frames = x[idx] * np.hamming(WIN)
    spec = np.abs(np.fft.rfft(frames, NFFT)) ** 2
    return np.log(spec @ mel_filterbank().T + 1e-10)


def dtw(a: np.ndarray, b: np.ndarray) -> float:
    """Cosine-distance DTW, normalised by path length."""
    a = a - a.mean(axis=0, keepdims=True)
    b = b - b.mean(axis=0, keepdims=True)
    a = a / (np.linalg.norm(a, axis=1, keepdims=True) + 1e-9)
    b = b / (np.linalg.norm(b, axis=1, keepdims=True) + 1e-9)
    cost = 1 - a @ b.T

    n, m = cost.shape
    acc = np.full((n + 1, m + 1), np.inf)
    acc[0, 0] = 0
    for i in range(1, n + 1):
        row, prev, c = acc[i], acc[i - 1], cost[i - 1]
        for j in range(1, m + 1):
            row[j] = c[j - 1] + min(prev[j], row[j - 1], prev[j - 1])
    return float(acc[n, m] / (n + m))


# This is the measuring instrument, so it does not move when the aligner does.
# Every recitation is loudness-normalised to -16 LUFS before it ships, so one
# level means the same thing across all of them, and -27 dB sits above every
# one of their room tones. The aligner derives its own threshold per
# recording; that is the thing being measured, and a check that adopted the
# aligner's definition of a pause would be marking its own homework.
QUIET_DB = -27.0
MIN_PAUSE_S = 0.10
FRAME_S = 0.020


def pauses_of(path: str) -> list[tuple[float, float]]:
    """The stretches the reciter was silent for, from the energy alone."""
    with wave.open(path) as w:
        x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768.0
    hop = int(FRAME_S * RATE)
    frames = x[: len(x) // hop * hop].reshape(-1, hop)
    db = 20 * np.log10(np.sqrt((frames ** 2).mean(axis=1)) + 1e-12)
    quiet = db < QUIET_DB
    edges = np.flatnonzero(np.diff(np.concatenate(([0], quiet.view(np.int8), [0]))))
    return [
        (float(a * FRAME_S), float(b * FRAME_S))
        for a, b in zip(edges[::2], edges[1::2])
        if (b - a) * FRAME_S >= MIN_PAUSE_S
    ]


def in_a_pause(times: np.ndarray, pauses: list[tuple[float, float]]) -> np.ndarray:
    lo = np.array([a for a, _ in pauses])
    hi = np.array([b for _, b in pauses])
    i = np.clip(np.searchsorted(lo, times, side="right") - 1, 0, len(lo) - 1)
    return (times >= lo[i]) & (times <= hi[i])


def check_pauses(spans: dict[int, tuple[float, float]], wav: str, seed: int) -> bool:
    pauses = pauses_of(wav)
    ordered = [v for _, v in sorted(spans.items())]
    starts = np.array([s for s, _ in ordered][1:])
    hit = in_a_pause(starts, pauses)
    rng = np.random.default_rng(seed)
    control = in_a_pause(rng.uniform(starts.min(), starts.max(), 20000), pauses)
    print(f"\nline starts inside one of the reciter's {len(pauses)} pauses: "
          f"{hit.mean() * 100:.0f}%  (times drawn at random: {control.mean() * 100:.0f}%)")

    # How much this check can actually tell you depends on whether the reciter
    # breaks at line ends at all. Jaap Sahib's chhands run into one another --
    # the median gap between one line ending and the next beginning is zero --
    # so most of its boundaries fall mid-flow however well they are aligned,
    # and a low score there is the check running out of evidence rather than
    # the alignment being wrong. Measured from the spans, not from the pause
    # detector, so it is an independent reading.
    gaps = np.array([ordered[i + 1][0] - ordered[i][1] for i in range(len(ordered) - 1)])
    median_gap = float(np.median(gaps))
    print(f"  median gap between one line and the next: {median_gap * 1000:.0f} ms")
    if median_gap < 0.15:
        print("  this reciter runs lines together, so the pause check has "
              "little to find here and says correspondingly little")
    return bool(hit.mean() > 0.85)


def check_collapsed(timings: dict, text: dict[int, str]) -> None:
    """Lines the warp gave almost no time at all.

    The warp has to account for every frame it is given, so when it runs short
    it does not report a problem -- it squeezes a line down instead, and the
    highlight flashes past it faster than an eye can follow. Sukhmani's
    \u0a38\u0a32\u0a4b\u0a15\u0a41 at 1:10:26 came out at 30 ms for its one word, which is the
    shape of the fault somebody reported as the highlight running a line
    behind: the lines before it were being stretched and that one paid for it.

    It does not vote on the verdict, and that is not timidity: Jaap has
    twenty of these and Kirtan Sohila one, and both have been listened to and
    accepted. Jaap's reciter barely stops between lines -- a 0 ms median gap
    against Ardas's 500 -- so a line of his can genuinely be squeezed without
    anything sounding wrong. This is a list of places to listen, and it is
    cheap, which is the point: it needs no audio at all.
    """
    bad = []
    for row in timings["lines"]:
        words = max(1, len(row["w"]))
        ms = (row["e"] - row["s"]) / words
        if ms < FLOOR_MS:
            bad.append((ms, row))
    print(f"\nlines given less than {FLOOR_MS:.0f} ms a word "
          f"(worth a listen, not a failure): {len(bad)}")
    for ms, row in sorted(bad)[:8]:
        s = row["s"] / 1000
        print(f"  line {row['line']:>5}  {int(s // 60)}:{s % 60:05.2f}  "
              f"{ms:5.0f} ms/word  {text.get(row['line'], '')[:40]}")


def check_anchors(bani: str, spans: dict[int, tuple[float, float]]) -> bool | None:
    """Compares against times a person listened to, if any have been written down."""
    path = os.path.join(TIMINGS_DIR, f"{bani}.anchors.json")
    if not os.path.exists(path):
        print("\nno anchors file: nothing here has been checked by ear yet.")
        print(f"  write one at {os.path.relpath(path, ROOT)} as")
        print('  [{"line": 167, "s": 472.96}, ...] and this will measure against it.')
        return None
    with open(path, encoding="utf-8") as fh:
        anchors = json.load(fh)
    errors = []
    for a in anchors:
        if a["line"] in spans:
            errors.append(spans[a["line"]][0] - a["s"])
    if not errors:
        print("\nanchors file holds no line this timing file covers")
        return None
    e = np.abs(np.array(errors))
    print(f"\nagainst {len(e)} anchors somebody listened to: "
          f"median error {np.median(e):.2f}s, worst {e.max():.2f}s")
    for a, err in zip(anchors, errors):
        if abs(err) > 0.5:
            print(f"  line {a['line']:>4}: {err:+.2f}s")
    return bool(np.median(e) < 0.30 and e.max() < 1.0)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("bani")
    ap.add_argument("--audio")
    ap.add_argument("--controls", type=int, default=200)
    ap.add_argument("--seed", type=int, default=7)
    args = ap.parse_args()

    audio = args.audio or os.path.join(AUDIO_SRC, f"{args.bani}.mp3")
    with open(os.path.join(TIMINGS_DIR, f"{args.bani}.json"), encoding="utf-8") as fh:
        timings = json.load(fh)
    spans = {l["line"]: (l["s"] / 1000, l["e"] / 1000) for l in timings["lines"]}

    con = sqlite3.connect(f"file:{CONTENT_DB}?mode=ro", uri=True)
    rows = con.execute(
        "SELECT idx, gurmukhi FROM line WHERE bani_version_id = ? ORDER BY idx",
        (timings["baniVersionId"],),
    ).fetchall()
    con.close()

    groups: dict[str, list[int]] = {}
    for idx, text in rows:
        groups.setdefault(text, []).append(idx)
    repeats = {t: v for t, v in groups.items() if len(v) > 1}
    print(f"bani: {args.bani}   lines: {len(rows)}   repeat groups: {len(repeats)}")

    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "a.wav")
        subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", audio,
             "-ac", "1", "-ar", str(RATE), "-c:a", "pcm_s16le", "-y", wav],
            check=True,
        )
        feats = log_mel(wav)
        anchors_ok = check_anchors(args.bani, spans)
        pauses_ok = check_pauses(spans, wav, args.seed)
    check_collapsed(timings, dict(rows))

    def segment(idx: int) -> np.ndarray | None:
        s, e = spans[idx]
        a, b = int(s * RATE / HOP), int(e * RATE / HOP)
        return feats[a:b] if b - a >= 10 else None

    matched: list[float] = []
    per_group: list[tuple[str, list[float]]] = []
    for text, idxs in repeats.items():
        segs = [(i, segment(i)) for i in idxs]
        segs = [(i, s) for i, s in segs if s is not None]
        dists = []
        for x in range(len(segs)):
            for y in range(x + 1, len(segs)):
                dists.append(dtw(segs[x][1], segs[y][1]))
        matched.extend(dists)
        per_group.append((text, dists))

    rng = random.Random(args.seed)
    repeated_idxs = {i for v in repeats.values() for i in v}
    pool = [i for i, _ in rows if i in spans and segment(i) is not None]
    text_of = dict(rows)
    controls: list[float] = []
    while len(controls) < args.controls:
        a, b = rng.sample(pool, 2)
        if text_of[a] == text_of[b]:
            continue
        controls.append(dtw(segment(a), segment(b)))

    m = np.array(matched)
    c = np.array(controls)
    if len(m) == 0:
        # Not every bani repeats a line verbatim -- Tav Prasad Savaiye and
        # Ardas do not -- and a check with nothing to measure is not a failed
        # check. It drops out of the verdict rather than voting against it.
        print("\nsame line, different occurrence: none -- this bani repeats no "
              "line verbatim, so this check does not apply")
        checks = [pauses_ok] + ([anchors_ok] if anchors_ok is not None else [])
        print(f"\nverdict: {'ALIGNED' if all(checks) else 'NEEDS A LISTEN'}"
              " (on pauses" + (" and anchors" if anchors_ok is not None else "")
              + " alone)")
        return 0 if all(checks) else 1
    print(f"\nsame line, different occurrence  (n={len(m):>3}): "
          f"mean {m.mean():.4f}  median {np.median(m):.4f}")
    print(f"different lines (control)        (n={len(c):>3}): "
          f"mean {c.mean():.4f}  median {np.median(c):.4f}")

    sep = (c.mean() - m.mean()) / c.std()
    print(f"\nseparation: {sep:.2f} standard deviations of the control spread")
    overlap = float((m > np.percentile(c, 5)).mean())
    print(f"matched pairs above the control 5th percentile: {overlap*100:.0f}%")

    print("\nper repeat group (lower is a tighter acoustic match):")
    for text, dists in sorted(per_group, key=lambda kv: -np.mean(kv[1]) if kv[1] else 0):
        if not dists:
            continue
        print(f"  {np.mean(dists):.4f}  x{len(dists)+1 if len(dists)<3 else 4}  {text[:46]}")

    repeats_ok = sep > 2.0 and m.mean() < c.mean() * 0.75
    print(f"\nrepeated lines: {'consistent' if repeats_ok else 'WEAK'}")

    checks = [pauses_ok, repeats_ok]
    if anchors_ok is not None:
        checks.append(anchors_ok)
    print(f"\nverdict: {'ALIGNED' if all(checks) else 'NEEDS A LISTEN'}")
    return 0 if all(checks) else 1


if __name__ == "__main__":
    sys.exit(main())
