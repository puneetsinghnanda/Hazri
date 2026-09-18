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


DOT = {"you": ("var(--kesri)", 5.5), "member": ("#5B8DEF", 3.0),
       "today": ("#3DBE7B", 3.4)}


def dots() -> str:
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
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{colour}"/>')
    return "".join(out)


def globe(size: int = 320) -> str:
    return (
        f'<svg width="{size}" height="{size}" viewBox="0 0 320 320" '
        f'style="display:block">'
        f'<defs><radialGradient id="g" cx="35%" cy="30%">'
        f'<stop offset="0%" stop-color="#1B2450"/>'
        f'<stop offset="70%" stop-color="#0E1533"/>'
        f'<stop offset="100%" stop-color="#080B1C"/></radialGradient></defs>'
        f'<circle cx="160" cy="160" r="150" fill="url(#g)"/>'
        f'{graticule()}'
        f'<circle cx="160" cy="160" r="150" fill="none" stroke="#3A4A80" '
        f'stroke-width="1.2" opacity="0.8"/>'
        f'{dots()}</svg>')


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

def global_simran() -> str:
    people = [("GK", "Gurpreet Kaur", "Southall"), ("HS", "Harjit Singh", "Ludhiana")]
    rows = "".join(
        f'<div class="row" style="gap:10px">{avatar(i)}'
        f'<div class="col" style="flex:1"><div style="font-size:14px;font-weight:600">'
        f'{n}</div><div style="font-size:12px;color:var(--muted)">{c}</div></div>'
        f'<div class="chip" style="background:var(--sageSoft);color:var(--sage)">'
        f'11 min</div></div>' for i, n, c in people)
    return f"""
<div class="pad col" style="gap:12px">
  {header("Global Simran", "Waheguru, together", right="share")}
  <div style="display:flex;justify-content:center">{globe(296)}</div>
  {legend()}
  <div style="text-align:center;font-size:11.5px;color:var(--muted);font-weight:600;
    margin-top:-6px">Drag to turn the globe</div>
  <div class="card row" style="padding:14px;gap:0">
    <div class="col" style="flex:1;align-items:center">
      <div class="disp" style="font-size:24px;font-weight:700">4,812</div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">sat today</div>
    </div>
    <div style="width:1px;align-self:stretch;background:var(--rule)"></div>
    <div class="col" style="flex:1;align-items:center">
      <div class="disp" style="font-size:24px;font-weight:700;color:var(--sage)">
        1,240</div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">
        sitting now</div>
    </div>
    <div style="width:1px;align-self:stretch;background:var(--rule)"></div>
    <div class="col" style="flex:1;align-items:center">
      <div class="disp" style="font-size:24px;font-weight:700">64</div>
      <div style="font-size:11.5px;color:var(--muted);font-weight:600">
        countries</div>
    </div>
  </div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    {icon("simran", 20)}<div>Sit with them</div></div>
  <div class="col" style="gap:10px">
    <div class="row" style="justify-content:space-between">
      <div class="eyebrow">In your sangat today</div>
      <div style="font-size:12.5px;color:var(--kesriInk);font-weight:600">See all 8</div>
    </div>
    {rows}
  </div>
</div>
{nav("simran")}
"""


def simran_tab() -> str:
    chips = "".join(
        f'<div class="chip" style="background:{"var(--kesriSoft)" if on else "var(--card2)"};'
        f'color:{"var(--kesriInk)" if on else "var(--ink2)"};min-height:34px">{t}</div>'
        for t, on in [("5 min", False), ("11 min", True), ("21 min", False),
                      ("31 min", False)])
    faces = "".join(avatar(i, size=30) for i in ["GK", "HS", "MK", "AS"])
    return f"""
<div class="pad col" style="gap:14px">
  {header("Simran", "Goal · 11 minutes a day", left="menu", right="bell")}
  <div style="position:relative;display:flex;justify-content:center;padding:6px 0 0">
    {ring(0.62, 232, 14)}
    <div style="position:absolute;inset:0;display:flex;flex-direction:column;
      align-items:center;justify-content:center;gap:2px">
      <div class="gur" style="font-size:32px;font-weight:600">ਵਾਹਿਗੁਰੂ</div>
      <div class="disp" style="font-size:30px;font-weight:700;
        font-variant-numeric:tabular-nums">6:48</div>
      <div style="font-size:12px;color:var(--muted);font-weight:600">left of 11:00</div>
    </div>
  </div>
  <div class="row" style="gap:8px;justify-content:center;flex-wrap:wrap">{chips}</div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    <div>Begin</div></div>
  <div class="card col" style="padding:14px;gap:10px">
    <div class="row" style="justify-content:space-between">
      <div style="font-size:13.5px;font-weight:700">Today in your sangat</div>
      <div style="font-size:12.5px;color:var(--kesriInk);font-weight:600">See all</div>
    </div>
    <div class="row" style="gap:10px">
      <div class="row" style="gap:-6px">{faces}</div>
      <div style="font-size:13px;color:var(--ink2);flex:1">
        Gurpreet, Harjit and 6 others sat today</div>
    </div>
  </div>
  <div class="card row" style="padding:14px;gap:12px">
    <div style="width:52px;height:52px;border-radius:26px;background:#0E1533;
      display:flex;align-items:center;justify-content:center;color:#5B8DEF;flex:none">
      {icon("globe", 26)}</div>
    <div class="col" style="flex:1">
      <div style="font-size:14px;font-weight:700">Around the world</div>
      <div style="font-size:12.5px;color:var(--muted)">
        4,812 sat today · 1,240 sitting now</div>
    </div>
    <div style="color:var(--muted);transform:rotate(180deg)">{icon("back", 20)}</div>
  </div>
  <div class="col" style="align-items:center;gap:0;padding-top:2px">
    <div class="gur" style="font-size:16px;line-height:1.6;color:var(--ink2)">
      ਸਿਮਰਉ ਸਿਮਰਿ ਸਿਮਰਿ ਸੁਖੁ ਪਾਵਉ ॥</div>
    <div style="font-size:11px;color:var(--muted);font-weight:600">Sukhmani Sahib</div>
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


SCREENS = [
    ("28-GlobalSimran", "Global Simran", global_simran),
    ("29-Simran", "Simran", simran_tab),
    ("30-Today", "Today", today),
    ("31-GroupDetail", "Group — shared goal", group_detail),
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
