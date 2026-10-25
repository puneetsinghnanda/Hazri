#!/usr/bin/env python3
"""Turns the owner's saakhi images and narration into app assets.

    python3 tools/saakhi/build_assets.py [<bundle-dir>]

<bundle-dir> (default `saakhi-handoff/`) holds `images/<id>/cover, p1 ... p8`
and `audio/<id>.<lang>.mp3`, as supplied by the owner (13-saakhi.md §6). For
every saakhi in content/source/saakhi/ this writes

    assets/saakhi/<id>/cover.webp, p1.webp ...   900 px wide, the phone's size
    assets/saakhi/<id>.<lang>.m4a                 mono AAC, 48 kbps

so the APK carries a few megabytes rather than the masters' forty-odd. The
masters themselves are not app assets (SK13). Needs Pillow and ffmpeg.
"""
import json
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "content" / "source" / "saakhi"
OUT = ROOT / "assets" / "saakhi"
WIDTH = 900


def image(src: Path, dst: Path) -> None:
    im = Image.open(src).convert("RGB")
    im = im.resize((WIDTH, round(im.height * WIDTH / im.width)), Image.LANCZOS)
    im.save(dst, "WEBP", quality=78, method=6)


def audio(src: Path, dst: Path) -> None:
    subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(src), "-vn", "-ac", "1",
                    "-c:a", "aac", "-b:a", "48k", "-movflags", "+faststart", str(dst)], check=True)


def main() -> int:
    bundle = Path(sys.argv[1]) if len(sys.argv) > 1 else ROOT / "saakhi-handoff"
    for path in sorted(SOURCE.glob("*.json")):
        s = json.loads(path.read_text(encoding="utf-8"))
        sid = s["id"]
        (OUT / sid).mkdir(parents=True, exist_ok=True)
        keys = ["cover"] + [p["image"] for p in s["pages"]] + [s["lesson"]["image"]]
        for key in dict.fromkeys(keys):
            found = sorted((bundle / "images" / sid).glob(f"{key}.*"))
            if not found:
                raise SystemExit(f"{sid}: no image {key} in {bundle / 'images' / sid}")
            image(found[0], OUT / sid / f"{key}.webp")
        for lang, narr in (s.get("narration") or {}).items():
            if not isinstance(narr, dict) or not narr.get("file"):
                continue
            src = bundle / "audio" / narr["file"]
            if not src.exists():
                raise SystemExit(f"{sid}: no narration {src}")
            audio(src, OUT / f"{sid}.{lang}.m4a")
        print(sid, "done")
    return 0


if __name__ == "__main__":
    sys.exit(main())
