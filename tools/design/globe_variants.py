#!/usr/bin/env python3
"""Six ways the Global Simran globe could look, side by side.

The globe is the one screen in Phase 2 with no precedent in the app, so it is
worth choosing rather than accepting. Every variant draws the same data --
Natural Earth's 110m coastline, bundled at 17 KB, and one dot per person --
and differs only in how it is painted. All six are plain geometry: no map
tiles, no network, no dependency, and each is a CustomPainter.

    python3 tools/design/globe_variants.py
"""
from __future__ import annotations

import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "design", "html")
WORLD = json.load(open(os.path.join(ROOT, "design", "world-110m.json")))["rings"]

import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_phase2 import PEOPLE, HEAD, TAIL, css_vars  # noqa: E402

LAT0, LON0 = 22.0, 52.0
R = 150.0
C = 160.0
SIZE = 320


def project(lat, lon, lat0=LAT0, lon0=LON0, r=R, c=C):
    p, l, p0 = math.radians(lat), math.radians(lon - lon0), math.radians(lat0)
    if math.sin(p0) * math.sin(p) + math.cos(p0) * math.cos(p) * math.cos(l) <= 0:
        return None
    return (c + r * math.cos(p) * math.sin(l),
            c - r * (math.cos(p0) * math.sin(p) - math.sin(p0) * math.cos(p) * math.cos(l)))


def runs(points):
    out, run = [], []
    for p in points:
        if p is None:
            if len(run) > 1:
                out.append(run)
            run = []
        else:
            run.append(p)
    if len(run) > 1:
        out.append(run)
    return out


def land_paths(fill: str, stroke: str | None = None, sw: float = 0.8) -> str:
    """The coastline, culled to the visible hemisphere."""
    out = []
    for ring in WORLD:
        for r in runs([project(lat, lon) for lon, lat in ring]):
            d = "M" + "L".join(f"{x:.1f} {y:.1f}" for x, y in r) + "Z"
            out.append(f'<path d="{d}" fill="{fill}"'
                       + (f' stroke="{stroke}" stroke-width="{sw}"' if stroke else "")
                       + ' stroke-linejoin="round"/>')
    return "".join(out)


def graticule(colour: str, opacity: float = 0.5, sw: float = 0.7) -> str:
    out = []
    for lon in range(-180, 180, 30):
        for r in runs([project(lat, lon) for lat in range(-90, 91, 3)]):
            out.append(f'<polyline points="{" ".join(f"{x:.1f},{y:.1f}" for x, y in r)}"'
                       f' fill="none" stroke="{colour}" stroke-width="{sw}"'
                       f' opacity="{opacity}"/>')
    for lat in range(-60, 61, 30):
        for r in runs([project(lat, lon) for lon in range(-180, 181, 3)]):
            out.append(f'<polyline points="{" ".join(f"{x:.1f},{y:.1f}" for x, y in r)}"'
                       f' fill="none" stroke="{colour}" stroke-width="{sw}"'
                       f' opacity="{opacity}"/>')
    return "".join(out)


DOTS = {"you": ("#F2A24E", 5.0), "member": ("#5B8DEF", 3.0), "today": ("#3DBE7B", 3.4)}


def dots(glow: bool = True, scale: float = 1.0) -> str:
    out = []
    for lat, lon, kind in PEOPLE:
        p = project(lat, lon)
        if p is None:
            continue
        colour, rad = DOTS[kind]
        x, y = p
        rad *= scale
        if kind == "you":
            out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="14" fill="{colour}" '
                       f'opacity="0.16"/><circle cx="{x:.1f}" cy="{y:.1f}" r="8.5" '
                       f'fill="{colour}" opacity="0.3"/>')
        elif glow:
            out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rad*2.4:.1f}" '
                       f'fill="{colour}" opacity="0.18"/>')
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rad:.1f}" fill="{colour}"/>')
    return "".join(out)


def svg(inner: str, size: int = SIZE) -> str:
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 320 320" '
            f'style="display:block">{inner}</svg>')


# ------------------------------------------------------------- the variants

def v_night() -> str:
    """A: night earth. Land raised out of a dark ocean."""
    return svg(
        '<defs><radialGradient id="oc" cx="34%" cy="28%">'
        '<stop offset="0%" stop-color="#1A2350"/><stop offset="72%" stop-color="#0D1430"/>'
        '<stop offset="100%" stop-color="#070A1A"/></radialGradient></defs>'
        f'<circle cx="160" cy="160" r="150" fill="url(#oc)"/>'
        f'{graticule("#33427A", 0.45)}'
        f'{land_paths("#27407A")}'
        f'<circle cx="160" cy="160" r="150" fill="none" stroke="#46589A" '
        f'stroke-width="1.1" opacity="0.85"/>{dots()}')


def v_terminator() -> str:
    """B: the day/night line, because Amrit Vela is a time as well as a place."""
    band = []
    # A soft shadow over the western half, drawn as a clipped ellipse.
    band.append('<defs><clipPath id="sph"><circle cx="160" cy="160" r="150"/>'
                '</clipPath><linearGradient id="nite" x1="0" x2="1">'
                '<stop offset="0%" stop-color="#000" stop-opacity="0.62"/>'
                '<stop offset="46%" stop-color="#000" stop-opacity="0.34"/>'
                '<stop offset="62%" stop-color="#000" stop-opacity="0"/>'
                '</linearGradient>'
                '<radialGradient id="oc2" cx="34%" cy="28%">'
                '<stop offset="0%" stop-color="#1E2A5E"/>'
                '<stop offset="72%" stop-color="#0F1738"/>'
                '<stop offset="100%" stop-color="#070A1A"/></radialGradient></defs>')
    return svg(
        "".join(band)
        + '<circle cx="160" cy="160" r="150" fill="url(#oc2)"/>'
        + graticule("#3A4A86", 0.4)
        + land_paths("#2B4785")
        + '<g clip-path="url(#sph)"><rect x="10" y="10" width="300" height="300" '
          'fill="url(#nite)"/></g>'
        + '<circle cx="160" cy="160" r="150" fill="none" stroke="#4E62A8" '
          'stroke-width="1.1" opacity="0.8"/>'
        + dots())


def v_halftone() -> str:
    """C: the land as a dot matrix, the way a printed globe reads."""
    grid = []
    for lat in range(-84, 85, 4):
        step = max(4, int(4 / max(0.18, math.cos(math.radians(lat)))))
        for lon in range(-180, 180, step):
            p = project(lat, lon)
            if p is None:
                continue
            if not on_land(lat, lon):
                continue
            x, y = p
            # Fade towards the limb so the sphere reads as a sphere.
            d = math.hypot(x - 160, y - 160) / 150
            grid.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="1.7" fill="#4E6BC4" '
                        f'opacity="{0.95 - 0.55*d*d:.2f}"/>')
    return svg(
        '<circle cx="160" cy="160" r="150" fill="#0A0F26"/>'
        + "".join(grid)
        + '<circle cx="160" cy="160" r="150" fill="none" stroke="#2C3A6E" '
          'stroke-width="1"/>'
        + dots())


_LAND_CACHE: dict[tuple[int, int], bool] = {}


def on_land(lat: float, lon: float) -> bool:
    key = (int(lat), int(lon))
    if key in _LAND_CACHE:
        return _LAND_CACHE[key]
    hit = False
    for ring in WORLD:
        inside = False
        j = len(ring) - 1
        for i, (x1, y1) in enumerate(ring):
            x2, y2 = ring[j]
            if (y1 > lat) != (y2 > lat) and \
                    lon < (x2 - x1) * (lat - y1) / ((y2 - y1) or 1e-9) + x1:
                inside = not inside
            j = i
        if inside:
            hit = True
            break
    _LAND_CACHE[key] = hit
    return hit


def v_wire() -> str:
    """D: outline only, with a thread from your dot to everyone else's."""
    me = next(p for p in PEOPLE if p[2] == "you")
    origin = project(me[0], me[1])
    threads = []
    for lat, lon, kind in PEOPLE:
        if kind == "you":
            continue
        p = project(lat, lon)
        if p is None or origin is None:
            continue
        # A gentle arc, bowed away from the straight line.
        mx, my = (origin[0] + p[0]) / 2, (origin[1] + p[1]) / 2
        dx, dy = p[0] - origin[0], p[1] - origin[1]
        bow = 0.14
        cx, cy = mx - dy * bow, my + dx * bow
        threads.append(f'<path d="M{origin[0]:.1f} {origin[1]:.1f} '
                       f'Q{cx:.1f} {cy:.1f} {p[0]:.1f} {p[1]:.1f}" fill="none" '
                       f'stroke="#F2A24E" stroke-width="0.7" opacity="0.28"/>')
    return svg(
        '<circle cx="160" cy="160" r="150" fill="#080B1C"/>'
        + graticule("#243057", 0.9, 0.6)
        + land_paths("none", "#41609E", 1.0)
        + "".join(threads)
        + '<circle cx="160" cy="160" r="150" fill="none" stroke="#33427A" '
          'stroke-width="1"/>'
        + dots(glow=False))


def v_light() -> str:
    """E: a globe that belongs in the light theme rather than a dark hole."""
    return svg(
        '<defs><radialGradient id="lo" cx="34%" cy="28%">'
        '<stop offset="0%" stop-color="#FFFFFF"/>'
        '<stop offset="68%" stop-color="#E7EBF7"/>'
        '<stop offset="100%" stop-color="#CFD6EA"/></radialGradient></defs>'
        '<circle cx="160" cy="160" r="150" fill="url(#lo)"/>'
        + graticule("#A9B4D4", 0.7, 0.6)
        + land_paths("#F3E4CE", "#D9C4A3", 0.8)
        + '<circle cx="160" cy="160" r="150" fill="none" stroke="#B3BDD8" '
          'stroke-width="1.2"/>'
        + dots(glow=False))


def v_flat() -> str:
    """F: no hidden hemisphere. Everybody at once, nothing to rotate."""
    w, h = 320, 170
    ox, oy = 0, 75

    def flat(lat, lon):
        return ox + (lon + 180) / 360 * w, oy + (90 - lat) / 180 * h

    land = []
    for ring in WORLD:
        pts = [flat(lat, lon) for lon, lat in ring]
        land.append('<path d="M' + "L".join(f"{x:.1f} {y:.1f}" for x, y in pts)
                    + 'Z" fill="#27407A"/>')
    grid = []
    for lon in range(-180, 181, 30):
        x, _ = flat(0, lon)
        grid.append(f'<line x1="{x:.1f}" y1="{oy}" x2="{x:.1f}" y2="{oy+h}" '
                    f'stroke="#33427A" stroke-width="0.6" opacity="0.5"/>')
    for lat in range(-60, 61, 30):
        _, y = flat(lat, 0)
        grid.append(f'<line x1="{ox}" y1="{y:.1f}" x2="{ox+w}" y2="{y:.1f}" '
                    f'stroke="#33427A" stroke-width="0.6" opacity="0.5"/>')
    pins = []
    for lat, lon, kind in PEOPLE:
        x, y = flat(lat, lon)
        colour, rad = DOTS[kind]
        if kind == "you":
            pins.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="12" fill="{colour}" '
                        f'opacity="0.18"/>')
        pins.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{rad:.1f}" fill="{colour}"/>')
    return svg(f'<rect x="{ox}" y="{oy}" width="{w}" height="{h}" rx="14" '
               f'fill="#0D1430"/>' + "".join(grid + land + pins))


VARIANTS = [
    ("A", "Night earth", "Land lifted out of a dark ocean. Closest to what a "
     "globe looks like at night, and the dots sit on top of it.", v_night),
    ("B", "Day and night", "The same, with the terminator drawn. Amrit Vela is "
     "a time as well as a place, and this shows where it is dark right now.",
     v_terminator),
    ("C", "Halftone", "The land as a dot matrix. The whole picture is made of "
     "the same mark a person is, which reads as one sangat.", v_halftone),
    ("D", "Threads", "Outline only, with a thread from your dot to every other. "
     "Says connection rather than geography.", v_wire),
    ("E", "Daylight", "A globe for the light theme. The others are a dark hole "
     "in a pale screen.", v_light),
    ("F", "Flat map", "No hidden hemisphere and nothing to rotate. Everybody is "
     "visible at once, on a screen this small.", v_flat),
]


def main() -> int:
    cards = ""
    for key, name, why, fn in VARIANTS:
        cards += (
            f'<div style="display:flex;flex-direction:column;gap:10px;width:340px">'
            f'<div style="display:flex;align-items:baseline;gap:8px">'
            f'<div style="font-size:13px;font-weight:700;color:var(--kesri)">{key}</div>'
            f'<div class="disp" style="font-size:19px;font-weight:700">{name}</div>'
            f'</div>'
            f'<div style="background:var(--card);border-radius:22px;padding:10px;'
            f'box-shadow:var(--shadow);display:flex;justify-content:center">'
            f'{fn()}</div>'
            f'<div style="font-size:12.5px;color:var(--muted);line-height:1.5">'
            f'{why}</div></div>')
    page = (HEAD.format(title="Globe variants", light=css_vars("light"),
                        dark=css_vars("dark"), cls="light")
            .replace('width:390px;height:844px;', 'width:1140px;min-height:100px;')
            .replace('overflow:hidden;', '')
            + f'<div style="padding:26px 24px;display:flex;flex-wrap:wrap;gap:26px">'
              f'{cards}</div>' + TAIL)
    path = os.path.join(OUT, "28-GlobeVariants.html")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(page)
    print(f"wrote {os.path.relpath(path, ROOT)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
