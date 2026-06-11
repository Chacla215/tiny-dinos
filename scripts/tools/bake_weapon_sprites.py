"""Bake the concept weapon PNGs into in-match sprites.

Source: assets/concept/weapons/<name>.png (vertical, blade-up, 300px tall,
flat-cartoon with dark outlines). Output: assets/sprites/weapons/<id>.png,
rotated blade-toward-+X (the convention dino.gd uses for held weapons: the
sprite rotates to `facing`), alpha-trimmed, LANCZOS-downscaled to ~TARGET_LEN
long, with a touch of warmth so they sit in the painterly dioramas instead of
reading as UI vectors.

Run: python3 scripts/tools/bake_weapon_sprites.py
"""
import os
from PIL import Image, ImageEnhance

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "assets/concept/weapons")
DST = os.path.join(ROOT, "assets/sprites/weapons")

# weapon id (MatchConfig.WEAPONS key) -> source file. Length is the baked
# long-axis size in px; heavier weapons read bigger in hand.
WEAPONS = {
    "sword":     ("sword.png", 46),
    "dagger":    ("dagger.png", 32),
    "axe":       ("axe.png", 46),
    "mace":      ("mace.png", 46),
    "hammer":    ("warhammer.png", 52),
    "nunchucks": ("nunchucks.png", 38),
    "bow":       ("bow.png", 44),
}

# warhammer.png shipped with an opaque slate background instead of alpha.
BG_KEY = (31, 45, 61)
BG_TOL = 28


def key_background(im: Image.Image) -> Image.Image:
    px = im.load()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a > 0 and abs(r - BG_KEY[0]) + abs(g - BG_KEY[1]) + abs(b - BG_KEY[2]) <= BG_TOL:
                px[x, y] = (0, 0, 0, 0)
    return im


def bake(wid: str, fname: str, target_len: int) -> None:
    im = Image.open(os.path.join(SRC, fname)).convert("RGBA")
    corner = im.getpixel((0, 0))
    if corner[3] == 255:
        im = key_background(im)
    im = im.crop(im.getbbox())
    # Blade-up -> blade-toward-+X (90 degrees clockwise).
    im = im.rotate(-90, expand=True)
    s = target_len / im.width
    im = im.resize((max(1, round(im.width * s)), max(1, round(im.height * s))),
                   Image.LANCZOS)
    # Slight warmth + softness so the flat vectors sit in the painterly world.
    im = ImageEnhance.Color(im).enhance(1.08)
    im = ImageEnhance.Brightness(im).enhance(1.03)
    im.save(os.path.join(DST, "%s.png" % wid))
    print("baked %-10s %dx%d" % (wid, im.width, im.height))


def main() -> None:
    os.makedirs(DST, exist_ok=True)
    for wid, (fname, target_len) in WEAPONS.items():
        bake(wid, fname, target_len)


if __name__ == "__main__":
    main()
