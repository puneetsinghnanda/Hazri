#!/usr/bin/env python3
"""Build the page for correcting a bani's line timings by ear.

The aligner gets most lines right and is honest about which ones it is least
sure of, but the PRD requires a person to have heard the timings before they
ship (PRD §8). This puts the recitation next to the text in a browser so that
can be done in one sitting: play, and tap as each line begins.

It writes a single HTML file that reads the audio from `assets/audio/`, so it
has to be served rather than opened from disk:

    python3 tools/timing_tool/build.py japji-sahib
    python3 -m http.server 8000          # from the repository root
    # then open http://localhost:8000/tools/timing_tool/japji-sahib.html

Corrections are kept in the browser as they are made, so the page can be
reloaded without losing them. "Save file" gives back the whole timing file to
put in `content/source/timings/`, after which `build_content_db.py` folds it
into the app.
"""
from __future__ import annotations

import argparse
import json
import os
import sqlite3
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
HERE = os.path.dirname(os.path.abspath(__file__))
CONTENT_DB = os.path.join(ROOT, "assets", "content", "content.db")
TIMINGS_DIR = os.path.join(ROOT, "content", "source", "timings")

# How many lines to mark for a listen. The pace estimate below is a weak
# signal, so this is a reading order, not a verdict: every line still wants
# hearing before the file can be called verified.
FLAG_COUNT = 24


def line_text(version_id: str) -> list[str]:
    con = sqlite3.connect(f"file:{CONTENT_DB}?mode=ro", uri=True)
    rows = con.execute(
        "SELECT idx, gurmukhi FROM line WHERE bani_version_id = ? ORDER BY idx",
        (version_id,),
    ).fetchall()
    con.close()
    return [g for _, g in rows]


def flagged(lines: list[dict]) -> list[int]:
    """The lines whose pace is least like the rest of the recitation.

    A line the reciter spent far more or far less time on than its share of the
    words is where a missed boundary shows up, so those are worth hearing
    first. Word count stands in for how long a line should take; the aligner's
    own measure is better but is not in the file.
    """
    paces = []
    for l in lines:
        words = max(len(l.get("w") or []), 1)
        paces.append((l["e"] - l["s"]) / words)
    middle = sorted(paces)[len(paces) // 2] or 1.0
    stray = sorted(range(len(lines)), key=lambda i: -abs(paces[i] / middle - 1))
    return sorted(lines[i]["line"] for i in stray[:FLAG_COUNT])


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("bani", help="bani slug, e.g. japji-sahib")
    args = ap.parse_args()

    timings_path = os.path.join(TIMINGS_DIR, f"{args.bani}.json")
    if not os.path.exists(timings_path):
        raise SystemExit(f"no timings for '{args.bani}': run forced_align.py first")
    with open(timings_path, encoding="utf-8") as fh:
        timings = json.load(fh)

    audio = f"../../assets/audio/{args.bani}.m4a"
    if not os.path.exists(os.path.join(ROOT, "assets", "audio", f"{args.bani}.m4a")):
        print(f"warning: assets/audio/{args.bani}.m4a is missing; "
              "the page will load but play nothing", file=sys.stderr)

    data = {
        "slug": args.bani,
        "audio": audio,
        "timings": timings,
        "text": line_text(timings["baniVersionId"]),
        "flagged": flagged(timings["lines"]),
        "out": os.path.relpath(timings_path, ROOT),
    }
    if len(data["text"]) != len(timings["lines"]):
        raise SystemExit(
            f"content.db has {len(data['text'])} lines but the timing file has "
            f"{len(timings['lines'])}; rebuild one of them")

    with open(os.path.join(HERE, "page.html"), encoding="utf-8") as fh:
        page = fh.read()
    out = os.path.join(HERE, f"{args.bani}.html")
    with open(out, "w", encoding="utf-8") as fh:
        fh.write(page.replace("__DATA__", json.dumps(data, ensure_ascii=False)))

    print(f"wrote {os.path.relpath(out, ROOT)}  "
          f"({len(timings['lines'])} lines, {len(data['flagged'])} flagged)")
    print("serve the repository root and open "
          f"http://localhost:8000/tools/timing_tool/{args.bani}.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
