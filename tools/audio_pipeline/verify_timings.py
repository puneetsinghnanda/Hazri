#!/usr/bin/env python3
"""Check an aligned timing file against the recording itself.

Alignment quality cannot be judged from the timings alone, so this measures it
acoustically. Japji Sahib repeats eight lines verbatim -- "ਆਦੇਸੁ ਤਿਸੈ ਆਦੇਸੁ ॥"
four times, and so on. If the alignment is tracking the recitation, the audio
under two occurrences of the same line should sound nearly the same, while the
audio under two unrelated lines should not.

The test compares log-mel spectra with dynamic time warping, and reports the
separation between matched pairs (same text) and control pairs (different
text). A large separation means the spans really do sit on the words they
claim to.

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

    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "a.wav")
        subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", audio,
             "-ac", "1", "-ar", str(RATE), "-c:a", "pcm_s16le", "-y", wav],
            check=True,
        )
        feats = log_mel(wav)

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
    print(f"bani: {args.bani}   lines: {len(rows)}   repeat groups: {len(repeats)}")
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

    verdict = "ALIGNED" if sep > 2.0 and m.mean() < c.mean() * 0.75 else "WEAK"
    print(f"\nverdict: {verdict}")
    return 0 if verdict == "ALIGNED" else 1


if __name__ == "__main__":
    sys.exit(main())
