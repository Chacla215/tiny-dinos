#!/usr/bin/env python3
"""Bake a painterly dino hero into an in-match pixel-art fighter sheet.

No new art: loads a hero PNG, keys out its flat background (or uses existing
alpha), shrinks it to fighter size, runs it through the SAME Bayer dither the
island backgrounds use (so the dino reads as pixel art on the pixel islands),
then bakes idle(2)/walk(4)/attack(3) frames via cheap transforms. Output:
assets/sprites/<dino>_fighter.png + a contact preview, and it prints the Rect2
cells + SHEET const for dino.gd ANIM_LAYOUTS.

Run:  python3 scripts/tools/gen_ralph_fighter.py [dino]
      dino defaults to "ralph". Once Charlie drops assets/concept/<dino>/<dino>_hero.png
      (per scripts/tools/dino_art_prompts.md), e.g. `... gen_ralph_fighter.py trike`
      bakes that species' fighter the same way.
"""
import os
import sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# Per-dino hero source. Ralph's file is named ralph_hero.png; the rest follow the
# <dino>/<dino>_hero.png convention from dino_art_prompts.md.
HERO_SRC = {
    "ralph":  "assets/concept/ralph/ralph_hero.png",
    "trex":   "assets/concept/trex/trex_hero.png",
    "raptor": "assets/concept/raptor/raptor_hero.png",
    "trike":  "assets/concept/trike/trike_hero.png",
    "pterry": "assets/concept/pterry/pterry_hero.png",
    "bronto": "assets/concept/bronto/bronto_hero.png",
    "anky":   "assets/concept/anky/anky_hero.png",
}

CHAR_H = 132          # target character height in px (reads ~1:1 at gameplay scale)
KEY_LO, KEY_HI = 34, 70   # color-distance band for the alpha ramp (soft edges)
POSTERIZE = 6         # levels/channel -> flatten painterly gradients toward pixels
DITHER_AMP = 12       # Bayer stipple strength (islands use ~16)

# dino.gd treats every sheet as facing RIGHT (no faces_left flags), but the
# painterly heroes have mixed native facings — only flip the ones drawn facing
# left. (The old unconditional flip shipped raptor/trike/pterry/bronto facing
# LEFT, so those four walked backwards in-match.)
HERO_FACES_LEFT = {"ralph": True, "bronto": True}

# 8x8 Bayer matrix (same as gen_island_bgs.py) for ordered dithering.
BAYER8 = [
    [0, 48, 12, 60, 3, 51, 15, 63], [32, 16, 44, 28, 35, 19, 47, 31],
    [8, 56, 4, 52, 11, 59, 7, 55], [40, 24, 36, 20, 43, 27, 39, 23],
    [2, 50, 14, 62, 1, 49, 13, 61], [34, 18, 46, 30, 33, 17, 45, 29],
    [10, 58, 6, 54, 9, 57, 5, 53], [42, 26, 38, 22, 41, 25, 37, 21],
]


def sample_bg(im):
    """Average the four corners -> the flat background color to key out."""
    w, h = im.size
    px = im.load()
    cs = [px[2, 2], px[w - 3, 2], px[2, h - 3], px[w - 3, h - 3]]
    return tuple(sum(c[i] for c in cs) // 4 for i in range(3))


def cutout(im):
    """RGBA with a clean alpha: use real transparency if present, else key the
    flat corner background with a soft distance ramp."""
    if im.mode == "RGBA" and im.getextrema()[3][0] < 250:
        return im.crop(im.getbbox())          # already has a usable alpha
    im = im.convert("RGB")
    bg = sample_bg(im)
    w, h = im.size
    src = im.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = src[x, y]
            d = ((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2) ** 0.5
            if d <= KEY_LO:
                a = 0
            elif d >= KEY_HI:
                a = 255
            else:
                a = int(round((d - KEY_LO) / (KEY_HI - KEY_LO) * 255))
            dst[x, y] = (r, g, b, a)
    return out.crop(out.getbbox())


def pixelate(rgba, flip):
    """Downscale to CHAR_H, posterize + Bayer-dither the RGB, keep the alpha."""
    w, h = rgba.size
    scale = CHAR_H / h
    small = rgba.resize((max(1, round(w * scale)), CHAR_H), Image.LANCZOS)
    r, g, b, a = small.split()
    rgb = Image.merge("RGB", (r, g, b))
    step = 255 / (POSTERIZE - 1)
    rgb = rgb.point(lambda v: int(round(round(v / step) * step)))
    sw, sh = rgb.size
    px = rgb.load()
    for y in range(sh):
        row = BAYER8[y % 8]
        for x in range(sw):
            nudge = int(round((row[x % 8] / 63.0 - 0.5) * DITHER_AMP))
            cr, cg, cb = px[x, y]
            px[x, y] = (max(0, min(255, cr + nudge)),
                        max(0, min(255, cg + nudge)),
                        max(0, min(255, cb + nudge)))
    a = a.point(lambda v: 0 if v < 110 else 255)
    out = Image.merge("RGBA", (*rgb.split(), a))
    if flip:
        out = out.transpose(Image.FLIP_LEFT_RIGHT)
    return out.crop(out.getbbox())


def smoothen(rgba, flip):
    """Downscale to CHAR_H keeping the SMOOTH painterly RGB + soft anti-aliased
    alpha (no posterize/dither, no hard alpha threshold) — the in-match painterly
    look. Same frame geometry as pixelate() so the dino.gd ANIM_LAYOUTS cells line
    up; only the in-match texture filter changes (LINEAR, not NEAREST)."""
    w, h = rgba.size
    scale = CHAR_H / h
    out = rgba.resize((max(1, round(w * scale)), CHAR_H), Image.LANCZOS)
    if flip:
        out = out.transpose(Image.FLIP_LEFT_RIGHT)
    return out.crop(out.getbbox())


# Body-part regions for bake-time articulation, as fractions of the cropped
# core (every sheet FACES RIGHT): box=(x0,y0,x1,y1), pivot=the joint the part
# rotates around (hip / tail base / neck). Cutting a painterly sprite at hard
# edges is fine ONLY because every pivot sits ON its cut boundary, so
# displacement at the seam is ~zero and grows toward the extremity.
# "default" fits a chibi upright biped (Ralph); the others account for body
# plan: raptor leans horizontal, trike/bronto/anky are quadrupeds, pterry's
# "legs" slots drive his WINGS (opposite signs = a flap) and "tail" his feet.
PART_DEFS_BY_DINO = {
    "default": {
        "back_leg":  {"box": (0.04, 0.66, 0.46, 1.00), "pivot": (0.30, 0.70)},
        "front_leg": {"box": (0.46, 0.66, 0.96, 1.00), "pivot": (0.62, 0.70)},
        "tail":      {"box": (0.00, 0.22, 0.28, 0.72), "pivot": (0.28, 0.50)},
        "head":      {"box": (0.52, 0.00, 1.00, 0.44), "pivot": (0.58, 0.42)},
    },
    "raptor": {
        "back_leg":  {"box": (0.20, 0.55, 0.55, 1.00), "pivot": (0.40, 0.60)},
        "front_leg": {"box": (0.55, 0.55, 0.92, 1.00), "pivot": (0.70, 0.60)},
        "tail":      {"box": (0.00, 0.05, 0.38, 0.60), "pivot": (0.38, 0.35)},
        "head":      {"box": (0.58, 0.00, 1.00, 0.52), "pivot": (0.62, 0.48)},
    },
    "trike": {
        "back_leg":  {"box": (0.22, 0.68, 0.55, 1.00), "pivot": (0.35, 0.74)},
        "front_leg": {"box": (0.55, 0.68, 0.95, 1.00), "pivot": (0.74, 0.74)},
        "tail":      {"box": (0.00, 0.30, 0.24, 0.78), "pivot": (0.24, 0.52)},
        "head":      {"box": (0.55, 0.00, 1.00, 0.78), "pivot": (0.58, 0.56)},
    },
    "pterry": {
        "back_leg":  {"box": (0.00, 0.30, 0.34, 1.00), "pivot": (0.32, 0.46)},  # far wing
        "front_leg": {"box": (0.66, 0.30, 1.00, 1.00), "pivot": (0.68, 0.46)},  # near wing
        "tail":      {"box": (0.42, 0.84, 0.60, 1.00), "pivot": (0.51, 0.86)},  # feet
        "head":      {"box": (0.42, 0.00, 1.00, 0.42), "pivot": (0.52, 0.40)},
    },
    "bronto": {
        "back_leg":  {"box": (0.10, 0.75, 0.45, 1.00), "pivot": (0.30, 0.80)},
        "front_leg": {"box": (0.45, 0.75, 0.75, 1.00), "pivot": (0.60, 0.80)},
        "tail":      {"box": (0.72, 0.70, 1.00, 1.00), "pivot": (0.72, 0.80)},
        "head":      {"box": (0.00, 0.00, 0.50, 0.55), "pivot": (0.28, 0.52)},  # neck sway
    },
    "anky": {
        "back_leg":  {"box": (0.28, 0.72, 0.55, 1.00), "pivot": (0.40, 0.78)},
        "front_leg": {"box": (0.55, 0.72, 0.80, 1.00), "pivot": (0.65, 0.78)},
        "tail":      {"box": (0.00, 0.45, 0.24, 1.00), "pivot": (0.24, 0.72)},  # club
        "head":      {"box": (0.78, 0.35, 1.00, 0.85), "pivot": (0.80, 0.55)},
    },
}


def _part_layers(core, part_defs, margin=6):
    """Split `core` into (body_remainder, [(part_layer, pivot_px), ...]).
    Each part layer is core-sized so it can rotate in place around its pivot.
    The part is cut `margin` px LARGER than the hole erased from the body, so a
    rotated part always overlaps its own seam (no hairline cracks). The HEAD's
    hole is NOT erased at all: on a chibi body the head is half the sprite, so
    even small angles swing its cut edge past any sane margin — instead the
    unrotated head stays in the body as backing and the rotated copy draws over
    it (residual slivers show head pixels, never a transparent crack)."""
    w, h = core.size
    body = core.copy()
    layers = []
    for name in ("back_leg", "tail", "front_leg", "head"):  # paint order
        d = part_defs[name]
        x0, y0, x1, y1 = (int(round(d["box"][0] * w)), int(round(d["box"][1] * h)),
                          int(round(d["box"][2] * w)), int(round(d["box"][3] * h)))
        gx0, gy0 = max(0, x0 - margin), max(0, y0 - margin)
        gx1, gy1 = min(w, x1 + margin), min(h, y1 + margin)
        mask = Image.new("L", (w, h), 0)
        mask.paste(255, (gx0, gy0, gx1, gy1))
        part = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        part.paste(core, (0, 0), mask)
        if name != "head":
            body.paste((0, 0, 0, 0), (x0, y0, x1, y1))
        pivot = (d["pivot"][0] * w, d["pivot"][1] * h)
        layers.append((name, part, pivot))
    return body, layers


def build_sheet(core, out_sheet, dino):
    """idle(2) walk(4) attack(3): per-part rotation (legs scissor, tail wags,
    head rears/chomps) + the old whole-body squash/waddle/lunge on top."""
    cw0, ch0 = core.size
    pad = 18
    CW, CH = cw0 + pad * 2, ch0 + pad * 2
    part_defs = PART_DEFS_BY_DINO.get(dino, PART_DEFS_BY_DINO["default"])
    body, layers = _part_layers(core, part_defs)

    def articulate(pose):
        """Compose body + each part rotated `pose[name]` degrees about its pivot."""
        out = Image.new("RGBA", (cw0, ch0), (0, 0, 0, 0))
        out.alpha_composite(body)
        for name, part, pivot in layers:
            ang = pose.get(name, 0.0)
            img = part if not ang else part.rotate(
                ang, resample=Image.NEAREST, center=pivot)
            out.alpha_composite(img)
        return out

    def frame(pose=None, scale=(1, 1), rot=0, dx=0, dy=0):
        img = articulate(pose or {})
        if scale != (1, 1):
            img = img.resize((max(1, round(cw0 * scale[0])),
                              max(1, round(ch0 * scale[1]))), Image.LANCZOS)
        if rot:
            img = img.rotate(rot, resample=Image.NEAREST, expand=True)
        cell = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        cell.alpha_composite(img, ((CW - img.width) // 2 + dx,
                                   (CH - img.height) // 2 + dy))
        return cell

    # PIL rotate() is counter-clockwise: positive swings a leg/tail back-left,
    # negative kicks it forward-right (sprite faces right).
    frames = [
        frame({"tail": 3}),                                        # idle breathe
        frame({"tail": -4, "head": 2}, scale=(1.03, 0.97), dy=3),
        frame({"front_leg": -14, "back_leg": 12, "tail": -6}, rot=-2, dy=1),   # step
        frame({"front_leg": -4, "back_leg": 3, "tail": 2, "head": 1},
              scale=(0.99, 1.02), dy=-4),                          # pass (bounce up)
        frame({"front_leg": 12, "back_leg": -14, "tail": 6}, rot=2, dy=1),     # step
        frame({"front_leg": 3, "back_leg": -4, "tail": -2, "head": 1},
              scale=(0.99, 1.02), dy=-4),
        frame({"head": 6, "tail": 7, "front_leg": 4}, rot=3, dx=-6,
              scale=(1.0, 0.96), dy=2),                            # attack windup
        frame({"head": -9, "tail": -6, "front_leg": -8}, rot=-5, dx=14,
              scale=(1.07, 0.97)),                                 # strike (chomp)
        frame({"head": -4, "tail": -2}, rot=-2, dx=7),             # follow-through
    ]
    sheet = Image.new("RGBA", (CW * len(frames), CH), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * CW, 0))
    os.makedirs(os.path.dirname(out_sheet), exist_ok=True)
    sheet.save(out_sheet)
    return CW, CH, len(frames)


def preview(out_sheet, out_preview):
    sheet = Image.open(out_sheet)
    bg = Image.new("RGB", sheet.size, (90, 96, 110))
    bg.paste(sheet, (0, 0), sheet)
    os.makedirs(os.path.dirname(out_preview), exist_ok=True)
    bg.resize((bg.width * 2, bg.height * 2), Image.NEAREST).save(out_preview)


def rects(dino, cw, ch):
    def R(i):
        return f"Rect2({i*cw}, 0, {cw}, {ch})"
    sheet_const = f"SHEET_{dino.upper()}"
    print(f"\n# add const {sheet_const} := \"res://assets/sprites/{dino}_fighter.png\"")
    print(f"# paste into ANIM_LAYOUTS (cell {cw}x{ch}):")
    print(f'"{dino}": {{')
    print(f"    \"sheet\": {sheet_const},")
    print(f'    "idle":   {{"loop": true,  "speed": 4.0,  "rects": [{R(0)}, {R(1)}]}},')
    print(f'    "walk":   {{"loop": true,  "speed": 8.0,  "rects": [{R(2)}, {R(3)}, {R(4)}, {R(5)}]}},')
    print(f'    "attack": {{"loop": false, "speed": 12.0, "rects": [{R(6)}, {R(7)}, {R(8)}]}},')
    print("},")


def main():
    dino = sys.argv[1] if len(sys.argv) > 1 else "ralph"
    if dino not in HERO_SRC:
        sys.exit(f"unknown dino '{dino}'; known: {', '.join(HERO_SRC)}")
    src = os.path.join(ROOT, HERO_SRC[dino])
    if not os.path.exists(src):
        sys.exit(f"no hero art at {src}\n"
                 f"  generate it per scripts/tools/dino_art_prompts.md, then re-run.")
    smooth = "--smooth" in sys.argv
    out_sheet = os.path.join(ROOT, f"assets/sprites/{dino}_fighter.png")
    out_preview = f"/tmp/ralph/{dino}_fighter_preview.png"
    flip = HERO_FACES_LEFT.get(dino, False)
    core = (smoothen if smooth else pixelate)(cutout(Image.open(src)), flip)
    cw, ch, n = build_sheet(core, out_sheet, dino)
    preview(out_sheet, out_preview)
    print(f"wrote {out_sheet}  cell={cw}x{ch}  char_h={core.size[1]}  frames={n}")
    print(f"preview -> {out_preview}")
    rects(dino, cw, ch)


if __name__ == "__main__":
    main()
