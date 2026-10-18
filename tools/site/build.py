"""Builds public/index.html, the home page at hazri-dfcc1.web.app (and hazri.me
once the domain is connected), from template.html and the data beside it.

    python3 tools/site/build.py

The phone screens it shows are public/img/*.webp. Nothing here is the app:
the page goes live only with `firebase deploy --only hosting`.
"""
from pathlib import Path

here = Path(__file__).resolve().parent
page = (here / 'template.html').read_text()
for key, name in [('__HELPERS__', 'parts_helpers.js'), ('__BUILD__', 'parts_build.js'),
                  ('__SCENES__', 'scenes.min.json'), ('__WORLD__', 'world.json'),
                  ('__CAL__', 'cal.json'), ('__BLOG__', 'blog.json'), ('__GUIDES__', 'guides.json')]:
    page = page.replace(key, (here / name).read_text())
out = here.parent.parent / 'public' / 'index.html'
out.write_text(page)
print(f'{out}: {len(page)} characters')
