#!/usr/bin/env python3
"""Emits the Phase 2 design specs into design/html/.

The Phase 1 files are 390 x 844 CSS px = 390 x 844 dp, self-contained, with
the tokens inlined as CSS variables. These match, because they are read the
same way: a visual spec to build Flutter widgets from, not code to port.

Written as a generator rather than by hand because every screen shares the
same chrome -- head, tokens, bottom bar -- and a light and a dark file differ
only by one class. Two files that are meant to be identical apart from a theme
should not be able to drift.

    python3 tools/design/build_phase2.py
"""
from __future__ import annotations

import json
import math
import os

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "design", "html")
TOKENS = os.path.join(ROOT, "design", "tokens.json")

with open(TOKENS, encoding="utf-8") as fh:
    T = json.load(fh)["color"]


def css_vars(theme: str) -> str:
    return "".join(f"--{k}:{v};" for k, v in T[theme].items() if k != "shadow") + \
        f"--shadow:{T[theme]['shadow']};"


HEAD = """<!doctype html>
<html><head><meta charset="utf-8"><title>{title}</title>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+Paaji+2:wght@500;600;700&amp;family=Mukta:wght@400;500;600;700&amp;family=Noto+Serif+Gurmukhi:wght@400;500;600;700&amp;family=Noto+Serif+Devanagari:wght@400;500;600&amp;display=swap">
  <style>
body{{margin:0;background:#888}}
.app{{{light}
  width:390px;height:844px;background:var(--bg);color:var(--ink);font-family:Mukta,'Noto Sans Devanagari',system-ui,sans-serif;position:relative;overflow:hidden;box-sizing:border-box;font-size:15px;line-height:1.45}}
.app.dark{{{dark}}}
.app *{{box-sizing:border-box}}
.gur{{font-family:'Noto Serif Gurmukhi','Noto Sans Gurmukhi',serif}}
.dev{{font-family:'Noto Serif Devanagari','Noto Sans Devanagari',serif}}
.disp{{font-family:'Baloo Paaji 2',Mukta,system-ui,sans-serif}}
.card{{background:var(--card);border-radius:20px;box-shadow:var(--shadow)}}
.eyebrow{{font-size:12px;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);font-weight:600}}
svg.i{{stroke:currentColor;fill:none;stroke-width:1.8;stroke-linecap:round;stroke-linejoin:round;flex:none;display:block}}
.btn{{display:flex;align-items:center;justify-content:center;gap:10px;border-radius:16px;min-height:52px;font-weight:600;font-size:16px}}
.chip{{display:inline-flex;align-items:center;gap:6px;border-radius:999px;padding:6px 12px;font-size:13px;font-weight:600}}
.row{{display:flex;align-items:center}}
.col{{display:flex;flex-direction:column}}
.pad{{padding:22px 20px 0}}
</style></head><body>
<div class="app {cls}">
"""

TAIL = "</div>\n</body></html>\n"

ICONS = {
    "today": '<path d="M3 18h18"/><path d="M7 18a5 5 0 0 1 10 0"/><path d="M12 5v3M5.2 9.2l1.8 1.8M18.8 9.2L17 11M3 14h1.5M19.5 14H21"/>',
    "nitnem": '<path d="M12 6.5C10.5 5.2 8 4.5 4 4.5v13c4 0 6.5.7 8 2 1.5-1.3 4-2 8-2v-13c-4 0-6.5.7-8 2z"/><path d="M12 6.5v13"/>',
    "simran": '<circle cx="12" cy="12" r="3.2"/><circle cx="12" cy="3.8" r="1.4" fill="currentColor"/><circle cx="17.8" cy="6.2" r="1.4" fill="currentColor"/><circle cx="20.2" cy="12" r="1.4" fill="currentColor"/><circle cx="17.8" cy="17.8" r="1.4" fill="currentColor"/><circle cx="12" cy="20.2" r="1.4" fill="currentColor"/><circle cx="6.2" cy="17.8" r="1.4" fill="currentColor"/><circle cx="3.8" cy="12" r="1.4" fill="currentColor"/><circle cx="6.2" cy="6.2" r="1.4" fill="currentColor"/>',
    "diary": '<rect x="3.5" y="5" width="17" height="15.5" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4"/>',
    "sangat": '<circle cx="9" cy="9" r="3.2"/><path d="M3.5 19.5a5.5 5.5 0 0 1 11 0"/><circle cx="17" cy="7.5" r="2.4"/><path d="M15.5 13.2a4.6 4.6 0 0 1 5 4.6"/>',
    "back": '<path d="M15 5l-7 7 7 7"/>',
    "menu": '<path d="M4 7h16M4 12h16M4 17h16"/>',
    "globe": '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.4 2.4 3.6 5.3 3.6 8.5s-1.2 6.1-3.6 8.5c-2.4-2.4-3.6-5.3-3.6-8.5S9.6 5.9 12 3.5z"/>',
    "check": '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    "plus": '<path d="M12 5v14M5 12h14"/>',
    "bell": '<path d="M6.5 10a5.5 5.5 0 0 1 11 0c0 4 1.5 5.5 1.5 5.5H5S6.5 14 6.5 10z"/><path d="M10 18.5a2 2 0 0 0 4 0"/>',
    "sparkle": '<path d="M12 3.5v4M12 16.5v4M3.5 12h4M16.5 12h4"/><circle cx="12" cy="12" r="3.1"/>',
    "search": '<circle cx="10.8" cy="10.8" r="6.3"/><path d="M15.4 15.4L20 20"/>',
    "pin": '<path d="M12 21s6.5-6 6.5-10.5a6.5 6.5 0 1 0-13 0C5.5 15 12 21 12 21z"/><circle cx="12" cy="10.3" r="2.4"/>',
    "flag": '<path d="M6 21V4.5M6 5h11l-2 3.5L17 12H6"/>',
    "play": '<path d="M8 5.5l10 6.5-10 6.5z"/>',
    "mail": '<rect x="3" y="5.5" width="18" height="13" rx="3"/><path d="M4 8l8 5.5L20 8"/>',
    "alert": '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5v5.5"/><circle cx="12" cy="16.3" r=".9" fill="currentColor" stroke="none"/>',
    "clock": '<circle cx="12" cy="12" r="8.5"/><path d="M12 7v5.2l3.4 2"/>',
    "phone": '<rect x="6.5" y="2.5" width="11" height="19" rx="3"/><path d="M10.5 18.6h3"/>',
    "share": '<circle cx="17" cy="6" r="2.4"/><circle cx="7" cy="12" r="2.4"/><circle cx="17" cy="18" r="2.4"/><path d="M9.2 10.9l5.6-3.3M9.2 13.1l5.6 3.3"/>',
}


def icon(name: str, size: int = 22) -> str:
    return (f'<svg class="i" width="{size}" height="{size}" viewBox="0 0 24 24">'
            f'{ICONS[name]}</svg>')


# The words on a screen, in the reader\'s language. Everything already in
# `lib/core/l10n/app_pa.arb` or the content database is taken from there
# rather than written again here; the handful of Phase 2 strings that do not
# exist yet are marked, because they are mine and want a native ear.
EN = {
    "nav": ["Today", "Nitnem", "Simran", "Sangat", "Diary"],
    "today": "Today", "date": "Friday, 20 November",
    "goals": "Your goals", "goalsDone": "1 of 3 done",
    "japji": "Japji Sahib", "simran": "Simran", "rehras": "Rehras Sahib",
    "japjiAt": "5:30 AM", "simranAt": "11 min", "rehrasAt": "6:40 PM",
    "start": "Start Nitnem",
    "gurpurabWhen": "IN 4 DAYS · GURPURAB",
    "gurpurab": "Prakash Purab, Guru Nanak Dev Ji",
    "vichar": "Today\u2019s Vichar", "vicharSource": "Sri Guru Granth Sahib Ji",
    "meaning": "Humility is sweetness, and it is the essence of true goodness.",
    "explore": "Explore", "share": "Share",
    # new in Phase 2
    "hazriMarked": "Today\u2019s hazri is marked",
    "hazriPending": "Today\u2019s hazri is not marked yet",
    "hazriWith": "Marked at 5:52 AM, with Japji Sahib",
    "hazriHow": "One paath, or one sitting of simran, marks it",
    "cls": "",
    "days": "days",
    "goalsAllDone": "All of today’s goals are done",
    "hazriWas": "Your hazri was marked at 5:52 AM, with Japji Sahib",
    "inPresence": "Read in the presence of Sri Guru Granth Sahib Ji",
    "streak": "11 days in a row", "gentle": "a gentle streak",
    "seeDiary": "See my diary", "done": "Done",
}
PA = {
    "nav": ["ਅੱਜ", "ਨਿਤਨੇਮ", "ਸਿਮਰਨ", "ਸੰਗਤ", "ਡਾਇਰੀ"],
    "today": "ਅੱਜ", "date": "ਸ਼ੁੱਕਰਵਾਰ, 20 ਨਵੰਬਰ",
    "goals": "ਮੇਰੇ ਸੰਕਲਪ", "goalsDone": "3 ਵਿੱਚੋਂ 1 ਅੱਜ ਪੂਰੇ",
    "japji": "ਜਪੁ ਜੀ ਸਾਹਿਬ", "simran": "ਸਿਮਰਨ", "rehras": "ਰਹਰਾਸਿ ਸਾਹਿਬ",
    "japjiAt": "5:30 AM", "simranAt": "11 ਮਿੰਟ", "rehrasAt": "6:40 PM",
    "start": "ਨਿਤਨੇਮ ਸ਼ੁਰੂ ਕਰੋ",
    "gurpurabWhen": "4 ਦਿਨਾਂ ਵਿੱਚ · ਗੁਰਪੁਰਬ",
    "gurpurab": "ਪ੍ਰਕਾਸ਼ ਪੁਰਬ, ਗੁਰੂ ਨਾਨਕ ਦੇਵ ਜੀ",
    "vichar": "ਅੱਜ ਦਾ ਵਿਚਾਰ", "vicharSource": "ਸ੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ",
    "meaning": "ਨਿਮਰਤਾ ਮਿੱਠਾਸ ਦਾ ਮੂਲ ਹੈ ਅਤੇ ਇਹੀ ਅਸਲ ਚੰਗਿਆਈਆਂ ਦਾ ਸਾਰ ਹੈ।",
    "explore": "ਹੋਰ ਵੇਖੋ", "share": "ਸਾਂਝਾ ਕਰੋ",
    # new in Phase 2
    "hazriMarked": "ਅੱਜ ਦੀ ਹਾਜ਼ਰੀ ਲੱਗ ਗਈ",
    "hazriPending": "ਅੱਜ ਦੀ ਹਾਜ਼ਰੀ ਬਾਕੀ ਹੈ",
    "hazriWith": "5:52 AM ਉੱਤੇ, ਜਪੁ ਜੀ ਸਾਹਿਬ ਨਾਲ",
    "hazriHow": "ਇੱਕ ਪਾਠ, ਜਾਂ ਇੱਕ ਵਾਰ ਦਾ ਸਿਮਰਨ, ਇਸ ਨੂੰ ਲਾ ਦਿੰਦਾ ਹੈ",
    "cls": "gur",
    "days": "ਦਿਨ",
    "goalsAllDone": "ਅੱਜ ਦੇ ਸਾਰੇ ਸੰਕਲਪ ਪੂਰੇ",
    "hazriWas": "ਅੱਜ ਦੀ ਹਾਜ਼ਰੀ 5:52 AM ਉੱਤੇ ਲੱਗੀ, ਜਪੁ ਜੀ ਸਾਹਿਬ ਨਾਲ",
    "inPresence": "ਸ੍ਰੀ ਗੁਰੂ ਗ੍ਰੰਥ ਸਾਹਿਬ ਜੀ ਦੀ ਹਜ਼ੂਰੀ ਵਿੱਚ",
    "streak": "ਲਗਾਤਾਰ 11 ਦਿਨ", "gentle": "ਇੱਕ ਨਰਮ ਲੜੀ",
    "seeDiary": "ਮੇਰੀ ਡਾਇਰੀ ਵੇਖੋ", "done": "ਹੋ ਗਿਆ",
}


def nav(active: str, t: dict = EN) -> str:
    """The bottom bar. Settings has left it; Sangat has taken the slot."""
    tabs = list(zip(["today", "nitnem", "simran", "sangat", "diary"], t["nav"]))
    out = ('<div style="position:absolute;left:0;right:0;bottom:0;background:var(--card);'
           'border-top:1px solid var(--rule);display:flex;padding:10px 4px 22px">')
    for key, label in tabs:
        on = key == active
        pill = ('background:var(--kesriSoft);color:var(--kesriInk)' if on
                else 'color:var(--muted)')
        text = ('font-weight:700;color:var(--ink)' if on
                else 'font-weight:500;color:var(--muted)')
        out += (f'<div class="col" style="align-items:center;gap:4px;flex:1">'
                f'<div style="width:58px;height:32px;border-radius:16px;display:flex;'
                f'align-items:center;justify-content:center;{pill}">{icon(key)}</div>'
                f'<div style="font-size:12px;{text}">{label}</div></div>')
    return out + "</div>"


# ---------------------------------------------------------------- the globe

# Where people are, as the design shows them: one dot per person, at their
# own location, which is what was asked for. Aggregating to a coarse cell is
# a change to `precision` in the payload rather than a change to this screen,
# so the decision stays reversible.
PEOPLE = [
    # (lat, lon, kind) - kind: you | member | today
    (31.63, 74.87, "you"),                                   # Amritsar
    (31.33, 75.58, "member"), (30.90, 75.85, "member"),      # Jalandhar, Ludhiana
    (30.73, 76.78, "today"), (31.52, 74.36, "member"),       # Chandigarh, Lahore
    (28.61, 77.21, "member"), (28.46, 77.03, "today"),       # Delhi, Gurugram
    (29.39, 76.97, "member"), (32.73, 74.86, "member"),
    (19.08, 72.88, "member"), (12.97, 77.59, "today"),       # Mumbai, Bengaluru
    (22.57, 88.36, "member"), (26.85, 80.95, "member"),
    (51.51, -0.38, "member"), (52.48, -1.90, "today"),       # Southall, Birmingham
    (53.80, -1.55, "member"), (55.86, -4.25, "member"),      # Leeds, Glasgow
    (45.46, 9.19, "member"), (52.37, 4.90, "member"),        # Milan, Amsterdam
    (48.86, 2.35, "today"), (50.11, 8.68, "member"),
    (25.20, 55.27, "member"), (24.47, 54.37, "today"),       # Dubai, Abu Dhabi
    (-1.29, 36.82, "member"), (1.35, 103.82, "member"),      # Nairobi, Singapore
    (13.76, 100.50, "today"), (3.14, 101.69, "member"),
    (-31.95, 115.86, "member"), (-37.81, 144.96, "today"),   # Perth, Melbourne
    (-33.87, 151.21, "member"), (35.68, 139.69, "member"),
    (43.65, -79.38, "member"), (49.28, -123.12, "today"),    # Toronto, Vancouver
    (37.34, -121.89, "member"), (40.71, -74.01, "member"),
    (34.05, -118.24, "member"), (41.88, -87.63, "today"),
]

LAT0, LON0 = 22.0, 52.0          # centred so India, the UK and Africa all show
R = 150.0
CX = CY = 160.0

# Natural Earth 110m land, public domain, simplified to what a 300 px globe can
# show. 17 KB, bundled, so the globe needs no tiles and no network.
with open(os.path.join(ROOT, "design", "world-110m.json"), encoding="utf-8") as _fh:
    WORLD = json.load(_fh)["rings"]


def project(lat: float, lon: float) -> tuple[float, float] | None:
    """Orthographic projection. None when the point is on the far side."""
    p, l = math.radians(lat), math.radians(lon - LON0)
    p0 = math.radians(LAT0)
    if math.sin(p0) * math.sin(p) + math.cos(p0) * math.cos(p) * math.cos(l) <= 0.02:
        return None
    x = R * math.cos(p) * math.sin(l)
    y = R * (math.cos(p0) * math.sin(p) - math.sin(p0) * math.cos(p) * math.cos(l))
    return CX + x, CY - y


def graticule() -> str:
    """Meridians and parallels, sampled and culled by the projection."""
    out = []
    for lon in range(-180, 180, 30):
        pts = [project(lat, lon) for lat in range(-90, 91, 3)]
        out.append(polyline(pts))
    for lat in range(-60, 61, 30):
        pts = [project(lat, lon) for lon in range(-180, 181, 3)]
        out.append(polyline(pts))
    return "".join(out)


def polyline(points) -> str:
    runs, run = [], []
    for p in points:
        if p is None:
            if len(run) > 1:
                runs.append(run)
            run = []
        else:
            run.append(p)
    if len(run) > 1:
        runs.append(run)
    return "".join(
        '<polyline points="{}" fill="none" stroke="#2A3A6B" stroke-width="0.8" '
        'opacity="0.55"/>'.format(
            " ".join(f"{x:.1f},{y:.1f}" for x, y in r))
        for r in runs)


DOT = {"you": ("#F2A24E", 5.0), "member": ("#5B8DEF", 3.0),
       "today": ("#3DBE7B", 3.4)}


def dots(glow: bool = True) -> str:
    out = []
    for lat, lon, kind in PEOPLE:
        p = project(lat, lon)
        if p is None:
            continue
        colour, r = DOT[kind]
        x, y = p
        if kind == "you":
            out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="13" fill="{colour}" '
                       f'opacity="0.18"/>')
            out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="8" fill="{colour}" '
                       f'opacity="0.30"/>')
        elif glow:
            out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r*2.4:.1f}" '
                       f'fill="{colour}" opacity="0.18"/>')
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{colour}"/>')
    return "".join(out)


def coastline() -> str:
    """The land, outlined, culled to the visible hemisphere."""
    out = []
    for ring in WORLD:
        for r in polyline_runs([project(lat, lon) for lon, lat in ring]):
            out.append('<path d="M' + "L".join(f"{x:.1f} {y:.1f}" for x, y in r)
                       + 'Z" fill="none" stroke="#41609E" stroke-width="1" '
                         'stroke-linejoin="round"/>')
    return "".join(out)


def polyline_runs(points):
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


def threads() -> str:
    """A thread from your dot to every other.

    This is the look chosen for the globe. It holds to a few hundred people
    and then turns off, leaving the dots alone -- but a Sangat group is never
    that large, so on a group's paath the threads always show.
    """
    me = next(p for p in PEOPLE if p[2] == "you")
    origin = project(me[0], me[1])
    if origin is None:
        return ""
    out = []
    for lat, lon, kind in PEOPLE:
        if kind == "you":
            continue
        p = project(lat, lon)
        if p is None:
            continue
        mx, my = (origin[0] + p[0]) / 2, (origin[1] + p[1]) / 2
        dx, dy = p[0] - origin[0], p[1] - origin[1]
        cx, cy = mx - dy * 0.14, my + dx * 0.14
        out.append(f'<path d="M{origin[0]:.1f} {origin[1]:.1f} Q{cx:.1f} {cy:.1f} '
                   f'{p[0]:.1f} {p[1]:.1f}" fill="none" stroke="#F2A24E" '
                   f'stroke-width="0.7" opacity="0.28"/>')
    return "".join(out)


def globe(size: int = 320) -> str:
    return (
        f'<svg width="{size}" height="{size}" viewBox="0 0 320 320" '
        f'style="display:block">'
        f'<circle cx="160" cy="160" r="150" fill="#080B1C"/>'
        f'{graticule()}{coastline()}{threads()}'
        f'<circle cx="160" cy="160" r="150" fill="none" stroke="#33427A" '
        f'stroke-width="1"/>'
        f'{dots(glow=False)}</svg>')


def legend() -> str:
    items = [("var(--kesri)", "You"), ("#5B8DEF", "Sangat worldwide"),
             ("#3DBE7B", "Joined today")]
    return ('<div class="row" style="gap:14px;justify-content:center;flex-wrap:wrap">'
            + "".join(
                f'<div class="row" style="gap:6px"><div style="width:9px;height:9px;'
                f'border-radius:5px;background:{c}"></div>'
                f'<div style="font-size:12px;color:var(--muted);font-weight:600">'
                f'{t}</div></div>' for c, t in items) + "</div>")


def avatar(initials: str, colour: str = "var(--card2)", ink: str = "var(--ink2)",
           size: int = 34) -> str:
    return (f'<div style="width:{size}px;height:{size}px;border-radius:{size // 2}px;'
            f'background:{colour};color:{ink};display:flex;align-items:center;'
            f'justify-content:center;font-size:{size // 3}px;font-weight:700;'
            f'flex:none">{initials}</div>')


def ring(pct: float, size: int, stroke: int, colour: str = "var(--kesri)",
         track: str = "var(--rule)") -> str:
    r = (size - stroke) / 2
    c = 2 * math.pi * r
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 {size} {size}" '
            f'style="display:block;transform:rotate(-90deg)">'
            f'<circle cx="{size/2}" cy="{size/2}" r="{r}" fill="none" '
            f'stroke="{track}" stroke-width="{stroke}"/>'
            f'<circle cx="{size/2}" cy="{size/2}" r="{r}" fill="none" '
            f'stroke="{colour}" stroke-width="{stroke}" stroke-linecap="round" '
            f'stroke-dasharray="{c*pct:.1f} {c:.1f}"/></svg>')


def header(title: str, sub: str | None = None, left: str = "back",
           right: str | None = None) -> str:
    r = (f'<div style="width:44px;height:44px;border-radius:14px;display:flex;'
         f'align-items:center;justify-content:center;background:var(--card);'
         f'box-shadow:var(--shadow)">{icon(right)}</div>' if right else
         '<div style="width:44px"></div>')
    return (f'<div class="row" style="justify-content:space-between;gap:10px">'
            f'<div class="row" style="gap:10px">'
            f'<div style="width:40px;height:40px;border-radius:13px;display:flex;'
            f'align-items:center;justify-content:center;background:var(--card);'
            f'box-shadow:var(--shadow)">{icon(left, 20)}</div>'
            f'<div class="col"><div class="disp" style="font-size:24px;'
            f'font-weight:700;line-height:1.15">{title}</div>'
            + (f'<div style="font-size:12.5px;color:var(--muted);font-weight:500">'
               f'{sub}</div>' if sub else "")
            + f'</div></div>{r}</div>')


# ------------------------------------------------------------------ screens

def simran_tab() -> str:
    """The Simran tab: the sangat as a globe you turn with your hand.

    Full bleed, and dark in both themes -- the globe is the screen, not a
    picture on it, and a planetarium does not change colour with the room.

    **No names here, ever.** A dot says a person exists and whether they
    opened Hazri today; who they are is the group's business, and groups live
    in Sangat. Nothing on this screen identifies anybody but you.
    """
    return f"""
<div style="position:absolute;inset:0;background:#070A1A"></div>
<div style="position:absolute;left:50%;top:296px;transform:translate(-50%,-50%);
  width:520px;height:520px;display:flex;align-items:center;justify-content:center">
  {globe(520)}</div>
<div style="position:absolute;left:0;right:0;bottom:96px;height:300px;
  background:linear-gradient(to bottom,rgba(7,10,26,0),#070A1A 46%)"></div>
<div style="position:absolute;inset:0;display:flex;flex-direction:column;
  padding:22px 20px 0">
  <div class="row" style="justify-content:space-between">
    <div style="width:40px;height:40px;border-radius:13px;display:flex;
      align-items:center;justify-content:center;background:rgba(255,255,255,.09);
      color:#fff">{icon("menu", 20)}</div>
    <div class="col" style="align-items:center">
      <div class="disp" style="font-size:22px;font-weight:700;color:#fff">Simran</div>
      <div style="font-size:11.5px;color:rgba(255,255,255,.6);font-weight:600">
        Turn the globe with your hand</div>
    </div>
    <div style="width:40px;height:40px;border-radius:13px;display:flex;
      align-items:center;justify-content:center;background:rgba(255,255,255,.09);
      color:#fff">{icon("bell", 20)}</div>
  </div>
  <div style="flex:1"></div>
  <div class="col" style="gap:14px;padding-bottom:110px">
    <div class="col" style="align-items:center;gap:7px;padding:0 10px">
      <div class="disp" style="font-size:25px;font-weight:700;color:#fff;
        line-height:1.3;text-align:center">
        You and <span style="color:#6FE3A6">47 others</span><br>are here today</div>
      <div style="font-size:12.5px;color:rgba(255,255,255,.66);font-weight:600">
        2,140 paath this month · 9 countries</div>
    </div>
    <div class="row" style="gap:13px;justify-content:center;flex-wrap:wrap">
      <div class="row" style="gap:6px"><div style="width:8px;height:8px;
        border-radius:4px;background:#F2A24E"></div>
        <div style="font-size:11.5px;color:rgba(255,255,255,.72);font-weight:600">
          You</div></div>
      <div class="row" style="gap:6px"><div style="width:8px;height:8px;
        border-radius:4px;background:#5B8DEF"></div>
        <div style="font-size:11.5px;color:rgba(255,255,255,.72);font-weight:600">
          In the sangat</div></div>
      <div class="row" style="gap:6px"><div style="width:8px;height:8px;
        border-radius:4px;background:#3DBE7B"></div>
        <div style="font-size:11.5px;color:rgba(255,255,255,.72);font-weight:600">
          Here today</div></div>
    </div>
    <div class="btn" style="background:var(--kesri);color:#231104">
      {icon("simran", 20)}<div>Begin Simran · 11 min</div></div>
  </div>
</div>
{nav("simran")}
"""


def join_banner() -> str:
    """The orange banner for somebody who has not set up at all."""
    return f"""
  <div class="card col" style="padding:14px 16px;gap:10px;
    background:linear-gradient(135deg,var(--kesri),#B8560A);color:#fff">
    <div class="row" style="gap:10px">
      <div style="width:38px;height:38px;border-radius:19px;background:rgba(255,255,255,.18);
        display:flex;align-items:center;justify-content:center;flex:none">
        {icon("sangat", 20)}</div>
      <div class="col" style="flex:1">
        <div style="font-size:15px;font-weight:700">Join the sangat</div>
        <div style="font-size:12.5px;opacity:.9">
          See who is reciting with you, worldwide</div>
      </div>
    </div>
    <div class="row" style="justify-content:space-between;align-items:center">
      <div style="font-size:12px;opacity:.85">Takes a couple of seconds</div>
      <div class="chip" style="background:#fff;color:#9A4F00">Set up</div>
    </div>
  </div>"""


def hazri_banner(t: dict = EN) -> str:
    """Today, for somebody set up, whose hazri is marked.

    It stands where the join banner stands, and only once setup is done, so
    the screen never carries two banners. It says the day is marked and what
    marked it -- and deliberately nothing about goals, which are the card
    underneath and a different question: the hazri is one thing finished,
    the goal is all of them.
    """
    return f"""
  <div class="card row" style="padding:14px 16px;gap:13px;
    background:linear-gradient(135deg,var(--kesri),#B8560A);color:#fff">
    <div style="width:46px;height:46px;border-radius:23px;flex:none;
      background:rgba(255,255,255,.17);display:flex;align-items:center;
      justify-content:center">{app_mark(28, "#fff", "#fff")}</div>
    <div class="col" style="flex:1;gap:2px">
      <div class="disp" style="font-size:17px;font-weight:700">
        {t["hazriMarked"]}</div>
      <div class="{t['cls']}" style="font-size:12.5px;opacity:.9">{t["hazriWith"]}</div>
      <div class="{t['cls']}" style="font-size:12px;opacity:.78;font-weight:600;
        padding-top:3px">{t["streak"]}</div>
    </div>
    </div>
  </div>"""


def hazri_pending(t: dict = EN) -> str:
    """The same slot before anything is finished -- which is when most people
    open the app. Quiet, and it names the one thing that would mark it."""
    return f"""
  <div class="card row" style="padding:14px 16px;gap:13px;
    border:1px solid var(--rule)">
    <div style="width:46px;height:46px;border-radius:23px;flex:none;
      background:var(--card2);display:flex;align-items:center;
      justify-content:center">{app_mark(28, "var(--ink2)", "var(--muted)")}</div>
    <div class="col" style="flex:1;gap:2px">
      <div class="disp" style="font-size:17px;font-weight:700;color:var(--ink2)">
        {t["hazriPending"]}</div>
      <div class="{t['cls']}" style="font-size:12.5px;color:var(--muted)">
        {t["hazriHow"]}</div>
    </div>
  </div>"""


def today_hazri() -> str:
    return today(hazri_banner())


def today_not_yet() -> str:
    return today(hazri_pending())


def today_punjabi() -> str:
    """The same screen for a reader whose language is Punjabi.

    Almost every word here already exists: the interface strings come from
    `app_pa.arb`, the bani names from `content.db`, the Gurpurab from
    `calendar-names.json`, and the line with its meaning from entry 178 of
    the vichar dataset. Only the four Phase 2 hazri strings are new, and
    those are mine rather than anybody else\u2019s -- they want a native ear
    before they become ARB keys.
    """
    return today(hazri_banner(PA), PA)


def today(banner: str | None = None, t: dict = EN) -> str:
    goals = [(t["japji"], t["japjiAt"], 1.0), (t["simran"], t["simranAt"], 0.62),
             (t["rehras"], t["rehrasAt"], 0.0)]
    rows = "".join(
        f'<div class="row" style="gap:10px">'
        f'<div style="width:26px;height:26px;flex:none">{ring(p, 26, 4)}</div>'
        f'<div class="{t["cls"]}" style="font-size:13.5px;font-weight:600;flex:1">'
        f'{n}</div>'
        f'<div style="font-size:12.5px;color:var(--muted);font-weight:600">{w}</div>'
        f'</div>' for n, w, p in goals)
    return f"""
<div class="pad col" style="gap:13px">
  {header(t["today"], t["date"], left="menu")}
  {banner if banner is not None else join_banner()}
  <div class="card col" style="padding:16px;gap:12px">
    <div class="row" style="justify-content:space-between">
      <div class="col">
        <div class="eyebrow {t['cls']}">{t["goals"]}</div>
        <div class="disp gur" style="font-size:20px;font-weight:700">
          {t["goalsDone"]}</div>
      </div>
      <div style="position:relative;width:56px;height:56px">
        {ring(0.54, 56, 7)}
        <div style="position:absolute;inset:0;display:flex;align-items:center;
          justify-content:center;font-size:13px;font-weight:700">54%</div>
      </div>
    </div>
    <div class="col" style="gap:9px;border-top:1px solid var(--rule);padding-top:11px">
      {rows}
    </div>
  </div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    {icon("nitnem", 20)}<div class="{t['cls']}">{t["start"]}</div></div>
  <div class="card row" style="padding:14px;gap:12px">
    <div style="width:46px;height:46px;border-radius:14px;background:var(--kesriSoft);
      color:var(--kesriInk);display:flex;align-items:center;justify-content:center;
      flex:none">{icon("diary", 22)}</div>
    <div class="col" style="flex:1">
      <div class="{t['cls']}" style="font-size:12px;color:var(--muted);
        font-weight:700">{t["gurpurabWhen"]}</div>
      <div class="{t['cls']}" style="font-size:14px;font-weight:700">{t["gurpurab"]}</div>
      <div class="gur" style="font-size:12.5px;color:var(--muted)">9 ਮੱਘਰ 558</div>
    </div>
  </div>
  {vichar_card(t)}
</div>
{nav("today", t)}
"""


def vichar_card(t: dict = EN) -> str:
    """ਅੱਜ ਦਾ ਵਿਚਾਰ on Today, as Phase 1 already ships it.

    Phase 1's `VicharCard` is an icon and title row with the source under it,
    the line, its meaning in the reader\'s language, then Explore and Share.
    Phase 2 had quietly reduced it to an eyebrow and one line, which is the
    misalignment that was reported. It is restored here rather than
    reinterpreted; the line and meaning are entry 178 of the shipped
    `content/source/vichar/gurbani-200.json`, not typed in.
    """
    return f"""
  <div class="card col" style="padding:14px;gap:0">
    <div class="row" style="gap:10px">
      <div style="width:36px;height:36px;border-radius:12px;flex:none;
        background:var(--kesriSoft);color:var(--kesriInk);display:flex;
        align-items:center;justify-content:center">{icon("sparkle", 19)}</div>
      <div class="col" style="flex:1">
        <div class="{t['cls']}" style="font-size:14.5px;font-weight:700">{t["vichar"]}</div>
        <div class="{t['cls']}" style="font-size:12px;color:var(--muted)">
          {t["vicharSource"]}</div>
      </div>
      <div style="color:var(--muted);transform:rotate(180deg)">{icon("back", 18)}</div>
    </div>
    <div class="gur" style="font-size:19px;line-height:1.75;color:var(--word);
      padding-top:13px">ਮਿਠਤੁ ਨੀਵੀ ਨਾਨਕਾ ਗੁਣ ਚੰਗਿਆਈਆ ਤਤੁ ॥</div>
    <div class="{t['cls']}" style="font-size:13.5px;line-height:1.5;
      color:var(--ink2);padding-top:9px">{t["meaning"]}</div>
    <div class="row" style="gap:10px;padding-top:13px">
      <div class="btn" style="flex:1;background:var(--card2);color:var(--ink2);
        min-height:44px;font-size:14.5px"><div class="{t['cls']}">{t["explore"]}</div></div>
      <div class="btn" style="flex:1;background:var(--primary);
        color:var(--onPrimary);min-height:44px;font-size:14.5px">
        <div class="{t['cls']}">{t["share"]}</div></div>
    </div>
  </div>
"""


def group_detail() -> str:
    members = [("HS", "Harjit Singh", 18, True), ("GK", "Gurpreet Kaur", 15, False),
               ("MK", "Manpreet Kaur", 12, False), ("AS", "Amrit Singh", 9, False),
               ("JK", "Jasleen Kaur", 8, False)]
    rows = "".join(
        f'<div class="row" style="gap:10px">'
        f'{avatar(i, "var(--kesriSoft)" if me else "var(--card2)", "var(--kesriInk)" if me else "var(--ink2)")}'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:14px;font-weight:600">{n}{" · you" if me else ""}</div>'
        f'<div style="font-size:12px;color:var(--muted)">{v} paath</div></div>'
        f'<div style="width:70px;height:6px;border-radius:3px;background:var(--rule);'
        f'overflow:hidden"><div style="width:{v*100//18}%;height:6px;'
        f'background:{"var(--kesri)" if me else "var(--teal)"}"></div></div></div>'
        for i, n, v, me in members)
    return f"""
<div class="pad col" style="gap:14px">
  {header("Nanda Family", "6 members · family group", right="share")}
  <div class="card col" style="padding:18px 16px;gap:14px">
    <div class="row" style="gap:16px">
      <div style="position:relative;width:104px;height:104px;flex:none">
        {ring(0.67, 104, 11)}
        <div style="position:absolute;inset:0;display:flex;flex-direction:column;
          align-items:center;justify-content:center">
          <div class="disp" style="font-size:26px;font-weight:700;line-height:1">68</div>
          <div style="font-size:11.5px;color:var(--muted);font-weight:600">
            of 101</div>
        </div>
      </div>
      <div class="col" style="flex:1;gap:6px">
        <div class="eyebrow">Shared goal</div>
        <div style="font-size:15.5px;font-weight:700;line-height:1.3">
          101 Sukhmani Sahib</div>
        <div style="font-size:12.5px;color:var(--muted)">
          by Prakash Purab · 4 days left</div>
      </div>
    </div>
    <div class="row" style="gap:10px;border-top:1px solid var(--rule);padding-top:12px">
      <div class="col" style="flex:1">
        <div style="font-size:12px;color:var(--muted);font-weight:700">YOU</div>
        <div class="disp" style="font-size:20px;font-weight:700;color:var(--kesri)">
          12 paath</div>
      </div>
      <div style="width:1px;align-self:stretch;background:var(--rule)"></div>
      <div class="col" style="flex:1">
        <div style="font-size:12px;color:var(--muted);font-weight:700">THE GROUP</div>
        <div class="disp" style="font-size:20px;font-weight:700">68 paath</div>
      </div>
    </div>
  </div>
  <div class="row" style="gap:10px">
    <div class="btn" style="flex:1;background:var(--primary);color:var(--onPrimary)">
      {icon("play", 19)}<div>Start the paath</div></div>
    <div class="btn" style="flex:1;background:var(--card2);color:var(--ink2)">
      {icon("plus", 19)}<div>Log a paath</div></div>
  </div>
  <div style="font-size:12px;color:var(--muted);text-align:center;margin-top:-6px">
    Starting it here counts towards the goal when you finish</div>
  <div class="col" style="gap:11px">
    <div class="row" style="justify-content:space-between">
      <div class="eyebrow">Members</div>
      <div style="font-size:12.5px;color:var(--kesriInk);font-weight:600">Invite</div>
    </div>
    {rows}
    <div style="text-align:center;font-size:12px;color:var(--muted);
      padding-top:6px">Report this group</div>
    <div style="height:86px"></div>
  </div>
</div>
{nav("sangat")}
"""



# ------------------------------------------------------- shared furniture

def field(label: str, value: str, hint: str | None = None,
          optional: bool = False) -> str:
    """A labelled input, filled or placeholder."""
    filled = not value.startswith("~")
    text = value.lstrip("~")
    return (
        f'<div class="col" style="gap:5px">'
        f'<div class="row" style="gap:6px">'
        f'<div style="font-size:12.5px;font-weight:700;color:var(--ink2)">{label}</div>'
        + (f'<div style="font-size:11.5px;color:var(--muted)">optional</div>'
           if optional else "")
        + f'</div>'
        f'<div style="background:var(--card);border:1px solid var(--rule);'
        f'border-radius:14px;padding:13px 14px;font-size:15px;'
        f'color:{"var(--ink)" if filled else "var(--muted)"}">{text}</div>'
        + (f'<div style="font-size:11.5px;color:var(--muted);line-height:1.45">'
           f'{hint}</div>' if hint else "")
        + f'</div>')


def sheet(inner: str, height: int = 520) -> str:
    """A bottom sheet over a dimmed screen."""
    return (
        f'<div style="position:absolute;inset:0;background:var(--scrim)"></div>'
        f'<div style="position:absolute;left:0;right:0;bottom:0;height:{height}px;'
        f'background:var(--bg);border-radius:28px 28px 0 0;padding:10px 20px 24px;'
        f'display:flex;flex-direction:column;gap:14px">'
        f'<div style="width:40px;height:4px;border-radius:2px;background:var(--rule);'
        f'align-self:center"></div>{inner}</div>')


def listrow(icon_name: str, title: str, sub: str | None = None,
            right: str | None = None, tint: bool = False) -> str:
    return (
        f'<div class="row" style="gap:12px;padding:12px 0">'
        f'<div style="width:38px;height:38px;border-radius:12px;flex:none;'
        f'display:flex;align-items:center;justify-content:center;'
        f'background:{"var(--kesriSoft)" if tint else "var(--card2)"};'
        f'color:{"var(--kesriInk)" if tint else "var(--ink2)"}">'
        f'{icon(icon_name, 19)}</div>'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:14.5px;font-weight:600">{title}</div>'
        + (f'<div style="font-size:12.5px;color:var(--muted)">{sub}</div>'
           if sub else "")
        + f'</div>'
        + (f'<div style="font-size:13px;color:var(--muted);font-weight:600">{right}'
           f'</div>' if right else
           f'<div style="color:var(--muted);transform:rotate(180deg)">'
           f'{icon("back", 18)}</div>')
        + f'</div>')


def toggle(on: bool) -> str:
    return (f'<div style="width:44px;height:26px;border-radius:13px;flex:none;'
            f'background:{"var(--sage)" if on else "var(--rule)"};position:relative">'
            f'<div style="position:absolute;top:3px;{"right" if on else "left"}:3px;'
            f'width:20px;height:20px;border-radius:10px;background:#fff"></div></div>')


def app_mark(size: int = 40, arc: str = "var(--primary)",
             sun: str = "var(--kesri)") -> str:
    """The brand mark, drawn to the same 40x40 grid as `AppMark` in Dart.

    The day arc with the sun on the horizon: the app already means "a day",
    which is what a hazri is. Nothing devotional is drawn anywhere in Hazri
    and this screen is the one most likely to tempt it, so the emblem for
    the moment is the app\u2019s own mark and nothing else.
    """
    w = size * 2.4 / 40
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 40 40" '
            f'style="display:block;flex:none">'
            f'<path d="M4 27A16 16 0 0 1 36 27" fill="none" stroke="{arc}" '
            f'stroke-width="{w:.2f}" stroke-linecap="round"/>'
            f'<path d="M6 31.5H34" fill="none" stroke="{arc}" '
            f'stroke-width="{w:.2f}" stroke-linecap="round"/>'
            f'<path d="M12 27A8 8 0 0 1 28 27Z" fill="{sun}"/></svg>')


def otp(typed: str, total: int = 6) -> str:
    """The code boxes, part-typed, with the caret on the next one."""
    out = '<div class="row" style="gap:8px;justify-content:center">'
    for i in range(total):
        ch = typed[i] if i < len(typed) else ""
        here = i == len(typed)
        edge = "var(--kesri)" if here else ("var(--ink2)" if ch else "var(--rule)")
        inner = ch or ('<div style="width:2px;height:22px;background:var(--kesri)">'
                       '</div>' if here else "")
        out += (f'<div style="width:46px;height:56px;border-radius:14px;'
                f'background:var(--card);border:1.5px solid {edge};display:flex;'
                f'align-items:center;justify-content:center;font-size:22px;'
                f'font-weight:700">{inner}</div>')
    return out + "</div>"


def quiet(text: str, ic: str = "check", colour: str = "var(--muted)") -> str:
    """A calm note in a sunk card -- the pattern the set already uses."""
    return (f'<div class="card row" style="padding:12px 14px;gap:10px;'
            f'background:var(--card2);box-shadow:none">'
            f'<div style="color:{colour};flex:none">{icon(ic, 18)}</div>'
            f'<div style="font-size:12.5px;color:var(--ink2);line-height:1.5">'
            f'{text}</div></div>')


def primary(label: str, ic: str | None = None) -> str:
    return (f'<div class="btn" style="background:var(--primary);color:var(--onPrimary)">'
            + (icon(ic, 20) if ic else "") + f'<div>{label}</div></div>')


def ghost(label: str) -> str:
    return (f'<div class="btn" style="background:var(--card2);color:var(--ink2);'
            f'min-height:48px;font-size:15px"><div>{label}</div></div>')


# ------------------------------------------------------------ the screens

def profile() -> str:
    return f"""
<div class="pad col" style="gap:16px">
  {header("Join the sangat", "So your paath is counted with others")}
  <div class="col" style="gap:14px">
    {field("Your name", "Harjit Singh")}
    {field("Email", "harjit@example.com",
           "How your sangat comes back if you change phone. Nobody else in "
           "the app ever sees it.")}
    {field("Phone", "~Add a number", optional=True)}
    {field("City", "Amritsar, Punjab",
           "Shown as a dot on the Global Simran globe.")}
  </div>
  {quiet("No password to make or remember, and never will be. You are in "
         "the sangat as soon as you tap Continue.", "check", "var(--sage)")}
  {primary("Continue")}
  <div style="text-align:center;font-size:12px;color:var(--muted)">
    What we store &amp; why</div>
</div>
"""


def account() -> str:
    return f"""
<div class="pad col" style="gap:14px">
  {header("Your account", left="menu")}
  <div class="card row" style="padding:16px;gap:14px">
    {avatar("HS", "var(--kesriSoft)", "var(--kesriInk)", 56)}
    <div class="col" style="flex:1">
      <div class="disp" style="font-size:20px;font-weight:700">Harjit Singh</div>
      <div style="font-size:13px;color:var(--muted)">Amritsar, Punjab</div>
    </div>
  </div>
  <div class="card col" style="padding:4px 16px">
    {listrow("mail", "Email", "harjit@example.com",
             right='<span style="color:var(--kesriInk)">Not verified</span>')}
    <div style="height:1px;background:var(--rule)"></div>
    {listrow("phone", "Phone", "Not added")}
    <div style="height:1px;background:var(--rule)"></div>
    {listrow("globe", "City", "Amritsar, Punjab")}
  </div>
  <div class="card col" style="padding:14px;gap:11px;background:var(--kesriSoft)">
    <div class="row" style="gap:10px">
      <div style="color:var(--kesriInk);flex:none">{icon("mail", 20)}</div>
      <div class="col" style="flex:1">
        <div style="font-size:14px;font-weight:700;color:var(--kesriInk)">
          Complete your verification</div>
        <div style="font-size:12.5px;color:var(--kesriInk);opacity:.85;
          line-height:1.45">Your account works either way. Confirming your
          email is what brings it back if you change phone.</div>
      </div>
    </div>
    <div class="btn" style="background:var(--kesri);color:#fff;min-height:44px;
      font-size:14.5px"><div>Verify my email</div></div>
  </div>
  <div class="card col" style="padding:4px 16px">
    {listrow("check", "Diary sync", "On · synced 2 minutes ago", right="On")}
    <div style="height:1px;background:var(--rule)"></div>
    {listrow("globe", "Privacy &amp; my data", "What is stored, and deleting it")}
  </div>
  {ghost("Sign out of this phone")}
  <div style="height:86px"></div>
</div>
{nav("today")}
"""


def verify_email() -> str:
    """Confirming the email, from setup or from the strip on Today.

    One screen does both jobs, because they are the same job: the address is
    unconfirmed and the account is not yet recoverable. The link and the code
    are two ways through the same door -- the link is one tap when the mail
    is read on this phone, and the code is what saves it when it is read on a
    laptop, which is where the old design quietly dead-ended.

    Changing the address lives here rather than in Account, because this is
    where somebody finds out they mistyped it.
    """
    return f"""
<div class="pad col" style="gap:16px">
  {header("Verify your email")}
  <div class="col" style="align-items:center;gap:12px;padding-top:6px">
    <div style="width:80px;height:80px;border-radius:40px;background:var(--kesriSoft);
      color:var(--kesriInk);display:flex;align-items:center;justify-content:center">
      {icon("mail", 38)}</div>
    <div class="disp" style="font-size:22px;font-weight:700;text-align:center">
      Check your email</div>
    <div style="font-size:14px;color:var(--ink2);text-align:center;line-height:1.6;
      padding:0 4px">We sent a link and a 6-digit code to
      <span style="font-weight:700;color:var(--ink)">harjit@example.com</span>.
      Tap the link, or type the code here.</div>
  </div>
  {otp("4291")}
  <div class="row" style="justify-content:center;gap:6px;font-size:13px">
    <div style="color:var(--muted)">Did not arrive?</div>
    <div style="color:var(--muted);font-weight:600">Send again in 0:42</div>
  </div>
  <div class="card row" style="padding:13px 14px;gap:11px">
    <div style="color:var(--teal);flex:none">{icon("mail", 19)}</div>
    <div class="col" style="flex:1">
      <div style="font-size:13.5px;font-weight:600">Wrong address?</div>
      <div style="font-size:12px;color:var(--muted)">
        harjit@example.com — change it and we will send a new code</div>
    </div>
    <div style="color:var(--muted);transform:rotate(180deg)">{icon("back", 18)}</div>
  </div>
  {quiet("Until this is done your groups and goals live on this phone only, "
         "and they cannot be brought back if you change phone.", "alert",
         "var(--kesriInk)")}
  <div style="text-align:center;font-size:13px;color:var(--muted);font-weight:600">
    Do this later</div>
</div>
"""


def code_problems() -> str:
    """The two ways a code fails, on one screen, as Sync does its three.

    A used code can say what it was used for, because the use is recorded --
    which turns a dead end into an answer, and is the only way somebody finds
    out their address is being read by somebody else.
    """
    def state(ic, colour, tint, title, body, when):
        return f'''
  <div class="card col" style="padding:15px;gap:9px">
    <div class="row" style="gap:11px">
      <div style="width:38px;height:38px;border-radius:12px;flex:none;
        background:{tint};color:{colour};display:flex;align-items:center;
        justify-content:center">{icon(ic, 19)}</div>
      <div class="col" style="flex:1">
        <div style="font-size:14.5px;font-weight:700">{title}</div>
        <div style="font-size:12px;color:var(--muted)">{when}</div>
      </div>
    </div>
    <div style="font-size:13px;color:var(--ink2);line-height:1.55">{body}</div>
  </div>'''
    return f"""
<div class="pad col" style="gap:13px">
  {header("That code did not work", "What happened, and what to do")}
  {state("alert", "var(--teal)", "var(--card2)", "Already used",
         "This code signed in a phone on 20 November at 6:12 PM. Every code "
         "works once and then stops, which is what keeps a forwarded email "
         "from being a way in.",
         "USED · 20 NOV, 6:12 PM")}
  {state("clock", "var(--kesriInk)", "var(--kesriSoft)", "Too old",
         "Codes last an hour. This one was sent yesterday, so it has lapsed "
         "on its own — nobody used it.",
         "SENT · 19 NOV, 9:04 PM")}
  {primary("Send a new code", "mail")}
  {quiet("If neither of those was you, change your email address before you "
         "verify. A code is only ever sent to the address on the account.",
         "alert", "var(--kesriInk)")}
  <div style="text-align:center;font-size:13px;color:var(--muted);font-weight:600">
    Not now</div>
</div>
"""


def restore_or_new() -> str:
    """A new phone, and the address already has an account behind it.

    Restoring and starting again are both legitimate -- a shared family email
    is the ordinary case -- so neither is hidden behind the other, and the
    existing account is described well enough to be recognised without
    showing anything a stranger could use.
    """
    return f"""
<div class="pad col" style="gap:14px">
  {header("You have been here before", "harjit@example.com")}
  <div class="card col" style="padding:16px;gap:13px;border:1.5px solid var(--kesri)">
    <div class="row" style="gap:13px">
      {avatar("HS", "var(--kesriSoft)", "var(--kesriInk)", 52)}
      <div class="col" style="flex:1">
        <div class="disp" style="font-size:19px;font-weight:700">Harjit Singh</div>
        <div style="font-size:13px;color:var(--muted)">Amritsar, Punjab</div>
      </div>
    </div>
    <div class="row" style="gap:0;border-top:1px solid var(--rule);padding-top:11px">
      <div class="col" style="flex:1;gap:1px">
        <div class="disp" style="font-size:17px;font-weight:700">3</div>
        <div style="font-size:11.5px;color:var(--muted)">groups</div>
      </div>
      <div class="col" style="flex:1;gap:1px">
        <div class="disp" style="font-size:17px;font-weight:700">412</div>
        <div style="font-size:11.5px;color:var(--muted)">paath logged</div>
      </div>
      <div class="col" style="flex:1;gap:1px">
        <div class="disp" style="font-size:17px;font-weight:700">Mar</div>
        <div style="font-size:11.5px;color:var(--muted)">since 2026</div>
      </div>
    </div>
    {primary("Restore this account")}
  </div>
  <div class="row" style="gap:12px">
    <div style="height:1px;background:var(--rule);flex:1"></div>
    <div style="font-size:12px;color:var(--muted);font-weight:600">or</div>
    <div style="height:1px;background:var(--rule);flex:1"></div>
  </div>
  <div class="card col" style="padding:15px;gap:11px">
    <div class="col" style="gap:3px">
      <div style="font-size:14.5px;font-weight:700">Start a new account</div>
      <div style="font-size:12.5px;color:var(--ink2);line-height:1.5">
        For somebody else on this phone. The account above is left exactly as
        it is, on whatever phone has it.</div>
    </div>
    {ghost("Start fresh")}
  </div>
  {quiet("Restoring signs nothing out. The same account can be on more than "
         "one phone at once.")}
</div>
"""


def restored() -> str:
    """What came back, said plainly, because the point is to be believed."""
    items = [("sangat", "3 groups", "Nanda Family, Gurdwara Sangat, Amrit Vela Circle"),
             ("check", "Your goals", "2 shared · 3 daily, at the times you set"),
             ("diary", "Your diary", "412 entries, from 2 March"),
             ("globe", "Your dot", "Amritsar, Punjab")]
    rows = "".join(
        f'<div class="row" style="gap:12px;padding:10px 0">'
        f'<div style="width:36px;height:36px;border-radius:12px;flex:none;'
        f'background:var(--sageSoft);color:var(--sage);display:flex;'
        f'align-items:center;justify-content:center">{icon(i, 18)}</div>'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:14px;font-weight:600">{t}</div>'
        f'<div style="font-size:12px;color:var(--muted)">{d}</div></div>'
        f'<div style="color:var(--sage)">{icon("check", 18)}</div></div>'
        for i, t, d in items)
    return f"""
<div class="pad col" style="gap:16px">
  <div class="col" style="align-items:center;gap:12px;padding-top:34px">
    <div style="width:88px;height:88px;border-radius:44px;background:var(--sageSoft);
      color:var(--sage);display:flex;align-items:center;justify-content:center">
      {icon("check", 44)}</div>
    <div class="disp" style="font-size:24px;font-weight:700;text-align:center">
      Your sangat is back</div>
    <div style="font-size:14px;color:var(--ink2);text-align:center;line-height:1.55">
      Everything below came down in a moment. The banis and their recitations
      were already on this phone.</div>
  </div>
  <div class="card col" style="padding:6px 16px">{rows}</div>
  {quiet("Your diary came back because sync was on. With sync off, only your "
         "groups and goals are kept — the diary stays on the phone that wrote it.")}
  {primary("Open Today")}
</div>
"""


def privacy_data() -> str:
    on_phone = ["Your diary and streaks", "Reading position and goals",
                "Every bani, its audio and the calendar"]
    on_server = ["Your name",
                 "The city you chose — shown as one dot on the globe",
                 "Which groups you are in",
                 "How much you have completed towards a shared goal"]
    def bullets(items, colour):
        return "".join(
            f'<div class="row" style="gap:9px;padding:4px 0">'
            f'<div style="width:6px;height:6px;border-radius:3px;background:{colour};'
            f'flex:none"></div>'
            f'<div style="font-size:13.5px;color:var(--ink2)">{t}</div></div>'
            for t in items)
    return f"""
<div class="pad col" style="gap:14px">
  {header("Privacy &amp; my data")}
  <div class="card col" style="padding:15px;gap:6px">
    <div class="row" style="gap:8px">
      <div style="color:var(--sage)">{icon("check", 18)}</div>
      <div style="font-size:14px;font-weight:700">On this phone only</div>
    </div>
    {bullets(on_phone, "var(--sage)")}
  </div>
  <div class="card col" style="padding:15px;gap:6px">
    <div class="row" style="gap:8px">
      <div style="color:var(--teal)">{icon("globe", 18)}</div>
      <div style="font-size:14px;font-weight:700">Shared with the sangat</div>
    </div>
    {bullets(on_server, "var(--teal)")}
  </div>
  <div class="card col" style="padding:15px;gap:6px">
    <div class="row" style="gap:8px">
      <div style="color:var(--kesriInk)">{icon("mail", 18)}</div>
      <div style="font-size:14px;font-weight:700">Held for your account alone</div>
    </div>
    {bullets(["Your email — the only thing it does is bring your account back"],
             "var(--kesri)")}
  </div>
  <div class="card col" style="padding:6px 16px">
    <div class="row" style="gap:12px;padding:13px 0">
      <div class="col" style="flex:1">
        <div style="font-size:14px;font-weight:600">Show my name in groups</div>
        <div style="font-size:12px;color:var(--muted)">
          Off shows you as "a member". Your name is never shown outside a
          group you joined.</div>
      </div>{toggle(True)}
    </div>
  </div>
  {ghost("Download everything we hold")}
  <div class="btn" style="background:transparent;color:#C0392B;min-height:48px;
    font-size:15px;border:1px solid #C0392B"><div>Delete my account and data</div></div>
</div>
"""


def unlock_sheet() -> str:
    perks = [("sangat", "See who is reciting", "Your family, your sangat, the world"),
             ("globe", "Join a shared goal", "101 Sukhmani Sahib by Gurpurab"),
             ("check", "Keep your diary safe", "It comes back if you change phone")]
    rows = "".join(
        f'<div class="row" style="gap:12px">'
        f'<div style="width:40px;height:40px;border-radius:13px;flex:none;'
        f'background:var(--kesriSoft);color:var(--kesriInk);display:flex;'
        f'align-items:center;justify-content:center">{icon(i, 20)}</div>'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:14.5px;font-weight:700">{t}</div>'
        f'<div style="font-size:12.5px;color:var(--muted)">{s}</div></div></div>'
        for i, t, s in perks)
    inner = f"""
  <div class="col" style="gap:4px;padding-top:4px">
    <div class="disp" style="font-size:24px;font-weight:700">Join the sangat</div>
    <div style="font-size:13.5px;color:var(--muted)">
      Hazri works fully without this. This adds the people.</div>
  </div>
  <div class="col" style="gap:14px;padding-top:4px">{rows}</div>
  <div style="flex:1"></div>
  {primary("Set up — takes a couple of seconds")}
  {ghost("Not now")}
  <div style="text-align:center;font-size:11.5px;color:var(--muted)">
    No password · no ads · your paath stays on your phone</div>
"""
    # A modal sheet covers the bottom bar rather than sliding under it.
    return today().replace(nav("today"), "") + nav("today") + sheet(inner, 486)


def settings_menu() -> str:
    inner = f"""
  <div class="card row" style="padding:14px;gap:12px">
    {avatar("HS", "var(--kesriSoft)", "var(--kesriInk)", 46)}
    <div class="col" style="flex:1">
      <div style="font-size:15.5px;font-weight:700">Harjit Singh</div>
      <div style="font-size:12.5px;color:var(--muted)">Amritsar · synced</div>
    </div>
    <div style="color:var(--muted);transform:rotate(180deg)">{icon("back", 18)}</div>
  </div>
  <div class="card col" style="padding:2px 16px">
    {listrow("bell", "Reminders")}
    <div style="height:1px;background:var(--rule)"></div>
    {listrow("simran", "Audio &amp; voice")}
    <div style="height:1px;background:var(--rule)"></div>
    {listrow("nitnem", "Text size &amp; script")}
    <div style="height:1px;background:var(--rule)"></div>
    {listrow("globe", "Language")}
  </div>
  <div class="card col" style="padding:2px 16px">
    {listrow("check", "Privacy &amp; my data")}
    <div style="height:1px;background:var(--rule)"></div>
    {listrow("share", "About &amp; credits")}
  </div>
  <div style="flex:1;min-height:6px"></div>
  <div style="text-align:center;font-size:11.5px;color:var(--muted)">
    Hazri 2.0 · No ads on Gurbani, ever</div>
"""
    return (today(hazri_banner()).replace(nav("today"), "") + nav("today")
            + sheet(inner, 600))


def sangat_home() -> str:
    groups = [("Nanda Family", "family group · 6 members", 0.67, "68 of 101 Sukhmani"),
              ("Gurdwara Sangat", "sangat · 214 members", 0.41,
               "8,900 of 21,000 paath"),
              ("Amrit Vela Circle", "simran circle · 12 members", 0.85,
               "255 of 300 minutes")]
    cards = "".join(
        f'<div class="card row" style="padding:14px;gap:13px">'
        f'<div style="position:relative;width:52px;height:52px;flex:none">'
        f'{ring(p, 52, 6)}'
        f'<div style="position:absolute;inset:0;display:flex;align-items:center;'
        f'justify-content:center;font-size:12px;font-weight:700">'
        f'{int(p*100)}%</div></div>'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:15px;font-weight:700">{n}</div>'
        f'<div style="font-size:12px;color:var(--muted)">{s}</div>'
        f'<div style="font-size:12.5px;color:var(--ink2);font-weight:600;'
        f'padding-top:2px">{g}</div></div>'
        f'<div style="color:var(--muted);transform:rotate(180deg)">'
        f'{icon("back", 18)}</div></div>' for n, s, p, g in groups)
    # Seeded by us, so there is no user-chosen name here to go wrong, and a
    # new account has somewhere to belong on its first day.
    seeded = [("simran", "Amrit Vela · 4 AM", "simran circle · 1,840 members"),
              ("nitnem", "Japji Sahib every morning", "daily bani · 3,210 members"),
              ("diary", "Gurpurab 2026 — together", "ends 24 Nov · 906 members"),
              ("sangat", "New to Nitnem", "start slowly · 412 members")]
    open_groups = "".join(
        f'<div class="card row" style="padding:12px 14px;gap:12px">'
        f'<div style="width:38px;height:38px;border-radius:12px;flex:none;'
        f'background:var(--card2);color:var(--teal);display:flex;'
        f'align-items:center;justify-content:center">{icon(i, 19)}</div>'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:14px;font-weight:700">{n}</div>'
        f'<div style="font-size:12px;color:var(--muted)">{d}</div></div>'
        f'<div class="chip" style="background:var(--kesriSoft);'
        f'color:var(--kesriInk)">Join</div></div>' for i, n, d in seeded)
    return f"""
<div class="pad col" style="gap:13px">
  {header("Sangat", "Create or join", left="menu", right="plus")}
  <div class="card row" style="padding:14px;gap:12px;background:#0E1533;color:#EDECF6">
    <div style="width:50px;height:50px;border-radius:25px;background:#1B2450;
      color:#5B8DEF;display:flex;align-items:center;justify-content:center;flex:none">
      {icon("globe", 26)}</div>
    <div class="col" style="flex:1">
      <div style="font-size:15px;font-weight:700">The sangat worldwide</div>
      <div style="font-size:12.5px;opacity:.7">
        12,400 in 64 countries · see it in Simran</div>
    </div>
    <div style="opacity:.6;transform:rotate(180deg)">{icon("back", 18)}</div>
  </div>
  <div class="eyebrow" style="padding-top:2px">Your groups</div>
  {cards}
  <div class="row" style="justify-content:space-between;padding-top:6px">
    <div class="eyebrow">Groups you can join</div>
    <div style="font-size:12.5px;color:var(--kesriInk);font-weight:600">See all</div>
  </div>
  <div style="font-size:12px;color:var(--muted);margin-top:-6px">
    Started by Hazri, open to everyone — no link needed</div>
  {open_groups}
  <div style="text-align:center;font-size:13px;color:var(--kesriInk);
    font-weight:600;padding-top:4px">Have a link? Join a group</div>
  <div style="height:86px"></div>
</div>
{nav("sangat")}
"""


def create_group() -> str:
    kinds = [("Family", "People you live with or call", True),
             ("Sangat", "A gurdwara or a wider group", False),
             ("Simran circle", "Counted in minutes, not paath", False)]
    cards = "".join(
        f'<div class="card row" style="padding:13px 14px;gap:12px;'
        f'border:1.5px solid {"var(--kesri)" if on else "transparent"}">'
        f'<div style="width:20px;height:20px;border-radius:10px;flex:none;'
        f'border:2px solid {"var(--kesri)" if on else "var(--rule)"};'
        f'background:{"var(--kesri)" if on else "transparent"};display:flex;'
        f'align-items:center;justify-content:center;color:#fff">'
        + (icon("check", 12) if on else "") + f'</div>'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:14.5px;font-weight:700">{t}</div>'
        f'<div style="font-size:12.5px;color:var(--muted)">{s}</div></div></div>'
        for t, s, on in kinds)
    # Private by default: a name only needs checking once strangers can see
    # it, and almost no group ever needs that.
    vis = [("Private — people you send the link to", "Live straight away", True),
           ("Listed in Sangat — anyone can find it", "Checked before it appears",
            False)]
    visibility = "".join(
        f'<div class="card row" style="padding:13px 14px;gap:12px;'
        f'border:1.5px solid {"var(--kesri)" if on else "transparent"}">'
        f'<div style="width:20px;height:20px;border-radius:10px;flex:none;'
        f'border:2px solid {"var(--kesri)" if on else "var(--rule)"};'
        f'background:{"var(--kesri)" if on else "transparent"};display:flex;'
        f'align-items:center;justify-content:center;color:#fff">'
        + (icon("check", 12) if on else "") + f'</div>'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:14px;font-weight:700;line-height:1.3">{t}</div>'
        f'<div style="font-size:12px;color:var(--muted)">{d}</div></div></div>'
        for t, d, on in vis)
    return f"""
<div class="pad col" style="gap:15px">
  {header("Create a group")}
  <div class="col" style="gap:9px">
    <div class="eyebrow">What kind</div>
    {cards}
  </div>
  {field("Group name", "Nanda Family",
         "Seen by the people in the group. Change it whenever you like.")}
  <div class="col" style="gap:9px">
    <div class="eyebrow">Who can find it</div>
    {visibility}
  </div>
  {quiet("The name of a listed group is seen by people who never met you, "
         "so we "
         "read it before it appears — usually the same day. Private groups "
         "go live at once.", "check")}
  <div style="flex:1"></div>
  {primary("Create group")}
</div>
"""


def set_goal() -> str:
    chips = "".join(
        f'<div class="chip" style="background:{"var(--kesriSoft)" if on else "var(--card2)"};'
        f'color:{"var(--kesriInk)" if on else "var(--ink2)"};min-height:36px">{t}</div>'
        for t, on in [("Japji Sahib", False), ("Sukhmani Sahib", True),
                      ("Chaupai Sahib", False), ("Rehras Sahib", False),
                      ("Simran minutes", False), ("More…", False)])
    return f"""
<div class="pad col" style="gap:15px">
  {header("Shared goal", "Nanda Family")}
  <div class="col" style="gap:9px">
    <div class="eyebrow">What the group recites</div>
    <div class="row" style="gap:8px;flex-wrap:wrap">{chips}</div>
  </div>
  <div class="col" style="gap:9px">
    <div class="eyebrow">How many, together</div>
    <div class="card row" style="padding:12px 14px;gap:14px">
      <div style="width:44px;height:44px;border-radius:22px;background:var(--card2);
        color:var(--ink2);display:flex;align-items:center;justify-content:center;
        flex:none;font-size:22px;font-weight:600">−</div>
      <div class="col" style="flex:1;align-items:center">
        <div class="disp" style="font-size:30px;font-weight:700;line-height:1">101</div>
        <div style="font-size:12px;color:var(--muted);font-weight:600">paath</div>
      </div>
      <div style="width:44px;height:44px;border-radius:22px;background:var(--kesriSoft);
        color:var(--kesriInk);display:flex;align-items:center;justify-content:center;
        flex:none;font-size:22px;font-weight:600">+</div>
    </div>
  </div>
  <div class="col" style="gap:9px">
    <div class="eyebrow">By when</div>
    <div class="card col" style="padding:6px 16px">
      {listrow("diary", "Prakash Purab, Guru Nanak Dev Ji", "Tue 24 Nov · 4 days",
               tint=True)}
      <div style="height:1px;background:var(--rule)"></div>
      {listrow("plus", "Pick another date", "Or no end date")}
    </div>
  </div>
  <div class="card col" style="padding:13px 15px;gap:4px;background:var(--card2);
    box-shadow:none">
    <div style="font-size:12px;color:var(--muted);font-weight:700">THE GROUP WILL SEE</div>
    <div style="font-size:14px;color:var(--ink);line-height:1.5">
      “101 Sukhmani Sahib by Prakash Purab” — with everyone's count, and yours.</div>
  </div>
  <div style="flex:1"></div>
  {primary("Set the goal")}
</div>
"""


def invite() -> str:
    members = [("HS", "Harjit Singh", "You started this group"),
               ("GK", "Gurpreet Kaur", "Joined 3 days ago"),
               ("MK", "Manpreet Kaur", "Joined 3 days ago"),
               ("AS", "Amrit Singh", "Joined yesterday")]
    rows = "".join(
        f'<div class="row" style="gap:11px;padding:9px 0">{avatar(i)}'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:14px;font-weight:600">{n}</div>'
        f'<div style="font-size:12px;color:var(--muted)">{s}</div></div>'
        f'<div style="font-size:12.5px;color:var(--muted);font-weight:600">'
        f'{"Admin" if idx == 0 else "Remove"}</div></div>'
        for idx, (i, n, s) in enumerate(members))
    return f"""
<div class="pad col" style="gap:15px">
  {header("Invite", "Nanda Family")}
  <div class="card col" style="padding:16px;gap:12px">
    <div class="eyebrow">Share this link</div>
    <div class="row" style="gap:10px;background:var(--card2);border-radius:14px;
      padding:13px 14px">
      <div style="font-size:13.5px;color:var(--ink2);flex:1;overflow:hidden;
        white-space:nowrap;text-overflow:ellipsis">hazri.app/j/nanda-7k2m</div>
      <div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk)">
        Copy</div>
    </div>
    <div class="btn" style="background:var(--primary);color:var(--onPrimary);
      min-height:46px;font-size:14.5px">{icon("share", 18)}<div>Share the link</div></div>
    <div style="font-size:11.5px;color:var(--muted);line-height:1.5">
      Anyone with this link can join and see the group's progress and members'
      names. You can turn the link off at any time.</div>
  </div>
  <div class="col" style="gap:2px">
    <div class="eyebrow" style="padding-bottom:4px">4 members</div>
    {rows}
  </div>
</div>
"""


def log_paath() -> str:
    inner = f"""
  <div class="col" style="gap:3px;padding-top:2px">
    <div class="disp" style="font-size:22px;font-weight:700">Log a paath</div>
    <div style="font-size:13px;color:var(--muted)">Nanda Family · 101 Sukhmani Sahib</div>
  </div>
  <div class="card row" style="padding:14px;gap:14px">
    <div style="width:44px;height:44px;border-radius:22px;background:var(--card2);
      color:var(--ink2);display:flex;align-items:center;justify-content:center;
      flex:none;font-size:22px;font-weight:600">−</div>
    <div class="col" style="flex:1;align-items:center">
      <div class="disp" style="font-size:34px;font-weight:700;line-height:1">2</div>
      <div style="font-size:12px;color:var(--muted);font-weight:600">
        Sukhmani Sahib today</div>
    </div>
    <div style="width:44px;height:44px;border-radius:22px;background:var(--kesriSoft);
      color:var(--kesriInk);display:flex;align-items:center;justify-content:center;
      flex:none;font-size:22px;font-weight:600">+</div>
  </div>
  <div class="card row" style="padding:12px 14px;gap:10px;background:var(--card2);
    box-shadow:none">
    <div style="color:var(--sage);flex:none">{icon("check", 18)}</div>
    <div style="font-size:12.5px;color:var(--ink2);line-height:1.5">
      Paath you read in Hazri is counted on its own. This is for paath you did
      elsewhere.</div>
  </div>
  <div style="flex:1"></div>
  {primary("Add to the group")}
  {ghost("Cancel")}
"""
    return group_detail().replace(nav("sangat"), "") + nav("sangat") + sheet(inner, 446)



def searchbox(placeholder: str) -> str:
    return (f'<div class="card row" style="padding:13px 14px;gap:10px;'
            f'border:1px solid var(--rule)">'
            f'<div style="color:var(--muted)">{icon("search", 19)}</div>'
            f'<div style="font-size:14.5px;color:var(--muted);flex:1">'
            f'{placeholder}</div></div>')


def tile(h: int = 132) -> str:
    """An abstract tile for an article.

    Deliberately geometric. No picture of a Guru is drawn anywhere in this
    app, and an illustration slot is exactly where one would creep in, so
    the slot itself is abstract by construction.
    """
    return (f'<div style="height:{h}px;border-radius:16px;overflow:hidden;'
            f'background:linear-gradient(135deg,var(--primary),#0E1533);'
            f'position:relative;flex:none">'
            f'<svg width="100%" height="{h}" viewBox="0 0 320 {h}" '
            f'preserveAspectRatio="xMidYMid slice" style="display:block">'
            + "".join(f'<circle cx="252" cy="{h//2}" r="{r}" fill="none" '
                      f'stroke="rgba(242,162,78,{0.40 - i*0.045:.2f})" '
                      f'stroke-width="1.4"/>' for i, r in enumerate(range(26, 150, 17)))
            + f'</svg></div>')


def kicker(text: str, colour: str = "var(--teal)") -> str:
    return (f'<div style="font-size:11px;font-weight:700;letter-spacing:.08em;'
            f'text-transform:uppercase;color:{colour}">{text}</div>')


def vichar_home() -> str:
    """Vichar, as a place to read rather than a place to ask.

    The brief: articles and blogs that live on the Hazri website, plus
    reference entries -- gurdwaras, the Guru Sahibans, the banis, the days
    that matter -- held in the backend and fetched. A box to search, and the
    articles themselves on the page to be read inline. Gurbani meanings are
    not here; ਅੱਜ ਦਾ ਵਿਚਾਰ keeps them, on Today.

    It is the one part of Hazri that needs a connection, which is said on
    the screen rather than discovered.
    """
    cats = [("Articles", True), ("Gurdwaras", False), ("Guru Sahibans", False),
            ("Banis", False), ("Sikh days", False)]
    chips = "".join(
        f'<div class="chip" style="min-height:34px;'
        f'background:{"var(--kesriSoft)" if on else "var(--card2)"};'
        f'color:{"var(--kesriInk)" if on else "var(--ink2)"}">{t}</div>'
        for t, on in cats)
    more = [("GURDWARAS", "Gurdwara Bangla Sahib, Delhi", "4 min read"),
            ("BANIS", "Why Rehras Sahib is read at sunset", "6 min read")]
    rows = "".join(
        f'<div class="card row" style="padding:13px 14px;gap:12px">'
        f'<div class="col" style="flex:1;gap:3px">{kicker(k)}'
        f'<div style="font-size:14.5px;font-weight:700;line-height:1.3">{t}</div>'
        f'<div style="font-size:12px;color:var(--muted)">{m}</div></div>'
        f'<div style="width:52px;height:52px;border-radius:13px;flex:none;'
        f'background:linear-gradient(135deg,var(--primary),#0E1533)"></div></div>'
        for k, t, m in more)
    return f"""
<div class="pad col" style="gap:13px">
  {header("ਵਿਚਾਰ", "Read, and look things up")}
  {searchbox("Search articles, gurdwaras, banis…")}
  <div class="row" style="gap:7px;flex-wrap:wrap">{chips}</div>
  <div class="card col" style="padding:14px;gap:11px">
    {tile()}
    <div class="col" style="gap:4px">
      {kicker("BANIS")}
      <div class="disp" style="font-size:18px;font-weight:700;line-height:1.25">
        The nine banis in Hazri</div>
      <div style="font-size:13px;color:var(--ink2);line-height:1.5">
        Which nine, why these, and where each recitation came from.</div>
    </div>
    <div class="row" style="gap:8px">
      <div style="font-size:12px;color:var(--muted);font-weight:600">
        hazri.app · 7 min read</div>
    </div>
  </div>
  <div class="eyebrow" style="padding-top:2px">More to read</div>
  {rows}
  {quiet("Vichar is the one part of Hazri that needs a connection. Your banis, "
         "their recitations, the calendar and your diary never do.", "globe")}
  <div style="height:20px"></div>
</div>
"""


def vichar_article() -> str:
    """One article, read inside the app rather than bounced to a browser."""
    body = [
        "Hazri ships nine banis. Four of them are in Sri Guru Granth Sahib Ji "
        "and five are not, which is why the meanings that can be shown differ "
        "from one to the next.",
        "Every line comes from a reviewed source file and is built into the "
        "app before release. Nothing is translated by a machine, and where a "
        "source has no entry the app shows a gap rather than filling it.",
    ]
    paras = "".join(
        f'<div style="font-size:14.5px;line-height:1.72;color:var(--ink2)">{t}</div>'
        for t in body)
    return f"""
<div class="pad col" style="gap:14px">
  {header("", left="back", right="share")}
  <div class="col" style="gap:7px;margin-top:-6px">
    {kicker("BANIS")}
    <div class="disp" style="font-size:25px;font-weight:700;line-height:1.22">
      The nine banis in Hazri</div>
    <div style="font-size:12.5px;color:var(--muted);font-weight:600">
      hazri.app · 7 min read · updated 12 November</div>
  </div>
  {tile(150)}
  <div class="col" style="gap:13px">{paras}</div>
  <div class="card row" style="padding:12px 14px;gap:10px;background:var(--card2);
    box-shadow:none">
    <div style="color:var(--teal);flex:none">{icon("globe", 18)}</div>
    <div style="font-size:12.5px;color:var(--ink2);line-height:1.5">
      Written and reviewed on hazri.app. The app shows it as written and does
      not summarise it.</div>
  </div>
  <div class="eyebrow">Read next</div>
  {listrow("nitnem", "Why Rehras Sahib is read at sunset", "6 min read")}
  <div style="height:20px"></div>
</div>
"""


def vichar_topic() -> str:
    """A reference entry, fetched rather than bundled.

    Facts in fields, not prose: a row somebody can check and correct on the
    website, and the app renders whatever it is given.
    """
    facts = [("pin", "Where", "Baba Kharak Singh Marg, New Delhi"),
             ("diary", "Marks", "The stay of Guru Har Krishan Sahib Ji"),
             ("globe", "Open", "All day, every day"),
             ("sangat", "Langar", "Served continuously")]
    rows = "".join(
        f'<div class="row" style="gap:12px;padding:11px 0">'
        f'<div style="width:34px;height:34px;border-radius:11px;flex:none;'
        f'background:var(--card2);color:var(--teal);display:flex;'
        f'align-items:center;justify-content:center">{icon(i, 17)}</div>'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:12px;color:var(--muted);font-weight:700">{k}</div>'
        f'<div style="font-size:14px;font-weight:600;line-height:1.35">{v}</div>'
        f'</div></div>' for i, k, v in facts)
    return f"""
<div class="pad col" style="gap:14px">
  {header("", left="back", right="share")}
  <div class="col" style="gap:6px;margin-top:-6px">
    {kicker("GURDWARAS")}
    <div class="disp" style="font-size:25px;font-weight:700;line-height:1.22">
      Gurdwara Bangla Sahib</div>
    <div style="font-size:13px;color:var(--muted)">New Delhi, India</div>
  </div>
  {tile(140)}
  <div class="card col" style="padding:6px 16px">{rows}</div>
  <div class="card col" style="padding:14px;gap:7px">
    <div style="font-size:14px;font-weight:700">About</div>
    <div style="font-size:13.5px;line-height:1.65;color:var(--ink2)">
      Placeholder. Every reference entry is written and checked on hazri.app
      and fetched by the app; the layout is what is being reviewed here, not
      the words.</div>
  </div>
  {quiet("Fetched from hazri.app. If something here is wrong, it is corrected "
         "once on the website and every phone sees the correction.", "globe")}
  <div style="height:20px"></div>
</div>
"""


def vichar_search() -> str:
    """Searching, and the two ways it comes back with nothing."""
    hits = [("GURDWARAS", "Gurdwara Bangla Sahib, Delhi"),
            ("GURDWARAS", "Gurdwara Sis Ganj Sahib, Delhi"),
            ("SIKH DAYS", "Guru Har Krishan Sahib Ji — Joti Jot")]
    rows = "".join(
        f'<div class="card row" style="padding:12px 14px;gap:12px">'
        f'<div class="col" style="flex:1;gap:2px">{kicker(k)}'
        f'<div style="font-size:14px;font-weight:600;line-height:1.3">{t}</div>'
        f'</div>'
        f'<div style="color:var(--muted);transform:rotate(180deg)">'
        f'{icon("back", 18)}</div></div>' for k, t in hits)
    return f"""
<div class="pad col" style="gap:13px">
  {header("Search", "3 results for “bangla sahib”")}
  <div class="card row" style="padding:13px 14px;gap:10px;
    border:1.5px solid var(--kesri)">
    <div style="color:var(--kesriInk)">{icon("search", 19)}</div>
    <div style="font-size:14.5px;color:var(--ink);flex:1">bangla sahib</div>
    <div style="font-size:13px;color:var(--muted);font-weight:600">Clear</div>
  </div>
  {rows}
  <div class="eyebrow" style="padding-top:8px">When it finds nothing</div>
  <div class="card row" style="padding:14px;gap:11px">
    <div style="width:38px;height:38px;border-radius:12px;flex:none;
      background:var(--card2);color:var(--muted);display:flex;
      align-items:center;justify-content:center">{icon("search", 19)}</div>
    <div class="col" style="flex:1">
      <div style="font-size:14px;font-weight:700">Nothing matches that yet</div>
      <div style="font-size:12.5px;color:var(--ink2);line-height:1.45">
        Vichar only holds what has been written on hazri.app. Ask for it and
        it can be added.</div>
    </div>
  </div>
  <div class="card row" style="padding:14px;gap:11px">
    <div style="width:38px;height:38px;border-radius:12px;flex:none;
      background:var(--kesriSoft);color:var(--kesriInk);display:flex;
      align-items:center;justify-content:center">{icon("globe", 19)}</div>
    <div class="col" style="flex:1">
      <div style="font-size:14px;font-weight:700">No connection</div>
      <div style="font-size:12.5px;color:var(--ink2);line-height:1.45">
        Vichar needs one. Everything else — your banis, the recitations, the
        calendar, your diary — is already on this phone.</div>
    </div>
  </div>
  <div style="height:20px"></div>
</div>
"""


def add_goal() -> str:
    chips = "".join(
        f'<div class="chip" style="background:{"var(--kesriSoft)" if on else "var(--card2)"};'
        f'color:{"var(--kesriInk)" if on else "var(--ink2)"};min-height:36px">{t}</div>'
        for t, on in [("Naam Simran", True), ("Japji Sahib", False),
                      ("Chaupai Sahib", False), ("Rehras Sahib", False),
                      ("Sukhmani Sahib", False), ("More…", False)])
    inner = f"""
  <div class="col" style="gap:3px;padding-top:2px">
    <div class="disp" style="font-size:22px;font-weight:700">Add a goal</div>
    <div style="font-size:13px;color:var(--muted)">
      Simran counts in minutes; a bani counts in paath</div>
  </div>
  <div class="col" style="gap:8px">
    <div class="eyebrow">What</div>
    <div class="row" style="gap:8px;flex-wrap:wrap">{chips}</div>
  </div>
  <div class="col" style="gap:8px">
    <div class="eyebrow">How long each time</div>
    <div class="row" style="gap:8px;flex-wrap:wrap">
      <div class="chip" style="background:var(--card2);color:var(--ink2);
        min-height:38px">5 min</div>
      <div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk);
        min-height:38px">11 min</div>
      <div class="chip" style="background:var(--card2);color:var(--ink2);
        min-height:38px">21 min</div>
      <div class="chip" style="background:var(--card2);color:var(--ink2);
        min-height:38px">31 min</div>
      <div class="chip" style="background:var(--card2);color:var(--ink2);
        min-height:38px">Custom</div>
    </div>
    <div style="font-size:11.5px;color:var(--muted);line-height:1.5">
      The recitation is five minutes long and loops with a soft crossfade for
      anything longer.</div>
  </div>
  <div class="col" style="gap:8px">
    <div class="eyebrow">When</div>
    <div class="card row" style="padding:12px 14px;gap:12px">
      <div style="color:var(--kesriInk);flex:none">{icon("bell", 19)}</div>
      <div class="col" style="flex:1">
        <div style="font-size:14px;font-weight:600">Remind me at 5:15 AM</div>
        <div style="font-size:12px;color:var(--muted)">Every day</div>
      </div>{toggle(True)}
    </div>
  </div>
  <div style="flex:1"></div>
  {primary("Save goal")}
"""
    return today().replace(nav("today"), "") + nav("today") + sheet(inner, 596)


def reader_complete() -> str:
    lines = [("ਸਲੋਕੁ ॥", False), ("ਤੇਰਾ ਕੀਤਾ ਜਾਤੋ ਨਾਹੀ ਮੈਨੋ ਜੋਗੁ ਕੀਤੋਈ ॥", False),
             ("ਮੈ ਨਿਰਗੁਣਿਆਰੇ ਕੋ ਗੁਣੁ ਨਾਹੀ ਆਪੇ ਤਰਸੁ ਪਇਓਈ ॥", False),
             ("ਤਰਸੁ ਪਇਆ ਮਿਹਰਾਮਤਿ ਹੋਈ ਸਤਿਗੁਰੁ ਸਜਣੁ ਮਿਲਿਆ ॥", True),
             ("ਨਾਨਕ ਨਾਮੁ ਮਿਲੈ ਤਾਂ ਜੀਵਾਂ ਤਨੁ ਮਨੁ ਥੀਵੈ ਹਰਿਆ ॥੧॥", False)]
    body = "".join(
        f'<div class="gur" style="font-size:19px;line-height:2;padding:7px 12px;'
        f'border-radius:12px;color:var(--ink);'
        f'{"background:var(--hl)" if hl else ""}">{t}</div>' for t, hl in lines)
    return f"""
<div class="pad col" style="gap:12px">
  {header("Japji Sahib", "38 of 38 pauris")}
  <div class="col" style="gap:2px;opacity:.55">{body}</div>
  <div class="card col" style="padding:18px 16px;gap:13px;border:1.5px solid var(--sage)">
    <div class="row" style="gap:12px">
      <div style="width:44px;height:44px;border-radius:22px;background:var(--sageSoft);
        color:var(--sage);display:flex;align-items:center;justify-content:center;
        flex:none">{icon("check", 24)}</div>
      <div class="col" style="flex:1">
        <div style="font-size:16px;font-weight:700">Japji Sahib complete</div>
        <div style="font-size:12.5px;color:var(--muted)">
          Logged in your diary · 5:52 AM</div>
      </div>
    </div>
    <div class="row" style="gap:10px;padding:2px 0 0">
      <div style="width:30px;height:30px;border-radius:10px;flex:none;
        background:var(--kesriSoft);display:flex;align-items:center;
        justify-content:center">{app_mark(19)}</div>
      <div class="col" style="flex:1">
        <div style="font-size:14px;font-weight:600;color:var(--kesriInk)">
          {EN["hazriMarked"]}</div>
        <div style="font-size:12px;color:var(--muted)">
          This is what marked it — the first thing finished today</div>
      </div>
    </div>
    <div class="row" style="gap:10px">
      <div class="btn" style="flex:1;background:var(--primary);color:var(--onPrimary);
        min-height:48px;font-size:14.5px">{icon("back", 18)}<div>Start again</div></div>
      <div class="btn" style="flex:1;background:var(--card2);color:var(--ink2);
        min-height:48px;font-size:14.5px"><div>Next bani</div></div>
    </div>
    <div style="font-size:11.5px;color:var(--muted);text-align:center;line-height:1.5">
      Start again takes you to the first line and clears where you left off.</div>
  </div>
</div>
"""


def goal_complete(t: dict = EN) -> str:
    """The one full-screen moment in the app: the day is finished.

    There was a second, on the first thing completed each day, and it is
    gone. A hazri is marked by one paath and most days hold several, so a
    takeover at the first of them interrupts the practice it is meant to
    honour -- and having fired already, it made the harder moment the
    quieter one. The hazri is still said at every step it happens: on the
    reader when a bani ends, on Today, and in the diary. Only this is
    ceremonial, and only on a day everything is done.

    The hazri gets a line here rather than the headline, because by now it
    was marked hours ago.
    """
    goals = [(t["japji"], "5:52 AM"), (t["simran"], "11 minutes"),
             (t["rehras"], "6:44 PM")]
    rows = "".join(
        f'<div class="row" style="gap:11px;padding:9px 0">'
        f'<div style="width:22px;height:22px;border-radius:11px;flex:none;'
        f'background:#6FE3A6;color:#06331F;display:flex;align-items:center;'
        f'justify-content:center">{icon("check", 13)}</div>'
        f'<div class="{t["cls"]}" style="font-size:14.5px;font-weight:600;'
        f'color:#EDECF6;flex:1">{n}</div>'
        f'<div style="font-size:13px;color:rgba(255,255,255,.55);font-weight:600">'
        f'{w}</div></div>' for n, w in goals)
    return f"""
<div style="position:absolute;inset:0;background:#070A1A"></div>
<div style="position:absolute;left:50%;top:150px;transform:translate(-50%,-50%);
  width:460px;height:460px;border-radius:230px;
  background:radial-gradient(circle,rgba(108,203,156,.20),rgba(7,10,26,0) 62%)"></div>
<div style="position:absolute;inset:0;display:flex;flex-direction:column;
  padding:56px 24px 26px">
  <div class="col" style="align-items:center;gap:16px">
    <div style="position:relative;width:112px;height:112px;flex:none">
      {ring(1.0, 112, 3, "#6FE3A6", "rgba(255,255,255,.08)")}
      <div style="position:absolute;inset:0;display:flex;align-items:center;
        justify-content:center">{app_mark(58, "rgba(255,255,255,.82)", "#6FE3A6")}</div>
    </div>
    <div class="disp gur" style="font-size:27px;font-weight:700;color:#fff;
      text-align:center;line-height:1.35">{t["goalsAllDone"]}</div>
    <div class="row" style="gap:9px;align-items:center">
      <div style="font-size:12.5px;color:rgba(255,255,255,.5);font-weight:600">
        Friday, 20 November</div>
      <div style="width:3px;height:3px;border-radius:2px;
        background:rgba(255,255,255,.3)"></div>
      <div class="gur" style="font-size:12.5px;color:rgba(255,255,255,.5);
        font-weight:600">5 ਮੱਘਰ 558</div>
    </div>
  </div>
  <div style="height:22px"></div>
  <div style="border-radius:20px;background:rgba(255,255,255,.055);
    border:1px solid rgba(255,255,255,.09);padding:6px 16px 8px">{rows}</div>
  <div class="row" style="gap:9px;justify-content:center;padding-top:16px">
    <div style="width:17px;height:17px;flex:none">
      {app_mark(17, "rgba(242,162,78,.85)", "#F2A24E")}</div>
    <div class="{t['cls']}" style="font-size:12.5px;color:rgba(255,255,255,.55);
      font-weight:600">{t["hazriWas"]}</div>
  </div>
  <div style="flex:1"></div>
  <div class="row" style="gap:9px;justify-content:center;padding-bottom:16px">
    <div class="{t['cls']}" style="font-size:13px;color:#6FE3A6;font-weight:700">
      {t["streak"]}</div>
    <div style="width:3px;height:3px;border-radius:2px;
      background:rgba(255,255,255,.3)"></div>
    <div class="{t['cls']}" style="font-size:13px;color:rgba(255,255,255,.5);
      font-weight:600">{t["gentle"]}</div>
  </div>
  <div class="btn" style="background:#6FE3A6;color:#06331F">
    {icon("diary", 19)}<div class="{t['cls']}">{t["seeDiary"]}</div></div>
  <div class="{t['cls']}" style="text-align:center;font-size:14px;
    color:rgba(255,255,255,.55);font-weight:600;padding-top:16px">{t["done"]}</div>
</div>
"""


def diary_today() -> str:
    """One day in the diary, opened.

    The hazri at the top and what earned it underneath, still tickable --
    Phase 1 lets any of the last seven days be corrected by hand and that
    does not change.
    """
    items = [("Japji Sahib", "5:52 AM", True), ("Naam Simran", "11 minutes", True),
             ("Rehras Sahib", "not yet · 6:40 PM", False),
             ("Kirtan Sohila", "not yet", False)]
    rows = "".join(
        f'<div class="row" style="gap:12px;padding:12px 0">'
        f'<div style="width:24px;height:24px;border-radius:12px;flex:none;'
        + (f'background:var(--sage);color:#fff;display:flex;align-items:center;'
           f'justify-content:center">{icon("check", 14)}'
           if on else f'border:2px solid var(--rule)">')
        + f'</div>'
        f'<div style="font-size:14.5px;font-weight:600;flex:1;'
        f'color:{"var(--ink)" if on else "var(--muted)"}">{n}</div>'
        f'<div style="font-size:12.5px;color:var(--muted);font-weight:600">{w}</div>'
        f'</div>' for n, w, on in items)
    return f"""
<div class="pad col" style="gap:14px">
  {header("Friday, 20 November", "5 ਮੱਘਰ 558")}
  <div class="card row" style="padding:16px;gap:14px;
    background:linear-gradient(135deg,var(--kesri),#B8560A);color:#fff">
    <div style="width:58px;height:58px;border-radius:29px;flex:none;
      background:rgba(255,255,255,.17);display:flex;align-items:center;
      justify-content:center">{app_mark(34, "#fff", "#fff")}</div>
    <div class="col" style="flex:1;gap:2px">
      <div class="disp" style="font-size:19px;font-weight:700">
        {EN["hazriMarked"]}</div>
      <div style="font-size:13px;opacity:.9">{EN["hazriWith"]}</div>
    </div>
  </div>
  <div class="col" style="gap:4px">
    <div class="eyebrow">What you completed</div>
    <div style="font-size:12px;color:var(--muted)">
      Tick anything you completed on this day</div>
  </div>
  <div class="card col" style="padding:4px 16px">{rows}</div>
  <div class="card row" style="padding:14px 16px">
    <div class="col" style="flex:1;align-items:center;gap:1px">
      <div class="disp" style="font-size:21px;font-weight:700">2</div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">paath</div>
    </div>
    <div style="width:1px;align-self:stretch;background:var(--rule)"></div>
    <div class="col" style="flex:1;align-items:center;gap:1px">
      <div class="disp" style="font-size:21px;font-weight:700">11</div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">
        simran minutes</div>
    </div>
    <div style="width:1px;align-self:stretch;background:var(--rule)"></div>
    <div class="col" style="flex:1;align-items:center;gap:1px">
      <div class="disp" style="font-size:21px;font-weight:700">11</div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">
        days in a row</div>
    </div>
  </div>
  {quiet("One paath or five, a single sitting of simran — any of them "
         "marks the day’s hazri. The count is what you did, not what you "
         "owed.")}
  <div style="height:86px"></div>
</div>
{nav("diary")}
"""


def diary_month() -> str:
    """The diary, a month at a time, with the days a hazri was marked.

    Phase 1\u2019s grid and its grace days, now saying what the ticks mean: a
    filled day is a day the hazri was marked.
    """
    import calendar as _cal
    weeks = _cal.Calendar(firstweekday=0).monthdayscalendar(2026, 11)
    # Two different questions, so two dots. The hazri asks "did you turn up",
    # and one paath or one sitting of simran answers it. The goal asks "did
    # you finish everything you set yourself", which is a harder day and a
    # rarer dot -- that gap is the honest picture of a month and the reason
    # one dot could never carry both.
    hazri = set(range(1, 21)) - {2, 6, 9}
    goals = {1, 4, 5, 8, 12, 15, 16, 19, 20}
    grace = {2, 6}
    cells = ""
    for wk in weeks:
        for d in wk:
            if d == 0:
                cells += '<div></div>'
                continue
            today_cell = d == 20
            past = d <= 20
            def dot(on, colour):
                if not past:
                    return '<div style="width:6px;height:6px"></div>'
                return (f'<div style="width:6px;height:6px;border-radius:3px;'
                        f'background:{colour if on else "var(--rule)"}"></div>')
            dots = (dot(d in hazri or d in grace,
                        "var(--teal)" if d in grace else "var(--kesri)")
                    + dot(d in goals, "var(--sage)"))
            ring = ("border:1.5px solid var(--kesri)" if today_cell
                    else "border:1.5px solid transparent")
            lit = d in hazri or d in grace
            cells += (
                f'<div class="col" style="align-items:center;justify-content:center;'
                f'gap:4px;height:44px;border-radius:13px;{ring};'
                f'background:{"var(--card)" if lit else "transparent"}">'
                f'<div style="font-size:13px;'
                f'font-weight:{700 if today_cell else 600};'
                f'color:{"var(--ink)" if lit or today_cell else "var(--muted)"}">'
                f'{d}</div>'
                f'<div class="row" style="gap:3px">{dots}</div></div>')
    heads = "".join(
        f'<div style="text-align:center;font-size:11px;font-weight:700;'
        f'color:var(--muted)">{c}</div>' for c in "MTWTFSS")
    return f"""
<div class="pad col" style="gap:13px">
  {header("Nitnem Diary", "Every day you marked your hazri", left="menu")}
  <div class="card row" style="padding:16px;gap:14px">
    <div style="width:56px;height:56px;border-radius:18px;flex:none;
      background:var(--kesriSoft);display:flex;align-items:center;
      justify-content:center">{app_mark(32)}</div>
    <div class="col" style="flex:1;gap:1px">
      <div class="disp" style="font-size:23px;font-weight:700;line-height:1.1">
        11 days in a row</div>
      <div style="font-size:12.5px;color:var(--muted)">
        A gentle streak · both grace days used this month</div>
    </div>
  </div>
  <div class="row" style="justify-content:space-between;padding-top:2px">
    <div style="font-size:15px;font-weight:700">November 2026</div>
    <div class="row" style="gap:14px;color:var(--muted)">
      {icon("back", 18)}<div style="transform:rotate(180deg)">{icon("back", 18)}</div>
    </div>
  </div>
  <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:4px">
    {heads}{cells}
  </div>
  <div class="row" style="gap:13px;justify-content:center;flex-wrap:wrap;
    padding-top:2px">
    <div class="row" style="gap:6px"><div style="width:7px;height:7px;
      border-radius:4px;background:var(--kesri)"></div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">
        Hazri</div></div>
    <div class="row" style="gap:6px"><div style="width:7px;height:7px;
      border-radius:4px;background:var(--sage)"></div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">
        All goals met</div></div>
    <div class="row" style="gap:6px"><div style="width:7px;height:7px;
      border-radius:4px;background:var(--teal)"></div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">
        Grace day</div></div>
  </div>
  <div class="card row" style="padding:14px 16px">
    <div class="col" style="flex:1;align-items:center;gap:1px">
      <div class="disp" style="font-size:21px;font-weight:700;
        color:var(--kesri)">17</div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">
        hazri days</div>
    </div>
    <div style="width:1px;align-self:stretch;background:var(--rule)"></div>
    <div class="col" style="flex:1;align-items:center;gap:1px">
      <div class="disp" style="font-size:21px;font-weight:700;
        color:var(--sage)">9</div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">
        goals met</div>
    </div>
    <div style="width:1px;align-self:stretch;background:var(--rule)"></div>
    <div class="col" style="flex:1;align-items:center;gap:1px">
      <div class="disp" style="font-size:21px;font-weight:700">54</div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">paath</div>
    </div>
  </div>
  <div style="font-size:11.5px;color:var(--muted);text-align:center">
    Kept on this phone. Synced only if you turned sync on.</div>
  <div style="height:86px"></div>
</div>
{nav("diary")}
"""


def sync_states() -> str:
    states = [
        ("check", "Synced", "Everything is up to date · 2 minutes ago",
         "var(--sageSoft)", "var(--sage)"),
        ("globe", "No connection", "Carry on — your paath is saved on this phone "
         "and goes up when you are back", "var(--card2)", "var(--muted)"),
        ("share", "Sending 3 changes", "2 paath and a Simran session",
         "var(--kesriSoft)", "var(--kesriInk)"),
    ]
    cards = "".join(
        f'<div class="card row" style="padding:14px;gap:12px">'
        f'<div style="width:40px;height:40px;border-radius:13px;background:{bg};'
        f'color:{fg};display:flex;align-items:center;justify-content:center;'
        f'flex:none">{icon(i, 20)}</div>'
        f'<div class="col" style="flex:1">'
        f'<div style="font-size:14.5px;font-weight:700">{t}</div>'
        f'<div style="font-size:12.5px;color:var(--muted);line-height:1.45">{s}</div>'
        f'</div></div>' for i, t, s, bg, fg in states)
    return f"""
<div class="pad col" style="gap:14px">
  {header("Sync", "What happens, and when")}
  <div class="col" style="gap:9px">
    <div class="eyebrow">The three states</div>
    {cards}
  </div>
  <div class="card col" style="padding:15px;gap:9px;background:var(--card2);
    box-shadow:none">
    <div style="font-size:13.5px;font-weight:700">Hazri works with no signal</div>
    <div style="font-size:13px;color:var(--ink2);line-height:1.6">
      Every bani, its recitation, the calendar and your diary are on this phone.
      Nothing you do needs a connection. Sync only carries your group counts and
      your diary up, and it waits quietly until there is signal.</div>
  </div>
  <div class="card col" style="padding:6px 16px">
    <div class="row" style="gap:12px;padding:13px 0">
      <div class="col" style="flex:1">
        <div style="font-size:14px;font-weight:600">Sync my diary</div>
        <div style="font-size:12px;color:var(--muted)">
          Off keeps everything on this phone only</div>
      </div>{toggle(True)}
    </div>
    <div style="height:1px;background:var(--rule)"></div>
    <div class="row" style="gap:12px;padding:13px 0">
      <div class="col" style="flex:1">
        <div style="font-size:14px;font-weight:600">Only on Wi‑Fi</div>
        <div style="font-size:12px;color:var(--muted)">Saves mobile data</div>
      </div>{toggle(False)}
    </div>
  </div>
</div>
"""


def notifications() -> str:
    groups = [
        ("Your own practice", [
            ("Nitnem reminders", "At your goal times", True),
            ("Simran reminder", "5:15 AM", True),
            ("Gurpurab", "The evening before and the morning of", True)]),
        ("Your groups", [
            ("A goal is close", "When the group passes 90%", True),
            ("Someone joined", "New members in your groups", False),
            ("Daily group summary", "One message, at 9 PM", False)]),
        ("Global Simran", [
            ("Large gatherings", "When thousands are sitting together", False)]),
    ]
    out = ""
    for title, items in groups:
        rows = ""
        for idx, (t, s, on) in enumerate(items):
            rows += (f'<div class="row" style="gap:12px;padding:13px 0">'
                     f'<div class="col" style="flex:1">'
                     f'<div style="font-size:14px;font-weight:600">{t}</div>'
                     f'<div style="font-size:12px;color:var(--muted)">{s}</div></div>'
                     f'{toggle(on)}</div>')
            if idx < len(items) - 1:
                rows += '<div style="height:1px;background:var(--rule)"></div>'
        out += (f'<div class="col" style="gap:8px">'
                f'<div class="eyebrow">{title}</div>'
                f'<div class="card col" style="padding:4px 16px">{rows}</div></div>')
    return f"""
<div class="pad col" style="gap:14px">
  {header("Notifications")}
  {out}
  <div style="font-size:11.5px;color:var(--muted);line-height:1.5;text-align:center">
    Hazri never sends anything you did not ask for, and never an advertisement.</div>
</div>
"""


SCREENS = [
    ("29-Simran", "Simran", simran_tab),
    ("30-Today", "Today", today),
    ("31-GroupDetail", "Group — shared goal", group_detail),
    ("32-Profile", "Join the sangat", profile),
    ("33-Account", "Your account", account),
    ("34-VerifyEmail", "Verify your email", verify_email),
    ("35-PrivacyData", "Privacy & my data", privacy_data),
    ("36-UnlockSheet", "Join the sangat — sheet", unlock_sheet),
    ("37-SettingsMenu", "Menu", settings_menu),
    ("38-SangatHome", "Sangat", sangat_home),
    ("39-CreateGroup", "Create a group", create_group),
    ("40-SetGoal", "Shared goal", set_goal),
    ("41-Invite", "Invite", invite),
    ("42-LogPaath", "Log a paath", log_paath),
    ("43-Vichar", "Vichar", vichar_home),
    ("44-VicharArticle", "Vichar — an article", vichar_article),
    ("45-VicharTopic", "Vichar — a reference entry", vichar_topic),
    ("46-VicharSearch", "Vichar — search", vichar_search),
    ("47-AddGoal", "Add a goal", add_goal),
    ("48-ReaderComplete", "Reader — complete", reader_complete),
    ("49-Sync", "Sync", sync_states),
    ("50-Notifications", "Notifications", notifications),
    ("52-CodeProblems", "That code did not work", code_problems),
    ("53-RestoreOrNew", "Restore, or start fresh", restore_or_new),
    ("54-Restored", "Your sangat is back", restored),
    ("56-DiaryToday", "Diary — one day", diary_today),
    ("57-Diary", "Diary — the month", diary_month),
    ("58-TodayHazri", "Today — hazri marked", today_hazri),
    ("59-TodayNotYet", "Today — hazri not yet", today_not_yet),
    ("60-TodayPunjabi", "Today — in Punjabi", today_punjabi),
    ("61-GoalComplete", "All of today's goals are done", goal_complete),
]


def main() -> int:
    os.makedirs(OUT, exist_ok=True)
    written = []
    for stem, title, build in SCREENS:
        body = build()
        for theme in ("light", "dark"):
            head = HEAD.format(title=f"{title} — {theme}", light=css_vars("light"),
                               dark=css_vars("dark"), cls=theme)
            path = os.path.join(OUT, f"{stem}.{theme}.html")
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(head + body + TAIL)
            written.append(os.path.relpath(path, ROOT))
    for p in written:
        print(f"wrote {p}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
