#!/usr/bin/env python3
"""Record that a person has listened to a bani's timings and accepted them.

The PRD wants a human to check an alignment before release (§8), and until now
`"verified": false` was the only answer the pipeline could give. This writes
down the check -- against a hash of the exact timings that were heard, so
re-aligning the bani drops it back to unverified by itself. Nobody's word gets
carried onto a file they never listened to.

Usage:
    python3 tools/audio_pipeline/mark_verified.py chaupai-sahib --by owner
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import forced_align as fa  # noqa: E402

NOTE = ("Alignments a person has listened to and accepted (PRD 8). `linesSha` "
        "is a hash of the exact timings they heard: re-align the bani and it "
        "stops matching, so the file goes back to unverified on its own.")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("bani", nargs="+")
    ap.add_argument("--by", default="owner", help="who listened")
    ap.add_argument("--note", default=None, help="what they said")
    args = ap.parse_args()

    store = {"_note": NOTE}
    if os.path.exists(fa.VERIFIED_FILE):
        with open(fa.VERIFIED_FILE, encoding="utf-8") as fh:
            store = json.load(fh)
        store["_note"] = NOTE

    for slug in args.bani:
        path = os.path.join(fa.TIMINGS_DIR, f"{slug}.json")
        with open(path, encoding="utf-8") as fh:
            doc = json.load(fh)
        entry = {
            "linesSha": fa.lines_sha(doc["lines"]),
            "checkedBy": args.by,
            "date": datetime.date.today().isoformat(),
        }
        if args.note:
            entry["note"] = args.note
        store[slug] = entry
        print(f"{slug}: recorded {entry['linesSha']} as checked by {args.by}")

    with open(fa.VERIFIED_FILE, "w", encoding="utf-8") as fh:
        json.dump(store, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
