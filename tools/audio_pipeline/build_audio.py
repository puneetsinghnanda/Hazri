#!/usr/bin/env python3
"""Convert a recitation master into the file the app ships.

Per the PRD (§8): mono AAC in an .m4a container, 64 kbps, loudness-normalised
to -16 LUFS, no music. The master stays out of the repository -- it lives on a
GitHub release -- and only this output is committed.

Usage:
    python3 tools/audio_pipeline/build_audio.py japji-sahib
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "audio", "source")
# Sideloaded builds read from here. A Play build moves these into the
# nitnem_audio asset pack instead; the app looks in both.
OUT = os.path.join(ROOT, "assets", "audio")

TARGET_LUFS = -16.0
TARGET_TRUE_PEAK = -1.5
TARGET_LRA = 11.0
BITRATE = "64k"


def measure(path: str) -> dict:
    """First pass: measure loudness so the second pass can correct it exactly."""
    proc = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", path,
         "-af", f"loudnorm=I={TARGET_LUFS}:TP={TARGET_TRUE_PEAK}:LRA={TARGET_LRA}:print_format=json",
         "-f", "null", "-"],
        capture_output=True, text=True, check=True,
    )
    text = proc.stderr
    start = text.rindex("{")
    return json.loads(text[start:text.rindex("}") + 1])


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("bani")
    ap.add_argument("--source", help="override the master path")
    args = ap.parse_args()

    src = args.source or os.path.join(SRC, f"{args.bani}.mp3")
    if not os.path.exists(src):
        raise SystemExit(f"missing master: {src}")
    os.makedirs(OUT, exist_ok=True)
    dst = os.path.join(OUT, f"{args.bani}.m4a")

    print(f"measuring {os.path.basename(src)} ...")
    m = measure(src)
    print(f"  input: {float(m['input_i']):.1f} LUFS, true peak {float(m['input_tp']):.1f} dBTP")

    # Two-pass loudnorm: linear correction, so the dynamics of the recitation
    # are preserved rather than compressed.
    loudnorm = (
        f"loudnorm=I={TARGET_LUFS}:TP={TARGET_TRUE_PEAK}:LRA={TARGET_LRA}"
        f":measured_I={m['input_i']}:measured_TP={m['input_tp']}"
        f":measured_LRA={m['input_lra']}:measured_thresh={m['input_thresh']}"
        f":offset={m['target_offset']}:linear=true:print_format=summary"
    )

    print("encoding mono AAC 64 kbps ...")
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", src,
         "-af", loudnorm, "-ac", "1", "-ar", "44100",
         "-c:a", "aac", "-b:a", BITRATE, "-movflags", "+faststart",
         "-map_metadata", "-1", "-y", dst],
        check=True,
    )

    size = os.path.getsize(dst)
    after = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", dst,
         "-af", "ebur128=framelog=quiet", "-f", "null", "-"],
        capture_output=True, text=True, check=True,
    ).stderr
    integrated = next(
        (l.split(":")[1].strip() for l in after.splitlines() if l.strip().startswith("I:")),
        "?",
    )
    print(f"  wrote {dst}")
    print(f"  {size/1048576:.2f} MB, measured {integrated}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
