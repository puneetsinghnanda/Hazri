#!/usr/bin/env python3
"""Catch a screen whose content wrapper closed early.

Removing the streak column from the hazri banner once left its ``</div>``
behind. That tag closed Today's flex column instead, so every card below the
banner became a direct child of ``.app``: the 13px gap the column was giving
them vanished, the cards ran together and slid up, and on the two screens
that end in a bottom sheet the sheet stopped covering what was behind it. The
markup either side of the stray tag looked fine, so it read as a spacing
problem rather than a broken tag, and it reached six screens before anybody
saw it.

The signature is precise, and it is what this checks: a card or a button
belongs inside a content wrapper, never directly under ``.app``. Counting
top-level children instead would flag Simran and the Hindi reader, which
legitimately have several, and a check that cries wolf is a check people
learn to ignore.

    python3 tools/design/check_structure.py

Exits non-zero and names the screens if any fail. Standard library only, so
it runs on a fresh clone next to build_phase2.py.
"""

import os
import sys
from html.parser import HTMLParser

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HTML = os.path.join(ROOT, "design", "html")

VOID = {"area", "base", "br", "col", "embed", "hr", "img", "input",
        "link", "meta", "param", "source", "track", "wbr"}


class Screens(HTMLParser):
    """Track the element stack and note anything loose directly under .app."""

    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.stack: list[tuple[str, str]] = []
        self.app_depth: int | None = None
        self.loose: list[str] = []

    def handle_starttag(self, tag: str, attrs) -> None:
        if tag in VOID:
            return
        classes = dict(attrs).get("class", "") or ""
        # <svg> subtrees carry their own tags; skip them wholesale.
        if any(t == "svg" for t, _ in self.stack):
            self.stack.append((tag, classes))
            return
        if self.app_depth is not None and len(self.stack) == self.app_depth:
            if {"card", "btn"} & set(classes.split()):
                self.loose.append(classes)
        self.stack.append((tag, classes))
        if self.app_depth is None and "app" in classes.split():
            self.app_depth = len(self.stack)

    def handle_endtag(self, tag: str) -> None:
        if tag in VOID:
            return
        for i in range(len(self.stack) - 1, -1, -1):
            if self.stack[i][0] == tag:
                del self.stack[i:]
                break


def main() -> int:
    failures = []
    files = sorted(f for f in os.listdir(HTML) if f.endswith(".html"))
    for name in files:
        with open(os.path.join(HTML, name), encoding="utf-8") as fh:
            parser = Screens()
            parser.feed(fh.read())
        if parser.app_depth is None:
            # 00-Foundations and the globe comparison sheet are not screens.
            continue
        if parser.loose:
            failures.append(f"{name}: {len(parser.loose)} loose "
                            f"({', '.join(parser.loose)})")
    if failures:
        print("content wrapper closed early:", file=sys.stderr)
        for line in failures:
            print(f"  {line}", file=sys.stderr)
        return 1
    print(f"{len(files)} files: every card sits inside its wrapper")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
