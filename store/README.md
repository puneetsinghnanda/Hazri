# Google Play listing images

`play/` is what goes into Play Console -> Grow -> Store presence -> Main store
listing, in three styles to choose from:

| Folder | Style |
|---|---|
| `play/a/` | **Airy**: light lavender, a huge two-line headline, the phone tilted with the slide's card lifted out of it |
| `play/b/` | **Bold**: white, an all-caps headline with one word ringed, a dashed path to the sun-arc mark, chips around the phone |
| `play/c/` | **Saffron**: a saffron sky, a pinned sticker, the headline at the top or bottom, the phone tilted off the edge |

Each folder has `screenshot-1.png` ... `screenshot-8.png` (1080 x 1920, upload in
this order) and `feature-graphic.png` (1024 x 500). `play/icon-512.png` is the
512 x 512 app icon, the launcher mark from `make_icons.py`, for all three.

They are **drawn, not edited**: change `tools/store/slides.json` (headlines,
which screen each slide shows, the card lifted out of it) or
`tools/store/build.js` (the three layouts), then run

```bash
node tools/store/build.js
```

Each screenshot is a **current** screen from `design/html/` (see
`design/canvas.html`). Play wants screenshots to show the app as it is, so
when a screen used here is superseded, or the build stops matching it, change
the slide with it. The headlines are English only, and no caption quotes
Gurbani (CLAUDE.md rule 3).
