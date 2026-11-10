# Instagram posts

Drawn, not edited, by `tools/social/build.js` from the app's own content, the
same way `tools/store/` draws the Play listing.

```bash
node tools/social/build.js --from 2026-11-09 --days 30   # into social/out/ (not in git)
node tools/social/build.js --samples                     # one of each, into social/samples/
```

Each run writes feed posts (1080 x 1350) and stories (1080 x 1920) plus
`captions.md` with a ready caption for each:

| When | Post |
|---|---|
| Every day | Today's Vichar: the line the app shows that day (`VicharCycle`), dawn and night on alternate days |
| The eve of an event | Every calendar event the app reminds about by default, with its hazri.me story line |
| Tuesdays | Gurmat Quiz carousel: the question, then the answer with its explanation |
| Fridays | A saakhi: its cover and subtitle |
| Always | Two brand posts: privacy, and a day with Hazri |

Every pankti and meaning is read from `assets/content/content.db` by
`tools/social/export.py`. None is typed, paraphrased or translated (CLAUDE.md
rule 3). The only pictures are the saakhi covers, which follow SK2. A post
that needs a new picture of a Guru must show light where the face would be.

## Profile picture

`brand/instagram-profile.png` (light, as the launcher icon) and
`brand/instagram-profile-navy.png` are the app mark at 1080 x 1080, drawn
with `draw_mark` from `tools/content_pipeline/make_icons.py` at 60% of the
square so it stays whole inside Instagram's circle.
