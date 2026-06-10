#!/usr/bin/env python3
"""Turn the EXISTING painterly Ralph hero into an in-match pixel-art fighter sheet.

No new art: loads assets/concept/ralph/ralph_hero.png, keys out its flat blue-grey
background, shrinks it to fighter size, runs it through the SAME Bayer dither the
island backgrounds use (so Ralph reads as pixel art on the pixel islands), then
bakes idle(2)/walk(4)/attack(3) frames via cheap transforms (same recipe as
gen_ralph.py). Output: assets/sprites/ralph_fighter.png + a contact preview, and it
prints the Rect2 cells for dino.gd ANIM_LAYOUTS.

Run:  python3 scripts/tools/gen_ralph_fighter.py
"""
import os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
HERO = os.path.join(ROOT, "assets/concept/ralph/ralph_hero.png")
OUT_SHEET = os.path.join(ROOT, "assets/sprites/ralph_fighter.png")
OUT_PREVIEW = "/tmp/ralph/ralph_fighter_preview.png"

CHAR_H = 132          # target character height in px (reads ~1:1 at gameplay scale)
BG = (125, 136, 158)  # measured flat hero background
KEY_LO, KEY_HI = 34, 70   # color-distance band for the alpha ramp (soft edges)
POSTERIZE = 6         # levels/channel -> flatten painterly gradients toward pixels
DITHER_AMP = 12       # Bayer stipple strength (islands use ~16)
FLIP_TO_FACE_RIGHT = True

# 8x8 Bayer matrix (same as gen_island_bgs.py) for ordered dithering.
BAYER8 = [
    [0, 48, 12, 60, 3, 51, 15, 63], [32, 16, 44, 28, 35, 19, 47, 31],
    [8, 56, 4, 52, 11, 59, 7, 55], [40, 24, 36, 20, 43, 27, 39, 23],
    [2, 50, 14, 62, 1, 49, 13, 61], [34, 18, 46, 30, 33, 17, 45, 29],
    [10, 58, 6, 54, 9, 57, 5, 53], [42, 26, 38, 22, 41, 25, 37, 21],
]


def cutout(im):
    """Key out the flat BG with a soft distance ramp -> RGBA with clean edges."""
    im = im.convert("RGB")
    w, h = im.size
    src = im.load()
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()
    for y in range(h):
        for x in range(w):
            r, g, b = src[x, y]
            d = ((r - BG[0]) ** 2 + (g - BG[1]) ** 2 + (b - BG[2]) ** 2) ** 0.5
            if d <= KEY_LO:
                a = 0
            elif d >= KEY_HI:
                a = 255
            else:
                a = int(round((d - KEY_LO) / (KEY_HI - KEY_LO) * 255))
            dst[x, y] = (r, g, b, a)
    return out.crop(out.getbbox())


def pixelate(rgba):
    """Downscale to CHAR_H, posterize + Bayer-dither the RGB, keep the alpha."""
    w, h = rgba.size
    scale = CHAR_H / h
    small = rgba.resize((max(1, round(w * scale)), CHAR_H), Image.LANCZOS)
    r, g, b, a = small.split()
    rgb = Image.merge("RGB", (r, g, b))
    # posterize toward flat pixel bands
    step = 255 / (POSTERIZE - 1)
    rgb = rgb.point(lambda v: int(round(round(v / step) * step)))
    # ordered Bayer dither
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
    # harden alpha edges so they don't look fuzzy at pixel scale
    a = a.point(lambda v: 0 if v < 110 else 255)
    out = Image.merge("RGBA", (*rgb.split(), a))
    if FLIP_TO_FACE_RIGHT:
        out = out.transpose(Image.FLIP_LEFT_RIGHT)
    return out.crop(out.getbbox())


def build_sheet(core):
    """idle(2) walk(4) attack(3) via squash/waddle/lunge transforms of `core`."""
    cw0, ch0 = core.size
    pad = 14
    CW, CH = cw0 + pad * 2, ch0 + pad * 2

    def frame(scale=(1, 1), rot=0, dx=0, dy=0):
        img = core
        if scale != (1, 1):
            img = core.resize((max(1, round(cw0 * scale[0])),
                               max(1, round(ch0 * scale[1]))), Image.LANCZOS)
        if rot:
            img = img.rotate(rot, resample=Image.NEAREST, expand=True)
        cell = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        cell.alpha_composite(img, ((CW - img.width) // 2 + dx,
                                   (CH - img.height) // 2 + dy))
        return cell

    frames = [
        frame(), frame(scale=(1.03, 0.97), dy=3),                 # idle breathe
        frame(rot=-4, dy=1), frame(scale=(0.99, 1.02), dy=-4),    # walk waddle
        frame(rot=4, dy=1), frame(scale=(0.99, 1.02), dy=-4),
        frame(rot=4, dx=-6, scale=(1.0, 0.96), dy=2),             # attack windup
        frame(rot=-6, dx=14, scale=(1.07, 0.97)),                 # strike
        frame(rot=-2, dx=7),                                      # follow-through
    ]
    sheet = Image.new("RGBA", (CW * len(frames), CH), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * CW, 0))
    os.makedirs(os.path.dirname(OUT_SHEET), exist_ok=True)
    sheet.save(OUT_SHEET)
    return CW, CH, len(frames)


def preview(cw, ch, n):
    """A contact sheet on a mid-grey so transparent areas are obvious."""
    sheet = Image.open(OUT_SHEET)
    bg = Image.new("RGB", sheet.size, (90, 96, 110))
    bg.paste(sheet, (0, 0), sheet)
    os.makedirs(os.path.dirname(OUT_PREVIEW), exist_ok=True)
    bg.resize((bg.width * 2, bg.height * 2), Image.NEAREST).save(OUT_PREVIEW)


def rects(cw, ch):
    """Print the ANIM_LAYOUTS rects (idle 0-1, walk 2-5, attack 6-8)."""
    def R(i):
        return f"Rect2({i*cw}, 0, {cw}, {ch})"
    print(f"\n# paste into ANIM_LAYOUTS (cell {cw}x{ch}):")
    print('"ralph": {')
    print("    \"sheet\": SHEET_RALPH,")
    print(f'    "idle":   {{"loop": true,  "speed": 4.0,  "rects": [{R(0)}, {R(1)}]}},')
    print(f'    "walk":   {{"loop": true,  "speed": 8.0,  "rects": [{R(2)}, {R(3)}, {R(4)}, {R(5)}]}},')
    print(f'    "attack": {{"loop": false, "speed": 12.0, "rects": [{R(6)}, {R(7)}, {R(8)}]}},')
    print("},")


def main():
    hero = Image.open(HERO)
    core = pixelate(cutout(hero))
    cw, ch, n = build_sheet(core)
    preview(cw, ch, n)
    print(f"wrote {OUT_SHEET}  cell={cw}x{ch}  char_h={core.size[1]}  frames={n}")
    print(f"preview -> {OUT_PREVIEW}")
    rects(cw, ch)


if __name__ == "__main__":
    main()
