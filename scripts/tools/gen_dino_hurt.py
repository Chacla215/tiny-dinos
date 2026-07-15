#!/usr/bin/env python3
"""Synthesize hurt ("hit") + knockdown ("ko") rows onto the motion sheets.

dino.gd already plays "hit" (flinch, hit_anim_timer) and "ko" (is_downed) clips
whenever a sheet carries them — but the Seedance source clips for those anims
were never generated (assets/concept/<dino>/motion/ has idle/walk/attack only).
This tool fills the gap WITHOUT new art: it lifts the idle pose off the baked
<dino>_motion.png and builds the two clips from cheap transforms, the same trick
gen_ralph_fighter.py uses for its whole sheet:

  hit — a sharp backward recoil (lean + squash + shove) that relaxes, 3 frames.
  ko  — a tip-over onto the back: rotate progressively flat, impact squash,
        settle, 5 frames; the non-looping clip HOLDS the flat last frame for
        the rest of the knockdown, then get_up() snaps back to idle.

The rows are APPENDED below the existing grid (same cell size, same feet
baseline), so every existing ANIM_LAYOUTS rect stays valid; this prints the two
new lines to paste in. If real Seedance hit/ko clips arrive later, rebaking with
gen_dino_motion.py replaces all of this wholesale.

Run:  python3 scripts/tools/gen_dino_hurt.py [dino|all]     (default: all)
"""
import os
import sys
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

# The gen_dino_motion.py grid every live sheet uses: one row per anim, walk's 8
# frames set the sheet width. Cell sizes pinned from ANIM_LAYOUTS so a rerun on
# an already-extended sheet still finds the right rows (crop-to-3 makes this
# idempotent).
GRID_COLS = 8            # walk row
GRID_ROWS = 3            # idle / walk / attack (the original baked rows)
CELL = {"ralph": (135, 153), "raptor": (156, 154), "trike": (131, 156),
        "pterry": (244, 157), "bronto": (237, 155), "anky": (231, 161)}
DINOS = list(CELL)

HIT_SPEED, KO_SPEED = 12.0, 10.0
# hit recoil: (lean° CCW = backward for a right-facing sprite, x-squash,
# y-squash, backward shove px)
HIT_POSES = [(12, 1.06, 0.92, -7), (7, 1.02, 0.97, -3), (2, 1.0, 1.0, -1)]
# Upright bodies TIP OVER onto their back (85° reads flopped, face-up); the
# quadrupeds are already horizontal, so tipping just looks bent — they PANCAKE
# instead (legs give out, body flattens), which also always fits their wide cells.
TIP_DINOS = {"ralph", "raptor", "pterry"}
FLAT_ANGLE = 85
# pancake collapse: (wobble°, x-spread, y-squash) — spread is capped to the cell.
PANCAKE_POSES = [(5, 1.02, 0.93), (-4, 1.06, 0.80), (2, 1.10, 0.62),
                 (0, 1.14, 0.50), (0, 1.10, 0.56)]


def _compose(content, cw, ch, baseline, rot=0.0, pre=(1.0, 1.0),
             post=(1.0, 1.0), dx=0):
    """One cell: pre-squash -> rotate -> post-squash (impact flattening AGAINST
    the ground wants to happen after the tip-over), bottom-align to the shared
    feet baseline so ground contact survives every pose. The safety fit-shrink
    only triggers on transient mid-fall frames — held poses are pre-fitted by
    the callers so a clip never visibly shrinks frame to frame."""
    def scaled(img, s):
        if s == (1.0, 1.0):
            return img
        return img.resize((max(1, round(img.width * s[0])),
                           max(1, round(img.height * s[1]))), Image.LANCZOS)
    img = scaled(content, pre)
    if rot:
        img = img.rotate(rot, resample=Image.BICUBIC, expand=True)
    img = scaled(img, post)
    fit = min(1.0, (cw - 2) / img.width, (baseline - 1) / img.height)
    if fit < 1.0:
        img = img.resize((max(1, round(img.width * fit)),
                          max(1, round(img.height * fit))), Image.LANCZOS)
    cell = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
    cell.alpha_composite(img, (max(0, (cw - img.width) // 2 + dx),
                               baseline - img.height))
    return cell


def _ko_tip(content, cw, ch, baseline):
    """Buckle -> fall -> flat on the back (impact squash, rebound, rest). The
    three FLAT frames share one pre-fitted content so the held pose is stable;
    only the single mid-fall frame may fit-shrink (transient, 0.1s)."""
    import math
    rad = math.radians(FLAT_ANGLE)
    rw = content.width * abs(math.cos(rad)) + content.height * abs(math.sin(rad))
    rh = content.width * abs(math.sin(rad)) + content.height * abs(math.cos(rad))
    s = min(1.0, (cw - 2) / rw, (baseline - 1) / rh)
    flat_src = content if s >= 1.0 else content.resize(
        (max(1, round(content.width * s)), max(1, round(content.height * s))),
        Image.LANCZOS)
    return [
        _compose(content, cw, ch, baseline, pre=(1.05, 0.90), dx=-2),
        _compose(content, cw, ch, baseline, rot=45, dx=-6),
        _compose(flat_src, cw, ch, baseline, rot=FLAT_ANGLE, post=(1.06, 0.86), dx=-8),
        _compose(flat_src, cw, ch, baseline, rot=FLAT_ANGLE, post=(1.02, 0.96), dx=-8),
        _compose(flat_src, cw, ch, baseline, rot=FLAT_ANGLE, dx=-8),
    ]


def _ko_pancake(content, cw, ch, baseline):
    """Stagger -> legs give -> flattened pancake -> settle, for the quadrupeds."""
    sx_max = (cw - 2) / content.width
    return [_compose(content, cw, ch, baseline, rot=r,
                     pre=(min(sx, sx_max), sy))
            for r, sx, sy in PANCAKE_POSES]


def build(dino):
    path = os.path.join(ROOT, f"assets/sprites/{dino}_motion.png")
    sheet = Image.open(path).convert("RGBA")
    w, h = sheet.size
    cw, ch = CELL[dino]
    if w != cw * GRID_COLS or h % ch:
        sys.exit(f"{dino}: sheet {w}x{h} does not match cell {cw}x{ch}")
    sheet = sheet.crop((0, 0, w, ch * GRID_ROWS))   # drop prior hit/ko rows

    idle0 = sheet.crop((0, 0, cw, ch))
    bbox = idle0.getbbox()
    if bbox is None:
        sys.exit(f"{dino}: idle frame 0 is empty?")
    content = idle0.crop(bbox)
    baseline = bbox[3]                       # shared feet line from the bake

    hit = [_compose(content, cw, ch, baseline, rot=r, pre=(sx, sy), dx=dx)
           for r, sx, sy, dx in HIT_POSES]
    ko = (_ko_tip if dino in TIP_DINOS else _ko_pancake)(content, cw, ch, baseline)

    out = Image.new("RGBA", (w, ch * (GRID_ROWS + 2)), (0, 0, 0, 0))
    out.alpha_composite(sheet, (0, 0))
    for i, f in enumerate(hit):
        out.alpha_composite(f, (i * cw, ch * GRID_ROWS))
    for i, f in enumerate(ko):
        out.alpha_composite(f, (i * cw, ch * (GRID_ROWS + 1)))
    out.save(path)

    def row(name, n, y, speed):
        rects = ", ".join(f"Rect2({i * cw}, {y}, {cw}, {ch})" for i in range(n))
        return (f'\t\t"{name}":    {{"loop": false, "speed": {speed}, '
                f'"rects": [{rects}]}},')

    plan = "tip" if dino in TIP_DINOS else "pancake"
    print(f"{dino}: {w}x{h} -> {out.size[0]}x{out.size[1]}  cell {cw}x{ch}  "
          f"ko={plan}  baseline={baseline}")
    print(row("hit", len(hit), ch * GRID_ROWS, HIT_SPEED))
    print(row("ko", len(ko), ch * (GRID_ROWS + 1), KO_SPEED))

    prev_dir = "/tmp/ralph"
    os.makedirs(prev_dir, exist_ok=True)
    strip = Image.new("RGB", (cw * max(len(hit), len(ko)), ch * 2), (90, 96, 110))
    for i, f in enumerate(hit):
        strip.paste(f, (i * cw, 0), f)
    for i, f in enumerate(ko):
        strip.paste(f, (i * cw, ch), f)
    strip.save(os.path.join(prev_dir, f"{dino}_hurt_preview.png"))


def main():
    which = sys.argv[1] if len(sys.argv) > 1 else "all"
    for dino in (DINOS if which == "all" else [which]):
        if dino not in DINOS:
            sys.exit(f"unknown dino '{dino}'; known: {', '.join(DINOS)}")
        build(dino)


if __name__ == "__main__":
    main()
