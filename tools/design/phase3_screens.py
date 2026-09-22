#!/usr/bin/env python3
"""Draws the Phase 3 design set into design/html/ (light and dark).

The screens are 390 x 844 CSS px, share the Phase 1 and 2 design system
(the tokens block below is the one every earlier screen carries) and are
what design/review/phase3-review.html puts on one page for comment.

Rule 3 of CLAUDE.md applies to a design file as it does to Dart: every line
of Gurbani below was copied from assets/content/content.db (Japji Sahib's
opening lines, the Sukhmani quote and the Vichar dataset's first line) and
nothing is paraphrased or invented. Saakhi and article bodies are drawn as
placeholder bars, never prose, and no illustration slot can hold a figure.

    python3 tools/design/phase3_screens.py
"""
from __future__ import annotations

import html
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "design" / "html"

HEAD = """<!doctype html>
<html><head><meta charset="utf-8"><title>{title} — {theme}</title>
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+Paaji+2:wght@500;600;700&amp;family=Mukta:wght@400;500;600;700&amp;family=Noto+Serif+Gurmukhi:wght@400;500;600;700&amp;family=Noto+Serif+Devanagari:wght@400;500;600&amp;display=swap">
  <style>
body{{margin:0;background:#888}}
.app{{--bg:#F4F3F8;--card:#FFFFFF;--card2:#ECEBF3;--ink:#1B1D3A;--ink2:#4D5070;--muted:#85879F;--rule:#E1E1EA;--primary:#262C63;--onPrimary:#FFFFFF;--kesri:#D9730D;--kesriSoft:#FBE8D2;--kesriInk:#9A4F00;--sage:#2E7A57;--sageSoft:#DCEFE5;--teal:#1F7A8C;--hl:#FBE5CB;--word:#A04F00;--simranField:#080B1C;--simranThread:#E8F4F8;--scrim:rgba(20,22,45,.45);--shadow:0 1px 2px rgba(27,29,58,.06),0 10px 28px rgba(27,29,58,.07);
  width:390px;height:844px;background:var(--bg);color:var(--ink);font-family:Mukta,'Noto Sans Devanagari',system-ui,sans-serif;position:relative;overflow:hidden;box-sizing:border-box;font-size:15px;line-height:1.45}}
.app.dark{{--bg:#0C0F24;--card:#161A37;--card2:#1F2447;--ink:#EDECF6;--ink2:#B9BAD3;--muted:#8084A6;--rule:#2A2F55;--primary:#F2A24E;--onPrimary:#1C1206;--kesri:#F2A24E;--kesriSoft:#3A2A1A;--kesriInk:#FFC27E;--sage:#6CCB9C;--sageSoft:#173327;--teal:#6FC3D3;--hl:rgba(242,162,78,.17);--word:#FFC27E;--simranField:#080B1C;--simranThread:#E8F4F8;--shadow:0 0 0 1px rgba(255,255,255,.04);}}
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
.bar{{height:9px;border-radius:5px;background:var(--card2)}}
.tog{{width:44px;height:26px;border-radius:13px;flex:none;position:relative}}
.tog i{{position:absolute;top:3px;width:20px;height:20px;border-radius:10px;background:#fff}}
</style></head><body>
<div class="app {theme}">
"""

FOOT = """
</div>
</body></html>
"""

# ---------------------------------------------------------------- real text
# From content.db. Do not edit these strings by hand.
JAPJI = [
    ("ਆਦਿ ਸਚੁ ਜੁਗਾਦਿ ਸਚੁ ॥", "aad sach jugaad sach |"),
    ("ਹੈ ਭੀ ਸਚੁ ਨਾਨਕ ਹੋਸੀ ਭੀ ਸਚੁ ॥੧॥", "hai bhee sach naanak hosee bhee sach |1|"),
    ("ਸੋਚੈ ਸੋਚਿ ਨ ਹੋਵਈ ਜੇ ਸੋਚੀ ਲਖ ਵਾਰ ॥", "sochai soch na hovee je sochee lakh vaar |"),
    ("ਚੁਪੈ ਚੁਪ ਨ ਹੋਵਈ ਜੇ ਲਾਇ ਰਹਾ ਲਿਵ ਤਾਰ ॥", "chupai chup na hovee je laae rahaa liv taar |"),
    ("ਭੁਖਿਆ ਭੁਖ ਨ ਉਤਰੀ ਜੇ ਬੰਨਾ ਪੁਰੀਆ ਭਾਰ ॥", "bhukhiaa bhukh na utaree je banaa pureea bhaar |"),
]
MEANING_EN = "True in the prime, True in the beginning of ages,"
SUKHMANI_QUOTE = ("ਸਿਮਰਉ ਸਿਮਰਿ ਸਿਮਰਿ ਸੁਖੁ ਪਾਵਉ ॥", "Sukhmani Sahib")
VICHAR_LINE = ("ਮਿਠਤੁ ਨੀਵੀ ਨਾਨਕਾ ਗੁਣ ਚੰਗਿਆਈਆ ਤਤੁ ॥",
               "Humility is sweetness, and it is the essence of true goodness.")
WAHEGURU = "ਵਾਹਿਗੁਰੂ"
# The Gurmukhi alphabet is an alphabet, not Gurbani.
PAINTI = ["ੳ", "ਅ", "ੲ", "ਸ", "ਹ", "ਕ", "ਖ", "ਗ", "ਘ", "ਙ", "ਚ", "ਛ", "ਜ", "ਝ", "ਞ",
          "ਟ", "ਠ", "ਡ", "ਢ", "ਣ", "ਤ", "ਥ", "ਦ", "ਧ", "ਨ", "ਪ", "ਫ", "ਬ", "ਭ", "ਮ",
          "ਯ", "ਰ", "ਲ", "ਵ", "ੜ"]

# ---------------------------------------------------------------- icons
I = {
    "back": '<path d="M15 5l-7 7 7 7"/>',
    "menu": '<path d="M4 7h16M4 12h16M4 17h16"/>',
    "chev": '<path d="M9 5l7 7-7 7"/>',
    "check": '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
    "play": '<path d="M8 5.5v13l10-6.5z" fill="currentColor" stroke="none"/>',
    "pause": '<rect x="6.5" y="5" width="3.8" height="14" rx="1.2" fill="currentColor" stroke="none"/><rect x="13.7" y="5" width="3.8" height="14" rx="1.2" fill="currentColor" stroke="none"/>',
    "mic": '<rect x="9" y="3.5" width="6" height="11" rx="3"/><path d="M5.5 11.5a6.5 6.5 0 0 0 13 0M12 18v2.5"/>',
    "bell": '<path d="M6 16.5V11a6 6 0 0 1 12 0v5.5l1.5 1.5h-15z"/><path d="M10 20.5a2.2 2.2 0 0 0 4 0"/>',
    "book": '<path d="M12 6.5C10.5 5.2 8 4.5 4 4.5v13c4 0 6.5.7 8 2 1.5-1.3 4-2 8-2v-13c-4 0-6.5.7-8 2z"/><path d="M12 6.5v13"/>',
    "sun": '<path d="M3 18h18"/><path d="M7 18a5 5 0 0 1 10 0"/><path d="M12 5v3M5.2 9.2l1.8 1.8M18.8 9.2L17 11M3 14h1.5M19.5 14H21"/>',
    "pin": '<path d="M12 21s-6.5-6-6.5-11a6.5 6.5 0 0 1 13 0c0 5-6.5 11-6.5 11z"/><circle cx="12" cy="10" r="2.3"/>',
    "lock": '<rect x="5" y="10.5" width="14" height="10" rx="2.5"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5"/>',
    "cast": '<path d="M3 16.5v1.5M3 12.5a6 6 0 0 1 6 6M3 8.5a10 10 0 0 1 10 10"/><path d="M8 5.5h12a1.5 1.5 0 0 1 1.5 1.5v10A1.5 1.5 0 0 1 20 18.5h-5"/>',
    "share": '<path d="M12 3.5v11M8 7.5l4-4 4 4"/><path d="M5 12.5v6a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-6"/>',
    "flag": '<path d="M5 21V4.5h11l-1.2 3.5 1.2 3.5H5"/>',
    "help": '<circle cx="12" cy="12" r="8.5"/><path d="M9.6 9.6a2.5 2.5 0 1 1 3.4 2.3c-.7.3-1 .8-1 1.6"/><circle cx="12" cy="17" r=".6" fill="currentColor"/>',
    "sangat": '<circle cx="9" cy="9" r="3.2"/><path d="M3.5 19.5a5.5 5.5 0 0 1 11 0"/><circle cx="17" cy="7.5" r="2.4"/><path d="M15.5 13.2a4.6 4.6 0 0 1 5 4.6"/>',
    "simran": '<circle cx="12" cy="12" r="3.2"/><circle cx="12" cy="3.8" r="1.4" fill="currentColor"/><circle cx="17.8" cy="6.2" r="1.4" fill="currentColor"/><circle cx="20.2" cy="12" r="1.4" fill="currentColor"/><circle cx="17.8" cy="17.8" r="1.4" fill="currentColor"/><circle cx="12" cy="20.2" r="1.4" fill="currentColor"/><circle cx="6.2" cy="17.8" r="1.4" fill="currentColor"/><circle cx="3.8" cy="12" r="1.4" fill="currentColor"/><circle cx="6.2" cy="6.2" r="1.4" fill="currentColor"/>',
    "calendar": '<rect x="3.5" y="5" width="17" height="15.5" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4"/>',
    "globe": '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.6 3.5 5.5 3.5 8.5s-1 5.9-3.5 8.5c-2.5-2.6-3.5-5.5-3.5-8.5s1-5.9 3.5-8.5z"/>',
    "eye": '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="2.8"/>',
    "sparkle": '<path d="M12 3.5l1.8 5.2 5.2 1.8-5.2 1.8L12 17.5l-1.8-5.2L5 10.5l5.2-1.8z"/>',
    "clock": '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
    "headphones": '<path d="M4 15v-3a8 8 0 0 1 16 0v3"/><rect x="3.5" y="14" width="4" height="6" rx="1.5"/><rect x="16.5" y="14" width="4" height="6" rx="1.5"/>',
    "watch": '<rect x="6.5" y="6.5" width="11" height="11" rx="3"/><path d="M9 6.5V3.5h6v3M9 17.5v3h6v-3"/>',
    "close": '<path d="M6 6l12 12M18 6L6 18"/>',
    "plus": '<path d="M12 5v14M5 12h14"/>',
    "route": '<circle cx="6" cy="18" r="2.5"/><circle cx="18" cy="6" r="2.5"/><path d="M8 17h6a3 3 0 0 0 0-6h-4a3 3 0 0 1 0-6h6"/>',
}


def ic(name: str, size: int = 20, style: str = "") -> str:
    return (f'<svg class="i" width="{size}" height="{size}" viewBox="0 0 24 24"'
            f'{" style=" + chr(34) + style + chr(34) if style else ""}>{I[name]}</svg>')


# ---------------------------------------------------------------- pieces
def e(s: str) -> str:
    return html.escape(s, quote=False)


def header(title: str, sub: str | None = None, *, back: bool = True,
           trailing: str | None = None, gur: bool = False) -> str:
    btn = ('<div style="width:40px;height:40px;border-radius:13px;display:flex;align-items:center;'
           'justify-content:center;background:var(--card);box-shadow:var(--shadow)">'
           f'{ic("back" if back else "menu")}</div>')
    subl = (f'<div style="font-size:12.5px;color:var(--muted);font-weight:500">{e(sub)}</div>'
            if sub else "")
    cls = "disp gur" if gur else "disp"
    right = trailing or '<div style="width:44px"></div>'
    return (f'<div class="row" style="justify-content:space-between;gap:10px"><div class="row" style="gap:10px">{btn}'
            f'<div class="col" style="gap:0px"><div class="{cls}" style="font-size:24px;font-weight:700;line-height:1.15">{e(title)}</div>{subl}</div></div>{right}</div>')


def iconbtn(name: str, *, soft: bool = False) -> str:
    bg = "var(--kesriSoft)" if soft else "var(--card)"
    fg = "var(--kesriInk)" if soft else "var(--ink)"
    return (f'<div style="width:40px;height:40px;border-radius:13px;display:flex;align-items:center;'
            f'justify-content:center;background:{bg};color:{fg};box-shadow:var(--shadow);flex:none">{ic(name)}</div>')


def primary(label: str, icon: str | None = None, *, kesri: bool = False, h: int = 52) -> str:
    bg = "var(--kesri)" if kesri else "var(--primary)"
    fg = "#fff" if kesri else "var(--onPrimary)"
    return (f'<div class="btn" style="background:{bg};color:{fg};min-height:{h}px">'
            f'{ic(icon) if icon else ""}<div>{e(label)}</div></div>')


def secondary(label: str, icon: str | None = None, h: int = 48) -> str:
    return (f'<div class="btn" style="background:var(--card2);color:var(--ink2);min-height:{h}px;font-size:15px">'
            f'{ic(icon, 18) if icon else ""}<div>{e(label)}</div></div>')


def note(text: str, icon: str = "lock") -> str:
    return (f'<div class="card row" style="padding:12px 14px;gap:10px;background:var(--card2);box-shadow:none">'
            f'<div style="color:var(--muted);flex:none">{ic(icon, 18)}</div>'
            f'<div style="font-size:12.5px;color:var(--ink2);line-height:1.5">{e(text)}</div></div>')


def toggle(on: bool, *, colour: str = "var(--sage)") -> str:
    if on:
        return f'<div class="tog" style="background:{colour}"><i style="right:3px"></i></div>'
    return '<div class="tog" style="background:var(--rule)"><i style="left:3px"></i></div>'


def settings_row(title: str, sub: str | None, trailing: str, *, first: bool = False) -> str:
    border = "" if first else "border-top:1px solid var(--rule);"
    subl = f'<div style="font-size:12px;color:var(--muted)">{e(sub)}</div>' if sub else ""
    return (f'<div class="row" style="gap:12px;padding:13px 0;{border}"><div class="col" style="flex:1">'
            f'<div style="font-size:14px;font-weight:600">{e(title)}</div>{subl}</div>{trailing}</div>')


def chevron() -> str:
    return f'<div style="color:var(--muted)">{ic("chev", 18)}</div>'


def bars(widths: list[int], *, h: int = 9, gap: int = 8) -> str:
    """Placeholder body copy, drawn rather than written (CLAUDE.md rule 3)."""
    rows = "".join(f'<div class="bar" style="width:{w}%;height:{h}px"></div>' for w in widths)
    return f'<div class="col" style="gap:{gap}px">{rows}</div>'


def abstract_art(h: int = 120, cx: int = 250) -> str:
    rings = "".join(
        f'<circle cx="{cx}" cy="{h // 2}" r="{26 + 17 * i}" fill="none" '
        f'stroke="rgba(242,162,78,{0.40 - 0.045 * i:.2f})" stroke-width="1.4"/>' for i in range(8))
    return (f'<div style="height:{h}px;border-radius:16px;overflow:hidden;background:linear-gradient(135deg,var(--primary),#0E1533);position:relative;flex:none">'
            f'<svg width="100%" height="{h}" viewBox="0 0 320 {h}" preserveAspectRatio="xMidYMid slice" style="display:block">{rings}</svg></div>')


def nav(active: str) -> str:
    tabs = [("Today", "sun"), ("Nitnem", "book"), ("Simran", "simran"), ("Sangat", "sangat"), ("Diary", "calendar")]
    out = []
    for label, icon in tabs:
        on = label == active
        pill = ('background:var(--kesriSoft);color:var(--kesriInk)' if on else 'color:var(--muted)')
        out.append(f'<div class="col" style="align-items:center;gap:4px;flex:1"><div style="width:58px;height:32px;border-radius:16px;display:flex;align-items:center;justify-content:center;{pill}">{ic(icon, 22)}</div>'
                   f'<div style="font-size:12px;line-height:1.45;font-weight:{700 if on else 500};color:{"var(--ink)" if on else "var(--muted)"}">{label}</div></div>')
    return ('<div style="position:absolute;left:0;right:0;bottom:0;background:var(--card);border-top:1px solid var(--rule);display:flex;padding:10px 4px 22px">'
            + "".join(out) + '</div>')


def gur_line(text: str, *, size: float = 20, colour: str = "var(--ink)", weight: int = 500) -> str:
    return f'<div class="gur" style="font-size:{size}px;line-height:1.6;color:{colour};font-weight:{weight}">{e(text)}</div>'


def screen(body: str, *, pad_gap: int = 14) -> str:
    return f'<div class="pad col" style="gap:{pad_gap}px">{body}</div>'


# ---------------------------------------------------------------- screens
SCREENS: dict[str, tuple[str, str]] = {}


def add(id_: str, title: str, body: str) -> None:
    SCREENS[id_] = (title, body)


# 62 — recitation check, live
def s62() -> str:
    def line(g, r, state):
        if state == "heard":
            mark = f'<div style="width:22px;height:22px;border-radius:11px;background:var(--sage);color:#fff;display:flex;align-items:center;justify-content:center;flex:none">{ic("check", 13)}</div>'
            col = "var(--ink)"
        elif state == "now":
            mark = f'<div style="width:22px;height:22px;border-radius:11px;background:var(--kesri);color:#fff;display:flex;align-items:center;justify-content:center;flex:none">{ic("mic", 13)}</div>'
            col = "var(--ink)"
        else:
            mark = '<div style="width:22px;height:22px;border-radius:11px;border:2px solid var(--rule);flex:none"></div>'
            col = "var(--muted)"
        bg = "background:var(--hl);border-radius:14px;" if state == "now" else ""
        return (f'<div class="row" style="gap:12px;padding:12px 12px;{bg}align-items:flex-start">{mark}'
                f'<div class="col" style="gap:2px;flex:1">{gur_line(g, size=19, colour=col)}'
                f'<div style="font-size:12px;color:var(--muted)">{e(r)}</div></div></div>')
    lines = "".join([
        line(*JAPJI[0], "heard"), line(*JAPJI[1], "heard"), line(*JAPJI[2], "now"),
        line(*JAPJI[3], "next"), line(*JAPJI[4], "next"),
    ])
    live = ('<div class="card row" style="padding:12px 14px;gap:10px;background:var(--sageSoft);box-shadow:none">'
            '<div style="width:10px;height:10px;border-radius:5px;background:var(--sage);flex:none"></div>'
            '<div class="col" style="flex:1"><div style="font-size:14px;font-weight:700;color:var(--sage)">Listening · 2 of 38 pauris heard</div>'
            '<div style="font-size:12px;color:var(--sage);opacity:.85">Say each line at your own pace. Nothing is scored.</div></div>'
            f'<div style="color:var(--sage)">{ic("mic", 20)}</div></div>')
    body = header("Japji Sahib", "Recitation check", trailing=iconbtn("headphones")) + live + \
        f'<div class="card col" style="padding:6px 4px">{lines}</div>' + \
        note("The check runs on this phone and keeps no recording. Nothing you say leaves it.", "lock") + \
        secondary("Stop checking", "close")
    return screen(body, pad_gap=12)


add("62-RecitationCheck", "Recitation check", s62())


# 63 — recitation summary
def s63() -> str:
    def again(g, r):
        return (f'<div class="row" style="gap:12px;padding:12px 0;border-top:1px solid var(--rule)">'
                f'<div class="col" style="flex:1;gap:2px">{gur_line(g, size=17)}<div style="font-size:12px;color:var(--muted)">{e(r)}</div></div>'
                f'<div style="width:38px;height:38px;border-radius:19px;background:var(--kesriSoft);color:var(--kesriInk);display:flex;align-items:center;justify-content:center;flex:none">{ic("play", 18)}</div></div>')
    top = ('<div class="card col" style="padding:18px 16px;gap:8px;background:linear-gradient(135deg,var(--kesri),#B8560A);color:#fff">'
           '<div style="font-size:12px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;opacity:.85">Japji Sahib · recited aloud</div>'
           '<div class="disp" style="font-size:30px;font-weight:700;line-height:1.1">36 of 38 pauris</div>'
           '<div style="font-size:13px;opacity:.9">Counted as a paath. Today’s hazri was marked at 5:52 AM.</div></div>')
    listen = ('<div class="col" style="gap:8px"><div class="eyebrow">Two lines to hear again</div>'
              '<div class="card col" style="padding:2px 16px">'
              + again(*JAPJI[4]) .replace("border-top:1px solid var(--rule)", "") + again(*JAPJI[3]) +
              '</div></div>')
    how = ('<div class="card col" style="padding:14px 16px;gap:6px">'
           '<div style="font-size:14px;font-weight:700">What “heard” means</div>'
           '<div style="font-size:13px;color:var(--ink2);line-height:1.5">The phone matched your voice to the line’s own recitation, on the phone. It never says whether you recited well — only that you did, so the day counts even with the screen dark.</div></div>')
    body = header("Recitation check", "Done · 24 minutes") + top + listen + how + primary("Back to Today")
    return screen(body)


add("63-RecitationSummary", "Recitation check, done", s63())


# 64 — pronunciation practice
def s64() -> str:
    g, r = JAPJI[0]
    words_g = g.split(" ")
    words_r = r.replace(" |", "").split(" ")
    states = ["ok", "ok", "again", "ok"]
    chips = []
    for wg, wr, st in zip(words_g, words_r, states):
        if st == "ok":
            bg, fg = "var(--sageSoft)", "var(--sage)"
        else:
            bg, fg = "var(--kesriSoft)", "var(--kesriInk)"
        chips.append(f'<div class="col" style="align-items:center;gap:2px;padding:8px 12px;border-radius:14px;background:{bg};color:{fg}">'
                     f'<div class="gur" style="font-size:20px;font-weight:600">{e(wg)}</div><div style="font-size:11px;font-weight:600">{e(wr)}</div></div>')
    def wave(colour, heights, label, action):
        bars_ = "".join(f'<div style="width:3px;border-radius:2px;background:{colour};height:{h}px"></div>' for h in heights)
        return (f'<div class="row" style="gap:12px"><div style="width:40px;height:40px;border-radius:20px;background:var(--card2);color:var(--ink);display:flex;align-items:center;justify-content:center;flex:none">{ic(action, 18)}</div>'
                f'<div class="col" style="flex:1;gap:4px"><div style="font-size:12px;font-weight:600;color:var(--muted)">{label}</div>'
                f'<div class="row" style="gap:3px;height:28px;align-items:center">{bars_}</div></div></div>')
    h1 = [6, 12, 20, 26, 18, 10, 14, 24, 28, 16, 8, 6, 14, 22, 26, 20, 12, 8, 10, 18, 24, 16, 8, 6, 12, 20, 14, 8, 6, 4]
    h2 = [4, 10, 18, 24, 20, 12, 12, 20, 26, 18, 10, 6, 10, 16, 18, 12, 8, 6, 10, 20, 26, 18, 10, 6, 14, 22, 16, 10, 6, 4]
    card = ('<div class="card col" style="padding:18px 16px;gap:14px">'
            '<div class="eyebrow">Japji Sahib · line 3 of 38</div>'
            f'{gur_line(g, size=27, weight=600)}'
            f'<div style="font-size:13px;color:var(--muted)">{e(r.replace(" |", ""))}</div>'
            f'<div style="font-size:13px;color:var(--ink2);line-height:1.5">{e(MEANING_EN)}</div>'
            '<div style="height:1px;background:var(--rule)"></div>'
            f'<div class="row" style="gap:8px;flex-wrap:wrap">{"".join(chips)}</div>'
            '<div style="font-size:12px;color:var(--muted)">One word to hear again. Tap any word to hear the paathi say it alone.</div>'
            '</div>')
    compare = ('<div class="card col" style="padding:14px 16px;gap:12px">'
               + wave("var(--primary)", h1, "The paathi", "play")
               + wave("var(--kesri)", h2, "You · just now", "play") + '</div>')
    body = header("Pronunciation", "Practice a line") + card + compare + \
        '<div class="row" style="gap:10px"><div style="flex:1">' + secondary("Hear it", "headphones", 52) + '</div><div style="flex:1">' + primary("Say it", "mic", kesri=True) + '</div></div>' + \
        note("Your voice stays on this phone and is gone when you leave this line.", "lock")
    return screen(body, pad_gap=12)


add("64-PronunciationPractice", "Pronunciation practice", s64())


# 65 — Gurmukhi letters (kids)
def s65() -> str:
    tiles = []
    for i, ch in enumerate(PAINTI):
        sel = ch == "ਸ"
        bg = "var(--kesri)" if sel else "var(--card)"
        fg = "#fff" if sel else "var(--ink)"
        tiles.append(f'<div class="gur" style="aspect-ratio:1;border-radius:16px;background:{bg};color:{fg};box-shadow:var(--shadow);display:flex;align-items:center;justify-content:center;font-size:30px;font-weight:600">{ch}</div>')
    grid = f'<div style="display:grid;grid-template-columns:repeat(5,1fr);gap:9px">{"".join(tiles)}</div>'
    kid = ('<div class="row" style="gap:8px"><div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk)">'
           f'{ic("sparkle", 14)} Kids mode</div><div class="chip" style="background:var(--card2);color:var(--ink2)">Letters</div>'
           '<div class="chip" style="background:var(--card2);color:var(--ink2)">Matras</div></div>')
    focus = ('<div class="card row" style="padding:14px 16px;gap:14px;align-items:center">'
             '<div class="gur" style="width:72px;height:72px;border-radius:22px;background:var(--kesriSoft);color:var(--kesriInk);display:flex;align-items:center;justify-content:center;font-size:44px;font-weight:600;flex:none">ਸ</div>'
             '<div class="col" style="flex:1;gap:3px"><div class="disp" style="font-size:22px;font-weight:700">ਸੱਸਾ</div>'
             '<div style="font-size:13px;color:var(--ink2)">sassa · the sound “s”</div>'
             '<div class="row" style="gap:8px;padding-top:4px"><div class="chip" style="background:var(--primary);color:var(--onPrimary);min-height:34px">'
             f'{ic("play", 14)} Hear it</div><div class="chip" style="background:var(--card2);color:var(--ink2);min-height:34px">Trace it</div></div></div></div>')
    body = header("ਪੈਂਤੀ ਅੱਖਰ", "The 35 letters of Gurmukhi", gur=True) + kid + focus + grid + \
        '<div style="font-size:12px;color:var(--muted);text-align:center;line-height:1.5">Learned so far: 12 of 35. No stars, no timer — a letter is learned when it is said back.</div>'
    return screen(body, pad_gap=12)


add("65-GurmukhiLetters", "Gurmukhi letters", s65())


# 66 — kantth (by heart)
def s66() -> str:
    def memo(g, r, hidden_idx: list[int], done: bool):
        words = g.split(" ")
        out = []
        for i, w in enumerate(words):
            if i in hidden_idx and not done:
                out.append('<span style="display:inline-block;min-width:44px;height:26px;border-radius:8px;background:var(--card2);vertical-align:middle;border:1.5px dashed var(--rule)"></span>')
            else:
                out.append(f'<span>{e(w)}</span>')
        mark = (f'<div style="width:22px;height:22px;border-radius:11px;background:var(--sage);color:#fff;display:flex;align-items:center;justify-content:center;flex:none">{ic("check", 13)}</div>'
                if done else '<div style="width:22px;height:22px;border-radius:11px;border:2px solid var(--kesri);flex:none"></div>')
        return (f'<div class="row" style="gap:12px;padding:12px 0;border-top:1px solid var(--rule);align-items:flex-start">{mark}'
                f'<div class="col" style="flex:1;gap:3px"><div class="gur" style="font-size:20px;line-height:1.7;display:flex;flex-wrap:wrap;gap:0 7px;align-items:center">{"".join(out)}</div>'
                f'<div style="font-size:12px;color:var(--muted)">{e(r)}</div></div></div>')
    rows = memo(*JAPJI[0], [], True) + memo(*JAPJI[1], [], True) + memo(*JAPJI[2], [2, 5], False) + memo(*JAPJI[3], [1, 3, 6], False)
    rows = rows.replace("border-top:1px solid var(--rule)", "", 1)
    prog = ('<div class="card col" style="padding:14px 16px;gap:8px">'
            '<div class="row" style="justify-content:space-between"><div class="col"><div class="eyebrow">Japji Sahib · Pauri 1</div>'
            '<div class="disp" style="font-size:20px;font-weight:700">2 of 4 lines by heart</div></div>'
            f'<div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk)">{ic("sparkle", 14)} Kids mode</div></div>'
            '<div style="height:8px;border-radius:4px;background:var(--card2);overflow:hidden"><div style="width:50%;height:100%;background:var(--kesri)"></div></div>'
            '<div style="font-size:12.5px;color:var(--ink2)">Words fade out a few at a time. Tap a gap to peek; say the line with none showing and it is yours.</div></div>')
    body = header("ਕੰਠ", "Learn by heart", gur=True) + prog + \
        f'<div class="card col" style="padding:2px 16px">{rows}</div>' + \
        '<div class="row" style="gap:10px"><div style="flex:1">' + secondary("Hear the line", "headphones", 52) + '</div><div style="flex:1">' + primary("Hide more words", None, kesri=True) + '</div></div>'
    return screen(body, pad_gap=12)


add("66-KantthMode", "By heart", s66())


# 67 — Sehaj Paath marker
def s67() -> str:
    marker = ('<div class="card col" style="padding:18px 16px;gap:10px;background:linear-gradient(135deg,var(--primary),#0E1533);color:#fff">'
              '<div style="font-size:12px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;opacity:.8">Sehaj Paath · where you are</div>'
              '<div class="row" style="gap:14px;align-items:flex-end"><div class="disp" style="font-size:54px;font-weight:700;line-height:1">342</div>'
              '<div class="col" style="padding-bottom:8px"><div style="font-size:14px;font-weight:600">Ang 342 · line 7</div><div style="font-size:12.5px;opacity:.8">of 1430 · Raag Gauree</div></div></div>'
              '<div style="height:6px;border-radius:3px;background:rgba(255,255,255,.18);overflow:hidden"><div style="width:24%;height:100%;background:#F2A24E"></div></div>'
              '<div style="font-size:12.5px;opacity:.85">Begun 12 August · about 4 Angs a day · at this pace, completing around 3 February</div></div>')
    move = ('<div class="card col" style="padding:14px 16px;gap:12px"><div class="eyebrow">Move the marker</div>'
            '<div class="row" style="gap:12px;justify-content:center">'
            '<div class="disp" style="width:52px;height:52px;border-radius:16px;background:var(--card2);display:flex;align-items:center;justify-content:center;font-size:24px">−</div>'
            '<div class="col" style="width:120px;align-items:center"><div class="disp" style="font-size:34px;font-weight:700;line-height:1">346</div><div style="font-size:12px;color:var(--muted)">Ang</div></div>'
            '<div class="disp" style="width:52px;height:52px;border-radius:16px;background:var(--card2);display:flex;align-items:center;justify-content:center;font-size:24px">+</div></div>'
            '<div class="row" style="gap:8px;justify-content:center"><div class="chip" style="background:var(--card2);color:var(--ink2)">Line 1</div><div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk)">Line 12</div><div class="chip" style="background:var(--card2);color:var(--ink2)">Last line</div></div>'
            + primary("Mark today’s reading", "book") + '</div>')
    hist = ('<div class="card col" style="padding:2px 16px">'
            + settings_row("Yesterday", "Ang 338 → 342", '<div style="font-size:13px;color:var(--muted);font-weight:600">4 Angs</div>', first=True)
            + settings_row("Saturday", "Ang 335 → 338", '<div style="font-size:13px;color:var(--muted);font-weight:600">3 Angs</div>')
            + '</div>')
    body = header("Sehaj Paath", "A marker, not the Saroop") + marker + move + hist + \
        note("Hazri does not carry the whole of Sri Guru Granth Sahib Ji. This is only where you are in yours. Moving it forward marks the day’s hazri.", "book")
    return screen(body, pad_gap=12)


add("67-SehajPath", "Sehaj Paath marker", s67())


# 68 — saakhis list
def s68() -> str:
    def item(kicker, title, mins):
        return (f'<div class="card row" style="padding:13px 14px;gap:12px"><div class="col" style="flex:1;gap:3px">'
                f'<div style="font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--teal)">{kicker}</div>'
                f'<div style="font-size:14.5px;font-weight:700;line-height:1.3">{e(title)}</div><div style="font-size:12px;color:var(--muted)">{mins} min · read or listen</div></div>'
                '<div style="width:52px;height:52px;border-radius:13px;flex:none;background:linear-gradient(135deg,var(--primary),#0E1533)"></div></div>')
    lead = ('<div class="card col" style="padding:14px;gap:11px">' + abstract_art(120) +
            '<div class="col" style="gap:4px"><div style="font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--teal)">This week’s saakhi</div>'
            '<div class="disp" style="font-size:18px;font-weight:700;line-height:1.25">[Title from hazri.app]</div>'
            + bars([100, 92, 64], h=8) + '</div>'
            '<div class="row" style="gap:8px"><div class="chip" style="background:var(--primary);color:var(--onPrimary)">'
            f'{ic("play", 14)} Listen · 6 min</div><div style="font-size:12px;color:var(--muted);font-weight:600">Read · 4 min</div></div></div>')
    body = header("ਸਾਖੀਆਂ", "Stories from Sikh history", gur=True) + \
        '<div class="row" style="gap:7px;flex-wrap:wrap"><div class="chip" style="min-height:34px;background:var(--kesriSoft);color:var(--kesriInk)">All</div><div class="chip" style="min-height:34px;background:var(--card2);color:var(--ink2)">For children</div><div class="chip" style="min-height:34px;background:var(--card2);color:var(--ink2)">Gurpurab</div><div class="chip" style="min-height:34px;background:var(--card2);color:var(--ink2)">Sewa</div></div>' + \
        lead + '<div class="eyebrow" style="padding-top:2px">More</div>' + \
        item("Guru Nanak Dev Ji", "[Title from hazri.app]", 5) + item("Sewa", "[Title from hazri.app]", 3) + \
        note("Every saakhi is written and checked on hazri.app. The pictures are patterns, never a likeness of a Guru Sahiban.", "eye")
    return screen(body, pad_gap=12)


add("68-Saakhis", "Saakhis", s68())


# 69 — a saakhi, reading
def s69() -> str:
    body = header("Saakhi", "For children · 4 min", trailing=iconbtn("share")) + abstract_art(150) + \
        '<div class="col" style="gap:6px"><div style="font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--teal)">Guru Nanak Dev Ji</div>' \
        '<div class="disp" style="font-size:24px;font-weight:700;line-height:1.2">[Title from hazri.app]</div></div>' + \
        '<div class="card row" style="padding:10px 14px;gap:12px"><div style="width:40px;height:40px;border-radius:20px;background:var(--kesri);color:#fff;display:flex;align-items:center;justify-content:center;flex:none">' + ic("play", 18) + '</div>' \
        '<div class="col" style="flex:1;gap:5px"><div style="font-size:13px;font-weight:600">Read aloud · 6 min</div><div style="height:4px;border-radius:2px;background:var(--card2)"><div style="width:0%;height:100%;background:var(--kesri)"></div></div></div>' \
        '<div style="font-size:12px;color:var(--muted);font-weight:600">A person’s voice</div></div>' + \
        bars([100, 96, 88, 100, 72], h=10, gap=10) + bars([100, 94, 100, 60], h=10, gap=10) + \
        '<div class="card col" style="padding:12px 14px;gap:4px;background:var(--kesriSoft);box-shadow:none"><div style="font-size:12px;font-weight:700;color:var(--kesriInk)">What this teaches</div>' + \
        '<div class="bar" style="width:90%;background:rgba(154,79,0,.18)"></div></div>'
    return screen(body, pad_gap=12)


add("69-SaakhiReading", "A saakhi", s69())


# 70 — voices
def s70() -> str:
    def voice(name, banis, size, state, first=False):
        if state == "on":
            tr = f'<div style="width:22px;height:22px;border-radius:11px;background:var(--primary);display:flex;align-items:center;justify-content:center;color:var(--onPrimary)">{ic("check", 13)}</div>'
        elif state == "down":
            tr = '<div style="font-size:12.5px;font-weight:600;color:var(--kesriInk)">Download · ' + size + '</div>'
        else:
            tr = '<div style="width:22px;height:22px;border-radius:11px;border:2px solid var(--rule)"></div>'
        border = "" if first else "border-top:1px solid var(--rule);"
        return (f'<div class="row" style="gap:12px;padding:13px 0;{border}">'
                f'<div style="width:38px;height:38px;border-radius:19px;background:var(--kesriSoft);color:var(--kesriInk);display:flex;align-items:center;justify-content:center;flex:none">{ic("play", 16)}</div>'
                f'<div class="col" style="flex:1"><div style="font-size:14.5px;font-weight:600">{e(name)}</div><div style="font-size:12px;color:var(--muted)">{e(banis)}</div></div>{tr}</div>')
    card = ('<div class="card col" style="padding:2px 16px">'
            + voice("Voice 1", "All nine banis · on this phone", "", "on", True)
            + voice("Voice 2", "Japji, Rehras, Sohila · 41 MB", "41 MB", "down")
            + voice("Voice 3 · slower", "Japji Sahib · 24 MB", "24 MB", "down") + '</div>')
    credit = ('<div class="card col" style="padding:14px 16px;gap:6px"><div class="eyebrow">Who is reciting</div>'
              '<div style="font-size:13.5px;color:var(--ink2);line-height:1.5">Each paathi is named here once they have agreed to it, with a line about them. Until then the voice is simply a number.</div>'
              + bars([70, 40], h=8) + '</div>')
    body = header("Voice", "Who recites in Hazri") + card + \
        '<div class="card col" style="padding:2px 16px">' + settings_row("Pace", "1.0x · a speed you set here holds for every bani", '<div style="font-size:13px;color:var(--muted);font-weight:600">1.0x</div>', first=True) + \
        settings_row("Naam Simran", "Its own recitation, unchanged by this", chevron()) + '</div>' + credit + \
        note("Downloads happen once, on Wi-Fi unless you say otherwise. Every voice then plays with the radio off.", "headphones")
    return screen(body, pad_gap=12)


add("70-Voices", "More voices", s70())


# 71 — cast to TV
def s71() -> str:
    tv = ('<div style="border-radius:14px;background:#080B1C;padding:22px 18px;color:#EDECF6;aspect-ratio:16/9;display:flex;flex-direction:column;justify-content:center;gap:10px;position:relative;overflow:hidden">'
          '<div style="position:absolute;top:10px;left:14px;font-size:10px;font-weight:700;letter-spacing:.08em;color:#F2A24E">JAPJI SAHIB · PAURI 1</div>'
          f'<div class="gur" style="font-size:19px;line-height:1.55;color:#EDECF6">{e(JAPJI[2][0])}</div>'
          f'<div class="gur" style="font-size:19px;line-height:1.55;color:rgba(237,236,246,.45)">{e(JAPJI[3][0])}</div>'
          '<div style="position:absolute;bottom:10px;left:14px;right:14px;height:3px;border-radius:2px;background:rgba(255,255,255,.15)"><div style="width:9%;height:100%;background:#F2A24E"></div></div></div>')
    devices = ('<div class="card col" style="padding:2px 16px">'
               + settings_row("Living room TV", "Chromecast · connected", f'<div style="color:var(--sage)">{ic("check", 20)}</div>', first=True)
               + settings_row("Bedroom", "Android TV", chevron())
               + settings_row("This phone only", "Stop casting", chevron()) + '</div>')
    body = header("Cast", "Japji Sahib on the TV", trailing=iconbtn("cast", soft=True)) + \
        '<div class="card col" style="padding:12px;gap:10px">' + tv + \
        '<div style="font-size:12.5px;color:var(--ink2);line-height:1.5">The TV shows the line being recited, large, in the script you chose. The phone stays the remote: play, pause, and the line list.</div></div>' + \
        '<div class="eyebrow">Cast to</div>' + devices + \
        '<div class="row" style="gap:10px"><div style="flex:1">' + secondary("Previous line", None, 48) + '</div>' + \
        '<div style="width:52px;height:48px;border-radius:16px;background:var(--kesri);color:#fff;display:flex;align-items:center;justify-content:center">' + ic("pause", 20) + '</div>' + \
        '<div style="flex:1">' + secondary("Next line", None, 48) + '</div></div>'
    return screen(body, pad_gap=12)


add("71-CastToTV", "Cast to TV", s71())


# 72 — live kirtan
def s72() -> str:
    live = ('<div class="card col" style="padding:16px;gap:12px;background:linear-gradient(160deg,#0E1533,#080B1C);color:#EDECF6;box-shadow:none">'
            '<div class="row" style="gap:8px"><div class="chip" style="background:#B8560A;color:#fff;min-height:26px;padding:3px 10px;font-size:11.5px">● LIVE</div><div style="font-size:12.5px;color:rgba(237,236,246,.7)">Sri Harmandir Sahib · Asa di Vaar</div></div>'
            '<div class="disp" style="font-size:22px;font-weight:700;line-height:1.2">Kirtan from Sri Darbar Sahib</div>'
            '<div style="font-size:12.5px;color:rgba(237,236,246,.7)">Audio only · 4:12 AM in Amritsar · 1,204 listening in Hazri</div>'
            '<div class="row" style="gap:14px;padding-top:4px;align-items:center">'
            f'<div style="width:54px;height:54px;border-radius:27px;background:#F2A24E;color:#1C1206;display:flex;align-items:center;justify-content:center">{ic("pause", 24)}</div>'
            '<div class="col" style="flex:1;gap:6px"><div class="row" style="gap:2px;height:22px;align-items:center">'
            + "".join(f'<div style="width:3px;border-radius:2px;background:rgba(242,162,78,{a});height:{h}px"></div>' for h, a in zip([6, 12, 20, 16, 8, 14, 22, 18, 10, 6, 12, 20, 24, 16, 8, 10, 18, 22, 14, 6, 10, 16, 20, 12, 8, 14, 20, 16, 10, 6, 12, 18, 22, 14, 8, 6, 12, 16, 10, 6], [".9", ".8", ".9", ".7", ".6", ".8", ".9", ".8", ".6", ".5"] * 4))
            + '</div><div style="font-size:11.5px;color:rgba(237,236,246,.6)">Streaming · 64 kbps · pauses if the signal drops</div></div></div></div>')
    perm = ('<div class="card row" style="padding:12px 14px;gap:10px;background:var(--sageSoft);box-shadow:none">'
            f'<div style="color:var(--sage);flex:none">{ic("check", 18)}</div>'
            '<div style="font-size:12.5px;color:var(--sage);line-height:1.5">Carried with the written permission of the SGPC. Hazri adds nothing to it — no voice-over, no advertisement, ever.</div></div>')
    sched = ('<div class="col" style="gap:8px"><div class="eyebrow">Today, in your time</div><div class="card col" style="padding:2px 16px">'
             + settings_row("Asa di Vaar", "Live now", '<div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk);min-height:26px;padding:3px 10px;font-size:11.5px">Live</div>', first=True)
             + settings_row("Rehras Sahib", "6:38 PM · remind me", toggle(True))
             + settings_row("Kirtan Sohila", "10:05 PM", toggle(False)) + '</div></div>')
    body = header("Live Kirtan", "From Sri Harmandir Sahib") + live + perm + sched + \
        note("Live audio is the one thing on this screen that needs a connection. Your banis and their recitations never do.", "globe")
    return screen(body, pad_gap=12)


add("72-LiveKirtan", "Live Kirtan", s72())


# 73 — report an error
def s73() -> str:
    g, r = JAPJI[2]
    line = ('<div class="card col" style="padding:14px 16px;gap:6px"><div class="eyebrow">Japji Sahib · line 5</div>'
            f'{gur_line(g, size=21, weight=600)}<div style="font-size:12.5px;color:var(--muted)">{e(r)}</div></div>')
    def chip(label, on=False):
        return (f'<div class="chip" style="min-height:38px;padding:8px 14px;background:{"var(--kesriSoft)" if on else "var(--card2)"};color:{"var(--kesriInk)" if on else "var(--ink2)"}">{label}</div>')
    what = ('<div class="col" style="gap:8px"><div class="eyebrow">What is wrong?</div><div class="row" style="gap:8px;flex-wrap:wrap">'
            + chip("Spelling") + chip("Line break") + chip("Meaning") + chip("Audio timing", True) + chip("Pause mark") + chip("Something else") + '</div></div>')
    detail = ('<div class="card col" style="padding:12px 14px;gap:6px;min-height:86px"><div style="font-size:12px;color:var(--muted);font-weight:600">Anything more? (optional)</div>'
              '<div style="font-size:14px;color:var(--ink)">The highlight moves on before the paathi finishes ਹੋਵਈ.</div></div>')
    body = header("Report an error", "In the text or the audio") + line + what + detail + \
        note("This goes to the people who review the text, with the line and your note — nothing about you. If it is a mistake, the fix reaches every phone with the next update.", "flag") + \
        primary("Send", "flag")
    return screen(body, pad_gap=12)


add("73-ReportAnError", "Report an error", s73())


# 74 — ask a question
def s74() -> str:
    def chip(label, on=False):
        return (f'<div class="chip" style="min-height:34px;background:{"var(--kesriSoft)" if on else "var(--card2)"};color:{"var(--kesriInk)" if on else "var(--ink2)"}">{label}</div>')
    ask = ('<div class="card col" style="padding:14px 16px;gap:10px"><div style="font-size:14px;font-weight:700">Your question</div>'
           '<div style="min-height:88px;border-radius:12px;background:var(--card2);padding:10px 12px;font-size:14px;color:var(--muted)">Ask about a bani, a word, a practice, a date…</div>'
           '<div class="row" style="gap:7px;flex-wrap:wrap">' + chip("Nitnem", True) + chip("A word") + chip("Rehat") + chip("History") + '</div>'
           + primary("Send my question") + '</div>')
    prev = ('<div class="col" style="gap:8px"><div class="eyebrow">Earlier</div>'
            '<div class="card col" style="padding:14px 16px;gap:8px"><div class="row" style="justify-content:space-between"><div style="font-size:12px;color:var(--muted);font-weight:600">Asked 14 Nov</div>'
            '<div class="chip" style="background:var(--sageSoft);color:var(--sage);min-height:24px;padding:2px 9px;font-size:11px">Answered</div></div>'
            + bars([88, 52], h=8) +
            '<div style="height:1px;background:var(--rule)"></div><div style="font-size:12px;color:var(--muted);font-weight:600">Reply · a sewadar, 16 Nov</div>'
            + bars([100, 96, 70], h=8) + '</div></div>')
    body = header("Ask a question", "A person answers, not a machine") + ask + prev + \
        note("Replies come here, usually within a few days. Your question and the reply are kept on this phone and on the account you asked from; your name is not sent unless you have joined the sangat.", "help")
    return screen(body, pad_gap=12)


add("74-AskAQuestion", "Ask a question", s74())


# 75 — gurdwara connect
def s75() -> str:
    def g(name, place, km, times, follow):
        return (f'<div class="card col" style="padding:13px 14px;gap:8px"><div class="row" style="gap:12px">'
                f'<div class="col" style="flex:1;gap:2px"><div style="font-size:14.5px;font-weight:700;line-height:1.3">{e(name)}</div><div style="font-size:12px;color:var(--muted)">{e(place)} · {km}</div></div>'
                f'<div style="width:36px;height:36px;border-radius:12px;background:{"var(--kesriSoft)" if follow else "var(--card2)"};color:{"var(--kesriInk)" if follow else "var(--muted)"};display:flex;align-items:center;justify-content:center;flex:none">{ic("bell", 18)}</div></div>'
                f'<div class="row" style="gap:7px;flex-wrap:wrap">' + "".join(f'<div class="chip" style="background:var(--card2);color:var(--ink2);min-height:28px;padding:4px 10px;font-size:12px">{e(t)}</div>' for t in times) + '</div></div>')
    body = header("Gurdwaras", "Near you today", trailing=iconbtn("pin", soft=True)) + \
        '<div class="card row" style="padding:12px 14px;gap:10px;border:1px solid var(--rule)"><div style="color:var(--muted)">' + ic("pin", 18) + '</div><div style="font-size:14px;color:var(--ink2);flex:1">Connaught Place, New Delhi</div><div style="font-size:12.5px;color:var(--kesriInk);font-weight:600">Change</div></div>' + \
        g("Gurdwara Bangla Sahib", "Connaught Place", "1.2 km", ["Asa di Vaar 4:30 AM", "Rehras 6:38 PM", "Kirtan Sohila 9:45 PM"], True) + \
        g("Gurdwara Rakab Ganj Sahib", "Pandit Pant Marg", "2.4 km", ["Nitnem 5:00 AM", "Rehras 6:38 PM"], False) + \
        g("Gurdwara Sis Ganj Sahib", "Chandni Chowk", "5.1 km", ["Asa di Vaar 4:00 AM", "Kirtan 6:00 PM"], False) + \
        note("Times come from each gurdwara’s own committee and are shown as they publish them. Following one adds its programme to your reminders; nothing about you goes to the gurdwara.", "globe") + \
        '<div style="height:70px"></div>' + nav("Sangat")
    return screen(body, pad_gap=12)


add("75-GurdwaraConnect", "Gurdwara Connect", s75())


# 76 — gurdwara detail
def s76() -> str:
    now = ('<div class="chip" style="background:var(--kesriSoft);color:var(--kesriInk);'
           'min-height:24px;padding:2px 9px;font-size:11px">Now</div>')

    def slot(time, name, live=False):
        dot = ('<div style="width:10px;height:10px;border-radius:5px;background:var(--kesri);flex:none;box-shadow:0 0 0 4px var(--kesriSoft)"></div>'
               if live else '<div style="width:10px;height:10px;border-radius:5px;background:var(--rule);flex:none"></div>')
        return (f'<div class="row" style="gap:12px;padding:10px 0">{dot}<div style="font-size:13px;color:var(--muted);font-weight:600;width:70px;font-variant-numeric:tabular-nums">{time}</div>'
                f'<div style="font-size:14px;font-weight:{700 if live else 500};flex:1">{e(name)}</div>'
                f'{now if live else ""}</div>')
    prog = ('<div class="card col" style="padding:6px 16px">'
            + slot("4:30 AM", "Asa di Vaar") + slot("6:00 AM", "Hukamnama") + slot("6:38 PM", "Rehras Sahib", True) + slot("7:15 PM", "Kirtan") + slot("9:45 PM", "Kirtan Sohila · Sukhasan") + '</div>')
    body = header("Gurdwara Bangla Sahib", "Connaught Place, New Delhi") + abstract_art(110, 240) + \
        '<div class="row" style="gap:10px"><div style="flex:1">' + primary("Follow · remind me", "bell", kesri=True, h=48) + '</div><div style="width:48px;height:48px;border-radius:16px;background:var(--card2);color:var(--ink2);display:flex;align-items:center;justify-content:center">' + ic("route", 20) + '</div></div>' + \
        '<div class="eyebrow">Today’s programme</div>' + prog + \
        '<div class="card col" style="padding:2px 16px">' + settings_row("Langar", "Open all day", '<div style="font-size:13px;color:var(--muted);font-weight:600">Daily</div>', first=True) + \
        settings_row("Gurpurab programme", "Prakash Purab · 24 Nov · Akhand Paath begins 22 Nov", chevron()) + '</div>' + \
        note("Published by the gurdwara’s committee on hazri.app, corrected once and seen on every phone.", "eye")
    return screen(body, pad_gap=12)


add("76-GurdwaraDetail", "A gurdwara", s76())


# 77 — home-screen widgets (Android)
def s77() -> str:
    def widget(inner, h, cols=4):
        return f'<div style="grid-column:span {cols};height:{h}px;border-radius:22px;background:var(--card);box-shadow:var(--shadow);padding:14px 16px;overflow:hidden">{inner}</div>'
    small = ('<div class="col" style="height:100%;justify-content:space-between"><div class="row" style="gap:8px"><div style="width:30px;height:30px;border-radius:15px;background:var(--sageSoft);color:var(--sage);display:flex;align-items:center;justify-content:center">' + ic("check", 16) + '</div></div>'
             '<div class="col"><div style="font-size:12px;color:var(--muted);font-weight:600">Today</div><div class="disp" style="font-size:15px;font-weight:700;line-height:1.2">Hazri marked</div><div style="font-size:11.5px;color:var(--muted)">5:52 AM · Japji Sahib</div></div></div>')
    goals = ('<div class="col" style="height:100%;gap:6px"><div class="row" style="justify-content:space-between"><div style="font-size:12px;color:var(--muted);font-weight:600">Your goals</div><div style="font-size:12px;font-weight:700;color:var(--kesriInk)">1 of 3</div></div>'
             + "".join(f'<div class="row" style="gap:8px"><div style="width:16px;height:16px;border-radius:8px;background:{c};flex:none"></div><div style="font-size:13px;font-weight:600;flex:1">{n}</div><div style="font-size:11.5px;color:var(--muted)">{t}</div></div>'
                       for n, t, c in [("Japji Sahib", "done", "var(--sage)"), ("Simran", "11 min", "var(--rule)"), ("Rehras Sahib", "6:40 PM", "var(--rule)")]) + '</div>')
    quote = ('<div class="col" style="height:100%;justify-content:space-between"><div style="font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--kesriInk)">ਅੱਜ ਦਾ ਵਿਚਾਰ</div>'
             f'<div class="gur" style="font-size:16px;line-height:1.5">{e(VICHAR_LINE[0])}</div><div style="font-size:12px;color:var(--ink2);line-height:1.4">{e(VICHAR_LINE[1])}</div></div>')
    simran = ('<div class="col" style="height:100%;justify-content:space-between;align-items:center"><div style="font-size:11.5px;color:var(--muted);font-weight:600">Simran</div>'
              f'<div class="gur" style="font-size:20px;font-weight:600;color:var(--kesriInk)">{WAHEGURU}</div><div style="width:44px;height:44px;border-radius:22px;background:var(--kesri);color:#fff;display:flex;align-items:center;justify-content:center">{ic("play", 20)}</div></div>')
    grid = (f'<div style="display:grid;grid-template-columns:repeat(4,1fr);gap:12px">{widget(small, 150, 2)}{widget(simran, 150, 2)}{widget(goals, 132, 4)}{widget(quote, 132, 4)}</div>')
    dock = ('<div style="position:absolute;left:20px;right:20px;bottom:24px;height:72px;border-radius:26px;background:rgba(255,255,255,.35);backdrop-filter:blur(8px);display:flex;align-items:center;justify-content:space-around;padding:0 10px">'
            + "".join('<div style="width:50px;height:50px;border-radius:16px;background:var(--card);opacity:.85"></div>' for _ in range(4)) + '</div>')
    return ('<div style="position:absolute;inset:0;background:linear-gradient(160deg,#F4E6D2,#D9C8E8 60%,#B9C7E6)"></div>'
            f'<div style="position:absolute;top:14px;left:0;right:0;display:flex;justify-content:space-between;padding:0 22px;font-size:12px;font-weight:600;color:#1B1D3A">5:52<span>▲ ▮ 81%</span></div>'
            f'<div style="position:absolute;top:44px;left:18px;right:18px;font-size:11.5px;font-weight:700;color:#1B1D3A;opacity:.6;letter-spacing:.08em;text-transform:uppercase">Home screen · Android</div>'
            f'<div style="position:absolute;top:70px;left:18px;right:18px">{grid}</div>{dock}')


SCREENS["77-Widgets"] = ("Home-screen widgets", s77())


# 78 — watch simran
def s78() -> str:
    face = ('<div style="width:300px;height:300px;border-radius:150px;background:#080B1C;box-shadow:0 30px 60px rgba(0,0,0,.45),inset 0 0 0 10px #1B1D3A;position:relative;display:flex;align-items:center;justify-content:center;color:#EDECF6">'
            '<svg width="300" height="300" viewBox="0 0 300 300" style="position:absolute;inset:0"><circle cx="150" cy="150" r="128" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="8"/>'
            '<circle cx="150" cy="150" r="128" fill="none" stroke="#F2A24E" stroke-width="8" stroke-linecap="round" stroke-dasharray="402 804" transform="rotate(-90 150 150)"/></svg>'
            '<div class="col" style="align-items:center;gap:6px;position:relative">'
            '<div style="font-size:11px;font-weight:700;letter-spacing:.1em;color:rgba(237,236,246,.55)">SIMRAN · 6:12 LEFT</div>'
            f'<div class="gur" style="font-size:30px;font-weight:600;color:#F2A24E">{WAHEGURU}</div>'
            '<div class="disp" style="font-size:64px;font-weight:700;line-height:1;font-variant-numeric:tabular-nums">108</div>'
            '<div style="font-size:12px;color:rgba(237,236,246,.6)">tap anywhere · one count</div></div>'
            '<div style="position:absolute;bottom:26px;width:64px;height:30px;border-radius:15px;background:rgba(255,255,255,.1);display:flex;align-items:center;justify-content:center;color:#EDECF6">' + ic("pause", 16) + '</div></div>')
    strap = '<div style="width:110px;height:120px;border-radius:0 0 40px 40px;background:#1B1D3A;margin-top:-24px;opacity:.9"></div>'
    strap_top = '<div style="width:110px;height:120px;border-radius:40px 40px 0 0;background:#1B1D3A;margin-bottom:-24px;opacity:.9"></div>'
    body = header("Simran on your wrist", "Wear OS · Apple Watch after iOS") + \
        f'<div class="col" style="align-items:center;padding:6px 0 0">{strap_top}{face}{strap}</div>' + \
        note("Each tap is one count, with a light buzz. The count and the minutes reach the phone when they next meet, and the sitting is logged there as hazri.", "watch")
    return screen(body, pad_gap=10)


add("78-WatchSimran", "Simran on the wrist", s78())


# 79 — iPhone Today
def s79() -> str:
    island = '<div style="position:absolute;top:11px;left:50%;transform:translateX(-50%);width:120px;height:34px;border-radius:17px;background:#000"></div>'
    status = '<div style="position:absolute;top:16px;left:0;right:0;display:flex;justify-content:space-between;padding:0 30px;font-size:15px;font-weight:600;color:var(--ink)"><span>5:52</span><span style="font-size:12px">●●● ▲ ▮▮▮</span></div>'
    home = '<div style="position:absolute;bottom:8px;left:50%;transform:translateX(-50%);width:134px;height:5px;border-radius:3px;background:var(--ink);opacity:.6"></div>'
    hazri = ('<div class="card row" style="padding:13px 14px;gap:12px;background:var(--sageSoft);box-shadow:none">'
             f'<div style="width:38px;height:38px;border-radius:19px;background:rgba(46,122,87,.18);color:var(--sage);display:flex;align-items:center;justify-content:center;flex:none">{ic("check", 20)}</div>'
             '<div class="col" style="flex:1"><div style="font-size:14.5px;font-weight:700;color:var(--sage)">Today’s hazri is marked</div><div style="font-size:12px;color:var(--ink2)">Marked at 5:52 AM, with Japji Sahib</div></div></div>')
    goals = ('<div class="card col" style="padding:16px;gap:12px"><div class="row" style="justify-content:space-between"><div class="col" style="gap:0px"><div class="eyebrow">Your goals</div><div class="disp" style="font-size:20px;font-weight:700;line-height:1.15">1 of 3 done</div></div>'
             '<div style="position:relative;width:56px;height:56px"><svg width="56" height="56" viewBox="0 0 56 56" style="display:block;transform:rotate(-90deg)"><circle cx="28" cy="28" r="24.5" fill="none" stroke="var(--rule)" stroke-width="7"/><circle cx="28" cy="28" r="24.5" fill="none" stroke="var(--kesri)" stroke-width="7" stroke-linecap="round" stroke-dasharray="51 154"/></svg><div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700">33%</div></div></div>'
             '<div class="col" style="gap:9px;border-top:1px solid var(--rule);padding-top:11px">'
             + "".join(f'<div class="row" style="gap:10px"><div style="width:26px;height:26px;border-radius:13px;background:{c};flex:none"></div><div style="font-size:13.5px;font-weight:600;flex:1">{n}</div><div style="font-size:12.5px;color:var(--muted);font-weight:600">{t}</div></div>'
                       for n, t, c in [("Japji Sahib", "done", "var(--sage)"), ("Simran", "11 min", "var(--rule)"), ("Rehras Sahib", "6:40 PM", "var(--rule)")]) + '</div></div>')
    body = ('<div class="pad col" style="gap:13px;padding-top:62px">' + header("Today", "Friday, 20 November", back=False) + hazri + goals + primary("Start Nitnem", "book") +
            '<div class="card row" style="padding:14px;gap:12px"><div style="width:46px;height:46px;border-radius:14px;background:var(--kesriSoft);color:var(--kesriInk);display:flex;align-items:center;justify-content:center;flex:none">' + ic("calendar", 22) + '</div>'
            '<div class="col" style="flex:1;gap:0px"><div style="font-size:12px;color:var(--muted);font-weight:700">IN 4 DAYS · GURPURAB</div><div style="font-size:14px;font-weight:700;line-height:1.15">Prakash Purab, Guru Nanak Dev Ji</div><div class="gur" style="font-size:12.5px;color:var(--muted)">9 ਮੱਘਰ 558</div></div></div>'
            + note("Same app, same design. iOS adds swipe-back from the left edge, its own date and time wheels, and safe areas around the island and the home bar.", "eye") + '</div>')
    ios_nav = nav("Today").replace("padding:10px 4px 22px", "padding:10px 4px 30px")
    return island + status + body + ios_nav + home


add("79-iPhoneToday", "Today on iPhone", s79())


# 80 — iOS reminder time (Cupertino wheel)
def s80() -> str:
    def wheel(items, sel):
        rows = "".join(f'<div style="height:34px;display:flex;align-items:center;justify-content:center;font-size:{22 if i == sel else 18}px;font-weight:{600 if i == sel else 400};color:{"var(--ink)" if i == sel else "var(--muted)"};opacity:{1 if i == sel else (0.7 if abs(i - sel) == 1 else 0.4)}">{v}</div>' for i, v in enumerate(items))
        return f'<div class="col" style="flex:1;align-items:stretch">{rows}</div>'
    sheet = ('<div style="position:absolute;left:0;right:0;bottom:0;background:var(--card);border-radius:28px 28px 0 0;padding:14px 20px 34px;box-shadow:0 -10px 40px rgba(0,0,0,.18)">'
             '<div style="width:40px;height:4px;border-radius:2px;background:var(--rule);margin:0 auto 14px"></div>'
             '<div class="disp" style="font-size:22px;font-weight:700">Rehras Sahib reminder</div>'
             '<div class="row" style="gap:2px;padding:3px;border-radius:12px;background:var(--card2);margin-top:12px"><div style="flex:1;padding:8px;border-radius:9px;text-align:center;font-size:13px;font-weight:600;color:var(--muted)">Auto · at sunset</div><div style="flex:1;padding:8px;border-radius:9px;text-align:center;font-size:13px;font-weight:600;background:var(--card);box-shadow:var(--shadow)">My time</div></div>'
             '<div style="position:relative;margin-top:12px;height:170px;overflow:hidden"><div style="position:absolute;left:0;right:0;top:68px;height:34px;border-radius:10px;background:var(--card2)"></div>'
             '<div class="row" style="position:relative;align-items:flex-start">' + wheel(["4", "5", "6", "7", "8"], 2) + wheel(["30", "35", "40", "45", "50"], 2) + wheel(["", "AM", "PM", "", ""], 2) + '</div></div>'
             '<div style="font-size:12px;color:var(--muted);text-align:center;margin-top:4px">The wheel is iOS’s own — the same control the Clock app uses.</div>'
             '<div class="row" style="gap:6px;justify-content:center;margin-top:14px">' + "".join(f'<div style="width:36px;height:36px;border-radius:18px;background:{"var(--primary)" if on else "var(--card2)"};color:{"var(--onPrimary)" if on else "var(--ink2)"};display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700">{d}</div>' for d, on in [("M", 1), ("T", 1), ("W", 1), ("T", 1), ("F", 1), ("S", 1), ("S", 0)]) + '</div>'
             '<div style="margin-top:14px">' + primary("Save") + '</div>'
             '<div style="text-align:center;font-size:14px;font-weight:600;color:var(--muted);margin-top:12px">Turn off this reminder</div></div>')
    behind = ('<div class="pad col" style="gap:13px;padding-top:62px;opacity:.5">' + header("Notifications", None) +
              '<div class="card col" style="padding:2px 16px">' + settings_row("Nitnem reminders", "At your goal times", toggle(True), first=True) + settings_row("Simran reminder", "5:15 AM", toggle(True)) + '</div></div>')
    island = '<div style="position:absolute;top:11px;left:50%;transform:translateX(-50%);width:120px;height:34px;border-radius:17px;background:#000"></div>'
    status = '<div style="position:absolute;top:16px;left:0;right:0;display:flex;justify-content:space-between;padding:0 30px;font-size:15px;font-weight:600;color:var(--ink)"><span>6:12</span><span style="font-size:12px">●●● ▲ ▮▮▮</span></div>'
    scrim = '<div style="position:absolute;inset:0;background:var(--scrim)"></div>'
    home = '<div style="position:absolute;bottom:8px;left:50%;transform:translateX(-50%);width:134px;height:5px;border-radius:3px;background:var(--ink);opacity:.6"></div>'
    return island + status + behind + scrim + sheet + home


add("80-iOSReminderTime", "Reminder time on iPhone", s80())


# 81 — privacy, Phase 3
def s81() -> str:
    def sect(title, icon, items, colour="var(--ink2)"):
        li = "".join(f'<div class="row" style="gap:10px;align-items:flex-start"><div style="width:6px;height:6px;border-radius:3px;background:var(--kesri);margin-top:8px;flex:none"></div><div style="font-size:13.5px;color:{colour};line-height:1.5">{e(t)}</div></div>' for t in items)
        return (f'<div class="card col" style="padding:14px 16px;gap:8px"><div class="row" style="gap:10px"><div style="color:var(--kesriInk)">{ic(icon, 18)}</div><div style="font-size:12px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)">{title}</div></div>{li}</div>')
    analytics = ('<div class="card col" style="padding:14px 16px;gap:10px"><div class="row" style="gap:10px"><div style="color:var(--kesriInk)">' + ic("eye", 18) + '</div>'
                 '<div style="font-size:12px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--muted);flex:1">Analytics & crash reports</div>' + toggle(True, colour="var(--primary)") + '</div>'
                 '<div style="font-size:13.5px;color:var(--ink2);line-height:1.5">New in this version, and on by default. Which screens are opened and which bani was finished, as counts — never what you read, never your name, never a word you typed. A crash sends what went wrong in the app, nothing about you.</div>'
                 '<div style="font-size:12.5px;color:var(--muted)">Switch it off and both stop at once. The app does not change.</div></div>')
    body = header("Privacy & my data", "What leaves this phone") + \
        sect("On this phone only", "lock", ["Your diary and streaks", "Reading position and goals", "Every bani, recitation and the calendar"]) + \
        sect("Shared with the sangat, if you joined", "sangat", ["Your name and city", "How much you have completed towards a shared goal"]) + \
        sect("Held for your account", "globe", ["Your email, never shown to anybody else"]) + analytics + \
        '<div class="row" style="gap:10px"><div style="flex:1">' + secondary("Download my data", "share", 46) + '</div><div style="flex:1">' + secondary("Delete my account", None, 46).replace("color:var(--ink2)", "color:#B3261E") + '</div></div>'
    return screen(body, pad_gap=12)


add("81-PrivacyPhase3", "Privacy, Phase 3", s81())


# 82 — first-launch consent (EEA / UK)
def s82() -> str:
    body = ('<div class="pad col" style="gap:16px;height:844px;justify-content:center;padding-bottom:40px">'
            '<div style="width:64px;height:64px;border-radius:22px;background:var(--kesriSoft);color:var(--kesriInk);display:flex;align-items:center;justify-content:center;margin:0 auto">' + ic("eye", 30) + '</div>'
            '<div class="disp" style="font-size:28px;font-weight:700;line-height:1.15;text-align:center">Help improve Hazri?</div>'
            '<div style="font-size:15px;color:var(--ink2);line-height:1.55;text-align:center">Hazri can count which screens are opened and which banis are finished, and tell us when it crashes. Only counts — never what you read, your name, or anything you type. No advertising, ever.</div>'
            '<div class="card col" style="padding:4px 16px">' + settings_row("What is sent", "Screen names, bani finished, app version", chevron(), first=True) + settings_row("What is never sent", "Your diary, your words, your identity", chevron()) + '</div>'
            + primary("Yes, count me") + secondary("No thanks", None, 52) +
            '<div style="font-size:12px;color:var(--muted);text-align:center;line-height:1.5">Asked once because you are in the EEA or UK. Change it any time under Privacy &amp; my data.</div></div>')
    return body


add("82-FirstLaunchConsent", "Consent, first launch", s82())


# 83 — milestones (3.13, quietly)
def s83() -> str:
    def m(title, sub, when, done):
        mark = (f'<div style="width:40px;height:40px;border-radius:14px;background:var(--kesriSoft);color:var(--kesriInk);display:flex;align-items:center;justify-content:center;flex:none">{ic("sun", 20)}</div>'
                if done else '<div style="width:40px;height:40px;border-radius:14px;background:var(--card2);color:var(--muted);display:flex;align-items:center;justify-content:center;flex:none">' + ic("sun", 20) + '</div>')
        return (f'<div class="row" style="gap:12px;padding:12px 0;border-top:1px solid var(--rule)">{mark}<div class="col" style="flex:1"><div style="font-size:14.5px;font-weight:600;color:{"var(--ink)" if done else "var(--muted)"}">{e(title)}</div><div style="font-size:12px;color:var(--muted)">{e(sub)}</div></div><div style="font-size:12px;color:var(--muted);font-weight:600">{when}</div></div>')
    rows = (m("Forty days of hazri", "Turned up forty days in a row", "12 Nov", True) + m("First Sukhmani Sahib", "Read to the end in the app", "3 Oct", True)
            + m("A year of Japji Sahib", "365 mornings", "—", False) + m("Ten sittings of simran", "Any length", "18 Sep", True)).replace("border-top:1px solid var(--rule)", "", 1)
    body = header("Milestones", "Things that happened, written down") + \
        '<div class="card col" style="padding:18px 16px;gap:6px;background:linear-gradient(135deg,var(--kesri),#B8560A);color:#fff"><div style="font-size:12px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;opacity:.85">Most recent</div><div class="disp" style="font-size:24px;font-weight:700;line-height:1.15">Forty days of hazri</div><div style="font-size:13px;opacity:.9">12 November · A gentle streak, with two grace days along the way.</div></div>' + \
        f'<div class="card col" style="padding:2px 16px">{rows}</div>' + \
        note("No points, no ranks, nothing to share by default. A milestone is a date the diary already knows, said once in words.", "book")
    return screen(body, pad_gap=12)


add("83-Milestones", "Milestones", s83())


# 84 — a tapped invite link
def s84() -> str:
    body = ('<div class="pad col" style="gap:16px;height:844px;justify-content:center;padding-bottom:40px">'
            '<div style="width:72px;height:72px;border-radius:36px;background:var(--kesriSoft);color:var(--kesriInk);display:flex;align-items:center;justify-content:center;margin:0 auto">' + ic("sangat", 32) + '</div>'
            '<div class="col" style="gap:4px;align-items:center"><div style="font-size:12px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;color:var(--muted)">You were invited to</div>'
            '<div class="disp" style="font-size:28px;font-weight:700;line-height:1.15;text-align:center">Nanda family</div>'
            '<div style="font-size:14px;color:var(--ink2)">by Harjit Singh · 12 members · private</div></div>'
            '<div class="card col" style="padding:14px 16px;gap:8px"><div class="eyebrow">Shared goal</div><div style="font-size:15px;font-weight:700">Sukhmani Sahib · 108 paath by 24 November</div>'
            '<div style="height:8px;border-radius:4px;background:var(--card2);overflow:hidden"><div style="width:61%;height:100%;background:var(--kesri)"></div></div><div style="font-size:12.5px;color:var(--muted)">66 of 108 so far</div></div>'
            + note("Joining shares your name and city with this group, and what you complete towards its goal. Nothing else.", "lock")
            + primary("Join Nanda family", "sangat", kesri=True) + secondary("Not now", None, 52) +
            '<div style="font-size:12px;color:var(--muted);text-align:center;line-height:1.5">The link opened straight into the app — hazri.app/j/nanda-7k2m. Nothing to paste.</div></div>')
    return body


add("84-TappedInvite", "An invite, tapped", s84())


# ---------------------------------------------------------------- write
def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for id_, (title, body) in SCREENS.items():
        for theme in ("light", "dark"):
            page = HEAD.format(title=title, theme=theme) + body + FOOT
            (OUT / f"{id_}.{theme}.html").write_text(page, encoding="utf-8")
    print(f"wrote {len(SCREENS) * 2} files to {OUT}")


if __name__ == "__main__":
    main()
