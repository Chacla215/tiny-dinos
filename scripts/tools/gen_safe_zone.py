"""Generate an island-shaped ring-out boundary for an arena.

main.gd now supports `safe_polygon` (world coords): when set, ring-out is a
point-in-polygon test instead of the rectangular `safe_rect`, so a round island
reads true to its painted shoreline. This emits the tscn-ready PackedVector2Array
line for that polygon and renders a debug preview (boundary + spawns + cover) over
the arena art so the shape can be tuned against the painting before editing .tscn.

World->image mapping matches gen_island_bgs: image = world + OFF (128, 72).

    python3 scripts/tools/gen_safe_zone.py          # print tscn line + write preview
"""
import math
from PIL import Image, ImageDraw

OFF = (128, 72)

# --- per-arena config (Purple Fields) --------------------------------------
BG = "assets/tilesets/purple_fields_bg.png"
PREVIEW = "/tmp/purple_safezone.png"

# Island boundary as an ELLIPSE (a true circle = equal radii). The viewport is
# 16:9, so a circle large enough for 4-player FFA would crop top/bottom; a wide
# ellipse traces the lozenge island and keeps the play space. Tune to the art.
CENTER = (640, 462)
RX, RY = 582, 213
SEGMENTS = 40

SPAWNS = [(400, 380), (780, 380), (400, 560), (800, 560)]  # p1..p4
# Cover blocks (world cx, cy, w, h) aligned to the painted boulders (v2 art).
OBSTACLES = [
    (360, 248, 130, 100),   # top-center-left rock
    (890, 250, 135, 100),   # top-center-right rock
    (240, 390, 110, 95),    # left-mid rock
    (990, 390, 115, 95),    # right-mid rock
    (585, 500, 130, 115),   # bottom-center pile
]
# ---------------------------------------------------------------------------


def ellipse_polygon(center, rx, ry, segments):
    cx, cy = center
    pts = []
    for i in range(segments):
        a = (i / segments) * math.tau
        pts.append((round(cx + rx * math.cos(a)), round(cy + ry * math.sin(a))))
    return pts


def tscn_line(pts):
    flat = ", ".join(str(v) for xy in pts for v in xy)
    return "safe_polygon = PackedVector2Array(%s)" % flat


def preview(pts):
    img = Image.open(BG).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    ox, oy = OFF
    loop = [(x + ox, y + oy) for (x, y) in pts] + [(pts[0][0] + ox, pts[0][1] + oy)]
    d.line(loop, fill=(255, 40, 40, 255), width=5)
    for i, (px, py) in enumerate(SPAWNS):
        cx, cy = px + ox, py + oy
        inside = point_in_poly((px, py), pts)
        fill = (40, 230, 80, 255) if inside else (255, 200, 0, 255)
        d.ellipse([cx - 14, cy - 14, cx + 14, cy + 14], fill=fill, outline=(0, 0, 0, 255), width=2)
        d.text((cx - 4, cy - 7), str(i + 1), fill=(0, 0, 0, 255))
    for (cx0, cy0, w0, h0) in OBSTACLES:
        cx, cy = cx0 + ox, cy0 + oy
        d.rectangle([cx - w0 / 2, cy - h0 / 2, cx + w0 / 2, cy + h0 / 2],
                    fill=(60, 120, 255, 90), outline=(40, 80, 255, 255), width=4)
    img.save(PREVIEW)


def point_in_poly(p, poly):
    x, y = p
    inside = False
    n = len(poly)
    j = n - 1
    for i in range(n):
        xi, yi = poly[i]
        xj, yj = poly[j]
        if ((yi > y) != (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi):
            inside = not inside
        j = i
    return inside


def main():
    pts = ellipse_polygon(CENTER, RX, RY, SEGMENTS)
    print(tscn_line(pts))
    preview(pts)
    bad = [i + 1 for i, s in enumerate(SPAWNS) if not point_in_poly(s, pts)]
    print("wrote", PREVIEW, "| spawns outside boundary:", bad or "none")


if __name__ == "__main__":
    main()
