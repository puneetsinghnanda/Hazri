#!/usr/bin/env python3
"""Builds `assets/geo/world.bin` — the outlines on design 29's globe.

Design 29 draws the earth as an outline: coastlines and the borders between
countries, one hairline stroke, no fill. This turns Natural Earth's 110m
country polygons into the lat/lon polylines the Flutter painter projects.

WHY ARCS AND NOT POLYGONS. TopoJSON already factors a country's boundary into
*arcs*, and an arc shared by two countries is stored once. Drawing the arcs is
therefore exactly the picture design 29 shows: every coastline once and every
land border once, with no doubled stroke down the middle of a shared frontier
and no filled shape to paint over the sea.

SOURCE. `countries-110m.json`, vendored beside this script, from the npm
package `world-atlas@2.0.2` (Mike Bostock, ISC). Its data is Natural Earth
1:110m Admin 0, which is in the public domain. Both files are in git so a
fresh clone can rebuild the asset without a network.

    python3 tools/geo/build_world_outline.py
"""

import json
import math
import pathlib
import struct

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent
SOURCE = HERE / 'countries-110m.json'
OUT = ROOT / 'assets' / 'geo' / 'world.bin'

# Degrees. The globe is at most 390 px across, so its radius is ~175 px and a
# degree of arc at the centre is a little under 3 px. A quarter of a degree is
# well under a pixel: simplifying to it is invisible and removes a third of
# the points.
TOLERANCE = 0.25

# Two decimal places — about a kilometre, and a hundredth of a degree in
# hundredths fits int16 for both longitude (+-18000) and latitude (+-9000).
SCALE = 100

MAGIC = b'HZGEO1'


def decode(topology):
    """TopoJSON's quantised, delta-encoded arcs back to (lon, lat) degrees."""
    sx, sy = topology['transform']['scale']
    tx, ty = topology['transform']['translate']
    out = []
    for arc in topology['arcs']:
        x = y = 0
        points = []
        for dx, dy in arc:
            x += dx
            y += dy
            points.append((x * sx + tx, y * sy + ty))
        out.append(points)
    return out


def simplify(points, tolerance):
    """Douglas-Peucker, iterative so a long coastline cannot blow the stack."""
    if len(points) < 3:
        return points
    keep = [False] * len(points)
    keep[0] = keep[-1] = True
    stack = [(0, len(points) - 1)]
    while stack:
        first, last = stack.pop()
        if last <= first + 1:
            continue
        ax, ay = points[first]
        bx, by = points[last]
        dx, dy = bx - ax, by - ay
        span = math.hypot(dx, dy)
        worst, at = 0.0, first
        for i in range(first + 1, last):
            px, py = points[i]
            if span == 0:
                d = math.hypot(px - ax, py - ay)
            else:
                d = abs(dy * px - dx * py + bx * ay - by * ax) / span
            if d > worst:
                worst, at = d, i
        if worst > tolerance:
            keep[at] = True
            stack.append((first, at))
            stack.append((at, last))
    return [p for p, k in zip(points, keep) if k]


def quantise(points):
    """To hundredths of a degree, dropping points the rounding made equal."""
    out = []
    for lon, lat in points:
        q = (round(lon * SCALE), round(lat * SCALE))
        if not out or q != out[-1]:
            out.append(q)
    return out


def main():
    topology = json.loads(SOURCE.read_text())
    arcs = []
    for points in decode(topology):
        q = quantise(simplify(points, TOLERANCE))
        # An arc that simplified down to a single point draws nothing.
        if len(q) >= 2:
            arcs.append(q)

    blob = bytearray(MAGIC)
    blob += struct.pack('<H', len(arcs))
    for arc in arcs:
        blob += struct.pack('<H', len(arc))
        for lon, lat in arc:
            blob += struct.pack('<hh', lon, lat)

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_bytes(bytes(blob))
    points = sum(len(a) for a in arcs)
    print(f'{OUT.relative_to(ROOT)}: {len(arcs)} arcs, {points} points, '
          f'{len(blob) / 1024:.1f} KiB')


if __name__ == '__main__':
    main()
