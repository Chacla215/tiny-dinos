"""Algorithmic skin recolors of the AI hero (assets/concept/ralph/ralph_hero.png).

Demonstrates "AI base + algorithmic multiplier": instead of AI-generating each
color preset, mask the scales (green) and spikes (cyan) by hue+saturation and
shift only those, keeping each pixel's VALUE so the painted shading/gloss
survives and the amber eyes / cream belly / grey background are untouched.

Fills the simple color-preset skins (Forest/Frozen/Golden/Spring) for the
creator carousel. The detail-heavy skins (Crystal facets, Volcano lava cracks,
Void stars, Robo/Galaxy/Dragon) still want AI -- recolor can't invent detail.
"""
import os
from PIL import Image, ImageChops, ImageFilter, ImageFont, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
SRC = os.path.join(ROOT, "assets/concept/ralph/ralph_hero.png")
OUTDIR = os.path.join(ROOT, "assets/concept/ralph")
FONT = os.path.join(ROOT, "assets/fonts/Jersey25.ttf")

BODY_BAND = (52, 111)   # green scales
SPIKE_BAND = (112, 140)  # cyan spikes
SAT_GATE = 60
BODY_C, SPIKE_C = 66, 126   # measured hue centers
KEEP = 0.35                  # fraction of original hue variation to retain

# name -> (body: target_h, sat_mul, val_mul), (spike: target_h, sat_mul, val_mul)
SKINS = {
    "forest": ((86, 1.30, 0.80), (96, 1.10, 0.82)),
    "frozen": ((150, 0.50, 1.12), (158, 0.60, 1.08)),
    "golden": ((36, 1.15, 1.06), (170, 1.20, 0.90)),   # royal-blue spikes
    "spring": ((70, 0.82, 1.13), (78, 0.88, 1.06)),
}


def _clamp(v):
    return 0 if v < 0 else (255 if v > 255 else int(v))


def band_mask(H, S, lo, hi):
    hue = H.point(lambda v: 255 if lo <= v <= hi else 0)
    sat = S.point(lambda v: 255 if v >= SAT_GATE else 0)
    m = ImageChops.multiply(hue, sat)
    return m.filter(ImageFilter.GaussianBlur(1.2))   # soft edge


def apply_region(H, S, V, mask, center, params):
    th, sm, vm = params
    newH = H.point(lambda v: _clamp(th + (v - center) * KEEP))
    newS = S.point(lambda v: _clamp(v * sm))
    newV = V.point(lambda v: _clamp(v * vm))
    return (Image.composite(newH, H, mask),
            Image.composite(newS, S, mask),
            Image.composite(newV, V, mask))


def recolor(src, body, spike):
    hsv = src.convert("HSV")
    H, S, V = hsv.split()
    bmask = band_mask(H, S, *BODY_BAND)
    smask = band_mask(H, S, *SPIKE_BAND)
    H, S, V = apply_region(H, S, V, bmask, BODY_C, body)
    H, S, V = apply_region(H, S, V, smask, SPIKE_C, spike)
    return Image.merge("HSV", (H, S, V)).convert("RGB")


def void_hybrid(src):
    """Void Ralph = recolor (deep cosmic purple body + glowing cyan spikes) THEN
    procedural FX code can't get from a hue shift alone: a starfield sprinkled
    only where the body mask is set, plus a soft cyan glow around the spikes."""
    import random
    out = recolor(src, (200, 0.95, 0.46), (132, 1.30, 1.20))  # purple + bright cyan

    hsv = src.convert("HSV")
    H, S, _ = hsv.split()
    bmask = band_mask(H, S, *BODY_BAND)
    smask = band_mask(H, S, *SPIKE_BAND)

    # soft cyan glow around the (now bright) spikes
    cyan = Image.new("RGB", src.size, (28, 120, 150))
    base = Image.new("RGB", src.size, (0, 0, 0))
    glow = Image.composite(cyan, base, smask.filter(ImageFilter.GaussianBlur(9)))
    out = ImageChops.screen(out, glow)

    # starfield confined to the body
    d = ImageDraw.Draw(out)
    px = bmask.load()
    w, h = src.size
    rng = random.Random(42)
    placed, tries = 0, 0
    while placed < 170 and tries < 9000:
        tries += 1
        x, y = rng.randint(0, w - 1), rng.randint(0, h - 1)
        if px[x, y] < 150:
            continue
        r = rng.choice([1, 1, 1, 2, 2, 3])
        c = rng.choice([(255, 255, 255), (216, 240, 255), (190, 226, 255)])
        d.ellipse([x - r, y - r, x + r, y + r], fill=c)
        if r >= 3 and rng.random() < 0.6:        # occasional sparkle cross
            d.line([x - r * 2, y, x + r * 2, y], fill=c, width=1)
            d.line([x, y - r * 2, x, y + r * 2], fill=c, width=1)
        placed += 1
    return out


def main():
    src = Image.open(SRC).convert("RGB")
    cells = [("EXPLORER", src)]
    for name, (body, spike) in SKINS.items():
        out = recolor(src, body, spike)
        path = os.path.join(OUTDIR, f"ralph_{name}.png")
        out.save(path)
        print("wrote", os.path.relpath(path, ROOT))
        cells.append((name.upper(), out))

    void = void_hybrid(src)
    vpath = os.path.join(OUTDIR, "ralph_void.png")
    void.save(vpath)
    print("wrote", os.path.relpath(vpath, ROOT))
    cells.append(("VOID", void))

    # comparison sheet
    th = 320
    thumbs = [(lbl, im.resize((round(im.width * th / im.height), th), Image.LANCZOS))
              for lbl, im in cells]
    cw = max(t.width for _, t in thumbs) + 20
    sheet = Image.new("RGB", (cw * len(thumbs), th + 50), (244, 246, 250))
    d = ImageDraw.Draw(sheet)
    try:
        font = ImageFont.truetype(FONT, 26)
    except Exception:
        font = ImageFont.load_default()
    for i, (lbl, t) in enumerate(thumbs):
        sheet.paste(t, (i * cw + (cw - t.width) // 2, 8))
        w = d.textlength(lbl, font=font)
        d.text((i * cw + (cw - w) / 2, th + 14), lbl, font=font, fill=(50, 60, 74))
    sheet.save("/tmp/ralph/recolor_sheet.png")
    print("wrote /tmp/ralph/recolor_sheet.png")


if __name__ == "__main__":
    main()
