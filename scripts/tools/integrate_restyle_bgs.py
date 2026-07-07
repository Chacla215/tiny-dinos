"""Integrate the painterly island RESTYLES into the live arena backgrounds.

Each Seedance/nano-banana restyle in assets/concept/islands/restyle/<arena>.png
keeps the EXACT composition of the original pixel-art bg, so integration is a
pure art swap: fit to the 1536x864 canvas (16:9, same framing as gen_island_bgs)
and bake the '<NAME> / BATTLE GROUND' banner on top (reusing
gen_island_bgs.draw_title so the title matches every other arena). Collision /
spawns / safe_rect are traced to the composition, which is unchanged.

Beach was integrated in a prior pass (beauty_beach_bg.png already painterly), so
this driver does the remaining five. Run from repo root:
    python3 scripts/tools/integrate_restyle_bgs.py
"""
import sys
from PIL import Image

sys.path.insert(0, "scripts/tools")
import gen_island_bgs as g   # W, H, draw_title, icon_*

RESTYLE = "assets/concept/islands/restyle"
TILES = "assets/tilesets"

# (restyle_name, dst_bg, TITLE, draw_title kwargs) — title styling lifted verbatim
# from gen_island_bgs.py (lava/falls/springs/purple) and integrate_arena_bg.py
# (floes / ICIEST AGE) so the restyle keeps each arena's exact banner look.
ARENAS = [
    ("lava", "laughing_lava_bg.png", "LAUGHING LAVA", dict(
        gtop=(255, 238, 156), gbot=(240, 120, 42), accent=(236, 92, 30),
        icon=g.icon_flame, icon_petal=(255, 226, 130, 255), icon_core=(255, 146, 42, 255))),
    ("falls", "white_water_falls_bg.png", "WHITE WATER FALLS", dict(
        gtop=(252, 253, 255), gbot=(150, 205, 240), accent=(70, 150, 210),
        icon=g.icon_drop, icon_petal=(224, 246, 255, 255), icon_core=(120, 196, 236, 255))),
    ("springs", "sunny_springs_bg.png", "SUNNY SPRINGS", dict(
        gtop=(250, 252, 220), gbot=(150, 210, 90), accent=(88, 166, 70),
        icon=g.icon_flower, icon_petal=(255, 206, 86, 255), icon_core=(245, 140, 40, 255))),
    ("purple", "purple_fields_bg.png", "PURPLE FIELDS", dict(
        gtop=(250, 244, 255), gbot=(192, 150, 232), accent=(150, 92, 196),
        icon=g.icon_flower, icon_petal=(214, 150, 230, 255), icon_core=(252, 224, 96, 255))),
    ("floes", "iciest_floes_bg.png", "ICIEST AGE", dict(
        gtop=(236, 248, 255), gbot=(150, 200, 240), accent=(58, 110, 170),
        icon=g.icon_drop, icon_petal=(190, 226, 255, 255), icon_core=(255, 255, 255, 255))),
]


def main():
    for name, dst, title, args in ARENAS:
        src = "%s/%s.png" % (RESTYLE, name)
        img = Image.open(src).convert("RGBA").resize((g.W, g.H), Image.LANCZOS)
        g.draw_title(img, title, **args)
        out = "%s/%s" % (TILES, dst)
        img.convert("RGB").save(out)
        print("wrote", out)


if __name__ == "__main__":
    main()
