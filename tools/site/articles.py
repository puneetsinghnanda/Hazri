"""The story pages at /gurpurab/: one page for each day in cal.json, an index,
the sitemap and robots.txt. Called by build.py; never run on its own.

Each page is written from tools/site/articles/*.json. An article names the
calendar events it tells the story of by their exact `n`, so one page can
serve several days (the twelve Sangrands, a Jorh Mela held on two days), and
the build fails if any event is left without a page or an article names an
event the calendar does not have.

An article's `img` is a Wikimedia Commons file name, shown from Commons with a
credit; with none, the page draws its own illustration. Nothing here is
Gurbani and no picture is of a Guru (CLAUDE.md rule 3): the photographs are
of places.
"""
import html
import json
import random
import re
from datetime import date
from pathlib import Path
from urllib.parse import quote

SITE = 'https://hazri.me'
PLAY = 'https://play.google.com/store/apps/details?id=app.hazri'
UPDATED = '2026-10-19'

MONTHS = ['Chet', 'Vaisakh', 'Jeth', 'Harh', 'Sawan', 'Bhadon', 'Assu', 'Katak', 'Maghar', 'Poh', 'Magh', 'Phagan']
KIND = {'prakash': 'Prakash Purab', 'gurgaddi': 'Gurgaddi', 'joti-jot': 'Joti Jot', 'shaheedi': 'Shaheedi',
        'birth': 'Birth anniversary', 'historical': 'Day in history', 'special': 'Special day', 'jor-mela': 'Jor Mela',
        'festival': 'Festival', 'sangrand': 'Sangrand', 'puranmashi': 'Puranmashi', 'masya': 'Masya'}
GROUP_NAME = {'gurpurab': 'Gurpurab', 'shaheedi': 'Shaheedi', 'panth': 'Day of the Panth', 'monthly': 'Every month'}


def group(t):
    if t in ('prakash', 'gurgaddi', 'joti-jot'):
        return 'gurpurab'
    if t == 'shaheedi':
        return 'shaheedi'
    if t in ('sangrand', 'puranmashi', 'masya'):
        return 'monthly'
    return 'panth'


def remind_at(e):
    return ('06:00' if group(e['t']) == 'gurpurab' else '07:00') if e.get('r') else ''


def long_date(s):
    d = date.fromisoformat(s)
    return f"{d.strftime('%A')}, {d.day} {d.strftime('%B %Y')}"


def esc(s):
    return html.escape(s, quote=True)


def inline(s):
    """Escapes a line of article text, then turns [words](/path) into a link."""
    return re.sub(r'\[([^\]]+)\]\((/[^)\s]*)\)', r'<a href="\2">\1</a>', esc(s))


def body_html(lines):
    out, items = [], []
    for line in lines + ['']:
        if line.startswith('- '):
            items.append(f'<li>{inline(line[2:])}</li>')
            continue
        if items:
            out.append('<ul>' + ''.join(items) + '</ul>')
            items = []
        if line.startswith('## '):
            out.append(f'<h2>{inline(line[3:])}</h2>')
        elif line:
            out.append(f'<p>{inline(line)}</p>')
    return '\n'.join(out)


def plain(s):
    return re.sub(r'\[([^\]]+)\]\([^)]*\)', r'\1', s)


MARK = ('<svg width="30" height="30" viewBox="0 0 40 40" aria-hidden="true"><path d="M4 27A16 16 0 0 1 36 27" fill="none" '
        'stroke="#F3F1FA" stroke-width="2.4" stroke-linecap="round"/><path d="M6 31.5H34" fill="none" stroke="#F3F1FA" '
        'stroke-width="2.4" stroke-linecap="round"/><path d="M12 27A8 8 0 0 1 28 27Z" fill="#F2A24E"/></svg>')
PLAY_ICON = ('<svg width="26" height="28" viewBox="0 0 26 28" aria-hidden="true"><path d="M1 1.5l13.2 12.5L1 26.5c-.6-.3-1-.9-1-1.7V3.2'
             'c0-.8.4-1.4 1-1.7z" fill="#3BCCFF"/><path d="M18.6 9.8L14.2 14 1 1.5c.4-.2 1-.2 1.5.1z" fill="#48FF48"/>'
             '<path d="M18.6 18.2L2.5 27.4c-.5.3-1.1.3-1.5.1L14.2 14z" fill="#FF3A44"/><path d="M18.6 9.8l5.4 3.1c1.3.7 1.3 '
             '1.5 0 2.2l-5.4 3.1L14.2 14z" fill="#FFD400"/></svg>')

SKIES = {
    'gurpurab': ['#070A1E', '#232659', '#5E3550', '#D9730D'],
    'shaheedi': ['#070A1E', '#2A1838', '#6B2A2A', '#C2560A'],
    'panth': ['#070A1E', '#10143A', '#2E3D73', '#8C4524'],
    'monthly': ['#05071A', '#0E1236', '#232659', '#3B2F5C'],
}


def illustration(slug, grp, kind, label):
    """A dawn over a gurdwara, drawn for a page with no photograph."""
    rnd = random.Random(slug)
    sky = SKIES[grp]
    stars = ''.join(f'<circle cx="{rnd.randint(0, 1600)}" cy="{rnd.randint(0, 520)}" r="{rnd.choice([1.2, 1.6, 2.2])}" '
                    f'fill="#F3F1FA" opacity="{rnd.choice([.35, .55, .8])}"/>' for _ in range(70))
    if kind == 'puranmashi':
        light = '<circle cx="1180" cy="230" r="86" fill="#FFF4DC"/><circle cx="1180" cy="230" r="150" fill="#FFF4DC" opacity=".12"/>'
    elif kind == 'masya':
        light = '<circle cx="1180" cy="230" r="80" fill="none" stroke="#C6C5DD" stroke-width="2" opacity=".5"/>'
    else:
        light = ('<ellipse cx="800" cy="700" rx="560" ry="300" fill="url(#glow)"/>'
                 '<path d="M540 700A260 260 0 0 1 1060 700Z" fill="#F2A24E" opacity=".75"/>')
    lit = '#F2A24E' if kind != 'masya' else '#C6C5DD'
    return f'''<svg viewBox="0 0 1600 900" role="img" aria-label="{esc(label)}" preserveAspectRatio="xMidYMid slice">
<defs><linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{sky[0]}"/><stop offset=".45" stop-color="{sky[1]}"/>
<stop offset=".72" stop-color="{sky[2]}"/><stop offset="1" stop-color="{sky[3]}"/></linearGradient>
<radialGradient id="glow" cx=".5" cy="1" r=".6"><stop offset="0" stop-color="#FFBE6E" stop-opacity=".85"/><stop offset=".5" stop-color="#F2A24E" stop-opacity=".3"/>
<stop offset="1" stop-color="#F2A24E" stop-opacity="0"/></radialGradient></defs>
<rect width="1600" height="900" fill="url(#sky)"/>{stars}{light}
<g fill="#0B0E26"><rect x="0" y="700" width="1600" height="200"/><rect x="540" y="560" width="520" height="140"/>
<rect x="690" y="480" width="220" height="80"/><path d="M690 480C690 390 750 350 800 300C850 350 910 390 910 480Z"/>
<rect x="797" y="240" width="6" height="64"/><circle cx="800" cy="236" r="10"/>
<rect x="560" y="515" width="50" height="45"/><path d="M560 515C560 490 585 478 585 458C585 478 610 490 610 515Z"/>
<rect x="990" y="515" width="50" height="45"/><path d="M990 515C990 490 1015 478 1015 458C1015 478 1040 490 1040 515Z"/>
<rect x="1236" y="330" width="8" height="370"/></g>
<path d="M1244 336L1360 372L1244 408Z" fill="#D9730D"/>
<g fill="{lit}" opacity=".85"><path d="M770 700V640A30 30 0 0 1 830 640V700Z"/><path d="M640 680V630A20 20 0 0 1 680 630V680Z"/>
<path d="M920 680V630A20 20 0 0 1 960 630V680Z"/><path d="M760 540V515A12 12 0 0 1 784 515V540Z"/><path d="M816 540V515A12 12 0 0 1 840 515V540Z"/></g>
<rect x="0" y="698" width="1600" height="3" fill="{lit}" opacity=".35"/>
</svg>'''


def head(title, desc, canonical, image, extra=''):
    return f'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>{esc(title)}</title>
<meta name="description" content="{esc(desc)}">
<link rel="canonical" href="{canonical}">
<meta property="og:type" content="article">
<meta property="og:site_name" content="Hazri">
<meta property="og:title" content="{esc(title)}">
<meta property="og:description" content="{esc(desc)}">
<meta property="og:url" content="{canonical}">
{f'<meta property="og:image" content="{esc(image)}">' if image else ''}
<meta name="twitter:card" content="{'summary_large_image' if image else 'summary'}">
<meta name="theme-color" content="#10143A">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Baloo+Paaji+2:wght@600;700&family=Mukta:wght@400;500;600&display=swap">
<link rel="stylesheet" href="/stories.css">
{extra}</head>
<body>
<header class="top"><div class="wrap nav">
<a class="brand" href="/" aria-label="Hazri home">{MARK} Hazri</a>
<ul><li><a href="/">Home</a></li><li><a href="/#features">Features</a></li><li><a href="/#gurpurab">Calendar</a></li><li><a href="/gurpurab">All stories</a></li></ul>
<a class="btn" href="{PLAY}">Get the app</a>
</div></header>
'''


FOOT = '''<div class="wrap"><footer>
<span>hazri.me · Mark your Hazri to Waheguru</span>
<span>Dates follow the SGPC’s Nanakshahi calendar for 558. Every line of Gurbani in Hazri comes from reviewed sources.</span>
</footer></div>
</body>
</html>
'''


def poster(art):
    when = 'on the morning of the day' if art['remind'] else 'on every Gurpurab of the year'
    return f'''<section class="poster" aria-labelledby="poster-h">
<small>Every day, before Waheguru</small>
<h2 id="poster-h">Mark your Hazri to Waheguru</h2>
<p>Stand before Waheguru every day, not only on days like this one. Hazri keeps your Nitnem on your phone with a recitation to read along with, marks your daily hazri, and reminds you {when}.</p>
<ul><li>Nitnem with audio</li><li>Gurpurab reminders</li><li>Paath with the sangat</li><li>No login, no ads</li></ul>
<a class="play" href="{PLAY}">{PLAY_ICON}<span><small>Get it on</small><b>Google Play</b></span></a>
</section>'''


def image_of(art):
    img = art.get('img')
    if not img:
        return None
    return f"https://commons.wikimedia.org/wiki/Special:FilePath/{quote(img)}?width=1280"


def figure(art):
    label = art.get('alt') or art['title']
    art_svg = illustration(art['slug'], art['group'], art['kind'], label)
    url = image_of(art)
    if not url:
        return f'<figure>{art_svg}</figure>'
    page = f"https://commons.wikimedia.org/wiki/File:{quote(art['img'].replace(' ', '_'))}"
    cap = esc(art.get('cap') or label)
    # If Commons does not answer, the drawing takes the photograph's place.
    return (f'<figure><img src="{esc(url)}" alt="{esc(label)}" width="1280" height="720" decoding="async" '
            f'onerror="this.parentNode.querySelector(\'figcaption\').remove();this.replaceWith(this.nextElementSibling.content.cloneNode(true))">'
            f'<template>{art_svg}</template>'
            f'<figcaption>{cap}. Photo: <a href="{esc(page)}" rel="noopener">Wikimedia Commons</a>, '
            f'where its author and licence are recorded.</figcaption></figure>')


def json_ld(art, canonical, image):
    data = [{
        '@context': 'https://schema.org', '@type': 'Article', 'headline': art['title'], 'description': art['desc'],
        'mainEntityOfPage': canonical, 'datePublished': UPDATED, 'dateModified': UPDATED, 'inLanguage': 'en',
        'author': {'@type': 'Organization', 'name': 'Hazri', 'url': SITE},
        'publisher': {'@type': 'Organization', 'name': 'Hazri', 'url': SITE},
        'about': art['events'][0]['n'], 'keywords': ', '.join(art.get('kw', [])),
        **({'image': [image]} if image else {}),
    }, {
        '@context': 'https://schema.org', '@type': 'BreadcrumbList', 'itemListElement': [
            {'@type': 'ListItem', 'position': 1, 'name': 'Hazri', 'item': SITE + '/'},
            {'@type': 'ListItem', 'position': 2, 'name': 'Gurpurab calendar', 'item': SITE + '/gurpurab'},
            {'@type': 'ListItem', 'position': 3, 'name': art['title'], 'item': canonical}]}]
    return ''.join(f'<script type="application/ld+json">{json.dumps(d, ensure_ascii=False)}</script>\n' for d in data)


def facts(art):
    evs = art['events']
    rows = []
    if art['group'] == 'monthly':
        rows.append(('Comes', 'Every month' if len(evs) > 2 else 'Twice a year'))
        nxt = next((e for e in evs if e['d'] >= UPDATED), evs[-1])
        rows.append(('Next', f"{long_date(nxt['d'])} · {nxt['ns']}"))
    else:
        rows.append(('Date' if len(evs) == 1 else 'Dates', [f"{long_date(e['d'])} · {e['ns']}" for e in evs]))
    rows.append(('Kind', KIND[evs[0]['t']]))
    rows.append(('Hazri reminds you', f"at {art['remind']}, on the day" if art['remind'] else 'no reminder by default'))
    dl = ''.join(f'<dt>{esc(k)}</dt><dd>{"<br>".join(map(esc, v)) if isinstance(v, list) else esc(v)}</dd>' for k, v in rows)
    return f'<section class="facts"><h3>In Nanakshahi 558</h3><dl>{dl}</dl></section>'


def date_table(art):
    rows = ''.join(f"<tr><td>{esc(long_date(e['d']))}</td><td>{esc(e['ns'])}</td></tr>" for e in art['events'])
    return (f'<h2>{esc(KIND[art["kind"]])} dates in Nanakshahi 558</h2>'
            f'<table class="dates"><thead><tr><th>Date</th><th>Nanakshahi</th></tr></thead><tbody>{rows}</tbody></table>')


def more(art, arts):
    first = UPDATED if art['group'] == 'monthly' else art['events'][0]['d']
    later = sorted((a for a in arts if a is not art and a['group'] != 'monthly' and a['first'] > first), key=lambda a: a['first'])
    same = [a for a in later if a['group'] == art['group']][:3]
    rest = [a for a in later if a not in same][:2]
    picks = sorted(same + rest, key=lambda a: a['first'])
    if len(picks) < 5:
        picks += [a for a in sorted(arts, key=lambda a: a['first']) if a is not art and a not in picks and a['group'] != 'monthly'][:5 - len(picks)]
    items = ''.join(f'<li><a href="/gurpurab/{a["slug"]}"><b>{esc(a["name"])}</b>'
                    f'<span>{esc(long_date(a["first"]))}</span></a></li>' for a in picks)
    return f'<section class="more"><h3>Next in the calendar</h3><ul>{items}</ul></section>'


def page(art, arts):
    canonical = f"{SITE}/gurpurab/{art['slug']}"
    image = image_of(art)
    evs = art['events']
    if art['group'] == 'monthly':
        when = f"<b>Every month</b> in the Nanakshahi calendar"
    else:
        when = ' · '.join(f"<b>{esc(long_date(e['d']))}</b> · {esc(e['ns'])}" for e in evs[:2])
    body = body_html(art['body'])
    if art['group'] == 'monthly':
        body += '\n' + date_table(art)
    return (head(f"{art['title']} | Hazri", art['desc'], canonical, image, json_ld(art, canonical, image)) + f'''<main class="wrap">
<nav class="crumbs" aria-label="Breadcrumb"><a href="/">Hazri</a> › <a href="/gurpurab">Gurpurab calendar</a> › <span>{esc(art['name'])}</span></nav>
<div class="layout">
<article>
<div class="kicker">{esc(KIND[art['kind']])}</div>
<h1>{esc(art['title'])}</h1>
<p class="dek">{esc(art['desc'])}</p>
<p class="when">{when}</p>
{figure(art)}
<div class="body">
{body}
</div>
{poster(art)}
</article>
<aside>
{facts(art)}
{more(art, arts)}
</aside>
</div>
</main>
''' + FOOT)


def index(arts):
    canonical = f'{SITE}/gurpurab'
    title = 'Gurpurab calendar 2026–27 (Nanakshahi 558): every Gurpurab, Shaheedi and Sikh day | Hazri'
    desc = ('The story of every Gurpurab, Shaheedi Purab and day of the Panth in the Nanakshahi calendar 558, '
            'from 14 March 2026 to 13 March 2027, with dates and how each day is observed.')
    by_month = {}
    for a in sorted((a for a in arts if a['group'] != 'monthly'), key=lambda a: a['first']):
        ns = a['events'][0]['ns'].split(' ')
        by_month.setdefault(f'{ns[1]} {ns[2]}', []).append(a)

    def card(a):
        return (f'<a class="card" href="/gurpurab/{a["slug"]}"><small>{esc(KIND[a["kind"]])}</small>'
                f'<b>{esc(a["name"])}</b><span>{esc(long_date(a["first"]))} · {esc(a["events"][0]["ns"])}</span></a>')
    months = ''.join(f'<section class="month"><h2>{esc(m)}</h2><div class="cards">{"".join(card(a) for a in lst)}</div></section>'
                     for m, lst in by_month.items())
    monthly = ''.join(card(a) for a in arts if a['group'] == 'monthly')
    return head(title, desc, canonical, None) + f'''<main class="wrap">
<div class="intro">
<div class="kicker">Gurpurab calendar · Nanakshahi 558</div>
<h1>Every Gurpurab and Sikh day of the year, with its story</h1>
<p>Dates follow the SGPC’s Nanakshahi calendar for 558, from 14 March 2026 to 13 March 2027. Each page tells the story of the day and how the sangat observes it. Hazri keeps the whole year on your phone and reminds you on the morning of each day.</p>
</div>
<section class="month"><h2>Every month</h2><div class="cards">{monthly}</div></section>
{months}
{poster({'remind': ''})}
</main>
''' + FOOT


def sitemap(arts):
    urls = [SITE + '/', SITE + '/gurpurab'] + [f"{SITE}/gurpurab/{a['slug']}" for a in arts]
    body = ''.join(f'<url><loc>{u}</loc><lastmod>{UPDATED}</lastmod></url>' for u in urls)
    return f'<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">{body}</urlset>\n'


def load(here):
    arts = []
    for f in sorted((here / 'articles').glob('*.json')):
        arts += json.loads(f.read_text())
    return arts


def build(here, public, cal):
    """Writes the story pages and returns cal with each event's page slug (`s`)
    and, where the calendar has no story of its own, the page's opening (`x`)."""
    arts = load(here)
    by_name = {}
    for a in arts:
        for n in a['events']:
            if n in by_name:
                raise SystemExit(f'{n!r} is claimed by both {by_name[n]["slug"]} and {a["slug"]}')
            by_name[n] = a
    slugs = [a['slug'] for a in arts]
    if len(set(slugs)) != len(slugs):
        raise SystemExit('two articles share a slug')
    names = {e['n'] for e in cal['events']}
    for n, a in by_name.items():
        if n not in names:
            raise SystemExit(f'{a["slug"]} names {n!r}, which is not in cal.json')
    missing = sorted(e['n'] for e in cal['events'] if e['n'] not in by_name)
    if missing:
        raise SystemExit('no story page for: ' + '; '.join(missing))

    for a in arts:
        names_of = set(a['events'])
        a['events'] = [e for e in cal['events'] if e['n'] in names_of]
        a['first'] = a['events'][0]['d']
        a['kind'] = a['events'][0]['t']
        a['group'] = group(a['kind'])
        a['name'] = a.get('name') or a['events'][0]['n']
        a['remind'] = remind_at(a['events'][0])
        words = len(' '.join(plain(x) for x in a['body']).split())
        if words < 200:
            raise SystemExit(f"{a['slug']} has {words} words; a story page carries at least 200")
        if len(a['desc']) > 180:
            raise SystemExit(f"{a['slug']}: desc is {len(a['desc'])} characters; search results cut it at about 160 and it should still read whole")

    out = public / 'gurpurab'
    out.mkdir(exist_ok=True)
    for old in out.glob('*.html'):
        old.unlink()
    for a in arts:
        (out / f"{a['slug']}.html").write_text(page(a, arts))
    (out / 'index.html').write_text(index(arts))
    (public / 'stories.css').write_text((here / 'stories.css').read_text())
    (public / 'sitemap.xml').write_text(sitemap(arts))
    (public / 'robots.txt').write_text(f'User-agent: *\nAllow: /\nDisallow: /verify\nDisallow: /j/\n\nSitemap: {SITE}/sitemap.xml\n')

    first_para = {a['slug']: plain(next(x for x in a['body'] if not x.startswith(('## ', '- ')))) for a in arts}
    events = []
    for e in cal['events']:
        a = by_name[e['n']]
        e = dict(e, s=a['slug'])
        if not e.get('a'):
            e['x'] = first_para[a['slug']]
        events.append(e)
    print(f'{out}: {len(arts)} story pages')
    return dict(cal, events=events)
