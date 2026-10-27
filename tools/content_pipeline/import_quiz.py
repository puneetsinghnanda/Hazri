#!/usr/bin/env python3
"""Import the owner's quiz bank into content/source/quiz/ (14-quiz.md QZ4).

The spreadsheet (`Hazri_Sikh_Quiz_Question_Bank.xlsx`, sheet "All Questions")
is the owner's working copy and stays with the owner; what git holds, and
what build_content_db.py reads, is one JSON file per topic written here.

A new spreadsheet is imported in full. Every id already in the JSON must be
in it (QZ5): a question that is gone is marked `retired`, never deleted, and
a question that is new gets `since` = the content version that will first
ship it. `topics.json` and `days.json` are written by hand and not touched.

Usage:  python3 tools/content_pipeline/import_quiz.py <bank.xlsx> [--since N]
"""
from __future__ import annotations

import argparse
import json
import os
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
QUIZ_DIR = os.path.join(ROOT, "content", "source", "quiz")

# The bank's category column, as the owner wrote it, to the topic id.
CATEGORY_TO_TOPIC = {
    "Guru Nanak Dev Ji": "guru-nanak-dev-ji",
    "Guru Angad Dev Ji": "guru-angad-dev-ji",
    "Guru Amar Das Ji": "guru-amar-das-ji",
    "Guru Ram Das Ji": "guru-ram-das-ji",
    "Guru Arjan Dev Ji": "guru-arjan-dev-ji",
    "Guru Hargobind Sahib Ji": "guru-hargobind-sahib-ji",
    "Guru Har Rai Ji": "guru-har-rai-ji",
    "Guru Har Krishan Ji": "guru-har-krishan-ji",
    "Guru Tegh Bahadur Ji": "guru-tegh-bahadur-ji",
    "Guru Gobind Singh Ji": "guru-gobind-singh-ji",
    "Sri Guru Granth Sahib Ji": "sri-guru-granth-sahib-ji",
    "Five Takhts": "five-takhts",
    "Historic Gurdwaras": "historic-gurdwaras",
    "Sikh Banis": "sikh-banis",
    "Sikh Heroes": "sikh-heroes",
    "Sikh History": "sikh-history",
    "Sikh Culture & Practices": "sikh-culture",
}

HEADERS = {
    "ID": "id", "Category": "category", "Difficulty": "difficulty", "Question": "question",
    "Option A": "A", "Option B": "B", "Option C": "C", "Option D": "D", "Answer": "answer",
    "Explanation": "explanation", "Source": "source", "Source URL": "url",
    "Second source URL": "url2", "Notes / caveats": "note",
}


def text(v) -> str:
    return "" if v is None else " ".join(str(v).split())


def read_bank(path: str) -> list[dict]:
    import openpyxl  # only the importer needs it; the pipeline reads JSON

    sheet = openpyxl.load_workbook(path, read_only=True, data_only=True)["All Questions"]
    rows = sheet.iter_rows(values_only=True)
    header = [text(h) for h in next(rows)]
    missing = [h for h in HEADERS if h not in header]
    if missing:
        raise SystemExit(f"bank: missing columns {missing}")
    col = {HEADERS[h]: header.index(h) for h in HEADERS}
    out = []
    for r in rows:
        if not r or not text(r[col["id"]]):
            continue
        q = {k: text(r[i]) for k, i in col.items()}
        out.append(q)
    return out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("xlsx")
    ap.add_argument("--since", type=int, default=10, help="content version a new question first ships in")
    args = ap.parse_args()

    bank = read_bank(args.xlsx)
    existing: dict[str, dict] = {}
    if os.path.isdir(QUIZ_DIR):
        for topic in CATEGORY_TO_TOPIC.values():
            path = os.path.join(QUIZ_DIR, f"{topic}.json")
            if os.path.exists(path):
                with open(path, encoding="utf-8") as fh:
                    for q in json.load(fh)["questions"]:
                        existing[q["id"]] = q

    by_topic: dict[str, list[dict]] = {t: [] for t in CATEGORY_TO_TOPIC.values()}
    seen = set()
    for q in bank:
        if q["id"] in seen:
            raise SystemExit(f"bank: {q['id']} appears twice")
        seen.add(q["id"])
        topic = CATEGORY_TO_TOPIC.get(q["category"])
        if topic is None:
            raise SystemExit(f"bank: {q['id']} has an unknown category {q['category']!r}")
        old = existing.get(q["id"])
        if old and old["topic"] != topic:
            raise SystemExit(f"bank: {q['id']} moved from {old['topic']} to {topic}; give it a new id (QZ5)")
        by_topic[topic].append({
            "id": q["id"],
            "topic": topic,
            "difficulty": q["difficulty"].lower(),
            "question": q["question"],
            "options": [q["A"], q["B"], q["C"], q["D"]],
            "answer": q["answer"].upper(),
            "explanation": q["explanation"],
            "source": q["source"],
            "url": q["url"] or None,
            "url2": q["url2"] or None,
            "note": q["note"] or None,
            "retired": False,
            "since": old["since"] if old else args.since,
        })
    for qid, old in existing.items():
        if qid not in seen:
            by_topic[old["topic"]].append({**old, "retired": True})
            print(f"retired {qid}", file=sys.stderr)

    os.makedirs(QUIZ_DIR, exist_ok=True)
    for topic, qs in by_topic.items():
        qs.sort(key=lambda q: int(q["id"].lstrip("Q")))
        with open(os.path.join(QUIZ_DIR, f"{topic}.json"), "w", encoding="utf-8") as fh:
            json.dump({"topic": topic, "questions": qs}, fh, ensure_ascii=False, indent=1)
            fh.write("\n")
    print(f"{len(bank)} questions in {len(by_topic)} topics")
    return 0


if __name__ == "__main__":
    sys.exit(main())
