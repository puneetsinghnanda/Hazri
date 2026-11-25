#!/usr/bin/env python3
"""Builds the live sangat loops in assets/live/ (15-live-sangat LS6).

Each loop is a recording whose end is crossfaded into its own start, baked
into the file: for a recording x of length L and a crossfade of C seconds,
the loop is x[C:L] with its last C seconds mixed (equal power) with x[0:C].
Played on repeat it never jumps: after its end comes x[C], which is what
follows x[0:C] in the recording. Nothing is added and nothing of the
recitation is cut but the silence the recording ends with.

    python3 tools/live/build_loops.py <masters dir>

The masters are the owner's (2026-11-18) and are not in git:
  naam-simran-live.mp3  Waheguru_Naam_Simran.mp3  ends in a fade and 2.6 s of silence
  mool-mantra.mp3       Mool_Mantra_Final.mp3     full level at both ends
and Chaupai Sahib's loop is made from the bundled assets/audio/chaupai-sahib.ogg.
"""
import os
import subprocess

import numpy as np
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "live")

# id: (source, start, end or None for the whole, crossfade seconds, AAC kbit/s)
LOOPS = {
    # Silence from 59.03 s; the fade-out before it overlaps the opening.
    "naam-simran": ("{m}/naam-simran-live.mp3", 0.0, 59.0, 3.0, 48),
    # Cut mid-flow at both ends: a longer crossfade hides the seam.
    "mool-mantar": ("{m}/mool-mantra.mp3", 0.0, None, 4.0, 48),
    # The bundled recitation: half a second of quiet before it starts, and
    # a fade at the end.
    "chaupai-sahib": (os.path.join(ROOT, "assets/audio/chaupai-sahib.ogg"), 0.45, 211.0, 2.5, 48),
}


def duration(path: str) -> float:
    return float(subprocess.check_output(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path]).strip())


RATE = 48000


def decode(path: str) -> "np.ndarray":
    """The whole recording, mono, at 48 kHz, as floats: one decode, so every
    cut below is to the sample (two ffmpeg inputs seeked separately into an
    MP3 were not, and left a click at the repeat, 2026-11-19)."""
    raw = subprocess.run(
        ["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"],
        capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)


def build(name: str, src: str, start: float, end: float | None, fade: float, kbps: int) -> None:
    x = decode(src)
    s = int(round(start * RATE))
    e = len(x) if end is None else int(round(end * RATE))
    c = int(round(fade * RATE))
    body = x[s + c:e].copy()
    # Equal power: the body's last C samples fade out as the opening's first
    # C fade in. The loop's last sample is then x[s + c - 1] and its first
    # x[s + c], so on repeat it runs on as the recording does.
    t = (np.arange(c) + 0.5) / c
    body[-c:] = body[-c:] * np.cos(t * np.pi / 2) + x[s:s + c] * np.sin(t * np.pi / 2)
    out = os.path.join(OUT, f"{name}.ogg")
    for old in (os.path.join(OUT, f"{name}.m4a"),):
        if os.path.exists(old):
            os.remove(old)
    # Mono Opus, as the recitations (owner, 2026-11-19): one voice, so
    # stereo only doubled the size.
    subprocess.run(
        ["ffmpeg", "-v", "error", "-y", "-f", "f32le", "-ar", str(RATE), "-ac", "1", "-i", "-",
         "-c:a", "libopus", "-b:a", f"{kbps}k", "-application", "audio", "-map_metadata", "-1", out],
        input=body.astype(np.float32).tobytes(), check=True)
    print(f"{name}: {len(body) / RATE * 1000:.2f} ms ({len(body)} samples), {os.path.getsize(out) // 1024} KB, "
          f"repeat step {abs(body[0] - body[-1]):.4f}")


def main() -> int:
    # The masters are on the audio-masters release (audio/README.md), fetched
    # into audio/source/ like the recitations' masters.
    masters = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "audio", "source")
    os.makedirs(OUT, exist_ok=True)
    for name, (src, start, end, fade, kbps) in LOOPS.items():
        build(name, src.format(m=masters), start, end, fade, kbps)
    return 0


if __name__ == "__main__":
    sys.exit(main())
