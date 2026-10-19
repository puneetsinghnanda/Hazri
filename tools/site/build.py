"""Builds the website in public/ from template.html and the data beside it:
the home page (public/index.html) and, through articles.py, a story page for
every day of the calendar at /gurpurab/<slug>, their index at /gurpurab, the
sitemap and robots.txt.

    python3 tools/site/build.py

The phone screens it shows are public/img/*.webp. Nothing here is the app:
the pages go live only with `firebase deploy --only hosting`.
"""
import json
from pathlib import Path

import articles

here = Path(__file__).resolve().parent
public = here.parent.parent / 'public'
cal = articles.build(here, public, json.loads((here / 'cal.json').read_text()))
page = (here / 'template.html').read_text()
page = page.replace('__CAL__', json.dumps(cal, ensure_ascii=False, separators=(',', ':')))
for key, name in [('__HELPERS__', 'parts_helpers.js'), ('__BUILD__', 'parts_build.js'),
                  ('__SCENES__', 'scenes.min.json'), ('__WORLD__', 'world.json'),
                  ('__BLOG__', 'blog.json'), ('__GUIDES__', 'guides.json')]:
    page = page.replace(key, (here / name).read_text())
out = public / 'index.html'
out.write_text(page)
print(f'{out}: {len(page)} characters')
