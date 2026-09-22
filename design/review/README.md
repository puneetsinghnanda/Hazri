# Phase 2 review page

`phase2-review.html` puts all 22 Phase 2 screens on one page at 390 x 844 --
light or dark, either one full size -- with a comment box and a Fine/Change
mark under each. It is the sign-off surface for the design set: nothing is
implemented until the set is agreed.

It is published as a Claude Artifact rather than opened from disk, because the
comments are stored in the artifact's own database (`capabilities: {db: {}}`,
collection `review`, one document per screen keyed by its design-file id) so
they survive a reload and can be read straight back. Without that database the
page still works and keeps what you type in the browser, on that device only.

The page loads each screen from `screens/<id>.<light|dark>.html`. At publish
time those are the files in `design/html/`, mapped one to one:

    screens/30-Today.light.html  ->  design/html/30-Today.light.html
    ...

To publish or republish it, pass this file to the Artifact tool with that
mapping as `files`. To open it from disk instead, copy the 44 files:

    mkdir -p /tmp/p2/screens && cp design/html/{29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50}-*.{light,dark}.html /tmp/p2/screens/
    cp design/review/phase2-review.html /tmp/p2/index.html   # then wrap in <html><body>

The screen list, the grouping and the one-line note under each screen live in
the `SECTIONS` constant at the top of the script. A screen added to
`design/html/` is not on the review page until it is added there.

## Phase 3

`phase3-review.html` is the same page for the Phase 3 set, screens 62 to 84,
which `tools/design/phase3_screens.py` draws into `design/html/` (light and
dark). Re-run that script after changing a screen, then republish the page
with the 46 files mapped as `screens/<id>.<light|dark>.html`. Its comments
live in the Phase 3 artifact's own database, apart from Phase 2's.
