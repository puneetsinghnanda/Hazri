"""Reads what the Instagram posts show, straight from the app's own sources,
and prints it as JSON for build.js.

Every pankti and meaning comes from assets/content/content.db (CLAUDE.md
rule 3): nothing here is typed in, paraphrased or translated. The calendar's
story lines come from tools/site/articles/, the same text as hazri.me.

    python3 tools/social/export.py > /dev/null   # build.js runs it itself
"""
import glob
import json
import os
import sqlite3
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))


def main():
    db = sqlite3.connect(os.path.join(ROOT, 'assets', 'content', 'content.db'))
    db.row_factory = sqlite3.Row
    rows = lambda sql: [dict(r) for r in db.execute(sql)]

    vichar = rows('SELECT idx, gurmukhi, meaning_pa, meaning_en FROM vichar ORDER BY idx')
    events = rows(
        'SELECT id, date, kind, name_en, name_pa, ns_label, default_remind '
        'FROM calendar_event WHERE supplementary = 0 ORDER BY date, id')
    quiz = rows(
        'SELECT q.id, q.topic_id, q.difficulty, q.question, q.option_a, q.option_b, '
        'q.option_c, q.option_d, q.answer, q.explanation, t.name_en AS topic, '
        't.name_pa AS topic_pa, t.glyph, t.slug '
        'FROM quiz_question q JOIN quiz_topic t ON t.id = q.topic_id '
        'WHERE q.retired = 0 ORDER BY t.sort, q.id')
    saakhi = []
    for r in db.execute('SELECT id, json FROM saakhi ORDER BY sort'):
        j = json.loads(r['json'])
        saakhi.append({'id': r['id'], 'title': j['title'], 'subtitle': j['subtitle'],
                       'cover': j['cover']['image']})

    # Event name -> its story page on hazri.me.
    stories = {}
    for f in sorted(glob.glob(os.path.join(ROOT, 'tools', 'site', 'articles', '*.json'))):
        for a in json.load(open(f, encoding='utf-8')):
            for name in a.get('events', []):
                stories.setdefault(name, {'slug': a['slug'], 'desc': a['desc']})

    json.dump({'vichar': vichar, 'events': events, 'quiz': quiz, 'saakhi': saakhi,
               'stories': stories}, sys.stdout, ensure_ascii=False)


if __name__ == '__main__':
    main()
