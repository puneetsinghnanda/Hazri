# Google Play listing images

`play/` is what goes into Play Console -> Grow -> Store presence -> Main store
listing. It is **drawn, not edited**: change `tools/store/slides.json` (the
headlines and which screen each slide shows) or `tools/store/build.js` (the
layout), then run

```bash
node tools/store/build.js
```

| File | Size | Play Console field |
|---|---|---|
| `icon-512.png` | 512 x 512 | App icon (the launcher mark from `make_icons.py`) |
| `feature-graphic.png` | 1024 x 500 | Feature graphic |
| `screenshot-1.png` ... `screenshot-8.png` | 1080 x 1920 | Phone screenshots, in this order |

Each screenshot is a **current** screen from `design/html/` (see
`design/canvas.html`). Play wants screenshots to show the app as it is, so
when a screen used here is superseded, or the build stops matching it, change
the slide with it. The headlines are English only, and no caption quotes
Gurbani (CLAUDE.md rule 3).
