"""One-off: make a Beauty Beach background by recoloring example1.png — green
grass becomes warm sand, the pond stays as bright ocean water. Same recolor
approach as winterize_bg.py / purple_fields_bg.png. Run from repo root:
    python3 scripts/tools/beachify_bg.py
Pure PIL, no numpy.
"""
from PIL import Image

SRC = "assets/tilesets/example1.png"
DST = "assets/tilesets/beauty_beach_bg.png"

img = Image.open(SRC).convert("RGB")
hsv = img.convert("HSV")
px = list(hsv.getdata())

out = []
for h, s, v in px:
    if 45 <= h <= 125 and s > 35:          # grass/trees -> sand
        h = 30                             # warm tan hue
        s = max(55, min(130, int(s * 0.55)))  # keep some grain, not flat
        v = min(255, int(v * 0.9 + 95))    # grass->light sand, trees->dune shade
    elif 128 <= h <= 185 and s > 25:       # pond -> bright tropical ocean
        h = 150                            # blue-cyan
        s = min(200, int(s * 1.25 + 30))   # saturate to seawater
        v = min(255, int(v * 1.0 + 20))
    else:                                  # tan dirt / grey rock -> warm sand wash
        s = int(s * 0.7)
        v = min(255, int(v * 1.0 + 30))
    out.append((h, s, v))

hsv.putdata(out)
rgb = hsv.convert("RGB")

# Sunlit warm wash: out = c*0.92 + tint*0.08  (tint = 255,240,200)
r, g, b = rgb.split()
r = r.point(lambda c: int(c * 0.92 + 20))
g = g.point(lambda c: int(c * 0.92 + 19))
b = b.point(lambda c: int(c * 0.92 + 16))
Image.merge("RGB", (r, g, b)).save(DST)
print("wrote", DST)
