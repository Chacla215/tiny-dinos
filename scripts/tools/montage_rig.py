#!/usr/bin/env python3
"""Tile the rig_test sequence frames into one contact sheet per dino (and a
combined roster sheet) so motion is judgeable in a single image.
Throwaway tuning helper — delete with rig_test.gd once the rig is dialled in.
  python3 scripts/tools/montage_rig.py [dino ...]
"""
import os
import sys
from PIL import Image, ImageDraw

TMP = "/tmp/ralph"
LABELS = ["idle", "walk1", "walk2", "walk3", "attack", "hit!", "hit+", "settle"]
CROP = (20, 70, 440, 440)   # trim the window to the dino region


def sheet(dino):
    cols = []
    for i in range(8):
        p = os.path.join(TMP, f"seq_{dino}_{i}.png")
        if not os.path.exists(p):
            return None
        im = Image.open(p).convert("RGB").crop(CROP)
        d = ImageDraw.Draw(im)
        d.rectangle((0, 0, im.width - 1, im.height - 1), outline=(20, 20, 24))
        d.text((6, 4), f"{dino} {LABELS[i]}", fill=(255, 240, 120))
        cols.append(im)
    w = sum(c.width for c in cols)
    out = Image.new("RGB", (w, cols[0].height), (25, 27, 32))
    x = 0
    for c in cols:
        out.paste(c, (x, 0)); x += c.width
    path = os.path.join(TMP, f"sheet_{dino}.png")
    out.save(path)
    print("wrote", path)
    return out


def main():
    dinos = sys.argv[1:] or ["ralph", "raptor", "trike", "pterry", "bronto", "anky"]
    rows = [s for s in (sheet(d) for d in dinos) if s is not None]
    if len(rows) > 1:
        w = max(r.width for r in rows)
        h = sum(r.height for r in rows)
        combo = Image.new("RGB", (w, h), (25, 27, 32))
        y = 0
        for r in rows:
            combo.paste(r, (0, y)); y += r.height
        # halve it so the whole roster fits in one readable frame
        combo = combo.resize((w // 2, h // 2), Image.LANCZOS)
        combo.save(os.path.join(TMP, "sheet_all.png"))
        print("wrote", os.path.join(TMP, "sheet_all.png"))


if __name__ == "__main__":
    main()
