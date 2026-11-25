#!/usr/bin/env python3
"""Convert a recitation master into the file the app ships.

Mono Opus in an Ogg container, 48 kbps, loudness-normalised to -16 LUFS, no
music (owner, 2026-11-19: Opus 48k chosen by ear over 32k and 64k; it
replaced AAC 64k, a quarter smaller and no worse). A recitation listed in
`downloads.json` is written to `public/audio/` and downloaded by the app once
(PRD §8); every other one ships in the APK under `assets/audio/`. The master stays out of the repository -- it lives on a
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
OUT = os.path.join(ROOT, "assets", "audio")
# Recitations the app downloads once rather than ships (Firebase Hosting).
DOWNLOAD_OUT = os.path.join(ROOT, "public", "audio")
DOWNLOADS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "downloads.json")

TARGET_LUFS = -16.0
TARGET_TRUE_PEAK = -1.5
TARGET_LRA = 11.0
BITRATE = "48k"
EXT = "ogg"


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
    ap.add_argument(
        "--seconds", type=float,
        help="ship only the first N seconds. The Naam Simran master runs 16 "
             "minutes and the session is 5, so shipping all of it would put "
             "megabytes of unplayed audio in every install.")
    ap.add_argument(
        "--fade", type=float, default=0.0,
        help="fade the last N seconds out. A cut taken on the clock lands "
             "wherever the reciter happens to be; a fade ends the recitation "
             "rather than interrupting it. Only meaningful with --seconds.")
    args = ap.parse_args()

    src = args.source or os.path.join(SRC, f"{args.bani}.mp3")
    if not os.path.exists(src):
        raise SystemExit(f"missing master: {src}")
    with open(DOWNLOADS, encoding="utf-8") as fh:
        downloaded = set(json.load(fh)["downloads"])
    out = DOWNLOAD_OUT if args.bani in downloaded else OUT
    os.makedirs(out, exist_ok=True)
    dst = os.path.join(out, f"{args.bani}.{EXT}")
    # One home per recitation: an older build of it in the other place goes.
    for old in (os.path.join(OUT, f"{args.bani}.m4a"), os.path.join(OUT, f"{args.bani}.{EXT}"),
                os.path.join(DOWNLOAD_OUT, f"{args.bani}.{EXT}")):
        if old != dst and os.path.exists(old):
            os.remove(old)

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

    trim = ["-t", str(args.seconds)] if args.seconds else []
    if args.fade and args.seconds:
        # After loudnorm, so the fade is the last thing the ear hears and the
        # measured loudness still describes the body of the recitation.
        fade = f",afade=t=out:st={args.seconds - args.fade}:d={args.fade}"
    else:
        fade = ""
    print(f"encoding mono Opus {BITRATE}"
          + (f", first {args.seconds:.0f}s" if args.seconds else "")
          + (f", {args.fade:.0f}s fade" if fade else "") + " ...")
    subprocess.run(
        ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", src, *trim,
         "-af", loudnorm + fade, "-ac", "1", "-ar", "48000",
         "-c:a", "libopus", "-b:a", BITRATE, "-application", "audio",
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
