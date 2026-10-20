#!/usr/bin/env python3
"""Build a playable preview of a saakhi from the approved reader design.

    python3 tools/design/build_saakhi_preview.py <images-dir> <narration.mp3> <out.html>

<images-dir> holds cover, p1 ... p8 (png, jpg or webp). The images and the
recording are embedded, so the one HTML file plays on a phone with no network
(Google Fonts aside). Neither the images nor the audio are kept in git
(docs/features/13-saakhi.md SK13).
"""
import base64
import io
import json
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "design" / "saakhi" / "reader.template.html"
KEYS = ["cover"] + [f"p{i}" for i in range(1, 9)]


def image_uri(path: Path) -> str:
    im = Image.open(path).convert("RGB")
    w = 780
    im = im.resize((w, round(im.height * w / im.width)), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=78, optimize=True, progressive=True)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def audio_uri(path: Path) -> str:
    # Mono 64 kbps keeps a two-minute narration near 1 MB.
    with tempfile.TemporaryDirectory() as tmp:
        out = Path(tmp) / "n.mp3"
        subprocess.run(["ffmpeg", "-loglevel", "error", "-y", "-i", str(path),
                        "-vn", "-ac", "1", "-b:a", "64k", str(out)], check=True)
        data = out.read_bytes()
    return "data:audio/mpeg;base64," + base64.b64encode(data).decode()


def main() -> None:
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    images, audio, out = Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3])
    found = {}
    for key in KEYS:
        match = sorted(p for p in images.iterdir() if p.stem == key)
        if not match:
            sys.exit(f"missing image: {key} in {images}")
        found[key] = image_uri(match[0])
    html = TEMPLATE.read_text()
    html = html.replace("__IMGS__", json.dumps(found)).replace("__NARR__", audio_uri(audio))
    out.write_text(html)
    print(f"wrote {out} ({out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
