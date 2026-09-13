#!/usr/bin/env python3
"""Measure the shape of a Naam Simran recitation, so the app can breathe with it.

The Simran ring is a standing wave: each Waheguru feeds a harmonic into it and
the wave settles back between utterances (PRD 1.13, Design 21). Android gives
no way to read the audio as it plays -- there is no visualiser on the player
the app uses -- so the shape is measured here, once, and shipped alongside the
recording.

Two things come out of it:

* **an envelope**, the loudness of the recitation 25 times a second, which the
  ring uses for its breath and ਵਾਹਿਗੁਰੂ for its fade;
* **onsets**, the moment each Waheguru begins, which is what actually pumps the
  wave. A bloom in the app is a real utterance, not a timer.

It reads the *shipped* .m4a rather than the master, so what was measured is
exactly what will play.

Usage:
    python3 tools/audio_pipeline/simran_envelope.py naam-simran
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
AUDIO = os.path.join(ROOT, "assets", "audio")
OUT_DIR = os.path.join(ROOT, "content", "source", "simran")

SR = 16000
RATE_HZ = 25          # envelope samples per second: 40 ms, finer than the eye needs
ONSET_LEVEL = 0.55    # of the recording's own range
MIN_GAP_S = 0.40      # two Waheguru cannot begin closer together than this


def envelope(path: str) -> tuple[np.ndarray, float]:
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "a.wav")
        subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", path,
             "-ac", "1", "-ar", str(SR), "-c:a", "pcm_s16le", "-y", wav],
            check=True,
        )
        with wave.open(wav) as w:
            x = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16)
    x = x.astype(np.float32) / 32768.0
    seconds = len(x) / SR
    hop = SR // RATE_HZ
    frames = x[: len(x) // hop * hop].reshape(-1, hop)
    db = 20 * np.log10(np.sqrt((frames ** 2).mean(axis=1)) + 1e-12)
    # Scaled to the recording's own quiet and loud, so a differently mastered
    # recitation still spans 0..1 rather than sitting in a corner of the range.
    lo, hi = np.percentile(db, 3), np.percentile(db, 99)
    return np.clip((db - lo) / max(hi - lo, 1e-6), 0, 1), seconds


def onsets_of(env: np.ndarray) -> list[int]:
    """Where each utterance starts, in milliseconds.

    A rise through the level, not a peak: the wave should be fed as the voice
    arrives, not once it is already loud.
    """
    out: list[int] = []
    last = -MIN_GAP_S * 2
    for i in range(1, len(env)):
        if env[i] > ONSET_LEVEL >= env[i - 1]:
            t = i / RATE_HZ
            if t - last >= MIN_GAP_S:
                out.append(int(round(t * 1000)))
                last = t
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("track", help="track slug, e.g. naam-simran")
    args = ap.parse_args()

    audio = os.path.join(AUDIO, f"{args.track}.m4a")
    if not os.path.exists(audio):
        raise SystemExit(f"missing {audio}: run build_audio.py first")

    env, seconds = envelope(audio)
    onsets = onsets_of(env)
    doc = {
        "track": args.track,
        "file": f"{args.track}.m4a",
        "durationMs": int(round(seconds * 1000)),
        "rateHz": RATE_HZ,
        "method": "RMS envelope of the shipped m4a, onsets on the rise",
        "envelope": base64.b64encode((env * 255).astype(np.uint8).tobytes()).decode(),
        "onsets": onsets,
    }

    os.makedirs(OUT_DIR, exist_ok=True)
    out = os.path.join(OUT_DIR, f"{args.track}.json")
    with open(out, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, ensure_ascii=False, separators=(",", ":"))
        fh.write("\n")
    print(f"wrote {os.path.relpath(out, ROOT)}")
    print(f"  {seconds:.1f}s, {len(env)} envelope samples at {RATE_HZ} Hz")
    print(f"  {len(onsets)} utterances, {len(onsets) / (seconds / 60):.0f} per minute")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
