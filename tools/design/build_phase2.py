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
    "share": '<circle cx="17" cy="6" r="2.4"/><circle cx="7" cy="12" r="2.4"/><circle cx="17" cy="18" r="2.4"/><path d="M9.2 10.9l5.6-3.3M9.2 13.1l5.6 3.3"/>',
}


def icon(name: str, size: int = 22) -> str:
    return (f'<svg class="i" width="{size}" height="{size}" viewBox="0 0 24 24">'
            f'{ICONS[name]}</svg>')


def nav(active: str) -> str:
    """The bottom bar. Settings has left it; Sangat has taken the slot."""
    tabs = [("today", "Today"), ("nitnem", "Nitnem"), ("simran", "Simran"),
            ("sangat", "Sangat"), ("diary", "Diary")]
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
    <div class="row" style="padding:0 6px">
      <div class="col" style="flex:1;align-items:center">
        <div class="disp" style="font-size:26px;font-weight:700;color:#fff;
          line-height:1.1">12,400</div>
        <div style="font-size:11.5px;color:rgba(255,255,255,.6);font-weight:600">
          in the sangat</div>
      </div>
      <div style="width:1px;align-self:stretch;background:rgba(255,255,255,.14)"></div>
      <div class="col" style="flex:1;align-items:center">
        <div class="disp" style="font-size:26px;font-weight:700;color:#6FE3A6;
          line-height:1.1">4,812</div>
        <div style="font-size:11.5px;color:rgba(255,255,255,.6);font-weight:600">
          here today</div>
      </div>
      <div style="width:1px;align-self:stretch;background:rgba(255,255,255,.14)"></div>
      <div class="col" style="flex:1;align-items:center">
        <div class="disp" style="font-size:26px;font-weight:700;color:#fff;
          line-height:1.1">64</div>
        <div style="font-size:11.5px;color:rgba(255,255,255,.6);font-weight:600">
          countries</div>
      </div>
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


def today() -> str:
    goals = [("Japji Sahib", "5:30 AM", 1.0), ("Simran", "11 min", 0.62),
             ("Rehras Sahib", "6:40 PM", 0.0)]
    rows = "".join(
        f'<div class="row" style="gap:10px">'
        f'<div style="width:26px;height:26px;flex:none">{ring(p, 26, 4)}</div>'
        f'<div style="font-size:13.5px;font-weight:600;flex:1">{n}</div>'
        f'<div style="font-size:12.5px;color:var(--muted);font-weight:600">{w}</div>'
        f'</div>' for n, w, p in goals)
    return f"""
<div class="pad col" style="gap:13px">
  {header("Today", "Friday, 20 November", left="menu", right="bell")}
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
      <div style="font-size:12px;opacity:.85">Takes a minute · no password</div>
      <div class="chip" style="background:#fff;color:#9A4F00">Set up</div>
    </div>
  </div>
  <div class="card col" style="padding:16px;gap:12px">
    <div class="row" style="justify-content:space-between">
      <div class="col">
        <div class="eyebrow">Your goals</div>
        <div class="disp" style="font-size:20px;font-weight:700">1 of 3 done</div>
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
    {icon("nitnem", 20)}<div>Start Nitnem</div></div>
  <div class="card row" style="padding:14px;gap:12px">
    <div style="width:46px;height:46px;border-radius:14px;background:var(--kesriSoft);
      color:var(--kesriInk);display:flex;align-items:center;justify-content:center;
      flex:none">{icon("diary", 22)}</div>
    <div class="col" style="flex:1">
      <div style="font-size:12px;color:var(--muted);font-weight:700">
        TOMORROW · GURPURAB</div>
      <div style="font-size:14px;font-weight:700">
        Prakash Purab, Guru Nanak Dev Ji</div>
      <div class="gur" style="font-size:12.5px;color:var(--muted)">9 ਮੱਘਰ 558</div>
    </div>
  </div>
  <div class="card col" style="padding:14px;gap:6px">
    <div class="eyebrow">ਅੱਜ ਦਾ ਵਿਚਾਰ</div>
    <div class="gur" style="font-size:16px;line-height:1.7;color:var(--ink)">
      ਸੋ ਕਿਉ ਮੰਦਾ ਆਖੀਐ ਜਿਤੁ ਜੰਮਹਿ ਰਾਜਾਨ ॥</div>
  </div>
</div>
{nav("today")}
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
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    {icon("plus", 20)}<div>Log a paath</div></div>
  <div class="col" style="gap:11px">
    <div class="row" style="justify-content:space-between">
      <div class="eyebrow">Members</div>
      <div style="font-size:12.5px;color:var(--kesriInk);font-weight:600">Invite</div>
    </div>
    {rows}
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
           "Only used to bring your sangat back if you change phone. "
           "Nobody else in the app sees it.")}
    {field("Phone", "~Add a number", optional=True)}
    {field("City", "Amritsar, Punjab",
           "Shown as a dot on the Global Simran globe.")}
  </div>
  <div class="card row" style="padding:12px 14px;gap:10px;background:var(--card2);
    box-shadow:none">
    <div style="color:var(--sage);flex:none">{icon("check", 18)}</div>
    <div style="font-size:12.5px;color:var(--ink2);line-height:1.5">
      No password to make or remember. Your diary and your paath stay on this
      phone unless you turn on sync.</div>
  </div>
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
    {listrow("bell", "Email", "harjit@example.com")}
    <div style="height:1px;background:var(--rule)"></div>
    {listrow("bell", "Phone", "Not added")}
    <div style="height:1px;background:var(--rule)"></div>
    {listrow("globe", "City", "Amritsar, Punjab")}
  </div>
  <div class="card col" style="padding:14px;gap:11px;background:var(--kesriSoft)">
    <div class="row" style="gap:10px">
      <div style="color:var(--kesriInk);flex:none">{icon("share", 20)}</div>
      <div class="col" style="flex:1">
        <div style="font-size:14px;font-weight:700;color:var(--kesriInk)">
          Secure your sangat</div>
        <div style="font-size:12.5px;color:var(--kesriInk);opacity:.85;
          line-height:1.45">Right now this account lives on this phone only.
          Add your email and it comes back if you change phone.</div>
      </div>
    </div>
    <div class="btn" style="background:var(--kesri);color:#fff;min-height:44px;
      font-size:14.5px"><div>Send me the link</div></div>
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


def secure_account() -> str:
    return f"""
<div class="pad col" style="gap:18px">
  {header("Keep your sangat")}
  <div class="col" style="align-items:center;gap:14px;padding-top:10px">
    <div style="width:92px;height:92px;border-radius:46px;background:var(--kesriSoft);
      color:var(--kesriInk);display:flex;align-items:center;justify-content:center">
      {icon("share", 44)}</div>
    <div class="disp" style="font-size:22px;font-weight:700;text-align:center;
      line-height:1.25">There is no password<br>to forget</div>
    <div style="font-size:14px;color:var(--ink2);text-align:center;line-height:1.6;
      padding:0 6px">Your account lives on this phone. Add your email and we
      will send one link — tap it and your groups, goals and diary come back on
      any phone you sign in from.</div>
  </div>
  {field("Email", "harjit@example.com")}
  {primary("Send the link")}
  <div class="card row" style="padding:12px 14px;gap:10px;background:var(--card2);
    box-shadow:none">
    <div style="color:var(--muted);flex:none">{icon("check", 18)}</div>
    <div style="font-size:12.5px;color:var(--ink2);line-height:1.5">
      We never show your email to anyone else, and we never send anything but
      this link.</div>
  </div>
  <div style="text-align:center;font-size:13px;color:var(--muted);font-weight:600">
    Not now</div>
</div>
"""


def privacy_data() -> str:
    on_phone = ["Your diary and streaks", "Reading position and goals",
                "Every bani, its audio and the calendar"]
    on_server = ["Your name and email",
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
  {primary("Set up — takes a minute")}
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
    return today().replace(nav("today"), "") + nav("today") + sheet(inner, 600)


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
    return f"""
<div class="pad col" style="gap:13px">
  {header("Sangat", "Together, wherever you are", left="menu", right="plus")}
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
  <div class="row" style="gap:10px;padding-top:2px">
    <div class="btn" style="flex:1;background:var(--primary);color:var(--onPrimary);
      min-height:48px;font-size:14.5px">{icon("plus", 18)}<div>Create</div></div>
    <div class="btn" style="flex:1;background:var(--card2);color:var(--ink2);
      min-height:48px;font-size:14.5px"><div>Join with a link</div></div>
  </div>
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
    return f"""
<div class="pad col" style="gap:15px">
  {header("Create a group")}
  <div class="col" style="gap:9px">
    <div class="eyebrow">What kind</div>
    {cards}
  </div>
  {field("Group name", "Nanda Family")}
  <div class="col" style="gap:9px">
    <div class="eyebrow">Who can join</div>
    <div class="card col" style="padding:6px 16px">
      <div class="row" style="gap:12px;padding:13px 0">
        <div class="col" style="flex:1">
          <div style="font-size:14px;font-weight:600">Anyone with the link</div>
          <div style="font-size:12px;color:var(--muted)">
            Off means you add people yourself</div>
        </div>{toggle(True)}
      </div>
    </div>
  </div>
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



def vichar_ask() -> str:
    suggested = ["What does ਹੁਕਮ mean in Japji Sahib?",
                 "Why is Sukhmani Sahib called the pearl of peace?",
                 "What is said about ਸੰਗਤ?",
                 "The meaning of ਨਾਮ ਜਪਣਾ"]
    chips = "".join(
        f'<div class="card" style="padding:13px 15px;font-size:14px;'
        f'line-height:1.45;border-radius:16px">{q}</div>' for q in suggested)
    return f"""
<div class="pad col" style="gap:15px">
  {header("ਵਿਚਾਰ", "Ask about Gurbani", left="menu")}
  <div class="card row" style="padding:14px 16px;gap:10px">
    <div style="color:var(--muted);flex:none">{icon("globe", 20)}</div>
    <div style="font-size:15px;color:var(--muted);flex:1">
      Ask about a line, a word, a bani…</div>
  </div>
  <div class="card col" style="padding:13px 15px;gap:8px;background:var(--card2);
    box-shadow:none">
    <div class="row" style="gap:8px">
      <div style="color:var(--teal);flex:none">{icon("check", 18)}</div>
      <div style="font-size:13px;font-weight:700">Where answers come from</div>
    </div>
    <div style="font-size:12.5px;color:var(--ink2);line-height:1.55">
      Every answer is a passage from Sri Guru Granth Sahib Ji and a reviewed
      teeka, shown as written, with its Ang. Nothing here is composed by a
      machine. If it is not in the sources, Hazri says so.</div>
  </div>
  <div class="col" style="gap:9px">
    <div class="eyebrow">Try asking</div>
    {chips}
  </div>
</div>
"""


def vichar_answer() -> str:
    return f"""
<div class="pad col" style="gap:14px">
  {header("ਵਿਚਾਰ")}
  <div class="card col" style="padding:14px 16px;gap:3px;background:var(--card2);
    box-shadow:none">
    <div style="font-size:11.5px;color:var(--muted);font-weight:700">YOU ASKED</div>
    <div style="font-size:14.5px;font-weight:600">
      What does ਹੁਕਮ mean in Japji Sahib?</div>
  </div>
  <div class="card col" style="padding:16px;gap:12px">
    <div class="eyebrow">The line</div>
    <div class="gur" style="font-size:19px;line-height:1.75;color:var(--ink)">
      ਹੁਕਮੀ ਹੋਵਨਿ ਆਕਾਰ ਹੁਕਮੁ ਨ ਕਹਿਆ ਜਾਈ ॥</div>
    <div style="height:1px;background:var(--rule)"></div>
    <div class="eyebrow">The teeka, as written</div>
    <div style="font-size:14.5px;line-height:1.65;color:var(--ink2)">
      By His Command, bodies are created; His Command cannot be described.</div>
    <div class="row" style="gap:8px;flex-wrap:wrap;padding-top:2px">
      <div class="chip" style="background:var(--card2);color:var(--ink2)">
        Japji Sahib · Pauri 2</div>
      <div class="chip" style="background:var(--card2);color:var(--ink2)">
        Ang 1</div>
    </div>
  </div>
  <div class="card row" style="padding:13px 15px;gap:11px">
    <div style="width:38px;height:38px;border-radius:12px;background:var(--sageSoft);
      color:var(--sage);display:flex;align-items:center;justify-content:center;
      flex:none">{icon("check", 19)}</div>
    <div class="col" style="flex:1">
      <div style="font-size:13.5px;font-weight:700">Faridkot Teeka</div>
      <div style="font-size:12px;color:var(--muted)">
        Reviewed source · see what it covers</div>
    </div>
    <div style="color:var(--muted);transform:rotate(180deg)">{icon("back", 18)}</div>
  </div>
  <div class="row" style="gap:10px">
    <div class="btn" style="flex:1;background:var(--card2);color:var(--ink2);
      min-height:46px;font-size:14px">{icon("nitnem", 18)}<div>Open in reader</div></div>
    <div class="btn" style="flex:1;background:var(--card2);color:var(--ink2);
      min-height:46px;font-size:14px">{icon("share", 18)}<div>Share</div></div>
  </div>
  <div style="font-size:11.5px;color:var(--muted);text-align:center;line-height:1.5">
    Shown exactly as the teeka has it. Hazri does not paraphrase Gurbani or
    its meanings.</div>
</div>
"""


def vichar_source() -> str:
    rows = [("Covers", "Sri Guru Granth Sahib Ji, Ang 1–1430"),
            ("Languages", "Punjabi and English · Hindi for SGGS only"),
            ("Reviewed by", "The source file shipped with the app"),
            ("Added", "Content build 8 · November 2026")]
    body = "".join(
        f'<div class="row" style="gap:12px;padding:11px 0;align-items:flex-start">'
        f'<div style="font-size:12.5px;color:var(--muted);font-weight:700;'
        f'width:96px;flex:none">{k}</div>'
        f'<div style="font-size:13.5px;color:var(--ink2);flex:1;line-height:1.5">'
        f'{v}</div></div>' for k, v in rows)
    return f"""
<div class="pad col" style="gap:15px">
  {header("Faridkot Teeka", "The source behind this answer")}
  <div class="card col" style="padding:6px 16px">{body}</div>
  <div class="card col" style="padding:15px;gap:9px;background:var(--card2);
    box-shadow:none">
    <div style="font-size:13.5px;font-weight:700">Why only reviewed sources</div>
    <div style="font-size:13px;color:var(--ink2);line-height:1.6">
      Gurbani and its meanings are never written, translated or summarised by
      this app. Hazri can only show you what is in a source somebody has
      reviewed and shipped. Where a source has no entry, there is no answer —
      and that is the honest result, not a failure.</div>
  </div>
  {ghost("See every source in this build")}
</div>
"""


def vichar_no_answer() -> str:
    return f"""
<div class="pad col" style="gap:14px">
  {header("ਵਿਚਾਰ")}
  <div class="card col" style="padding:14px 16px;gap:3px;background:var(--card2);
    box-shadow:none">
    <div style="font-size:11.5px;color:var(--muted);font-weight:700">YOU ASKED</div>
    <div style="font-size:14.5px;font-weight:600">
      When was Gurdwara Bangla Sahib built?</div>
  </div>
  <div class="col" style="align-items:center;gap:14px;padding:24px 10px 6px">
    <div style="width:84px;height:84px;border-radius:42px;background:var(--card2);
      color:var(--muted);display:flex;align-items:center;justify-content:center">
      {icon("globe", 40)}</div>
    <div class="disp" style="font-size:21px;font-weight:700;text-align:center;
      line-height:1.3">This is not in<br>the sources Hazri has</div>
    <div style="font-size:14px;color:var(--ink2);text-align:center;line-height:1.6">
      Hazri only answers from Sri Guru Granth Sahib Ji and the reviewed teekas
      shipped with it. It will not guess, and it will not write an answer of
      its own.</div>
  </div>
  <div class="card col" style="padding:15px;gap:10px">
    <div style="font-size:13.5px;font-weight:700">What it can answer</div>
    <div class="row" style="gap:8px;flex-wrap:wrap">
      <div class="chip" style="background:var(--card2);color:var(--ink2)">
        A line's meaning</div>
      <div class="chip" style="background:var(--card2);color:var(--ink2)">
        A word in a bani</div>
      <div class="chip" style="background:var(--card2);color:var(--ink2)">
        Where a shabad sits</div>
    </div>
  </div>
  {ghost("Ask something else")}
</div>
"""


def add_goal() -> str:
    chips = "".join(
        f'<div class="chip" style="background:{"var(--kesriSoft)" if on else "var(--card2)"};'
        f'color:{"var(--kesriInk)" if on else "var(--ink2)"};min-height:36px">{t}</div>'
        for t, on in [("Japji Sahib", False), ("Chaupai Sahib", False),
                      ("Rehras Sahib", False), ("Sukhmani Sahib", False),
                      ("Naam Simran", True), ("More…", False)])
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
    ("34-SecureAccount", "Keep your sangat", secure_account),
    ("35-PrivacyData", "Privacy & my data", privacy_data),
    ("36-UnlockSheet", "Join the sangat — sheet", unlock_sheet),
    ("37-SettingsMenu", "Menu", settings_menu),
    ("38-SangatHome", "Sangat", sangat_home),
    ("39-CreateGroup", "Create a group", create_group),
    ("40-SetGoal", "Shared goal", set_goal),
    ("41-Invite", "Invite", invite),
    ("42-LogPaath", "Log a paath", log_paath),
    ("43-VicharAsk", "Vichar — ask", vichar_ask),
    ("44-VicharAnswer", "Vichar — answer", vichar_answer),
    ("45-VicharSource", "Vichar — source", vichar_source),
    ("46-VicharNoAnswer", "Vichar — not in the sources", vichar_no_answer),
    ("47-AddGoal", "Add a goal", add_goal),
    ("48-ReaderComplete", "Reader — complete", reader_complete),
    ("49-Sync", "Sync", sync_states),
    ("50-Notifications", "Notifications", notifications),
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
