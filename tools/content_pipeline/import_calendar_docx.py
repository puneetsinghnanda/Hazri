#!/usr/bin/env python3
"""Turns the supplied Sikh calendar .docx into content/source/calendar-558.json.

The document is the reviewed source; this only reshapes it. Nothing is
invented, translated or reworded on the way through -- an event's English text
is carried across exactly as written, and a bani that the document leaves in
English stays in English rather than being machine-translated into Gurmukhi.

Three things in the document are read as data rather than prose:

* the **month-by-month tables**, which carry Gregorian date, Nanakshahi date,
  type and event -- the four columns asked for;
* the **calendar markers** line under each month, which names that month's
  Sangrand, Puranmashi and Masya. These become events in their own right, and
  the Sangrands also fix every Nanakshahi month start for the year;
* the **"Major dates at a glance"** table, which is the document's own
  statement of which dates are major. That, rather than a rule invented here,
  decides which events default to reminding.

The "at a glance" table is also a free consistency check: every row in it has
to appear in a month table with the same date and wording, or the document
disagrees with itself and this refuses to write a file.

The Nanakshahi column is **recomputed** from its month's Sangrand rather than
copied, because in four places the document's own two statements disagree.
Every month start is fixed twice over -- by the Sangrand named in the markers
line, and by the Nanakshahi day on each of that month's events -- and the two
must agree or this stops. Where a single row then disagrees with its own
month, the row is the odd one out and its Gregorian date is kept while its
Nanakshahi day is corrected; each correction is listed in `corrections` in the
output and printed, so none of it happens quietly.

    python3 tools/content_pipeline/import_calendar_docx.py \\
        content/source/Sikh_Calendar_FY_2026-27.docx
"""
from __future__ import annotations

import argparse
import datetime
import json
import os
import re
import xml.etree.ElementTree as ET
import zipfile

W = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
NS = {"w": W}

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "content", "source", "calendar-558.json")

MONTHS = ["Chet", "Vaisakh", "Jeth", "Harh", "Sawan", "Bhadon",
          "Assu", "Katak", "Maghar", "Poh", "Magh", "Phagun"]

# The document's Type column, as stored. A trailing asterisk means the
# document marks the row as supplementary rather than SGPC-confirmed, and is
# stripped here and kept in its own field.
TYPES = {
    "prakash": "prakash", "gurgaddi": "gurgaddi", "joti jot": "joti-jot",
    "shaheedi": "shaheedi", "jor mela": "jor-mela", "birth": "birth",
    "historical": "historical", "festival": "festival", "special": "special",
}
MARKERS = {"sangrand": "sangrand", "puranmashi": "puranmashi", "masya": "masya"}


def blocks(path: str) -> list[dict]:
    with zipfile.ZipFile(path) as z:
        root = ET.fromstring(z.read("word/document.xml"))
    body = root.find("w:body", NS)
    out: list[dict] = []
    for child in body:
        tag = child.tag.split("}")[1]
        if tag == "p":
            text = "".join(n.text or "" for n in child.iter(f"{{{W}}}t")).strip()
            if text:
                out.append({"kind": "p", "text": text})
        elif tag == "tbl":
            out.append({"kind": "tbl", "rows": [
                ["".join(n.text or "" for n in tc.iter(f"{{{W}}}t")).strip()
                 for tc in tr.findall("w:tc", NS)]
                for tr in child.findall("w:tr", NS)]})
    return out


def parse_date(cell: str) -> str:
    """'Wed, 01 Apr 2026' or '01 Apr 2026' -> '2026-04-01'."""
    text = cell.split(",")[-1].strip()
    return datetime.datetime.strptime(text, "%d %b %Y").date().isoformat()


def parse_ns(cell: str) -> tuple[int, str, int]:
    """'01 Vaisakh 558' -> (1, 'Vaisakh', 558)."""
    day, month, year = cell.split()
    if month not in MONTHS:
        raise SystemExit(f"unknown Nanakshahi month {month!r} in {cell!r}")
    return int(day), month, int(year)


def ns_label(day: int, month: str, year: int) -> str:
    return f"{day} {month} {year}"


def read_markers(line: str) -> list[tuple[str, str]]:
    """'Calendar markers: 14 Apr - Sangrand - 02 Apr - Puranmashi' -> pairs.

    A marker can carry two names at once ('15 Jun - Sangrand / Masya') when
    they fall on the same day, and one is spelled 'Chet Sangrand / Nanakshahi
    New Year'. Both are read as the markers they name and nothing else.
    """
    found = []
    for part in line.split(":", 1)[1].split("•"):
        part = part.strip()
        if not part:
            continue
        when, _, names = part.partition("–")
        if not names:
            when, _, names = part.partition("-")
        when = when.strip()
        for name in names.split("/"):
            key = name.strip().lower().replace("chet ", "")
            if key in MARKERS:
                found.append((when, MARKERS[key]))
    return found


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("docx")
    ap.add_argument("-o", "--out", default=OUT)
    args = ap.parse_args()

    bs = blocks(args.docx)

    # "Major dates at a glance": the document's own list of the major ones.
    glance: set[tuple[str, str]] = set()
    for b in bs:
        if b["kind"] == "tbl" and b["rows"][0][:3] == ["Date", "Nanakshahi", "Event"]:
            for row in b["rows"][1:]:
                glance.add((parse_date(row[0]), row[2]))
            break
    if not glance:
        raise SystemExit("no 'Major dates at a glance' table found")

    events: list[dict] = []
    marker_rows: list[tuple[str, str]] = []
    month_of: dict[str, str] = {}          # gregorian month heading -> year text
    heading = None

    for i, b in enumerate(bs):
        if b["kind"] == "p":
            if re.fullmatch(r"[A-Z][a-z]+ \d{4}", b["text"]):
                heading = b["text"]
            elif b["text"].startswith("Calendar markers:"):
                for when, kind in read_markers(b["text"]):
                    # '14 Apr' takes its year from the month heading above it.
                    year = heading.split()[-1]
                    marker_rows.append(
                        (parse_date(f"{when} {year}"), kind))
            continue
        head = b["rows"][0]
        if head[:4] != ["Gregorian Date", "Nanakshahi Date", "Type", "Event"]:
            continue
        for row in b["rows"][1:]:
            date = parse_date(row[0])
            day, month, year = parse_ns(row[1])
            raw_type = row[2].strip()
            supplementary = raw_type.endswith("*")
            key = raw_type.rstrip("*").strip().lower()
            if key not in TYPES:
                raise SystemExit(f"unknown Type {raw_type!r} on {date}")
            events.append({
                "date": date,
                "nanakshahi": ns_label(day, month, year),
                "type": TYPES[key],
                "en": row[3],
                "supplementary": supplementary,
                "remind": (date, row[3]) in glance,
            })

    # Every "at a glance" row has to be somewhere in the month tables.
    have = {(e["date"], e["en"]) for e in events}
    missing = sorted(glance - have)
    if missing:
        raise SystemExit(
            "these rows are in 'Major dates at a glance' but in no month "
            "table, so the document disagrees with itself:\n  "
            + "\n  ".join(f"{d}  {t}" for d, t in missing))

    # Each month's start, taken twice over. Every event implies one through its
    # own Nanakshahi day; the markers line names the Sangrand outright. The
    # majority of the events decides, and the marker has to agree with it.
    votes: dict[tuple[int, int], dict[str, int]] = {}
    for e in events:
        day, month, year = parse_ns(e["nanakshahi"])
        d = datetime.date.fromisoformat(e["date"]) - datetime.timedelta(days=day - 1)
        tally = votes.setdefault((year, MONTHS.index(month)), {})
        tally[d.isoformat()] = tally.get(d.isoformat(), 0) + 1

    starts = {k: max(v.items(), key=lambda kv: kv[1])[0] for k, v in votes.items()}
    for key, tally in votes.items():
        best = starts[key]
        if tally[best] <= sum(tally.values()) - tally[best]:
            raise SystemExit(
                f"{MONTHS[key[1]]} {key[0]} has no clear start: {tally}")

    sangrands = {d for d, k in marker_rows if k == "sangrand"}
    stray = sorted(sangrands - set(starts.values()))
    if stray:
        raise SystemExit(
            "these Sangrand markers match no month start the events imply, so "
            f"the document's two statements disagree: {stray}")

    months = [{"ns_year": y, "idx": i, "start": s}
              for (y, i), s in sorted(starts.items())]
    # A month runs until the next Sangrand. The last one has no next, so it
    # takes the traditional length -- 31 days for the first five months of the
    # year, 30 for the rest.
    for pos, m in enumerate(months):
        if pos + 1 < len(months):
            m["days"] = (datetime.date.fromisoformat(months[pos + 1]["start"])
                         - datetime.date.fromisoformat(m["start"])).days
        else:
            m["days"] = 31 if m["idx"] < 5 else 30

    # Rows whose own Nanakshahi day disagrees with their month. The Gregorian
    # date is kept and the Nanakshahi day recomputed, because the month start
    # is corroborated twice and the row only once.
    corrections = []
    for e in events:
        day, month, year = parse_ns(e["nanakshahi"])
        start = datetime.date.fromisoformat(starts[(year, MONTHS.index(month))])
        want = (datetime.date.fromisoformat(e["date"]) - start).days + 1
        if want != day:
            corrections.append({
                "date": e["date"], "event": e["en"],
                "document": e["nanakshahi"], "stored": ns_label(want, month, year),
            })
            e["nanakshahi"] = ns_label(want, month, year)

    # Markers become events too, with the Nanakshahi date computed from the
    # month they fall in rather than guessed.
    def ns_for(date: str) -> str | None:
        d = datetime.date.fromisoformat(date)
        best = None
        for m in months:
            start = datetime.date.fromisoformat(m["start"])
            if start <= d and (best is None
                               or start > datetime.date.fromisoformat(best["start"])):
                best = m
        if best is None:
            return None
        day = (d - datetime.date.fromisoformat(best["start"])).days + 1
        return ns_label(day, MONTHS[best["idx"]], best["ns_year"])

    for date, kind in sorted(set(marker_rows)):
        label = ns_for(date)
        if label is None:
            continue
        events.append({
            "date": date,
            "nanakshahi": label,
            "type": kind,
            "en": {"sangrand": "Sangrand", "puranmashi": "Puranmashi",
                   "masya": "Masya"}[kind],
            "supplementary": False,
            "remind": False,
        })

    events.sort(key=lambda e: (e["date"], e["type"], e["en"]))
    doc = {
        "_note": (
            "Sikh calendar for financial year 2026-27, Nanakshahi Samvat 558 "
            "with the tail entering 559, read from the supplied .docx by "
            "tools/content_pipeline/import_calendar_docx.py. The document "
            "names the SGPC 2026-27 Nanakshahi calendar as its primary "
            "authority and marks its own supplementary entries; those are "
            "carried here as \"supplementary\": true. Event text is English "
            "only, exactly as the document writes it. Punjabi and Hindi are "
            "absent rather than machine-translated, and the reader falls back "
            "to English where they are missing. `remind` is true for the "
            "dates the document itself lists under \"Major dates at a "
            "glance\"."),
        "year": "558 NS",
        "months": months,
        "corrections": corrections,
        "events": events,
    }
    with open(args.out, "w", encoding="utf-8") as fh:
        json.dump(doc, fh, ensure_ascii=False, indent=1)
        fh.write("\n")

    kinds: dict[str, int] = {}
    for e in events:
        kinds[e["type"]] = kinds.get(e["type"], 0) + 1
    print(f"wrote {args.out}")
    print(f"  {len(events)} events, {len(months)} Nanakshahi months, "
          f"{sum(1 for e in events if e['remind'])} default to reminding, "
          f"{sum(1 for e in events if e['supplementary'])} supplementary")
    print("  " + "  ".join(f"{k}={v}" for k, v in sorted(kinds.items())))
    print(f"  {months[0]['start']} .. covered through {events[-1]['date']}")
    if corrections:
        print(f"  {len(corrections)} Nanakshahi date(s) corrected against the "
              f"Sangrand their month is given:")
        for c in corrections:
            print(f"    {c['date']}  {c['document']} -> {c['stored']}   "
                  f"{c['event'][:48]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
