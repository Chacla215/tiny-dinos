#!/usr/bin/env python3
"""Bake AI-generated motion clips into an in-match animation sheet.

Companion to gen_ralph_fighter.py (which fakes frames from ONE still). This
tool eats real video — Seedance 2.0 image-to-video clips generated per
scripts/tools/dino_motion_prompts.md — and bakes true animation frames:

  assets/concept/<dino>/motion/<anim>.mp4   (anim = idle/walk/attack/heavy/
                                             hit/ko/dodge/win; filename = clip)
        │  ffmpeg -vf fps=N → frames
        │  key the flat studio background (same soft ramp as the hero bake)
        │  per-clip union bbox → intra-clip motion (lunges, bounces) survives
        │  one global scale + one shared feet baseline → anims line up in-game
        ▼
  assets/sprites/<dino>_motion.png          (uniform grid, one row per anim)
        + printed ANIM_LAYOUTS block for dino.gd
        + contact preview at /tmp/ralph/<dino>_motion_preview.png

Run:  python3 scripts/tools/gen_dino_motion.py <dino>
      --fps 12            extraction rate (frames sampled FROM these)
      --pixel             Bayer-dither pixel look (default: smooth painterly,
                          matching the current in-match LINEAR filter)
      --trim walk=0.4,1.6 use only this time window (seconds) of a clip —
                          the usual fix to isolate ONE clean walk cycle
      --pick walk=2,5,8   hand-pick extracted frame indices (overrides count)
      --frames walk=10    sample a different frame count for one anim
      --src DIR           read clips from DIR instead of assets/concept/…
Requires ffmpeg (checked at /opt/homebrew/bin/ffmpeg, falls back to PATH).
"""
import argparse
import glob
import os
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

from gen_ralph_fighter import BAYER8, DITHER_AMP, KEY_HI, KEY_LO, POSTERIZE, sample_bg

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
CLIP_EXTS = (".mp4", ".mov", ".webm", ".m4v")
PAD = 10          # px of air around the union bbox in every cell
CHAR_H = 132      # standing character height target (matches gen_ralph_fighter)

# Per-anim bake defaults: (frames to sample, playback speed fps, loops).
# Speeds are starting points — retune in ANIM_LAYOUTS once it's in-hand.
ANIM_DEFAULTS = {
    "idle":   (4, 6.0, True),
    "walk":   (8, 12.0, True),
    "attack": (5, 14.0, False),
    "heavy":  (6, 12.0, False),
    "hit":    (4, 12.0, False),
    "ko":     (6, 10.0, False),
    "dodge":  (4, 14.0, False),
    "win":    (6, 8.0, True),
}
ANIM_ORDER = ["idle", "walk", "attack", "heavy", "hit", "ko", "dodge", "win"]
# Clips whose median frame height defines the dino's standing scale (a KO clip
# spends half its frames flopped flat — never let it set the scale).
SCALE_ANCHORS = ["idle", "walk", "attack"]


def ffmpeg_bin():
    for cand in ("/opt/homebrew/bin/ffmpeg", shutil.which("ffmpeg")):
        if cand and os.path.exists(cand):
            return cand
    sys.exit("ffmpeg not found (brew install ffmpeg)")


def extract(clip, fps, outdir):
    """Dump `clip` to numbered PNGs at `fps`; returns the sorted frame paths."""
    os.makedirs(outdir, exist_ok=True)
    subprocess.run(
        [ffmpeg_bin(), "-v", "error", "-i", clip, "-vf", f"fps={fps}", "-y",
         os.path.join(outdir, "f%04d.png")],
        check=True)
    return sorted(glob.glob(os.path.join(outdir, "f*.png")))


def key_alpha(im, bg):
    """Full-frame RGBA: CONNECTED-background key. Flood-fill from the frame
    borders through pixels near the studio bg color, so only the background
    region keys out — bg-colored details INSIDE the dino (cream belly on a
    grey-blue studio) survive. Soft KEY_LO..KEY_HI ramp on the boundary ring.
    (Connected-region idea borrowed from FrameKit's smart chroma key.)"""
    im = im.convert("RGB")
    w, h = im.size
    src = im.load()
    span = KEY_HI - KEY_LO

    def dist(x, y):
        r, g, b = src[x, y]
        return ((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2) ** 0.5

    # BFS the bg-connected region: seeds = border pixels within the key band.
    is_bg = bytearray(w * h)
    queue = []
    for x in range(w):
        for y in (0, h - 1):
            if not is_bg[y * w + x] and dist(x, y) < KEY_HI:
                is_bg[y * w + x] = 1
                queue.append((x, y))
    for y in range(h):
        for x in (0, w - 1):
            if not is_bg[y * w + x] and dist(x, y) < KEY_HI:
                is_bg[y * w + x] = 1
                queue.append((x, y))
    while queue:
        x, y = queue.pop()
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if 0 <= nx < w and 0 <= ny < h and not is_bg[ny * w + nx] \
                    and dist(nx, ny) < KEY_HI:
                is_bg[ny * w + nx] = 1
                queue.append((nx, ny))

    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    dst = out.load()
    for y in range(h):
        row = y * w
        for x in range(w):
            r, g, b = src[x, y]
            if not is_bg[row + x]:
                dst[x, y] = (r, g, b, 255)
                continue
            d = ((r - bg[0]) ** 2 + (g - bg[1]) ** 2 + (b - bg[2]) ** 2) ** 0.5
            if d > KEY_LO:  # soft edge ring of the bg region
                dst[x, y] = (r, g, b, int(round((d - KEY_LO) / span * 255)))
    return out


def sample_indices(n_total, lo, hi, count, picks):
    """Which extracted frames to bake: hand-picked indices, else `count` spread
    evenly across [lo, hi)."""
    if picks:
        return [i for i in picks if 0 <= i < n_total]
    lo, hi = max(0, lo), min(n_total, hi)
    span = hi - lo
    if span <= 0:
        return []
    if span <= count:
        return list(range(lo, hi))
    return [lo + round(i * (span - 1) / (count - 1)) for i in range(count)]


def stylize(rgba, pixel):
    """Finish a scaled frame: pixel = posterize + Bayer dither + hard alpha
    (the dithered look); smooth = keep painterly RGB + soft alpha (the current
    in-match look, LINEAR filter)."""
    if not pixel:
        return rgba
    r, g, b, a = rgba.split()
    rgb = Image.merge("RGB", (r, g, b))
    step = 255 / (POSTERIZE - 1)
    rgb = rgb.point(lambda v: int(round(round(v / step) * step)))
    w, h = rgb.size
    px = rgb.load()
    for y in range(h):
        row = BAYER8[y % 8]
        for x in range(w):
            nudge = int(round((row[x % 8] / 63.0 - 0.5) * DITHER_AMP))
            cr, cg, cb = px[x, y]
            px[x, y] = (max(0, min(255, cr + nudge)),
                        max(0, min(255, cg + nudge)),
                        max(0, min(255, cb + nudge)))
    a = a.point(lambda v: 0 if v < 110 else 255)
    return Image.merge("RGBA", (*rgb.split(), a))


def parse_kv(pairs, cast):
    """'walk=0.4,1.6' CLI pairs -> {'walk': [cast(0.4), cast(1.6)]}."""
    out = {}
    for p in pairs or []:
        name, _, vals = p.partition("=")
        out[name] = [cast(v) for v in vals.split(",") if v != ""]
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("dino")
    ap.add_argument("--fps", type=float, default=12.0)
    ap.add_argument("--pixel", action="store_true")
    ap.add_argument("--char-h", type=int, default=CHAR_H)
    ap.add_argument("--src", help="clip dir override (default assets/concept/<dino>/motion)")
    ap.add_argument("--trim", action="append", metavar="ANIM=START,END")
    ap.add_argument("--pick", action="append", metavar="ANIM=I,J,K")
    ap.add_argument("--frames", action="append", metavar="ANIM=N")
    args = ap.parse_args()

    trims = parse_kv(args.trim, float)
    picks = parse_kv(args.pick, int)
    counts = {k: v[0] for k, v in parse_kv(args.frames, int).items()}

    src_dir = args.src or os.path.join(ROOT, f"assets/concept/{args.dino}/motion")
    clips = {}
    for path in sorted(glob.glob(os.path.join(src_dir, "*"))):
        name, ext = os.path.splitext(os.path.basename(path))
        if ext.lower() in CLIP_EXTS and name in ANIM_DEFAULTS:
            clips[name] = path
    if not clips:
        sys.exit(f"no clips in {src_dir}\n  expected <anim>.mp4 with anim in: "
                 f"{', '.join(ANIM_ORDER)}\n  (generate per scripts/tools/dino_motion_prompts.md)")

    # 1) extract + key the sampled frames of every clip (full-frame RGBA so the
    #    locked camera's coordinates carry alignment for free)
    tmp = tempfile.mkdtemp(prefix=f"{args.dino}_motion_")
    anims = {}  # name -> {"frames": [RGBA], "union": (x0,y0,x1,y1)}
    for name in [a for a in ANIM_ORDER if a in clips]:
        frames_all = extract(clips[name], args.fps, os.path.join(tmp, name))
        t = trims.get(name)
        lo = int(t[0] * args.fps) if t else 0
        hi = int(t[1] * args.fps) if t and len(t) > 1 else len(frames_all)
        count = counts.get(name, ANIM_DEFAULTS[name][0])
        idxs = sample_indices(len(frames_all), lo, hi, count, picks.get(name))
        if not idxs:
            print(f"  !! {name}: trim/pick selected 0 of {len(frames_all)} frames, skipping")
            continue
        bg = sample_bg(Image.open(frames_all[idxs[0]]).convert("RGB"))
        keyed, union = [], None
        for i in idxs:
            fr = key_alpha(Image.open(frames_all[i]), bg)
            bb = fr.getbbox()
            if bb is None:
                continue
            keyed.append(fr)
            union = bb if union is None else (min(union[0], bb[0]), min(union[1], bb[1]),
                                              max(union[2], bb[2]), max(union[3], bb[3]))
        if not keyed:
            print(f"  !! {name}: keying removed everything — wrong bg color? skipping")
            continue
        anims[name] = {"frames": keyed, "union": union}
        print(f"  {name}: {len(keyed)} frames from {len(frames_all)} extracted "
              f"(union {union[2]-union[0]}x{union[3]-union[1]})")
    if not anims:
        sys.exit("nothing baked")

    # 2) one global scale from the standing-height anchor clip: median keyed
    #    frame height -> char_h, so every anim shares the dino's true size
    anchor = next((a for a in SCALE_ANCHORS if a in anims), next(iter(anims)))
    heights = sorted(f.getbbox()[3] - f.getbbox()[1] for f in anims[anchor]["frames"])
    med_h = heights[len(heights) // 2]
    scale = args.char_h / med_h
    print(f"scale {scale:.3f} from '{anchor}' median height {med_h}px -> {args.char_h}px")

    # 3) uniform grid: cell fits the largest scaled union bbox; every clip's
    #    union bottom sits on ONE baseline so anim switches don't pop in-game
    scaled = {}
    for name, a in anims.items():
        x0, y0, x1, y1 = a["union"]
        tw = max(1, round((x1 - x0) * scale))
        th = max(1, round((y1 - y0) * scale))
        scaled[name] = [stylize(f.crop(a["union"]).resize((tw, th), Image.LANCZOS),
                                args.pixel) for f in a["frames"]]
    cw = max(fs[0].width for fs in scaled.values()) + PAD * 2
    ch = max(fs[0].height for fs in scaled.values()) + PAD * 2
    rows = [n for n in ANIM_ORDER if n in scaled]
    sheet = Image.new("RGBA", (cw * max(len(fs) for fs in scaled.values()),
                               ch * len(rows)), (0, 0, 0, 0))
    for r, name in enumerate(rows):
        for c, fr in enumerate(scaled[name]):
            sheet.alpha_composite(fr, (c * cw + (cw - fr.width) // 2,
                                       r * ch + (ch - PAD - fr.height)))
    out_sheet = os.path.join(ROOT, f"assets/sprites/{args.dino}_motion.png")
    os.makedirs(os.path.dirname(out_sheet), exist_ok=True)
    sheet.save(out_sheet)

    prev = Image.new("RGB", sheet.size, (90, 96, 110))
    prev.paste(sheet, (0, 0), sheet)
    os.makedirs("/tmp/ralph", exist_ok=True)
    out_prev = f"/tmp/ralph/{args.dino}_motion_preview.png"
    prev.resize((prev.width * 2, prev.height * 2), Image.NEAREST).save(out_prev)

    # 4) the dino.gd paste block
    const = f"SHEET_{args.dino.upper()}_MOTION"
    print(f"\nwrote {out_sheet}  cell={cw}x{ch}  rows={len(rows)}")
    print(f"preview -> {out_prev}")
    print("\nremember: /opt/homebrew/bin/godot --headless --import")
    print(f"\n# add const {const} := \"res://assets/sprites/{args.dino}_motion.png\"")
    print("# paste into ANIM_LAYOUTS:")
    print(f'"{args.dino}": {{')
    print(f"    \"sheet\": {const},")
    for r, name in enumerate(rows):
        _, speed, loop = ANIM_DEFAULTS[name]
        rects = ", ".join(f"Rect2({c*cw}, {r*ch}, {cw}, {ch})"
                          for c in range(len(scaled[name])))
        print(f'    "{name}": {{"loop": {str(loop).lower()}, "speed": {speed}, '
              f'"rects": [{rects}]}},')
    print("},")


if __name__ == "__main__":
    main()
