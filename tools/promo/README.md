# Play Store promo video

A 60-second, 16:9 promo for Hazri, rendered at 3840 x 2160 and 30 fps, plus a
1080p copy. Like the listing images in `store/`, it is **drawn, not edited**:
change a file here and run

```bash
tools/promo/build.sh /some/work/dir
```

which writes `hazri-promo-4k.mp4` and `hazri-promo-1080p.mp4`, and the Punjabi
`hazri-promo-pa-4k.mp4` and `hazri-promo-pa-1080p.mp4`, into that directory. It takes about 25 minutes on four cores.

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

## The Punjabi version

`hazri-promo-pa-4k.mp4` and `-1080p.mp4` carry a Punjabi voice-over, Punjabi
subtitles burned in (Baloo Paaji 2), and switchable Punjabi and English
subtitle tracks. The script is `narration.json`: one line per scene, each
timed to start with its caption. `tts.py` speaks it phrase by phrase with
Meta's MMS Punjabi voice (`facebook/mms-tts-pan`), adding the pauses the model
cannot read from punctuation, and `voiceover.py` writes the subtitles and
mixes the voice over the score, which ducks under it.

**Two things to settle before it is published:**

- **The voice is synthetic, and its licence is CC-BY-NC 4.0** (non-commercial).
  It is a stand-in for timing and tone. For the store, record a person reading
  the same script (the owner's saakhi narrator would match the app) and drop
  the takes in as `vo/NN.wav`; `voiceover.py` does the rest.
- **The Punjabi script is Claude's draft** and wants a native ear, like the
  app's other Punjabi strings. It quotes no Gurbani.

| Starts | Punjabi | English |
|---|---|---|
| 0.7 s | ਹਾਜ਼ਰੀ। ਤੁਹਾਡਾ ਰੂਹਾਨੀ ਸਾਥੀ। | Hazri. Your spiritual companion. |
| 5.6 s | ਇੱਕ ਬਾਣੀ ਪੜ੍ਹੋ, ਜਾਂ ਪੰਜ ਮਿੰਟ ਨਾਮ ਸਿਮਰਨ ਕਰੋ, ਤੇ ਅੱਜ ਦੀ ਹਾਜ਼ਰੀ ਲੱਗ ਜਾਂਦੀ ਹੈ। | Read a bani, or do five minutes of Naam Simran, and today's hazri is marked. |
| 12.0 s | ਨੌਂ ਬਾਣੀਆਂ, ਗੁਰਮੁਖੀ, ਹਿੰਦੀ ਜਾਂ ਰੋਮਨ ਵਿੱਚ, ਅਰਥਾਂ ਸਮੇਤ, ਤੇ ਪਾਠ ਦੀ ਆਵਾਜ਼ ਦੇ ਨਾਲ ਨਾਲ। | Nine banis, in Gurmukhi, Hindi or Roman, with meanings, alongside the recitation. |
| 19.0 s | ਆਪਣੇ ਰੋਜ਼ ਦੇ ਪਾਠ ਤੇ ਸਿਮਰਨ ਦੇ ਟੀਚੇ ਰੱਖੋ, ਹਰ ਇੱਕ ਦੀ ਯਾਦ ਆਪਣੇ ਵੇਲੇ। | Set your daily paath and simran goals, each reminded at its own time. |
| 25.2 s | ਸਿਮਰਨ ਕਰੋ, ਤੇ ਦੇਖੋ ਦੁਨੀਆਂ ਭਰ ਦੇ ਸ਼ਹਿਰਾਂ ਵਿੱਚ ਸੰਗਤ ਤੁਹਾਡੇ ਨਾਲ ਹੈ। | Do simran, and see the sangat with you in cities across the world. |
| 31.5 s | ਸੰਗਤ ਦੇ ਗਰੁੱਪ ਨਾਲ ਜੁੜੋ, ਤੇ ਰਲ ਕੇ ਸਾਂਝਾ ਟੀਚਾ ਪੂਰਾ ਕਰੋ। | Join a sangat group, and complete a shared goal together. |
| 37.2 s | ਡਾਇਰੀ ਤੁਹਾਡਾ ਹਰ ਦਿਨ ਸਾਂਭਦੀ ਹੈ, ਤੇ ਤੁਹਾਡੀ ਲੜੀ ਗਿਣਦੀ ਹੈ। | The diary keeps every day, and counts your streak. |
| 42.5 s | ਤਸਵੀਰਾਂ ਨਾਲ ਸਾਖੀਆਂ, ਤੇ ਹਰ ਰੋਜ਼ ਗੁਰਬਾਣੀ ਦਾ ਇੱਕ ਵਿਚਾਰ। | Saakhis in pictures, and a thought from Gurbani every day. |
| 48.8 s | ਹਰ ਰੋਜ਼ ਨਵਾਂ ਗੁਰਮਤਿ ਕੁਇਜ਼। ਖੇਡੋ, ਸਿੱਖੋ, ਤੇ ਅੱਗੇ ਵਧੋ। | A new Gurmat quiz every day. Play, learn, and climb. |
| 54.7 s | ਹਰ ਦਿਨ ਨੂੰ ਹਾਜ਼ਰੀ ਬਣਾਓ। ਹਾਜ਼ਰੀ, ਹੁਣ ਗੂਗਲ ਪਲੇ ਉੱਤੇ। | Make every day a Hazri. Hazri, now on Google Play. |

## Using it on Google Play

Play takes a promo video only as a **YouTube URL** (Main store listing ->
Video). Upload the 4K file to YouTube as public or unlisted, with ads off,
and paste the link. The end card says "Available on Google Play" in plain
type rather than Google's badge artwork; swap in the official badge from
Google's partner marketing site if wanted.
