"""Generate rich pixel-art landscape backgrounds for all 5 battlegrounds.

Best-effort procedural take on the "Purple Fields" reference: layered scenery
(gradient sky + clouds, snow-capped mountain ranges, rolling themed fields, a
worn foreground battle arena), themed per island, finished with a posterize +
nearest-neighbour pass for a pixel-art feel. Captures the composition/palette,
NOT hand-painted detail.

Sizing for "make the place bigger": the canvas is 1536x864 (the gameplay world
stays 1280x720). Each arena's Camera2D zooms out to 0.8333 and keeps its bg
Sprite2D centred at (640,360), so the 1536x864 image covers world
(-128..1408, -72..792) and the extra scenery frames the action. Gameplay coords
are unchanged, so when painting hazards we shift world -> image by +OFF.

The hazard regions (lava / water that kills) are read straight from each arena
.tscn's "Water" Area2D so the painted danger lines up with the real kill zone
(main.gd draws no tint over the bg -- the image is the only hazard cue).

Pure PIL, no numpy. Run from repo root:
    python3 scripts/tools/gen_island_bgs.py
"""
import re
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageFont, ImageChops

W, H = 1536, 864          # background canvas (world is 1280x720, centred)
OFF = (128, 72)           # world -> image offset (world 0,0 sits at image 128,72)
PIX = 2                   # pixel-art block size (image is downsampled to W/PIX then NN-upscaled)

TILES = "assets/tilesets"
SCENES = "scenes"
FONT = "assets/fonts/Jersey25.ttf"   # shared with the title wordmark (SIL OFL)
FRAME = (26, 32, 50)      # dark card border

# 8x8 Bayer matrix (0..63) for ordered dithering -> turns the posterize banding
# into pixel-art stipple instead of flat vector fills.
BAYER8 = [
    [0, 32, 8, 40, 2, 34, 10, 42], [48, 16, 56, 24, 50, 18, 58, 26],
    [12, 44, 4, 36, 14, 46, 6, 38], [60, 28, 52, 20, 62, 30, 54, 22],
    [3, 35, 11, 43, 1, 33, 9, 41], [51, 19, 59, 27, 49, 17, 57, 25],
    [15, 47, 7, 39, 13, 45, 5, 37], [63, 31, 55, 23, 61, 29, 53, 21],
]


# ----------------------------------------------------------------------------
# colour / gradient helpers
# ----------------------------------------------------------------------------
def lerp(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def band_gradient(stops, size=(W, H)):
    """Vertical gradient through (pos0..1, color) stops."""
    w, h = size
    img = Image.new("RGB", (1, h))
    px = img.load()
    stops = sorted(stops, key=lambda s: s[0])
    for y in range(h):
        t = y / max(1, h - 1)
        c = stops[-1][1]
        for i in range(len(stops) - 1):
            p0, c0 = stops[i]
            p1, c1 = stops[i + 1]
            if t <= p0:
                c = c0
                break
            if p0 <= t <= p1:
                c = lerp(c0, c1, (t - p0) / max(1e-6, p1 - p0))
                break
        px[0, y] = c
    return img.resize((w, h)).convert("RGBA")


# ----------------------------------------------------------------------------
# scenery elements
# ----------------------------------------------------------------------------
def cloud(d, cx, cy, scale, seed, color=(255, 255, 255, 235)):
    rnd = random.Random(seed)
    shade = (lerp(color[:3], (180, 195, 215), 0.35)) + (color[3],)
    lobes = [(0, 8, 1.0), (-1.0, 4, 0.8), (1.0, 4, 0.8), (-1.9, 10, 0.6),
             (1.9, 10, 0.6), (-0.5, -2, 0.7), (0.7, -2, 0.7)]
    # soft underside
    for ox, oy, r in lobes:
        x = cx + ox * scale * 9
        y = cy + (oy + 6) * scale * 0.6
        rr = r * scale * 14
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=shade)
    for ox, oy, r in lobes:
        x = cx + ox * scale * 9 + rnd.uniform(-2, 2)
        y = cy + oy * scale * 0.6
        rr = r * scale * 14
        d.ellipse([x - rr, y - rr, x + rr, y + rr], fill=color)


def mountain_range(d, base_y, height, color, seed, jag=9, snow=None,
                   snow_frac=0.32, faces=True):
    """Jagged ridge silhouette spanning the width with faceted light/shadow
    sides (low-poly look) and optional zigzag snow caps."""
    rnd = random.Random(seed)
    n = jag
    peaks = []
    pts = [(-20, H)]
    for i in range(n + 1):
        x = -20 + (W + 40) * i / n
        peak = height * (0.45 + 0.55 * rnd.random())
        y = base_y - peak
        peaks.append((x, y, peak))
        pts.append((x, y))
    pts.append((W + 20, H))
    d.polygon(pts, fill=color)
    # faceted shading: each slope is lit (ascending, sun from the left) or in
    # shadow (descending). Strips partition the width so they never overlap.
    if faces:
        light = lerp(color, (255, 255, 255), 0.22)
        shade = lerp(color, (0, 0, 0), 0.26)
        # Wedge directly under each slope (no flat bottom): descending slopes
        # face away from the sun (shadow), ascending slopes catch light.
        for i in range(len(peaks) - 1):
            x0, y0, _ = peaks[i]
            x1, y1, _ = peaks[i + 1]
            if y1 > y0:
                d.polygon([(x0, y0), (x1, y1), (x0, y1)], fill=shade + (104,))
            else:
                d.polygon([(x0, y0), (x1, y1), (x1, y0)], fill=light + (70,))
    if snow:
        ssh = lerp(snow, (120, 132, 168), 0.4) + (190,)
        for x, y, peak in peaks:
            cap = peak * snow_frac
            if cap < 10:
                continue
            yb = y + cap
            # irregular zigzag cap rather than a clean triangle
            d.polygon([(x - cap * 0.95, yb), (x - cap * 0.34, yb - cap * 0.42),
                       (x, y), (x + cap * 0.34, yb - cap * 0.42),
                       (x + cap * 0.95, yb)], fill=snow)
            d.polygon([(x, y), (x + cap * 0.34, yb - cap * 0.42),
                       (x + cap * 0.95, yb)], fill=ssh)   # shadow on right face


def rolling_hills(d, region, bands, seed):
    """Soft overlapping ellipse hills to texture a field, back-to-front."""
    rnd = random.Random(seed)
    x0, y0, x1, y1 = region
    for i, col in enumerate(bands):
        cy = y0 + (y1 - y0) * (i + 0.5) / len(bands)
        for k in range(3):
            cx = x0 + (x1 - x0) * (k + rnd.uniform(-0.2, 0.2)) / 2.0
            w = (x1 - x0) * rnd.uniform(0.5, 0.8)
            hh = (y1 - y0) * 0.5
            d.ellipse([cx - w, cy, cx + w, cy + hh * 2], fill=col)


def speckle(d, region, color, n, rmin, rmax, seed):
    rnd = random.Random(seed)
    x0, y0, x1, y1 = region
    for _ in range(n):
        x = rnd.uniform(x0, x1)
        y = rnd.uniform(y0, y1)
        r = rnd.uniform(rmin, rmax)
        d.ellipse([x - r, y - r, x + r, y + r], fill=color)


def field_strokes(d, region, color, n, seed, length=10, vert=True):
    """Little tufts / flower dabs; denser + bigger toward the bottom (nearer)."""
    rnd = random.Random(seed)
    x0, y0, x1, y1 = region
    for _ in range(n):
        x = rnd.uniform(x0, x1)
        t = rnd.random()
        y = y0 + (y1 - y0) * (t ** 0.5)          # bias downward
        s = length * (0.5 + t)
        if vert:
            d.line([x, y, x, y - s], fill=color, width=max(1, int(s * 0.25)))
        else:
            d.ellipse([x - s * 0.3, y - s * 0.3, x + s * 0.3, y + s * 0.3],
                      fill=color)


def arena_floor(base, cx, cy, rw, rh, dirt, dirt_dark, seed, rim=None):
    """A worn elliptical battle clearing in the foreground."""
    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer, "RGBA")
    if rim:
        d.ellipse([cx - rw - 10, cy - rh - 8, cx + rw + 10, cy + rh + 8],
                  fill=rim)
    d.ellipse([cx - rw, cy - rh, cx + rw, cy + rh], fill=dirt)
    d.ellipse([cx - rw * 0.7, cy - rh * 0.6, cx + rw * 0.7, cy + rh * 0.6],
              fill=lerp(dirt, dirt_dark, 0.35) + (255,))
    speckle(d, (cx - rw, cy - rh, cx + rw, cy + rh), dirt_dark + (170,),
            60, 2, 6, seed)
    # feather the patch edge so it reads as worn ground, not a hard disc
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).ellipse([cx - rw - 6, cy - rh - 6, cx + rw + 6,
                                  cy + rh + 6], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(10))
    base.paste(layer, (0, 0), Image.composite(mask, Image.new("L", (W, H), 0),
                                              mask))


# ----------------------------------------------------------------------------
# hazard mask (read from the arena .tscn, mapped world -> image with OFF)
# ----------------------------------------------------------------------------
def hazard_masks(scene, blur=24):
    txt = open(f"{SCENES}/{scene}.tscn").read()
    sizes = {}
    for s in re.finditer(
        r'\[sub_resource type="RectangleShape2D" id="([^"]+)"\]\s*\nsize = '
        r"Vector2\(([^,]+), ([^)]+)\)", txt):
        sizes[s.group(1)] = (float(s.group(2)), float(s.group(3)))
    raw = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(raw)
    found = False
    for block in re.split(r"\n\[node ", txt):
        if 'parent="Water"' not in block:
            continue
        pos = re.search(r"position = Vector2\(([^,]+), ([^)]+)\)", block)
        shp = re.search(r'shape = SubResource\("([^"]+)"\)', block)
        if pos and shp and shp.group(1) in sizes:
            cx = float(pos.group(1)) + OFF[0]
            cy = float(pos.group(2)) + OFF[1]
            sw, sh = sizes[shp.group(1)]
            d.rectangle([cx - sw / 2, cy - sh / 2, cx + sw / 2, cy + sh / 2],
                        fill=255)
            found = True
    if not found:
        return None, None
    blurred = raw.filter(ImageFilter.GaussianBlur(blur))
    fill = blurred.point(lambda v: 255 if v > 128 else 0)
    inner = blurred.point(lambda v: 255 if v > 168 else 0)
    outer = blurred.point(lambda v: 255 if v > 92 else 0)
    rim = Image.composite(Image.new("L", (W, H), 255),
                          Image.new("L", (W, H), 0), outer)
    rim = Image.composite(Image.new("L", (W, H), 0), rim, inner)
    return fill, rim


def paint_water(base, fill, rim, top, bottom, foam=(246, 251, 255),
                streaks=False, seed=5):
    body = band_gradient([(0.0, top), (1.0, bottom)])
    bd = ImageDraw.Draw(body, "RGBA")
    if streaks:
        rnd = random.Random(seed)
        for _ in range(120):
            x = rnd.uniform(0, W)
            y = rnd.uniform(0, H * 0.7)
            ln = rnd.uniform(40, 160)
            bd.line([x, y, x, y + ln], fill=(225, 240, 250, 130),
                    width=int(rnd.uniform(2, 6)))
    else:
        speckle(bd, (0, 0, W, H), lerp(top, (255, 255, 255), 0.3) + (130,),
                70, 12, 30, seed)
    base.paste(body, (0, 0), fill)
    f = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(f, "RGBA").bitmap((0, 0), rim, fill=foam + (255,))
    base.alpha_composite(f.filter(ImageFilter.GaussianBlur(3)))


def paint_glow(base, rim, color, blur=5):
    g = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(g, "RGBA").bitmap((0, 0), rim, fill=color + (255,))
    base.alpha_composite(g.filter(ImageFilter.GaussianBlur(blur)))


# ----------------------------------------------------------------------------
# title heading -- "<ISLAND NAME>" over a "BATTLE GROUND" banner, baked in the
# top frame band so it survives the pixelate pass and matches the title screen
# ----------------------------------------------------------------------------
def _grad_rgba(size, top, bot):
    return band_gradient([(0.0, top), (1.0, bot)], size=size)


def text_block(text, font, gtop, gbot, outline=(34, 24, 46), ow=7, depth=7):
    """One word/line -> tight RGBA tile: dark outline + faked 3D extrude +
    vertical gradient fill (same recipe as the TINY DINOS wordmark)."""
    tmp = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    bb = tmp.textbbox((0, 0), text, font=font, stroke_width=ow)
    w, h = bb[2] - bb[0], bb[3] - bb[1]
    pad = ow + depth + 10
    layer = Image.new("RGBA", (w + pad * 2, h + pad * 2 + depth), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ox, oy = pad - bb[0], pad - bb[1]
    dark = tuple(int(c * 0.40) for c in gbot)
    for i in range(depth, 0, -1):
        ld.text((ox, oy + i), text, font=font, fill=dark,
                stroke_width=ow, stroke_fill=dark)
    ld.text((ox, oy), text, font=font, fill=outline,
            stroke_width=ow, stroke_fill=outline)
    mask = Image.new("L", layer.size, 0)
    ImageDraw.Draw(mask).text((ox, oy), text, font=font, fill=255)
    layer.paste(_grad_rgba(layer.size, gtop, gbot), (0, 0), mask)
    return layer.crop(layer.getbbox())


def icon_flower(d, cx, cy, r, petal, core):
    for k in range(5):
        a = k * 2 * math.pi / 5 - math.pi / 2
        ox, oy = cx + math.cos(a) * r, cy + math.sin(a) * r
        d.ellipse([ox - r * 0.74, oy - r * 0.74, ox + r * 0.74, oy + r * 0.74],
                  fill=petal)
    d.ellipse([cx - r * 0.5, cy - r * 0.5, cx + r * 0.5, cy + r * 0.5],
              fill=core)


def icon_sun(d, cx, cy, r, petal, core):
    for k in range(8):
        a = k * math.pi / 4
        d.line([cx + math.cos(a) * r * 1.05, cy + math.sin(a) * r * 1.05,
                cx + math.cos(a) * r * 1.6, cy + math.sin(a) * r * 1.6],
               fill=petal, width=5)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=core)


def icon_drop(d, cx, cy, r, petal, core):
    d.ellipse([cx - r, cy - r * 0.4, cx + r, cy + r * 1.3], fill=core)
    d.polygon([(cx - r * 0.78, cy + r * 0.2), (cx, cy - r * 1.4),
               (cx + r * 0.78, cy + r * 0.2)], fill=core)
    d.ellipse([cx - r * 0.42, cy + r * 0.1, cx + r * 0.1, cy + r * 0.7],
              fill=petal)   # highlight


def icon_flame(d, cx, cy, r, petal, core):
    d.polygon([(cx, cy - r * 1.5), (cx + r * 0.95, cy + r * 0.6),
               (cx + r * 0.5, cy + r), (cx - r * 0.5, cy + r),
               (cx - r * 0.95, cy + r * 0.6)], fill=core)
    d.polygon([(cx, cy - r * 0.5), (cx + r * 0.5, cy + r * 0.55),
               (cx - r * 0.5, cy + r * 0.55)], fill=petal)   # inner flame


def draw_title(base, name, gtop, gbot, accent, icon=None,
               icon_petal=(255, 255, 255, 255), icon_core=(255, 255, 255, 255),
               max_w=880):
    """Bake '<NAME>' + a 'BATTLE GROUND' banner centred in the top frame band.
    Auto-shrinks the name (incl. its flanking icons) so it stays clear of the
    corner HUD score labels. Pass a smaller max_w for long names (e.g. 3-word)."""
    size = 96
    tmp = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    tw = tmp.textbbox((0, 0), name.upper(),
                      font=ImageFont.truetype(FONT, size), stroke_width=7)[2]
    if tw > max_w:                                 # keep within the centre band
        size = max(46, int(size * max_w / tw))
    title = text_block(name.upper(), ImageFont.truetype(FONT, size),
                       gtop, gbot)
    tx, ty = (W - title.width) // 2, 24
    base.alpha_composite(title, (tx, ty))

    sub = text_block("BATTLE GROUND", ImageFont.truetype(FONT, 40),
                     (240, 236, 248), (202, 194, 222), ow=4, depth=4)
    sx, sy = (W - sub.width) // 2, ty + title.height - 8
    base.alpha_composite(sub, (sx, sy))

    d = ImageDraw.Draw(base, "RGBA")
    midy = sy + sub.height // 2
    for sgn, ex in ((-1, sx - 16), (1, sx + sub.width + 16)):
        d.line([ex, midy, ex + sgn * 78, midy], fill=accent + (235,), width=4)
        dx = ex + sgn * 92
        d.polygon([(dx, midy - 8), (dx + sgn * 11, midy), (dx, midy + 8),
                   (dx - sgn * 11, midy)], fill=accent + (255,))
    if icon:
        ir = max(14, title.height * 0.17)
        iy = ty + title.height * 0.42
        icon(d, tx - ir * 2.1, iy, ir, icon_petal, icon_core)
        icon(d, tx + title.width + ir * 2.1, iy, ir, icon_petal, icon_core)


# ----------------------------------------------------------------------------
# finish: ordered dither + posterize + pixelate + frame
# ----------------------------------------------------------------------------
def dither(small, amp):
    """Ordered (Bayer 8x8) dither -> signed per-pixel luminance nudge so the
    following posterize interleaves bands into pixel-art stipple."""
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


def finish(img, name):
    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle([8, 8, W - 8, H - 8], radius=40,
                        outline=FRAME + (255,), width=12)
    rgb = img.convert("RGB")
    small = rgb.resize((W // PIX, H // PIX), Image.LANCZOS)
    small = dither(small, amp=16)
    small = ImageOps.posterize(small, 5)
    out = small.resize((W, H), Image.NEAREST)
    path = f"{TILES}/{name}.png"
    out.save(path)
    print("wrote", path)


# ============================================================================
# PURPLE FIELDS -- the reference: sky+clouds, snow mountains, lavender fields,
# foreground dirt arena, deep purple kill-pool lower-centre
# ============================================================================
def purple():
    base = band_gradient([
        (0.00, (150, 205, 240)), (0.20, (180, 218, 245)),
        (0.34, (214, 206, 232)), (0.40, (150, 116, 186)),
        (0.62, (132, 96, 170)), (1.00, (96, 66, 132))])
    d = ImageDraw.Draw(base, "RGBA")
    cloud(d, 380, 150, 1.5, 1)
    cloud(d, 1100, 110, 1.9, 2)
    cloud(d, 760, 220, 1.1, 3)
    # distant range (hazy) + nearer range (snow caps)
    mountain_range(d, 360, 210, (150, 140, 186), 11, jag=11, snow=(225, 222, 240))
    mountain_range(d, 380, 150, (120, 104, 164), 12, jag=8, snow=(232, 228, 246))
    rolling_hills(d, (0, 330, W, 720), [(168, 120, 196), (150, 104, 184),
                                        (130, 88, 166), (112, 76, 150)], 13)
    # worn path receding to the horizon, drawing the eye to the arena
    d.polygon([(742, 352), (806, 352), (980, 720), (560, 720)],
              fill=(150, 120, 110, 80))
    field_strokes(d, (0, 360, W, 740), (196, 150, 214), 360, 14, length=10)
    field_strokes(d, (0, 430, W, 760), (214, 168, 226), 300, 15, length=8)
    speckle(d, (0, 470, W, 760), (236, 200, 240, 200), 220, 1, 3, 17)  # blooms
    arena_floor(base, 768, 660, 470, 150, (150, 110, 92, 255), (96, 66, 64),
                16, rim=(120, 84, 110, 255))
    fill, rim = hazard_masks("arena_purple")
    if fill:
        pool = band_gradient([(0.0, (74, 46, 116)), (1.0, (40, 24, 72))])
        base.paste(pool, (0, 0), fill)
        paint_glow(base, rim, (190, 110, 220), blur=4)
    draw_title(base, "PURPLE FIELDS", (250, 244, 255), (192, 150, 232),
               (150, 92, 196), icon=icon_flower,
               icon_petal=(214, 150, 230, 255), icon_core=(252, 224, 96, 255))
    finish(base, "purple_fields_bg")


# ============================================================================
# SUNNY SPRINGS -- safe meadow: sky+clouds, green mountains, flowery field,
# foreground arena, shallow (safe) pond
# ============================================================================
def springs():
    base = band_gradient([
        (0.00, (140, 205, 245)), (0.22, (176, 222, 248)),
        (0.30, (150, 206, 120)), (0.55, (120, 192, 84)), (1.00, (96, 170, 64))])
    d = ImageDraw.Draw(base, "RGBA")
    cloud(d, 320, 120, 1.6, 21)
    cloud(d, 980, 95, 2.0, 22)
    cloud(d, 1280, 180, 1.1, 23)
    mountain_range(d, 320, 170, (122, 168, 120), 31, jag=10, snow=(228, 240, 232))
    mountain_range(d, 340, 120, (96, 150, 96), 32, jag=7, snow=(236, 244, 238))
    rolling_hills(d, (0, 300, W, 720), [(132, 200, 88), (116, 188, 76),
                                        (104, 178, 70)], 33)
    arena_floor(base, 768, 650, 460, 150, (156, 124, 84, 255), (104, 80, 52),
                34, rim=(120, 162, 78, 255))
    # flowers (yellow + pink) scattered on grass
    rnd = random.Random(35)
    for _ in range(40):
        fx = rnd.uniform(60, W - 60)
        t = rnd.random()
        fy = 360 + (760 - 360) * (t ** 0.6)
        d.line([fx, fy, fx, fy + 12], fill=(70, 150, 60, 255), width=2)
        yellow = rnd.random() < 0.6
        petal = (255, 206, 86, 255) if yellow else (240, 120, 170, 255)
        core = (245, 140, 40, 255) if yellow else (255, 255, 255, 255)
        for k in range(5):
            a = k * 2 * math.pi / 5
            ox, oy = fx + math.cos(a) * 6, fy + math.sin(a) * 6
            d.ellipse([ox - 4, oy - 4, ox + 4, oy + 4], fill=petal)
        d.ellipse([fx - 3, fy - 3, fx + 3, fy + 3], fill=core)
    # shallow decorative pond (NO hazard -> light & clear = reads safe)
    px0, py0, px1, py1 = 600, 560, 1000, 700
    d.ellipse([px0, py0, px1, py1], fill=(150, 214, 224, 255))
    d.ellipse([px0 + 16, py0 + 12, px1 - 16, py1 - 12], fill=(176, 226, 232, 255))
    speckle(d, (px0 + 30, py0 + 20, px1 - 30, py1 - 20), (120, 180, 150, 150),
            18, 2, 4, 36)
    draw_title(base, "SUNNY SPRINGS", (250, 252, 220), (150, 210, 90),
               (88, 166, 70), icon=icon_flower,
               icon_petal=(255, 206, 86, 255), icon_core=(245, 140, 40, 255))
    finish(base, "sunny_springs_bg")


# ============================================================================
# BEAUTY BEACH -- sandy arena, central lagoon (kill), sun + palm, distant sea
# ============================================================================
def beach():
    base = band_gradient([
        (0.00, (138, 206, 240)), (0.18, (170, 222, 246)),
        (0.24, (66, 150, 206)), (0.34, (44, 122, 188)),   # sea band
        (0.40, (240, 224, 168)), (1.00, (224, 192, 120))])  # sand
    d = ImageDraw.Draw(base, "RGBA")
    cloud(d, 360, 110, 1.6, 41)
    cloud(d, 1120, 90, 1.9, 42)
    # distant green headland across the bay -- drawn first, then the beach sand
    # is laid back over the foreground so the land reads as far off, not underfoot
    mountain_range(d, 296, 64, (90, 168, 130), 43, jag=6, faces=False)
    shore = 300
    sand = band_gradient([(0.0, (242, 226, 170)), (1.0, (222, 188, 116))],
                         size=(W, H - shore))
    base.paste(sand, (0, shore))
    d = ImageDraw.Draw(base, "RGBA")
    d.rectangle([0, shore, W, shore + 9], fill=(238, 222, 198, 160))  # wet shore
    speckle(d, (0, 320, W, H), (206, 174, 110, 120), 200, 2, 5, 44)   # sand grain
    fill, rim = hazard_masks("arena_beach")
    if fill:
        paint_glow(base, rim, (210, 178, 108), blur=8)            # wet-sand ring
        paint_water(base, fill, rim, (96, 178, 230), (40, 116, 190),
                    foam=(246, 251, 255), seed=45)
    # sun (top-right): halo + disc + rays
    sx, sy, sr = 1290, 150, 66
    d.ellipse([sx - sr * 1.5, sy - sr * 1.5, sx + sr * 1.5, sy + sr * 1.5],
              fill=(255, 243, 190, 120))
    for k in range(12):
        a = k * math.pi / 6
        d.line([sx + math.cos(a) * sr * 1.25, sy + math.sin(a) * sr * 1.25,
                sx + math.cos(a) * sr * 1.7, sy + math.sin(a) * sr * 1.7],
               fill=(255, 224, 92, 255), width=7)
    d.ellipse([sx - sr, sy - sr, sx + sr, sy + sr], fill=(255, 224, 92, 255))
    # palm tree (left)
    tx, ty = 250, 560
    d.line([tx, ty, tx - 28, ty - 160], fill=(140, 94, 52, 255), width=18)
    cx, cy = tx - 28, ty - 160
    for a, ln in [(-2.6, 100), (-2.0, 116), (-1.2, 110), (-0.5, 100), (0.2, 84)]:
        ex, ey = cx + math.cos(a) * ln, cy + math.sin(a) * ln
        mx = (cx + ex) / 2 + math.cos(a + 1.5) * 18
        my = (cy + ey) / 2 + math.sin(a + 1.5) * 18
        d.polygon([(cx, cy), (mx, my), (ex, ey)], fill=(60, 170, 90, 255))
    draw_title(base, "BEAUTY BEACH", (252, 252, 240), (118, 200, 226),
               (66, 168, 200), icon=icon_sun,
               icon_petal=(255, 224, 92, 255), icon_core=(255, 238, 156, 255))
    finish(base, "beauty_beach_bg")


# ============================================================================
# WHITE WATER FALLS -- green bank (right) arena, cascade + plunge pool (kill)
# on the left/bottom, mountains behind
# ============================================================================
def falls():
    base = band_gradient([
        (0.00, (140, 200, 240)), (0.16, (176, 220, 246)),
        (0.22, (118, 176, 116)), (0.55, (98, 162, 100)), (1.00, (84, 146, 92))])
    d = ImageDraw.Draw(base, "RGBA")
    cloud(d, 1080, 110, 1.7, 71)
    cloud(d, 1360, 170, 1.0, 72)
    mountain_range(d, 250, 150, (104, 150, 130), 73, jag=8, snow=(228, 238, 232))
    rolling_hills(d, (0, 240, W, 760), [(112, 176, 110), (98, 160, 98),
                                        (86, 148, 90)], 74)
    arena_floor(base, 940, 470, 360, 150, (150, 124, 86, 255), (100, 80, 54),
                75, rim=(110, 156, 96, 255))
    fill, rim = hazard_masks("arena_falls")
    if fill:
        paint_water(base, fill, rim, (104, 176, 222), (52, 120, 184),
                    foam=(248, 252, 255), streaks=True, seed=76)
        d2 = ImageDraw.Draw(base, "RGBA")
        speckle(d2, (0, 620, W, H), (250, 253, 255, 220), 120, 4, 13, 77)
    draw_title(base, "WHITE WATER FALLS", (252, 253, 255), (150, 205, 240),
               (70, 150, 210), icon=icon_drop,
               icon_petal=(224, 246, 255, 255), icon_core=(120, 196, 236, 255))
    finish(base, "white_water_falls_bg")


# ============================================================================
# LAUGHING LAVA -- molten lake across the top (kill), dark volcanic rock arena
# below, distant glowing volcanoes, embers
# ============================================================================
def lava():
    base = band_gradient([
        (0.00, (74, 40, 52)), (0.22, (58, 36, 48)),
        (0.34, (48, 34, 44)), (1.00, (26, 18, 28))])
    d = ImageDraw.Draw(base, "RGBA")
    # smoky haze clouds (dark/red)
    cloud(d, 420, 120, 1.6, 81, color=(70, 52, 60, 180))
    cloud(d, 1120, 100, 1.9, 82, color=(78, 56, 64, 180))
    # distant volcano silhouettes with glowing tops
    mountain_range(d, 320, 150, (40, 28, 36), 83, jag=7)
    for vx in (430, 1080):
        d.polygon([(vx - 18, 290), (vx, 250), (vx + 18, 290)],
                  fill=(232, 110, 40, 220))
    speckle(d, (0, 360, W, H), (40, 30, 40, 255), 220, 2, 5, 84)
    speckle(d, (0, 420, W, H), (70, 54, 62, 110), 120, 3, 7, 85)
    fill, rim = hazard_masks("arena_lava")
    if fill:
        molten = band_gradient([(0.0, (255, 150, 36)), (0.6, (236, 88, 24)),
                                 (1.0, (150, 38, 14))])
        md = ImageDraw.Draw(molten, "RGBA")
        speckle(md, (0, 0, W, 320), (255, 184, 60, 200), 70, 14, 36, 86)
        speckle(md, (0, 0, W, 320), (255, 226, 150, 230), 46, 6, 16, 87)
        base.paste(molten, (0, 0), fill)
        paint_glow(base, rim, (255, 224, 130), blur=6)
    # embers over the rock
    ed = ImageDraw.Draw(base, "RGBA")
    speckle(ed, (40, 360, W - 40, H - 40), (255, 178, 70, 210), 60, 2, 5, 88)
    draw_title(base, "LAUGHING LAVA", (255, 238, 156), (240, 120, 42),
               (236, 92, 30), icon=icon_flame,
               icon_petal=(255, 226, 130, 255), icon_core=(255, 146, 42, 255))
    finish(base, "laughing_lava_bg")


def main():
    purple()
    springs()
    beach()
    falls()
    lava()


if __name__ == "__main__":
    main()
