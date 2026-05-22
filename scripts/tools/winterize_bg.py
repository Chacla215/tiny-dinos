"""One-off: make an Iciest Age background by recoloring example1.png into a
winter palette (same approach used for purple_fields_bg.png). Run from repo root:
    python3 scripts/tools/winterize_bg.py
Pure PIL, no numpy.
"""
from PIL import Image

SRC = "assets/tilesets/example1.png"
DST = "assets/tilesets/iciest_age_bg.png"

img = Image.open(SRC).convert("RGB")
hsv = img.convert("HSV")
px = list(hsv.getdata())

out = []
for h, s, v in px:
    if 45 <= h <= 140 and s > 35:          # vegetation -> bright snow
        h = 145                            # icy blue hue
        s = int(s * 0.20)                  # nearly white
        v = min(255, int(v * 1.10 + 70))   # grass->white, trees->pale grey
    elif (h <= 44 or h >= 200) and s > 28:  # tan/brown dirt -> frozen ground
        h = 150                            # icy blue hue
        s = int(s * 0.22)                  # mostly desaturated
        v = min(255, int(v * 0.95 + 95))   # lift to pale grey-blue, not pure white
    else:                                  # cool everything else (paths, water)
        s = int(s * 0.55)
        v = min(255, int(v * 1.05 + 25))
    out.append((h, s, v))

hsv.putdata(out)
rgb = hsv.convert("RGB")

# Unifying cold wash: out = c*0.88 + tint*0.12  (tint = 200,225,245)
r, g, b = rgb.split()
r = r.point(lambda c: int(c * 0.88 + 24))
g = g.point(lambda c: int(c * 0.88 + 27))
b = b.point(lambda c: int(c * 0.88 + 29))
Image.merge("RGB", (r, g, b)).save(DST)
print("wrote", DST)
