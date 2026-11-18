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
  naam-simran.mp3   Waheguru_Naam_Simran.mp3   ends in a fade and 2.6 s of silence
  mool-mantar.mp3   Mool_Mantra_Final.mp3      full level at both ends
and Chaupai Sahib's loop is made from the bundled assets/audio/chaupai-sahib.m4a.
"""
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "live")

# id: (source, start, end or None for the whole, crossfade seconds, AAC kbit/s)
LOOPS = {
    # Silence from 59.03 s; the fade-out before it overlaps the opening.
    "naam-simran": ("{m}/naam-simran.mp3", 0.0, 59.0, 3.0, 128),
    # Cut mid-flow at both ends: a longer crossfade hides the seam.
    "mool-mantar": ("{m}/mool-mantar.mp3", 0.0, None, 4.0, 128),
    # The bundled recitation: half a second of quiet before it starts, and
    # a fade at the end.
    # Its source is already ~66 kbit/s AAC, so nothing is gained above 80.
    "chaupai-sahib": (os.path.join(ROOT, "assets/audio/chaupai-sahib.m4a"), 0.45, 211.0, 2.5, 80),
}


def duration(path: str) -> float:
    return float(subprocess.check_output(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path]).strip())


def build(name: str, src: str, start: float, end: float | None, fade: float, kbps: int) -> None:
    end = end if end is not None else duration(src)
    out = os.path.join(OUT, f"{name}.m4a")
    # The body (x[C:L]) and the opening (x[0:C]) are read as two inputs, and
    # acrossfade overlaps the body's last C seconds with the opening.
    subprocess.check_call([
        "ffmpeg", "-v", "error", "-y",
        "-ss", f"{start + fade}", "-to", f"{end}", "-i", src,
        "-ss", f"{start}", "-to", f"{start + fade}", "-i", src,
        "-filter_complex", f"[0:a][1:a]acrossfade=d={fade}:c1=qsin:c2=qsin,aresample=44100[o]",
        "-map", "[o]", "-ac", "2", "-c:a", "aac", "-b:a", f"{kbps}k", "-map_metadata", "-1", "-vn", out])
    print(f"{name}: {duration(out):.2f} s, {os.path.getsize(out) // 1024} KB")


def main() -> int:
    masters = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "live-masters")
    os.makedirs(OUT, exist_ok=True)
    for name, (src, start, end, fade, kbps) in LOOPS.items():
        build(name, src.format(m=masters), start, end, fade, kbps)
    return 0


if __name__ == "__main__":
    sys.exit(main())
