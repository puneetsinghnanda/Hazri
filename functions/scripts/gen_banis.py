#!/usr/bin/env python3
"""Writes functions/src/banis.json from assets/content/content.db (read-only).

The server needs bani ids (to validate a group goal) and bani names (the admin
goal form, 11-admin.md 4.2, and `{bani}` in a Sangat push, 02-notifications.md
5.5). Names come from content.db and nowhere else (CLAUDE.md rule 3), so this
file is generated, never typed.
"""
import json
import pathlib
import sqlite3

here = pathlib.Path(__file__).resolve().parent
db = here.parent.parent / "assets" / "content" / "content.db"
out = here.parent / "src" / "banis.json"

con = sqlite3.connect(f"file:{db}?mode=ro", uri=True)
rows = con.execute(
    "select id, name_en, name_pa, name_hi, default_slot from bani order by sort"
).fetchall()
banis = [
    {"id": r[0], "en": r[1], "pa": r[2], "hi": r[3], "defaultSlot": r[4]}
    for r in rows
]
out.write_text(json.dumps(banis, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
print(f"gen_banis: wrote {len(banis)} banis to {out}")
