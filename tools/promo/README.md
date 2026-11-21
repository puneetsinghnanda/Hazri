# Play Store promo video

A 60-second, 16:9 promo for Hazri, rendered at 3840 x 2160 and 30 fps, plus a
1080p copy. Like the listing images in `store/`, it is **drawn, not edited**:
change a file here and run

```bash
tools/promo/build.sh /some/work/dir
```

which writes `hazri-promo-4k.mp4` and `hazri-promo-1080p.mp4` into that
directory. It takes about 25 minutes on four cores.

| File | Does |
|---|---|
| `stage.html` | The whole film as one page. `render(t)` draws second `t`: phone mockups, captions, the lifted cards, taps, the background and the end card |
| `frames.js` | Opens the stage in Playwright and screenshots each frame at `deviceScaleFactor` 2 (1920 x 1080 CSS px gives 4K) |
| `render_screens.js` | Renders the `design/html/` screens the film shows, at 4x |
| `music.py` | The score, synthesised with numpy: D major, 90 BPM, pad, arpeggio, bells, soft drums, a whoosh on each scene change and a chime when a hazri is marked. Original, so no licence is needed |
| `build.sh` | All of the above, then ffmpeg |

## What is on screen

Every phone screen is a **current or new** design from `design/canvas.html`,
shown unchanged (CLAUDE.md rule 1); the saakhi pages are the app's own
`assets/saakhi/bhai-lalo-malik-bhago/` pictures. The film adds only what
surrounds the phone: captions, a tap ring, a card lifted out of the screen
(a crop of that same screen), sparks, and the "Following the recitation"
chip. No caption quotes Gurbani (rule 3). When a screen used here is
superseded, change the film with it, as with the store slides.

| Time | Feature | Screens |
|---|---|---|
| 0-5 s | The mark draws itself; the phone rises | 92 |
| 5-11 s | 01 Daily Hazri | 13, 48, 85 |
| 11-18 s | 02 Nitnem: Gurmukhi, Hindi, Roman and meanings | 121, 13, 15, 14 |
| 18-24 s | 03 Personal Goals | 106, 120 |
| 24-31 s | 04 Simran Globe | 123, 124 |
| 31-37 s | 05 Sangat | 102, 104 |
| 37-42 s | 06 Diary | 87, 56 |
| 42-48 s | 07 Saakhis and Vichar | 111, saakhi pages, 122, 85 |
| 48-54 s | 08 Gurmat Quiz | 113, 114, 115, 116 |
| 54-60 s | App icon, "Make Every Day a Hazri.", download line, Google Play | — |

## Using it on Google Play

Play takes a promo video only as a **YouTube URL** (Main store listing ->
Video). Upload the 4K file to YouTube as public or unlisted, with ads off,
and paste the link. The end card says "Available on Google Play" in plain
type rather than Google's badge artwork; swap in the official badge from
Google's partner marketing site if wanted.
