#!/usr/bin/env python3
"""Alpha-cut a flat-background hero PNG via corner flood fill.

Only pixels color-close to the corner background AND connected to the frame
edge become transparent, so interior tones near the bg color (Jessie's cream
belly vs the light-gray backdrop) survive. Writes RGBA in place, which
gen_ralph_fighter.py's cutout() then uses directly ("real transparency wins").
"""
import sys
from collections import deque
from PIL import Image

TOL = 30.0  # color distance to count as background

src = sys.argv[1]
im = Image.open(src).convert("RGB")
w, h = im.size
px = im.load()
cs = [px[2, 2], px[w - 3, 2], px[2, h - 3], px[w - 3, h - 3]]
bg = tuple(sum(c[i] for c in cs) // 4 for i in range(3))

def is_bg(p):
    return ((p[0] - bg[0]) ** 2 + (p[1] - bg[1]) ** 2 + (p[2] - bg[2]) ** 2) ** 0.5 <= TOL

mask = bytearray(w * h)  # 1 = background (transparent)
q = deque()
for x in range(w):
    for y in (0, h - 1):
        if is_bg(px[x, y]) and not mask[y * w + x]:
            mask[y * w + x] = 1
            q.append((x, y))
for y in range(h):
    for x in (0, w - 1):
        if is_bg(px[x, y]) and not mask[y * w + x]:
            mask[y * w + x] = 1
            q.append((x, y))
while q:
    x, y = q.popleft()
    for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
        if 0 <= nx < w and 0 <= ny < h and not mask[ny * w + nx] and is_bg(px[nx, ny]):
            mask[ny * w + nx] = 1
            q.append((nx, ny))

out = im.convert("RGBA")
op = out.load()
n = 0
for y in range(h):
    for x in range(w):
        if mask[y * w + x]:
            r, g, b, _ = op[x, y]
            op[x, y] = (r, g, b, 0)
            n += 1
out.save(src)
print(f"bg={bg} cleared {n}/{w*h} px ({100.0*n/(w*h):.1f}%) -> {src}")
