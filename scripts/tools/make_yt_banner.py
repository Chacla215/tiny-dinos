#!/usr/bin/env python3
"""Build a YouTube channel banner that survives YouTube's three nested crops.

The old banner failed because the cast art was scaled to fill the whole canvas,
so on a phone — which only ever shows the CENTRAL 1235x338 of a 2560x1440
image — viewers got a cropped close-up of Ralph's face and no logo at all.

YouTube's crops, all centred:
    2560x1440   TV / full bleed        (everything else is decoration)
    2560x423    desktop, max width
    1855x423    tablet
    1235x338    MOBILE  <- the only region guaranteed to be visible

So the rule is: ANY element that must always be seen — the logo, a tagline —
goes inside 1235x338. The cast is atmosphere and lives in the bleed.

    python3 scripts/tools/make_yt_banner.py [--preview]
"""
import os
import sys
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BG = os.path.join(ROOT, "assets/concept/brand/banner_bg_wide.png")
LOGO = os.path.join(ROOT, "assets/sprites/title_logo.png")
OUT = os.path.join(ROOT, "assets/concept/brand/avatar/yt_banner_2560.png")

W, H = 2560, 1440
SAFE_W, SAFE_H = 1235, 338


def build():
    """Composite: generated wide beach art + the real logo, inside the safe area.

    The art is generated (banner_bg_wide.png) rather than composited from
    cast_group.png, because that source is PORTRAIT — every attempt to make it
    fill a 16:9 banner either cropped it into a face close-up or, when split to
    flank the logo, visibly sliced a dinosaur in half. The generated version
    spreads all seven across the full width with a deliberately clear centre.

    The logo is composited from the real asset, never generated, so the wordmark
    is pixel-exact.
    """
    bg = Image.open(BG).convert("RGB")
    # cover-fit to 2560x1440 without distorting
    bw, bh = bg.size
    scale = max(W / bw, H / bh)
    bg = bg.resize((int(bw * scale), int(bh * scale)), Image.LANCZOS)
    canvas = bg.crop(((bg.size[0] - W) // 2, (bg.size[1] - H) // 2,
                      (bg.size[0] - W) // 2 + W, (bg.size[1] - H) // 2 + H))

    # --- the logo, INSIDE the 1235x338 mobile safe area.
    # That box is the only region YouTube guarantees on every device, so the
    # wordmark lives there and everything else is bleed.
    logo = Image.open(LOGO).convert("RGBA")
    logo = logo.crop(logo.split()[-1].getbbox())
    lw, lh = logo.size
    target_h = int(SAFE_H * 0.92)
    target_w = int(lw * target_h / lh)
    if target_w > int(SAFE_W * 0.60):
        target_w = int(SAFE_W * 0.60)
        target_h = int(lh * target_w / lw)
    logo = logo.resize((target_w, target_h), Image.LANCZOS)

    # NO halo behind the wordmark. A blurred rectangle was tried and read as a
    # visible pale box on the art — the logo already carries its own dark
    # outline and sits against bright sky and sea, so it holds up unaided.
    hx = (W - target_w) // 2
    hy = (H - SAFE_H) // 2 + (SAFE_H - target_h) // 2
    canvas.paste(logo, (hx, hy), logo)

    canvas.save(OUT)
    return OUT


def preview(path):
    """Render the three crops so the result can be judged before uploading."""
    im = Image.open(path).convert("RGB")
    out_dir = os.environ.get("BANNER_PREVIEW_DIR", "/tmp")
    for name, (zw, zh) in (("mobile", (SAFE_W, SAFE_H)),
                           ("tablet", (1855, 423)),
                           ("desktop", (2560, 423))):
        x0, y0 = (W - zw) // 2, (H - zh) // 2
        im.crop((x0, y0, x0 + zw, y0 + zh)).save(f"{out_dir}/banner_{name}.png")
    im.resize((900, int(900 * H / W))).save(f"{out_dir}/banner_full.png")
    print(f"previews -> {out_dir}/banner_[mobile|tablet|desktop|full].png")


if __name__ == "__main__":
    p = build()
    print(f"built {os.path.relpath(p, ROOT)}  ({Image.open(p).size[0]}x{Image.open(p).size[1]})")
    if "--preview" in sys.argv:
        preview(p)
