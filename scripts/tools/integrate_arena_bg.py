"""Integrate a generated pixel-art arena background into the game.

Takes one of Charlie's AI-generated island images, fits it to the 1536x864
canvas (16:9, same as the camera framing in gen_island_bgs.py), bakes the
'<NAME> / BATTLE GROUND' title on top (reusing gen_island_bgs.draw_title so it
matches the other arenas), and writes assets/tilesets/<name>_bg.png.

These new arenas are "island surrounded by hazard" -> ring-out, not an interior
pool. The gameplay safe zone is main.gd's rectangular `safe_rect` (world coords).
Run with DEBUG=1 to instead dump a preview with the candidate safe_rect + player
spawns drawn over the art, so the rect can be tuned before editing the .tscn.
World->image mapping is +OFF (see gen_island_bgs): image = world + (128, 72).

Run from repo root:
    python3 scripts/tools/integrate_arena_bg.py            # write final bg
    DEBUG=1 python3 scripts/tools/integrate_arena_bg.py    # write debug preview
"""
import os
import sys
from PIL import Image, ImageDraw

sys.path.insert(0, "scripts/tools")
import gen_island_bgs as g   # W, H, OFF, draw_title, icon_flower, ...

DEBUG = os.environ.get("DEBUG") == "1"

# --- per-island config (Purple Fields) -------------------------------------
SRC = "/Users/charlie/.claude/image-cache/15bc98a7-b342-472d-8601-e233fc1b4728/2.png"
DST = "assets/tilesets/purple_fields_bg.png"
DEBUG_DST = "scripts/tools/_purple_debug.png"
TITLE = "PURPLE FIELDS"
TITLE_ARGS = dict(gtop=(250, 244, 255), gbot=(192, 150, 232), accent=(150, 92, 196),
                  icon=g.icon_flower, icon_petal=(214, 150, 230, 255),
                  icon_core=(252, 224, 96, 255))

# Candidate gameplay safe zone + spawns, in WORLD coords (tune via DEBUG preview).
SAFE_RECT = (175, 325, 950, 350)         # x, y, w, h
SPAWNS = [(330, 430), (950, 430), (490, 620), (800, 620)]  # p1..p4
# Cover blocks aligned to painted rock formations: WORLD (cx, cy, w, h).
OBSTACLES = [
    (220, 370, 72, 64),     # left stone stack (upper-left)
    (1080, 370, 72, 64),    # right stone stack (upper-right)
    (210, 600, 64, 56),     # front-left rocks
    (1075, 600, 64, 56),    # front-right rocks
    (525, 650, 84, 54),     # front-center rock
]
# ---------------------------------------------------------------------------


def build():
    img = Image.open(SRC).convert("RGBA").resize((g.W, g.H), Image.LANCZOS)
    g.draw_title(img, TITLE, **TITLE_ARGS)
    return img


def main():
    img = build()
    if DEBUG:
        d = ImageDraw.Draw(img, "RGBA")
        ox, oy = g.OFF
        x, y, w, h = SAFE_RECT
        d.rectangle([x + ox, y + oy, x + w + ox, y + h + oy],
                    outline=(255, 40, 40, 255), width=5)
        for i, (px, py) in enumerate(SPAWNS):
            cx, cy = px + ox, py + oy
            d.ellipse([cx - 12, cy - 12, cx + 12, cy + 12],
                      fill=(40, 230, 80, 255), outline=(0, 0, 0, 255), width=2)
            d.text((cx - 4, cy - 8), str(i + 1), fill=(0, 0, 0, 255))
        for (cx0, cy0, w0, h0) in OBSTACLES:
            cx, cy = cx0 + ox, cy0 + oy
            d.rectangle([cx - w0 / 2, cy - h0 / 2, cx + w0 / 2, cy + h0 / 2],
                        fill=(60, 120, 255, 90), outline=(40, 80, 255, 255), width=4)
        img.save(DEBUG_DST)
        print("wrote", DEBUG_DST, "(safe_rect", SAFE_RECT, ")")
    else:
        img.convert("RGB").save(DST)
        print("wrote", DST)


if __name__ == "__main__":
    main()
