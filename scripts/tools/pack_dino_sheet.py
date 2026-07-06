"""
Pack Blender-rendered dino frames into a game fighter sheet + ANIM_LAYOUTS.

    python3 scripts/tools/pack_dino_sheet.py --dino ralph --frames /tmp/dino3d \
        --out assets/sprites/ralph_fighter_3d.png [--preview]

Takes frame_00..08.png (idle x2, walk x4, attack x3), crops them all to ONE
shared alpha bbox (so the walk bob + attack lunge stay as real motion instead of
being re-centred away), height-normalises every cell to CELL_H=168 to match the
existing sheets, and packs them into a horizontal strip. Prints the ANIM_LAYOUTS
block to paste into dino.gd. With --preview, also composites the cycle onto the
painterly beach and muxes an mp4 so you can watch it move.
"""
import sys, os, subprocess
from PIL import Image

def argval(flag, default=None):
    a = sys.argv
    return a[a.index(flag) + 1] if flag in a else default

DINO    = argval("--dino", "ralph")
FRAMES  = argval("--frames", "/tmp/dino3d")
OUT     = argval("--out", "assets/sprites/%s_fighter_3d.png" % DINO)
PREVIEW = "--preview" in sys.argv
CELL_H  = 168

N = 9  # idle x2, walk x4, attack x3
imgs = [Image.open(os.path.join(FRAMES, "frame_%02d.png" % i)).convert("RGBA")
        for i in range(N)]

# --- shared alpha bbox across ALL frames (motion-preserving crop) ---
union = None
for im in imgs:
    bb = im.getbbox()
    if bb is None:
        continue
    union = bb if union is None else (
        min(union[0], bb[0]), min(union[1], bb[1]),
        max(union[2], bb[2]), max(union[3], bb[3]))
if union is None:
    raise SystemExit("all frames empty -- render produced nothing")
pad = 4
union = (max(0, union[0] - pad), max(0, union[1] - pad),
         min(imgs[0].width, union[2] + pad), min(imgs[0].height, union[3] + pad))

cropped = [im.crop(union) for im in imgs]
bw, bh = union[2] - union[0], union[3] - union[1]
cell_w = max(1, round(bw * CELL_H / bh))
cells = [im.resize((cell_w, CELL_H), Image.LANCZOS) for im in cropped]

# --- pack horizontal strip ---
sheet = Image.new("RGBA", (cell_w * N, CELL_H), (0, 0, 0, 0))
for i, c in enumerate(cells):
    sheet.paste(c, (i * cell_w, 0), c)
os.makedirs(os.path.dirname(OUT) or ".", exist_ok=True)
sheet.save(OUT)
print("SHEET -> %s  (%dx%d, cell %dx%d)" % (OUT, sheet.width, sheet.height, cell_w, CELL_H))

# --- ANIM_LAYOUTS block ---
def rect(i): return "Rect2(%d, 0, %d, %d)" % (i * cell_w, cell_w, CELL_H)
idle   = ", ".join(rect(i) for i in (0, 1))
walk   = ", ".join(rect(i) for i in (2, 3, 4, 5))
attack = ", ".join(rect(i) for i in (6, 7, 8))
const_name = "SHEET_%s_3D" % DINO.upper()
print("\n--- paste into dino.gd ---")
print('const %s := "res://%s"' % (const_name, OUT))
print('\t"%s_3d": {' % DINO)
print('\t\t"sheet": %s,' % const_name)
print('\t\t"idle":   {"loop": true,  "speed": 4.0,  "rects": [%s]},' % idle)
print('\t\t"walk":   {"loop": true,  "speed": 8.0,  "rects": [%s]},' % walk)
print('\t\t"attack": {"loop": false, "speed": 12.0, "rects": [%s]},' % attack)
print("\t},")

# --- optional: animated preview on the beach ---
if PREVIEW:
    beach_path = "assets/concept/islands/restyle/beach.png"
    scene_w, scene_h = 960, 540
    if os.path.exists(beach_path):
        bg = Image.open(beach_path).convert("RGBA").resize((scene_w, scene_h), Image.LANCZOS)
    else:
        bg = Image.new("RGBA", (scene_w, scene_h), (120, 170, 210, 255))
    disp_h = 300
    disp_w = round(cell_w * disp_h / CELL_H)
    order = [0, 1, 0, 1, 2, 3, 4, 5, 2, 3, 4, 5, 6, 7, 8, 8, 0, 1]
    pv_dir = os.path.join(FRAMES, "preview")
    os.makedirs(pv_dir, exist_ok=True)
    for k, fi in enumerate(order):
        frame = bg.copy()
        dino = cells[fi].resize((disp_w, disp_h), Image.LANCZOS)
        fx = scene_w // 2 - disp_w // 2
        fy = int(scene_h * 0.60) - disp_h // 2
        frame.alpha_composite(dino, (fx, fy))
        frame.convert("RGB").save(os.path.join(pv_dir, "pv_%03d.png" % k))
    mp4 = os.path.join(FRAMES, "%s_3d_preview.mp4" % DINO)
    subprocess.run(["ffmpeg", "-y", "-framerate", "9", "-i",
                    os.path.join(pv_dir, "pv_%03d.png"),
                    "-vf", "scale=960:540:flags=lanczos", "-c:v", "libx264",
                    "-pix_fmt", "yuv420p", "-loop", "0", mp4],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    still = os.path.join(FRAMES, "%s_3d_on_beach.png" % DINO)
    Image.open(os.path.join(pv_dir, "pv_005.png")).save(still)
    print("\nPREVIEW mp4  -> %s" % mp4)
    print("PREVIEW still -> %s" % still)
