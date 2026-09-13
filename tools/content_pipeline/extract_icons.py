#!/usr/bin/env python3
"""Re-extract lib/core/theme/icon_data.dart from the design HTML.

The design files are the source of truth for the icon set (tokens.json ->
icons: "SVG paths in design/html"). Run this after the designs change.
"""
import json
import os
import re
import glob

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
# Order matters: it is the descending frequency order the names were assigned in.
NAMES = ["bell", "chevronRight", "book", "sunArc", "calendar", "simranDots", "clock",
         "play", "pause", "sliders", "check", "chevronLeft", "prev", "replay10",
         "forward10", "next", "sunset", "headphones", "download", "globe", "eye",
         "sparkle", "share", "moon", "pin", "lock", "help", "speed", "close",
         "chevronDown", "cardLines", "endOfBani", "phone", "noSound", "arrowUp",
         "dots", "copy", "flag"]


def main() -> None:
    counts: dict[str, int] = {}
    for f in sorted(glob.glob(os.path.join(ROOT, "design", "html", "*.html"))):
        html = open(f, encoding="utf-8").read()
        for m in re.finditer(r'<svg class="i"[^>]*viewBox="0 0 24 24"[^>]*>(.*?)</svg>', html, re.S):
            inner = re.sub(r"\s+", " ", m.group(1)).strip()
            counts[inner] = counts.get(inner, 0) + 1
    ordered = sorted(counts, key=lambda k: -counts[k])
    if len(ordered) != len(NAMES):
        raise SystemExit(f"icon count changed: {len(ordered)} found, {len(NAMES)} named")
    print(json.dumps(dict(zip(NAMES, ordered)), ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
