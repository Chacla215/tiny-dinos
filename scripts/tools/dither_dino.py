"""Apply the arena's exact pixel-dither finish to a character sprite, so dinos
sit in the same texture world as the flat-cartoon battlegrounds.

Mirrors gen_island_bgs.py: same BAYER8 matrix, amp=16, posterize(5), and a
PIX=2 block grid in 1536x864 *world-image* space -- so a dino scaled to its
real in-game size dithers on the same grid as the arena behind it.

This is a LOOK test (outputs to /tmp/dino_dither/), not wired into the game.
"""
import os
from PIL import Image, ImageChops, ImageOps, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = "/tmp/dino_dither"
FONT = os.path.join(ROOT, "assets/fonts/Jersey25.ttf")
PIX = 2                       # same block size the arenas use (1536x864 space)
INGAME_H = 150                # dino height in world-image space (~120px on the 720p screen)

# 8x8 Bayer matrix (0..63) -- copied verbatim from gen_island_bgs.py
BAYER8 = [
    [0, 32, 8, 40, 2, 34, 10, 42], [48, 16, 56, 24, 50, 18, 58, 26],
    [12, 44, 4, 36, 14, 46, 6, 38], [60, 28, 52, 20, 62, 30, 54, 22],
    [3, 35, 11, 43, 1, 33, 9, 41], [51, 19, 59, 27, 49, 17, 57, 25],
    [15, 47, 7, 39, 13, 45, 5, 37], [63, 31, 55, 23, 61, 29, 53, 21],
]


def dither(small, amp):
    """Ordered (Bayer 8x8) luminance nudge -- identical to gen_island_bgs.py."""
    w, h = small.size
    tile = Image.new("L", (8, 8))
    tile.putdata([int(round((BAYER8[y][x] / 63.0 - 0.5) * amp)) + 128
                  for y in range(8) for x in range(8)])
    full = Image.new("L", (w, h))
    for oy in range(0, h, 8):
        for ox in range(0, w, 8):
            full.paste(tile, (ox, oy))
    pos = full.point(lambda v: max(0, v - 128)).convert("RGB")
    neg = full.point(lambda v: max(0, 128 - v)).convert("RGB")
    return ImageChops.subtract(ImageChops.add(small, pos), neg)


def dither_sprite(img, pix):
    """Dither+posterize an RGBA sprite on a `pix`-block grid, keeping a clean
    (grid-aligned) alpha edge so it reads as pixel art."""
    w, h = img.size
    sw, sh = max(1, w // pix), max(1, h // pix)
    rgb = img.convert("RGB").resize((sw, sh), Image.LANCZOS)
    rgb = dither(rgb, amp=16)
    rgb = ImageOps.posterize(rgb, 5)
    rgb = rgb.resize((w, h), Image.NEAREST)
    a = img.getchannel("A").resize((sw, sh), Image.LANCZOS)
    a = a.point(lambda v: 255 if v > 128 else 0).resize((w, h), Image.NEAREST)
    out = rgb.convert("RGBA")
    out.putalpha(a)
    return out


def scale_to_h(img, target_h):
    w, h = img.size
    return img.resize((round(w * target_h / h), target_h), Image.LANCZOS)


def checker(size, a=(70, 76, 92), b=(58, 63, 78), c=16):
    bg = Image.new("RGB", size, a)
    d = ImageDraw.Draw(bg)
    for y in range(0, size[1], c):
        for x in range(0, size[0], c):
            if (x // c + y // c) % 2:
                d.rectangle([x, y, x + c, y + c], fill=b)
    return bg


def main():
    os.makedirs(OUT, exist_ok=True)
    src = Image.open(os.path.join(ROOT, "assets/concept/dinos/trex.png")).convert("RGBA")

    # dino at true in-game size, then dithered on the arena's grid
    ingame = scale_to_h(src, INGAME_H)
    d2 = dither_sprite(ingame, PIX)          # faithful match to arenas (pix=2)
    d3 = dither_sprite(ingame, 3)            # chunkier alt for comparison

    # ---- panel 1: zoomed comparison so the stipple is actually visible ----
    Z = 3
    def zoom(im):
        return im.resize((im.width * Z, im.height * Z), Image.NEAREST)
    cells = [("ORIGINAL (flat)", scale_to_h(src, INGAME_H)),
             ("DITHER pix=2  (matches arenas)", d2),
             ("DITHER pix=3  (chunkier)", d3)]
    pad, lblh = 30, 46
    cw = max(zoom(im).width for _, im in cells) + pad * 2
    ch = max(zoom(im).height for _, im in cells) + pad + lblh
    sheet = checker((cw * 3, ch))
    try:
        font = ImageFont.truetype(FONT, 26)
    except Exception:
        font = ImageFont.load_default()
    dr = ImageDraw.Draw(sheet)
    for i, (label, im) in enumerate(cells):
        z = zoom(im)
        x = i * cw + (cw - z.width) // 2
        sheet.paste(z, (x, lblh + (ch - lblh - z.height) // 2 - pad // 2), z)
        dr.text((i * cw + pad, 10), label, font=font, fill=(240, 244, 255))
    sheet.save(f"{OUT}/compare.png")
    print("wrote", f"{OUT}/compare.png")

    # ---- panel 2: in-context, true size, on real arenas (grids aligned) ----
    for arena, x, y in [("sunny_springs_bg", 470, 470), ("laughing_lava_bg", 470, 470)]:
        bg = Image.open(os.path.join(ROOT, f"assets/tilesets/{arena}.png")).convert("RGB")
        comp = bg.copy()
        comp.paste(d2, (x, y - d2.height), d2)
        crop = comp.crop((x - 260, y - d2.height - 60, x + d2.width + 260, y + 90))
        crop = crop.resize((crop.width * 2, crop.height * 2), Image.NEAREST)
        crop.save(f"{OUT}/incontext_{arena}.png")
        print("wrote", f"{OUT}/incontext_{arena}.png")


if __name__ == "__main__":
    main()
