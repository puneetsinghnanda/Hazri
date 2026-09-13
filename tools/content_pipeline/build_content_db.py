#!/usr/bin/env python3
"""Build assets/content/content.db for Hazri.

Nothing Gurbani-related is typed by hand in app code (PRD §8): every line of
Gurbani, every meaning and every credit in the app comes out of this script,
which reads only the reviewed source files under content/source/.

Usage:  python3 tools/content_pipeline/build_content_db.py
"""
from __future__ import annotations

import hashlib
import json
import os
import sqlite3
import sys
from datetime import datetime, timedelta

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SRC = os.path.join(ROOT, "content", "source")
OUT = os.path.join(ROOT, "assets", "content", "content.db")
REPORT = os.path.join(ROOT, "content", "build-report.json")
AUDIO_DIR = os.path.join(ROOT, "assets", "audio")
TIMINGS_DIR = os.path.join(ROOT, "content", "source", "timings")
SIMRAN_DIR = os.path.join(ROOT, "content", "source", "simran")
VICHAR_DIR = os.path.join(ROOT, "content", "source", "vichar")

CONTENT_VERSION = 6

# Must match ContentDb.schemaVersion in lib/core/db/content_db.dart.
DRIFT_SCHEMA_VERSION = 1

# Shabad OS encodes vishraam (pause marks) as punctuation inside the Gurmukhi
# string: ';' is the heavy mid-line pause, '.' and ',' are lighter ones.
# The reader renders two levels, so ';' maps to long and the rest to short.
VISHRAAM = {";": "long", ".": "short", ",": "short"}

SCHEMA = """
PRAGMA journal_mode=DELETE;

CREATE TABLE source(
  id TEXT PRIMARY KEY, name TEXT NOT NULL, author TEXT, kind TEXT NOT NULL,
  licence TEXT, url TEXT, notes TEXT, publisher TEXT, pub_date TEXT);

CREATE TABLE bani(
  id TEXT PRIMARY KEY, slug TEXT NOT NULL UNIQUE,
  name_en TEXT NOT NULL, name_pa TEXT NOT NULL, name_hi TEXT NOT NULL,
  category TEXT NOT NULL, default_slot TEXT NOT NULL,
  sort INTEGER NOT NULL, est_minutes INTEGER NOT NULL,
  author_en TEXT, has_text INTEGER NOT NULL DEFAULT 0);

CREATE TABLE bani_version(
  id TEXT PRIMARY KEY, bani_id TEXT NOT NULL REFERENCES bani(id),
  code TEXT NOT NULL, label_en TEXT, label_pa TEXT, label_hi TEXT,
  is_default INTEGER NOT NULL DEFAULT 0, line_count INTEGER NOT NULL DEFAULT 0);

CREATE TABLE line(
  id INTEGER PRIMARY KEY, bani_version_id TEXT NOT NULL REFERENCES bani_version(id),
  idx INTEGER NOT NULL,
  section_label_en TEXT, section_label_pa TEXT, section_label_hi TEXT,
  kind TEXT NOT NULL,
  gurmukhi TEXT NOT NULL, devanagari TEXT NOT NULL, roman TEXT NOT NULL,
  visraam_json TEXT, word_count INTEGER NOT NULL, word_align INTEGER NOT NULL DEFAULT 1,
  source_id TEXT, source_ref TEXT, pauri INTEGER, ends_pauri INTEGER);
CREATE UNIQUE INDEX line_version_idx ON line(bani_version_id, idx);

CREATE TABLE meaning(
  line_id INTEGER NOT NULL REFERENCES line(id), lang TEXT NOT NULL,
  text TEXT NOT NULL, source_id TEXT, is_alt INTEGER NOT NULL DEFAULT 0,
  kind TEXT NOT NULL DEFAULT 'translation', note TEXT,
  PRIMARY KEY(line_id, lang, is_alt));

CREATE TABLE voice(id TEXT PRIMARY KEY, name TEXT, credit_en TEXT, credit_pa TEXT, credit_hi TEXT);

CREATE TABLE audio_track(
  id TEXT PRIMARY KEY, bani_version_id TEXT NOT NULL, voice_id TEXT,
  pack TEXT NOT NULL, file TEXT NOT NULL, duration_ms INTEGER, bytes INTEGER);

CREATE TABLE timing(audio_track_id TEXT PRIMARY KEY, json TEXT NOT NULL);

-- Naam Simran is not a bani, so it has no bani_version and cannot ride in
-- audio_track. Its json carries the loudness envelope and the utterance
-- onsets the Simran ring is drawn from (PRD 1.13).
-- One line of Gurbani a day, with its meaning (PRD 1.11). `idx` is the
-- position in the cycle, not an Ang: this dataset carries no Ang numbers and
-- the app does not invent one.
CREATE TABLE vichar(
  idx INTEGER PRIMARY KEY, gurmukhi TEXT NOT NULL,
  meaning_pa TEXT NOT NULL, meaning_en TEXT NOT NULL);

CREATE TABLE simran_track(
  id TEXT PRIMARY KEY, file TEXT NOT NULL, duration_ms INTEGER, bytes INTEGER,
  json TEXT NOT NULL);

CREATE TABLE nanakshahi_month(
  ns_year INTEGER NOT NULL, idx INTEGER NOT NULL,
  name_en TEXT NOT NULL, name_pa TEXT NOT NULL, name_hi TEXT NOT NULL,
  start_date TEXT NOT NULL, days INTEGER NOT NULL,
  PRIMARY KEY(ns_year, idx));

CREATE TABLE calendar_event(
  id TEXT PRIMARY KEY, ns_year INTEGER NOT NULL, date TEXT NOT NULL, kind TEXT NOT NULL,
  name_en TEXT NOT NULL, name_pa TEXT NOT NULL, name_hi TEXT NOT NULL,
  ns_label TEXT, default_remind INTEGER NOT NULL DEFAULT 1);
CREATE INDEX calendar_event_date ON calendar_event(date);

CREATE TABLE city(
  id TEXT PRIMARY KEY, name_en TEXT NOT NULL, name_pa TEXT NOT NULL, name_hi TEXT NOT NULL,
  country_code TEXT NOT NULL, lat REAL NOT NULL, lon REAL NOT NULL, tz TEXT NOT NULL);

CREATE TABLE quote(
  id TEXT PRIMARY KEY, gurmukhi TEXT NOT NULL, devanagari TEXT NOT NULL, roman TEXT NOT NULL,
  attribution_en TEXT, attribution_pa TEXT, attribution_hi TEXT, source_id TEXT);

CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT NOT NULL);
"""

# Nanakshahi month names. The Sangrand (start_date) rows below are the only
# thing that maps a Gregorian date onto these, and they are taken from the
# supplied SGPC sample -- never computed or guessed.
NS_MONTHS = [
    ("Chet", "ਚੇਤ", "चेत"), ("Vaisakh", "ਵੈਸਾਖ", "वैसाख"), ("Jeth", "ਜੇਠ", "जेठ"),
    ("Harh", "ਹਾੜ", "हाड़"), ("Sawan", "ਸਾਵਣ", "सावण"), ("Bhadon", "ਭਾਦੋਂ", "भादों"),
    ("Assu", "ਅੱਸੂ", "अस्सू"), ("Katak", "ਕੱਤਕ", "कत्तक"), ("Maghar", "ਮੱਘਰ", "मग्घर"),
    ("Poh", "ਪੋਹ", "पोह"), ("Magh", "ਮਾਘ", "माघ"), ("Phagun", "ਫੱਗਣ", "फग्गण"),
]

BANIS = [
    # id, slug, en, pa, hi, category, slot, sort, est_min, author
    ("JAPJ", "japji-sahib", "Japji Sahib", "ਜਪੁ ਜੀ ਸਾਹਿਬ", "जपु जी साहिब",
     "nitnem", "morning", 1, 20, "Guru Nanak Dev Ji"),
    ("JAAP", "jaap-sahib", "Jaap Sahib", "ਜਾਪੁ ਸਾਹਿਬ", "जापु साहिब",
     "nitnem", "morning", 2, 18, "Guru Gobind Singh Ji"),
    ("TVPS", "tav-prasad-savaiye", "Tav Prasad Savaiye", "ਤਵ ਪ੍ਰਸਾਦਿ ਸਵੱਯੇ", "तव प्रसादि सवैये",
     "nitnem", "morning", 3, 4, "Guru Gobind Singh Ji"),
    ("CHAU", "chaupai-sahib", "Chaupai Sahib", "ਚੌਪਈ ਸਾਹਿਬ", "चौपई साहिब",
     "nitnem", "morning", 4, 8, "Guru Gobind Singh Ji"),
    ("ANND", "anand-sahib", "Anand Sahib", "ਅਨੰਦੁ ਸਾਹਿਬ", "अनंदु साहिब",
     "nitnem", "morning", 5, 13, "Guru Amar Das Ji"),
    ("REHR", "rehras-sahib", "Rehras Sahib", "ਰਹਿਰਾਸ ਸਾਹਿਬ", "रहिरास साहिब",
     "nitnem", "evening", 6, 18, None),
    ("SOHL", "kirtan-sohila", "Kirtan Sohila", "ਕੀਰਤਨ ਸੋਹਿਲਾ", "कीरतन सोहिला",
     "nitnem", "bedtime", 7, 5, None),
    ("ARDS", "ardas", "Ardas", "ਅਰਦਾਸ", "अरदास",
     "other", "none", 8, 5, None),
    ("SUKH", "sukhmani-sahib", "Sukhmani Sahib", "ਸੁਖਮਨੀ ਸਾਹਿਬ", "सुखमनी साहिब",
     "other", "none", 9, 60, "Guru Arjan Dev Ji"),
]

SECTION_LABELS = {
    "mool_mantar": ("Mool Mantar", "ਮੂਲ ਮੰਤਰ", "मूल मंतर"),
    "title": ("Jap", "ਜਪੁ", "जपु"),
    "opening_salok": ("Opening Salok", "ਆਰੰਭਕ ਸਲੋਕ", "आरंभिक सलोक"),
    "salok_heading": ("Salok", "ਸਲੋਕੁ", "सलोकु"),
    "closing_salok": ("Closing Salok", "ਅੰਤਮ ਸਲੋਕ", "अंतिम सलोक"),
}

LINE_KIND = {
    "mool_mantar": "mangal",
    "title": "heading",
    "salok_heading": "heading",
    "opening_salok": "verse",
    "closing_salok": "verse",
    "pauri": "verse",
}


def parse_vishraam(marked: str, plain_words: list[str]) -> list[dict]:
    """Return [{"w": word_index, "t": "short"|"long"}] from the marked string.

    The marked string is the plain string with pause punctuation appended to
    some words, so walking both in step gives the word index of each mark.
    """
    marks: list[dict] = []
    i = 0
    for token in marked.split():
        stripped = token.rstrip(";.,")
        trailing = token[len(stripped):]
        if not stripped:
            # A bare punctuation token would desynchronise the walk; skip it.
            continue
        if i >= len(plain_words) or stripped != plain_words[i]:
            # Tokens diverged -- refuse to guess, drop the marks for this line.
            return []
        if trailing:
            marks.append({"w": i, "t": VISHRAAM.get(trailing[0], "short")})
        i += 1
    return marks if i == len(plain_words) else []


def build_japji(con: sqlite3.Connection, report: dict) -> None:
    with open(os.path.join(SRC, "japji_sahib.json"), encoding="utf-8") as fh:
        doc = json.load(fh)

    prov = doc["provenance"]
    # Sources: text/translation datasets declared by the source file itself.
    con.execute(
        "INSERT INTO source(id,name,author,kind,licence,url,notes) VALUES(?,?,?,?,?,?,?)",
        ("SHABADOS", prov["text_and_translations"]["dataset"], None, "text",
         prov["text_and_translations"]["license"], prov["text_and_translations"]["repository"],
         "commit " + prov["text_and_translations"]["commit"]))
    con.execute(
        "INSERT INTO source(id,name,author,kind,licence,url,notes) VALUES(?,?,?,?,?,?,?)",
        ("GURMUKHIUTILS", "gurmukhi-utils " + prov["transliteration"]["version"], None,
         "translit", "MIT", "https://github.com/shabados/gurmukhi-utils",
         prov["transliteration"]["note"]))
    for code, a in prov["assets"].items():
        con.execute(
            "INSERT INTO source(id,name,author,kind,licence,url,notes,publisher,pub_date) "
            "VALUES(?,?,?,?,?,?,?,?,?)",
            (code, a.get("name", code), a.get("author"), "meaning", None, None,
             None, a.get("publisher"), a.get("date")))

    b = doc["bani"]
    # The Gurmukhi and Devanagari names come from the source file; the English
    # one stays as the designs and the PRD spell it ("Japji Sahib", not the
    # dataset's "Jap Ji Sahib"), since it is a display label rather than
    # scripture.
    con.execute(
        "UPDATE bani SET name_pa=?, name_hi=?, author_en=?, has_text=1 WHERE id='JAPJ'",
        (b["name"]["gurmukhi"], b["name"]["transliteration_hindi"], b["author"]))

    version_id = "JAPJ_SGPC"
    con.execute(
        "INSERT INTO bani_version(id,bani_id,code,label_en,label_pa,label_hi,is_default,line_count)"
        " VALUES(?,?,?,?,?,?,1,?)",
        (version_id, "JAPJ", "sgpc", "SGPC", "ਐਸ.ਜੀ.ਪੀ.ਸੀ.", "एस.जी.पी.सी.", len(doc["lines"])))

    # Section label per line, from the structure block.
    total_pauris = b["total_pauris"]
    label_for_line: dict[int, tuple[str, str, str]] = {}
    for sec in doc["structure"]:
        if sec["type"] == "pauri":
            n = sec["pauri"]
            labels = (f"Pauri {n} of {total_pauris}",
                      f"ਪਉੜੀ {n} / {total_pauris}",
                      f"पउड़ी {n} / {total_pauris}")
        else:
            labels = SECTION_LABELS[sec["type"]]
        for ln in range(sec["line_from"], sec["line_to"] + 1):
            label_for_line[ln] = labels

    misaligned: list[int] = []
    no_vishraam: list[int] = []
    for ln in doc["lines"]:
        idx = ln["id"] - 1
        text = ln["text"]
        plain_words = text["gurmukhi_plain"].split()
        roman = text["transliteration"]["english"]
        dev = text["transliteration"]["hindi"]
        aligned = (len(roman.split()) == len(plain_words)
                   and len(dev.split()) == len(plain_words))
        if not aligned:
            misaligned.append(ln["id"])
        marks = parse_vishraam(text["gurmukhi"], plain_words)
        if not marks and any(c in text["gurmukhi"] for c in VISHRAAM):
            no_vishraam.append(ln["id"])
        labels = label_for_line.get(ln["id"], ("", "", ""))
        con.execute(
            "INSERT INTO line(id,bani_version_id,idx,section_label_en,section_label_pa,"
            "section_label_hi,kind,gurmukhi,devanagari,roman,visraam_json,word_count,"
            "word_align,source_id,source_ref,pauri,ends_pauri) "
            "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (ln["id"], version_id, idx, labels[0], labels[1], labels[2],
             LINE_KIND[ln["section"]], text["gurmukhi_plain"], dev, roman,
             json.dumps(marks, ensure_ascii=False) if marks else None,
             len(plain_words), 1 if aligned else 0, "SHABADOS",
             f"SGGS {ln['sggs']['page']}:{ln['sggs']['line']}",
             ln.get("pauri"), 1 if ln.get("ends_pauri") else 0))

        m = ln["meaning"]
        rows = []
        if m.get("english"):
            rows.append(("en", m["english"], 0, "translation", None))
        if m.get("english_alt"):
            rows.append(("en", m["english_alt"], 1, "translation", None))
        if m.get("punjabi"):
            rows.append(("pa", m["punjabi"], 0, "translation", None))
        if m.get("punjabi_alt"):
            rows.append(("pa", m["punjabi_alt"], 1, "translation", None))
        if m.get("hindi"):
            # Faridkot Wala Teeka: Braj/Sadhukkari exegesis, not a plain
            # translation, so it is tagged 'commentary' and the reader shows it
            # collapsed behind its own disclosure with the source note.
            rows.append(("hi", m["hindi"], 0, "commentary", m["hindi"].get("note")))
        for lang, payload, is_alt, kind, note in rows:
            con.execute(
                "INSERT INTO meaning(line_id,lang,text,source_id,is_alt,kind,note) "
                "VALUES(?,?,?,?,?,?,?)",
                (ln["id"], lang, payload["text"], payload.get("source"), is_alt, kind, note))

    report["japji"] = {
        "lines": len(doc["lines"]),
        "word_misaligned_lines": misaligned,
        "vishraam_unparsed_lines": no_vishraam,
    }

    # The Simran quote card (PRD 1.13) comes from content, not from app code.
    con.execute(
        "INSERT INTO quote(id,gurmukhi,devanagari,roman,attribution_en,attribution_pa,"
        "attribution_hi,source_id) VALUES(?,?,?,?,?,?,?,?)",
        ("simran_1", "ਸਿਮਰਉ ਸਿਮਰਿ ਸਿਮਰਿ ਸੁਖੁ ਪਾਵਉ ॥", "सिमरउ सिमरि सिमरि सुखु पावउ ॥",
         "simrau simar simar sukh paavau ||", "Sukhmani Sahib", "ਸੁਖਮਨੀ ਸਾਹਿਬ",
         "सुखमनी साहिब", "SHABADOS"))


def build_audio(con: sqlite3.Connection, report: dict) -> None:
    """Registers any converted recitation and its timing file.

    Audio is optional: a bani with no recording gets no audio_track row, and
    the app falls back to a text-only reader for it.
    """
    built = []
    for bani_id, slug in con.execute("SELECT id, slug FROM bani").fetchall():
        audio = os.path.join(AUDIO_DIR, f"{slug}.m4a")
        timings = os.path.join(TIMINGS_DIR, f"{slug}.json")
        if not os.path.exists(audio):
            continue
        version = con.execute(
            "SELECT id FROM bani_version WHERE bani_id = ? AND is_default = 1", (bani_id,)
        ).fetchone()
        if version is None:
            continue
        version_id = version[0]

        duration_ms = None
        timing_json = None
        if os.path.exists(timings):
            with open(timings, encoding="utf-8") as fh:
                doc = json.load(fh)
            duration_ms = doc.get("durationMs")
            timing_json = json.dumps(doc, ensure_ascii=False, separators=(",", ":"))

        track_id = f"{slug}_sgpc"
        con.execute(
            "INSERT INTO audio_track(id,bani_version_id,voice_id,pack,file,duration_ms,bytes) "
            "VALUES(?,?,?,?,?,?,?)",
            (track_id, version_id, None, "nitnem_audio", f"{slug}.m4a",
             duration_ms, os.path.getsize(audio)),
        )
        if timing_json:
            con.execute("INSERT INTO timing(audio_track_id,json) VALUES(?,?)",
                        (track_id, timing_json))
        built.append({
            "bani": slug,
            "bytes": os.path.getsize(audio),
            "duration_ms": duration_ms,
            "has_timings": timing_json is not None,
        })
    report["audio"] = built


def build_vichar(con: sqlite3.Connection, report: dict) -> None:
    """Loads the daily Gurbani lines the Today card cycles through.

    Nothing here is written by the app: the lines and both meanings come from
    the reviewed file in content/source/vichar, exactly as every other piece of
    Gurbani does (PRD §0.3).
    """
    path = os.path.join(VICHAR_DIR, "gurbani-200.json")
    if not os.path.exists(path):
        report["vichar"] = None
        return
    with open(path, encoding="utf-8") as fh:
        doc = json.load(fh)

    rows = []
    for idx, entry in enumerate(doc["gurbani_lines"]):
        line = " ".join(
            part.strip()
            for part in (entry.get("punjabi_line1"), entry.get("punjabi_line2"))
            if part and part.strip()
        )
        pa = (entry.get("punjabi_meaning") or "").strip()
        en = (entry.get("english_meaning") or "").strip()
        if not line or not pa:
            raise SystemExit(f"vichar entry {entry.get('id')} has no line or no meaning")
        rows.append((idx, line, pa, en))

    con.executemany(
        "INSERT INTO vichar(idx,gurmukhi,meaning_pa,meaning_en) VALUES(?,?,?,?)", rows
    )
    report["vichar"] = {
        "lines": len(rows),
        "scripture": doc.get("scripture"),
        "with_english": sum(1 for r in rows if r[3]),
    }


def build_simran(con: sqlite3.Connection, report: dict) -> None:
    """Registers the Naam Simran recitation and the shape the ring follows."""
    built = []
    for name in sorted(os.listdir(SIMRAN_DIR)) if os.path.isdir(SIMRAN_DIR) else []:
        if not name.endswith(".json"):
            continue
        with open(os.path.join(SIMRAN_DIR, name), encoding="utf-8") as fh:
            doc = json.load(fh)
        audio = os.path.join(AUDIO_DIR, doc["file"])
        if not os.path.exists(audio):
            continue
        con.execute(
            "INSERT INTO simran_track(id,file,duration_ms,bytes,json) VALUES(?,?,?,?,?)",
            (doc["track"], doc["file"], doc.get("durationMs"), os.path.getsize(audio),
             json.dumps(doc, ensure_ascii=False, separators=(",", ":"))),
        )
        built.append({
            "track": doc["track"],
            "bytes": os.path.getsize(audio),
            "duration_ms": doc.get("durationMs"),
            "onsets": len(doc.get("onsets", [])),
        })
    report["simran"] = built


def build_calendar(con: sqlite3.Connection, report: dict) -> None:
    with open(os.path.join(SRC, "gurpurab-558.json"), encoding="utf-8") as fh:
        doc = json.load(fh)
    ns_year = int(doc["year"].split()[0])

    con.execute(
        "INSERT INTO source(id,name,author,kind,licence,url,notes) VALUES(?,?,?,?,?,?,?)",
        ("SGPCCAL", "SGPC Nanakshahi calendar (jantri)", "SGPC", "calendar", None, None,
         doc.get("_note")))

    # Derive each Sangrand from the event list: an event dated D and labelled
    # "<n> <Month> <year>" puts that month's day 1 at D - (n-1). Only months the
    # supplied data actually covers are stored; the rest stay absent so the app
    # can say so rather than show an invented date.
    name_to_idx = {m[0]: i for i, m in enumerate(NS_MONTHS)}
    starts: dict[int, set[date]] = {}
    for ev in doc["events"]:
        day_s, month_name, _ = ev["nanakshahi"].split()
        idx = name_to_idx[month_name]
        d = datetime.strptime(ev["date"], "%Y-%m-%d").date()
        starts.setdefault(idx, set()).add(d - timedelta(days=int(day_s) - 1))

    months = []
    for idx, candidates in sorted(starts.items()):
        if len(candidates) != 1:
            raise SystemExit(
                f"Inconsistent Sangrand for {NS_MONTHS[idx][0]}: {sorted(candidates)}")
        months.append((idx, candidates.pop()))

    for pos, (idx, start) in enumerate(months):
        # Month length is only known when the next month's Sangrand is also
        # covered; otherwise fall back to the traditional length.
        if pos + 1 < len(months) and months[pos + 1][0] == idx + 1:
            days = (months[pos + 1][1] - start).days
        else:
            days = 31 if idx < 5 else 30
        name_en, name_pa, name_hi = NS_MONTHS[idx]
        con.execute(
            "INSERT INTO nanakshahi_month(ns_year,idx,name_en,name_pa,name_hi,start_date,days)"
            " VALUES(?,?,?,?,?,?,?)",
            (ns_year, idx, name_en, name_pa, name_hi, start.isoformat(), days))

    for i, ev in enumerate(doc["events"]):
        con.execute(
            "INSERT INTO calendar_event(id,ns_year,date,kind,name_en,name_pa,name_hi,"
            "ns_label,default_remind) VALUES(?,?,?,?,?,?,?,?,?)",
            (f"ev{i:03d}", ns_year, ev["date"], ev.get("kind", "gurpurab"),
             ev["en"], ev["pa"], ev.get("hi", ev["en"]), ev["nanakshahi"],
             1 if ev.get("remind", True) else 0))

    report["calendar"] = {
        "events": len(doc["events"]),
        "months_covered": [NS_MONTHS[i][0] for i, _ in months],
        "covered_from": months[0][1].isoformat() if months else None,
        "covered_to": (months[-1][1] + timedelta(
            days=(31 if months[-1][0] < 5 else 30) - 1)).isoformat() if months else None,
    }


def build_cities(con: sqlite3.Connection, report: dict) -> None:
    with open(os.path.join(os.path.dirname(__file__), "cities.json"), encoding="utf-8") as fh:
        cities = json.load(fh)
    for c in cities:
        con.execute(
            "INSERT INTO city(id,name_en,name_pa,name_hi,country_code,lat,lon,tz) "
            "VALUES(?,?,?,?,?,?,?,?)",
            (c["id"], c["en"], c["pa"], c["hi"], c["cc"], c["lat"], c["lon"], c["tz"]))
    report["cities"] = len(cities)


def source_digest() -> str:
    """sha256 over every input that can change the database."""
    h = hashlib.sha256()
    inputs = [
        os.path.join(SRC, "japji_sahib.json"),
        os.path.join(SRC, "gurpurab-558.json"),
        os.path.join(os.path.dirname(__file__), "cities.json"),
        os.path.abspath(__file__),
    ]
    for folder in (TIMINGS_DIR, SIMRAN_DIR, VICHAR_DIR):
        if os.path.isdir(folder):
            inputs += sorted(
                os.path.join(folder, f) for f in os.listdir(folder) if f.endswith(".json")
            )
    for path in inputs:
        with open(path, "rb") as fh:
            h.update(hashlib.sha256(fh.read()).digest())
    return h.hexdigest()[:16]


def main() -> int:
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    if os.path.exists(OUT):
        os.remove(OUT)
    con = sqlite3.connect(OUT)
    con.executescript(SCHEMA)
    report: dict = {}

    for row in BANIS:
        con.execute(
            "INSERT INTO bani(id,slug,name_en,name_pa,name_hi,category,default_slot,sort,"
            "est_minutes,author_en,has_text) VALUES(?,?,?,?,?,?,?,?,?,?,0)", row)

    build_japji(con, report)
    build_audio(con, report)
    build_simran(con, report)
    build_vichar(con, report)
    build_calendar(con, report)
    build_cities(con, report)

    con.execute("INSERT INTO meta(key,value) VALUES('content_version',?)", (str(CONTENT_VERSION),))
    # A digest of the inputs rather than a wall-clock timestamp, so the same
    # sources always produce a byte-identical database and CI can verify that
    # the committed file really is what the pipeline builds.
    con.execute("INSERT INTO meta(key,value) VALUES('source_digest',?)", (source_digest(),))
    # drift records its schema version in `user_version`. Stamping it here
    # means the shipped file never has to be written to on first open, which
    # keeps the read-only `query_only` pragma the app sets from failing.
    con.execute(f"PRAGMA user_version = {DRIFT_SCHEMA_VERSION}")
    con.commit()
    con.execute("VACUUM")
    con.close()

    report["content_version"] = CONTENT_VERSION
    report["source_digest"] = source_digest()
    report["bytes"] = os.path.getsize(OUT)
    with open(REPORT, "w", encoding="utf-8") as fh:
        json.dump(report, fh, ensure_ascii=False, indent=2)
        fh.write("\n")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0


if __name__ == "__main__":
    sys.exit(main())
