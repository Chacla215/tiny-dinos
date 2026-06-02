"""Ralph -- Tiny Dino, 3/4 hero pose. Default starter look + color presets.

Built modularly (base body + spikes + face + accents) so the character-creator
categories (spikes, hats, chest, tail, color presets) can swap in later. Pure
PIL: draw the union silhouette, grow a soft outline, fill regions, then layer
face + shine + shading. Supersampled then LANCZOS-downscaled for clean edges.

3/4 turn: Ralph faces the viewer's lower-right -- snout juts right, tail curls
out back-left, near arm/foot forward. LOOK test -> /tmp/ralph/. Not in-game.
"""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT = "/tmp/ralph"
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
FONT = os.path.join(ROOT, "assets/fonts/Jersey25.ttf")
S = 4                       # supersample
W = H = 620                 # final canvas

DEFAULT = {
    "scales":   (150, 212, 158), "scales_hi": (188, 234, 192),
    "scales_sh": (112, 178, 130), "belly": (249, 240, 206),
    "belly_sh": (228, 214, 176), "spike": (118, 220, 214),
    "spike_sh": (86, 188, 188), "pad": (210, 168, 116),
    "eye": (246, 188, 52), "eye_sh": (228, 150, 36),
    "cheek": (247, 154, 162), "outline": (44, 66, 62),
    "horn_core": (236, 226, 206),
}


def pal(**over):
    p = dict(DEFAULT)
    p.update(over)
    return p


def _tint(c, k=42):
    return tuple(min(255, v + k) for v in c[:3])


def draw_ralph(p, speckle=False, glow=None, spikes="rounded"):
    """Return an RGBA Ralph (W*S square) on a transparent background, 3/4 pose.
    `spikes` picks the creator's Spikes-category ridge style."""
    s = S
    cv = Image.new("RGBA", (W * s, H * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(cv)

    def E(cx, cy, rx, ry, fill):
        d.ellipse([(cx - rx) * s, (cy - ry) * s, (cx + rx) * s, (cy + ry) * s], fill=fill)

    def P(pts, fill):
        d.polygon([(x * s, y * s) for x, y in pts], fill=fill)

    def L(pts, fill, w):
        d.line([(x * s, y * s) for x, y in pts], fill=fill, width=int(w * s))

    # ---- one ridge spike in the chosen creator style, centred (x,y) size r ----
    col, sh, hi = p["spike"], p["spike_sh"], _tint(p["spike"])

    def spike(x, y, rx, ry, style):
        if style == "rounded":                                  # soft baby bump
            E(x, y, rx, ry, col)
            E(x - rx * .25, y - ry * .25, rx * .42, ry * .42, hi)
        elif style == "crystal":                                # faceted gem
            top, bot = (x, y - ry * 1.25), (x, y + ry * .7)
            l, r = (x - rx * .8, y - ry * .1), (x + rx * .8, y - ry * .1)
            P([top, r, bot, l], col)
            P([top, (x, y - ry * .1), bot, l], hi)
            L([top, bot], sh, 1.4)
        elif style == "flame":                                  # licking flame
            P([(x - rx * .8, y + ry * .2), (x - rx * .5, y - ry * .5),
               (x - rx * .15, y - ry * .1), (x, y - ry * 1.35),
               (x + rx * .25, y - ry * .35), (x + rx * .5, y - ry * .6),
               (x + rx * .8, y + ry * .2)], col)
            P([(x - rx * .4, y + ry * .1), (x, y - ry * .9),
               (x + rx * .35, y + ry * .1)], hi)
        elif style == "ice":                                    # sharp icicle
            P([(x - rx * .58, y + ry * .2), (x, y - ry * 1.4),
               (x + rx * .58, y + ry * .2)], col)
            P([(x - rx * .58, y + ry * .2), (x, y - ry * 1.4),
               (x - rx * .12, y - ry * .1)], hi)
        elif style == "leaf":                                   # pointed leaf
            P([(x, y - ry * 1.2), (x + rx * .72, y - ry * .15),
               (x, y + ry * .55), (x - rx * .72, y - ry * .15)], col)
            L([(x - rx * .12, y - ry * 1.0), (x + rx * .04, y + ry * .4)], sh, 1.4)
        elif style == "dragon":                                 # tall jagged
            P([(x - rx * .52, y + ry * .25), (x - rx * .12, y - ry * 1.65),
               (x + rx * .46, y + ry * .25)], col)
            P([(x - rx * .12, y - ry * 1.65), (x + rx * .46, y + ry * .25),
               (x + rx * .06, y + ry * .25)], sh)
        elif style == "feather":                                # soft plume
            E(x, y - ry * .2, rx * .82, ry * 1.15, col)
            E(x - rx * .28, y - ry * .35, rx * .34, ry * .6, hi)
            L([(x, y - ry * 1.2), (x, y + ry * .5)], sh, 1.4)

    # ================= structural silhouette (back-to-front) =================
    # spike back ridge (poking above the crown, receding back-left)
    for sx, sy, rx, ry in [(286, 100, 30, 40), (244, 110, 28, 36),
                           (206, 142, 25, 32)]:
        spike(sx, sy, rx, ry, spikes)
    # broken horn standing on the crown -- snapped flat, jagged top, bone core
    bx, by, ya = 330, 118, 66
    P([(bx - 22, by + 8), (bx - 16, ya + 10), (bx - 9, ya + 2), (bx - 3, ya + 12),
       (bx + 4, ya - 2), (bx + 11, ya + 9), (bx + 18, ya + 3), (bx + 22, by + 8)],
      p["spike"])
    P([(bx + 4, ya - 2), (bx + 11, ya + 9), (bx + 18, ya + 3), (bx + 22, by + 8),
       (bx + 6, by + 8)], p["spike_sh"])               # shaded right face
    # tail (short, fat, curling out back-left)
    E(200, 476, 48, 42, p["scales"])
    E(154, 436, 35, 32, p["scales"])
    E(124, 394, 26, 25, p["scales"])
    # far (back) limbs
    E(196, 452, 25, 33, p["scales"])                      # far arm peek
    E(252, 526, 40, 30, p["scales"])                      # far foot
    # body (chunky)
    E(300, 452, 128, 116, p["scales"])
    # near (front) limbs
    E(346, 534, 46, 34, p["scales"])                      # near foot
    E(422, 446, 31, 40, p["scales"])                      # near arm
    # head + protruding 3/4 snout
    E(296, 252, 158, 150, p["scales"])
    E(392, 302, 88, 72, p["scales"])

    # ================= soft grown outline around the union ===================
    a = cv.split()[3]
    grow = a.filter(ImageFilter.GaussianBlur(7 * s)).point(lambda v: 255 if v > 40 else 0)
    outline = Image.new("RGBA", cv.size, (0, 0, 0, 0))
    outline.paste(tuple(p["outline"]) + (255,), (0, 0), grow)
    outline.alpha_composite(cv)
    cv = outline
    d = ImageDraw.Draw(cv)

    # ================= shading (clipped to the body via fill mask) ===========
    shade = Image.new("RGBA", cv.size, (0, 0, 0, 0))
    sd = ImageDraw.Draw(shade)
    sd.ellipse([(250 - 116) * s, (206 - 92) * s, (250 + 116) * s, (206 + 92) * s],
               fill=p["scales_hi"] + (150,))              # upper-left highlight
    sd.ellipse([(372 - 138) * s, (476 - 86) * s, (372 + 138) * s, (476 + 86) * s],
               fill=p["scales_sh"] + (120,))              # lower-right shadow
    shade = shade.filter(ImageFilter.GaussianBlur(10 * s))
    shade.putalpha(Image.composite(shade.split()[3], Image.new("L", cv.size, 0), a))
    cv = Image.alpha_composite(cv, shade)
    d = ImageDraw.Draw(cv)

    # belly (cream, on the turned-front), foot pads
    E(330, 462, 82, 96, p["belly"])
    E(330, 498, 82, 60, p["belly_sh"])
    E(330, 456, 78, 90, p["belly"])
    E(346, 546, 28, 16, p["pad"])
    E(252, 540, 22, 13, p["pad"])

    if speckle:                                            # Void Ralph stars
        import random
        rng = random.Random(7)
        for _ in range(90):
            px = rng.randint(150, 440); py = rng.randint(150, 540)
            rr = rng.choice([2, 2, 3])
            d.ellipse([(px - rr) * s, (py - rr) * s, (px + rr) * s, (py + rr) * s],
                      fill=(235, 245, 255, 220))

    # broken-horn detail: exposed bone cross-section + hairline crack
    E(bx - 1, ya + 3, 15, 6, p["horn_core"])
    E(bx - 1, ya + 3, 8, 3, p["belly_sh"])
    d.line([(bx - 3) * s, (ya + 12) * s, (bx - 8) * s, (ya + 28) * s,
            (bx - 2) * s, (by - 6) * s], fill=p["outline"], width=int(1.8 * s))

    # ================= face ==================================================
    cheek = Image.new("RGBA", cv.size, (0, 0, 0, 0))
    cd = ImageDraw.Draw(cheek)
    cd.ellipse([(398 - 30) * s, (320 - 18) * s, (398 + 30) * s, (320 + 18) * s],
               fill=p["cheek"] + (180,))
    cd.ellipse([(250 - 26) * s, (312 - 16) * s, (250 + 26) * s, (312 + 16) * s],
               fill=p["cheek"] + (170,))
    cheek = cheek.filter(ImageFilter.GaussianBlur(5 * s))
    cv = Image.alpha_composite(cv, cheek)
    d = ImageDraw.Draw(cv)

    # eyes -- near (right) bigger, far (left) smaller; pupils look forward-right
    for ex, ey, rx, ry, pdx in [(262, 252, 39, 52, 5), (360, 244, 47, 57, 7)]:
        E(ex, ey, rx + 6, ry + 6, p["outline"])
        E(ex, ey, rx, ry, (255, 255, 255))
        E(ex + pdx, ey + 6, rx - 5, ry - 7, p["eye"])
        E(ex + pdx, ey + 9, int((rx - 5) * 0.62), int((ry - 7) * 0.62), (40, 40, 48))
        E(ex + pdx - 8, ey - 2, 9, 11, (255, 255, 255))      # big shine
        E(ex + pdx + 8, ey + 18, 4, 5, (255, 255, 255, 220))  # small shine
    if glow:
        gl = Image.new("RGBA", cv.size, (0, 0, 0, 0))
        gd = ImageDraw.Draw(gl)
        for ex, ey in [(262, 252), (360, 244)]:
            gd.ellipse([(ex - 40) * s, (ey - 48) * s, (ex + 40) * s, (ey + 48) * s],
                       fill=glow + (110,))
        cv = Image.alpha_composite(cv, gl.filter(ImageFilter.GaussianBlur(7 * s)))
        d = ImageDraw.Draw(cv)

    # nostrils on the snout, wide smile, one tooth
    E(386, 292, 5, 4, p["outline"])
    E(418, 290, 5, 4, p["outline"])
    ow = int(6 * s)
    d.arc([336 * s, 300 * s, 456 * s, 372 * s], 12, 168, fill=p["outline"], width=ow)
    d.rounded_rectangle([388 * s, 348 * s, 406 * s, 372 * s], radius=5 * s,
                        fill=(255, 255, 255), outline=p["outline"], width=int(2 * s))

    return cv.resize((W, H), Image.LANCZOS)


def card(img, bg=(238, 240, 246)):
    c = Image.new("RGB", img.size, bg)
    c.paste(img, (0, 0), img)
    return c


def build_sheet(p=DEFAULT, spikes="rounded", path=None):
    """Bake an in-game sprite sheet: idle(2) walk(4) attack(3), uniform cells,
    character centred. Animation is squash/stretch + a waddle rock done by
    transforming the rendered base (cheap 'juice' to judge motion at scale)."""
    base = draw_ralph(p, spikes=spikes)
    core = base.crop(base.getbbox())
    cw0, ch0 = core.size
    pad = 48
    CW, CH = cw0 + pad * 2, ch0 + pad * 2

    def frame(scale=(1, 1), rot=0, dx=0, dy=0):
        img = core
        if scale != (1, 1):
            img = core.resize((max(1, round(cw0 * scale[0])),
                               max(1, round(ch0 * scale[1]))), Image.LANCZOS)
        if rot:
            img = img.rotate(rot, resample=Image.BICUBIC, expand=True)
        cell = Image.new("RGBA", (CW, CH), (0, 0, 0, 0))
        cell.alpha_composite(img, ((CW - img.width) // 2 + dx,
                                   (CH - img.height) // 2 + dy))
        return cell

    frames = [
        frame(), frame(scale=(1.03, 0.97), dy=4),                 # idle breathe
        frame(rot=-4, dy=2), frame(scale=(0.99, 1.02), dy=-5),    # walk waddle
        frame(rot=4, dy=2), frame(scale=(0.99, 1.02), dy=-5),
        frame(rot=5, dx=-8, scale=(1.0, 0.96), dy=3),             # attack windup
        frame(rot=-6, dx=16, scale=(1.07, 0.97)),                 # strike
        frame(rot=-2, dx=8),                                      # follow-through
    ]
    sheet = Image.new("RGBA", (CW * len(frames), CH), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        sheet.alpha_composite(f, (i * CW, 0))
    path = path or os.path.join(ROOT, "assets/sprites/ralph.png")
    sheet.save(path)
    print(f"wrote {path}  cell={CW}x{CH}  char_h={ch0}  frames={len(frames)}")
    return CW, CH, ch0


def main():
    os.makedirs(OUT, exist_ok=True)
    ralph = draw_ralph(DEFAULT)
    ralph.save(f"{OUT}/ralph_default.png")
    card(ralph).save(f"{OUT}/ralph_default_card.png")
    print("wrote ralph_default")
    build_sheet()                       # -> assets/sprites/ralph.png (in-game)

    presets = [
        ("DEFAULT", DEFAULT),
        ("FOREST", pal(scales=(72, 150, 92), scales_hi=(118, 190, 120),
                       scales_sh=(48, 116, 72), spike=(96, 168, 88),
                       spike_sh=(70, 138, 70))),
        ("VOLCANO", pal(scales=(74, 70, 78), scales_hi=(110, 104, 110),
                        scales_sh=(48, 44, 52), belly=(246, 168, 90),
                        belly_sh=(220, 132, 60), spike=(252, 140, 60),
                        spike_sh=(220, 96, 40), cheek=(250, 120, 70))),
        ("FROZEN", pal(scales=(176, 214, 238), scales_hi=(214, 238, 250),
                       scales_sh=(140, 184, 220), belly=(244, 250, 255),
                       belly_sh=(216, 230, 246), spike=(150, 224, 244),
                       spike_sh=(110, 190, 226))),
        ("GOLDEN", pal(scales=(238, 196, 92), scales_hi=(252, 226, 150),
                       scales_sh=(206, 158, 60), belly=(252, 248, 232),
                       belly_sh=(232, 222, 196), spike=(64, 96, 200),
                       spike_sh=(44, 70, 162))),
    ]
    cells = [draw_ralph(p) for _, p in presets]
    labels = [n for n, _ in presets]
    cells.append(draw_ralph(pal(scales=(70, 52, 104), scales_hi=(104, 80, 150),
                                 scales_sh=(48, 34, 78), belly=(120, 96, 168),
                                 belly_sh=(98, 76, 142), spike=(96, 226, 232),
                                 spike_sh=(60, 180, 196), cheek=(150, 120, 200)),
                            speckle=True, glow=(120, 230, 240)))
    labels.append("VOID")

    n = len(cells)
    cw = int(W * 0.62)
    sheet = Image.new("RGB", (cw * n, int(H * 0.62) + 56), (244, 246, 250))
    sd = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype(FONT, 30)
    except Exception:
        font = ImageFont.load_default()
    for i, (im, name) in enumerate(zip(cells, labels)):
        small = im.resize((cw, int(H * 0.62 / W * cw)), Image.LANCZOS)
        sheet.paste(small, (i * cw, 8), small)
        wd = sd.textlength(name, font=font)
        sd.text((i * cw + (cw - wd) / 2, sheet.height - 42), name, font=font,
                fill=(60, 70, 84))
    sheet.save(f"{OUT}/ralph_presets.png")
    print("wrote ralph_presets")

    # ---- creator category demo: swappable Spikes (shape) on the one base ----
    spike_styles = [
        ("ROUNDED", "rounded", DEFAULT),
        ("CRYSTAL", "crystal", pal(spike=(150, 226, 240), spike_sh=(108, 186, 214))),
        ("FLAME", "flame", pal(spike=(252, 150, 60), spike_sh=(224, 96, 40))),
        ("ICE", "ice", pal(spike=(204, 236, 250), spike_sh=(150, 200, 232))),
        ("LEAF", "leaf", pal(spike=(120, 196, 96), spike_sh=(84, 154, 74))),
        ("DRAGON", "dragon", pal(spike=(198, 78, 72), spike_sh=(150, 50, 50))),
        ("FEATHER", "feather", pal(spike=(210, 238, 240), spike_sh=(150, 196, 210))),
    ]
    cells = [draw_ralph(p, spikes=st) for _, st, p in spike_styles]
    labels = [n for n, _, _ in spike_styles]
    n = len(cells)
    cw = int(W * 0.52)
    sheet = Image.new("RGB", (cw * n, int(H * 0.52) + 56), (244, 246, 250))
    sd = ImageDraw.Draw(sheet)
    for i, (im, name) in enumerate(zip(cells, labels)):
        small = im.resize((cw, int(H * 0.52 / W * cw)), Image.LANCZOS)
        sheet.paste(small, (i * cw, 8), small)
        wd = sd.textlength(name, font=font)
        sd.text((i * cw + (cw - wd) / 2, sheet.height - 42), name, font=font,
                fill=(60, 70, 84))
    sheet.save(f"{OUT}/ralph_spikes.png")
    print("wrote ralph_spikes")


if __name__ == "__main__":
    main()
