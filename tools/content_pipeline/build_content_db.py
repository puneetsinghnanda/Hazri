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
VERIFIED_FILE = os.path.join(TIMINGS_DIR, "verified.json")
VICHAR_DIR = os.path.join(ROOT, "content", "source", "vichar")
SAAKHI_DIR = os.path.join(ROOT, "content", "source", "saakhi")
SAAKHI_ASSETS = os.path.join(ROOT, "assets", "saakhi")
QUIZ_DIR = os.path.join(ROOT, "content", "source", "quiz")
ARTICLES_DIR = os.path.join(ROOT, "tools", "site", "articles")
# The quiz's answer key goes to the api Function too, as the Vichar library does
# (14-quiz.md QZ4): the server draws and scores, the phone shows.
QUIZ_BANK_OUT = os.path.join(ROOT, "functions", "src", "quiz-bank.json")
# The order Today's row and the library show them in (owner, 2026-10-25).
SAAKHI_ORDER = ["bhai-lalo-malik-bhago", "anand-bhaya-meri-maaye", "why-was-the-hut-broken", "the-saint-soldier"]

CONTENT_VERSION = 10

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
  name_en TEXT NOT NULL, name_pa TEXT, name_hi TEXT,
  ns_label TEXT, default_remind INTEGER NOT NULL DEFAULT 1,
  supplementary INTEGER NOT NULL DEFAULT 0);
CREATE INDEX calendar_event_date ON calendar_event(date);

CREATE TABLE city(
  id TEXT PRIMARY KEY, name_en TEXT NOT NULL, name_pa TEXT NOT NULL, name_hi TEXT NOT NULL,
  country_code TEXT NOT NULL, lat REAL NOT NULL, lon REAL NOT NULL, tz TEXT NOT NULL);

CREATE TABLE quote(
  id TEXT PRIMARY KEY, gurmukhi TEXT NOT NULL, devanagari TEXT NOT NULL, roman TEXT NOT NULL,
  attribution_en TEXT, attribution_pa TEXT, attribution_hi TEXT, source_id TEXT);

-- A saakhi (13-saakhi.md), resolved: its pages, lesson, narration cues and
-- any Gurbani, read here from the bani's own source file (SK3). One JSON row
-- per saakhi because the reader always wants the whole of one; `sort` is the
-- order Today and the library list them in.
CREATE TABLE saakhi(id TEXT PRIMARY KEY, sort INTEGER NOT NULL, json TEXT NOT NULL);

-- The Gurmat Quiz (14-quiz.md). Topics, the owner's question bank, and which
-- calendar events have a quiz. Sources and reviewer's notes are not shipped
-- (QZ7); `has_note` only keeps a noted question out of the insights (QZ10).
CREATE TABLE quiz_topic(
  id TEXT PRIMARY KEY, category TEXT NOT NULL, sort INTEGER NOT NULL,
  name_en TEXT NOT NULL, name_pa TEXT NOT NULL, name_hi TEXT NOT NULL,
  glyph TEXT NOT NULL, slug TEXT);
CREATE TABLE quiz_question(
  id TEXT PRIMARY KEY, topic_id TEXT NOT NULL REFERENCES quiz_topic(id),
  difficulty TEXT NOT NULL, question TEXT NOT NULL,
  option_a TEXT NOT NULL, option_b TEXT NOT NULL, option_c TEXT NOT NULL, option_d TEXT NOT NULL,
  answer TEXT NOT NULL, explanation TEXT NOT NULL,
  has_note INTEGER NOT NULL, retired INTEGER NOT NULL, since INTEGER NOT NULL);
CREATE INDEX quiz_question_topic ON quiz_question(topic_id);
CREATE TABLE quiz_day(
  event_name TEXT PRIMARY KEY, label_en TEXT NOT NULL, label_pa TEXT NOT NULL, label_hi TEXT NOT NULL,
  topic_id TEXT NOT NULL REFERENCES quiz_topic(id), slug TEXT);

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
            "INSERT OR IGNORE INTO source(id,name,author,kind,licence,url,notes,"
            "publisher,pub_date) VALUES(?,?,?,?,?,?,?,?,?)",
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
    japji_sort = con.execute("SELECT sort FROM bani WHERE id = 'JAPJ'").fetchone()[0]
    base = japji_sort * LINE_ID_BLOCK
    for ln in doc["lines"]:
        idx = ln["id"] - 1
        line_id = base + ln["id"]
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
            (line_id, version_id, idx, labels[0], labels[1], labels[2],
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
                (line_id, lang, payload["text"], payload.get("source"), is_alt, kind, note))

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


# The eight banis whose source files use schema 2.0. The slug is the filename
# under content/source/ and the key into the bani table; the source file's own
# `bani.id` is a Shabad OS id and does not always match ours (its Chaupai is
# CPDT, ours is CHAU), so the slug is what joins them, never that id.
V2_BANIS = [
    "jaap-sahib", "tav-prasad-savaiye", "chaupai-sahib", "anand-sahib",
    "rehras-sahib", "kirtan-sohila", "ardas", "sukhmani-sahib",
]

# Line ids have to be unique across every bani, so each one is given a block.
LINE_ID_BLOCK = 100_000

# A source file may carry more of a bani than the arrangement Hazri ships.
# The Rehras file opens with a shabad and a salok from a longer arrangement;
# the SGPC Rehras, and the recitation that ships with it, both begin at So Dar.
# The line named here is kept and everything before it is dropped, so the
# reader shows the Rehras that is actually recited.
STARTS_AT = {
    "rehras-sahib": "ਸੋ ਦਰੁ ਰਾਗੁ ਆਸਾ ਮਹਲਾ ੧ ॥",
}

# The same in the other direction. The Chaupai Sahib of Nitnem closes on
# ॥੪੦੧॥; this source file carries on into the colophon verses, the ਅੜਿਲ and
# the ਸ੍ਵੈਯਾ, which the recitation does not say. The line named here is kept
# and everything after it is dropped.
ENDS_AT = {
    "chaupai-sahib": "ਦੁਸਟ ਦੋਖ ਤੇ ਲੇਹੁ ਬਚਾਈ ॥੪੦੧॥",
}


def build_bani_v2(con: sqlite3.Connection, slug: str, report: dict) -> None:
    """Loads one schema-2.0 source file into bani, bani_version, line, meaning.

    Schema 2.0 differs from the Japji file in more than field names: it has no
    author, its sections carry no type, and its `unit` numbers are derived
    mechanically from the Gurmukhi numerals in the closing dandas. The source
    file says so itself and warns they are not editorial labels, so they are
    stored as unit numbers and nothing here invents a word for them. A bani
    whose structure has no name shows none, the same way a bani with no
    recording gets no audio row.
    """
    path = os.path.join(SRC, f"{slug}.json")
    with open(path, encoding="utf-8") as fh:
        doc = json.load(fh)
    if doc.get("schema_version") != "2.0":
        raise SystemExit(f"{path}: expected schema_version 2.0")

    bani_id, sort = con.execute(
        "SELECT id, sort FROM bani WHERE slug = ?", (slug,)
    ).fetchone()
    prov = doc["provenance"]

    dropped = 0
    opening = STARTS_AT.get(slug)
    if opening:
        starts = [i for i, ln in enumerate(doc["lines"])
                  if ln["text"]["gurmukhi_plain"].strip() == opening]
        if not starts:
            raise SystemExit(f"{path}: no line reads {opening!r} to start at")
        dropped = starts[0]
        doc["lines"] = doc["lines"][dropped:]

    dropped_after = 0
    closing = ENDS_AT.get(slug)
    if closing:
        ends = [i for i, ln in enumerate(doc["lines"])
                if ln["text"]["gurmukhi_plain"].strip() == closing]
        if not ends:
            raise SystemExit(f"{path}: no line reads {closing!r} to end at")
        keep = ends[-1] + 1
        dropped_after = len(doc["lines"]) - keep
        doc["lines"] = doc["lines"][:keep]

    for code, a in prov["assets"].items():
        con.execute(
            "INSERT OR IGNORE INTO source(id,name,author,kind,licence,url,notes,"
            "publisher,pub_date) VALUES(?,?,?,?,?,?,?,?,?)",
            (code, a.get("name", code), ", ".join(a.get("authors") or []) or None,
             "meaning", None, a.get("url"), None, a.get("publisher"), a.get("date")))

    b = doc["bani"]
    # The English name stays as the PRD and the designs spell it: it is a
    # display label, not scripture. The Gurmukhi and Devanagari names come from
    # the source file.
    con.execute(
        "UPDATE bani SET name_pa=?, name_hi=?, has_text=1 WHERE id=?",
        (b["name"]["gurmukhi"], b["name"]["transliteration_hindi"], bani_id))

    version_id = f"{bani_id}_SGPC"
    con.execute(
        "INSERT INTO bani_version(id,bani_id,code,label_en,label_pa,label_hi,is_default,"
        "line_count) VALUES(?,?,?,?,?,?,1,?)",
        (version_id, bani_id, "sgpc", "SGPC", "ਐਸ.ਜੀ.ਪੀ.ਸੀ.", "एस.जी.पी.सी.",
         len(doc["lines"])))

    base = sort * LINE_ID_BLOCK
    misaligned: list[int] = []
    no_vishraam: list[int] = []
    meanings = {"en": 0, "pa": 0, "hi": 0}

    for idx, ln in enumerate(doc["lines"]):
        line_id = base + ln["id"]
        text = ln["text"]
        plain_words = text["gurmukhi_plain"].split()
        roman = text["transliteration"]["english"]
        dev = text["transliteration"]["hindi"]
        # Word highlighting needs the three scripts to agree word for word.
        # Where they do not, the line still reads; only its words stop being
        # separately highlightable, which is what word_align records.
        aligned = (len(roman.split()) == len(plain_words)
                   and len(dev.split()) == len(plain_words))
        if not aligned:
            misaligned.append(ln["id"])
        marks = parse_vishraam(text["gurmukhi"], plain_words)
        if not marks and any(c in text["gurmukhi"] for c in VISHRAAM):
            no_vishraam.append(ln["id"])

        scripture = ln.get("scripture") or {}
        ref = None
        if scripture.get("asset"):
            page = scripture.get("page")
            ref = scripture["asset"] + (f" {page}" if page else "")

        con.execute(
            "INSERT INTO line(id,bani_version_id,idx,section_label_en,section_label_pa,"
            "section_label_hi,kind,gurmukhi,devanagari,roman,visraam_json,word_count,"
            "word_align,source_id,source_ref,pauri,ends_pauri) "
            "VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
            (line_id, version_id, idx, None, None, None, "verse",
             text["gurmukhi_plain"], dev, roman,
             json.dumps(marks, ensure_ascii=False) if marks else None,
             len(plain_words), 1 if aligned else 0, "SHABADOS", ref,
             ln.get("unit"), 1 if ln.get("ends_unit") else 0))

        m = ln["meaning"]
        rows = [
            ("en", m.get("english"), 0),
            ("en", m.get("english_alt"), 1),
            ("pa", m.get("punjabi"), 0),
            ("pa", m.get("punjabi_alt"), 1),
            ("hi", m.get("hindi"), 0),
        ]
        for lang, payload, is_alt in rows:
            if not payload:
                continue
            con.execute(
                "INSERT INTO meaning(line_id,lang,text,source_id,is_alt,kind,note) "
                "VALUES(?,?,?,?,?,?,?)",
                (line_id, lang, payload["text"], payload.get("source"), is_alt,
                 "translation", None))
            meanings[lang] += 1

    report.setdefault("banis", {})[slug] = {
        "source_bani_id": b["id"],
        "lines": len(doc["lines"]),
        "lines_dropped_before_start": dropped,
        "lines_dropped_after_end": dropped_after,
        "units": b["total_units"],
        "meanings": meanings,
        "word_misaligned_lines": len(misaligned),
        "vishraam_unparsed_lines": len(no_vishraam),
        "hindi_meaning_note": (prov.get("hindi_meaning") or {}).get("note"),
    }


def listened_to(slug: str, lines: list) -> bool:
    """Has a person listened to exactly these timings and accepted them?

    Decided here rather than trusted from the timing file, because the file's
    own flag is written when the aligner runs: marking a bani verified
    afterwards would not have reached it, and re-aligning one that was
    verified would have carried somebody's word onto timings they never heard.
    The hash is over the lines themselves, so either way it answers.
    """
    if not os.path.exists(VERIFIED_FILE):
        return False
    with open(VERIFIED_FILE, encoding="utf-8") as fh:
        recorded = (json.load(fh).get(slug) or {}).get("linesSha")
    if not recorded:
        return False
    payload = json.dumps(lines, ensure_ascii=False, separators=(",", ":"))
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()[:16] == recorded


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
            doc["verified"] = listened_to(slug, doc.get("lines", []))
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
        if duration_ms:
            # est_minutes was a hand-set guess while there was nothing to
            # measure. Now that the recitation ships, the number Nitnem and
            # Today show is how long the recording actually runs, rounded up:
            # a bani is never billed as shorter than it is.
            con.execute(
                "UPDATE bani SET est_minutes = ? WHERE id = ?",
                (max(1, -(-duration_ms // 60000)), bani_id))
        verified = doc["verified"] if timing_json else None
        built.append({
            "bani": slug,
            "bytes": os.path.getsize(audio),
            "duration_ms": duration_ms,
            "has_timings": timing_json is not None,
            # Whether a person has listened to this alignment. Nothing in the
            # app reads it; it is here so the build report says plainly which
            # recitations are still riding on a machine's word (PRD §8).
            "timings_verified": verified,
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
    """The Sikh calendar: Nanakshahi months, and every dated event in them.

    `calendar-558.json` is written from the supplied document by
    `import_calendar_docx.py` and carries the four columns that document gives
    -- Gregorian date, Nanakshahi date, type and event -- plus which entries
    the document marks as supplementary rather than SGPC-confirmed.

    Punjabi lives in `calendar-names.json` and covers ten of the events. The
    rest ship with English only: the document is English, and a name nobody
    has reviewed in Gurmukhi is worse than a name in the language it was
    written in. `name_pa` and `name_hi` are null there and the reader falls
    back, which is the same rule the meanings follow.
    """
    with open(os.path.join(SRC, "calendar-558.json"), encoding="utf-8") as fh:
        doc = json.load(fh)
    with open(os.path.join(SRC, "calendar-names.json"), encoding="utf-8") as fh:
        names = json.load(fh)

    con.execute(
        "INSERT INTO source(id,name,author,kind,licence,url,notes) VALUES(?,?,?,?,?,?,?)",
        ("SGPCCAL", "SGPC Nanakshahi calendar (jantri)", "SGPC", "calendar", None, None,
         doc.get("_note")))

    for m in doc["months"]:
        start = datetime.strptime(m["start"], "%Y-%m-%d").date()
        name_en, name_pa, name_hi = NS_MONTHS[m["idx"]]
        con.execute(
            "INSERT INTO nanakshahi_month(ns_year,idx,name_en,name_pa,name_hi,start_date,days)"
            " VALUES(?,?,?,?,?,?,?)",
            (m["ns_year"], m["idx"], name_en, name_pa, name_hi, start.isoformat(),
             m["days"]))

    # Punjabi is attached on date *and* English text, so a reworded event
    # fails the build rather than quietly taking the wrong Gurmukhi.
    pa_for = {(n["date"], n["en"]): n["pa"] for n in names["names"]}
    seen = set()

    for i, ev in enumerate(doc["events"]):
        key = (ev["date"], ev["en"])
        pa = pa_for.get(key)
        if pa is not None:
            seen.add(key)
        day_s, month_name, ns_year = ev["nanakshahi"].split()
        con.execute(
            "INSERT INTO calendar_event(id,ns_year,date,kind,name_en,name_pa,name_hi,"
            "ns_label,default_remind,supplementary) VALUES(?,?,?,?,?,?,?,?,?,?)",
            (f"ev{i:03d}", int(ns_year), ev["date"], ev["type"], ev["en"], pa, None,
             ev["nanakshahi"], 1 if ev.get("remind") else 0,
             1 if ev.get("supplementary") else 0))

    unused = sorted(set(pa_for) - seen)
    if unused:
        raise SystemExit(
            "calendar-names.json has Punjabi for events that are not in "
            "calendar-558.json, so one of the two has moved:\n  "
            + "\n  ".join(f"{d}  {t}" for d, t in unused))

    kinds: dict[str, int] = {}
    for ev in doc["events"]:
        kinds[ev["type"]] = kinds.get(ev["type"], 0) + 1
    first = datetime.strptime(doc["months"][0]["start"], "%Y-%m-%d").date()
    last = doc["months"][-1]
    report["calendar"] = {
        "events": len(doc["events"]),
        "by_kind": dict(sorted(kinds.items())),
        "with_punjabi": len(seen),
        "supplementary": sum(1 for e in doc["events"] if e.get("supplementary")),
        "reminding_by_default": sum(1 for e in doc["events"] if e.get("remind")),
        "corrections": doc.get("corrections", []),
        "months_covered": [f"{NS_MONTHS[m['idx']][0]} {m['ns_year']}"
                           for m in doc["months"]],
        "covered_from": first.isoformat(),
        "covered_to": (datetime.strptime(last["start"], "%Y-%m-%d").date()
                       + timedelta(days=last["days"] - 1)).isoformat(),
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


def saakhi_line(ref: dict, sources: dict) -> dict:
    """One line of a bani, with its Ang and the meanings the saakhi names by source (SK3)."""
    with open(os.path.join(SRC, f"{ref['bani']}.json"), encoding="utf-8") as fh:
        bani = json.load(fh)
    line = next(l for l in bani["lines"] if l["id"] == ref["id"])
    meanings = {}
    for lang, key in (("en", "english"), ("pa", "punjabi")):
        for variant in (key, f"{key}_alt"):
            m = (line.get("meaning") or {}).get(variant)
            if m and m.get("source") == sources.get(lang):
                meanings[lang] = m["text"]
    return {"lines": [line["text"]["gurmukhi_plain"]], "ang": line["scripture"]["page"],
            "meaning": meanings}


def build_saakhis(con: sqlite3.Connection, report: dict) -> None:
    """The saakhis, each resolved into what the reader needs.

    Gurbani named by `ref` is read from its bani's source file. A shabad typed
    into the saakhi file ships only once it carries a `checked` record naming
    the source it was checked against (SK3, "an unsourced pankti"); until then
    the saakhi shows no Gurbani row. Images and narration must exist as assets
    (tools/saakhi/build_assets.py) or the saakhi is left out.
    """
    built = []
    names = sorted(f[:-5] for f in os.listdir(SAAKHI_DIR) if f.endswith(".json")) \
        if os.path.isdir(SAAKHI_DIR) else []
    order = [n for n in SAAKHI_ORDER if n in names] + [n for n in names if n not in SAAKHI_ORDER]
    for sort, sid in enumerate(order):
        with open(os.path.join(SAAKHI_DIR, f"{sid}.json"), encoding="utf-8") as fh:
            s = json.load(fh)
        asset = lambda key: f"assets/saakhi/{sid}/{key}.webp"
        keys = ["cover"] + [p["image"] for p in s["pages"]] + [s["lesson"]["image"]]
        missing = [k for k in keys if not os.path.exists(os.path.join(SAAKHI_ASSETS, sid, f"{k}.webp"))]
        if missing:
            raise SystemExit(f"saakhi {sid}: no asset for {missing}; run tools/saakhi/build_assets.py")
        sh = s.get("shabad")
        shabad = None
        if sh and "ref" in sh:
            shabad = saakhi_line(sh["ref"], sh["meaning_sources"])
        elif sh and sh.get("checked"):
            shabad = {"lines": sh["gurmukhi"], "ang": sh["ang"], "meaning": sh.get("meaning") or {}}
        if shabad:
            shabad["source"] = sh["source"]
        pages = []
        for p in s["pages"]:
            page = {"title": p["title"], "text": p["text"], "image": asset(p["image"])}
            if p.get("gurbani"):
                page["gurbani"] = saakhi_line(p["gurbani"]["ref"], (sh or {}).get("meaning_sources", {}))
            pages.append(page)
        narration = {}
        for lang, n in (s.get("narration") or {}).items():
            if not isinstance(n, dict) or not n.get("file"):
                continue
            path = os.path.join(SAAKHI_ASSETS, f"{sid}.{lang}.m4a")
            if not os.path.exists(path):
                raise SystemExit(f"saakhi {sid}: no narration asset {path}")
            narration[lang] = {"asset": f"assets/saakhi/{sid}.{lang}.m4a",
                               "duration": n["duration"], "pageStarts": n["page_starts"],
                               "meaningAt": n.get("meaning_at") if shabad else None}
        doc = {
            "id": sid, "title": s["title"], "subtitle": s["subtitle"], "blurb": s["blurb"],
            "languages": sorted(s["title"].keys()),
            "cover": {"image": asset("cover"), "titleInImage": bool(s["images"]["cover"].get("title_in_image"))},
            "pages": pages,
            "lesson": {"title": s["lesson"]["title"], "line": s["lesson"]["line"],
                       "ask": s["lesson"]["ask"], "image": asset(s["lesson"]["image"])},
            "shabad": shabad, "narration": narration,
        }
        con.execute("INSERT INTO saakhi(id,sort,json) VALUES(?,?,?)",
                    (sid, sort, json.dumps(doc, ensure_ascii=False, separators=(",", ":"))))
        built.append({"id": sid, "pages": len(pages), "shabad": bool(shabad),
                      "narration": sorted(narration)})
    report["saakhis"] = built


QUIZ_CATEGORIES = ("gurus", "gurdwaras", "banis", "heroes", "culture")
QUIZ_DIFFICULTIES = ("easy", "medium", "hard")


def has_gurmukhi(text: str) -> bool:
    return any("\u0a00" <= ch <= "\u0a7f" for ch in text)


def build_quiz(con: sqlite3.Connection, report: dict) -> None:
    """The Gurmat Quiz (14-quiz.md QZ4): topics, questions and the day map.

    Fails on any broken reference: an unknown topic, an event that is not in
    the calendar, a Vichar page that is not in tools/site/articles/, an answer
    that is not one of the four, or Gurmukhi in a question, option or
    explanation (QZ2). Writes the same questions, with their answers, to
    functions/src/quiz-bank.json for the api Function.
    """
    with open(os.path.join(QUIZ_DIR, "topics.json"), encoding="utf-8") as fh:
        topics = json.load(fh)["topics"]
    with open(os.path.join(QUIZ_DIR, "days.json"), encoding="utf-8") as fh:
        days = json.load(fh)["days"]
    slugs: set[str] = set()
    for name in sorted(os.listdir(ARTICLES_DIR)):
        if name.endswith(".json"):
            with open(os.path.join(ARTICLES_DIR, name), encoding="utf-8") as fh:
                slugs.update(a["slug"] for a in json.load(fh))
    events = {r[0] for r in con.execute("SELECT name_en FROM calendar_event")}

    topic_ids = set()
    for t in topics:
        if t["category"] not in QUIZ_CATEGORIES:
            raise SystemExit(f"quiz: topic {t['id']} has an unknown category {t['category']}")
        if t["slug"] is not None and t["slug"] not in slugs:
            raise SystemExit(f"quiz: topic {t['id']} names Vichar page {t['slug']}, which does not exist")
        topic_ids.add(t["id"])
        con.execute(
            "INSERT INTO quiz_topic(id,category,sort,name_en,name_pa,name_hi,glyph,slug) VALUES(?,?,?,?,?,?,?,?)",
            (t["id"], t["category"], t["sort"], t["name"]["en"], t["name"]["pa"], t["name"]["hi"],
             t["glyph"], t["slug"]))

    bank = []
    seen = set()
    for t in sorted(topics, key=lambda t: t["sort"]):
        with open(os.path.join(QUIZ_DIR, f"{t['id']}.json"), encoding="utf-8") as fh:
            questions = json.load(fh)["questions"]
        live = {d: 0 for d in QUIZ_DIFFICULTIES}
        for q in questions:
            qid = q["id"]
            if qid in seen:
                raise SystemExit(f"quiz: {qid} appears twice")
            seen.add(qid)
            if q["topic"] != t["id"]:
                raise SystemExit(f"quiz: {qid} is in {t['id']}.json but names topic {q['topic']}")
            if q["difficulty"] not in QUIZ_DIFFICULTIES:
                raise SystemExit(f"quiz: {qid} has difficulty {q['difficulty']}")
            if q["answer"] not in ("A", "B", "C", "D") or len(q["options"]) != 4 or not all(q["options"]):
                raise SystemExit(f"quiz: {qid} needs four options and an answer among A to D")
            if not q["question"] or not q["explanation"]:
                raise SystemExit(f"quiz: {qid} has no question or no explanation")
            if any(has_gurmukhi(x) for x in [q["question"], q["explanation"], *q["options"]]):
                raise SystemExit(f"quiz: {qid} carries Gurmukhi; a question never quotes Gurbani (QZ2)")
            if not q["retired"]:
                live[q["difficulty"]] += 1
            con.execute(
                "INSERT INTO quiz_question(id,topic_id,difficulty,question,option_a,option_b,option_c,option_d,"
                "answer,explanation,has_note,retired,since) VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)",
                (qid, t["id"], q["difficulty"], q["question"], *q["options"], q["answer"],
                 q["explanation"], 1 if q.get("note") else 0, 1 if q["retired"] else 0, q["since"]))
            bank.append({"id": qid, "topic": t["id"], "difficulty": q["difficulty"], "answer": q["answer"],
                         "retired": q["retired"], "since": q["since"]})
        if sum(live.values()) < 5:
            raise SystemExit(f"quiz: topic {t['id']} has fewer than five live questions")
    missing = topic_ids - {q["topic"] for q in bank}
    if missing:
        raise SystemExit(f"quiz: topics with no questions: {sorted(missing)}")

    named = set()
    for d in days:
        if d["event"] in named:
            raise SystemExit(f"quiz: {d['event']} appears twice in days.json")
        named.add(d["event"])
        if d["event"] not in events:
            raise SystemExit(f"quiz: days.json names {d['event']!r}, which is not in the calendar")
        if d["topic"] not in topic_ids:
            raise SystemExit(f"quiz: days.json maps {d['event']!r} to unknown topic {d['topic']}")
        if d["slug"] is not None and d["slug"] not in slugs:
            raise SystemExit(f"quiz: days.json names Vichar page {d['slug']}, which does not exist")
        con.execute(
            "INSERT INTO quiz_day(event_name,label_en,label_pa,label_hi,topic_id,slug) VALUES(?,?,?,?,?,?)",
            (d["event"], d["label"]["en"], d["label"]["pa"], d["label"]["hi"], d["topic"], d["slug"]))

    # QZ7: the bank is credited once in About, not question by question.
    con.execute(
        "INSERT INTO source(id,name,author,kind,licence,url,notes) VALUES(?,?,?,?,?,?,?)",
        ("QUIZBANK", "Gurmat Quiz question bank", None, "quiz", None, None,
         "Prepared for Hazri and checked against published references, among them the "
         "Encyclopaedia of Sikhism (Punjabi University), The Sikh Encyclopedia, SGPC, "
         "Britannica and Sikhs.org."))

    with open(QUIZ_BANK_OUT, "w", encoding="utf-8") as fh:
        json.dump({"contentVersion": CONTENT_VERSION,
                   "topics": [t["id"] for t in sorted(topics, key=lambda t: t["sort"])],
                   "questions": bank}, fh, ensure_ascii=False, separators=(",", ":"))
        fh.write("\n")
    report["quiz"] = {"topics": len(topics), "questions": len(bank), "days": len(days)}


def source_digest() -> str:
    """sha256 over every input that can change the database."""
    h = hashlib.sha256()
    inputs = [
        os.path.join(SRC, "japji_sahib.json"),
        *(os.path.join(SRC, f"{slug}.json") for slug in V2_BANIS),
        os.path.join(SRC, "gurpurab-558.json"),
        os.path.join(os.path.dirname(__file__), "cities.json"),
        os.path.abspath(__file__),
    ]
    for folder in (TIMINGS_DIR, SIMRAN_DIR, VICHAR_DIR, SAAKHI_DIR, QUIZ_DIR, ARTICLES_DIR):
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
    for slug in V2_BANIS:
        build_bani_v2(con, slug, report)
    build_audio(con, report)
    build_simran(con, report)
    build_vichar(con, report)
    build_calendar(con, report)
    build_cities(con, report)
    build_saakhis(con, report)
    build_quiz(con, report)

    con.execute("INSERT INTO meta(key,value) VALUES('content_version',?)", (str(CONTENT_VERSION),))
    # A digest of the inputs rather than a wall-clock timestamp, so the same
    # sources always produce a byte-identical database and CI can verify that
    # the committed file really is what the pipeline builds.
    con.execute("INSERT INTO meta(key,value) VALUES('source_digest',?)", (source_digest(),))
    # ੴ for the share card's watermark, lifted from the bani rather than typed
    # into Dart: no Gurbani character is authored in the app (§0.3).
    ik = con.execute(
        "SELECT gurmukhi FROM line WHERE gurmukhi LIKE ? LIMIT 1", ("\u0a74%",)
    ).fetchone()
    if ik:
        con.execute("INSERT INTO meta(key,value) VALUES('ik_onkar',?)", (ik[0][0],))
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
