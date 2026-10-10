"""Draws assets/images/media_art.png, the artwork on the playback notification
and the lock screen (design 18): the Hazri sunrise mark on Neela.

    python3 tools/design/build_media_art.py

The geometry is the launcher icon's, scaled to a 512 px square; Android crops
media artwork to a square or a circle, so the mark sits well inside the edge.
"""
from pathlib import Path

from PIL import Image, ImageDraw

SIZE = 512
NEELA = (0x26, 0x2C, 0x63, 255)
WHITE = (255, 255, 255, 255)
KESRI = (0xF2, 0xA2, 0x4E, 255)
SCALE = 4  # drawn large and reduced, for smooth edges


def main() -> None:
    s = SIZE * SCALE
    img = Image.new('RGBA', (s, s), NEELA)
    d = ImageDraw.Draw(img)
    cx, base = s / 2, s * 0.60
    r_arc, w_arc = s * 0.27, s * 0.045
    # The arc: the upper half of a ring.
    d.arc([cx - r_arc, base - r_arc, cx + r_arc, base + r_arc], 180, 360, fill=WHITE, width=int(w_arc))
    # The sun: a half disc on the horizon.
    r_sun = s * 0.14
    d.pieslice([cx - r_sun, base - r_sun, cx + r_sun, base + r_sun], 180, 360, fill=KESRI)
    # The horizon.
    half, h = s * 0.30, s * 0.042
    d.rounded_rectangle([cx - half, base + s * 0.035, cx + half, base + s * 0.035 + h], radius=h / 2, fill=WHITE)
    out = Path(__file__).resolve().parents[2] / 'assets/images/media_art.png'
    img.resize((SIZE, SIZE), Image.LANCZOS).save(out, optimize=True)
    print(out)


if __name__ == '__main__':
    main()
