"""Bake the 'TINY DINOS' title wordmark from the Jersey 25 pixel font: yellow
TINY and green DINOS, each with a vertical gradient fill, dark outline, and a
faked 3D extrude — the recreated-title look approved from the mockups. Emitted
as TWO tight-cropped transparent PNGs so the title screen can animate them
independently (TINY slams onto DINOS). Run from repo root:
    python3 scripts/tools/gen_title_logo.py
Pure PIL. The font ships in assets/fonts/ (SIL OFL)."""
from PIL import Image, ImageDraw, ImageFont

FONT = "assets/fonts/Jersey25.ttf"
DST_TINY = "assets/sprites/title_tiny.png"
DST_DINOS = "assets/sprites/title_dinos.png"

SIZE = 250      # rendered at on-screen size -> placed at scale 1 for crisp edges
OUTLINE = (20, 17, 26)
YEL_TOP, YEL_BOT = (250, 224, 92), (224, 158, 40)
GRN_TOP, GRN_BOT = (150, 212, 72), (40, 120, 38)
OW = 13         # outline width
DEPTH = 19      # 3D extrude depth (px)
GAP = 1         # vertical gap between the two words (tight stack)


def grad(w, h, top, bot):
    g = Image.new("RGB", (w, h))
    px = g.load()
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(top[i] + (bot[i] - top[i]) * t) for i in range(3))
        for x in range(w):
            px[x, y] = c
    return g


def word(font, text, gtop, gbot):
    """Render one word -> tight RGBA tile (extrude + outline + gradient fill)."""
    tmp = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    bb = tmp.textbbox((0, 0), text, font=font, stroke_width=OW)
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    pad = OW + DEPTH + 6
    layer = Image.new("RGBA", (w + pad * 2, h + pad * 2 + DEPTH), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ox, oy = pad - bb[0], pad - bb[1]
    dark = tuple(int(c * 0.42) for c in gbot)          # extruded side
    for i in range(DEPTH, 0, -1):
        ld.text((ox, oy + i), text, font=font, fill=dark,
                stroke_width=OW, stroke_fill=dark)
    ld.text((ox, oy), text, font=font, fill=OUTLINE,
            stroke_width=OW, stroke_fill=OUTLINE)       # outline + black base
    mask = Image.new("L", layer.size, 0)
    ImageDraw.Draw(mask).text((ox, oy), text, font=font, fill=255)
    layer.paste(grad(*layer.size, gtop, gbot), (0, 0), mask)
    return layer.crop(layer.getbbox())


def main():
    f = ImageFont.truetype(FONT, SIZE)
    tiny = word(f, "TINY", YEL_TOP, YEL_BOT)
    dinos = word(f, "DINOS", GRN_TOP, GRN_BOT)
    tiny.save(DST_TINY)
    dinos.save(DST_DINOS)
    # The title scene stacks them as TINY over DINOS with GAP px between, both
    # centered on x. Print the geometry it needs to recreate that rest layout.
    print("TINY  %dx%d -> %s" % (tiny.width, tiny.height, DST_TINY))
    print("DINOS %dx%d -> %s" % (dinos.width, dinos.height, DST_DINOS))
    print("GAP=%d  stacked_height=%d" % (GAP, tiny.height + GAP + dinos.height))


if __name__ == "__main__":
    main()
