#!/usr/bin/env python3
"""Build a playable preview of a saakhi from the approved reader design.

    python3 tools/design/build_saakhi_preview.py <saakhi.json> <images-dir> <out.html> [--audio <narration.mp3>]

<saakhi.json> is a file in content/source/saakhi/. <images-dir> holds cover,
p1 ... p8 (png, jpg or webp); an image the saakhi marks "missing" may be
absent, and the page before it stands in. The images and the recording are
embedded, so the one HTML file plays on a phone with no network (Google Fonts
aside). Neither is kept in git (docs/features/13-saakhi.md SK13).

Gurbani a saakhi refers to by {"ref": {"bani", "id"}} is read from that
bani's source file here, never copied into the saakhi (SK3).
"""
import argparse
import base64
import io
import json
import subprocess
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "design" / "saakhi" / "reader.template.html"
SOURCE = ROOT / "content" / "source"

FLAGS = [  # (words in an image status, flag class, label)
    ("figure", "f-fig", "Guru as figure"),
    ("meat", "f-meat", "Meat"),
    ("title painted", "f-txt", "Title in image"),
    ("missing", "f-txt", "Missing"),
]


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


def bani_line(ref: dict, sources: dict) -> dict:
    """One line of a bani, with its Ang and the meanings named by source."""
    bani = json.loads((SOURCE / f"{ref['bani']}.json").read_text())
    line = next(l for l in bani["lines"] if l["id"] == ref["id"])
    meanings = {}
    for lang, key in (("en", "english"), ("pa", "punjabi")):
        for variant in (key, f"{key}_alt"):
            m = (line.get("meaning") or {}).get(variant)
            if m and m.get("source") == sources.get(lang):
                meanings[lang] = m["text"]
    return {"lines": [line["text"]["gurmukhi_plain"]],
            "ang": line["scripture"]["page"], "meaning": meanings}


def note(status: str) -> str:
    flags = "".join(f'<span class="flag {cls}">{label}</span>'
                    for word, cls, label in FLAGS if word in status)
    if status == "ok":
        flags = '<span class="flag f-ok">Good</span>'
    return flags + status


def view_model(s: dict) -> dict:
    images = s["images"]
    shabad = None
    if s.get("shabad"):
        sh = s["shabad"]
        if "ref" in sh:
            shabad = bani_line(sh["ref"], sh["meaning_sources"])
        else:
            shabad = {"lines": sh["gurmukhi"], "ang": sh["ang"], "meaning": sh["meaning"]}
        shabad["source"] = sh["source"]
    pages = []
    for p in s["pages"]:
        page = {"k": p["image"], "t": p["title"], "en": p["text"]["en"],
                "pa": p["text"]["pa"], "note": note(images[p["image"]]["status"])}
        if p.get("gurbani"):
            g = p["gurbani"]
            page["gb"] = bani_line(g["ref"], s["shabad"]["meaning_sources"])
        pages.append(page)
    narr = s["narration"]["en"]
    return {
        "id": s["id"], "title": s["title"], "subtitle": s["subtitle"], "blurb": s["blurb"],
        "pages": pages,
        "lesson": {"k": s["lesson"]["image"], "t": s["lesson"]["title"],
                   "line": s["lesson"]["line"], "ask": s["lesson"]["ask"],
                   "note": note(images[s["lesson"]["image"]]["status"])},
        "coverNote": note(images["cover"]["status"]),
        "coverHasTitle": bool(images["cover"].get("title_in_image")),
        "shabad": shabad,
        "narration": narr and {k: narr[k] for k in ("page_starts", "meaning_at", "duration")},
    }


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("saakhi", type=Path)
    ap.add_argument("images", type=Path)
    ap.add_argument("out", type=Path)
    ap.add_argument("--audio", type=Path)
    a = ap.parse_args()
    s = json.loads(a.saakhi.read_text())
    if a.audio and not s["narration"]["en"]:
        ap.error(f"{a.saakhi.name} has no narration.en page_starts yet")
    keys = ["cover"] + [p["image"] for p in s["pages"]] + [s["lesson"]["image"]]
    found, last = {}, None
    for key in keys:
        match = sorted(p for p in a.images.iterdir() if p.stem == key)
        if match:
            found[key] = last = image_uri(match[0])
        elif "missing" in s["images"][key]["status"] and last:
            found[key] = last
        else:
            raise SystemExit(f"missing image: {key} in {a.images}")
    html = TEMPLATE.read_text()
    html = (html.replace("__IMGS__", json.dumps(found))
                .replace("__SAAKHI__", json.dumps(view_model(s), ensure_ascii=False))
                .replace("__NARR__", audio_uri(a.audio) if a.audio else ""))
    a.out.write_text(html)
    print(f"wrote {a.out} ({a.out.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
