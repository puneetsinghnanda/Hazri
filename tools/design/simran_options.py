#!/usr/bin/env python3
"""Four layouts for the Simran tab, to choose between.

Simran is the global tab now: every person in the app as a dot on a globe you
can turn with your hand. Blue is a member, green opened the app today, orange
is you. Groups are not created here -- that is Sangat's job -- so this screen
has one thing to show and one thing to do.

The four differ in how much room the globe takes and where a session starts:

    1  In the ring      the globe sits where ਵਾਹਿਗੁਰੂ was, ringed by the timer
    2  Globe first      a large globe, counts under it, session full-screen
    3  Full bleed       the globe is the screen; everything floats over it
    4  Two blocks       presence above, your practice below, neither merged

Threads are drawn from your dot to every other, which is the look chosen for
the globe. Above a few hundred people they turn off and the dots stand alone;
at the size this app starts, threads are what a person will see.

    python3 tools/design/simran_options.py
"""
from __future__ import annotations

import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
OUT = os.path.join(ROOT, "design", "html")
sys.path.insert(0, HERE)

from build_phase2 import (HEAD, TAIL, avatar, css_vars, header, icon,  # noqa: E402
                          nav, ring)
from globe_variants import v_wire  # noqa: E402


def globe(size: int) -> str:
    """The chosen globe -- outline earth, your dot, a thread to each person."""
    return v_wire().replace('width="320" height="320"',
                            f'width="{size}" height="{size}"', 1)


LEGEND = [("var(--kesri)", "You"), ("#5B8DEF", "In the sangat"),
          ("#3DBE7B", "Here today")]


def legend(centred: bool = True, on_dark: bool = False) -> str:
    ink = "rgba(255,255,255,.72)" if on_dark else "var(--muted)"
    return ('<div class="row" style="gap:13px;flex-wrap:wrap;'
            + ("justify-content:center" if centred else "") + '">'
            + "".join(f'<div class="row" style="gap:6px">'
                      f'<div style="width:8px;height:8px;border-radius:4px;'
                      f'background:{c}"></div>'
                      f'<div style="font-size:11.5px;color:{ink};font-weight:600">'
                      f'{t}</div></div>' for c, t in LEGEND) + "</div>")


def counts(big: bool = False, on_dark: bool = False) -> str:
    ink = "#fff" if on_dark else "var(--ink)"
    sub = "rgba(255,255,255,.6)" if on_dark else "var(--muted)"
    rule = "rgba(255,255,255,.14)" if on_dark else "var(--rule)"
    size = 26 if big else 22
    items = [("12,400", "in the sangat", ink), ("4,812", "here today",
                                                "var(--sage)"), ("64", "countries", ink)]
    cells = ""
    for i, (n, t, colour) in enumerate(items):
        cells += (f'<div class="col" style="flex:1;align-items:center">'
                  f'<div class="disp" style="font-size:{size}px;font-weight:700;'
                  f'color:{colour};line-height:1.1">{n}</div>'
                  f'<div style="font-size:11.5px;color:{sub};font-weight:600">{t}</div>'
                  f'</div>')
        if i < 2:
            cells += f'<div style="width:1px;align-self:stretch;background:{rule}"></div>'
    return cells


def faces() -> str:
    return "".join(avatar(i, size=28) for i in ["GK", "HS", "MK", "AS"])


# ------------------------------------------------------------------ layouts

def opt1_in_ring() -> str:
    """The globe where ਵਾਹਿਗੁਰੂ was, with the session ring around it."""
    return f"""
<div class="pad col" style="gap:13px">
  {header("Simran", "The sangat, wherever it is", left="menu", right="bell")}
  <div style="position:relative;display:flex;justify-content:center;padding:4px 0 0">
    {ring(0.62, 268, 10)}
    <div style="position:absolute;inset:0;display:flex;align-items:center;
      justify-content:center">
      <div style="width:236px;height:236px;border-radius:118px;overflow:hidden;
        display:flex;align-items:center;justify-content:center;
        box-shadow:0 10px 30px rgba(11,16,40,.35)">{globe(236)}</div>
    </div>
  </div>
  <div style="text-align:center;font-size:11.5px;color:var(--muted);
    font-weight:600">Turn the globe with your hand</div>
  <div class="row" style="justify-content:center;gap:10px;margin-top:-4px">
    <div class="disp" style="font-size:26px;font-weight:700;
      font-variant-numeric:tabular-nums">6:48</div>
    <div style="font-size:12.5px;color:var(--muted);font-weight:600;
      align-self:flex-end;padding-bottom:5px">left of 11:00</div>
  </div>
  {legend()}
  <div class="card row" style="padding:12px 8px">{counts()}</div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    {icon("simran", 20)}<div>Begin</div></div>
  <div class="row" style="gap:8px;justify-content:center;flex-wrap:wrap">
    <div class="chip" style="background:var(--card2);color:var(--ink2);
      min-height:34px">5 min</div>
    <div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk);
      min-height:34px">11 min</div>
    <div class="chip" style="background:var(--card2);color:var(--ink2);
      min-height:34px">21 min</div>
    <div class="chip" style="background:var(--card2);color:var(--ink2);
      min-height:34px">31 min</div>
  </div>
</div>
{nav("simran")}
"""


def opt2_globe_first() -> str:
    """A large globe and the counts; the session takes the whole screen."""
    return f"""
<div class="pad col" style="gap:13px">
  {header("Simran", "12,400 in the sangat", left="menu", right="bell")}
  <div style="display:flex;justify-content:center;padding:2px 0">{globe(330)}</div>
  <div style="text-align:center;font-size:11.5px;color:var(--muted);
    font-weight:600;margin-top:-8px">Turn the globe with your hand</div>
  {legend()}
  <div class="card row" style="padding:13px 8px">{counts(big=True)}</div>
  <div class="btn" style="background:var(--primary);color:var(--onPrimary)">
    {icon("simran", 20)}<div>Begin Simran · 11 min</div></div>
  <div class="card row" style="padding:12px 14px;gap:11px">
    <div class="row" style="gap:0">{faces()}</div>
    <div style="font-size:12.5px;color:var(--ink2);flex:1;line-height:1.4">
      Gurpreet, Harjit and 6 others opened Hazri today</div>
  </div>
</div>
{nav("simran")}
"""


def opt3_full_bleed() -> str:
    """The globe is the screen. Everything else floats over it."""
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
      <div class="disp" style="font-size:22px;font-weight:700;color:#fff">
        Simran</div>
      <div style="font-size:11.5px;color:rgba(255,255,255,.6);font-weight:600">
        Turn the globe with your hand</div>
    </div>
    <div style="width:40px;height:40px;border-radius:13px;display:flex;
      align-items:center;justify-content:center;background:rgba(255,255,255,.09);
      color:#fff">{icon("bell", 20)}</div>
  </div>
  <div style="flex:1"></div>
  <div class="col" style="gap:14px;padding-bottom:110px">
    <div class="row" style="padding:0 6px">{counts(big=True, on_dark=True)}</div>
    {legend(on_dark=True)}
    <div class="btn" style="background:var(--kesri);color:#231104">
      {icon("simran", 20)}<div>Begin Simran · 11 min</div></div>
  </div>
</div>
{nav("simran")}
"""


def opt4_two_blocks() -> str:
    """Presence above, your own practice below. Neither pretends to be the other."""
    return f"""
<div class="pad col" style="gap:13px">
  {header("Simran", left="menu", right="bell")}
  <div class="card col" style="padding:14px 14px 12px;gap:11px;background:#0B1028">
    <div class="row" style="justify-content:space-between">
      <div class="col">
        <div style="font-size:11.5px;letter-spacing:.08em;text-transform:uppercase;
          color:rgba(255,255,255,.55);font-weight:700">The sangat right now</div>
        <div class="disp" style="font-size:19px;font-weight:700;color:#fff">
          12,400 in 64 countries</div>
      </div>
      <div class="chip" style="background:rgba(61,190,123,.16);color:#6FE3A6">
        4,812 today</div>
    </div>
    <div style="display:flex;justify-content:center">{globe(238)}</div>
    {legend(on_dark=True)}
  </div>
  <div class="card col" style="padding:15px;gap:12px">
    <div class="row" style="gap:14px">
      <div style="position:relative;width:74px;height:74px;flex:none">
        {ring(0.62, 74, 8)}
        <div style="position:absolute;inset:0;display:flex;flex-direction:column;
          align-items:center;justify-content:center">
          <div class="disp" style="font-size:16px;font-weight:700;line-height:1;
            font-variant-numeric:tabular-nums">6:48</div>
          <div style="font-size:9.5px;color:var(--muted);font-weight:600">
            of 11:00</div>
        </div>
      </div>
      <div class="col" style="flex:1;gap:3px">
        <div class="eyebrow">Your Simran</div>
        <div style="font-size:15px;font-weight:700">11 minutes a day</div>
        <div style="font-size:12.5px;color:var(--muted)">7 day streak · in Goals</div>
      </div>
    </div>
    <div class="row" style="gap:7px;flex-wrap:wrap">
      <div class="chip" style="background:var(--card2);color:var(--ink2);
        min-height:32px">5 min</div>
      <div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk);
        min-height:32px">11 min</div>
      <div class="chip" style="background:var(--card2);color:var(--ink2);
        min-height:32px">21 min</div>
      <div class="chip" style="background:var(--card2);color:var(--ink2);
        min-height:32px">31 min</div>
    </div>
    <div class="btn" style="background:var(--primary);color:var(--onPrimary);
      min-height:48px;font-size:15px">{icon("simran", 19)}<div>Begin</div></div>
  </div>
  <div class="col" style="align-items:center;gap:0">
    <div class="gur" style="font-size:15px;line-height:1.6;color:var(--ink2)">
      ਸਿਮਰਉ ਸਿਮਰਿ ਸਿਮਰਿ ਸੁਖੁ ਪਾਵਉ ॥</div>
    <div style="font-size:11px;color:var(--muted);font-weight:600">Sukhmani Sahib</div>
  </div>
</div>
{nav("simran")}
"""


SCREENS = [
    ("29a-Simran-InRing", "Simran — globe in the ring", opt1_in_ring),
    ("29b-Simran-GlobeFirst", "Simran — globe first", opt2_globe_first),
    ("29c-Simran-FullBleed", "Simran — full bleed", opt3_full_bleed),
    ("29d-Simran-TwoBlocks", "Simran — two blocks", opt4_two_blocks),
]


def main() -> int:
    for stem, title, build in SCREENS:
        body = build()
        for theme in ("light", "dark"):
            head = HEAD.format(title=f"{title} — {theme}", light=css_vars("light"),
                               dark=css_vars("dark"), cls=theme)
            path = os.path.join(OUT, f"{stem}.{theme}.html")
            with open(path, "w", encoding="utf-8") as fh:
                fh.write(head + body + TAIL)
        print(f"wrote {stem}.{{light,dark}}.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
