#!/usr/bin/env python3
"""Render the app mark into the Android launcher icons.

The mark is the day arc: a navy semicircle over a horizon with a saffron sun
sitting on it (PRD §10). It is drawn here rather than shipped as artwork so the
legacy, adaptive and monochrome variants all come from one definition.
"""
import math
import os

from PIL import Image, ImageDraw

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RES = os.path.join(ROOT, "android", "app", "src", "main", "res")

BG = (244, 243, 248, 255)       # tokens: light.bg
NAVY = (38, 44, 99, 255)        # tokens: light.primary
KESRI = (217, 115, 13, 255)     # tokens: light.kesri

# Legacy launcher icons, per density.
LEGACY = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
# Adaptive foreground layers are 108dp with the middle 72dp safe.
ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}

SS = 4  # supersample factor


def draw_mark(size: int, *, inset: float, background: tuple | None,
              arc_colour: tuple, sun_colour: tuple) -> Image.Image:
    """Draws the mark on a `size` square, scaled to `inset` of the canvas."""
    s = size * SS
    img = Image.new("RGBA", (s, s), background or (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # The mark is authored on a 40x40 grid (see AppMark in the app).
    scale = s * inset / 40
    ox = oy = (s - 40 * scale) / 2

    def p(x: float, y: float) -> tuple[float, float]:
        return (ox + x * scale, oy + y * scale)

    stroke = max(1, round(2.4 * scale))

    # Sky arc: semicircle of radius 16 centred at (20, 27).
    box = [*p(4, 11), *p(36, 43)]
    d.arc(box, start=180, end=360, fill=arc_colour, width=stroke)

    # Sun: half-disc of radius 8 on the horizon.
    d.pieslice([*p(12, 19), *p(28, 35)], start=180, end=360, fill=sun_colour)

    # Horizon.
    d.line([p(6, 31.5), p(34, 31.5)], fill=arc_colour, width=stroke)

    return img.resize((size, size), Image.LANCZOS)


def round_corners(img: Image.Image, radius_ratio: float = 0.5) -> Image.Image:
    """Legacy icons are not masked by the launcher, so give them a circle."""
    mask = Image.new("L", (img.width * SS, img.height * SS), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, mask.width - 1, mask.height - 1], fill=255)
    mask = mask.resize(img.size, Image.LANCZOS)
    out = Image.new("RGBA", img.size, (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def main() -> None:
    for density, size in LEGACY.items():
        folder = os.path.join(RES, f"mipmap-{density}")
        os.makedirs(folder, exist_ok=True)
        icon = round_corners(
            draw_mark(size, inset=0.72, background=BG, arc_colour=NAVY, sun_colour=KESRI)
        )
        icon.save(os.path.join(folder, "ic_launcher.png"))

        # The adaptive foreground keeps the mark inside the 72/108 safe zone.
        fg_size = ADAPTIVE[density]
        fg_folder = os.path.join(RES, f"drawable-{density}")
        os.makedirs(fg_folder, exist_ok=True)
        draw_mark(
            fg_size, inset=0.46, background=None, arc_colour=NAVY, sun_colour=KESRI
        ).save(os.path.join(fg_folder, "ic_launcher_foreground.png"))
        # Android 13 themed icons need a single-colour layer.
        draw_mark(
            fg_size,
            inset=0.46,
            background=None,
            arc_colour=(0, 0, 0, 255),
            sun_colour=(0, 0, 0, 255),
        ).save(os.path.join(fg_folder, "ic_launcher_monochrome.png"))

    # The media-notification icon: Android renders it as a white silhouette on
    # a transparent ground, at 24dp.
    NOTIF = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72, "xxxhdpi": 96}
    for density, size in NOTIF.items():
        folder = os.path.join(RES, f"drawable-{density}")
        os.makedirs(folder, exist_ok=True)
        draw_mark(
            size,
            inset=0.92,
            background=None,
            arc_colour=(255, 255, 255, 255),
            sun_colour=(255, 255, 255, 255),
        ).save(os.path.join(folder, "ic_notification.png"))

    # The splash mark, used by the launch theme.
    splash = os.path.join(RES, "drawable-xxhdpi")
    os.makedirs(splash, exist_ok=True)
    draw_mark(
        288, inset=0.8, background=None, arc_colour=(243, 239, 230, 255), sun_colour=(242, 162, 78, 255)
    ).save(os.path.join(splash, "splash_mark.png"))

    print("icons written")


if __name__ == "__main__":
    main()
