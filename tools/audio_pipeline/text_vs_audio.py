#!/usr/bin/env python3
"""Does the text carry more than the recitation says, and where?

The aligner cannot refuse. Given a text and a recording it will always produce
a mapping, so text the reciter never says does not announce itself -- it gets
absorbed, and the reader's highlight runs ahead of the voice from that point
on. That is what eight of these recitations did, and neither the pause check
nor an anchor at the first line could see it.

This looks at the one thing the two sides can be compared on without trusting
the alignment: how often the reciter stops for breath, against how many lines
the timing file puts in the same stretch. The reciter's phrasing rate is
roughly constant through a bani -- it comes from the recording's energy and
nothing else -- so where the line count climbs against a flat pause count, the
text is being packed in, and something in it is not being recited.

It says where to listen. It cannot say which lines, and it is noisy for a bani
whose lines vary a lot in length (Jaap Sahib), so read the shape, not a single
window.

Usage:
    python3 tools/audio_pipeline/text_vs_audio.py chaupai-sahib
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import tempfile

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import forced_align as fa  # noqa: E402

ROOT = fa.ROOT
AUDIO = os.path.join(ROOT, "assets", "audio")

# A breath between phrases, not the gap between two words.
PHRASE_PAUSE_S = 0.35


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("bani", nargs="+", help="bani slug, e.g. chaupai-sahib")
    ap.add_argument("--window", type=float, default=30.0, help="seconds per row")
    args = ap.parse_args()

    for slug in args.bani:
        with tempfile.TemporaryDirectory() as tmp:
            wav = os.path.join(tmp, "a.wav")
            fa.decode(os.path.join(AUDIO, f"{slug}.m4a"), wav)
            pauses, _, _ = fa.find_pauses(wav)

        lead, _ = fa.audio_start_for(slug)
        starts = np.array([a + lead for a, b in pauses if b - a >= PHRASE_PAUSE_S])
        path = os.path.join(fa.TIMINGS_DIR, f"{slug}.json")
        with open(path, encoding="utf-8") as fh:
            lines = json.load(fh)["lines"]
        line_s = np.array([l["s"] / 1000 for l in lines])

        rows = []
        end = max(line_s[-1], starts[-1] if len(starts) else 0.0)
        for t in np.arange(0, end, args.window):
            p = int(((starts >= t) & (starts < t + args.window)).sum())
            n = int(((line_s >= t) & (line_s < t + args.window)).sum())
            if n:
                rows.append((t, p, n, p / n))
        if not rows:
            print(f"{slug}: no timings to read")
            continue

        med = float(np.median([r[3] for r in rows]))
        print(f"\n{slug}: {med:.2f} phrase pauses per line is typical here, "
              f"{args.window:.0f}s windows")
        for t, p, n, r in rows:
            flag = "  <<< listen here" if r < med * 0.6 else ""
            print(f"  {int(t) // 60:3d}:{int(t) % 60:02d}  pauses {p:3d}  "
                  f"lines {n:3d}  {r:5.2f}{flag}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
