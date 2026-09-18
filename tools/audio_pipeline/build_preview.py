#!/usr/bin/env python3
"""Builds a single-file timing preview you can open in a browser.

Checking an alignment should not cost a fifteen-minute CI build and an APK
install. This bakes every bani's line text and timings into one HTML file; you
point it at a recitation already on your own disk and it highlights the line
the timings claim is being said, with the exact start time next to it.

The audio never leaves your machine -- the page reads it through a file picker,
not a network request, which is the same rule the app itself keeps.

    python3 tools/audio_pipeline/build_preview.py [-o out.html]
"""
import argparse
import json
import os
import sqlite3
import statistics

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DB = os.path.join(ROOT, "assets", "content", "content.db")
TIMINGS = os.path.join(ROOT, "content", "source", "timings")

SEP = "\x1f"


def collect() -> list[dict]:
    con = sqlite3.connect(DB)
    banis = []
    for slug, name_en, name_pa in con.execute(
        "SELECT b.slug, b.name_en, b.name_pa FROM bani b ORDER BY b.sort"
    ):
        path = os.path.join(TIMINGS, f"{slug}.json")
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as fh:
            doc = json.load(fh)
        text = dict(
            con.execute(
                "SELECT l.idx, l.gurmukhi || ? || COALESCE(l.roman, '') "
                "FROM line l JOIN bani_version v ON v.id = l.bani_version_id "
                "JOIN bani b2 ON b2.id = v.bani_id WHERE b2.slug = ?",
                (SEP, slug),
            )
        )
        # One row per sung pass, so a line the reciter repeats appears twice,
        # exactly as the reader shows it.
        rows = [
            [line["line"], line["s"], line["e"]]
            + text.get(line["line"], "?" + SEP).split(SEP)
            for line in doc["lines"]
        ]
        # How far each line's pace is from this reciter's own median. Both
        # faults found by ear in Sukhmani's tail -- the two saloks arriving
        # four and five seconds late -- sat on lines flagged here, so the
        # numbers are worth showing rather than keeping in a separate tool.
        paces = [
            (line["e"] - line["s"]) / len(line["w"])
            for line in doc["lines"] if line["w"]
        ]
        median = statistics.median(paces) if paces else 0.0
        for row, line in zip(rows, doc["lines"]):
            pace = ((line["e"] - line["s"]) / len(line["w"]) / median
                    if line["w"] and median else 1.0)
            row.append(round(pace, 2))
        banis.append(
            {
                "slug": slug,
                "name": f"{name_en}  {name_pa}",
                "durationMs": doc["durationMs"],
                "pinned": doc.get("pinnedLines") or [],
                "held": doc.get("heldLines") or [],
                "verified": bool(doc.get("verified")),
                "median": round(median),
                "rows": rows,
            }
        )
    return banis


CSS = """
:root{--bg:#faf7f2;--card:#fff;--ink:#231d16;--muted:#7c6f60;--line:#e7ddcf;
--accent:#a8641b;--accent-soft:#fdf1e0;--warn:#9a3412;
--shadow:0 1px 2px rgba(35,29,22,.06)}
@media(prefers-color-scheme:dark){:root:not([data-theme=light]){--bg:#14110d;
--card:#1d1813;--ink:#f0e8dc;--muted:#a2927f;--line:#332b22;--accent:#e0a463;
--accent-soft:#2b2015;--warn:#f0a882;--shadow:none}}
:root[data-theme=dark]{--bg:#14110d;--card:#1d1813;--ink:#f0e8dc;--muted:#a2927f;
--line:#332b22;--accent:#e0a463;--accent-soft:#2b2015;--warn:#f0a882;
--shadow:none}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--ink);font:15px/1.5 -apple-system,
BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
.wrap{max-width:860px;margin:0 auto;padding:24px 16px 64px}
h1{font-size:19px;margin:0 0 2px;letter-spacing:-.01em}
.sub{color:var(--muted);font-size:13px;margin:0 0 20px}
.panel{background:var(--card);border:1px solid var(--line);border-radius:14px;
padding:14px;margin-bottom:14px;box-shadow:var(--shadow)}
.row{display:flex;gap:10px;align-items:center;flex-wrap:wrap}
select,input[type=text],button{font:inherit;color:inherit;background:var(--bg);
border:1px solid var(--line);border-radius:9px;padding:8px 11px}
button{cursor:pointer}button:hover{border-color:var(--accent)}
input[type=file]{font:inherit;color:var(--muted);max-width:100%}
.now{font-variant-numeric:tabular-nums;font-size:26px;letter-spacing:-.02em}
.tag{font-size:11px;color:var(--muted);border:1px solid var(--line);
border-radius:999px;padding:2px 8px}
.tag.on{color:var(--accent);border-color:var(--accent)}
#seek{width:100%;accent-color:var(--accent);margin:12px 0 2px}
.cur{background:var(--accent-soft);border:1px solid var(--accent);
border-radius:14px;padding:16px;margin-bottom:14px}
.cur .gm{font-size:24px;line-height:1.7}
.cur .rm{color:var(--muted);font-size:13px;margin-top:6px}
.cur .meta{font-variant-numeric:tabular-nums;color:var(--accent);font-size:12px;
margin-bottom:8px}
ol{list-style:none;margin:0;padding:0;max-height:52vh;overflow:auto}
li{display:grid;grid-template-columns:66px 1fr;gap:12px;padding:7px 10px;
border-radius:9px;cursor:pointer;align-items:baseline}
li:hover{background:var(--accent-soft)}
li.on{background:var(--accent-soft);box-shadow:inset 2px 0 0 var(--accent)}
li .t{font-variant-numeric:tabular-nums;color:var(--muted);font-size:12px}
li .gm{font-size:16px;line-height:1.65}
li .rm{color:var(--muted);font-size:11.5px}
li.odd .t{color:var(--warn);font-weight:600}
li.odd .t::after{content:" ◆";font-size:9px;vertical-align:1px}
.hint{color:var(--muted);font-size:12.5px;margin:10px 2px 0}
kbd{border:1px solid var(--line);border-radius:5px;padding:1px 5px;font-size:11px}
@media(max-width:520px){li{grid-template-columns:58px 1fr}.cur .gm{font-size:20px}}
"""

JS = r"""
const B = window.__BANIS__;
const $ = s => document.querySelector(s);
const sel = $('#bani'), list = $('#lines'), seek = $('#seek'), audio = $('#a');
let cur = B[0], rows = [], at = -1;

const fmt = ms => {
  const t = Math.max(0, ms) / 1000, h = Math.floor(t / 3600);
  const m = Math.floor(t / 60) % 60, s = t % 60;
  return (h ? h + ':' + String(m).padStart(2, '0') : m) + ':' +
         s.toFixed(2).padStart(5, '0');
};
const parse = v => {
  const p = v.trim().split(':').map(Number);
  if (!p.length || p.some(isNaN)) return null;
  return p.reduce((a, n) => a * 60 + n, 0);
};

B.forEach((b, i) => sel.add(new Option(b.name + ' — ' + b.slug, i)));

function esc(s) {
  return s.replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' })[c]);
}

// A line whose pace is far from this reciter's median. The warp must account
// for every frame it is given, so where it loses its place it stretches one
// line and squeezes the next rather than reporting anything -- which is what
// both Sukhmani saloks looked like before anybody heard them.
const ODD_FAST = 0.5, ODD_SLOW = 2.0;
const isOdd = r => r[5] < ODD_FAST || r[5] > ODD_SLOW;

function draw() {
  rows = cur.rows;
  list.innerHTML = '';
  const f = document.createDocumentFragment();
  rows.forEach(r => {
    const li = document.createElement('li');
    li.innerHTML = '<span class="t">' + fmt(r[1]) + '</span><span>' +
      '<span class="gm">' + esc(r[3]) + '</span><br><span class="rm">' +
      esc(r[4]) + '</span></span>';
    if (isOdd(r)) {
      li.classList.add('odd');
      li.title = 'x' + r[5].toFixed(2) + ' this reciter\'s median of ' +
        cur.median + ' ms a word';
    }
    li.onclick = () => { audio.currentTime = r[1] / 1000; tick(); };
    f.appendChild(li);
  });
  list.appendChild(f);
  $('#dur').textContent = fmt(cur.durationMs);
  $('#pins').textContent = cur.pinned.length + ' pinned, ' + cur.held.length + ' held';
  $('#odd').textContent = rows.filter(isOdd).length + ' off the pace';
  $('#ver').className = 'tag' + (cur.verified ? ' on' : '');
  $('#ver').textContent = cur.verified ? 'checked by ear' : 'not checked by ear';
  seek.max = cur.durationMs / 1000;
  at = -1;
  tick();
}

// The last line that has started. A repeated line appears twice in rows, so
// this walks the sung order rather than looking the line number up.
function indexAt(ms) {
  let lo = 0, hi = rows.length - 1, best = -1;
  while (lo <= hi) {
    const mid = (lo + hi) >> 1;
    if (rows[mid][1] <= ms) { best = mid; lo = mid + 1; } else hi = mid - 1;
  }
  return best;
}

function tick() {
  const ms = audio.currentTime * 1000;
  $('#now').textContent = fmt(ms);
  if (document.activeElement !== seek) seek.value = audio.currentTime;
  const i = indexAt(ms);
  if (i === at) return;
  if (at >= 0 && list.children[at]) list.children[at].classList.remove('on');
  at = i;
  const r = rows[i];
  if (!r) {
    $('#cg').textContent = '—';
    $('#cr').textContent = '';
    $('#cm').textContent = '';
    return;
  }
  const li = list.children[i];
  li.classList.add('on');
  li.scrollIntoView({ block: 'nearest' });
  $('#cg').textContent = r[3];
  $('#cr').textContent = r[4];
  $('#cm').textContent = 'line ' + r[0] + '  ·  ' + fmt(r[1]) + ' – ' +
    fmt(r[2]) + (cur.pinned.includes(r[0]) ? '  ·  pinned' : '') +
    (cur.held.includes(r[0]) ? '  ·  held' : '');
}

sel.onchange = () => { cur = B[sel.value]; draw(); };
$('#file').onchange = e => {
  const f = e.target.files[0];
  if (!f) return;
  audio.src = URL.createObjectURL(f);
  $('#fname').textContent = f.name;
  const stem = f.name.toLowerCase().replace(/\.[^.]+$/, '');
  const guess = B.findIndex(b => stem === b.slug);
  if (guess >= 0) { sel.value = guess; cur = B[guess]; draw(); }
};
seek.oninput = () => { audio.currentTime = +seek.value; tick(); };
$('#go').onclick = () => {
  const s = parse($('#jump').value);
  if (s !== null) { audio.currentTime = s; tick(); }
};
$('#jump').onkeydown = e => { if (e.key === 'Enter') $('#go').click(); };
$('#next').onclick = () => {
  const ms = audio.currentTime * 1000;
  const r = rows.find(x => x[1] > ms + 250 && isOdd(x)) || rows.find(isOdd);
  if (r) { audio.currentTime = Math.max(0, r[1] / 1000 - 3); tick(); }
};
audio.ontimeupdate = tick;
audio.onloadedmetadata = () => {
  const off = Math.round(audio.duration * 1000 - cur.durationMs);
  $('#drift').textContent = Math.abs(off) > 1500
    ? 'this file is ' + fmt(Math.abs(off)) + ' ' + (off > 0 ? 'longer' : 'shorter') +
      ' than the one these timings were built from'
    : '';
};
document.onkeydown = e => {
  if (e.target.tagName === 'INPUT' || e.target.tagName === 'SELECT') return;
  if (e.key === ' ') { e.preventDefault(); audio.paused ? audio.play() : audio.pause(); }
  if (e.key === 'ArrowLeft') audio.currentTime -= e.shiftKey ? 1 : 5;
  if (e.key === 'ArrowRight') audio.currentTime += e.shiftKey ? 1 : 5;
};
draw();
"""


def document(banis: list[dict]) -> str:
    data = json.dumps(banis, ensure_ascii=False, separators=(",", ":"))
    # The payload sits in a script tag, so a literal </script> in the text
    # would end it early. None exists today; this keeps it true.
    data = data.replace("</", "<\\/")
    return f"""<!DOCTYPE html>
<html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Hazri timings</title><style>{CSS}</style></head><body><div class="wrap">
<h1>Hazri timings</h1>
<p class="sub">Pick a recitation from your own disk and check where each line
lands. Nothing is uploaded.</p>

<div class="panel">
  <div class="row">
    <input type="file" id="file" accept="audio/*">
    <span class="tag" id="fname">no file</span>
  </div>
  <div class="row" style="margin-top:12px">
    <select id="bani"></select>
    <span class="tag" id="ver"></span>
    <span class="tag" id="pins"></span>
    <span class="tag" id="odd"></span>
    <span class="tag">of <span id="dur"></span></span>
  </div>
  <input type="range" id="seek" min="0" step="0.01" value="0">
  <div class="row">
    <span class="now" id="now">0:00.00</span>
    <input type="text" id="jump" size="9" placeholder="1:07:10">
    <button id="go">Go</button>
    <button id="next">Next suspect &#9670;</button>
    <span class="tag" id="drift"></span>
  </div>
  <p class="hint"><kbd>space</kbd> play &middot; <kbd>&larr;</kbd><kbd>&rarr;</kbd>
  5s, with <kbd>shift</kbd> 1s &middot; click any line to jump there &middot;
  a &#9670; time is a line the timings pace unlike the rest of this
  recitation &mdash; half the median or double it &mdash; which is where the
  warp tends to have lost its place</p>
</div>

<div class="cur">
  <div class="meta" id="cm"></div>
  <div class="gm" id="cg">&mdash;</div>
  <div class="rm" id="cr"></div>
</div>

<div class="panel"><ol id="lines"></ol></div>
<audio id="a"></audio></div>
<script>window.__BANIS__={data};</script>
<script>{JS}</script></body></html>
"""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("-o", "--out", default=os.path.join(ROOT, "build", "timings.html"))
    args = ap.parse_args()
    banis = collect()
    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write(document(banis))
    total = sum(len(b["rows"]) for b in banis)
    print(f"wrote {args.out}  ({len(banis)} banis, {total} lines, "
          f"{os.path.getsize(args.out) / 1024:.0f} KB)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
