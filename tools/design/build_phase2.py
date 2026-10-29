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
    # added 2026-10-10 for the profile and sangat screens, 100-103
    "edit": '<path d="M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
    "verified": '<path d="M12 3l2.4 1.8 3 .2.9 2.9 2.2 2-1 2.8 1 2.9-2.2 2-.9 2.9-3 .2L12 21l-2.4-1.8-3-.2-.9-2.9-2.2-2 1-2.9-1-2.8 2.2-2 .9-2.9 3-.2z"/><path d="M8.5 12.2l2.4 2.4 4.6-4.8"/>',
    "cloud": '<path d="M7 18.5a4.5 4.5 0 0 1-.6-9A6 6 0 0 1 18 8.6a4 4 0 0 1-.5 7.9"/><path d="M12 12v8M9 15l3-3 3 3"/>',
    "restore": '<path d="M4 12a8 8 0 1 0 2.4-5.7"/><path d="M4 4v4.5h4.5"/><path d="M12 8v4l3 2"/>',
    "shield": '<path d="M12 3l7.5 3v5.5c0 4.6-3.2 8.2-7.5 9.5-4.3-1.3-7.5-4.9-7.5-9.5V6z"/><path d="M9 12l2.2 2.2L15.5 10"/>',
    "code": '<rect x="3" y="6" width="18" height="12" rx="3"/><path d="M7 12h.01M10.5 12h.01M14 12h.01M17.5 12h.01"/>',
    "more": '<circle cx="12" cy="5.5" r="1.3" fill="currentColor"/><circle cx="12" cy="12" r="1.3" fill="currentColor"/><circle cx="12" cy="18.5" r="1.3" fill="currentColor"/>',
    "sunrise": '<path d="M3 18h18"/><path d="M7 18a5 5 0 0 1 10 0"/><path d="M12 4v4M9.5 6.5L12 4l2.5 2.5"/>',
    "sunset": '<path d="M3 18h18"/><path d="M7 18a5 5 0 0 1 10 0"/><path d="M12 4v4M9.5 5.5L12 8l2.5-2.5"/>',
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
    "cls": "", "lh": "1.15", "rg": "0px", "leading": "1.45",
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
    "cls": "gur", "lh": "1.5", "rg": "4px", "leading": "1.75",
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
                f'<div class="{t["cls"]}" style="font-size:12px;'
                f'line-height:{t["leading"]};{text}">{label}</div></div>')
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
           right: str | None = None, t: dict = EN) -> str:
    r = (f'<div style="width:44px;height:44px;border-radius:14px;display:flex;'
         f'align-items:center;justify-content:center;background:var(--card);'
         f'box-shadow:var(--shadow)">{icon(right)}</div>' if right else
         '<div style="width:44px"></div>')
    return (f'<div class="row" style="justify-content:space-between;gap:10px">'
            f'<div class="row" style="gap:10px">'
            f'<div style="width:40px;height:40px;border-radius:13px;display:flex;'
            f'align-items:center;justify-content:center;background:var(--card);'
            f'box-shadow:var(--shadow)">{icon(left, 20)}</div>'
            f'<div class="col" style="gap:{t["rg"]}">'
            f'<div class="disp" style="font-size:24px;font-weight:700;'
            f'line-height:{t["lh"]}">{title}</div>'
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
    <div class="col" style="flex:1;gap:{t["rg"]}">
      <div class="disp" style="font-size:17px;font-weight:700;
        line-height:{t["lh"]}">{t["hazriMarked"]}</div>
      <div class="{t['cls']}" style="font-size:12.5px;opacity:.9">{t["hazriWith"]}</div>
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
    <div class="col" style="flex:1;gap:{t["rg"]}">
      <div class="disp" style="font-size:17px;font-weight:700;color:var(--ink2);
        line-height:{t["lh"]}">{t["hazriPending"]}</div>
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
        f'<div class="{t["cls"]}" style="font-size:13.5px;font-weight:600;'
        f'flex:1;line-height:{t["leading"]}">{n}</div>'
        f'<div style="font-size:12.5px;color:var(--muted);font-weight:600">{w}</div>'
        f'</div>' for n, w, p in goals)
    return f"""
<div class="pad col" style="gap:13px">
  {header(t["today"], t["date"], left="menu", t=t)}
  {banner if banner is not None else join_banner()}
  <div class="card col" style="padding:16px;gap:12px">
    <div class="row" style="justify-content:space-between">
      <div class="col" style="gap:{t["rg"]}">
        <div class="eyebrow {t['cls']}" style="line-height:{t["leading"]}">
          {t["goals"]}</div>
        <div class="disp {t['cls']}" style="font-size:20px;font-weight:700;
          line-height:{t["lh"]}">{t["goalsDone"]}</div>
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
    <div class="col" style="flex:1;gap:{t["rg"]}">
      <div class="{t['cls']}" style="font-size:12px;color:var(--muted);
        font-weight:700;line-height:{t["leading"]}">{t["gurpurabWhen"]}</div>
      <div class="{t['cls']}" style="font-size:14px;font-weight:700;
        line-height:{t["lh"]}">{t["gurpurab"]}</div>
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
      <div class="col" style="flex:1;gap:{t["rg"]}">
        <div class="{t['cls']}" style="font-size:14.5px;font-weight:700;
          line-height:{t["lh"]}">{t["vichar"]}</div>
        <div class="{t['cls']}" style="font-size:12px;color:var(--muted);
          line-height:{t["leading"]}">{t["vicharSource"]}</div>
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

    It has exactly one trigger, and no fallback. The last goal of the day
    is completed and this appears. **Somebody who has set no goals never
    sees it at all** -- not on their first paath, not on their fiftieth --
    and that is deliberate rather than a gap: without a goal there is no
    day to finish, and a screen that fired anyway would be congratulating
    somebody for nothing.

    There was a second moment, on the first thing completed each day, and
    it is gone. A hazri is marked by one paath and most days hold several,
    so a takeover at the first of them interrupts the practice it is meant
    to honour -- and having fired already, it made the harder moment the
    quieter one. The hazri is still said at every step it happens: on the
    reader when a bani ends, on Today, and at the head of the day in the
    diary. Those never depend on a goal existing.

    The hazri gets a line here rather than the headline, because by the
    time this appears it was marked hours ago.
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


# ------------------------------------------- chosen 2026-10-07 (05-today, 09-diary)

def app_bar(greeting: str) -> str:
    """Today's app bar: design option D, chosen 2026-10-07 (05-today.md T11).

    Today only; every other tab keeps its own header. Neela in light and
    `card2` in dark, because the dark theme's `primary` is kesri. The first
    card below it overlaps the band by 32 px.
    """
    btn = ('width:44px;height:44px;border-radius:{r}px;flex:none;display:flex;'
           'align-items:center;justify-content:center;background:rgba(255,255,255,.12);'
           'color:#fff')
    person = ('<svg class="i" width="22" height="22" viewBox="0 0 24 24">'
              '<circle cx="12" cy="8.2" r="3.7"/><path d="M4.8 20.2a7.2 7.2 0 0 1 14.4 0"/></svg>')
    return f"""
<style>.band{{background:#262C63}}.app.dark .band{{background:var(--card2)}}</style>
<div class="band col" style="gap:14px;padding:22px 20px 46px;color:#fff;
  border-radius:0 0 28px 28px">
  <div class="row" style="gap:10px">
    <div style="{btn.format(r=13)}">{icon("menu", 20)}</div>
    <div class="row" style="gap:8px;flex:1">{app_mark(28, "#fff", "#F2A24E")}
      <div class="disp" style="font-size:22px;font-weight:700;line-height:1">Hazri</div></div>
    <div style="{btn.format(r=22)}">{person}</div>
  </div>
  <div class="col" style="padding-left:2px">
    <div class="disp" style="font-size:24px;font-weight:700;line-height:1.15">{greeting}</div>
    <div style="font-size:13px;color:rgba(255,255,255,.78);font-weight:500">
      Wednesday, 7 October</div>
  </div>
</div>"""


def streak_strip() -> str:
    """The Nitnem streak on Today: option 3, the week strip (05-today.md T12).

    Shown only from two days; the last seven days, today ringed.
    """
    days = "".join(
        f'<div class="col" style="align-items:center;gap:4px">'
        f'<div style="font-size:11px;font-weight:700;color:var(--muted)">{d}</div>'
        f'<div style="width:22px;height:22px;border-radius:11px;background:var(--kesri);'
        + ('box-shadow:0 0 0 2px var(--card),0 0 0 4px var(--kesriInk)' if i == 6 else '')
        + '"></div></div>'
        for i, d in enumerate("TFSSMTW"))
    return f"""
  <div class="card row" style="padding:12px 16px;gap:14px">
    <div class="col" style="flex:none">
      <div class="disp" style="font-size:26px;font-weight:700;line-height:1;
        color:var(--kesriInk)">12</div>
      <div style="font-size:12px;color:var(--muted);font-weight:600;line-height:1.25">
        days of Nitnem<br>in a row</div>
    </div>
    <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:4px;flex:1">{days}</div>
  </div>"""


def goal_widget() -> str:
    """The goal widget of 04-goals.md 7.1: items met of items in scope."""
    tick = (f'<div style="width:24px;height:24px;border-radius:12px;flex:none;'
            f'background:var(--sage);color:#fff;display:flex;align-items:center;'
            f'justify-content:center">{icon("check", 14)}</div>')
    empty = ('<div style="width:24px;height:24px;border-radius:12px;flex:none;'
             'border:3px solid var(--rule)"></div>')
    rows = "".join(
        f'<div class="row" style="gap:10px">{mark}'
        f'<div style="font-size:14px;font-weight:600;flex:1">{name}</div>'
        f'<div style="font-size:13px;color:var(--muted);font-weight:600">{what}</div></div>'
        for mark, name, what in [(tick, "Japji Sahib", "1 of 1"),
                                 (empty, "Naam Simran", "11 min")])
    return f"""
  <div class="card col" style="padding:16px;gap:12px">
    <div class="row" style="justify-content:space-between">
      <div class="col">
        <div class="eyebrow">Today’s goal</div>
        <div class="disp" style="font-size:20px;font-weight:700;line-height:1.15">
          1 of 2 done</div>
      </div>
      {ring(0.5, 52, 7)}
    </div>
    <div class="col" style="gap:9px;border-top:1px solid var(--rule);padding-top:11px">
      {rows}
    </div>
  </div>"""


def today_app_bar() -> str:
    """Today with a profile: the app bar, hazri, the streak, the goal."""
    return f"""
{app_bar("Welcome, Harpreet")}
<div class="col" style="gap:13px;padding:0 20px;margin-top:-32px">
  {hazri_banner(dict(EN, hazriWith="Marked at 5:10 AM, with Japji Sahib"))}
  {streak_strip()}
  {goal_widget()}
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    {icon("simran", 20)}<div>Start Naam Simran · 11 min</div></div>
  {vichar_card()}
</div>
{nav("today")}
"""


def today_no_profile() -> str:
    """Today on the first day: no profile, no goal, nothing yet (05-today.md T-a).

    The profile banner is the first card, so it overlaps the band; no streak
    card, because there is no streak.
    """
    return f"""
{app_bar("Welcome")}
<div class="col" style="gap:13px;padding:0 20px;margin-top:-32px">
  <div class="card row" style="padding:14px 16px;gap:13px;box-shadow:0 10px 24px rgba(27,29,58,.16)">
    <div style="width:46px;height:46px;border-radius:23px;flex:none;
      background:var(--kesriSoft);color:var(--kesriInk);display:flex;
      align-items:center;justify-content:center"><svg class="i" width="22" height="22"
      viewBox="0 0 24 24"><circle cx="12" cy="8.2" r="3.7"/>
      <path d="M4.8 20.2a7.2 7.2 0 0 1 14.4 0"/></svg></div>
    <div class="col" style="flex:1">
      <div style="font-size:15px;font-weight:700;line-height:1.2">Set up your profile</div>
      <div style="font-size:12.5px;color:var(--muted)">
        Add your name and email to personalise the app.</div>
    </div>
    <div style="color:var(--muted);transform:rotate(180deg)">{icon("back", 18)}</div>
  </div>
  {hazri_pending()}
  <div class="card row" style="padding:16px;gap:13px">
    <div style="width:46px;height:46px;border-radius:14px;flex:none;
      background:var(--sageSoft);color:var(--sage);display:flex;
      align-items:center;justify-content:center">{icon("plus", 22)}</div>
    <div class="col" style="flex:1">
      <div class="disp" style="font-size:17px;font-weight:700;line-height:1.15">
        Set a daily goal</div>
      <div style="font-size:12.5px;color:var(--muted)">
        Choose the banis you want to recite each day.</div>
    </div>
    <div style="color:var(--muted);transform:rotate(180deg)">{icon("back", 18)}</div>
  </div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    {icon("nitnem", 20)}<div>Start Japji Sahib</div></div>
  {vichar_card()}
</div>
{nav("today")}
"""


def diary_streak() -> str:
    """The Diary month with the streak card of option 2 (09-diary.md D12).

    Dots follow 04-goals.md 4.7: the first is hazri; the second appears only
    on a day that had a goal. Grace days are never shown (D8).
    """
    import calendar as _cal
    weeks = _cal.Calendar(firstweekday=0).monthdayscalendar(2026, 10)
    goal_days = {3: True, 4: True, 5: False, 6: True, 7: False}
    cells = ""
    for wk in weeks:
        for d in wk:
            if d == 0:
                cells += '<div></div>'
                continue
            past = d <= 7
            dots = ""
            if past:
                dots = ('<div style="width:6px;height:6px;border-radius:3px;'
                        'background:var(--kesri)"></div>')
                if d in goal_days:
                    dots += ('<div style="width:6px;height:6px;border-radius:3px;'
                             f'background:{"var(--sage)" if goal_days[d] else "var(--rule)"}'
                             '"></div>')
            border = "var(--kesri)" if d == 7 else "transparent"
            cells += (
                f'<div class="col" style="align-items:center;justify-content:center;'
                f'gap:4px;height:44px;border-radius:13px;border:1.5px solid {border};'
                f'background:{"var(--card)" if past else "transparent"}">'
                f'<div style="font-size:13px;font-weight:{700 if d == 7 else 600};'
                f'color:{"var(--ink)" if past else "var(--muted)"}">{d}</div>'
                f'<div class="row" style="gap:3px;height:6px">{dots}</div></div>')
    heads = "".join(
        f'<div style="text-align:center;font-size:11px;font-weight:700;'
        f'color:var(--muted)">{c}</div>' for c in "MTWTFSS")
    legend = "".join(
        f'<div class="row" style="gap:6px"><div style="width:7px;height:7px;'
        f'border-radius:4px;background:{c}"></div><div style="font-size:11.5px;'
        f'color:var(--muted);font-weight:600">{n}</div></div>'
        for c, n in [("var(--kesri)", "Hazri"), ("var(--sage)", "Goal met")])
    stat = ('<div class="col" style="flex:1;align-items:center;gap:1px">'
            '<div class="disp" style="font-size:21px;font-weight:700;color:{c}">{n}</div>'
            '<div style="font-size:11.5px;color:var(--muted);font-weight:600">{l}</div></div>')
    rule = '<div style="width:1px;align-self:stretch;background:var(--rule)"></div>'
    return f"""
<div class="pad col" style="gap:13px">
  {header("Nitnem Diary", "Every day you marked your hazri", left="menu")}
  <div class="card row" style="padding:14px 8px">
    <div class="col" style="flex:1;align-items:center;gap:2px">
      <div class="disp" style="font-size:30px;font-weight:700;line-height:1;
        color:var(--kesriInk)">12</div>
      <div style="font-size:12.5px;color:var(--muted);font-weight:600">days in a row now</div>
    </div>
    {rule}
    <div class="col" style="flex:1;align-items:center;gap:2px">
      <div class="disp" style="font-size:30px;font-weight:700;line-height:1">30</div>
      <div style="font-size:12.5px;color:var(--muted);font-weight:600">your longest</div>
    </div>
  </div>
  <div class="row" style="justify-content:space-between;padding-top:2px">
    <div style="font-size:15px;font-weight:700">October 2026</div>
    <div class="row" style="gap:14px;color:var(--muted)">
      {icon("back", 18)}<div style="transform:rotate(180deg)">{icon("back", 18)}</div>
    </div>
  </div>
  <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:4px">
    {heads}{cells}
  </div>
  <div class="row" style="gap:16px;justify-content:center">{legend}</div>
  <div class="card row" style="padding:14px 16px">
    {stat.format(c="var(--kesri)", n=7, l="hazri days")}{rule}
    {stat.format(c="var(--sage)", n=3, l="goal days met")}{rule}
    {stat.format(c="var(--ink)", n=9, l="paath")}
  </div>
  <div style="font-size:11.5px;color:var(--muted);text-align:center">
    Kept on this phone. Backed up each week with your profile.</div>
</div>
{nav("diary")}
"""


# ------------------------------------------- the Simran tab as it ships (07-simran)

SKY = {"live": "#3DBE7B", "here": "#5B8DEF", "you": "#F2A24E"}


def sky_globe(size: int, you: bool = True) -> str:
    """The globe of `simran_globe.dart`: a lit sea, a fine grid, bright coasts.

    Dots follow 07-simran.md DR1-DR4: orange for you (with its halo), green
    for Live, blue for Here today. The threads of design 29 run from your dot
    to every other (DR6). Without a profile there is no orange dot, so every
    dot is joined into one web instead (DR7).
    """
    kind = {"you": "you", "today": "live", "member": "here"}
    pts = []
    for lat, lon, k in PEOPLE:
        if k == "you" and not you:
            continue
        p = project(lat, lon)
        if p is None:
            continue
        x, y = p
        c = SKY[kind[k]]
        if k == "you":
            pts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="12" fill="#6FC3D3" opacity="0.18"/>'
                       f'<circle cx="{x:.1f}" cy="{y:.1f}" r="7.5" fill="#6FC3D3" opacity="0.28"/>'
                       f'<circle cx="{x:.1f}" cy="{y:.1f}" r="4.6" fill="{c}"/>')
        else:
            r = 3.4 if k == "today" else 2.8
            pts.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r * 2.2:.1f}" fill="{c}" opacity="0.22"/>'
                       f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{c}"/>')
    grid = graticule().replace('stroke="#2A3A6B" stroke-width="0.8" opacity="0.55"',
                               'stroke="#2F4E96" stroke-width="0.7" opacity="0.6"')
    coast = coastline().replace('stroke="#41609E" stroke-width="1"',
                                'stroke="#8FD4FF" stroke-width="0.9" opacity="0.8"')
    return (
        f'<svg width="{size}" height="{size}" viewBox="10 10 300 300" style="display:block;overflow:visible">'
        '<defs><radialGradient id="sea"><stop offset="0" stop-color="#071232"/>'
        '<stop offset=".72" stop-color="#071232"/><stop offset="1" stop-color="#0A1F52"/>'
        '</radialGradient><radialGradient id="glow"><stop offset=".72" stop-color="#6FC3D3" '
        'stop-opacity=".22"/><stop offset="1" stop-color="#6FC3D3" stop-opacity="0"/>'
        '</radialGradient></defs>'
        '<circle cx="160" cy="160" r="200" fill="url(#glow)"/>'
        '<circle cx="160" cy="160" r="150" fill="url(#sea)"/>'
        f'{grid}{coast}{threads() if you else web()}'
        '<circle cx="160" cy="160" r="149.5" fill="none" stroke="#7FC4FF" stroke-width="2" opacity=".85"/>'
        f'{"".join(pts)}</svg>')


def web(k: int = 2) -> str:
    """Without a profile: one web joining every dot (07-simran.md DR7).

    The shortest tree that reaches every dot, so no cluster is left on its
    own, plus each dot's k nearest. Distances are great-circle, each pair is
    drawn once, and only when both ends are on the visible side -- the same
    rule a thread from your dot follows.
    """
    others = [(lat, lon) for lat, lon, kind in PEOPLE if kind != "you"]

    def gc(a, b):
        p1, l1, p2, l2 = map(math.radians, (a[0], a[1], b[0], b[1]))
        return math.acos(max(-1.0, min(1.0, math.sin(p1) * math.sin(p2)
                                       + math.cos(p1) * math.cos(p2) * math.cos(l1 - l2))))
    pairs = set()
    # Prim's tree: every dot joins the web by its shortest link to it.
    inside, rest = {0}, set(range(1, len(others)))
    while rest:
        _, i, j = min((gc(others[i], others[j]), i, j) for i in inside for j in rest)
        pairs.add((min(i, j), max(i, j)))
        inside.add(j)
        rest.discard(j)
    for i, a in enumerate(others):
        near = sorted((gc(a, b), j) for j, b in enumerate(others) if j != i)[:k]
        for _, j in near:
            pairs.add((min(i, j), max(i, j)))
    out = []
    for i, j in sorted(pairs):
        p, q = project(*others[i]), project(*others[j])
        if p is None or q is None:
            continue
        mx, my = (p[0] + q[0]) / 2, (p[1] + q[1]) / 2
        dx, dy = q[0] - p[0], q[1] - p[1]
        cx, cy = mx - dy * 0.14, my + dx * 0.14
        out.append(f'<path d="M{p[0]:.1f} {p[1]:.1f} Q{cx:.1f} {cy:.1f} {q[0]:.1f} {q[1]:.1f}" '
                   f'fill="none" stroke="#F2A24E" stroke-width="0.7" opacity="0.28"/>')
    return "".join(out)


def stars() -> str:
    """A fixed field, seeded like `_Starfield`, so it is the same every build."""
    import random
    rnd = random.Random(7)
    return "".join(
        f'<circle cx="{rnd.uniform(0, 390):.0f}" cy="{rnd.uniform(0, 760):.0f}" '
        f'r="{rnd.choice([0.6, 0.8, 1.1]):.1f}" fill="#fff" opacity="{rnd.uniform(.25, .8):.2f}"/>'
        for _ in range(90))


def simran_sky(state: str = "rest") -> str:
    """The Simran tab to the reader's mock-up of 2026-09-20, with 07-simran.md.

    `rest` with a profile, `sitting` while a sitting runs, `noprofile` for
    somebody without one (NP1-NP3). One screen in all three: the countdown
    takes the presence line's place while a sitting runs.
    """
    serif = "font-family:'Playfair Display','Noto Serif Gurmukhi',serif"
    dark_btn = ('width:40px;height:40px;border-radius:13px;display:flex;flex:none;'
                'align-items:center;justify-content:center;background:rgba(255,255,255,.09);color:#fff')
    rule = ('<div style="flex:1;max-width:110px;height:1px;background:linear-gradient'
            '({d},rgba(242,162,78,0),rgba(242,162,78,.45))"></div>')
    legend = "".join(
        f'<div class="row" style="gap:6px"><div style="width:8px;height:8px;border-radius:4px;'
        f'background:{c}"></div><div style="font-size:11.5px;color:rgba(255,255,255,.72);'
        f'font-weight:600">{t}</div></div>'
        for c, t in [(SKY["you"], "You"), (SKY["live"], "Live"), (SKY["here"], "Here today")])
    naam = ""
    if state == "sitting":
        for x, y, o in [(96, 250, .5), (262, 300, .42), (150, 420, .3), (290, 200, .22)]:
            naam += (f'<div class="gur" style="position:absolute;left:{x}px;top:{y}px;'
                     f'font-size:17px;font-weight:500;color:rgba(255,230,194,{o});'
                     f'text-shadow:0 0 12px rgba(242,162,78,{o * .6:.2f})">ਵਾਹਿਗੁਰੂ</div>')
    if state == "sitting":
        middle = f"""
    <div class="col" style="align-items:center">
      <div style="font-size:34px;font-weight:500;color:#fff;line-height:1.1;
        font-variant-numeric:tabular-nums">7:42</div>
      <div style="font-size:12.5px;color:rgba(255,255,255,.55)">left of 11:00</div>
    </div>"""
        buttons = f"""
    <div class="row" style="gap:12px">
      <div class="btn" style="flex:1;background:#F2A24E;color:#1C1206">Pause</div>
      <div class="btn" style="flex:1;background:rgba(255,255,255,.10);color:#fff">End</div>
    </div>"""
    else:
        middle = f"""
    <div style="{serif};font-size:20px;font-weight:500;line-height:1.25;color:#fff;
      text-align:center"><span style="color:#6FE3A6">48</span> live today</div>"""
        minutes = 5 if state == "noprofile" else 11
        buttons = f"""
    <div class="btn" style="background:#F2A24E;color:#1C1206">
      {icon("simran", 20)}<div>Begin Simran · {minutes} min</div></div>"""
    banner = ""
    if state == "noprofile":
        banner = f"""
    <div class="row" style="gap:11px;padding:11px 14px;border-radius:16px;
      background:rgba(255,255,255,.08);border:1px solid rgba(255,255,255,.14);color:#fff">
      <svg class="i" width="20" height="20" viewBox="0 0 24 24"><circle cx="12" cy="8.2" r="3.7"/>
        <path d="M4.8 20.2a7.2 7.2 0 0 1 14.4 0"/></svg>
      <div style="flex:1;font-size:13px;font-weight:600;line-height:1.3">
        Create your profile to see yourself on the globe</div>
      <div style="opacity:.6;transform:rotate(180deg)">{icon("back", 16)}</div>
    </div>"""
    return f"""
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Playfair+Display:wght@500;600&amp;display=swap">
<div style="position:absolute;inset:0;background:radial-gradient(110% 80% at 50% 57%,#071130,#040819)"></div>
<svg style="position:absolute;left:0;top:0" width="390" height="760">{stars()}</svg>
<div class="col" style="position:absolute;left:0;right:0;top:0;bottom:78px;padding:18px 0 14px">
  <div class="row" style="gap:8px;padding:0 20px">
    <div style="{dark_btn}">{icon("menu", 20)}</div>
    <div class="col" style="flex:1;align-items:center;gap:2px">
      <div style="{serif};font-size:23px;font-weight:500;line-height:1.1;color:#fff">Daily
        <span style="color:#F2A24E">Simran</span></div>
      <div style="font-size:8.5px;letter-spacing:.9px;font-weight:500;color:rgba(255,255,255,.62)">
        ONE BREATH · ONE WORLD · ONE WAHEGURU</div>
    </div>
    <div style="{dark_btn}">{icon("bell", 20)}</div>
  </div>
  <div class="row" style="justify-content:center;padding:12px 20px 0">
    {rule.format(d="to right")}
    <div class="gur" style="padding:0 14px;font-size:17px;line-height:1.3;font-weight:500;color:#F2A24E">ੴ</div>
    {rule.format(d="to left")}
  </div>
  <div style="text-align:center;font-size:11.5px;line-height:1.5;color:rgba(255,255,255,.7);padding:0 20px">
    Breathe in peace, breathe out worry.<br>With every breath, say
    <span style="color:#F2A24E;font-weight:600">Waheguru.</span></div>
  <div style="flex:1;position:relative;display:flex;align-items:center;justify-content:center;
    overflow:visible">{sky_globe(390, you=state != "noprofile")}
    <div style="position:absolute;inset:0">{naam}</div></div>
  <div class="col" style="gap:8px;padding:6px 20px 0">
    {middle}
    <div class="row" style="gap:13px;justify-content:center;flex-wrap:wrap">{legend}</div>
    {banner}
    {buttons}
  </div>
</div>
{nav("simran")}
"""


def simran_rest() -> str:
    return simran_sky("rest")


def simran_sitting() -> str:
    return simran_sky("sitting")


def simran_no_profile() -> str:
    return simran_sky("noprofile")


# ------------------------------------------------ first run (03-first-run.md)

def steps(at: int) -> str:
    """Language, then How you read; the current step long. Welcome has none:
    it is one screen, "no carousel, no dots" (03-first-run.md F2)."""
    return ('<div class="row" style="gap:6px">' + "".join(
        f'<div style="height:6px;border-radius:3px;width:{28 if i == at else 12}px;'
        f'background:{"var(--kesri)" if i <= at else "var(--rule)"}"></div>'
        for i in range(2)) + '</div>')


PROMISES = ('<div class="row" style="justify-content:center;gap:12px;font-size:12px;'
            'color:var(--muted);font-weight:600"><div>Works offline</div><div>·</div>'
            '<div>No login</div><div>·</div><div>No ads on Gurbani</div></div>')


def system_splash() -> str:
    """Android's own splash (03-first-run.md F1): the mark on #0C0F24, nothing else.

    The SplashScreen API draws it while the app starts and takes it away at
    the first frame. There is no second, branded splash and no fixed hold.
    """
    return f"""
<div style="position:absolute;inset:0;background:#0C0F24;display:flex;
  align-items:center;justify-content:center">
  <div style="width:160px;height:160px;border-radius:80px;display:flex;
    align-items:center;justify-content:center">{app_mark(112, "#F3EFE6", "#F2A24E")}</div>
</div>
"""


def welcome() -> str:
    """Welcome (03-first-run.md F2), option D chosen 2026-10-08: a day with Hazri.

    One screen. The headline names Waheguru; under it, one day as a timeline
    -- the 04:00 reminder, the hazri marked, the daily goal, the sangat group,
    the streak -- so the features are shown in the order somebody meets them.
    The figures are an illustration, the same on every phone, not the
    reader's own: nobody has a day yet when they see this.
    """
    card = ("position:relative;display:flex;align-items:center;gap:10px;padding:11px 13px;"
            "border-radius:16px;background:var(--card);box-shadow:var(--shadow)")
    def when(t, top=""):
        return (f'<div style="position:absolute;left:-72px;{top}width:50px;text-align:right;white-space:nowrap;'
                f'font-size:12px;font-weight:700;color:var(--muted)">{t}</div>'
                f'<div style="position:absolute;left:-17px;{top.replace("13px", "18px")}width:10px;'
                f'height:10px;border-radius:5px;background:var(--kesri);box-shadow:0 0 0 3px var(--bg)"></div>')
    def text(title, sub, sub_colour="var(--muted)"):
        return (f'<div class="col" style="flex:1"><div style="font-size:14px;font-weight:700">{title}</div>'
                f'<div style="font-size:12.5px;color:{sub_colour}">{sub}</div></div>')
    bar = ('<div style="height:6px;border-radius:3px;background:var(--rule)">'
           '<div style="width:67%;height:6px;border-radius:3px;background:var(--kesri)"></div></div>')
    streak = ('<div class="row" style="gap:4px">' + "".join(
        '<div style="width:9px;height:9px;border-radius:5px;background:var(--kesri)"></div>'
        for _ in range(5)) + '</div>')
    return f"""
<div class="col" style="height:100%;padding:48px 22px 30px">
  <div class="row" style="gap:9px">{app_mark(34)}
    <div class="disp" style="font-size:23px;font-weight:700;line-height:1">Hazri</div></div>
  <div class="disp" style="margin-top:22px;font-size:29px;line-height:1.15;font-weight:700">
    From Amrit Vela to bedtime, mark your hazri to
    <span style="color:var(--kesri)">Waheguru</span>.</div>
  <div class="col" style="position:relative;gap:12px;margin-top:24px;padding-left:70px">
    <div style="position:absolute;left:57px;top:14px;bottom:14px;width:2px;background:var(--kesriSoft)"></div>
    <div style="{card}">{when("4:00 AM")}
      <div style="color:var(--primary)">{icon("bell", 19)}</div>
      {text("Amrit Vela", "A gentle reminder, Japji Sahib is ready")}</div>
    <div style="{card};background:linear-gradient(135deg,var(--kesri),#B8560A);color:#fff">{when("5:10 AM")}
      {app_mark(22, "#fff", "#fff")}
      {text("Today’s hazri is marked", "With Japji Sahib", "rgba(255,255,255,.92)")}</div>
    <div style="{card}">{when("6:30 PM")}
      {ring(0.5, 26, 5)}
      {text("Daily goal · 1 of 2 done", "Japji Sahib, and 11 minutes of Simran")}</div>
    <div style="{card};flex-direction:column;align-items:stretch;gap:7px">{when("9:00 PM", "top:13px;")}
      <div class="row" style="gap:10px"><div style="color:var(--primary)">{icon("sangat", 19)}</div>
        {text("Your sangat group", "68 of 101 Sukhmani Sahib, together")}</div>
      {bar}</div>
    <div style="{card}">{when("Night")}
      {text("12 days in a row", "Kept in your diary")}{streak}</div>
  </div>
  <div style="flex:1"></div>
  <div style="margin-bottom:14px">{PROMISES}</div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">Begin</div>
</div>
"""


def setup_language() -> str:
    """Language (03-first-run.md F2). Applies the moment it is tapped."""
    def option(name, sub, cls, on):
        mark = (f'<div style="width:24px;height:24px;border-radius:12px;background:var(--kesri);'
                f'display:flex;align-items:center;justify-content:center;color:#fff">{icon("check", 16)}</div>'
                if on else '<div style="width:24px;height:24px;border-radius:12px;border:2px solid var(--rule)"></div>')
        ring = "box-shadow:inset 0 0 0 2px var(--kesri)" if on else "box-shadow:var(--shadow)"
        return (f'<div class="row" style="gap:14px;padding:16px 18px;border-radius:18px;min-height:72px;'
                f'background:var(--card);{ring}"><div class="col" style="flex:1">'
                f'<div class="{cls}" style="font-size:22px;font-weight:700;line-height:1.3">{name}</div>'
                f'<div style="font-size:13px;color:var(--muted)">{sub}</div></div>{mark}</div>')
    return f"""
<div class="col" style="height:100%;padding:40px 24px 30px">
  {steps(0)}
  <div class="col" style="gap:8px;margin-top:40px">
    <div class="row" style="gap:10px">{app_mark(36)}
      <div class="disp" style="font-size:22px;font-weight:700">Hazri</div></div>
    <div class="disp" style="font-size:28px;font-weight:700;line-height:1.2;margin-top:18px">
      Choose your language</div>
    <div style="font-size:14.5px;color:var(--muted)">You can change it any time in Settings.</div>
  </div>
  <div class="col" style="gap:10px;margin-top:24px">
    {option("ਪੰਜਾਬੀ", "Punjabi", "gur", False)}
    {option("हिन्दी", "Hindi", "dev", False)}
    {option("English", "English", "", True)}
  </div>
  <div style="flex:1"></div>
  <div style="margin-bottom:14px">{PROMISES}</div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">Continue</div>
</div>
"""


def setup_reading() -> str:
    """How you read (03-first-run.md F2, F8): script and size against a real
    line, elder mode as one option, Skip allowed. The line is the one design 06
    shows, from Japji Sahib in content.db."""
    def script(label, text, cls, on):
        ring = "box-shadow:inset 0 0 0 2px var(--kesri)" if on else "box-shadow:var(--shadow)"
        return (f'<div class="col" style="gap:2px;padding:12px 16px;border-radius:16px;'
                f'background:var(--card);{ring}"><div style="font-size:12px;color:var(--muted);'
                f'font-weight:700">{label}</div><div class="{cls}" style="font-size:19px;'
                f'line-height:1.6;font-weight:500">{text}</div></div>')
    return f"""
<div class="col" style="height:100%;padding:40px 24px 30px;gap:16px">
  <div class="row" style="justify-content:space-between">{steps(1)}
    <div style="font-size:15px;font-weight:700;color:var(--ink2)">Skip</div></div>
  <div class="disp" style="font-size:28px;font-weight:700;line-height:1.2;margin-top:10px">
    How do you like to read Gurbani?</div>
  <div class="col" style="gap:10px">
    {script("GURMUKHI", "ਆਦਿ ਸਚੁ ਜੁਗਾਦਿ ਸਚੁ ॥", "gur", True)}
    {script("हिन्दी · DEVANAGARI", "आदि सचु जुगादि सचु ॥", "dev", False)}
    {script("ROMAN", "aad sach jugaad sach ||", "", False)}
  </div>
  <div class="card col" style="padding:14px 16px;gap:10px">
    <div class="row" style="justify-content:space-between;font-size:14px;font-weight:600">
      <div>Text size</div><div style="color:var(--muted)">Standard</div></div>
    <div class="row" style="gap:12px"><div style="font-size:13px;font-weight:700;color:var(--muted)">A</div>
      <div style="flex:1;height:4px;border-radius:2px;background:var(--rule);position:relative">
        <div style="width:45%;height:4px;border-radius:2px;background:var(--kesri)"></div>
        <div style="position:absolute;left:45%;top:-8px;width:20px;height:20px;margin-left:-10px;
          border-radius:10px;background:var(--card);box-shadow:0 0 0 2px var(--kesri)"></div></div>
      <div style="font-size:22px;font-weight:700;color:var(--muted)">A</div></div>
    <div class="row" style="gap:12px;border-top:1px solid var(--rule);padding-top:10px">
      <div class="col" style="flex:1"><div style="font-size:15px;font-weight:600">Elder mode</div>
        <div style="font-size:12.5px;color:var(--muted)">Larger text and simpler screens</div></div>
      <div style="width:48px;height:28px;border-radius:14px;background:var(--card2);padding:4px;
        flex:none;display:flex"><div style="width:20px;height:20px;border-radius:10px;
        background:var(--muted)"></div></div></div>
  </div>
  <div style="font-size:13px;color:var(--ink2)">Bani versions follow the SGPC Rehat Maryada.</div>
  <div style="flex:1"></div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">Done</div>
</div>
"""


# ------------------------------------------- badges, chosen 2026-10-08 (12-badges.md)

# (name, Gurmukhi, what it marks, how it is earned, earned on, icon path)
BADGES = [
    ("Jigyasu", "ਜਿਗਿਆਸੂ", "The seeker", "Your first hazri", "28 Aug 2026",
     "M3 17h18M7 17a5 5 0 0 1 10 0M12 7v3M6.5 10.5l1.5 1.5M17.5 10.5L16 12"),
    ("Shardhalu", "ਸ਼ਰਧਾਲੂ", "Coming back with shardha", "Hazri on 7 days", "3 Sep 2026",
     "M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z"),
    ("Abhyasi", "ਅਭਿਆਸੀ", "One who practises", "Hazri on 40 days", "7 Oct 2026",
     "M4 12a8 8 0 0 1 14-5.3M20 12a8 8 0 0 1-14 5.3M18 3v4h-4M6 21v-4h4"),
    ("Nitnemi", "ਨਿਤਨੇਮੀ", "Keeps the Nitnem", "The five morning banis on 40 days", "8 Oct 2026",
     "M12 6.5C10.5 5.2 8 4.5 4 4.5v13c4 0 6.5.7 8 2 1.5-1.3 4-2 8-2v-13c-4 0-6.5.7-8 2zM12 6.5v13"),
    ("Simrani", "ਸਿਮਰਨੀ", "Settled in Simran", "Simran of 5 minutes or more on 108 days", "",
     "M12 4a8 8 0 1 1-.01 0M12 20v2.5"),
    ("Paathi", "ਪਾਠੀ", "Has read every bani through", "Every bani read through once", "",
     "M5 4h11a3 3 0 0 1 3 3v13H8a3 3 0 0 1-3-3zM5 17a3 3 0 0 1 3-3h11M13 4v6l2-1.5L17 10V4"),
    ("Sevadar", "ਸੇਵਾਦਾਰ", "Sewa in the sangat", "3 sangat goals reached with you", "",
     "M3 15h4l3 2h6a2 2 0 0 0 0-4h-3M12 10.5s-3-1.9-3-4.2A1.8 1.8 0 0 1 12 5a1.8 1.8 0 0 1 3 1.3c0 2.3-3 4.2-3 4.2z"),
    ("Gursikh", "ਗੁਰਸਿੱਖ", "The whole of it, held over months",
     "Nitnemi, Simrani, Paathi and hazri on 180 days", "",
     "M12 16a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM12 2.5V5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8"
     "M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8"),
    ("Satsangi", "ਸਤਿਸੰਗੀ", "Brought others into the sangat", "5 people joined groups you created", "",
     "M12 11a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM6.5 20a5.5 5.5 0 0 1 11 0M5 11.5a2.2 2.2 0 1 0 0-4.4"
     "M2 17.5a4 4 0 0 1 3-3.6M19 11.5a2.2 2.2 0 1 1 0-4.4M22 17.5a4 4 0 0 0-3-3.6"),
    ("Vichari", "ਵੀਚਾਰੀ", "The long road", "Hazri on 365 days", "",
     "M3 19l6-8 4 5 3-3 5 6zM16 8a2 2 0 1 0 0-4 2 2 0 0 0 0 4z"),
]
LIT = "radial-gradient(circle at 35% 30%,#F7B76A,#D9730D 70%)"


def emblem(d: str, size: int, earned: bool, ring: str | None = None) -> str:
    """A badge: kesri with a white mark when earned, grey with a grey mark when not."""
    if ring is None:
        ring = "0 0 0 3px var(--kesriSoft)" if earned else "inset 0 0 0 1.5px var(--rule)"
    bg = LIT if earned else "var(--card2)"
    ink = "#fff" if earned else "var(--muted)"
    icon_px = round(size * 0.48)
    return (f'<div style="width:{size}px;height:{size}px;flex:none;border-radius:{size // 2}px;'
            f'background:{bg};box-shadow:{ring};display:flex;align-items:center;justify-content:center">'
            f'<svg width="{icon_px}" height="{icon_px}" viewBox="0 0 24 24" fill="none" stroke="{ink}" '
            f'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="{d}"/></svg></div>')


def today_backdrop() -> str:
    """Today, dimmed, under a sheet or the menu."""
    return """
<style>.band{background:#262C63}.app.dark .band{background:var(--card2)}</style>
<div class="band" style="position:absolute;left:0;right:0;top:0;height:190px;border-radius:0 0 28px 28px"></div>
<div style="position:absolute;left:20px;right:20px;top:158px;height:74px;border-radius:20px;
  background:linear-gradient(135deg,var(--kesri),#B8560A)"></div>
<div style="position:absolute;left:20px;right:20px;top:246px;height:82px;border-radius:20px;background:var(--card)"></div>
<div style="position:absolute;left:20px;right:20px;top:342px;height:150px;border-radius:20px;background:var(--card)"></div>
<div style="position:absolute;inset:0;background:var(--scrim)"></div>"""


def badge_earned() -> str:
    """A badge is earned: option 1C, the compact sheet with the set (12-badges.md AN1)."""
    name, pa, marks, rule, date, d = BADGES[2]
    strip = "".join(
        f'<div style="aspect-ratio:1;border-radius:50%;background:{LIT if b[4] else "var(--card2)"};'
        f'box-shadow:{"0 0 0 2px var(--kesriSoft)" if b[4] else "inset 0 0 0 1px var(--rule)"};'
        f'display:flex;align-items:center;justify-content:center"><svg width="16" height="16" '
        f'viewBox="0 0 24 24" fill="none" stroke="{"#fff" if b[4] else "var(--muted)"}" stroke-width="2" '
        f'stroke-linecap="round" stroke-linejoin="round"><path d="{b[5]}"/></svg></div>' for b in BADGES)
    return f"""
{today_backdrop()}
<div class="col" style="position:absolute;left:0;right:0;bottom:0;background:var(--card);
  border-radius:28px 28px 0 0;padding:12px 22px 30px;gap:16px">
  <div class="row" style="justify-content:center"><div style="width:40px;height:4px;border-radius:2px;background:var(--rule)"></div></div>
  <div class="row" style="gap:16px;margin-top:8px">
    {emblem(d, 84, True, "0 0 0 5px var(--kesriSoft)")}
    <div class="col">
      <div class="eyebrow" style="color:var(--kesriInk);font-weight:700">New badge</div>
      <div class="row" style="gap:8px;align-items:baseline;flex-wrap:wrap">
        <div class="disp" style="font-size:25px;font-weight:700;line-height:1.15">{name}</div>
        <div class="gur" style="font-size:18px;font-weight:600;color:var(--kesriInk)">{pa}</div></div>
      <div style="font-size:14px;color:var(--ink2);line-height:1.4">{marks}: {rule.lower()}</div>
    </div>
  </div>
  <div class="col" style="gap:10px;padding:14px;border-radius:18px;background:var(--bg)">
    <div class="row" style="justify-content:space-between;font-size:13.5px;font-weight:700">
      <span>Your badges</span><span style="color:var(--muted);font-weight:600">4 of 10</span></div>
    <div style="display:grid;grid-template-columns:repeat(10,1fr);gap:6px">{strip}</div>
  </div>
  <div class="row" style="gap:10px;margin-top:6px">
    <div class="btn" style="flex:1;background:var(--card2);color:var(--ink2)">Done</div>
    <div class="btn" style="flex:1.4;background:var(--primary);color:var(--onPrimary)">See all badges</div>
  </div>
</div>
"""


def badges_page() -> str:
    """The Badges page: option 2A, two columns, earned in colour (12-badges.md UI2)."""
    cards = ""
    for name, pa, marks, rule, date, d in BADGES:
        e = bool(date)
        cards += (
            f'<div class="col" style="align-items:center;text-align:center;gap:4px;padding:14px 12px;'
            f'border-radius:18px;background:{"var(--card)" if e else "var(--card2)"};'
            f'box-shadow:{"var(--shadow)" if e else "none"}">'
            f'{emblem(d, 56, e, "0 0 0 3px var(--kesriSoft)" if e else "none")}'
            f'<div class="gur" style="margin-top:4px;font-size:16px;font-weight:600;'
            f'color:{"var(--ink)" if e else "var(--muted)"}">{pa}</div>'
            f'<div style="font-size:14px;font-weight:700;color:{"var(--ink)" if e else "var(--muted)"}">{name}</div>'
            f'<div style="font-size:12px;color:var(--muted);line-height:1.35">{rule}</div>'
            f'<div style="margin-top:2px;font-size:11.5px;font-weight:700;'
            f'color:{"var(--kesriInk)" if e else "var(--muted)"}">{"Earned " + date if e else "Not yet"}</div></div>')
    return f"""
<div class="pad col" style="gap:14px;padding:20px 18px 0">
  {header("Badges", "4 of 10 earned · Hazri on 41 days")}
  <div style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:12px">{cards}</div>
</div>
"""


def badge_detail() -> str:
    """One badge, opened: option 3B, a full page (12-badges.md UI4)."""
    name, pa, marks, rule, date, d = BADGES[3]
    card = "padding:16px;border-radius:20px;background:var(--card);box-shadow:var(--shadow);gap:4px"
    side = ('<a style="display:flex;align-items:center;gap:6px;min-height:44px;padding:0 14px;'
            'border-radius:14px;background:var(--card);color:var(--ink2);font-size:14px;font-weight:600">')
    return f"""
<div class="col" style="height:100%">
  <div class="col" style="align-items:center;gap:4px;padding:20px 18px 28px;
    background:radial-gradient(90% 80% at 50% 100%,var(--kesriSoft),var(--bg))">
    <div class="row" style="align-self:stretch;justify-content:space-between">
      <div style="width:40px;height:40px;border-radius:13px;display:flex;align-items:center;justify-content:center;
        background:var(--card);box-shadow:var(--shadow)">{icon("back", 20)}</div>
      <div style="font-size:13px;font-weight:700;color:var(--kesriInk)">Badge 4 of 10</div>
      <div style="width:40px"></div></div>
    <div style="margin-top:22px">{emblem(d, 128, True, "0 0 0 7px var(--card),0 16px 34px rgba(217,115,13,.35)")}</div>
    <div class="gur" style="margin-top:18px;font-size:30px;font-weight:600;line-height:1.3">{pa}</div>
    <div class="disp" style="font-size:21px;font-weight:700;line-height:1">{name}</div>
    <div class="chip" style="margin-top:10px;background:var(--card);color:var(--kesriInk)">Earned {date}</div>
  </div>
  <div class="col" style="gap:12px;padding:4px 18px 0">
    <div class="col" style="{card}"><div class="eyebrow">What it marks</div>
      <div style="font-size:15.5px;line-height:1.45">{marks}.</div></div>
    <div class="col" style="{card}"><div class="eyebrow">How it is earned</div>
      <div style="font-size:15.5px;line-height:1.45">Japji Sahib, Jaap Sahib, Tav Prasad Savaiye, Chaupai Sahib
        and Anand Sahib, all five on the same day, on 40 days. The days need not be in a row.</div></div>
  </div>
  <div style="flex:1"></div>
  <div class="row" style="justify-content:space-between;padding:0 18px 30px">
    {side}{icon("back", 16)}Abhyasi</a>
    {side}Simrani<div style="transform:rotate(180deg)">{icon("back", 16)}</div></a>
  </div>
</div>
"""


def profile_badges() -> str:
    """The Profile with its Badges section: option 4B (12-badges.md UI1)."""
    grid = "".join(
        f'<div class="col" style="align-items:center;gap:4px">{emblem(b[5], 50, bool(b[4]))}'
        f'<div style="font-size:11.5px;font-weight:600;color:{"var(--ink)" if b[4] else "var(--muted)"}">'
        f'{b[0]}</div></div>' for b in BADGES)
    card = "border-radius:20px;background:var(--card);box-shadow:var(--shadow)"
    return f"""
<div class="pad col" style="gap:14px;padding:20px 18px 0">
  {header("Your profile")}
  <div class="row" style="gap:14px;padding:16px;{card}">
    {avatar("HK", "var(--kesriSoft)", "var(--kesriInk)", 56)}
    <div class="col" style="flex:1"><div style="font-size:18px;font-weight:700">Harpreet Kaur</div>
      <div style="font-size:13.5px;color:var(--muted)">Amritsar, Punjab</div></div>
    <div class="chip" style="background:var(--card2);color:var(--primary);padding:9px 14px">Edit</div>
  </div>
  <div class="col" style="gap:12px;padding:16px;{card}">
    <div class="row" style="justify-content:space-between;align-items:baseline">
      <div style="font-size:16px;font-weight:700">Badges</div>
      <div style="font-size:14px;font-weight:700;color:var(--kesriInk)">See all 10</div></div>
    <div style="display:grid;grid-template-columns:repeat(5,minmax(0,1fr));gap:6px;row-gap:12px">{grid}</div>
  </div>
  <div class="col" style="{card}">
    <div class="row" style="justify-content:space-between;padding:14px 16px">
      <div class="col"><span style="font-size:12.5px;color:var(--muted)">Email</span>
        <span style="font-size:15px">harpreet@example.com</span></div>
      <div class="chip" style="background:var(--sageSoft);color:var(--sage)">Verified</div></div>
    <div class="col" style="padding:14px 16px;border-top:1px solid var(--rule)">
      <span style="font-size:12.5px;color:var(--muted)">Phone</span><span style="font-size:15px">Not added</span></div>
  </div>
  <div class="col" style="gap:4px;padding:14px 16px;{card}">
    <div style="font-size:15px;font-weight:700">Backup</div>
    <div style="font-size:13px;color:var(--muted)">Last backed up Sunday, 4 Oct</div>
  </div>
</div>
"""


def menu_badges() -> str:
    """The menu: option 5C, a navy header with name, city and the ten badges (12-badges.md UI1)."""
    strip = "".join(
        f'<div style="aspect-ratio:1;border-radius:50%;background:{LIT if b[4] else "rgba(255,255,255,.08)"};'
        f'box-shadow:{"none" if b[4] else "inset 0 0 0 1px rgba(255,255,255,.2)"};display:flex;'
        f'align-items:center;justify-content:center"><svg width="13" height="13" viewBox="0 0 24 24" '
        f'fill="none" stroke="{"#fff" if b[4] else "rgba(255,255,255,.4)"}" stroke-width="2.2" '
        f'stroke-linecap="round" stroke-linejoin="round"><path d="{b[5]}"/></svg></div>' for b in BADGES)
    items = "".join(
        f'<div class="row" style="min-height:48px;font-size:15.5px;font-weight:600">{t}</div>'
        for t in ["Your profile", "Badges", "Notifications", "Audio and voice", "Text size and script",
                  "Language", "Privacy and my data", "About and credits"])
    return f"""
{today_backdrop()}
<div class="col" style="position:absolute;left:0;top:0;bottom:0;width:304px;background:var(--card);
  border-radius:0 24px 24px 0;overflow:hidden">
  <div class="band col" style="color:#fff;padding:30px 18px 18px;gap:14px">
    <div class="row" style="gap:12px">{avatar("HK", "var(--kesriSoft)", "var(--kesriInk)", 52)}
      <div class="col"><div style="font-size:17px;font-weight:700">Harpreet Kaur</div>
        <div style="font-size:13px;color:rgba(255,255,255,.75)">Amritsar, Punjab</div></div></div>
    <div class="col" style="gap:8px">
      <div class="row" style="justify-content:space-between;font-size:12.5px;font-weight:600;
        color:rgba(255,255,255,.8)"><span>Badges</span><span>4 of 10</span></div>
      <div style="display:grid;grid-template-columns:repeat(10,1fr);gap:4px">{strip}</div>
    </div>
  </div>
  <div class="col" style="padding:10px 18px 0">{items}</div>
  <div style="flex:1"></div>
  <div style="padding:0 18px 24px;font-size:12px;color:var(--muted)">Hazri 2.0 · No ads on Gurbani, ever</div>
</div>
"""


# ------------------------------- profile and sangat, chosen 2026-10-10
# 01-accounts.md (100, 101) and 08-sangat.md (102, 103), each picked by the
# owner from four or more options. Sample person: Harpreet Kaur, Ludhiana.

# Neela is the light theme's primary, but the dark theme's primary is kesri,
# so a navy line, icon or link needs a colour of its own in dark: the canvas's
# own --neela for dark (#C9CCF2). `--edge` is an outlined field's border,
# darker than `--rule` so the field reads at 3:1.
SHARED_STYLE = """
<style>
.app{--neela:#262C63;--edge:#C9C9D6;--plank:#DCDBE7}
.app.dark{--neela:#C9CCF2;--edge:#3D4372;--plank:#2A2F55}
.band{background:#262C63}.app.dark .band{background:var(--card2)}
.idcard{background:linear-gradient(150deg,#2E3577 0%,#262C63 55%,#1A1E48 100%);
  box-shadow:0 14px 30px rgba(38,44,99,.28)}
.app.dark .idcard{background:linear-gradient(150deg,#2A3170 0%,#1F2447 55%,#161A37 100%);
  box-shadow:0 0 0 1px rgba(255,255,255,.06)}
</style>"""

ON_BAND = ('width:44px;height:44px;border-radius:13px;flex:none;display:flex;'
           'align-items:center;justify-content:center;background:rgba(255,255,255,.12);color:#fff')


def chev(size: int = 18) -> str:
    """A forward chevron: the back arrow, turned round, as the set draws it."""
    return (f'<div style="color:var(--muted);transform:rotate(180deg);flex:none">'
            f'{icon("back", size)}</div>')


def ringed(pct: float, size: int, stroke: int, centre: str,
           colour: str = "var(--kesri)", track: str = "var(--rule)") -> str:
    """`ring` with something written in the middle of it."""
    return (f'<div style="position:relative;width:{size}px;height:{size}px;flex:none">'
            f'{ring(pct, size, stroke, colour, track)}'
            f'<div style="position:absolute;inset:0;display:flex;flex-direction:column;'
            f'align-items:center;justify-content:center">{centre}</div></div>')


def tab_header(title: str) -> str:
    """A tab's own header: the menu button, the tab's name, a line under it."""
    return (f'<div style="padding:16px 18px 12px;border-bottom:1px solid var(--rule)">'
            f'{header(title, left="menu")}</div>')


def soft_chip(label: str, kind: str = "sage", ic: str | None = None) -> str:
    bg, fg = {"sage": ("var(--sageSoft)", "var(--sage)"),
              "kesri": ("var(--kesriSoft)", "var(--kesriInk)"),
              "soft": ("var(--card2)", "var(--ink2)")}[kind]
    return (f'<div class="chip" style="background:{bg};color:{fg};padding:4px 10px;'
            f'font-size:12.5px;font-weight:700;gap:5px;flex:none">'
            + (icon(ic, 14) if ic else "") + f'{label}</div>')


PRIVACY = ("Your email is never shown to anyone in the app. Your city is one dot "
           "on the Simran globe, and nothing finer.")


def profile_card() -> str:
    """The Profile: option D, an identity card and a badge shelf (01-accounts.md 8.7)."""
    arc = ('<svg width="230" height="140" viewBox="0 0 230 140" style="position:absolute;'
           'right:-40px;top:-6px;display:block">'
           '<path d="M10 135A105 105 0 0 1 220 135" fill="none" stroke="rgba(255,255,255,.08)" '
           'stroke-width="18"/><path d="M65 135A50 50 0 0 1 165 135Z" '
           'fill="rgba(242,162,78,.16)"/></svg>')
    stat = lambda n, l: (
        f'<div class="col" style="flex:1"><div class="disp" style="font-size:22px;'
        f'font-weight:700;line-height:1.05">{n}</div><div style="font-size:12px;'
        f'color:rgba(255,255,255,.8);font-weight:600">{l}</div></div>')
    line = lambda ic, text: (
        f'<div class="row" style="gap:5px;font-size:14px;color:rgba(255,255,255,.85)">'
        f'{icon(ic, 15)}{text}</div>')
    idcard = f"""
  <div class="idcard col" style="position:relative;overflow:hidden;border-radius:24px;
    padding:18px 18px 16px;color:#fff;gap:14px">
    {arc}
    <div class="row" style="gap:8px;position:relative">{app_mark(26, "#fff", "#F2A24E")}
      <div class="disp" style="font-size:17px;font-weight:700">Hazri</div></div>
    <div class="col" style="position:relative">
      <div class="disp" style="font-size:30px;font-weight:700;line-height:1.05">Harpreet Kaur</div>
      <div style="padding-top:4px">{line("pin", "Ludhiana, Punjab")}</div>
      <div class="row" style="gap:4px">{line("mail", "harpreet@example.com")}
        <div class="row" style="gap:3px;color:#9FE3BF;font-weight:700;font-size:12.5px;
          padding-left:4px">{icon("check", 13)}Verified</div></div>
    </div>
    <div class="row" style="gap:10px;padding-top:12px;border-top:1px solid rgba(255,255,255,.16);
      position:relative">{stat("86", "days of Hazri")}{stat("12", "in a row")}{stat("4", "badges")}</div>
  </div>"""

    def shelf(start: int) -> str:
        cells = "".join(
            f'<div class="col" style="align-items:center;gap:4px;min-height:44px">'
            f'{emblem(b[5], 46, bool(b[4]))}<div style="font-size:11.5px;font-weight:600;'
            f'color:{"var(--ink)" if b[4] else "var(--ink2)"}">{b[0]}</div></div>'
            for b in BADGES[start:start + 5])
        return (f'<div class="col"><div style="display:grid;grid-template-columns:'
                f'repeat(5,minmax(0,1fr));gap:4px;padding:0 4px 8px">{cells}</div>'
                f'<div style="height:8px;border-radius:4px;background:linear-gradient('
                f'180deg,var(--card2),var(--plank));box-shadow:0 3px 6px rgba(27,29,58,.08)">'
                f'</div></div>')
    return f"""
{SHARED_STYLE}
<div class="col" style="gap:12px;padding:16px 16px 0">
  {header("Your profile")}
  {idcard}
  <div class="card col" style="padding:6px 14px 16px;gap:10px">
    <div class="row" style="justify-content:space-between;min-height:44px">
      <div style="font-size:16px;font-weight:700">Badges</div>
      <div style="font-size:14px;font-weight:700;color:var(--kesriInk)">See all 10</div></div>
    {shelf(0)}
    {shelf(5)}
  </div>
  <div class="row" style="gap:10px">
    <div class="btn" style="flex:1;background:var(--primary);color:var(--onPrimary)">
      {icon("edit", 19)}<div>Edit profile</div></div>
    <div class="btn" style="flex:1;background:var(--card2);color:var(--neela)">
      {icon("cloud", 19)}<div>Back up now</div></div>
  </div>
  <div style="padding:0 4px;font-size:13px;color:var(--ink2)">
    Last backed up Sunday, 4 Oct · Phone not provided</div>
  <div class="row" style="justify-content:center;gap:6px;min-height:44px;color:var(--neela);
    font-weight:600;font-size:14px">{icon("restore", 17)}Restore my goals and diary</div>
  <div class="row" style="align-items:flex-start;gap:8px;padding:0 4px;margin-top:-4px;
    font-size:12.5px;line-height:1.4;color:var(--ink2)">
    <div style="color:var(--sage);padding-top:1px">{icon("shield", 16)}</div>
    <div>{PRIVACY}</div></div>
</div>
"""


def outlined(label: str, inner: str, focus: bool = False) -> str:
    """A Material outlined field: the label sits on the border."""
    edge = "var(--neela)" if focus else "var(--edge)"
    return (f'<div style="position:relative">'
            f'<div style="position:absolute;left:12px;top:-9px;background:var(--card);'
            f'padding:0 5px;font-size:12.5px;font-weight:700;line-height:18px;'
            f'color:{"var(--neela)" if focus else "var(--ink2)"}">{label}</div>'
            f'<div class="row" style="min-height:56px;border:{2 if focus else 1.5}px solid {edge};'
            f'border-radius:14px;gap:10px;padding:0 6px 0 14px">{inner}</div></div>')


def edit_profile() -> str:
    """Edit profile: option C, outlined fields with a sunrise preview (01-accounts.md 13.8)."""
    help_ = lambda t, extra="": (f'<div style="font-size:12.5px;color:var(--ink2);'
                                 f'line-height:1.4;{extra}">{t}</div>')
    sun = lambda ic, label, time, bg, fg: (
        f'<div class="row" style="flex:1;gap:10px;background:{bg};border-radius:14px;'
        f'padding:10px 12px"><div style="color:{fg}">{icon(ic, 22)}</div>'
        f'<div class="col"><div style="font-size:12px;color:{fg};font-weight:700">{label}</div>'
        f'<div class="disp" style="font-size:20px;font-weight:700;line-height:1.1">{time}</div>'
        f'</div></div>')
    value = lambda t: f'<div style="flex:1;min-width:0;font-size:16px">{t}</div>'
    return f"""
{SHARED_STYLE}
<div class="col" style="gap:14px;padding:16px 16px 0">
  {header("Edit profile")}
  <div class="card col" style="padding:14px;gap:10px">
    <div class="row" style="justify-content:space-between">
      <div style="font-size:15px;font-weight:700">Today in Ludhiana</div>
      {soft_chip("Changed from Amritsar", "kesri")}</div>
    <div class="row" style="gap:10px">
      {sun("sunrise", "Sunrise", "6:22 AM", "var(--kesriSoft)", "var(--kesriInk)")}
      {sun("sunset", "Sunset", "5:53 PM", "var(--card2)", "var(--neela)")}
    </div>
    {help_("Your sunrise times on Today and your dot on the Simran globe follow it.")}
  </div>
  <div class="card col" style="padding:22px 14px 16px;gap:20px">
    {outlined("Name", value("Harpreet Kaur"))}
    {help_("2 to 50 letters. Spaces, full stops, apostrophes and hyphens are fine.",
           "margin-top:-12px;padding-left:4px")}
    {outlined("City", f'<div style="color:var(--neela)">{icon("pin", 19)}</div>'
              + value("Ludhiana, Punjab")
              + f'<div style="color:var(--ink2);padding-right:8px">{icon("search", 18)}</div>',
              focus=True)}
    {outlined("Email",
              '<div style="flex:1;min-width:0;font-size:15.5px;white-space:nowrap;overflow:hidden;'
              'text-overflow:ellipsis">harpreet@example.com</div>'
              f'<div style="color:var(--sage)">{icon("verified", 18)}</div>'
              '<div class="row" style="min-height:44px;padding:0 10px;border-radius:10px;'
              'background:var(--kesriSoft);color:var(--kesriInk);font-size:13.5px;'
              'font-weight:700;flex:none">Change email</div>')}
    {help_("A new email takes over only once you confirm it from the link we send.",
           "margin-top:-12px;padding-left:4px")}
  </div>
</div>
<div style="position:absolute;left:16px;right:16px;bottom:26px">
  {primary("Save changes", "check")}
</div>
"""


# Sample groups, not real figures.
MY_GROUPS = [
    ("Gill Parivar", "3,412 of 5,000", "83 days left", 0.68, "sangat"),
    ("Simran Sangat", "212,480 of 500,000 min", "22 days left", 0.42, "simran"),
    ("Model Town Sangat", "297 of 1,100", "37 days left", 0.27, "sangat"),
    ("Gurpurab Simran", "3,000 of 3,000 min", "Ended on 5 Oct", 1.0, None),
]
BUILT_IN = [
    ("sunrise", "Amrit Vela Sangat", "100,000 Japji Sahib by 31 Oct", "4,982 members", False),
    ("simran", "Simran Sangat", "500,000 minutes of Naam Simran by 31 Oct", "2,418 members", True),
    ("nitnem", "Sukhmani Sahib Sangat", "10,000 Sukhmani Sahib by 31 Oct", "1,306 members", False),
]


def tinted(ic: str, size: int, radius: int = 12) -> str:
    return (f'<div style="width:{size}px;height:{size}px;border-radius:{radius}px;flex:none;'
            f'background:var(--card2);color:var(--teal);display:flex;align-items:center;'
            f'justify-content:center">{icon(ic, round(size * 0.5))}</div>')


def sangat_tiles() -> str:
    """The Sangat tab: option C, dashboard tiles (08-sangat.md 8.1, VS1, VS2)."""
    action = lambda ic, label, sub, bg, fg: (
        f'<div class="row" style="flex:1;min-height:72px;border-radius:20px;padding:12px 14px;'
        f'gap:12px;background:{bg};color:{fg};box-shadow:var(--shadow)">'
        f'<div style="width:36px;height:36px;flex:none;border-radius:12px;'
        f'background:rgba(255,255,255,.16);display:flex;align-items:center;'
        f'justify-content:center">{icon(ic, 20)}</div>'
        f'<div class="col"><div style="font-size:16px;font-weight:700;line-height:1.3">{label}</div>'
        f'<div style="font-size:12.5px;opacity:.9;line-height:1.35">{sub}</div></div></div>')
    tiles = ""
    for name, prog, left, pct, ic in MY_GROUPS:
        done = pct >= 1
        corner = tinted(ic, 28, 9) if ic else soft_chip("Ended", "soft")
        tiles += (
            f'<div class="card col" style="padding:11px 12px;gap:5px;min-height:124px">'
            f'<div class="row" style="justify-content:space-between;align-items:flex-start">'
            f'{ringed(pct, 46, 6, f"<div style=\'font-size:11px;font-weight:700\'>{round(pct * 100)}%</div>", "var(--sage)" if done else "var(--kesri)")}'
            f'{corner}</div>'
            f'<div style="font-size:14.5px;font-weight:700;line-height:1.2">{name}</div>'
            f'<div style="font-size:12px;color:var(--ink2);line-height:1.3">{prog}<br>{left}</div>'
            f'</div>')
    rows = ""
    for k, (ic, name, goal, members, joined) in enumerate(BUILT_IN):
        btn = ('<div class="row" style="min-height:44px;min-width:72px;justify-content:center;'
               'padding:0 16px;border-radius:999px;font-size:14px;font-weight:700;flex:none;'
               + ('background:var(--sageSoft);color:var(--sage)">✓ Joined' if joined else
                  'background:var(--kesriSoft);color:var(--kesriInk)">Join') + '</div>')
        rows += (
            f'<div class="row" style="gap:12px;padding:8px 12px 8px 14px;'
            f'{"border-top:1px solid var(--rule)" if k else ""}">{tinted(ic, 38)}'
            f'<div class="col" style="flex:1;min-width:0">'
            f'<div style="font-size:14.5px;font-weight:700;line-height:1.3">{name}</div>'
            f'<div style="font-size:12.5px;color:var(--ink2);line-height:1.35;white-space:nowrap;'
            f'overflow:hidden;text-overflow:ellipsis">{goal}</div>'
            f'<div style="font-size:12.5px;color:var(--ink2);line-height:1.35">{members}</div>'
            f'</div>{btn}</div>')
    return f"""
{SHARED_STYLE}
{tab_header("Sangat")}
<div class="col" style="gap:10px;padding:12px 16px 0">
  <div class="row" style="gap:10px">
    {action("plus", "Create group", "One goal, an end date", "var(--primary)", "var(--onPrimary)")}
    {action("code", "Join group", "With a link or code", "var(--kesriSoft)", "var(--kesriInk)")}
  </div>
  <div class="eyebrow" style="padding:2px 4px 0;color:var(--ink2);font-weight:700">My groups</div>
  <div style="display:grid;grid-template-columns:1fr 1fr;gap:10px">{tiles}</div>
  <div class="eyebrow" style="padding:2px 4px 0;color:var(--ink2);font-weight:700">Join the sangat</div>
  <div class="card col">{rows}</div>
</div>
{nav("sangat")}
"""


def built_in_group() -> str:
    """A built-in group: option H, the ring in a navy band, a timeline below (08-sangat.md VS3, VS4)."""
    centre = ('<div class="disp" style="font-size:28px;font-weight:700;line-height:1">212,480</div>'
              '<div style="font-size:12px;color:rgba(255,255,255,.85);font-weight:600">of 500,000 min</div>'
              '<div class="disp" style="font-size:17px;font-weight:700;color:#F2A24E;padding-top:2px">42%</div>')

    def node(dot: str, t1: str, t2: str, align: str, here: bool = False) -> str:
        text = {"flex-start": "left", "center": "center", "flex-end": "right"}[align]
        return (f'<div class="col" style="flex:1;gap:6px;align-items:{align}">'
                f'<div style="width:18px;height:18px;border-radius:9px;{dot}"></div>'
                f'<div style="font-size:13px;font-weight:700;text-align:{text};'
                f'color:{"var(--kesriInk)" if here else "var(--ink)"}">{t1}</div>'
                f'<div style="font-size:12px;line-height:1.25;text-align:{text};'
                f'color:{"var(--kesriInk)" if here else "var(--ink2)"}">{t2}</div></div>')

    def figure(n: str, label: str, yours: bool = False) -> str:
        return (f'<div class="card col" style="border-radius:18px;padding:10px 12px">'
                f'<div class="disp" style="font-size:22px;font-weight:700;line-height:1.1;'
                f'{"color:var(--kesriInk)" if yours else ""}">{n}<span style="font-size:13px;'
                f'font-weight:600"> min</span></div>'
                f'<div style="font-size:12px;color:var(--ink2);font-weight:600;line-height:1.25">'
                f'{label}</div></div>')
    members = "".join(
        f'<div class="row" style="justify-content:space-between;min-height:44px;padding:0 16px;'
        f'font-size:15px;{"border-top:1px solid var(--rule)" if i else ""}">'
        f'<div style="font-weight:600">{n}</div>'
        f'<div style="color:var(--ink2);font-weight:600">{v}</div></div>'
        for i, (n, v) in enumerate([("Amandeep Singh", "240 min"), ("Baljit Kaur", "95 min"),
                                    ("Charanjit Singh", "410 min")]))
    return f"""
{SHARED_STYLE}
<div class="band col" style="gap:10px;padding:16px 18px 44px;color:#fff;border-radius:0 0 28px 28px">
  <div class="row" style="gap:10px">
    <div style="{ON_BAND}">{icon("back", 20)}</div>
    <div class="col" style="flex:1">
      <div class="disp" style="font-size:22px;font-weight:700;line-height:1.1">Simran Sangat</div>
      <div style="font-size:12.5px;color:rgba(255,255,255,.82)">Built-in group · 2,418 members</div>
    </div>
    <div style="{ON_BAND}">{icon("more", 20)}</div>
  </div>
  <div class="row" style="justify-content:center">
    {ringed(0.42, 150, 13, centre, "#F2A24E", "rgba(255,255,255,.16)")}</div>
  <div style="font-size:14.5px;font-weight:600;text-align:center;color:rgba(255,255,255,.92)">
    500,000 minutes of Naam Simran by 31 Oct</div>
</div>
<div class="col" style="gap:10px;padding:0 16px;margin-top:-28px">
  <div class="card col" style="padding:12px 16px 14px;gap:10px">
    <div class="row" style="justify-content:space-between;align-items:baseline">
      <div class="eyebrow" style="color:var(--ink2);font-weight:700">This goal</div>
      <div style="font-size:12.5px;color:var(--ink2);font-weight:600">Day 10 of 31</div></div>
    <div class="row" style="position:relative;align-items:flex-start">
      <div style="position:absolute;left:9px;right:9px;top:8px;height:2px;background:var(--rule)"></div>
      <div style="position:absolute;left:9px;width:calc(50% - 9px);top:8px;height:2px;
        background:var(--neela)"></div>
      {node("background:var(--neela);position:relative", "1 Oct", "Started", "flex-start")}
      {node("background:var(--kesri);box-shadow:0 0 0 4px var(--kesriSoft);position:relative",
            "Today", "22 days left", "center", True)}
      {node("background:var(--card);box-shadow:inset 0 0 0 2px var(--edge);position:relative",
            "31 Oct", "Ends; new goal 1 Nov", "flex-end")}
    </div>
  </div>
  <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px">
    {figure("6,930", "Sangat today")}{figure("15", "Yours today", True)}
    {figure("186", "Yours toward the goal", True)}</div>
  {primary("Sit for Naam Simran", "simran")}
  <div class="card col">
    <div class="row" style="justify-content:space-between;align-items:baseline;padding:12px 16px 6px">
      <div class="eyebrow" style="color:var(--ink2);font-weight:700">Members</div>
      <div style="font-size:13px;color:var(--ink2);font-weight:600">2,418 · A to Z</div></div>
    {members}
    <div style="padding:8px 16px 12px;border-top:1px solid var(--rule);font-size:13.5px;
      color:var(--ink2);font-weight:600">and 2,415 more</div>
  </div>
</div>
"""



def _group_globe_svg(size: int, cities, you, lon0: float, lat0: float, scale: float,
                     arrivals=(), tip=None) -> str:
    """The group's globe (08-sangat GG1-GG4): members by city, threads, and paath
    arriving as light into the ring's leading edge (`tip`, in viewBox units).

    cities: (lat, lon, today, not_yet). Dots sized by 07-simran SZ1 (one person
    the size of your dot, full at 25), scaled for a globe this small.
    """
    global LON0, LAT0
    saved = (LON0, LAT0)
    LON0, LAT0 = lon0, lat0
    try:
        k = 300 / size
        grid = graticule().replace('stroke="#2A3A6B" stroke-width="0.8" opacity="0.55"',
                                   'stroke="#2F4E96" stroke-width="0.9" opacity="0.6"')
        coast = coastline().replace('stroke="#41609E" stroke-width="1"',
                                    'stroke="#8FD4FF" stroke-width="1.1" opacity="0.85"')
        me = project(*you)
        pts = [(project(lat, lon), t, n) for lat, lon, t, n in cities]
        pts = [(p, t, n) for p, t, n in pts if p]

        def radius(c: int) -> float:
            return 4.0 if c <= 1 else 4 + 10 * math.sqrt((min(c, 25) - 1) / 24)

        def arc(a, b, colour, w, op):
            mx, my = (a[0] + b[0]) / 2, (a[1] + b[1]) / 2
            dx, dy = b[0] - a[0], b[1] - a[1]
            cx, cy = mx - dy * 0.14, my + dx * 0.14 - 0.11 * math.hypot(dx, dy)
            return (f'<path d="M{a[0]:.1f} {a[1]:.1f} Q{cx:.1f} {cy:.1f} {b[0]:.1f} {b[1]:.1f}" '
                    f'fill="none" stroke="{colour}" stroke-width="{w:.1f}" opacity="{op}"/>')
        threads = []
        for i, (p, _, _) in enumerate(pts):
            for j in sorted(range(len(pts)), key=lambda m: math.dist(p, pts[m][0]))[1:3]:
                if j > i:
                    threads.append(arc(p, pts[j][0], "#AACDFF", 1.0 * k, 0.32))
        if me:
            threads += [arc(me, p, SKY["you"], 1.4 * k, 0.6) for p, _, _ in pts if math.dist(p, me) > 2]
        dots = []
        for (x, y), today, not_yet in pts:
            for n, colour, side in ((not_yet, SKY["here"], -1.5), (today, SKY["live"], 1.5)):
                if n <= 0:
                    continue
                r = radius(n) * scale * k
                dots.append(f'<circle cx="{x + side * r:.1f}" cy="{y:.1f}" r="{r * 2.2:.1f}" '
                            f'fill="{colour}" opacity=".22"/><circle cx="{x + side * r:.1f}" '
                            f'cy="{y:.1f}" r="{r:.1f}" fill="{colour}"/>')
        if me:
            r = 4 * scale * k
            dots.append(f'<circle cx="{me[0]:.1f}" cy="{me[1]:.1f}" r="{r * 3:.1f}" fill="{SKY["you"]}" '
                        f'opacity=".25"/><circle cx="{me[0]:.1f}" cy="{me[1]:.1f}" r="{r:.1f}" '
                        f'fill="{SKY["you"]}"/>')
        # GG4a: every dot in view tied to the ring's leading edge, dashed, in its own colour.
        tethers = ""
        if tip is not None:
            ends = [(p, SKY["here"] if t <= 0 else SKY["live"]) for p, t, _ in pts]
            if me:
                ends.append((me, SKY["you"]))
            for p, colour in ends:
                d = (f'M{p[0]:.1f} {p[1]:.1f} Q{(p[0] + tip[0]) / 2 + 30:.1f} '
                     f'{min(p[1], tip[1]) - 40:.1f} {tip[0]:.1f} {tip[1]:.1f}')
                tethers += (f'<path d="{d}" fill="none" stroke="{colour}" stroke-width="{1.2 * k:.1f}" '
                            f'stroke-dasharray="4 5" stroke-linecap="round" opacity=".6"/>')
        lights = ""
        for i, (lat, lon) in enumerate(arrivals):
            p = project(lat, lon)
            if not p or tip is None:
                continue
            d = (f'M{p[0]:.1f} {p[1]:.1f} Q{(p[0] + tip[0]) / 2 + 30:.1f} '
                 f'{min(p[1], tip[1]) - 40:.1f} {tip[0]:.1f} {tip[1]:.1f}')
            # A still frame shows each light part way along its path.
            f = (i + 1) / (len(arrivals) + 1)
            qx = (1 - f) ** 2 * p[0] + 2 * (1 - f) * f * ((p[0] + tip[0]) / 2 + 30) + f * f * tip[0]
            qy = (1 - f) ** 2 * p[1] + 2 * (1 - f) * f * (min(p[1], tip[1]) - 40) + f * f * tip[1]
            lights += (f'<path d="{d}" fill="none" stroke="{SKY["you"]}" stroke-width="{1.2 * k:.1f}" '
                       f'stroke-dasharray="4 6" opacity=".5"/>'
                       f'<circle cx="{qx:.1f}" cy="{qy:.1f}" r="{5 * k:.1f}" fill="#FFD7A3"/>')
        return (f'<svg width="{size}" height="{size}" viewBox="10 10 300 300" style="display:block;overflow:visible">'
                '<defs><radialGradient id="gsea"><stop offset="0" stop-color="#0B1A44"/>'
                '<stop offset=".75" stop-color="#071232"/><stop offset="1" stop-color="#0A1F52"/></radialGradient>'
                '<radialGradient id="gglow"><stop offset=".72" stop-color="#6FC3D3" stop-opacity=".28"/>'
                '<stop offset="1" stop-color="#6FC3D3" stop-opacity="0"/></radialGradient></defs>'
                '<circle cx="160" cy="160" r="196" fill="url(#gglow)"/>'
                '<circle cx="160" cy="160" r="150" fill="url(#gsea)"/>'
                f'{grid}{coast}{"".join(threads)}'
                '<circle cx="160" cy="160" r="149.5" fill="none" stroke="#7FC4FF" stroke-width="2.4" opacity=".85"/>'
                f'{tethers}{"".join(dots)}{lights}</svg>')
    finally:
        LON0, LAT0 = saved


def group_globe(private: bool) -> str:
    """A group with its globe inside the goal ring, and paath arriving as light
    (08-sangat GG1-GG9, option C, owner 2026-10-17). 104 is a private group,
    105 a built-in one; the rest of the screen is design 103."""
    if private:
        name, sub, total, target, unit, pct, frac = ("Gill Parivar", "24 members", "3,412", "5,000",
                                                     "paath", "68%", 3412 / 5000)
        goal, key = "5,000 Japji Sahib by 8 Jan", ("10 today", "13 not yet", "7 cities")
        arrivals_line = "3 paath arrived in the last hour"
        cities = [(30.90, 75.85, 3, 3), (31.33, 75.58, 2, 2), (28.61, 77.21, 1, 2),
                  (51.51, -0.38, 2, 2), (52.48, -1.90, 1, 1), (25.20, 55.27, 1, 0),
                  (31.63, 74.87, 0, 1)]
        arrivals = [(30.90, 75.85), (51.51, -0.38), (25.20, 55.27)]
        view = (40.0, 30.0)
        timeline = ("Day 61 of 144", "17 Aug", "83 days left", "8 Jan", "Ends")
        figures = (("41", "Paath today"), ("2", "Yours today"), ("96", "Yours toward the goal"))
        unit_suffix = ""
        sit = ("Sit for Japji Sahib", "nitnem")
        members = [("Harpreet Kaur", "412"), ("Gurdeep Singh", "388"), ("Simran Kaur", "260")]
        members_head, more = "24 · A to Z", "and 21 more"
    else:
        name, sub, total, target, unit, pct, frac = ("Simran Sangat", "Built-in group · 2,418 members",
                                                     "212,480", "500,000", "min", "42%", 0.42)
        goal, key = "500,000 minutes of Naam Simran by 31 Oct", ("312 today", "2,105 not yet", "64 cities")
        arrivals_line = "86 minutes of Naam Simran in the last hour"
        cities = [(lat, lon, 9 if kind == "today" else 2, 14 if kind == "member" else 4)
                  for lat, lon, kind in PEOPLE if kind != "you"]
        arrivals = [(51.51, -0.38), (43.65, -79.38), (28.61, 77.21), (-37.81, 144.96)]
        view = (50.0, 24.0)
        timeline = ("Day 10 of 31", "1 Oct", "22 days left", "31 Oct", "Ends; new goal 1 Nov")
        figures = (("6,930", "Sangat today"), ("15", "Yours today"), ("186", "Yours toward the goal"))
        unit_suffix = '<span style="font-size:13px;font-weight:600"> min</span>'
        sit = ("Sit for Naam Simran", "simran")
        members = [("Amandeep Singh", "240 min"), ("Baljit Kaur", "95 min"), ("Charanjit Singh", "410 min")]
        members_head, more = "2,418 · A to Z", "and 2,415 more"

    size, ring = 190, 214
    r = ring / 2 - 7
    c = 2 * math.pi * r
    tip_angle = -math.pi / 2 + 2 * math.pi * frac
    k = 300 / size
    tip = (10 + (ring / 2 + r * math.cos(tip_angle) - (ring - size) / 2) * k,
           10 + (ring / 2 + r * math.sin(tip_angle) - (ring - size) / 2) * k)
    globe_svg = _group_globe_svg(size, cities, (31.63, 74.87), view[0], view[1],
                                 0.62 if private else 0.42, arrivals, tip)
    glow_x, glow_y = ring / 2 + r * math.cos(tip_angle), ring / 2 + r * math.sin(tip_angle)

    def node(dot: str, t1: str, t2: str, align: str, here: bool = False) -> str:
        text = {"flex-start": "left", "center": "center", "flex-end": "right"}[align]
        return (f'<div class="col" style="flex:1;gap:6px;align-items:{align}">'
                f'<div style="width:18px;height:18px;border-radius:9px;{dot}"></div>'
                f'<div style="font-size:13px;font-weight:700;text-align:{text};'
                f'color:{"var(--kesriInk)" if here else "var(--ink)"}">{t1}</div>'
                f'<div style="font-size:12px;line-height:1.25;text-align:{text};'
                f'color:{"var(--kesriInk)" if here else "var(--ink2)"}">{t2}</div></div>')

    def figure(n: str, label: str, yours: bool = False) -> str:
        return (f'<div class="card col" style="border-radius:18px;padding:10px 12px">'
                f'<div class="disp" style="font-size:22px;font-weight:700;line-height:1.1;'
                f'{"color:var(--kesriInk)" if yours else ""}">{n}{unit_suffix}</div>'
                f'<div style="font-size:12px;color:var(--ink2);font-weight:600;line-height:1.25">'
                f'{label}</div></div>')

    def key_dot(colour: str, label: str) -> str:
        return (f'<div class="row" style="gap:6px"><div style="width:8px;height:8px;border-radius:4px;'
                f'background:{colour}"></div>{label}</div>')
    rows = "".join(
        f'<div class="row" style="justify-content:space-between;min-height:44px;padding:0 16px;'
        f'font-size:15px;{"border-top:1px solid var(--rule)" if i else ""}">'
        f'<div style="font-weight:600">{n}</div>'
        f'<div style="color:var(--ink2);font-weight:600">{v}</div></div>'
        for i, (n, v) in enumerate(members))
    return f"""
{SHARED_STYLE}
<div class="band col" style="gap:6px;padding:14px 18px 40px;color:#fff;border-radius:0 0 28px 28px">
  <div class="row" style="gap:10px">
    <div style="{ON_BAND}">{icon("back", 20)}</div>
    <div class="col" style="flex:1">
      <div class="disp" style="font-size:22px;font-weight:700;line-height:1.1">{name}</div>
      <div style="font-size:12.5px;color:rgba(255,255,255,.82)">{sub}</div>
    </div>
    <div style="{ON_BAND}">{icon("more", 20)}</div>
  </div>
  <div class="row" style="justify-content:center">
    <div style="position:relative;width:{ring}px;height:{ring}px">
      <div style="position:absolute;left:{(ring - size) / 2}px;top:{(ring - size) / 2}px">{globe_svg}</div>
      <svg width="{ring}" height="{ring}" viewBox="0 0 {ring} {ring}" style="position:absolute;inset:0;overflow:visible">
        <g transform="rotate(-90 {ring / 2} {ring / 2})">
          <circle cx="{ring / 2}" cy="{ring / 2}" r="{r:.1f}" fill="none" stroke="rgba(255,255,255,.16)" stroke-width="9"/>
          <circle cx="{ring / 2}" cy="{ring / 2}" r="{r:.1f}" fill="none" stroke="#F2A24E" stroke-width="9"
            stroke-linecap="round" stroke-dasharray="{c * frac:.1f} {c:.1f}"/></g>
        <circle cx="{glow_x:.1f}" cy="{glow_y:.1f}" r="9" fill="#FFD7A3" opacity=".75"/>
      </svg>
    </div></div>
  <div class="row" style="justify-content:center;gap:8px;align-items:baseline">
    <div class="disp" style="font-size:26px;font-weight:700;line-height:1">{total}</div>
    <div style="font-size:13px;color:rgba(255,255,255,.85);font-weight:600">of {target} {unit}</div>
    <div class="disp" style="font-size:17px;font-weight:700;color:#F2A24E">{pct}</div></div>
  <div class="row" style="justify-content:center;gap:12px;font-size:12.5px;color:rgba(255,255,255,.85);font-weight:600">
    {key_dot(SKY["you"], "You")}{key_dot(SKY["live"], key[0])}{key_dot(SKY["here"], key[1])}<div>· {key[2]}</div></div>
  <div style="font-size:14.5px;font-weight:600;text-align:center;color:rgba(255,255,255,.92)">{goal}</div>
</div>
<div class="col" style="gap:10px;padding:0 16px;margin-top:-28px">
  <div class="row" style="align-self:center;gap:8px;background:var(--card);border-radius:999px;padding:7px 14px;
    box-shadow:var(--shadow);font-size:13.5px;font-weight:600">
    <div style="width:8px;height:8px;border-radius:4px;background:var(--kesri);box-shadow:0 0 0 4px var(--kesriSoft)"></div>
    {arrivals_line}</div>
  <div class="card col" style="padding:12px 16px 14px;gap:10px">
    <div class="row" style="justify-content:space-between;align-items:baseline">
      <div class="eyebrow" style="color:var(--ink2);font-weight:700">This goal</div>
      <div style="font-size:12.5px;color:var(--ink2);font-weight:600">{timeline[0]}</div></div>
    <div class="row" style="position:relative;align-items:flex-start">
      <div style="position:absolute;left:9px;right:9px;top:8px;height:2px;background:var(--rule)"></div>
      <div style="position:absolute;left:9px;width:calc(50% - 9px);top:8px;height:2px;
        background:var(--neela)"></div>
      {node("background:var(--neela);position:relative", timeline[1], "Started", "flex-start")}
      {node("background:var(--kesri);box-shadow:0 0 0 4px var(--kesriSoft);position:relative",
            "Today", timeline[2], "center", True)}
      {node("background:var(--card);box-shadow:inset 0 0 0 2px var(--edge);position:relative",
            timeline[3], timeline[4], "flex-end")}
    </div>
  </div>
  <div style="display:grid;grid-template-columns:1fr 1fr 1fr;gap:8px">
    {figure(*figures[0])}{figure(figures[1][0], figures[1][1], True)}{figure(figures[2][0], figures[2][1], True)}</div>
  {primary(sit[0], sit[1])}
  <div class="card col">
    <div class="row" style="justify-content:space-between;align-items:baseline;padding:12px 16px 6px">
      <div class="eyebrow" style="color:var(--ink2);font-weight:700">Members</div>
      <div style="font-size:13px;color:var(--ink2);font-weight:600">{members_head}</div></div>
    {rows}
    <div style="padding:8px 16px 12px;border-top:1px solid var(--rule);font-size:13.5px;
      color:var(--ink2);font-weight:600">{more}</div>
  </div>
</div>
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


# ------------------------------------------------- goals as one page, 2026-10-19

GOAL_DAY = [
    ("Amrit Vela", "moon", [("05:30", "Naam Simran", "11 min", False)]),
    ("Morning", "sun", [("06:00", "Japji Sahib", None, True), ("06:15", "Jaap Sahib", None, True),
                        ("06:30", "Tav Prasad Savaiye", None, False), ("06:45", "Chaupai Sahib", None, True),
                        ("07:00", "Anand Sahib", None, False)]),
    ("Daytime", "sun", [("11:00", "Sukhmani Sahib", None, False)]),
    ("Evening", "moon", [("18:00", "Rehras Sahib", None, True), ("18:30", "Ardas", None, False),
                         ("19:00", "Kirtan Sohila", None, True)]),
]


def goal_planner() -> str:
    """Option C of four (owner, 2026-10-19): the day as a timeline. Every bani
    and Naam Simran at its own time; tap one to add it, tap its time to move
    the reminder. Once a day each, reminders always on. 04-goals 7.2."""
    sun = ('<svg class="i" width="16" height="16" viewBox="0 0 24 24" style="color:var(--kesri)">'
           '<circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5L19 19M5 19l1.5-1.5M17.5 6.5L19 5"/></svg>')
    moon = ('<svg class="i" width="16" height="16" viewBox="0 0 24 24" style="color:var(--primary)">'
            '<path d="M20 14A8 8 0 0 1 10 4a8 8 0 1 0 10 10z"/></svg>')
    rows = []
    for band, ic, items in GOAL_DAY:
        rows.append(f'<div class="row" style="gap:8px;margin:12px 0 4px 54px">{sun if ic == "sun" else moon}'
                    f'<span class="eyebrow">{band}</span></div>')
        for time, name, detail, on in items:
            if on:
                dot = (f'<div style="width:26px;height:26px;border-radius:13px;background:var(--kesri);color:#fff;'
                       f'display:flex;align-items:center;justify-content:center;position:relative;z-index:1">'
                       f'{icon("check", 15)}</div>')
                box = (f'<div class="card row" style="flex:1;padding:10px 10px 10px 14px;gap:8px;border-radius:16px">'
                       f'<div style="flex:1;font-weight:600;font-size:15.5px">{name}</div>'
                       f'<div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk);padding:6px 9px">'
                       f'{icon("bell", 13)}{time} ▾</div></div>')
            else:
                dot = ('<div style="width:22px;height:22px;border-radius:11px;background:var(--bg);'
                       'border:2px solid var(--muted);opacity:.7;position:relative;z-index:1"></div>')
                label = name if detail is None else f"{name} · {detail}"
                box = (f'<div class="row" style="flex:1;padding:12px 14px;border:1.5px dashed var(--muted);'
                       f'border-radius:16px;color:var(--ink2);font-weight:600;font-size:15.5px">'
                       f'<span style="flex:1">{label}</span><span style="color:var(--kesri)">{icon("plus", 18)}</span></div>')
            rows.append(f'<div class="row" style="gap:8px;margin:5px 0"><div style="width:44px;text-align:right;'
                        f'font-size:12px;font-weight:600;color:var(--muted)">{time}</div>'
                        f'<div style="width:28px;display:flex;justify-content:center">{dot}</div>{box}</div>')
    return f"""
<div class="pad col" style="gap:6px;padding-bottom:150px">
  {header("Your day of paath")}
  <div style="font-size:14px;color:var(--ink2);line-height:1.45;margin-top:6px">Each paath sits at its time
    in the day. Tap one to add it to your goal, and tap it again to take it out.</div>
  <div style="position:relative">
    <div style="position:absolute;left:65px;top:30px;bottom:6px;width:2px;background:var(--rule)"></div>
    {''.join(rows)}
  </div>
</div>
<div style="position:absolute;left:0;right:0;bottom:0;z-index:2;background:var(--card);border-top:1px solid var(--rule);
  padding:12px 16px 18px" class="col">
  <div class="row" style="background:var(--card2);border-radius:14px;padding:4px;gap:4px">
    <div style="flex:1;text-align:center;padding:10px 0;border-radius:10px;background:var(--card);font-weight:600;font-size:13px">Every day</div>
    <div style="flex:1;text-align:center;padding:10px 0;font-weight:600;font-size:13px;color:var(--ink2)">For 40 days</div>
    <div style="flex:1;text-align:center;padding:10px 0;font-weight:600;font-size:13px;color:var(--ink2)">Until…</div>
  </div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary);margin-top:10px">Start goal · 5 paaths a day</div>
</div>
"""


# ------------------------------------------- Vichar articles, three layouts, 2026-10-19

def _article_body(paras, heading) -> str:
    out = []
    for p in paras:
        if p.startswith("## "):
            out.append(heading(p[3:]))
        else:
            out.append(f'<div style="font-size:15.5px;line-height:1.7;color:var(--ink2)">{p}</div>')
    return "".join(out)


def article_calendar() -> str:
    """A: a Gurpurab as a calendar card (owner, 2026-10-19): the date, the
    countdown, the title and the opening in a navy card; headings with a
    kesri bar; the facts; what comes next in the calendar."""
    bar = lambda t: (f'<div class="row" style="gap:10px;margin-top:6px"><div style="width:24px;height:3px;'
                     f'border-radius:2px;background:var(--kesri)"></div><div class="disp" style="font-size:19px;'
                     f'font-weight:700">{t}</div></div>')
    body = _article_body([
        "The Prakash Purab of Sri Guru Ram Das Ji celebrates the birth in 1534 of the fourth Sikh Guru, in Lahore.",
        "## From Lahore to the fourth Guru",
        "Bhai Jetha Ji lost both parents as a child and came to Goindwal Sahib, where he stayed to serve Sri Guru Amar Das Ji.",
    ], bar)
    return f"""
<div class="pad col" style="gap:14px;padding-top:14px">
  <div class="row" style="justify-content:space-between"><div style="width:44px">{icon("back", 22)}</div>
    <div style="font-weight:600;color:var(--ink2)">Vichar</div><div style="width:44px;display:flex;justify-content:flex-end">{icon("share", 20)}</div></div>
  <div class="col" style="background:var(--primary);color:var(--onPrimary);border-radius:24px;padding:20px;gap:12px">
    <div class="row" style="gap:14px">
      <div class="col" style="width:64px;height:72px;border-radius:16px;background:rgba(255,255,255,.1);align-items:center;justify-content:center">
        <div class="disp" style="font-size:30px;font-weight:700;line-height:1">27</div>
        <div style="font-size:11px;font-weight:600;letter-spacing:.12em;color:var(--kesri)">OCT</div></div>
      <div class="col" style="gap:6px"><div style="font-size:12px;font-weight:600;letter-spacing:.12em;color:var(--kesri)">PRAKASH PURAB · IN 8 DAYS</div>
        <div style="font-size:13.5px;opacity:.75">Tuesday, 27 October 2026</div></div>
    </div>
    <div class="disp" style="font-size:26px;font-weight:700;line-height:1.15">Prakash Purab of Sri Guru Ram Das Ji</div>
    <div style="font-size:14px;opacity:.75;line-height:1.5">The fourth Guru, who founded Amritsar and gave the Laavan of the Anand Karaj.</div>
    <div class="chip" style="background:rgba(255,255,255,.12);align-self:flex-start">2 min read</div>
  </div>
  <div class="col" style="gap:12px;padding:0 4px">{body}</div>
  <div class="eyebrow" style="margin-top:6px">Next in the calendar</div>
  {listrow("diary", "Shaheedi of Bhai Beant Singh", "Shaheedi · 1 Nov")}
</div>
"""


def _gurdwara_art(h: int = 300) -> str:
    return (f'<svg width="390" height="{h}" viewBox="0 0 390 320" preserveAspectRatio="xMidYMid slice" style="display:block">'
            '<rect width="390" height="320" fill="#232659"/><rect y="150" width="390" height="170" fill="#5E3550"/>'
            '<ellipse cx="195" cy="250" rx="190" ry="90" fill="#D9730D" opacity="0.45"/>'
            '<g fill="#0B0E26"><rect x="0" y="250" width="390" height="70"/><rect x="110" y="190" width="170" height="60"/>'
            '<rect x="160" y="160" width="70" height="30"/><path d="M160 160C160 128 180 114 195 98C210 114 230 128 230 160Z"/>'
            '<rect x="194" y="74" width="2" height="26"/><rect x="116" y="172" width="18" height="18"/>'
            '<path d="M116 172C116 162 125 158 125 150C125 158 134 162 134 172Z"/><rect x="256" y="172" width="18" height="18"/>'
            '<path d="M256 172C256 162 265 158 265 150C265 158 274 162 274 172Z"/><rect x="320" y="110" width="3" height="140"/></g>'
            '<path d="M323 112L362 124L323 136Z" fill="#D9730D"/></svg>')


def article_photo() -> str:
    """B: a place, photo-led (owner, 2026-10-19). The picture is drawn, not
    fetched (PRD 8 lists no photo host); the place is named over it. Kind and
    topics as chips, the story, then previous and next."""
    h2 = lambda t: f'<div class="disp" style="font-size:19px;font-weight:700;margin-top:6px">{t}</div>'
    body = _article_body([
        "## Serving the sick",
        "That year smallpox spread through Delhi. The Guru went among the sick of every faith, giving them water from the well at the bungalow where he stayed.",
    ], h2)
    return f"""
<div style="position:relative;height:300px">{_gurdwara_art()}
  <div class="row" style="position:absolute;left:12px;right:12px;top:14px;justify-content:space-between;color:#fff">
    <div style="width:44px;height:44px;border-radius:22px;background:rgba(7,10,30,.45);display:flex;align-items:center;justify-content:center">{icon("back", 22)}</div>
    <div style="width:44px;height:44px;border-radius:22px;background:rgba(7,10,30,.45);display:flex;align-items:center;justify-content:center">{icon("share", 20)}</div></div>
  <div style="position:absolute;right:14px;bottom:40px;font-size:11.5px;color:#fff;background:rgba(7,10,30,.5);padding:5px 8px;border-radius:8px">Gurdwara Bangla Sahib, New Delhi</div>
</div>
<div class="col" style="margin-top:-28px;background:var(--bg);border-radius:28px 28px 0 0;padding:22px 20px 0;gap:12px;position:relative">
  <div class="row" style="gap:8px;flex-wrap:wrap">
    <span class="chip" style="background:var(--kesriSoft);color:var(--kesriInk);letter-spacing:.08em">JOTI JOT</span>
    <span class="chip" style="background:var(--card2);color:var(--ink2);letter-spacing:.08em">GURDWARAS</span>
    <span class="chip" style="background:var(--card2);color:var(--ink2);letter-spacing:.08em">GURU SAHIBANS</span></div>
  <div class="disp" style="font-size:26px;font-weight:700;line-height:1.15">Joti Jot of Sri Guru Harkrishan Sahib Ji</div>
  <div style="font-size:13.5px;color:var(--muted)">Thursday, 1 April · 2 min read</div>
  <div style="font-size:16.5px;line-height:1.6">The eighth Guru, still a child, completed his life on earth in Delhi in 1664.</div>
  {body}
</div>
"""


def article_timeline() -> str:
    """C: a day of history as a timeline (owner, 2026-10-19): a navy band with
    the dates in the calendar, the opening, then each section of the story as
    a step on a line, the first in kesri."""
    def step(title, text, first=False, last=False):
        dot = ('<div style="width:18px;height:18px;border-radius:9px;background:var(--kesri);box-shadow:0 0 0 4px var(--kesriSoft)"></div>'
               if first else
               '<div style="width:12px;height:12px;border-radius:6px;background:var(--card);box-shadow:inset 0 0 0 3px var(--primary);margin-top:3px"></div>')
        line = '' if last else '<div style="flex:1;width:2px;background:var(--rule)"></div>'
        return (f'<div class="row" style="align-items:stretch;gap:14px"><div class="col" style="width:20px;align-items:center">{dot}{line}</div>'
                f'<div class="col" style="flex:1;padding-bottom:18px;gap:6px"><div style="font-weight:600;font-size:16px;'
                f'color:{"var(--kesriInk)" if first else "var(--ink)"}">{title}</div>'
                f'<div style="font-size:14.5px;line-height:1.6;color:var(--ink2)">{text}</div></div></div>')
    tiles = []
    for d, state in [("21", ""), ("22", ""), ("23", "next"), ("28", "")]:
        bg = "var(--kesri)" if state == "next" else "rgba(255,255,255,.12)"
        fg = "#1C1206" if state == "next" else "#fff"
        tiles.append(f'<div class="col" style="width:52px;height:62px;border-radius:12px;background:{bg};color:{fg};align-items:center;justify-content:center">'
                     f'<div style="font-weight:600;font-size:17px;line-height:1">{d}</div><div style="font-size:10px;font-weight:600;letter-spacing:.12em;margin-top:4px">DEC</div></div>')
    return f"""
<div class="col" style="background:var(--primary);color:var(--onPrimary);padding:14px 0 22px">
  <div class="row" style="justify-content:space-between;padding:0 12px">{icon("back", 22)}{icon("share", 20)}</div>
  <div class="col" style="padding:8px 20px 0;gap:10px">
    <div style="font-size:12px;font-weight:600;letter-spacing:.12em;color:var(--kesri)">SHAHEEDI · DEC 2026</div>
    <div class="disp" style="font-size:28px;font-weight:700;line-height:1.12">Saka Chamkaur Sahib</div>
    <div style="font-size:14px;opacity:.75;line-height:1.5">The elder Sahibzade gave their lives with a small band of Singhs against a vast army.</div>
  </div>
  <div style="padding:16px 20px 8px;font-size:11px;font-weight:600;letter-spacing:.12em;opacity:.75">IN THE CALENDAR</div>
  <div class="row" style="gap:6px;padding:0 20px">{''.join(tiles)}</div>
</div>
<div class="pad col" style="gap:14px">
  <div style="font-size:16.5px;line-height:1.65">On the night of 22 December 1704 the Guru reached Chamkaur with about forty Singhs.</div>
  <div class="eyebrow" style="margin-top:6px">How the story unfolds</div>
  <div class="col">
    {step("The garhi at Chamkaur", "Forty Singhs in a mud fortress against a vast army.", first=True)}
    {step("Five at a time", "With few arrows left, the Singhs went out in groups of five.")}
    {step("The Sahibzade", "Baba Ajit Singh Ji and Baba Jujhar Singh Ji asked to go, and fell.", last=True)}
  </div>
</div>
"""


# ------------------------------------------- saakhis, chosen 2026-10-25
# 13-saakhi.md SK11: on Today as a row of covers (option 1A), the library,
# and the menu as a left drawer (option A). The reader itself is
# design/saakhi/reader.template.html, approved 2026-10-20. Covers are small
# copies of the owner's images, kept in design/saakhi/covers/ and embedded.

SAAKHIS = [
    # id, English name, Punjabi name, length
    ("bhai-lalo-malik-bhago", "Bhai Lalo and Malik Bhago", "ਭਾਈ ਲਾਲੋ ਤੇ ਮਲਿਕ ਭਾਗੋ", "2 min"),
    ("anand-bhaya-meri-maaye", "Anand Bhaya Meri Maaye", "ਅਨੰਦੁ ਭਇਆ ਮੇਰੀ ਮਾਏ", "2 min"),
    ("why-was-the-hut-broken", "Why Was the Hut Broken?", "ਕੁੱਲੀ ਕਿਉਂ ਢਾਹੀ ਗਈ?", "2 min"),
    ("the-saint-soldier", "The Saint-Soldier", "ਸੰਤ ਸਿਪਾਹੀ", "3 min"),
]


def cover(sid: str) -> str:
    """A saakhi's cover as a data URI, so the design file stays self-contained."""
    import base64
    with open(os.path.join(ROOT, "design", "saakhi", "covers", f"{sid}.jpg"), "rb") as fh:
        return "data:image/jpeg;base64," + base64.b64encode(fh.read()).decode()


def saakhi_row() -> str:
    """Option 1A: 'Saakhis' and 'See all', then tall covers scrolling sideways."""
    cards = "".join(
        f'<div style="flex:none;width:118px;height:192px;border-radius:18px;overflow:hidden;position:relative;'
        f'background:url({cover(sid)}) center/cover;box-shadow:0 8px 18px rgba(27,29,58,.16)">'
        f'<div style="position:absolute;left:8px;top:8px;font-size:11px;font-weight:700;color:#fff;'
        f'background:rgba(12,15,36,.55);padding:3px 7px;border-radius:999px" class="row">'
        f'<span style="margin-right:3px">▶</span>{length}</div>'
        f'<div class="col" style="position:absolute;left:0;right:0;bottom:0;padding:26px 9px 9px;gap:2px;'
        f'background:linear-gradient(transparent,rgba(12,15,36,.88))">'
        f'<div class="gur" style="font-size:11.5px;color:rgba(255,255,255,.85);line-height:1.3">{pa}</div>'
        f'<div style="font-size:13px;font-weight:700;color:#fff;line-height:1.2">{en}</div></div></div>'
        for sid, en, pa, length in SAAKHIS)
    return f"""
<div class="col" style="gap:10px">
  <div class="row" style="justify-content:space-between">
    <div class="disp" style="font-size:18px;font-weight:700">Saakhis</div>
    <div style="font-size:13px;font-weight:700;color:var(--kesriInk)">See all</div>
  </div>
  <div class="row" style="gap:10px;margin-right:-20px;overflow:hidden">{cards}</div>
</div>"""


def today_saakhis() -> str:
    """Today with the saakhis row: after the Nitnem button, before ਅੱਜ ਦਾ ਵਿਚਾਰ (SK11, 1A)."""
    return f"""
{app_bar("Sat Sri Akal, Harpreet")}
<div class="col" style="gap:13px;padding:0 20px;margin-top:-32px">
  {streak_strip()}
  {goal_widget()}
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    {icon("nitnem", 20)}<div>Start your Nitnem</div></div>
  {saakhi_row()}
  {vichar_card()}
</div>
{nav("today")}
"""


def saakhi_library() -> str:
    """The library: one card per saakhi, Punjabi name above English, pages, narration, length (SK11)."""
    rows = "".join(
        f'<div class="card row" style="padding:10px;gap:14px;align-items:stretch">'
        f'<div style="width:78px;height:118px;border-radius:14px;flex:none;'
        f'background:url({cover(sid)}) center/cover"></div>'
        f'<div class="col" style="flex:1;gap:3px;justify-content:center">'
        f'<div class="gur" style="font-size:14px;color:var(--ink2);line-height:1.35">{pa}</div>'
        f'<div class="disp" style="font-size:17px;font-weight:700;line-height:1.2">{en}</div>'
        f'<div style="font-size:12.5px;color:var(--muted);margin-top:2px">8 pages · Punjabi and English narration</div>'
        f'<div class="row" style="gap:8px;margin-top:8px">'
        f'<div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk)">'
        f'{icon("play", 13)}Listen · {length}</div>'
        f'<div class="chip" style="background:var(--card2);color:var(--ink2)">Read</div></div>'
        f'</div></div>'
        for sid, en, pa, length in SAAKHIS)
    return f"""
<div class="pad col" style="gap:14px">
  {header("Saakhis", "Stories to read and listen to together")}
  <div class="col" style="gap:12px">{rows}</div>
</div>
"""


def menu_saakhis() -> str:
    """The menu as a left drawer, option A (SK11): navy header, then one list with Saakhis near the top."""
    strip = "".join(
        f'<div style="aspect-ratio:1;border-radius:50%;background:{LIT if b[4] else "rgba(255,255,255,.08)"};'
        f'box-shadow:{"none" if b[4] else "inset 0 0 0 1px rgba(255,255,255,.2)"}"></div>' for b in BADGES)
    sv = ('<svg class="i" width="20" height="20" viewBox="0 0 24 24">{}</svg>')
    glyph = {
        "Today": icon("today", 20),
        "Saakhis": sv.format('<rect x="4" y="3.5" width="12" height="17" rx="2"/><path d="M16 6.5h2a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2h-8"/>'),
        "Gurmat Quiz": sv.format('<circle cx="12" cy="12" r="8.5"/><path d="M9.6 9.4a2.5 2.5 0 0 1 4.8 1c0 1.7-2.4 2.1-2.4 3.6M12 17h.01"/>'),
        "Library": icon("nitnem", 20),
        "Badges": sv.format('<circle cx="12" cy="9" r="5.5"/><path d="M8.5 13.5L7 21l5-2.5 5 2.5-1.5-7.5"/>'),
        "Notifications": icon("bell", 20),
        "Settings": sv.format('<path d="M4 7h9M17 7h3M4 17h3M11 17h9"/><circle cx="15" cy="7" r="2"/><circle cx="9" cy="17" r="2"/>'),
        "Privacy and data": icon("shield", 20),
        "About and credits": sv.format('<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 8h.01"/>'),
        "Help": sv.format('<circle cx="12" cy="12" r="8.5"/><path d="M9.6 9.4a2.5 2.5 0 0 1 4.8 1c0 1.7-2.4 2.1-2.4 3.6M12 17h.01"/>'),
    }

    def item(t, on=False, count=None):
        bg = "var(--kesriSoft)" if on else "transparent"
        fg = "var(--kesriInk)" if on else "var(--ink)"
        ic = "var(--kesriInk)" if on else "var(--muted)"
        badge = (f'<div style="margin-left:auto;min-width:22px;height:22px;border-radius:11px;background:var(--kesri);'
                 f'color:#fff;font-size:12px;font-weight:700;display:flex;align-items:center;justify-content:center">{count}</div>'
                 if count else "")
        return (f'<div class="row" style="gap:14px;min-height:48px;padding:0 12px;border-radius:14px;background:{bg};'
                f'color:{fg};font-size:15px;font-weight:{700 if on else 600}"><div style="color:{ic}">{glyph[t]}</div>{t}{badge}</div>')

    top = item("Today", on=True) + item("Saakhis", count=4) + item("Gurmat Quiz") + item("Library") + item("Badges")
    rest = "".join(item(t) for t in ["Notifications", "Settings", "Privacy and data", "About and credits", "Help"])
    return f"""
{today_backdrop()}
<div class="col" style="position:absolute;left:0;top:0;bottom:0;width:304px;background:var(--card);
  border-radius:0 24px 24px 0;overflow:hidden">
  <div class="band col" style="color:#fff;padding:30px 18px 18px;gap:14px">
    <div class="row" style="gap:12px">{avatar("HK", "var(--kesriSoft)", "var(--kesriInk)", 52)}
      <div class="col"><div style="font-size:17px;font-weight:700">Harpreet Kaur</div>
        <div style="font-size:13px;color:rgba(255,255,255,.75)">Ludhiana</div></div></div>
    <div class="col" style="gap:8px">
      <div class="row" style="justify-content:space-between;font-size:12.5px;font-weight:600;
        color:rgba(255,255,255,.8)"><span>Badges</span><span>4 of 10</span></div>
      <div style="display:grid;grid-template-columns:repeat(10,1fr);gap:4px">{strip}</div>
    </div>
  </div>
  <div class="col" style="padding:10px 8px 0">{top}
    <div style="height:1px;background:var(--rule);margin:8px 12px"></div>{rest}</div>
  <div style="flex:1"></div>
  <div style="padding:0 20px 22px;font-size:12px;color:var(--muted)">Hazri · version 2.0</div>
</div>
"""


# ------------------------------------------------------------- saakhis, option C

def _saakhi_pa(sid: str, field: str) -> str:
    """A saakhi's Punjabi title or subtitle, read from its reviewed source file."""
    with open(os.path.join(ROOT, "content", "source", "saakhi", f"{sid}.json"), encoding="utf-8") as fh:
        return json.load(fh)[field]["pa"]


def saakhi_card() -> str:
    """Option C (owner, 2026-10-27; SK11): one card, the day's saakhi large and the others small.

    The day's saakhi is days since 1970 modulo the count, so on 27 October it
    is the second; the rest follow in a row of small covers.
    """
    import datetime
    day = (datetime.date(2026, 10, 27) - datetime.date(1970, 1, 1)).days % len(SAAKHIS)
    sid, en, pa, length = SAAKHIS[day]
    rest = "".join(
        f'<div style="flex:none;width:86px;height:128px;border-radius:14px;overflow:hidden;position:relative;'
        f'background:url({cover(s)}) center/cover">'
        f'<div class="col" style="position:absolute;left:0;right:0;bottom:0;padding:20px 7px 7px;'
        f'background:linear-gradient(transparent,rgba(12,15,36,.88))">'
        f'<div class="gur" style="font-size:10.5px;color:#fff;line-height:1.3">{p}</div></div></div>'
        for s, _, p, _ in SAAKHIS if s != sid)
    return f"""
  <div class="card col" style="padding:14px 14px 16px">
    <div class="row" style="justify-content:space-between">
      <div class="disp" style="font-size:18px;font-weight:700">Saakhis</div>
      <div style="font-size:13px;font-weight:700;color:var(--kesriInk)">See all</div>
    </div>
    <div class="row" style="gap:12px;margin-top:10px;align-items:stretch">
      <div style="width:100px;height:150px;border-radius:14px;flex:none;
        background:url({cover(sid)}) center/cover"></div>
      <div class="col" style="flex:1;min-width:0">
        <div class="eyebrow" style="color:var(--kesriInk)">Today’s saakhi</div>
        <div class="gur" style="font-size:17px;line-height:1.35;margin-top:4px">{_saakhi_pa(sid, "title")}</div>
        <div class="disp" style="font-size:15px;font-weight:700;color:var(--ink2);line-height:1.2">{en}</div>
        <div class="gur" style="font-size:12.5px;color:var(--muted);line-height:1.4;margin-top:2px">{_saakhi_pa(sid, "subtitle")}</div>
        <div style="flex:1"></div>
        <div class="row" style="gap:8px;margin-top:10px">
          <div class="btn" style="flex:1;min-height:40px;font-size:14px;background:var(--kesri);color:#fff;border-radius:12px">
            {icon("play", 14)}Listen</div>
          <div class="btn" style="flex:1;min-height:40px;font-size:14px;background:var(--card2);color:var(--ink);border-radius:12px">
            Read</div>
        </div>
      </div>
    </div>
    <div class="eyebrow" style="margin-top:14px">More saakhis</div>
    <div class="row" style="gap:9px;margin-top:8px;overflow:hidden">{rest}</div>
  </div>"""


# ------------------------------------------------------------------ Gurmat Quiz

def _drawing(name: str, size: int) -> str:
    """A category drawing exactly as the app ships it (lib/features/quiz/ui/quiz_drawings.dart).

    Read from the Dart file rather than copied, so the design cannot drift
    from the app. The Banis drawing gets its ੴ here, as the app lays
    content.db's on top of it.
    """
    import re
    with open(os.path.join(ROOT, "lib", "features", "quiz", "ui", "quiz_drawings.dart"), encoding="utf-8") as fh:
        svg = re.search(rf"static const {name} = '(.*?)';", fh.read()).group(1)
    svg = svg.replace("<svg ", f'<svg width="{size}" height="{size}" ', 1)
    if name == "banis":
        svg = svg.replace("</svg>", '<text x="32" y="17" text-anchor="middle" font-family="Noto Serif Gurmukhi,serif" '
                                    'font-size="15" font-weight="700" fill="#D9730D">ੴ</text></svg>')
    return svg


def _numeral(glyph: str, size: int = 46) -> str:
    """A Guru's topic mark: the Gurmukhi numeral in gold on navy (QuizTopicGlyph)."""
    return (f'<div class="gur" style="width:{size}px;height:{size}px;border-radius:50%;flex:none;'
            f'background:linear-gradient(135deg,#2E3577,#1A1E48);color:#F6C26B;display:flex;'
            f'align-items:center;justify-content:center;font-weight:700;font-size:{size * .44:.0f}px">{glyph}</div>')


def quiz_card() -> str:
    """The calendar leaf on Today (14-quiz.md QZ9-QZ11, design 1A): the date,
    the day's event, the topic and one explanation word for word. No buttons
    (owner, 2026-10-28); on a day with an event the whole card opens its
    Vichar page, and the arrow by the eyebrow says so."""
    small = "font-size:11px;font-weight:700;letter-spacing:.1em"
    arrow = ('<svg class="i" width="16" height="16" viewBox="0 0 24 24" style="color:var(--kesriInk)">'
             '<path d="M9 6l6 6-6 6"/></svg>')
    return f"""
  <div class="card row" style="padding:0;overflow:hidden;align-items:stretch">
    <div class="col" style="width:78px;flex:none;background:var(--kesri);color:#1C1206;
      align-items:center;justify-content:center;padding:12px 0;line-height:1.05">
      <div style="{small}">TUE</div>
      <div class="disp" style="font-size:36px;font-weight:700">27</div>
      <div style="{small}">OCT</div>
      <div style="width:40px;height:1px;background:rgba(28,18,6,.3);margin:8px 0"></div>
      <div style="font-size:12px;font-weight:700">11</div>
      <div style="font-size:10.5px;font-weight:700">Katak</div>
    </div>
    <div class="col" style="padding:12px 14px 14px;flex:1;min-width:0">
      <div class="row" style="justify-content:space-between">
        <div class="eyebrow" style="color:var(--kesriInk)">Prakash Purab</div>{arrow}</div>
      <div class="disp" style="font-size:20px;font-weight:700;line-height:1.15;margin-top:4px">Guru Ram Das Ji</div>
      <div style="font-size:13.5px;line-height:1.4;color:var(--ink2);margin-top:6px">Guru Ram Das Ji was named
        Jetha (meaning 'firstborn') as a child and later became known as Ram Das.</div>
    </div>
  </div>"""


def quiz_pick_card() -> str:
    """The quiz's own card on Today, design D (owner, 2026-10-28; QZ9, QZ12):
    Gurmat Quiz with your points and All quizzes, today's topic highlighted
    with Start, then the other categories as drawn tiles."""
    tiles = "".join(
        f'<div class="col" style="width:76px;flex:none;align-items:center;gap:4px">'
        f'<div style="width:64px;height:64px;border-radius:20px;background:var(--kesriSoft);display:flex;'
        f'align-items:center;justify-content:center">{_drawing(k, 44)}</div>'
        f'<div style="font-size:11.5px;font-weight:700;color:var(--ink2)">{label}</div></div>'
        for k, label in [("gurdwaras", "Gurdwaras"), ("banis", "Banis"), ("heroes", "Heroes"),
                         ("culture", "Culture"), ("all", "All")])
    return f"""
  <div class="card col" style="padding:12px 0 14px 16px">
    <div class="row" style="gap:8px;padding-right:12px">
      <div class="disp" style="font-size:19px;font-weight:700;flex:1">Gurmat Quiz</div>
      <div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk);padding:3px 10px">120 pts</div>
      <div class="row" style="font-size:13px;font-weight:700;color:var(--kesriInk)">All quizzes{chev(14).replace("var(--muted)", "var(--kesriInk)")}</div>
    </div>
    <div class="row" style="gap:12px;margin:8px 16px 0 0;padding:12px;border-radius:18px;border:2px solid var(--kesri);
      background:linear-gradient(90deg,var(--kesriSoft),var(--card))">
      <div style="width:60px;height:60px;border-radius:30px;background:var(--card);display:flex;align-items:center;
        justify-content:center;flex:none">{_numeral("੪", 48)}</div>
      <div class="col" style="flex:1;min-width:0">
        <div class="eyebrow" style="color:var(--kesriInk)">Today</div>
        <div class="disp" style="font-size:19px;font-weight:700;line-height:1.15">Guru Ram Das Ji</div>
        <div style="font-size:12.5px;color:var(--ink2)">5 questions · 10 points each</div>
      </div>
      <div class="btn" style="min-height:44px;padding:0 16px;font-size:14.5px;border-radius:14px;
        background:var(--primary);color:var(--onPrimary)">Start</div>
    </div>
    <div class="eyebrow" style="margin-top:12px">Or pick another</div>
    <div class="row" style="gap:8px;margin-top:8px;overflow:hidden">{tiles}</div>
  </div>"""


def today_quiz() -> str:
    """Today scrolled past the band and the goal: the Nitnem button, the
    calendar leaf (1A, no buttons), the quiz card (D), then the saakhis card
    in option C (05-today.md 6a, 6b; 14-quiz.md QZ9-QZ12; SK11). In elder
    mode too (QZ9, SK15)."""
    return f"""
<div class="col" style="gap:12px;padding:16px 20px 0">
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    {icon("nitnem", 20)}<div>Start your Nitnem</div></div>
  {quiz_card()}
  {quiz_pick_card()}
  {saakhi_card()}
</div>
{nav("today")}
"""


def _quiz_top(title: str, sub: str | None = None, left: str = "close") -> str:
    """The quiz's own top bar: close (or back), the title, a line under it."""
    glyph = ('<svg class="i" width="20" height="20" viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>'
             if left == "close" else icon(left, 20))
    return (f'<div class="row" style="gap:10px;padding:16px 18px 12px">'
            f'<div style="width:40px;height:40px;border-radius:13px;display:flex;align-items:center;'
            f'justify-content:center;background:var(--card);box-shadow:var(--shadow);flex:none">{glyph}</div>'
            f'<div class="col"><div class="disp" style="font-size:19px;font-weight:700;line-height:1.15">{title}</div>'
            + (f'<div style="font-size:12.5px;color:var(--muted);font-weight:600">{sub}</div>' if sub else "")
            + '</div></div>')


def _option(letter: str, text: str, state: str = "open") -> str:
    bg, border, mark_bg, mark_fg, fg = {
        "open": ("var(--card)", "var(--rule)", "var(--card2)", "var(--ink2)", "var(--ink)"),
        "right": ("var(--sageSoft)", "var(--sage)", "var(--sage)", "#fff", "var(--ink)"),
        "wrong": ("#FBE3E1", "#C2463D", "#C2463D", "#fff", "var(--ink)"),
        "faded": ("var(--card)", "var(--rule)", "var(--card2)", "var(--muted)", "var(--muted)"),
    }[state]
    mark = {"right": icon("check", 14), "wrong": "✕"}.get(state, letter)
    return (f'<div class="row" style="gap:12px;min-height:56px;padding:8px 14px;border-radius:16px;'
            f'background:{bg};border:1.5px solid {border};color:{fg};font-size:16px;font-weight:600">'
            f'<div style="width:30px;height:30px;border-radius:15px;flex:none;background:{mark_bg};color:{mark_fg};'
            f'display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700">{mark}</div>'
            f'{text}</div>')


def quiz_question() -> str:
    """A question, answered wrong, design A of round 8 (owner, 2026-10-28;
    QZ15): the question on a navy stage with the topic's drawing and five
    bars; the options as white cards over its foot, in the bank's order,
    marked at once; the explanation word for word with no source (QZ7); and
    only then Next question."""
    def opt(letter, text, state=""):
        bg, ring, mark_bg, mark_fg, mark = {
            "": ("var(--card)", "none", "var(--kesriSoft)", "var(--kesriInk)", letter),
            "r": ("var(--sageSoft)", "inset 0 0 0 2px var(--sage)", "var(--sage)", "#fff", icon("check", 15)),
            "w": ("rgba(179,38,30,.12)", "inset 0 0 0 2px #C2463D", "#C2463D", "#fff", "✕"),
            "f": ("var(--card)", "none", "var(--kesriSoft)", "var(--kesriInk)", letter),
        }[state]
        return (f'<div class="row" style="gap:12px;min-height:60px;padding:10px 14px;border-radius:18px;background:{bg};'
                f'box-shadow:{ring if state in ("r", "w") else "var(--shadow)"};font-size:16px;font-weight:600;'
                f'{"opacity:.5;" if state == "f" else ""}">'
                f'<div style="width:34px;height:34px;border-radius:17px;flex:none;background:{mark_bg};color:{mark_fg};'
                f'display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:700">{mark}</div>{text}</div>')
    bars = "".join(f'<div style="flex:1;height:6px;border-radius:3px;background:{"#F08A80" if i == 0 else "rgba(255,255,255,.18)"}"></div>'
                   for i in range(5))
    close = ('<svg class="i" width="20" height="20" viewBox="0 0 24 24"><path d="M6 6l12 12M18 6L6 18"/></svg>')
    return f"""
<div class="col" style="padding:22px 20px 50px;color:#fff;border-radius:0 0 30px 30px;
  background:linear-gradient(180deg,#2E3577,#1A1E48)">
  <div class="row" style="gap:12px">
    <div style="{ON_BAND}">{close}</div>
    <div class="row" style="gap:6px;flex:1">{bars}</div>
  </div>
  <div class="row" style="gap:10px;margin-top:14px">
    <div style="width:44px;height:44px;border-radius:13px;background:#FFF1DE;display:flex;align-items:center;
      justify-content:center;flex:none">{_drawing("heroes", 36)}</div>
    <div class="col"><div class="eyebrow" style="color:#F2A24E">Sikh Heroes</div>
      <div style="font-size:12.5px;color:rgba(255,255,255,.78)">Question 1 of 5 · Easy · 10 points</div></div>
  </div>
  <div class="disp" style="font-size:22px;font-weight:700;line-height:1.25;margin-top:14px">In which city did Bhagat
    Puran Singh Ji establish the Pingalwara, a home for destitute and disabled people?</div>
</div>
<div class="col" style="gap:10px;padding:0 20px;margin-top:-34px">
  {opt("A", "Lahore", "w")}{opt("B", "Ludhiana", "f")}{opt("C", "Amritsar", "r")}{opt("D", "Delhi", "f")}
  <div class="card col" style="background:var(--kesriSoft);box-shadow:none;padding:14px 16px;gap:4px">
    <div style="font-weight:700;color:var(--kesriInk)">The answer is Amritsar</div>
    <div style="font-size:14px;line-height:1.45;color:var(--ink2)">After Partition in 1947, Bhagat Puran Singh Ji
      settled in Amritsar and set up the Pingalwara to care for the destitute and disabled.</div>
  </div>
</div>
<div style="position:absolute;left:20px;right:20px;bottom:24px">
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">Next question</div></div>
"""


def quiz_result() -> str:
    """Result 4B (QZ23-QZ26): the score and points, the five answers, the
    challenge to share, then the leaderboard as the main button."""
    answers = [("In which city was Guru Ram Das Ji born?", True),
               ("What was Guru Ram Das Ji's name before he became the Guru?", True),
               ("Guru Ram Das Ji married Bibi Bhani Ji, the daughter of which Guru?", True),
               ("Which city did Guru Ram Das Ji found?", False),
               ("Who became the Guru after Guru Ram Das Ji?", True)]
    rows = "".join(
        f'<div class="row" style="gap:12px;padding:11px 14px;{"border-top:1px solid var(--rule)" if i else ""}">'
        f'<div style="width:22px;height:22px;border-radius:11px;flex:none;color:#fff;display:flex;align-items:center;'
        f'justify-content:center;font-size:12px;font-weight:700;background:{"var(--sage)" if ok else "#C2463D"}">'
        f'{icon("check", 13) if ok else "✕"}</div>'
        f'<div style="flex:1;min-width:0;font-size:14px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis">{q}</div>'
        f'{chev(16)}</div>'
        for i, (q, ok) in enumerate(answers))
    return f"""
{_quiz_top("Your answers")}
<div class="col" style="padding:4px 20px 0;gap:14px">
  <div class="col">
    <div class="row" style="align-items:flex-end;gap:14px">
      <div class="row" style="align-items:flex-end">
        <div class="disp" style="font-size:44px;font-weight:700;line-height:1">4</div>
        <div class="disp" style="font-size:22px;font-weight:700;color:var(--muted);margin:0 0 4px 2px">/5</div></div>
      <div style="font-weight:700;color:var(--kesriInk);margin-bottom:6px">+40 points</div>
    </div>
    <div style="font-weight:700;color:var(--ink2)">Guru Ram Das Ji</div>
  </div>
  <div class="card col" style="padding:4px 0">{rows}</div>
  <div class="card col" style="background:var(--kesriSoft);box-shadow:none;padding:16px;gap:4px">
    <div class="disp" style="font-size:19px;font-weight:700;line-height:1.2">Can your family beat 4 out of 5?</div>
    <div style="font-size:14px;color:var(--ink2)">Share the quiz and learn together.</div>
    <div class="btn" style="background:var(--kesri);color:#fff;margin-top:8px">{icon("share", 18)}Share the quiz</div>
  </div>
</div>
<div class="col" style="position:absolute;left:20px;right:20px;bottom:14px;gap:4px">
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">See the leaderboard · you are #3</div>
  <div style="text-align:center;font-weight:600;color:var(--primary);padding:10px">Done</div>
</div>
"""


QUIZ_PEOPLE = [("Manpreet S.", "MS", "Amritsar", 50), ("Gurleen K.", "GK", "Brampton", 50),
               ("Harpreet K.", "HK", "Ludhiana", 40), ("Jasleen K.", "JK", "Delhi", 40),
               ("Arjun S.", "AS", "Surrey", 30), ("Simran K.", "SK", "Birmingham", 30),
               ("Navdeep S.", "NS", "Patiala", 30), ("Amandeep K.", "AK", "Melbourne", 20),
               ("Ravinder S.", "RS", "Jalandhar", 20)]


def _board(you: str | None) -> str:
    rows = []
    for i, (name, ini, city, score) in enumerate(QUIZ_PEOPLE, start=1):
        me = name.startswith(you) if you else False
        rows.append(
            f'<div class="row" style="gap:12px;padding:9px 14px;{"background:var(--kesriSoft)" if me else ""}">'
            f'<div style="width:22px;font-weight:700;color:{"var(--kesriInk)" if i <= 3 else "var(--muted)"}">{i}</div>'
            + avatar(ini, "var(--kesri)" if me else "var(--card2)", "#fff" if me else "var(--ink2)", 34)
            + f'<div class="col" style="flex:1;min-width:0"><div style="font-weight:700;font-size:14.5px">'
            f'{"You" if me else name}</div><div style="font-size:12.5px;color:var(--muted)">{city}</div></div>'
            f'<div style="font-weight:700">{score}</div></div>')
    return f'<div class="card col" style="padding:4px 0;overflow:hidden">{"".join(rows)}</div>'


def _chips(items, on: str) -> str:
    return "".join(
        f'<div class="chip" style="flex:none;min-height:40px;padding:0 14px;'
        f'{"background:var(--primary);color:var(--onPrimary)" if t == on else "background:var(--card);color:var(--ink2);box-shadow:var(--shadow)"}">{t}</div>'
        for t in items)


def quiz_board() -> str:
    """Leaderboard 5A (QZ27-QZ30): one quiz, today; the top twenty, you marked."""
    return f"""
{_quiz_top("Leaderboard", left="back")}
<div class="col" style="padding:0 20px;gap:8px">
  <div class="row" style="gap:8px">{_chips(["Today", "Week", "Month"], "Today")}</div>
  <div class="row" style="gap:8px;overflow:hidden;margin-right:-20px">
    {_chips(["Everyone", "Guru Ram Das Ji", "Guru Nanak Dev Ji", "Sikh Banis"], "Guru Ram Das Ji")}</div>
  <div style="height:4px"></div>
  {_board("Harpreet")}
  <div style="text-align:center;font-size:12.5px;color:var(--muted);margin-top:2px">
    Top 20 · 46 played today · resets at midnight IST</div>
</div>
"""


def quiz_board_no_profile() -> str:
    """Leaderboard 5B (QZ29): everyone, this week, seen without a profile; the
    board is the same, with Make a profile above it."""
    return f"""
{_quiz_top("Leaderboard", left="back")}
<div class="col" style="padding:0 20px;gap:8px">
  <div class="row" style="gap:8px">{_chips(["Today", "Week", "Month"], "Week")}</div>
  <div class="row" style="gap:8px;overflow:hidden;margin-right:-20px">
    {_chips(["Everyone", "Guru Ram Das Ji", "Guru Nanak Dev Ji", "Sikh Banis"], "Everyone")}</div>
  <div class="card col" style="padding:14px 16px;gap:4px;margin-top:4px">
    <div style="font-weight:700">Make a profile to be on the leaderboard</div>
    <div style="font-size:13.5px;color:var(--ink2)">Your quiz points count from the day you make one.
      Just a name and your city.</div>
    <div style="font-weight:700;color:var(--kesriInk);margin-top:4px">Make a profile</div>
  </div>
  {_board(None)}
  <div style="text-align:center;font-size:12.5px;color:var(--muted);margin-top:2px">
    Top 20 · 312 played this week · resets Monday at midnight IST</div>
</div>
"""


def quiz_home() -> str:
    """The quiz page 6A (QZ33): Coming up on the calendar, Your quiz, the
    featured categories as drawn tiles, and the chosen category's quizzes."""
    coming = [("27", "OCT", "Guru Ram Das Ji", "Today", True),
              ("3", "NOV", "Guru Nanak Dev Ji", "Prakash Purab", False),
              ("8", "NOV", "Guru Hargobind Sahib Ji", "Bandi Chhor Divas", False)]
    rows = "".join(
        (f'<div style="height:1px;background:rgba(255,255,255,.15);margin:9px 0"></div>' if i else "")
        + f'<div class="row" style="gap:10px"><div class="col" style="width:44px;align-items:center">'
        f'<div class="disp" style="font-size:22px;font-weight:700;line-height:1">{d}</div>'
        f'<div style="font-size:10.5px;font-weight:700;opacity:.7">{m}</div></div>'
        f'<div class="col" style="flex:1"><div style="font-weight:700;font-size:14.5px">{t}</div>'
        f'<div style="font-size:12.5px;opacity:.72">{s}</div></div>'
        + ('<div class="btn" style="min-height:40px;padding:0 16px;font-size:14px;border-radius:12px;'
           'background:var(--kesri);color:#fff">Start</div>' if start else "")
        + '</div>'
        for i, (d, m, t, s, start) in enumerate(coming))
    cats = [("all", "All"), ("gurus", "Gurus"), ("gurdwaras", "Gurdwaras"), ("banis", "Banis"),
            ("heroes", "Heroes"), ("culture", "Culture")]
    tiles = "".join(
        f'<div class="col" style="width:74px;flex:none;align-items:center;gap:6px">'
        f'<div style="width:70px;height:70px;border-radius:22px;background:var(--kesriSoft);display:flex;'
        f'align-items:center;justify-content:center;border:2.5px solid {"var(--kesri)" if k == "gurus" else "transparent"}">'
        f'{_drawing(k, 46)}</div>'
        f'<div style="font-size:12px;font-weight:700;color:{"var(--kesriInk)" if k == "gurus" else "var(--ink2)"}">{label}</div></div>'
        for k, label in cats)
    gurus = [("੧", "Guru Nanak Dev Ji", 60, "3 Nov"), ("੨", "Guru Angad Dev Ji", 20, None),
             ("੪", "Guru Ram Das Ji", 40, "Today")]
    topics = "".join(
        f'<div class="card row" style="padding:12px;gap:12px">{_numeral(g)}'
        f'<div class="col" style="flex:1;min-width:0"><div class="row" style="gap:6px">'
        f'<div style="font-weight:700;font-size:14.5px">{name}</div>'
        + (f'<div class="chip" style="padding:2px 8px;font-size:11.5px;background:var(--kesriSoft);color:var(--kesriInk)">{when}</div>'
           if when else "")
        + f'</div><div style="font-size:12.5px;color:var(--muted)">5 random questions · {pts} pts so far</div></div>'
        f'<div class="btn" style="min-height:40px;padding:0 16px;font-size:14px;border-radius:12px;'
        f'background:var(--primary);color:var(--onPrimary)">Start</div></div>'
        for g, name, pts, when in gurus)
    return f"""
<div class="row" style="gap:10px;padding:16px 18px 12px">
  <div style="width:40px;height:40px;border-radius:13px;display:flex;align-items:center;justify-content:center;
    background:var(--card);box-shadow:var(--shadow)">{icon("back", 20)}</div>
  <div class="disp" style="font-size:22px;font-weight:700;flex:1">Gurmat Quiz</div>
  <div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk);min-height:40px;padding:0 14px">120 pts</div>
  <svg class="i" width="22" height="22" viewBox="0 0 24 24" style="color:var(--ink2)"><path d="M5 20V12M12 20V5M19 20v-9"/></svg>
</div>
<div class="col" style="padding:0 20px;gap:12px">
  <div class="card col" style="background:var(--primary);color:var(--onPrimary);padding:14px 16px">
    <div class="eyebrow" style="color:var(--kesri);margin-bottom:10px">Coming up on the calendar</div>{rows}</div>
  <div class="card row" style="padding:14px 16px;gap:8px">
    <div style="font-weight:700;flex:1">Your quiz</div>
    <div style="font-weight:700;color:var(--kesriInk)">120 pts</div>
    <div style="font-size:13px;color:var(--muted)">#3</div>{chev(16)}</div>
  <div class="disp" style="font-size:18px;font-weight:700;margin-top:6px">Featured categories</div>
  <div class="row" style="gap:10px;overflow:hidden;margin-right:-20px">{tiles}</div>
  <div class="row" style="justify-content:space-between;margin-top:4px">
    <div class="disp" style="font-size:18px;font-weight:700">Gurus</div>
    <div style="font-size:12.5px;color:var(--muted)">10 quizzes</div></div>
  {topics}
</div>
"""


def quiz_me() -> str:
    """Your quiz 7A (QZ34): the navy card with name, city, total and places,
    then the month as a calendar with each day's points."""
    pts = {3: 30, 4: 50, 8: 20, 11: 40, 12: 40, 15: 30, 19: 50, 20: 10, 22: 40, 25: 30, 26: 40, 27: 40}
    lead = 3  # 1 October 2026 is a Thursday; Monday first
    cells = "".join('<div></div>' for _ in range(lead)) + "".join(
        f'<div class="col" style="aspect-ratio:.82;border-radius:10px;align-items:center;justify-content:center;'
        f'{"background:var(--kesriSoft);" if d in pts else ""}'
        f'{"border:1.5px solid var(--kesri);" if d == 27 else ""}">'
        f'<div style="font-size:12px;color:{"var(--muted)" if d > 27 else "var(--ink)"}">{d}</div>'
        + (f'<div style="font-size:10.5px;font-weight:700;color:var(--kesriInk);line-height:1">{pts[d]}</div>' if d in pts else "")
        + '</div>' for d in range(1, 32))
    week = "".join(f'<div style="text-align:center;font-size:12px;font-weight:700;color:var(--muted)">{w}</div>'
                   for w in "MTWTFSS")
    place = lambda n, label: (f'<div class="col" style="flex:1;align-items:center">'
                              f'<div class="disp" style="font-size:20px;font-weight:700">{n}</div>'
                              f'<div style="font-size:12px;opacity:.72">{label}</div></div>')
    return f"""
{_quiz_top("Your quiz", left="back")}
<div class="col" style="padding:4px 20px 0;gap:16px">
  <div class="card col" style="background:var(--primary);color:#fff;padding:16px">
    <div class="row" style="gap:12px">{avatar("HK", "var(--kesri)", "#fff", 44)}
      <div class="col" style="flex:1"><div style="font-weight:700">Harpreet Kaur</div>
        <div style="font-size:12.5px;opacity:.72">Ludhiana</div></div>
      <div class="col" style="align-items:flex-end">
        <div class="disp" style="font-size:26px;font-weight:700;line-height:1;color:var(--kesri)">1,240</div>
        <div style="font-size:12px;opacity:.72">points</div></div></div>
    <div class="row" style="margin-top:16px">{place("#3", "today")}{place("#11", "this week")}{place("#18", "this month")}</div>
  </div>
  <div class="card col" style="padding:16px">
    <div class="row" style="justify-content:space-between;margin-bottom:10px">
      <div class="disp" style="font-size:18px;font-weight:700">October</div>
      <div style="font-weight:700;color:var(--kesriInk)">420 points</div></div>
    <div style="display:grid;grid-template-columns:repeat(7,1fr);gap:4px">{week}{cells}</div>
  </div>
</div>
"""


# ------------------------------------------------------- Today and Nitnem, 2026-10-29

def goal_folded() -> str:
    """Design 1A (owner, 2026-10-29; 04-goals.md 7.1): with more than three
    items the goal card folds to the one due now, the next and the earliest
    missed, with Show all and how many are done."""
    def row(name, right, colour="var(--muted)", now=False):
        mark = ('<div style="width:24px;height:24px;border-radius:12px;flex:none;border:3px solid '
                + ('var(--kesri)' if now else 'var(--rule)') + '"></div>')
        return (f'<div class="row" style="gap:10px;min-height:34px">{mark}'
                f'<div style="font-size:14px;font-weight:600;flex:1">{name}</div>'
                f'<div style="font-size:13px;color:{colour};font-weight:600">{right}</div></div>')
    return f"""
{app_bar("Welcome, Puneet Singh")}
<div class="col" style="gap:13px;padding:0 20px;margin-top:-32px">
  {streak_strip()}
  <div class="card col" style="padding:16px;gap:8px">
    <div class="row" style="justify-content:space-between">
      <div class="col">
        <div class="eyebrow">Today’s goal</div>
        <div class="disp" style="font-size:20px;font-weight:700;line-height:1.15">2 of 7 done</div>
        <div style="font-size:12.5px;color:var(--muted)">Next: Kirtan Sohila at 7 PM</div>
      </div>
      {ring(2 / 7, 52, 7)}
    </div>
    <div class="col" style="gap:2px;border-top:1px solid var(--rule);padding-top:8px">
      {row("Rehras Sahib", "Now · 6 PM", "var(--kesriInk)", True)}
      {row("Kirtan Sohila", "0 of 1 · 7 PM")}
      {row("Tav Prasad Savaiye", "Missed · 6:30 AM")}
    </div>
    <div class="row" style="justify-content:space-between;font-size:13.5px;font-weight:700">
      <span style="color:var(--kesriInk)">Show all 7</span><span style="color:var(--sage)">2 done ✓</span></div>
  </div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    {icon("nitnem", 20)}<div>Read Rehras Sahib</div></div>
</div>
{nav("today")}
"""


def _bani_pa() -> dict:
    """Bani names in Gurmukhi, from content.db (never typed here)."""
    import sqlite3
    db = sqlite3.connect(os.path.join(ROOT, "assets", "content", "content.db"))
    return {slug: pa for slug, pa in db.execute("select slug, name_pa from bani")}


def nitnem_tinted() -> str:
    """Design 2A (owner, 2026-10-29; 06-nitnem.md B9, B10): the saffron goals
    banner (1C, 2026-10-30), then one card per part of the day, tinted by its
    light and fading to the card; Before sleep in a soft lavender, never navy;
    More banis, below the fold, in sage."""
    pa = _bani_pa()
    sun = ('<svg class="i" width="22" height="22" viewBox="0 0 24 24"><path d="M3 18h18M7 18a5 5 0 0 1 10 0M12 6v3M5 10l2 2M19 10l-2 2"/></svg>')
    sunset = ('<svg class="i" width="22" height="22" viewBox="0 0 24 24"><path d="M3 18h18M7 18a5 5 0 0 1 10 0M12 5v6M9 8l3 3 3-3"/></svg>')
    moon = ('<svg class="i" width="22" height="22" viewBox="0 0 24 24"><path d="M20 14.5A8 8 0 1 1 9.5 4a6.5 6.5 0 0 0 10.5 10.5z"/></svg>')

    def bani(slug, en, right, going=False):
        ring_ = ('<div style="width:26px;height:26px;border-radius:13px;flex:none;border:3px solid '
                 + ('var(--kesri)' if going else 'var(--rule)') + '"></div>')
        return (f'<div class="row" style="gap:12px;min-height:54px;border-top:1px solid var(--rule)">{ring_}'
                f'<div class="col" style="flex:1;min-width:0;line-height:1.2"><div style="font-size:15px;font-weight:700">{en}</div>'
                f'<div class="gur" style="font-size:13px;color:var(--ink2)">{pa[slug]}</div></div>'
                f'<div style="font-size:13px;font-weight:600;color:{"var(--kesriInk)" if going else "var(--muted)"}">{right}</div></div>')

    def slot(tint, ic, title, sub, rows, play=False):
        pill = (f'<div class="row" style="gap:6px;border-radius:999px;padding:8px 14px;font-size:13px;font-weight:700;'
                f'background:var(--primary);color:var(--onPrimary)">{icon("play", 13)}Play all</div>' if play else "")
        return (f'<div class="card col" style="padding:14px 16px 4px;background:linear-gradient(135deg,{tint},var(--card) 60%)">'
                f'<div class="row" style="gap:12px;margin-bottom:8px"><div style="color:var(--kesriInk)">{ic}</div>'
                f'<div class="col" style="flex:1;line-height:1.15"><div style="font-size:16px;font-weight:700">{title}</div>'
                f'<div style="font-size:12px;color:var(--muted)">{sub}</div></div>{pill}</div>{rows}</div>')

    morning = (bani("japji-sahib", "Japji Sahib", "18:59 in", True) + bani("jaap-sahib", "Jaap Sahib", "0:15 in", True)
               + bani("tav-prasad-savaiye", "Tav Prasad Savaiye", "4 min") + bani("chaupai-sahib", "Chaupai Sahib", "4 min")
               + bani("anand-sahib", "Anand Sahib", "22 min"))
    return f"""
<style>.app{{--dusk:#F8D9C4;--lav:#E3E4F6}}.app.dark{{--dusk:#40261C;--lav:#262A55}}</style>
<div style="padding:16px 18px 10px">{header("Nitnem", "SGPC version", left="menu")}</div>
<div class="col" style="gap:14px;padding:0 20px">
  <div class="card col" style="padding:14px 16px;gap:8px;color:#2A1404;
    background:linear-gradient(135deg,#F7C88E,#F2A24E 55%,#E58A2E)">
    <div class="row" style="gap:10px"><div class="col" style="flex:1;line-height:1.15">
      <div class="eyebrow" style="color:rgba(42,20,4,.75)">My paath goals</div>
      <div class="disp" style="font-size:24px;font-weight:700">0 of 7 today</div></div>
      <div class="chip" style="background:rgba(255,255,255,.45);color:#2A1404">Change</div></div>
    <div style="height:8px;border-radius:4px;background:rgba(255,255,255,.4);overflow:hidden">
      <div style="width:3%;height:100%;background:#2A1404"></div></div>
    <div style="font-size:13px;font-weight:700">Next: Rehras Sahib at 6 PM</div>
  </div>
  {slot("var(--kesriSoft)", sun, "Amrit Vela", "5 banis · about 66 min", morning, True)}
  {slot("var(--dusk)", sunset, "Evening", "At sunset · 5:40 PM", bani("rehras-sahib", "Rehras Sahib", "15 min"))}
  {slot("var(--lav)", moon, "Before sleep", "Kirtan Sohila", bani("kirtan-sohila", "Kirtan Sohila", "4 min"))}
</div>
{nav("nitnem")}
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
    # 62-84 are the superseded Phase 3 set on another branch; never reuse them.
    ("85-TodayAppBar", "Today — app bar and streak", today_app_bar),
    ("86-TodayNoProfile", "Today — first day, no profile", today_no_profile),
    ("87-DiaryStreak", "Diary — the month, with the streak", diary_streak),
    ("88-Simran", "Simran — at rest", simran_rest),
    ("89-SimranSitting", "Simran — a sitting running", simran_sitting),
    ("90-SimranNoProfile", "Simran — no profile", simran_no_profile),
    ("91-SystemSplash", "First run — Android's splash", system_splash),
    ("92-Welcome", "First run — Welcome", welcome),
    ("93-SetupLanguage", "First run — Language", setup_language),
    ("94-SetupReading", "First run — How you read", setup_reading),
    ("95-BadgeEarned", "Badges — one earned", badge_earned),
    ("96-Badges", "Badges — all ten", badges_page),
    ("97-BadgeDetail", "Badges — one, opened", badge_detail),
    ("98-ProfileBadges", "Profile — with badges", profile_badges),
    ("99-MenuBadges", "Menu — with badges", menu_badges),
    ("100-Profile", "Profile — identity card and badge shelf", profile_card),
    ("101-EditProfile", "Edit profile — with the sunrise preview", edit_profile),
    ("102-SangatHome", "Sangat — dashboard tiles", sangat_tiles),
    ("103-BuiltInGroup", "Built-in group — ring and timeline", built_in_group),
    ("104-GroupGlobe", "Private group — the globe in the ring", lambda: group_globe(True)),
    ("105-BuiltInGroupGlobe", "Built-in group — the globe in the ring", lambda: group_globe(False)),
    ("106-GoalPlanner", "Goals — your day of paath", goal_planner),
    ("107-ArticleCalendar", "Vichar — a Gurpurab, as a calendar card", article_calendar),
    ("108-ArticlePhoto", "Vichar — a place, photo-led", article_photo),
    ("109-ArticleTimeline", "Vichar — a day of history, as a timeline", article_timeline),
    ("110-TodaySaakhis", "Today — with the saakhis row", today_saakhis),
    ("111-SaakhiLibrary", "Saakhis — the library", saakhi_library),
    ("112-MenuSaakhis", "Menu — the left drawer, with Saakhis", menu_saakhis),
    ("113-TodayQuiz", "Today — scrolled to the quiz and the saakhis", today_quiz),
    ("114-QuizQuestion", "Gurmat Quiz — a question, answered wrong", quiz_question),
    ("115-QuizResult", "Gurmat Quiz — your answers", quiz_result),
    ("116-QuizBoard", "Gurmat Quiz — one quiz's leaderboard", quiz_board),
    ("117-QuizBoardNoProfile", "Gurmat Quiz — everyone, without a profile", quiz_board_no_profile),
    ("118-QuizHome", "Gurmat Quiz — the quiz page", quiz_home),
    ("119-QuizMe", "Gurmat Quiz — your quiz", quiz_me),
    ("120-TodayGoalFolded", "Today — a goal of seven, folded", goal_folded),
    ("121-NitnemTinted", "Nitnem — each part of the day in its light", nitnem_tinted),
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
